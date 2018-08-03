enum Direction
{
    case up, down, left, right
}

struct ControlPlane
{
    struct Ray 
    {
        let source:Math<Float>.V3, 
            vector:Math<Float>.V3
    }
    
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
            if self.phase == nil 
            {
                self.phase = 0
            }
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
    
    private static 
    func displace(_ displacement:Math<Float>.V2, action:Action, base:Camera.Rig, head:inout Camera.Rig)
    {
        switch action
        {
            case .pan:
                let delta:Math<Float>.V2 = Math.scale(displacement, by: -1/128)
                head.angle.φ =            base.angle.φ + delta.x
                head.angle.θ = max(0, min(base.angle.θ - delta.y, Float.pi))

            case .track:
                let delta:Math<Float>.V2 = Math.scale(displacement, by: -1/128)
                let basis:Math<Math<Float>.V3>.V3 = base.basis()

                head.pivot = Math.add(base.pivot,
                    (Math.dot(delta, (basis.x.x, basis.y.x)),
                     Math.dot(delta, (basis.x.y, basis.y.y)),
                     Math.dot(delta, (basis.x.z, basis.y.z))))

            case .zoom:
                let delta:Float = -1/8 * displacement.y
                head.focalLength = max(8, head.focalLength + delta)
        }
    }
    private mutating 
    func displace(_ displacement:Math<Float>.V2, action:Action)
    {
        ControlPlane.displace(displacement, action: action, base: self.base, head: &self.head)
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
    
    // rebases to the current animation state and starts the transition timer to 
    // progress to whatever head will be set to
    private mutating 
    func charge(_ body:(Camera.Rig, inout Camera.Rig) -> ())
    {
        // if an action is in progress, ignore
        guard self.anchor == nil
        else
        {
            return 
        }

        // ordering of operations here is important
        self.rebase()
        self.phase = 1
        body(self.base, &self.head)
    }
    
    mutating
    func bump(_ direction:Direction, action:Action)
    {        
        let displacement:Math<Float>.V2
        switch direction 
        {
            // a bump is kind of like pushing off into the opposite direction
            case .up:
            displacement = (  0, -64)
            
            case .down:
            displacement = (  0,  64)
            
            case .left:
            displacement = ( 64,   0)
            
            case .right:
            displacement = (-64,   0)
        }
        
        self.charge 
        {
            ControlPlane.displace(displacement, action: action, base: $0, head: &$1)
        }
    }
    
    mutating 
    func jump(to target:Math<Float>.V3)
    {
        self.charge()
        {
            $1.pivot = target 
        } 
    }

    mutating
    func down(_ position:Math<Float>.V2, action:Action)
    {
        // if another action is in progress, end it 
        if let anchor:Anchor = self.anchor 
        {
            self.release(position, anchor: anchor)
        }
        
        self.rebase()
        self.anchor = .init(base: position, action: action)
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
        guard let anchor:Anchor = self.anchor, 
                  anchor.action == action
        else
        {
            Log.warning("control up event recieved, but no corresponding down event was recieved")
            return
        }
        
        self.release(position, anchor: anchor)
    }
    
    private mutating 
    func release(_ position:Math<Float>.V2, anchor:Anchor)
    {
        self.displace(Math.sub(position, anchor.base), action: anchor.action)
        self.phase  = 0
        self.anchor = nil
    }

    // returns true if the view system has changed
    mutating
    func next(_ delta:Float) -> Bool
    {
        guard let phase:Float = self.phase
        else
        {
            return false
        }

        let decremented:Float = phase - delta * 5,
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
    
    func raycast(_ position:Math<Float>.V2) -> Ray
    {
        let F:Math<Float>.Mat3 = Math.mat3(from: self.camera.F)
        let vector:Math<Float>.V3 = Math.normalize(Math.mult(F, Math.homogenize(position)))
        return .init(source: self.camera.position, vector: vector)
    }
}
