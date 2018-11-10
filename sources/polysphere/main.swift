import GLFW

// use reference type because we want to attach `self` pointer to GLFW
final
class Window
{
    private
    let window:OpaquePointer

    private
    var coordinator:Coordinator, 
        height:Double, // need to store this to flip y axis
        lastPrimary:Double 

    init(size:Math<Float>.V2, name:String)
    {
        guard let window:OpaquePointer = glfwCreateWindow(CInt(size.x), CInt(size.y), name, nil, nil)
        else
        {
            Log.fatal("failed to create window")
        }

        glfwMakeContextCurrent(window)
        glfwSwapInterval(1)

        self.window      = window
        self.coordinator = .init()
        self.height      = Double(size.y)
        self.lastPrimary = glfwGetTime()
        
        self.coordinator.resize(to: size)
        
        // attach pointer to self to window
        glfwSetWindowUserPointer(window,
            UnsafeMutableRawPointer(Unmanaged<Window>.passUnretained(self).toOpaque()))

        glfwSetFramebufferSizeCallback(window)
        {
            (context:OpaquePointer?, x:CInt, y:CInt) in
            
            let window:Window = .reconstitute(from: context)
            window.height = Double(y)
            window.coordinator.resize(to: Math.cast((x, y), as: Float.self))
        }

        glfwSetKeyCallback(window)
        {
            (context:OpaquePointer?, keycode:CInt, scancode:CInt, action:CInt, mods:CInt) in

            guard action == GLFW_PRESS
            else
            {
                return
            }
            
            Window.reconstitute(from: context).coordinator.keypress(.init(keycode))
        }
        
        glfwSetCursorPosCallback(window)
        {
            (context:OpaquePointer?, x:Double, y:Double) in
            
            let window:Window = .reconstitute(from: context)
            window.coordinator.move(Math.cast((x, window.height - y), as: Float.self))
        }

        glfwSetMouseButtonCallback(window)
        {
            (context:OpaquePointer?, code:CInt, direction:CInt, mods:CInt) in

            let window:Window = .reconstitute(from: context), 
                position:Math<Float>.V2 = window.cursorPosition(context: context)
            
            switch (code, direction)
            {
                case (GLFW_MOUSE_BUTTON_LEFT, GLFW_PRESS):
                    let timestamp:Double = glfwGetTime(), 
                        delta:Double     = timestamp - window.lastPrimary
                    
                    window.lastPrimary = timestamp 
                    if delta < 0.3 
                    {
                        window.coordinator.down(.double, position)
                    }
                    else 
                    {
                        window.coordinator.down(.primary, position)
                    }
                case (GLFW_MOUSE_BUTTON_LEFT, GLFW_RELEASE):
                    window.coordinator.up(.primary, position)
                    
                case (GLFW_MOUSE_BUTTON_MIDDLE, GLFW_PRESS):
                    window.coordinator.down(.tertiary, position)
                case (GLFW_MOUSE_BUTTON_MIDDLE, GLFW_RELEASE):
                    window.coordinator.up(.tertiary, position)
                
                case (GLFW_MOUSE_BUTTON_RIGHT, GLFW_PRESS):
                    window.coordinator.down(.secondary, position)
                case (GLFW_MOUSE_BUTTON_RIGHT, GLFW_RELEASE):
                    window.coordinator.up(.secondary, position)
                
                default:
                    Log.note("unrecognized mouse action (\(code), \(direction)")
            }
        }
        
        glfwSetScrollCallback(window)
        {
            (window:OpaquePointer?, x:Double, y:Double) in

            let interface:Window = Window.reconstitute(from: window)

            if y > 0
            {
                interface.coordinator.scroll(.up)
            }
            else if y < 0
            {
                interface.coordinator.scroll(.down)
            }
            else if x > 0
            {
                interface.coordinator.scroll(.left)
            }
            else if x < 0
            {
                interface.coordinator.scroll(.right)
            }
        }
        
        GL.enableDebugOutput()
    }
    
    func cursorPosition(context:OpaquePointer?) -> Math<Float>.V2 
    {
        var position:Math<Double>.V2 = (0, 0)
        glfwGetCursorPos(context, &position.x, &position.y)
        position.y = self.height - position.y
        
        return Math.cast(position, as: Float.self)
    }

    func loop()
    {
        GL.depthTest(.greaterEqual)
        GL.clearColor((0.1, 0.1, 0.1), 1)
        GL.clearDepth(-1.0)
        
        var t0:Double = glfwGetTime()
        while glfwWindowShouldClose(self.window) == 0
        {
            glfwPollEvents()

            let t1:Double = glfwGetTime()
            
            self.coordinator.process(Int(t1 * 256) - Int(t0 * 256))
            self.coordinator.draw()
            
            glfwSwapBuffers(self.window)

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

    let window:Window = .init(size: (1200, 600), name: "Map Editor")
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
