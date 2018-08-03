import GLFW

struct Frame
{
    enum MouseButton
    {
        case left, middle, right
    }

    enum Key:Int
    {
        case esc     = 256,
             enter,
             tab,
             backspace,
             insert,
             delete,
             right,
             left,
             down,
             up,

             zero = 48, one, two, three, four, five, six, seven, eight, nine,

             f1 = 290, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12,

             space   = 32,
             period  = 46,
             unknown = -1

        init(_ keycode:Int32)
        {
            self = Key.init(rawValue: Int(keycode)) ?? .unknown
        }
    }

    private
    var world:World, 
        scene:Scene,
        _cameraBlock:GL.Buffer<Camera.Storage>,
        plane:ControlPlane, 
        
        _preselectedResource:Int? = nil

    init(size:Math<Int>.V2)
    {
        GL.enableDebugOutput()
        
        self.world = .init()
        self.scene = .init()
        self.plane = .init(.init(
            pivot: (0, 0, 0),
            angle: (0.25 * Float.pi, 1.75 * Float.pi),
            distance: 4,
            focalLength: 32))
        
        self._cameraBlock = .generate()
        self._cameraBlock.bind(to: .uniform)
        {
            $0.reserve(capacity: 1, usage: .dynamic)
        }

        self.resize(to: size)
    }

    mutating
    func resize(to size:Math<Int>.V2)
    {
        // figure out center point of screen
        let sizef:Math<Float>.V2 = Math.castFloat(size),
            shift:Math<Float>.V2 = Math.scale(sizef, by: -0.5)
        
        self.plane.sensor = (shift, Math.add(sizef, shift))
        
        GL.viewport(anchor: (0, 0), size: size)
    }

    private static
    func buttonAction(_ button:MouseButton) -> ControlPlane.Action?
    {
        switch button
        {
            case .left:
                return nil

            case .middle:
                return .track

            case .right:
                return .pan
        }
    }
    
    private 
    func sphereIntersection(_ position:Math<Double>.V2) -> Math<Float>.V3? 
    {
        let ray:ControlPlane.Ray = self.plane.raycast(Math.castFloat(position))
        return self.scene.cast(ray.vector, from: ray.source)
    }

    mutating
    func press(_ position:Math<Double>.V2, button:MouseButton)
    {
        switch button 
        {
            case .left:
                if let intersect:Math<Float>.V3 = self.sphereIntersection(position)
                {
                    self._preselectedResource = 
                        world.add(deposit: .init(location: .init(vector: intersect), amount: 2))
                }
            
            default:
                break 
        }
        
        guard let action:ControlPlane.Action = Frame.buttonAction(button)
        else
        {
            return
        }

        self.plane.down(Math.castFloat(position), action: action)
    }

    mutating
    func cursor(_ position:Math<Double>.V2)
    {
        self.plane.move(Math.castFloat(position))
        
        if let intersect:Math<Float>.V3 = self.sphereIntersection(position)
        {
            self._preselectedResource = world.find(.init(vector: intersect))
        }
        else 
        {
            self._preselectedResource = nil
        }
    }

    mutating
    func release(_ position:Math<Double>.V2, button:MouseButton)
    {
        guard let action:ControlPlane.Action = Frame.buttonAction(button)
        else
        {
            return
        }

        self.plane.up(Math.castFloat(position), action: action)
    }

    mutating
    func scroll(_ direction:Direction)
    {
        self.plane.bump(direction, action: .zoom)
    }

    mutating
    func keypress(_ key:Key)
    {
        switch key
        {
            case .up:
                self.plane.bump(.up, action: .track)
            case .down:
                self.plane.bump(.down, action: .track)
            case .left:
                self.plane.bump(.left, action: .track)
            case .right:
                self.plane.bump(.right, action: .track)
            
            case .period:
                self.plane.jump(to: (0, 0, 0))

            default:
                Log.note("unrecognized key press (\(key))")
        }
    }

    mutating
    func process(_ δ:Double) -> Bool
    {
        GL.clearColor((0.1, 0.1, 0.1), 1)
        GL.clearDepth(-1.0)
        GL.clear(color: true, depth: true)

        self._cameraBlock.bind(to: .uniform, index: 0)
        {
            (target:GL.Buffer.BoundTarget) in

            // check if camera needs updating
            if self.plane.next(Float(δ))
            {
                self.plane.camera.withUnsafeBytes
                {
                    target.subData($0)
                }
            }
            
            // rebuild the scene 
            self.scene.rebuild(self.world)
            self.scene.draw(preselectedResource: self._preselectedResource)
        }

        return true
    }

    /*
    func step(_ delta:Double)
    {

    }
    */
}

// use reference type because we want to attach `self` pointer to GLFW
final
class Window
{
    private
    let window:OpaquePointer

    private
    var frame:Frame, 
        height:Double // need to store this to flip y axis

    init(size:Math<Int>.V2, name:String)
    {
        guard let window:OpaquePointer = glfwCreateWindow(CInt(size.x), CInt(size.y), name, nil, nil)
        else
        {
            Log.fatal("failed to create window")
        }

        glfwMakeContextCurrent(window)
        glfwSwapInterval(1)

        self.window = window
        self.frame  = .init(size: size)
        self.height = Double(size.y)

        // attach pointer to self to window
        glfwSetWindowUserPointer(window,
            UnsafeMutableRawPointer(Unmanaged<Window>.passUnretained(self).toOpaque()))

        glfwSetFramebufferSizeCallback(window)
        {
            (context:OpaquePointer?, x:CInt, y:CInt) in
            
            let window:Window = .reconstitute(from: context)
            window.height = Double(y)
            window.frame.resize(to: Math.cast((x, y), as: Int.self))
        }

        glfwSetKeyCallback(window)
        {
            (context:OpaquePointer?, keycode:CInt, scancode:CInt, action:CInt, mods:CInt) in

            guard action == GLFW_PRESS
            else
            {
                return
            }

            let key:Frame.Key = .init(keycode)
            Window.reconstitute(from: context).frame.keypress(key)
        }

        glfwSetCursorPosCallback(window)
        {
            (context:OpaquePointer?, x:Double, y:Double) in
            
            let window:Window = .reconstitute(from: context)
            window.frame.cursor((x, window.height - y))
        }

        glfwSetMouseButtonCallback(window)
        {
            (context:OpaquePointer?, code:CInt, action:CInt, mods:CInt) in

            let window:Window = .reconstitute(from: context),
                button:Frame.MouseButton

            switch code
            {
            case GLFW_MOUSE_BUTTON_LEFT:
                button = .left
            case GLFW_MOUSE_BUTTON_MIDDLE:
                button = .middle
            case GLFW_MOUSE_BUTTON_RIGHT:
                button = .right
            default:

                Log.note("unrecognized mouse button (\(code))")
                return
            }

            var position:Math<Double>.V2 = (0, 0)
            glfwGetCursorPos(context, &position.x, &position.y)
            position.y = window.height - position.y

            if action == GLFW_PRESS
            {
                window.frame.press(position, button: button)
            }
            else // if action == GLFW_RELEASE
            {
                window.frame.release(position, button: button)
            }
        }

        glfwSetScrollCallback(window)
        {
            (window:OpaquePointer?, x:Double, y:Double) in

            let interface:Window = Window.reconstitute(from: window)

            if y > 0
            {
                interface.frame.scroll(.up)
            }
            else if y < 0
            {
                interface.frame.scroll(.down)
            }
            else if x > 0
            {
                interface.frame.scroll(.left)
            }
            else if x < 0
            {
                interface.frame.scroll(.right)
            }
        }
    }

    func loop()
    {
        GL.depthTest(.greaterEqual)
        
        var t0:Double = glfwGetTime()
        while glfwWindowShouldClose(self.window) == 0
        {
            glfwPollEvents()

            let t1:Double = glfwGetTime()
            if self.frame.process(t1 - t0)
            {
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

    let window:Window = .init(size: (1200, 600), name: "Polysphere")
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
