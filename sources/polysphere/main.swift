import GLFW

enum Programs
{
    static
    let debug:GL.Program = .create(
        shaders:
        [
            (.vertex  , "shaders/debug.vert"),
            (.fragment, "shaders/debug.frag")
        ],
        uniforms:
        [
            .block("Camera", binding: 0)
        ]
    )!
    static
    let sphere:GL.Program = .create(
        shaders:
        [
            (.vertex  , "shaders/sphere.vert"),
            (.fragment, "shaders/sphere.frag")
        ],
        uniforms:
        [
            .block("Camera", binding: 0), 
            .float4("sphere")
        ]
    )!
}

enum Direction
{
    case up, down, left, right
}

struct ViewControl
{
    enum Action
    {
        case pan, track, zoom
    }

    struct Anchor
    {
        let base:Math<Float>.V2,
            action:Action
    }

    private(set)
    var camera:Camera

    private
    var view:Camera.Rig,
        base:Camera.Rig,

        sensor:Math<Float>.Rectangle,
        anchor:Anchor? = nil,

        // animation
        phase:Float?

    init(_ base:Camera.Rig)
    {
        self.view = base
        self.base = base

        self.camera = .init()
        self.sensor = ((0, 0), (0, 0))
        self.phase  = 0
    }

    mutating
    func setSensor(_ sensor:Math<Float>.Rectangle)
    {
        self.sensor = sensor
        self.phase  = 0
    }

    mutating
    func down(_ position:Math<Float>.V2, action:Action)
    {
        guard self.anchor == nil
        else
        {
            return
        }

        self.anchor = .init(base: position, action: action)
        self.rebase()
    }

    mutating
    func move(_ position:Math<Float>.V2)
    {
        guard let anchor:Anchor = self.anchor
        else
        {
            // hover
            return
        }

        self.compose(position, anchor: anchor)
    }

    mutating
    func up(_ position:Math<Float>.V2, action:Action)
    {
        guard let anchor:Anchor = self.anchor
        else
        {
            Log.warning("control up event recieved, but no corresponding down event was recieved")
            return
        }

        switch (anchor.action, action)
        {
            case (.pan, .pan), (.track, .track), (.zoom, .zoom):
                break

            default:
                // up event does not match stored down event
                return
        }

        self.compose(position, anchor: anchor)

        self.anchor = nil
    }

    mutating
    func bump(_ direction:Direction, action:Action)
    {
        // bumps have lower priority than anchors
        guard self.anchor == nil
        else
        {
            return
        }

        // ordering of operations here is important
        self.rebase()
        self.phase = 1

        switch action
        {
            case .pan:
                switch direction
                {
                    case .up:
                        let θ:Float       = self.view.angle.θ - 0.1
                        self.view.angle.θ = max(0, min(θ, Float.pi))
                    case .down:
                        let θ:Float       = self.view.angle.θ + 0.1
                        self.view.angle.θ = max(0, min(θ, Float.pi))
                    case .left:
                        self.view.angle.φ -= 0.1
                    case .right:
                        self.view.angle.φ += 0.1
                }

            case .track:
                let basis:Math<Math<Float>.V3>.V3 = self.base.basis()

                let vector:Math<Float>.V3
                switch direction
                {
                    case .up:
                        vector = basis.y
                    case .down:
                        vector = Math.neg(basis.y)
                    case .left:
                        vector = Math.neg(basis.x)
                    case .right:
                        vector = basis.x
                }

                self.view.pivot = Math.scadd(self.base.pivot, vector, 0.5)

            case .zoom:
                switch direction
                {
                    case .up:
                        self.view.focalLength = min(195, self.view.focalLength + 10)
                    case .down:
                        self.view.focalLength = max(15,  self.view.focalLength - 10)

                    default:
                        self.phase = 0
                }
        }
    }

    // returns true if the view system has changed
    mutating
    func next(_ δ:Float) -> Bool
    {
        guard let phase:Float = self.phase
        else
        {
            return false
        }

        let decremented:Float = phase - δ * 5,
            interpolation:Camera.Rig
        if decremented > 0
        {
            interpolation = Camera.Rig.lerp(self.view, self.base,
                ViewControl.parameter(decremented))
            self.phase = decremented
        }
        else
        {
            interpolation = self.view
            self.phase = nil
        }

        let space:Space = interpolation.space()
        let (a, b):(Math<Float>.V3, Math<Float>.V3) =
            interpolation.frustum(sensor: self.sensor, clip: (-0.1, -100))

        self.camera.view(space)
        self.camera.frustum(a, b)
        self.camera.fragment(sensor: self.sensor, space: space)
        self.camera.matrices()

        return true
    }

    private mutating
    func compose(_ position:Math<Float>.V2, anchor:Anchor)
    {
        let displacement:Math<Float>.V2 =
            Math.scale(Math.sub(position, anchor.base), by: -0.005)
        switch anchor.action
        {
            case .pan:
                self.view.angle.φ = self.base.angle.φ + displacement.x
                let θ:Float       = self.base.angle.θ - displacement.y
                self.view.angle.θ = max(0, min(θ, Float.pi))

            case .track:
                let basis:Math<Math<Float>.V3>.V3 = self.base.basis()

                self.view.pivot = Math.add(self.base.pivot,
                    (Math.dot(displacement, (basis.x.x, basis.y.x)),
                     Math.dot(displacement, (basis.x.y, basis.y.y)),
                     Math.dot(displacement, (basis.x.z, basis.y.z))))

            case .zoom:
                // not implemented
                break
        }

        self.phase = 0
    }

    private static
    func parameter(_ x:Float) -> Float
    {
        // x from 0 to 1
        return x * x
    }

    // kills any current animation and synchronizes the 2 current keyframes
    mutating
    func rebase()
    {
        if let  phase:Float = self.phase,
                phase > 0
        {
            self.view  = Camera.Rig.lerp(self.view, self.base, ViewControl.parameter(phase))
            self.phase = 0
        }

        self.base = self.view
    }
}

struct _Obj
{
    let vbo:GL.Buffer,
        ebo:GL.Buffer,
        vao:GL.VertexArray

    init()
    {
        self.ebo = .generate()
        self.vbo = .generate()
        self.vao = .generate()

        let cube:[Float] =
        [
             -1, -1, -1,
              1, -1, -1,
              1,  1, -1,
             -1,  1, -1,

             -1, -1,  1,
              1, -1,  1,
              1,  1,  1,
             -1,  1,  1,
        ]

        let indices:[UInt32] =
        [
            0, 2, 1,
            0, 3, 2,

            0, 1, 5,
            0, 5, 4,

            1, 2, 6,
            1, 6, 5,

            2, 3, 7,
            2, 7, 6,

            3, 0, 4,
            3, 4, 7,

            4, 5, 6,
            4, 6, 7
        ]

        self.vbo.bind(to: .array)
        {


            $0.data(cube, usage: .static)

            self.vao.bind()
            GL.setVertexLayout(.float(from: .float3))

            self.ebo.bind(to: .elementArray)
            {
                $0.data(indices, usage: .static)
                self.vao.unbind()
            }
        }
    }
}

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
    var size:Math<Int>.V2 = (0, 0)

    private
    var _obj:_Obj,
        _cameraBlock:GL.Buffer,
        view:ViewControl

    init(size:Math<Int>.V2)
    {
        GL.enableDebugOutput()

        self.view = .init(.init(
            pivot: (0, 0, 0),
            angle: (0.25 * Float.pi, 1.75 * Float.pi),
            distance: 3,
            focalLength: 25))

        self._obj    = .init()

        self._cameraBlock = .generate()
        self._cameraBlock.bind(to: .uniform)
        {
            (target:GL.Buffer.BoundTarget) in
            self.view.camera.withUnsafeBytes
            {
                target.reserve($0.count, usage: .dynamic)
            }
        }

        self.resize(to: size)
    }

    mutating
    func resize(to size:Math<Int>.V2)
    {
        // figure out center point of screen
        let sizef:Math<Float>.V2 = Math.castFloat(size),
            shift:Math<Float>.V2 = Math.scale(sizef, by: -0.5)

        let sensor:Math<Float>.Rectangle = (shift, Math.add(sizef, shift))

        self.view.setSensor(sensor)
        self.size = size
        GL.viewport(anchor: (0, 0), size: size)
    }

    private static
    func buttonAction(_ button:MouseButton) -> ViewControl.Action?
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

    mutating
    func press(_ position:Math<Double>.V2, button:MouseButton)
    {
        guard let action:ViewControl.Action = Frame.buttonAction(button)
        else
        {
            return
        }

        self.view.down(Math.castFloat(position), action: action)
    }

    mutating
    func cursor(_ position:Math<Double>.V2)
    {
        self.view.move(Math.castFloat(position))
    }

    mutating
    func release(_ position:Math<Double>.V2, button:MouseButton)
    {
        guard let action:ViewControl.Action = Frame.buttonAction(button)
        else
        {
            return
        }

        self.view.up(Math.castFloat(position), action: action)
    }

    mutating
    func scroll(_ direction:Direction)
    {
        self.view.bump(direction, action: .zoom)
    }

    mutating
    func keypress(_ key:Key)
    {
        switch key
        {
            case .up:
                self.view.bump(.up, action: .track)
            case .down:
                self.view.bump(.down, action: .track)
            case .left:
                self.view.bump(.left, action: .track)
            case .right:
                self.view.bump(.right, action: .track)

            default:
                break
        }
    }

    mutating
    func process(_ δ:Double) -> Bool
    {
        GL.clearColor((0.1, 0.1, 0.1), 1)
        OpenGL.glClearDepth(-1.0)
        GL.clear(color: true, depth: true)

        //GL.enable(.blending)
        GL.enable(.multisampling)
        //GL.blend(.mix)

        OpenGL.glEnable(OpenGL.DEPTH_TEST)
        OpenGL.glDepthFunc(OpenGL.GEQUAL)
        OpenGL.glEnable(OpenGL.CULL_FACE)
        OpenGL.glPolygonMode(OpenGL.FRONT_AND_BACK, OpenGL.FILL)

        self._cameraBlock.bind(to: .uniform, index: 0)
        {
            (target:GL.Buffer.BoundTarget) in

            // check if camera needs updating
            if self.view.next(Float(δ))
            {
                self.view.camera.withUnsafeBytes
                {
                    target.subData($0)
                }
            }

            Programs.sphere.bind
            {
                $0.set(float4: "sphere", (0, 0, 0, 1))
                self._obj.vao.draw(0 ..< 36, as: .triangles)
            }
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
    var frame:Frame

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

        // attach pointer to self to window
        glfwSetWindowUserPointer(window,
            UnsafeMutableRawPointer(Unmanaged<Window>.passUnretained(self).toOpaque()))

        glfwSetFramebufferSizeCallback(window)
        {
            (window:OpaquePointer?, x:CInt, y:CInt) in

            Window.reconstitute(from: window).frame.resize(to: Math.cast((x, y), as: Int.self))
        }

        glfwSetKeyCallback(window)
        {
            (window:OpaquePointer?, keycode:CInt, scancode:CInt, action:CInt, mods:CInt) in

            guard action == GLFW_PRESS
            else
            {
                return
            }

            let key:Frame.Key = .init(keycode)
            Window.reconstitute(from: window).frame.keypress(key)
        }

        glfwSetCursorPosCallback(window)
        {
            (window:OpaquePointer?, x:Double, y:Double) in

            Window.reconstitute(from: window).frame.cursor((x, -y))
        }

        glfwSetMouseButtonCallback(window)
        {
            (window:OpaquePointer?, code:CInt, action:CInt, mods:CInt) in

            let interface:Window = Window.reconstitute(from: window),
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
            glfwGetCursorPos(window, &position.x, &position.y)
            position.y = -position.y

            if action == GLFW_PRESS
            {
                interface.frame.press(position, button: button)
            }
            else // if action == GLFW_RELEASE
            {
                interface.frame.release(position, button: button)
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
            else if x < 0
            {
                interface.frame.scroll(.left)
            }
            else if x > 0
            {
                interface.frame.scroll(.right)
            }
        }
    }

    func loop()
    {
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
        fatalError("glfwInit() failed")
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
            print("(glfw) \(error): \(String(cString: description))")
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
