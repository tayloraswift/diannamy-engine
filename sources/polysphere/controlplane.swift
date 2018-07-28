enum Direction
{
    case up, down, left, right
}

struct ControlPlane
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
    
    var sensor:Math<Float>.Rectangle
    {
        didSet 
        {
            self.phase = 0
        }
    }

    internal private(set)
    var camera:Camera

    private
    var head:Camera.Rig,
        base:Camera.Rig,
        
        anchor:Anchor? = nil,

        // animation: setting the phase to 0 will immediately update the state to 
        // head while setting it to 1 will allow a transition from base to head
        phase:Float?

    init(_ base:Camera.Rig)
    {
        self.head = base
        self.base = base

        self.camera = .init()
        self.sensor = ((0, 0), (0, 0))
        self.phase  = 0
    }
    
    private static
    func parameter(_ x:Float) -> Float
    {
        // x from 0 to 1
        return x * x
    }
    
    private 
    func interpolate(phase:Float) -> Camera.Rig 
    {
        return Camera.Rig.lerp(self.head, self.base, ControlPlane.parameter(phase))
    }
    
    private mutating 
    func displace(_ displacement:Math<Float>.V2, action:Action)
    {
        switch action
        {
            case .pan:
                let delta:Math<Float>.V2 = Math.scale(displacement, by: 1/128)
                self.head.angle.φ =            self.base.angle.φ - delta.x
                self.head.angle.θ = max(0, min(self.base.angle.θ + delta.y, Float.pi))

            case .track:
                let delta:Math<Float>.V2 = Math.scale(displacement, by: 1/128)
                let basis:Math<Math<Float>.V3>.V3 = self.base.basis()

                self.head.pivot = Math.add(self.base.pivot,
                    (Math.dot(delta, (basis.x.x, basis.y.x)),
                     Math.dot(delta, (basis.x.y, basis.y.y)),
                     Math.dot(delta, (basis.x.z, basis.y.z))))

            case .zoom:
                let delta:Float = 1/8 * displacement.y
                self.head.focalLength = max(8, self.head.focalLength + delta)
        }
    }

    // kills any current animation and synchronizes the 2 current keyframes
    private mutating
    func rebase()
    {
        if let  phase:Float = self.phase,
                phase > 0
        {
            self.head  = self.interpolate(phase: phase)
            self.phase = 0
        }

        self.base = self.head
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

        self.displace(Math.sub(position, anchor.base), action: anchor.action)
        self.phase = 0
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

        self.displace(Math.sub(position, anchor.base), action: anchor.action)
        self.phase  = 0
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
        
        let displacement:Math<Float>.V2
        switch direction 
        {
            case .up:
                displacement = (  0,  64)
            
            case .down:
                displacement = (  0, -64)
            
            case .left:
                displacement = (-64,   0)
            
            case .right:
                displacement = ( 64,   0)
        }
        
        self.displace(displacement, action: action)
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
            interpolation = self.interpolate(phase: decremented)
            self.phase = decremented
        }
        else
        {
            interpolation = self.head
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
}
