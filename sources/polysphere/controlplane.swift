struct ControlPlane
{
    private 
    enum Validity 
    {
        case invalid, mutated, valid 
    }
    
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
                orbit(Quaternion<Float>, Float, Vector3<Float>, Rayfilm), 
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
    
    private(set)
    var matrices:Camera<Float>.Matrices
        
    private
    var validity:Validity, 
        animation:Transition<Camera<Float>.Rig, Curve.Quadratic>, 
        state:State
    
    var mutated:Bool 
    {
        if case .mutated = self.validity 
        {
            return true 
        }
        else 
        {
            return false 
        }
    }
    
    init(_ base:Camera<Float>.Rig)
    {
        self.matrices   = .identity
        self.validity   = .mutated 
        
        self.animation  = .init(initial: base)
        self.state      = .none 
    }
    
    // project a point into 2D (normalized 0 ... 1 x 0 ... 1 coordinates )
    func trace(_ point:Vector3<Float>) -> Vector2<Float>
    {
        let h:Vector4<Float>    = self.matrices.U >< .extend(point, 1)
        let clip:Vector2<Float> = .init(h.x, h.y) / h.w
        return 0.5 + 0.5 * clip
    }
    
    // rebases to the current animation state and starts the transition timer to 
    // progress to whatever head will be set to
    private mutating 
    func charge(_ body:(inout Camera<Float>.Rig) -> ())
    {
        // if an action is in progress, ignore
        guard case .none = self.state
        else
        {
            return 
        }
        
        self.animation.charge(time: 256, transform: body)
    }
    
    mutating 
    func bump(_ direction:UI.Direction, action:Camera<Float>.Rig.Action)
    {
        self.charge 
        {
            $0.displace(action: action, direction)
        }
    }
    
    mutating 
    func jump(to target:Vector3<Float>)
    {
        self.charge
        {
            $0.center = target 
        } 
    }

    mutating
    func down(_ position:Vector2<Float>, button:UI.Action)
    {
        self.animation.stop()
        self.state = .none 
        switch button
        {
            case .primary:
                let rig:Camera<Float>.Rig = self.animation.current 
                // save the current rayfilm
                let rayfilm:Rayfilm  = self.rayfilm, 
                    ray:Ray          = rayfilm.cast(position), 
                    c:Vector3<Float> = rig.center - ray.source, 
                    l:Float          = c <> ray.vector, 
                    r:Float          = max(1, (c <> c - l * l).squareRoot()), 
                    a:Vector3<Float> = ControlPlane.project(ray: ray, on: rig.center, radius: r)
                self.state = .orbit(rig.orientation, r, (a - rig.center).normalized(), rayfilm)
            
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
            
            case .orbit(let orientation, let r, let anchor, let rayfilm):
                self.animation.charge(time: 0)
                {
                    let ray:Ray             = rayfilm.cast(position), 
                        q:Quaternion<Float> = ControlPlane.attract(anchor, on: $0.center, to: ray, radius: r)
                    $0.orientation          = q.inverse >< orientation
                }
            
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
                self.state = .none
            
            default:
                break
        }
    }
    
    mutating 
    func invalidate() 
    {
        self.validity = .invalid
    }
    
    // returns true if the view system has changed
    mutating
    func process(_ delta:Int, viewport:Vector2<Float>, frame:Rectangle<Float>) -> Bool 
    {
        if self.animation.process(delta) || self.validity == .invalid 
        {
            self.matrices    = self.animation.current.matrices(frame: frame, 
                                                            viewport: viewport, 
                                                                clip: .init(-0.1, -100))
            self.validity    = .mutated  
            return true 
        }
        else 
        {
            return false
        }
    }
    
    mutating 
    func pop() -> Camera<Float>.Matrices? 
    {
        if case .mutated = self.validity 
        {
            self.validity = .valid 
            return self.matrices 
        }
        else 
        {
            return nil 
        }
    }
    
    private static 
    func attract(_ anchor:Vector3<Float>, on center:Vector3<Float>, to ray:Ray, radius r:Float) 
        -> Quaternion<Float>
    {
        let b:Vector3<Float> = project(ray: ray, on: center, radius: r)
        return .init(from: anchor, to: (b - center).normalized())
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
