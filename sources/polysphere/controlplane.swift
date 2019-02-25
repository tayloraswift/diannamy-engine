struct ControlPlane
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
        return self.matrices.position
    }
    
    private 
    var rayfilm:Rayfilm 
    {
        return .init(matrix: self.matrices.F, source: self.matrices.position)
    }

    internal private(set)
    var matrices:Camera.Matrices
    
    private
    var head:Camera.Rig,
        base:Camera.Rig, 
        
        state:State, 

        // animation: setting the phase to 0 will immediately update the state to 
        // head while setting it to 1 will allow a transition from base to head
        phase:Float?
    
    mutating 
    func queueUpdate() 
    {
        if self.phase == nil 
        {
            self.phase = 0
        }
    }
    
    private(set)
    var mutated:Bool = true
    
    init(_ base:Camera.Rig)
    {
        self.matrices   = .identity
        
        self.head       = base
        self.base       = base
        
        self.state      = .none 
        
        self.phase      = 0
    }
    
    // project a point into 2D (normalized 0 ... 1 x 0 ... 1 coordinates )
    func trace(_ point:Math<Float>.V3) -> Math<Float>.V2
    {
        let h:Math<Float>.V4    = Math.mult(self.matrices.U, Math.extend(point, 1))
        let clip:Math<Float>.V2 = Math.scale((h.x, h.y), by: 1 / h.w) 
        return Math.add(Math.scale(clip, by: 0.5), (0.5, 0.5))
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
    func process(_ delta:Int, viewport:Math<Float>.V2, frame:Math<Float>.Rectangle) -> Bool 
    {
        guard let phase:Float = self.phase
        else
        {
            return self.mutated
        }

        let decremented:Float = phase - (1.0 / 250.0) * .init(delta),
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
        
        self.updateMatrices(interpolation, viewport: viewport, frame: frame)
        return self.mutated
    }
    
    private mutating 
    func updateMatrices(_ rig:Camera.Rig, viewport:Math<Float>.V2, frame:Math<Float>.Rectangle) 
    {
        self.matrices = rig.matrices(frame: frame, viewport: viewport, clip: (-0.1, -100))
        self.mutated  = true
    }
    
    mutating 
    func pop() -> Camera.Matrices? 
    {
        if self.mutated 
        {
            self.mutated = false 
            return self.matrices
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
