struct Camera<F> where F:FloatingPoint & ExpressibleByFloatLiteral & Mathematical & SIMDScalar
{
    struct Matrices 
    {
        let U:Matrix4<F>, 
            V:Matrix4<F>, 
            F:Matrix3<F>, 
            position:Vector3<F>, 
            
            frame:Rectangle<F>, 
            viewport:Vector2<F>
        
        static 
        var identity:Matrices 
        {
            return .init(U: .identity, V: .identity, F: .identity, 
                position: .zero, frame: .zero, viewport: .zero)
        }
    }
    
    struct Rig:Equatable, Interpolable
    {        
        var center:Vector3<F>, 
            orientation:Quaternion<F>, 
            distance:F,  // negative is outwards, positive is inwards
            focalLength:F
        
        init(center:Vector3<F> = .zero, orientation:Quaternion<F> = .identity, 
            distance:F = 0, focalLength:F = 35)
        {
            self.center      = center
            self.orientation = orientation
            self.distance    = distance
            self.focalLength = focalLength
        }
        
        static 
        func interpolate(_ a:Camera<F>.Rig, _ b:Camera<F>.Rig, by t:F) -> Camera<F>.Rig
        {
            return .init(center: .interpolate(a.center,      b.center,      by: t), 
                    orientation: .interpolate(a.orientation, b.orientation, by: t), 
                       distance: .interpolate(a.distance,    b.distance,    by: t),
                    focalLength: .interpolate(a.focalLength, b.focalLength, by: t))
        }
        
        // will rotate the camera (and world) into default position
        private 
        func rotation() -> Matrix3<F> 
        {
            return self.orientation.inverse.matrix
        }
        
        // will translate the camera (and the world) to the origin
        private 
        func translation() -> Vector3<F> 
        {
            return -self.orientation.rotate(.extend(.zero, self.distance)) - self.center
        }
        
        // focal length is 35mm equivalent
        func matrices(frame:Rectangle<F>, viewport:Vector2<F>, clip:Vector2<F>) -> Matrices
        {
            // center of frame 
            let center:Vector2<F> = frame.midpoint
            // c = 43.3mm / length(p.xy)
            // f = q / c
            // a.xy = p.xy * a.z / f
            //      = p.xy * a.z * c / q
            //      = p.xy * a.z * 43.3mm / (length(p.xy) * q)
            // where `f` is the physical focal length, `q` is the 35mm equivalent focal 
            // length (units of mm), `p` is a pixel coordinate of a viewport boundary
            // (units of px), and `c` is the crop factor (units of mm)
            let reference35:Vector2<F> = .init(24, 36), 
                factor:F = -clip.x * reference35.length / (self.focalLength * frame.size.length)
            
            let a:Vector3<F> = .extend(           -center  * factor, clip.x), 
                b:Vector3<F> = .extend((viewport - center) * factor, clip.y)
            
            let R:Matrix3<F> = self.rotation(), 
                t:Vector3<F> = self.translation()
            // projection matrix 
            let P:Matrix4<F> = Rig.projection(a, b)
            
            // view matrix 
            let V:Matrix4<F> = .init(
                .extend(R[0], 0), 
                .extend(R[1], 0), 
                .extend(R[2], 0), 
                .extend(R >< t,      1)
            )
            
            // calculates the `F` (“fragment”) matrix. its purpose is to convert `gl_FragCoord`s 
            // into world space vectors (not necessarily normalized)
            let k:Vector2<F>  = (b.xy - a.xy) / viewport
            let S:Matrix3<F>  = R.transposed
            let v0:Vector3<F> = k.x * S[0], 
                v1:Vector3<F> = k.y * S[1], 
                v2:Vector3<F> = a.z * S[2] + a.y * S[1] + a.x * S[0]
            let F:Matrix3<F>  = .init(v0, v1, v2)
            
            return .init(U: P >< V, V: V, F: F, position: -t, frame: frame, viewport: viewport)
        }
        
        private static  
        func projection(_ a:Vector3<F>, _ b:Vector3<F>) -> Matrix4<F>
        {
            // `a` and `b` are such that 
            assert(a.x < b.x)
            assert(a.y < b.y)
            assert(b.z < a.z && a.z < 0)
            // the last one may seem weird but it makes more sense when you think 
            // about it like |a.z| < |b.z|
            let scale:Vector3<F> = 1 / (a - b), 
                shift:Vector3<F> = -scale * (a + b)
            //                                 x                   y                     z            w
            let v0:Vector4<F> = .init(2 * a.z * scale.x, 0,                  0,                       0), 
                v1:Vector4<F> = .init(0,                 2 * a.z * scale.y,  0,                       0), 
                v2:Vector4<F> = .init(shift.x,           shift.y,            shift.z,                -1), 
                v3:Vector4<F> = .init(0,                 0,                  2 * a.z * b.z * scale.z, 0)
            return .init(v0, v1, v2, v3)
        }
    }
}
