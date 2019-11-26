extension UI
{
    final 
    class Plane3D
    {
        enum Movement 
        {
            case orbit(Vector2<Float>)
            case jump(Vector3<Float>)
            case jumpRelative(Vector3<Float>)
            case jumpLocal(Vector3<Float>)
            case zoom(UI.Event.Direction.D1)
        }
        
        /* private 
        typealias Update = (frame:Rectangle<Float>, viewport:Vector2<Float>) */
        
        private 
        enum Action
        {
            case none
            case orbit(  orientation:Quaternion<Float>,     // the original orientation of the trackball
                              radius:Float,                 // the original radius of the trackball
                              anchor:Vector3<Float>,        // the part of the trackball clicked 
                             rayfilm:Rayfilm)               // the original configuration of the view plane
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
        
        // UI.Group 
        var state:(focus:Bool, active:Bool, hover:Bool) = (false, false, false)
        //
        
        private(set)
        var matrices:Camera<Float>.Matrices = .identity
        
        private
        var action:Action, 
            animation:Transition<Camera<Float>.Rig, Curve.Quadratic>
        
        init(_ camera:Camera<Float>.Rig)
        {
            self.action     = .none 
            self.animation  = .init(initial: camera)
        }
    }
}

extension UI.Plane3D:UI.Group 
{
    var cursor:(inactive:UI.Cursor, active:UI.Cursor) 
    {
        (.crosshair, .hand)
    }
    
    func contains(_:Vector2<Float>) -> UI.Group?
    {
        return self
    }
    
    func update(_ delta:Int, styles:UI.Styles, viewport:Vector2<Int>, frame:Rectangle<Int>) 
    {
        let viewport:Vector2<Float> = .cast(viewport), 
            frame:Rectangle<Float>  = .cast(frame)
        if  self.animation.process(delta)       || 
            self.matrices.viewport  != viewport || 
            self.matrices.frame     != frame 
        {
            self.matrices    = self.animation.current.matrices(frame: frame, 
                                                            viewport: viewport, 
                                                                clip: .init(-0.1, -100))
        }
    }
     
    func action(_ action:UI.Event.Action)
    {
        let action:UI.Event.Action = action.reflect(vertical: self.matrices.viewport.y)
        switch action 
        {
        case .primary(let s):
            self.move(.orbit(s))
        
        case .secondary(_):
            break 
        
        case .drag(let s):
            guard case .orbit(let orientation, let radius, let anchor, let rayfilm) = self.action 
            else 
            {
                break
            }
            
            self.animation.charge(time: 64)
            {
                let b:Vector3<Float>    = Self.project(ray: rayfilm.cast(s), on: $0.center, radius: radius), 
                    q:Quaternion<Float> = .init(from: anchor, to: (b - $0.center).normalized())
                $0.orientation = q.inverse >< orientation
            } 
        
        case .defocus:
            self.action = .none
            
        case .scroll(let direction):
            switch direction 
            {
            case .up:
                self.move(.zoom(.up))
            case .down:
                self.move(.zoom(.down))
            default:
                break
            }
            
        case .key(.Q, _):
            self.charge
            {
                let q:Quaternion<Float> = .init(axis: .init(0, 0, 1), angle: .pi * 0.33)
                $0.orientation = q >< $0.orientation 
            } 
        case .key(.E, _):
            self.charge
            {
                let q:Quaternion<Float> = .init(axis: .init(0, 0, 1), angle: .pi * -0.33)
                $0.orientation = q >< $0.orientation 
            } 
        
        default:
            break
        }
    }
}
extension UI.Plane3D
{    
    var position:Vector3<Float>
    {
        return self.matrices.position
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
            p:Vector3<Float>    = Self.project(ray: ray, on: center, radius: r)
        return p
    }
    
    private  
    func move(_ movement:Movement) 
    {
        switch movement 
        {
        case .orbit(let s):
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
                                     rayfilm: rayfilm)
        
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
                }
            }
        }
    }
    
    // rebases to the current animation state and starts the transition timer to 
    // progress to whatever head will be set to
    private  
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
