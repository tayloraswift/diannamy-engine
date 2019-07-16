enum Display
{
    struct Plane3D 
    {
        enum Movement 
        {
            case orbit(Vector2<Float>, confirmation:UI.Event.Confirmation)
            case jump(Vector3<Float>)
            case jumpRelative(Vector3<Float>)
            case jumpLocal(Vector3<Float>)
            case zoom(UI.Event.Direction)
        }
        
        private 
        typealias Update = (frame:Rectangle<Float>, viewport:Vector2<Float>)
        
        private 
        enum Action
        {
            case none
            case orbit(  orientation:Quaternion<Float>,     // the original orientation of the trackball
                              radius:Float,                 // the original radius of the trackball
                              anchor:Vector3<Float>,        // the part of the trackball clicked 
                             rayfilm:Rayfilm,               // the original configuration of the view plane
                        confirmation:UI.Event.Confirmation) // the event to watch for to end the action
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
        
        @State private(set)
        var matrices:Camera<Float>.Matrices = .identity
        
        private
        var update:Update?, 
            action:Action, 
            animation:Transition<Camera<Float>.Rig, Curve.Quadratic>
    }
}

extension Display.Plane3D
{
    init(_ camera:Camera<Float>.Rig)
    {
        self.update     = nil   
        self.action     = .none 
        self.animation  = .init(initial: camera)
    }
    
    var position:Vector3<Float>
    {
        return self.matrices.position
    }
    
    var frame:Rectangle<Float> 
    {
        get 
        {
            self.update?.frame ?? self.matrices.frame
        }
        set(frame) 
        {
            self.update = (frame, self.viewport)
        }
    } 
    var viewport:Vector2<Float> 
    {
        get 
        {
            self.update?.viewport ?? self.matrices.viewport
        }
        set(viewport) 
        {
            self.update = (self.frame, viewport)
        }
    } 
    
    private 
    var rayfilm:Rayfilm 
    {
        return .init(matrix: self.matrices.F, source: self.matrices.position)
    }
    
    // project a point into 2D (normalized 0 ... 1 x 0 ... 1 coordinates )
    func trace(_ point:Vector3<Float>) -> Vector2<Float>
    {
        let h:Vector4<Float>    = self.matrices.U >< .extend(point, 1), 
            clip:Vector2<Float> = .init(h.x, h.y) / h.w
        return 0.5 + 0.5 * clip
    }
    
    func project(_ position:Vector2<Float>, on center:Vector3<Float>, radius r:Float) -> Vector3<Float>
    {
        let ray:Ray             = self.rayfilm.cast(position), 
            p:Vector3<Float>    = ControlPlane.project(ray: ray, on: center, radius: r)
        return p
    }
    
    
    // returns true if the view system has changed
    mutating
    func process(_ delta:Int) // -> Bool 
    {
        if self.animation.process(delta) || self.update != nil 
        {
            self.matrices    = self.animation.current.matrices(frame: self.frame, 
                                                            viewport: self.viewport, 
                                                                clip: .init(-0.1, -100))
            // return true 
        }
        else 
        {
            // return false
        }
    }
    
    mutating 
    func move(_ movement:Movement) 
    {
        switch movement 
        {
        case .orbit(let s, let confirmation):
            self.animation.stop()
            let rig:Camera<Float>.Rig = self.animation.current 
            // save the current rayfilm
            let rayfilm:Rayfilm  = self.rayfilm, 
                ray:Ray          = rayfilm.cast(s), 
                c:Vector3<Float> = rig.center - ray.source, 
                l:Float          = c <> ray.vector, 
                r:Float          = max(1, (c <> c - l * l).squareRoot()), 
                a:Vector3<Float> = Self.project(ray: ray, on: rig.center, radius: r)
            self.action = .orbit(orientation: rig.orientation, 
                                      radius: r, 
                                      anchor: (a - rig.center).normalized(), 
                                     rayfilm: rayfilm, 
                                confirmation: confirmation)
        
        case .jump(let target):
            self.charge
            {
                $0.center = target 
            } 
        
        case .jumpRelative(let displacement):
            self.charge
            {
                $0.center += displacement 
            } 
        
        case .jumpLocal(let displacement):
            self.charge
            {
                $0.center += $0.orientation.rotate(0.1 * displacement)
            } 
        
        case .zoom(let direction):
            self.charge
            {
                switch direction 
                {
                case .up:
                    $0.focalLength =         $0.focalLength + 10
                case .down:
                    $0.focalLength = max(20, $0.focalLength - 10)
                default:
                    break
                }
            }
        }
    }
    
    // rebases to the current animation state and starts the transition timer to 
    // progress to whatever head will be set to
    private mutating 
    func charge(_ body:(inout Camera<Float>.Rig) -> ())
    {
        // if an action is in progress, ignore
        guard case .none = self.action 
        else
        {
            return 
        }
        
        self.animation.charge(time: 256, transform: body)
    }

    // to *trigger* an action, have the caller sort the event, and call the `move(_:)` 
    // method directly.
    mutating 
    func event(_ event:UI.Event, pass _:UI.Event.Pass) -> Bool 
    {
        switch self.action 
        {
        case .none:
            return false 
        
        case .orbit(let orientation, let radius, let anchor, let rayfilm, let confirmation):
            switch event 
            {
            case .enter(let s):
                self.animation.charge(time: 0)
                {
                    let b:Vector3<Float>    = Self.project(ray: rayfilm.cast(s), on: $0.center, radius: radius), 
                        q:Quaternion<Float> = .init(from: anchor, to: (b - $0.center).normalized())
                    $0.orientation = q.inverse >< orientation
                } 
            
            case .leave:
                self.action = .none 
                        
            default:
                break 
            }
            
            if confirmation ~= event 
            {
                self.action = .none 
            }
            
            return true 
        }
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
}
