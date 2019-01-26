struct ControlPlane:ViewEquatable
{
    private 
    struct Ray 
    {
        let source:Math<Float>.V3, 
            vector:Math<Float>.V3
    }
    
    private 
    struct Rayfilm 
    {
        let matrix:Math<Float>.Mat3, 
            source:Math<Float>.V3
        
        init(matrix:Math<Float>.Mat3, source:Math<Float>.V3) 
        {
            self.matrix = matrix
            self.source = source
        }
        
        func cast(_ position:Math<Float>.V2) -> Ray
        {
            let vector:Math<Float>.V3 = Math.normalize(Math.mult(self.matrix, Math.extend(position, 1)))
            return .init(source: self.source, vector: vector)
        }
    }
    
    private 
    enum State
    {
        case    none, 
                orbit(Math<Float>.V3, Rayfilm), 
                track(Math<Float>.V3, Rayfilm), 
                zoom(Float)
    }
    
    
    var position:Math<Float>.V3 
    {
        return self.camera.position
    }
    
    private 
    var rayfilm:Rayfilm 
    {
        return .init(matrix: Math.mat3(from: self.camera.F), source: self.camera.position)
    }

    internal private(set)
    var camera:Camera
    
    private
    var head:Camera.Rig,
        base:Camera.Rig, 
        
        state:State, 

        // animation: setting the phase to 0 will immediately update the state to 
        // head while setting it to 1 will allow a transition from base to head
        phase:Float?
        
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
    
    static 
    func viewEquivalent(_ a:ControlPlane, _ b:ControlPlane) -> Bool 
    {
        // self.camera is a cache property for storing animation interpolations 
        // self.state is only used for internal book-keeping
        return  a.head   == b.head && 
                a.base   == b.base && 
                a.phase  == b.phase && 
                a.sensor == b.sensor 
    }
    
    private 
    var mutated:Bool = true
    
    init(_ base:Camera.Rig)
    {
        self.sensor = ((0, 0), (0, 0))
        
        self.camera = .init()
        
        self.head   = base
        self.base   = base
        
        self.state  = .none 
        
        self.phase  = 0
    }
    
    // project a point into 2D (pixel coordinates )
    func trace(_ point:Math<Float>.V3) -> Math<Float>.V2
    {
        let h:Math<Float>.V4    = Math.mult(self.camera.U, Math.extend(point, 1))
        let clip:Math<Float>.V2 = Math.scale((h.x, h.y), by: 1 / h.w) 
        return Math.mult(   Math.sub(self.sensor.b, self.sensor.a), 
                            Math.add(Math.scale(clip, by: 0.5), (0.5, 0.5)))
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
        
        self.base  = self.head
        self.state = .none
    }
    
    // rebases to the current animation state and starts the transition timer to 
    // progress to whatever head will be set to
    private mutating 
    func charge(_ body:(inout Camera.Rig) -> ())
    {
        // if an action is in progress, ignore
        guard case .none = self.state
        else
        {
            return 
        }

        // ordering of operations here is important
        self.rebase()
        self.phase = 1
        body(&self.head)
    }
    
    mutating 
    func bump(_ direction:UI.Direction, action:Camera.Rig.Action)
    {
        self.charge 
        {
            $0.displace(action: action, direction)
        }
    }
    
    mutating 
    func jump(to target:Math<Float>.V3)
    {
        self.charge()
        {
            $0.center = target 
        } 
    }

    mutating
    func down(_ position:Math<Float>.V2, button:UI.Action)
    {
        self.rebase()
        switch (button, self.state) 
        {
            case    (.primary,  .none):
                // save the current rayfilm
                let rayfilm:Rayfilm  = self.rayfilm, 
                    ray:Ray          = rayfilm.cast(position), 
                    c:Math<Float>.V3 = Math.sub(self.base.center, ray.source), 
                    l:Float          = Math.dot(c, ray.vector), 
                    r:Float          = max(1, (Math.eusq(c) - l * l).squareRoot()), 
                    a:Math<Float>.V3 = ControlPlane.project(ray: ray, on: self.base.center, radius: r)
                self.state = .orbit(a, rayfilm)
            
            default:
                break
        }
    }

    mutating
    func move(_ position:Math<Float>.V2)
    {
        switch self.state 
        {
            case .none:
                break 
            
            case .orbit(let anchor, let rayfilm):
                let ray:Ray             = rayfilm.cast(position), 
                    q:Quaternion<Float> = ControlPlane.attract(anchor, on: self.base.center, to: ray)
                
                self.head.orientation = q.inverse * self.base.orientation
                self.phase = 0
            
            default:
                break
        }
    }

    mutating
    func up(_ position:Math<Float>.V2, button:UI.Action)
    {
        self.move(position)
        switch (button, self.state) 
        {
            case    (.primary,  .orbit):
                self.rebase()
            
            default:
                break
        }
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

    // returns true if the view system has changed
    mutating
    func process(_ delta:Int) 
    {
        guard let phase:Float = self.phase
        else
        {
            return
        }

        let decremented:Float = phase - (1 / 64) * Float(delta),
            interpolation:Camera.Rig
        if decremented > 0
        {
            interpolation = self.interpolate(phase: decremented)
            self.phase    = decremented
        }
        else
        {
            interpolation = self.head
            self.phase    = nil
        }
        
        self.updateCamera(interpolation)
        self.mutated = true
    }
    
    private mutating 
    func updateCamera(_ rig:Camera.Rig) 
    {
        let R:Math<Float>.Mat3 = rig.rotationMatrix(), 
            t:Math<Float>.V3   = rig.translation()
        let (a, b):(Math<Float>.V3, Math<Float>.V3) =
            rig.frustum(sensor: self.sensor, clip: (-0.1, -100))

        self.camera.view(rotationMatrix: R, translation: t)
        self.camera.frustum(a, b)
        self.camera.fragment(rotationMatrix: R, translation: t, sensor: self.sensor)
        self.camera.matrices()
    }
    
    mutating 
    func pop() -> Camera? 
    {
        if self.mutated 
        {
            self.mutated = false 
            return self.camera 
        }
        else 
        {
            return nil
        }
    }
    
    private static 
    func attract(_ anchor:Math<Float>.V3, on center:Math<Float>.V3, to ray:Ray) 
        -> Quaternion<Float>
    {
        let a:Math<Float>.V3 = Math.sub(anchor, center), 
            r:Float          = Math.length(a), 
            s:Math<Float>.V3 = Math.scale(a, by: 1 / r), 
            t:Math<Float>.V3 = Math.normalize(Math.sub(project(ray: ray, on: center, radius: r), center))
        
        return .init(from: s, to: t)
    }
    
    private static 
    func project(ray:Ray, on center:Math<Float>.V3, radius r:Float) -> Math<Float>.V3
    {
        // need to deal with case of sphere not centered at origin
        let c:Math<Float>.V3 = Math.sub(center, ray.source), 
            l:Float          = Math.dot(c, ray.vector)
        
        let discriminant:Float = r * r + l * l - Math.eusq(c)
        guard discriminant >= 0 
        else 
        {
            // sin(C - B - A)   = sin C cos -B cos -A + sin -B cos -A cos C + sin -A cos C cos -B - sin C sin -B sin -A
            //                  = sin C cos B cos A - sin B cos A cos C - sin A cos C cos B - sin C sin B sin A
            // sin(π - B - A)   = sin π cos B cos A - sin B cos A cos π - sin A cos π cos B - sin π sin B sin A
            //                  = sin B cos A + sin A cos B
            //            sin C = sin B cos A + sin A cos B
            //                  = sqrt(1 - cos^2 B) cos A + sqrt(1 - cos^2 A) cos B
            
            //            sin A = h / c 
            //                  = sqrt(c^2 - r^2) / c
            //                a = c sin A / sin C
            //                  = c sin A / (sin B cos A + sin A cos B)
            // 
            // this is numerically stable for A, B >> 0, which will be satisfied so long 
            // as the camera is not too far from the planet that the disk reduces to a point.
            let d2:Float = Math.eusq(c), 
                h:Float  = (d2 - r * r).squareRoot(), 
                g:Float  = Math.dot(Math.normalize(c), ray.vector)
            
            let a:Float  = d2.squareRoot() * h / (r * (1 - g * g).squareRoot() + g * h)
            return Math.add(ray.source, Math.scale(ray.vector, by: a))
        }
        
        let offset:Math<Float>.V3 = Math.scale(ray.vector, by: l - discriminant.squareRoot())
        return Math.add(ray.source, offset)
    }
    
    func project(_ position:Math<Float>.V2, on center:Math<Float>.V3, radius r:Float) -> Math<Float>.V3
    {
        let ray:Ray             = self.rayfilm.cast(position), 
            p:Math<Float>.V3    = ControlPlane.project(ray: ray, on: center, radius: r)
        return p
    }
}
