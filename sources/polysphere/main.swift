import GLFW

// use reference type because we want to attach `self` pointer to GLFW
fileprivate final 
class Context
{
    private 
    var coordinator:Coordinator 
    private 
    let backpointer:OpaquePointer
    
    // need this to detect double clicks
    private 
    var lastPrimary:Double 
    
    init(_ coordinator:Coordinator, backpointer:OpaquePointer)
    {
        self.coordinator = coordinator
        self.backpointer = backpointer
        
        self.lastPrimary = glfwGetTime()
    }
    
    func connect() 
    {
        // attach pointer to window to handle
        let context:UnsafeMutableRawPointer = 
            .init(Unmanaged<Context>.passUnretained(self).toOpaque())
        glfwSetWindowUserPointer(self.backpointer, context)
        
        glfwSetFramebufferSizeCallback(self.backpointer)
        {
            (context:OpaquePointer?, x:CInt, y:CInt) in
            
            let context:Context         = .reconstitute(from: context)
            context.coordinator.window  = .cast(.init(x, y))
        }

        glfwSetCharCallback(self.backpointer)
        {
            (context:OpaquePointer?, value:UInt32) in
            
            guard let codepoint:Unicode.Scalar = Unicode.Scalar.init(value)
            else 
            {
                return 
            }
            
            let context:Context = .reconstitute(from: context)
            context.coordinator.event(.character(.init(codepoint)))
        }
        
        glfwSetKeyCallback(self.backpointer)
        {
            (context:OpaquePointer?, keycode:CInt, scancode:CInt, action:CInt, modifiers:CInt) in

            let key:UI.Event.Key                    = .init(keycode), 
                modifiers:UI.Event.Key.Modifiers    = .init(modifiers)
            
            guard action == GLFW_PRESS || action == GLFW_REPEAT && key.repeatable
            else
            {
                return
            }
            
            let context:Context = .reconstitute(from: context)
            let event:UI.Event 
            if modifiers.control
            {
                switch key 
                {
                case .X:
                    event = .cut  
                case .C:
                    event = .copy 
                case .V:
                    event = .paste(.init(cString: glfwGetClipboardString(context.backpointer)))
                default:
                    event = .key(key, modifiers)
                }
            }
            else 
            {
                event = .key(key, modifiers)
            }
            
            context.coordinator.event(event)
        }
        
        glfwSetCursorPosCallback(self.backpointer)
        {
            (context:OpaquePointer?, x:Double, y:Double) in
            
            let context:Context = .reconstitute(from: context)
            let position:Vector2<Float> = 
                .init(.init(x), .init(context.coordinator.window.y) - .init(y))
            context.coordinator.event(.enter(position))
        }

        glfwSetMouseButtonCallback(self.backpointer)
        {
            (context:OpaquePointer?, code:CInt, direction:CInt, mods:CInt) in

            let context:Context         = .reconstitute(from: context), 
                position:Vector2<Float> = context.cursorPosition()
            
            let d1:UI.Event.Direction.D1
            switch direction 
            {
            case GLFW_PRESS:
                d1 = .down 
            case GLFW_RELEASE:
                d1 = .up 
            default:
                return 
            }
            
            let event:UI.Event
            switch code 
            {
            case    GLFW_MOUSE_BUTTON_LEFT:
                let threshold:Double = 0.3, 
                    timestamp:Double = glfwGetTime()
                if d1 == .down, timestamp - context.lastPrimary < threshold
                {
                    event = .double(d1, position)
                }
                else 
                {
                    event = .primary(d1, position)
                }
                context.lastPrimary = timestamp
                
            case    GLFW_MOUSE_BUTTON_MIDDLE:
                return 
            
            case    GLFW_MOUSE_BUTTON_RIGHT:
                event = .secondary(d1, position)
            
            case    GLFW_MOUSE_BUTTON_4, 
                    GLFW_MOUSE_BUTTON_5, 
                    GLFW_MOUSE_BUTTON_6, 
                    GLFW_MOUSE_BUTTON_7, 
                    GLFW_MOUSE_BUTTON_8:
                return 
            
            default:
                return 
            }
            
            context.coordinator.event(event)
        }
        
        glfwSetScrollCallback(self.backpointer)
        {
            (context:OpaquePointer?, x:Double, y:Double) in

            let context:Context         = .reconstitute(from: context), 
                position:Vector2<Float> = context.cursorPosition()
            
            let d2:UI.Event.Direction.D2
            switch (x < y, -x < y)
            {
            case (true, true):
                d2 = .up 
            case (true, false):
                d2 = .right 
            case (false, true):
                d2 = .left 
            case (false, false):
                d2 = .down 
            }
            
            context.coordinator.event(.scroll(d2, position))
        }
    }

    func loop()
    {
        glfwSwapInterval(1)
        
        self.coordinator.window = self.framebufferSize()
        
        var t0:Double = glfwGetTime()
        while glfwWindowShouldClose(self.backpointer) == 0
        {
            glfwPollEvents()
            
            let t1:Double = glfwGetTime()
            
            if self.coordinator.process(delta: .init(t1 * 1000) - .init(t0 * 1000)) 
            {
                glfwSwapBuffers(self.backpointer)
            }
            
            t0 = t1
        }
    }

    static
    func reconstitute(from context:OpaquePointer?) -> Self 
    {
        return Unmanaged<Self>.fromOpaque(glfwGetWindowUserPointer(context)).takeUnretainedValue()
    }
    
    private 
    func cursorPosition() -> Vector2<Float> 
    {
        var (x, y):(Double, Double) = (0, 0) 
        glfwGetCursorPos(self.backpointer, &x, &y)
        return .init(.init(x), .init(self.coordinator.window.y) - .init(y))
    }
    private 
    func framebufferSize() -> Vector2<Int> 
    {
        var (x, y):(Int32, Int32) = (0, 0) 
        glfwGetFramebufferSize(self.backpointer, &x, &y)
        return .cast(.init(x, y))
    }
}

func main()
{
    guard glfwInit() == 1
    else
    {
        Log.fatal("glfwInit() failed")
    }
    defer
    {
        glfwTerminate()
    }

    glfwSetErrorCallback
    {
        (error:CInt, description:UnsafePointer<CChar>?) in

        if let description = description
        {
            Log.error(.init(cString: description), from: .glfw)
        }
        else 
        {
            Log.error("<no description available> (code \(error))", from: .glfw)
        }
    }

    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3)
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3)
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_ANY_PROFILE)
    glfwWindowHint(GLFW_RESIZABLE, 1)
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, 1)
    glfwWindowHint(GLFW_SAMPLES, 4)
    
    guard let window:OpaquePointer = 
        glfwCreateWindow(1200, 600, "<anonymous>", nil, nil)
    else
    {
        Log.fatal("failed to create window")
    }
    defer
    {
        glfwDestroyWindow(window)
    }
    
    // must be called before any GL-related API calls are made
    glfwMakeContextCurrent(window)
    
    typealias LoaderFunction    = (UnsafePointer<Int8>) -> UnsafeMutableRawPointer?
    let loader:LoaderFunction   = unsafeBitCast(glfwGetProcAddress, to: LoaderFunction.self)
    
    Renderer.Backend.initialize(loader: loader, options: 
        .debug, 
        .clear(r: 0.3, g: 0, b: 1, a: 1), 
        .clearDepth(-1))
    let coordinator:Coordinator = .init(renderer: .init(options: .clear(color: true, depth: true)))
    let context:Context         = .init(coordinator, backpointer: window)
    withExtendedLifetime(context)
    {
        (context:Context) in
        
        do 
        {
            try UI.Style.Sheet.parse(path: "test")
            try UI.Style.Sheet.parse(path: "default")
        }
        catch 
        {
            Log.trace(error: error)
        }
        
        context.connect()
        context.loop()
    }
}

main()
