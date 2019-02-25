struct Camera 
{
    struct Matrices 
    {
        let U:Math<Float>.Mat4, 
            V:Math<Float>.Mat4, 
            F:Math<Float>.Mat3, 
            position:Math<Float>.V3
        
        static 
        let identity:Matrices = .init(
            U: 
            (
                (1, 0, 0, 0), 
                (0, 1, 0, 0), 
                (0, 0, 1, 0), 
                (0, 0, 0, 1)
            ), 
            V: 
            (
                (1, 0, 0, 0), 
                (0, 1, 0, 0), 
                (0, 0, 1, 0), 
                (0, 0, 0, 1)
            ), 
            F: 
            (
                (1, 0, 0), 
                (0, 1, 0), 
                (0, 0, 1)
            ), 
            position: (0, 0, 0)
        )
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
        
        var center:Math<Float>.V3, 
            orientation:Quaternion<Float>, 
            distance:Float,  // negative is outwards, positive is inwards
            focalLength:Float
        
        static 
        func == (a:Rig, b:Rig) -> Bool 
        {
            return  a.center        == b.center && 
                    a.orientation   == b.orientation && 
                    a.distance      == b.distance && 
                    a.focalLength   == b.focalLength
        }
        
        init(center:Math<Float>.V3 = (0, 0, 0), orientation:Quaternion<Float> = .init(), 
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
                    let q:Quaternion<Float>
                    switch direction 
                    {
                        case .up:
                            q = .init(from: (0, 0, 1), to: Math.normalize(( 0,  1, 1)))
                        
                        case .down:
                            q = .init(from: (0, 0, 1), to: Math.normalize(( 0, -1, 1)))
                        
                        case .right:
                            q = .init(from: (0, 0, 1), to: Math.normalize(( 1,  0, 1)))
                        
                        case .left:
                            q = .init(from: (0, 0, 1), to: Math.normalize((-1,  0, 1)))
                    }
                    self.orientation = q * self.orientation
                
                case .track:
                    let factor:Float = 0.1
                    let d:Math<Float>.V3
                    switch direction 
                    {
                        case .up:
                            d = (0,  factor, 0)
                        case .down:
                            d = (0, -factor, 0)
                        case .right:
                            d = ( factor, 0, 0)
                        case .left:
                            d = (-factor, 0, 0)
                    }
                    self.center = Math.add(self.center, self.orientation.rotate(d))
                
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
            return .init(center: Math.lerp(a.center, b.center, t), 
                    orientation: t < 1 ? a.orientation : b.orientation, 
                       distance: Math.lerp(a.distance, b.distance, t), 
                    focalLength: Math.lerp(a.focalLength, b.focalLength, t))
        }
        
        // will rotate the camera (and world) into default position
        private 
        func rotation() -> Math<Float>.Mat3 
        {
            return self.orientation.inverse.matrix
        }
        
        // will translate the camera (and the world) to the origin
        private 
        func translation() -> Math<Float>.V3 
        {
            return Math.neg(Math.add(self.orientation.rotate((0, 0, self.distance)), self.center))
        }
        
        // focal length is 35mm equivalent
        func matrices(frame:Math<Float>.Rectangle, viewport:Math<Float>.V2, clip:Math<Float>.V2) -> Matrices
        {
            // fine size and center of frame 
            let size:Math<Float>.V2     = Math.sub(frame.1, frame.0), 
                center:Math<Float>.V2   = Math.scale(Math.add(frame.0, frame.1), by: 0.5)
            // c = 43.3mm / length(p.xy)
            // f = q / c
            // a.xy = p.xy * a.z / f
            //      = p.xy * a.z * c / q
            //      = p.xy * a.z * 43.3mm / (length(p.xy) * q)
            // where `f` is the physical focal length, `q` is the 35mm equivalent focal 
            // length (units of mm), `p` is a pixel coordinate of a viewport boundary
            // (units of px), and `c` is the crop factor (units of mm)
            let factor:Float = -clip.0 * Math.length((24, 36)) / (self.focalLength * Math.length(size))
            
            let a:Math<Float>.V3 = Math.extend(Math.scale(Math.neg(          center), by: factor), clip.0), 
                b:Math<Float>.V3 = Math.extend(Math.scale(Math.sub(viewport, center), by: factor), clip.1)
            
            let R:Math<Float>.Mat3 = self.rotation(), 
                t:Math<Float>.V3   = self.translation()
            // projection matrix 
            let P:Math<Float>.Mat4 = Rig.projection(a, b)
            
            // view matrix 
            let V:Math<Float>.Mat4 = 
            (
                Math.extend(R.0, 0), 
                Math.extend(R.1, 0), 
                Math.extend(R.2, 0), 
                Math.extend(Math.mult(R, t), 1)
            )
            
            // calculates the `F` (“fragment”) matrix. its purpose is to convert `gl_FragCoord`s 
            // into world space vectors (not necessarily normalized)
            let k:Math<Float>.V2   = Math.div(Math.sub((b.x, b.y), (a.x, a.y)), viewport)
            let F:Math<Float>.Mat3 = 
            (
                Math.scale((R.0.0, R.1.0, R.2.0), by: k.x), 
                Math.scale((R.0.1, R.1.1, R.2.1), by: k.y), 
                (Math.dot(a, R.0), Math.dot(a, R.1), Math.dot(a, R.2))
            )
            
            return .init(U: Math.mult(P, V), V: V, F: F, position: Math.neg(t))
        }
        
        private static  
        func projection(_ a:Math<Float>.V3, _ b:Math<Float>.V3) -> Math<Float>.Mat4
        {
            // `a` and `b` are such that 
            assert(a.x < b.x)
            assert(a.y < b.y)
            assert(b.z < a.z && a.z < 0)
            // the last one may seem weird but it makes more sense when you think 
            // about it like |a.z| < |b.z|
            let scale:Math<Float>.V3 = Math.reciprocal(Math.sub(a, b)), 
                shift:Math<Float>.V3 = Math.neg(Math.mult(Math.add(a, b), scale))
            
            return //         x                   y                     z            w
                (
                    (2 * a.z * scale.x, 0,                  0,                       0), 
                    (0,                 2 * a.z * scale.y,  0,                       0), 
                    (shift.x,           shift.y,            shift.z,                -1), 
                    (0,                 0,                  2 * a.z * b.z * scale.z, 0)
                )
        }
    }
}
