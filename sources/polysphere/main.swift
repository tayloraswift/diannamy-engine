import GLFW

// use reference type because we want to attach `self` pointer to GLFW
final
class Window
{
    private
    let window:OpaquePointer

    private
    var coordinator:Coordinator 
    {
        didSet 
        {
            self.eventsProcessed = true 
        }
    }
    private 
    var height:Double, // need to store this to flip y axis
        lastDown:(left:Double, middle:Double, right:Double)
    
    private 
    var eventsProcessed:Bool = true 
    
    init(size:Vector2<Float>, name:String)
    {
        guard let window:OpaquePointer = glfwCreateWindow(.init(size.x), .init(size.y), name, nil, nil)
        else
        {
            Log.fatal("failed to create window")
        }

        glfwMakeContextCurrent(window)
        glfwSwapInterval(1)

        self.window      = window
        self.coordinator = .init()
        self.height      = .init(size.y)
        self.lastDown    = (glfwGetTime(), glfwGetTime(), glfwGetTime())
        
        GL.enableDebugOutput()
        
        self.coordinator.window(size: size)
        
        // attach pointer to self to window
        glfwSetWindowUserPointer(window,
            UnsafeMutableRawPointer(Unmanaged<Window>.passUnretained(self).toOpaque()))

        glfwSetFramebufferSizeCallback(window)
        {
            (context:OpaquePointer?, x:CInt, y:CInt) in
            
            let window:Window   = .reconstitute(from: context)
            window.height       = .init(y)
            window.coordinator.window(size: Vector2<CInt>.init(x, y).map(Float.init(_:)))
        }

        glfwSetCharCallback(window)
        {
            (context:OpaquePointer?, value:UInt32) in
            
            guard let codepoint:Unicode.Scalar = Unicode.Scalar.init(value)
            else 
            {
                return 
            }
            
            let window:Window   = .reconstitute(from: context)
            window.coordinator.character(.init(codepoint))
        }
        
        glfwSetKeyCallback(window)
        {
            (context:OpaquePointer?, keycode:CInt, scancode:CInt, action:CInt, modifiers:CInt) in

            let key:UI.Key                  = .init(keycode), 
                modifiers:UI.Key.Modifiers  = .init(modifiers)
            
            guard action == GLFW_PRESS || action == GLFW_REPEAT && key.isArrowKey
            else
            {
                return
            }
            
            let window:Window               = .reconstitute(from: context)
            if  modifiers.control, 
                key == .V 
            {
                let string:String = .init(cString: glfwGetClipboardString(window.window))
                window.coordinator.paste(string)
                return                 
            }
            
            window.coordinator.keypress(key, modifiers)
        }
        
        glfwSetCursorPosCallback(window)
        {
            (context:OpaquePointer?, x:Double, y:Double) in
            
            let window:Window = .reconstitute(from: context)
            window.coordinator.move(Vector2<Double>.init(x, window.height - y).map(Float.init(_:)))
        }

        glfwSetMouseButtonCallback(window)
        {
            (context:OpaquePointer?, code:CInt, direction:CInt, mods:CInt) in

            let window:Window = .reconstitute(from: context), 
                position:Vector2<Float> = window.cursorPosition(context: context)
            
            outer: 
            switch direction 
            {
            case GLFW_PRESS:
                let timestamp:Double = glfwGetTime(), 
                    delta:Double, 
                    action:UI.Action
                
                let threshold:Double = 0.3 
                switch code 
                {
                case    GLFW_MOUSE_BUTTON_LEFT:
                    delta                   = timestamp - window.lastDown.left
                    action                  = .primary
                    window.lastDown.left    = delta < threshold ? window.lastDown.left   : timestamp 
                    
                case    GLFW_MOUSE_BUTTON_MIDDLE:
                    delta                   = timestamp - window.lastDown.middle
                    action                  = .tertiary
                    window.lastDown.middle  = delta < threshold ? window.lastDown.middle : timestamp 
                
                case    GLFW_MOUSE_BUTTON_RIGHT:
                    delta                   = timestamp - window.lastDown.right
                    action                  = .secondary
                    window.lastDown.right   = delta < threshold ? window.lastDown.right  : timestamp 
                
                case    GLFW_MOUSE_BUTTON_4, 
                        GLFW_MOUSE_BUTTON_5, 
                        GLFW_MOUSE_BUTTON_6, 
                        GLFW_MOUSE_BUTTON_7, 
                        GLFW_MOUSE_BUTTON_8:
                    return 
                
                default:
                    break outer 
                }
                
                window.coordinator.down(action, position, doubled: delta < threshold)
                return 
                
            case GLFW_RELEASE:
                let action:UI.Action
                
                switch code 
                {
                case GLFW_MOUSE_BUTTON_LEFT:
                    action = .primary
                    
                case GLFW_MOUSE_BUTTON_MIDDLE:
                    action = .tertiary
                
                case GLFW_MOUSE_BUTTON_RIGHT:
                    action = .secondary
                
                case    GLFW_MOUSE_BUTTON_4, 
                        GLFW_MOUSE_BUTTON_5, 
                        GLFW_MOUSE_BUTTON_6, 
                        GLFW_MOUSE_BUTTON_7, 
                        GLFW_MOUSE_BUTTON_8:
                    return 
                
                default:
                    break outer 
                }
                
                window.coordinator.up(action, position)
                return 
            
            default:
                break 
            }
            
            Log.warning("unrecognized mouse action (\(code), \(direction)")
        }
        
        glfwSetScrollCallback(window)
        {
            (context:OpaquePointer?, x:Double, y:Double) in

            let window:Window           = .reconstitute(from: context), 
                position:Vector2<Float> = window.cursorPosition(context: context)

            if y > 0
            {
                window.coordinator.scroll(.up, position)
            }
            else if y < 0
            {
                window.coordinator.scroll(.down, position)
            }
            else if x > 0
            {
                window.coordinator.scroll(.left, position)
            }
            else if x < 0
            {
                window.coordinator.scroll(.right, position)
            }
        }
    }
    
    func cursorPosition(context:OpaquePointer?) -> Vector2<Float> 
    {
        var (x, y):(Double, Double) = (0, 0) 
        glfwGetCursorPos(context, &x, &y)
        return .init(.init(x), .init(self.height - y))
    }

    func loop()
    {
        GL.depthTest(.greaterEqual)
        GL.clearColor(.init(0.02, 0.02, 0.02), 1)
        GL.clearDepth(-1.0)
        
        var t0:Double = glfwGetTime()
        while glfwWindowShouldClose(self.window) == 0
        {
            glfwPollEvents()

            let t1:Double = glfwGetTime()
            
            if  self.coordinator.process(.init(t1 * 1000) - .init(t0 * 1000)) || 
                self.eventsProcessed
            {
                self.eventsProcessed = false 
                self.coordinator.draw()
                glfwSwapBuffers(self.window)
            }
            
            t0 = t1
        }
    }

    deinit
    {
        glfwDestroyWindow(self.window)
    }

    private static
    func reconstitute(from window:OpaquePointer?) -> Window
    {
        return Unmanaged<Window>.fromOpaque(glfwGetWindowUserPointer(window)).takeUnretainedValue()
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
    }

    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3)
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3)
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_ANY_PROFILE)
    glfwWindowHint(GLFW_RESIZABLE, 1)
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, 1)
    glfwWindowHint(GLFW_SAMPLES, 4)

    OpenGL.loader = unsafeBitCast(glfwGetProcAddress, to: OpenGL.LoaderFunction.self)
    
    let window:Window = .init(size: .init(1200, 600), name: "Map Editor")
    
    window.loop()
}

main()

// define the pole to be crossed if the counterclockwise fan `[a, b)` includes
// the pole, with `a` not parallel to `b`. this means a fan with its starting point
// on the pole is defined to be crossing it, but a fan with its ending point on
// the pole is not. a fan whose starting and ending point are both on the pole
// does not cross it.
func crossesPole<F>(_ a:Math<F>.V2, _ b:Math<F>.V2) -> Bool where F:FloatingPoint
{
    let aperture:F = Math.cross(a, b)
    if  aperture == 0
    {
        // make sure fan is the 180° case, not the 0° case
        // (degenerate cases where `a` or `b` are the zero vector are also filtered
        // out as the entire result is undefined in those cases)
        guard Math.dot(a, b) < 0
        else
        {
            return false
        }

        // `a` has to be in quadrants III or IV for `a` crossing to occur, inclusive
        // of the boundary with I, but exclusive of the boundary with II
        if a.x < 0
        {
            return a.y <  0
        }
        else
        {
            return a.y <= 0
        }
    }
    else if aperture < 0
    {
        return b.y >  0 || a.y <= 0
    }
    else
    {
        return a.y <= 0 && b.y >  0
    }
}

/*
let hours:[(Float, Float)] =
[
    (-1,  0),
    (-1, -1),
    ( 0, -1),
    ( 1, -1),
    ( 1,  0),
    ( 1,  1),
    ( 0,  1),
    (-1,  1)
]

for i:Int in 0 ..< 5
{
    for j:Int in 0 ..< 8
    {
        print(crossesPole(hours[i], hours[(i + j) % 8]) == (i + j > 4))
    }
}

for i:Int in 5 ..< 8
{
    for j:Int in 0 ..< 8
    {
        print(crossesPole(hours[i], hours[(i + j) % 8]) == (i + j > 12))
    }
}
*/
