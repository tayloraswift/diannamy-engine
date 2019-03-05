struct Camera 
{
    struct Matrices 
    {
        let U:Matrix4<Float>, 
            V:Matrix4<Float>, 
            F:Matrix3<Float>, 
            position:Vector3<Float>
        
        static 
        let identity:Matrices = .init(U: .identity, V: .identity, F: .identity, position: .zero)
    }
    
    struct Rig:Equatable
    {
        enum Action 
        {
            case    orbit, 
                    track, 
                    approach, 
                    zoom 
        }
        
        var center:Vector3<Float>, 
            orientation:Quaternion<Float>, 
            distance:Float,  // negative is outwards, positive is inwards
            focalLength:Float
        
        init(center:Vector3<Float> = .zero, orientation:Quaternion<Float> = .identity, 
            distance:Float = 0, focalLength:Float = 35)
        {
            self.center      = center
            self.orientation = orientation
            self.distance    = distance
            self.focalLength = focalLength
        }
        
        mutating 
        func displace(action:Action, _ direction:UI.Direction)
        {
            switch action
            {
                case .orbit:
                    let t:Vector3<Float> 
                    switch direction 
                    {
                        case .up:
                            t = .init( 0,  1, 1)
                        
                        case .down:
                            t = .init( 0, -1, 1)
                        
                        case .right:
                            t = .init( 1,  0, 1)
                        
                        case .left:
                            t = .init(-1,  0, 1)
                    }
                    
                    let q:Quaternion<Float> = .init(from: .init(0, 0, 1), to: t.normalized())
                    self.orientation = q >< self.orientation
                
                case .track:
                    let factor:Float = 0.1
                    let d:Vector3<Float> 
                    switch direction 
                    {
                        case .up:
                            d = .init(0,  factor, 0)
                        case .down:
                            d = .init(0, -factor, 0)
                        case .right:
                            d = .init( factor, 0, 0)
                        case .left:
                            d = .init(-factor, 0, 0)
                    }
                    self.center += self.orientation.rotate(d)
                
                case .approach:
                    break 
                
                case .zoom:
                    switch direction 
                    {
                        case .up:
                            self.focalLength =         self.focalLength + 10
                        
                        case .down:
                            self.focalLength = max(20, self.focalLength - 10)
                        
                        default:
                            break
                    }
                    
                    self.focalLength.round()
            }
        }
        
        static 
        func lerp(_ a:Rig, _ b:Rig, _ t:Float) -> Rig 
        {
            // need slerp for orientation
            return .init(center: .lerp(a.center, b.center, t), 
                    orientation: t < 1 ? a.orientation : b.orientation, 
                       distance: .lerp(a.distance, b.distance, t), 
                    focalLength: .lerp(a.focalLength, b.focalLength, t))
        }
        
        // will rotate the camera (and world) into default position
        private 
        func rotation() -> Matrix3<Float> 
        {
            return self.orientation.inverse.matrix
        }
        
        // will translate the camera (and the world) to the origin
        private 
        func translation() -> Vector3<Float> 
        {
            return -self.orientation.rotate(.extend(.zero, self.distance)) - self.center
        }
        
        // focal length is 35mm equivalent
        func matrices(frame:Rectangle<Float>, viewport:Vector2<Float>, clip:Vector2<Float>) -> Matrices
        {
            // center of frame 
            let center:Vector2<Float> = frame.midpoint
            // c = 43.3mm / length(p.xy)
            // f = q / c
            // a.xy = p.xy * a.z / f
            //      = p.xy * a.z * c / q
            //      = p.xy * a.z * 43.3mm / (length(p.xy) * q)
            // where `f` is the physical focal length, `q` is the 35mm equivalent focal 
            // length (units of mm), `p` is a pixel coordinate of a viewport boundary
            // (units of px), and `c` is the crop factor (units of mm)
            let reference35:Vector2<Float>  = .init(24, 36), 
                factor:Float = -clip.x * reference35.length / (self.focalLength * frame.size.length)
            
            let a:Vector3<Float> = .extend(           -center  * factor, clip.x), 
                b:Vector3<Float> = .extend((viewport - center) * factor, clip.y)
            
            let R:Matrix3<Float> = self.rotation(), 
                t:Vector3<Float> = self.translation()
            // projection matrix 
            let P:Matrix4<Float> = Rig.projection(a, b)
            
            // view matrix 
            let V:Matrix4<Float> = .init(
                .extend(R[0], 0), 
                .extend(R[1], 0), 
                .extend(R[2], 0), 
                .extend(R >< t,      1)
            )
            
            // calculates the `F` (“fragment”) matrix. its purpose is to convert `gl_FragCoord`s 
            // into world space vectors (not necessarily normalized)
            let k:Vector2<Float>  = (b.xy - a.xy) / viewport
            let S:Matrix3<Float>  = R.transposed
            let v0:Vector3<Float> = k.x * S[0], 
                v1:Vector3<Float> = k.y * S[1], 
                v2:Vector3<Float> = a.z * S[2] + a.y * S[1] + a.x * S[0]
            let F:Matrix3<Float>  = .init(v0, v1, v2)
            
            return .init(U: P >< V, V: V, F: F, position: -t)
        }
        
        private static  
        func projection(_ a:Vector3<Float>, _ b:Vector3<Float>) -> Matrix4<Float>
        {
            // `a` and `b` are such that 
            assert(a.x < b.x)
            assert(a.y < b.y)
            assert(b.z < a.z && a.z < 0)
            // the last one may seem weird but it makes more sense when you think 
            // about it like |a.z| < |b.z|
            let scale:Vector3<Float> = 1 / (a - b), 
                shift:Vector3<Float> = -scale * (a + b)
            //                                     x                   y                     z            w
            let v0:Vector4<Float> = .init(2 * a.z * scale.x, 0,                  0,                       0), 
                v1:Vector4<Float> = .init(0,                 2 * a.z * scale.y,  0,                       0), 
                v2:Vector4<Float> = .init(shift.x,           shift.y,            shift.z,                -1), 
                v3:Vector4<Float> = .init(0,                 0,                  2 * a.z * b.z * scale.z, 0)
            return .init(v0, v1, v2, v3)
        }
    }
}
