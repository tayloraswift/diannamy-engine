struct UI 
{
    enum Direction
    {
        case up, down, left, right
    }
    
    enum Action 
    {
        case double, primary, secondary, tertiary
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
    
    enum Mode 
    {
    }
    
    enum Lazy<T> 
    {
        case mutated(T), invariant
        
        mutating 
        func push(_ value:T) 
        {
            self = .mutated(value)
        }
        
        mutating 
        func pop() -> T? 
        {
            switch self 
            {
                case .mutated(let value):
                    self = .invariant
                    return value 
                
                case .invariant:
                    return nil
            }
        }
    }
    
    
    private 
    var _interface:Controller.Geo, 
        _scene:Controller.Geo.Scene, 
        
        plane:ControlPlane, 
        cameraBlock:GL.Buffer<Camera.Storage>, 
        
        _view:View.Geo
        
    init()
    {
        let sphere:Sphere = .init([(0, 1, 1), (-1, -1, 1), (1, -1, 1)].map(Math.normalize(_:)))
        self._interface   = .init(sphere: sphere)
        self._scene       = .init(sphere: sphere)
        
        self.plane = .init(.init(
            pivot: (0, 0, 0),
            angle: (0.25 * Float.pi, 1.75 * Float.pi),
            distance: 4,
            focalLength: 32))
        
        self.cameraBlock = .generate()
        self.cameraBlock.bind(to: .uniform)
        {
            $0.reserve(capacity: 1, usage: .dynamic)
        }
        
        self._view = .init()
    }

    mutating
    func resize(to size:Math<Float>.V2)
    {
        // figure out center point of screen
        let shift:Math<Float>.V2 = Math.scale(size, by: -0.5)
        self.plane.sensor = (shift, Math.add(size, shift))
        
        GL.viewport(anchor: (0, 0), size: Math.cast(size, as: Int.self))
    }
    
    mutating 
    func down(_ position:Math<Float>.V2, action:Action)
    {
        assert(self._interface.down(position, action: action, 
            scene: &self._scene, plane: &self.plane) == nil)
    }
    
    mutating 
    func move(_ position:Math<Float>.V2)
    {
        self._interface.move(position, scene: &self._scene, plane: &self.plane)
    }
    
    mutating 
    func up(_ position:Math<Float>.V2, action:Action)
    {
        self._interface.up(position, action: action, scene: &self._scene, plane: &self.plane)
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
    func process(_ delta:Float) -> Bool
    {
        GL.clear(color: true, depth: true)

        self.cameraBlock.bind(to: .uniform, index: 0)
        {
            (target:GL.Buffer.BoundTarget) in

            // check if camera needs updating
            if self.plane.next(delta)
            {
                self.plane.camera.withUnsafeBytes
                {
                    target.subData($0)
                }
            }
            
            // rebuild the scene 
            self._view.rebuild(from: &self._scene)
            self._view.draw()
        }

        return true
    }
}
