struct ControlPlane
{
    private 
    struct Ray 
    {
        let source:Vector3<Float>, 
            vector:Vector3<Float>
    }
    
    private 
    struct Rayfilm 
    {
        let matrix:Matrix3<Float>, 
            source:Vector3<Float>
        
        init(matrix:Matrix3<Float>, source:Vector3<Float>) 
        {
            self.matrix = matrix
            self.source = source
        }
        
        func cast(_ position:Vector2<Float>) -> Ray
        {
            let vector:Vector3<Float> = (self.matrix >< .extend(position, 1)).normalized()
            return .init(source: self.source, vector: vector)
        }
    }
    
    private 
    enum State
    {
        case    none, 
                orbit(Vector3<Float>, Rayfilm), 
                track(Vector3<Float>, Rayfilm), 
                zoom(Float)
    }
    
    
    var position:Vector3<Float>
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
    func trace(_ point:Vector3<Float>) -> Vector2<Float>
    {
        let h:Vector4<Float>    = self.matrices.U >< .extend(point, 1)
        let clip:Vector2<Float> = .init(h.x, h.y) / h.w
        return 0.5 + 0.5 * clip
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
    func jump(to target:Vector3<Float>)
    {
        self.charge()
        {
            $0.center = target 
        } 
    }

    mutating
    func down(_ position:Vector2<Float>, button:UI.Action)
    {
        self.rebase()
        switch (button, self.state) 
        {
            case    (.primary,  .none):
                // save the current rayfilm
                let rayfilm:Rayfilm  = self.rayfilm, 
                    ray:Ray          = rayfilm.cast(position), 
                    c:Vector3<Float> = self.base.center - ray.source, 
                    l:Float          = c <> ray.vector, 
                    r:Float          = max(1, (c <> c - l * l).squareRoot()), 
                    a:Vector3<Float> = ControlPlane.project(ray: ray, on: self.base.center, radius: r)
                self.state = .orbit(a, rayfilm)
            
            default:
                break
        }
    }

    mutating
    func move(_ position:Vector2<Float>)
    {
        switch self.state 
        {
            case .none:
                break 
            
            case .orbit(let anchor, let rayfilm):
                let ray:Ray             = rayfilm.cast(position), 
                    q:Quaternion<Float> = ControlPlane.attract(anchor, on: self.base.center, to: ray)
                
                self.head.orientation = q.inverse >< self.base.orientation
                self.phase = 0
            
            default:
                break
        }
    }

    mutating
    func up(_ position:Vector2<Float>, button:UI.Action)
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
    func process(_ delta:Int, viewport:Vector2<Float>, frame:Rectangle<Float>) -> Bool 
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
    func updateMatrices(_ rig:Camera.Rig, viewport:Vector2<Float>, frame:Rectangle<Float>) 
    {
        self.matrices = rig.matrices(frame: frame, viewport: viewport, clip: .init(-0.1, -100))
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
    func attract(_ anchor:Vector3<Float>, on center:Vector3<Float>, to ray:Ray) 
        -> Quaternion<Float>
    {
        let a:Vector3<Float> = anchor - center, 
            r:Float          = a.length, 
            b:Vector3<Float> = project(ray: ray, on: center, radius: r) - center
        
        return .init(from: a / r, to: b.normalized())
    }
    
    private static 
    func project(ray:Ray, on center:Vector3<Float>, radius r:Float) -> Vector3<Float>
    {
        // need to deal with case of sphere not centered at origin
        let c:Vector3<Float>    = center - ray.source, 
            l:Float             = c <> ray.vector
        
        let a:Float 
        
        let c2:Float            = c <> c
        let discriminant:Float  = r * r + l * l - c2
        if discriminant < 0 
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
            let h:Float  = (c2 - r * r).squareRoot(), 
                g:Float  = c.normalized() <> ray.vector
                
            a = c2.squareRoot() * h / (r * (1 - g * g).squareRoot() + g * h)
        }
        else 
        {
            a = l - discriminant.squareRoot()
        }
        
        return ray.source + a * ray.vector
    }
    
    func project(_ position:Vector2<Float>, on center:Vector3<Float>, radius r:Float) -> Vector3<Float>
    {
        let ray:Ray             = self.rayfilm.cast(position), 
            p:Vector3<Float>    = ControlPlane.project(ray: ray, on: center, radius: r)
        return p
    }
}
