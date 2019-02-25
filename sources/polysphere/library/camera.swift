struct Space 
{
    let origin:Math<Float>.V3, 
        basis:Math<Math<Float>.V3>.V3
}

struct Camera 
{
    /*
    standard camera uniform blocks

    layout(std140) uniform camera
    {
        mat4 U;         // set by matrices()
        
        mat4 V;         // set by view(_:)
        
        mat3 F;         // set by fragment(_:_:sensor:space)
        vec3 position;  // set by fragment(_:_:sensor:space)
        
        // projection parameters 
        vec3 a;         // set by frustum(_:_:)
        float h;        // set by fragment(_:_:sensor:space)
        vec3 b;         // set by frustum(_:_:)
        float k;        // set by fragment(_:_:sensor:space)
    };
    */
    
    @_fixed_layout
    @usableFromInline
    struct Storage 
    {
        var U:Math<Float>.Mat4,   // projection–view matrix
            V:Math<Float>.Mat4,   // view matrix 
            F:Math<Float>.Mat4,   // fragment matrix
            //G:Math<Float>.Mat4, // global matrix
            
            a:Math<Float>.V3, 
            h:Float,              // viewport width
            
            b:Math<Float>.V3, 
            k:Float               // viewport height
        
        init()
        {
            let identity:Math<Float>.Mat4 = 
            (
                (1, 0, 0, 0), 
                (0, 1, 0, 0), 
                (0, 0, 1, 0), 
                (0, 0, 0, 1)
            )
            self.U = identity
            self.V = identity
            self.F = identity
            
            self.a = (-1, -1, -0.5)
            self.b = ( 1,  1, -2)
            self.h = 0
            self.k = 0
            
            assert(MemoryLayout<Storage>.size   == 56 * MemoryLayout<Float>.size)
            assert(MemoryLayout<Storage>.stride == 56 * MemoryLayout<Float>.size)
        }
    }
    
    private 
    var storage:Unique<Storage>
    
    // private field accessors, unimportant to the logic of the engine
    internal private(set)
    var U:Math<Float>.Mat4 
    {
        get 
        {
            return self.storage.value.U
        }
        set(U)
        {
            self.storage.value.U = U
        }
    }
    internal private(set)
    var V:Math<Float>.Mat4 
    {
        get 
        {
            return self.storage.value.V
        }
        set(V)
        {
            self.storage.value.V = V
        }
    }
    internal private(set)
    var F:Math<Float>.Mat4 
    {
        get 
        {
            return self.storage.value.F
        }
        set(F)
        {
            self.storage.value.F = F
        }
    }
    internal private(set)
    var a:Math<Float>.V3
    {
        get 
        {
            return self.storage.value.a
        }
        set(a)
        {
            self.storage.value.a = a
        }
    }
    internal private(set)
    var b:Math<Float>.V3
    {
        get 
        {
            return self.storage.value.b
        }
        set(b)
        {
            self.storage.value.b = b
        }
    }
    var viewport:Math<Float>.V2
    {
        get 
        {
            return (self.storage.value.h, self.storage.value.k)
        }
        set(viewport)
        {
            (self.storage.value.h, self.storage.value.k) = viewport
        }
    }
    
    var position:Math<Float>.V3 
    {
        let homogenous:Math<Float>.V4 = self.storage.value.F.3
        return (homogenous.x, homogenous.y, homogenous.z)
    }
    
    // when used as a data source for a uniform buffer
    func withUnsafeBytes<Result>(body:(UnsafeRawBufferPointer) -> Result) -> Result 
    {
        return self.storage.withUnsafeBytes(body: body)
    }
    
    init()
    {
        self.storage = .init(.init())
    }
    
    /* // all vectors must be normalized
    private static 
    func view(_ space:Space) -> Math<Float>.Mat4
    {
        let translation:Math<Float>.V3 = 
        (
            -Math.dot(space.origin, space.basis.x), 
            -Math.dot(space.origin, space.basis.y), 
            -Math.dot(space.origin, space.basis.z)
        )
        
        return 
            (
                (space.basis.x.x, space.basis.y.x, space.basis.z.x, 0), 
                (space.basis.x.y, space.basis.y.y, space.basis.z.y, 0), 
                (space.basis.x.z, space.basis.y.z, space.basis.z.z, 0), 
                Math.homogenize(translation)
            )
    } */
    
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
    
    // computes the `F` (“fragment”) matrix. its purpose is to convert `gl_FragCoord`s 
    // into world space rays (not necessarily normalized)
    /* private static  
    func fragment(_ a:Math<Float>.V3, _ b:Math<Float>.V3, viewport:Math<Float>.V2, space:Space) 
        -> Math<Float>.Mat4
    {
        let k:Math<Float>.V2  = Math.div(Math.sub((b.x, b.y), (a.x, a.y)), viewport)
        let ξ1:Math<Float>.V3 = Math.scale(space.basis.x, by: k.x), 
            ξ2:Math<Float>.V3 = Math.scale(space.basis.y, by: k.y)
        
        let d:Math<Float>.V3 
        d.x = Math.dot(a, (space.basis.x.x, space.basis.y.x, space.basis.z.x))
        d.y = Math.dot(a, (space.basis.x.y, space.basis.y.y, space.basis.z.y))
        d.z = Math.dot(a, (space.basis.x.z, space.basis.y.z, space.basis.z.z))
        
        return 
            (
                (ξ1.x, ξ1.y, ξ1.z, 0), 
                (ξ2.x, ξ2.y, ξ2.z, 0), 
                (d.x,  d.y,  d.z,  0), 
                
                // the ‘position’ variable in the glsl uniform block
                Math.extend(space.origin, 1)
            )
    } */

    // sets the view matrix. does not update the combined `U` matrix
    
    // sets the frustum parameters. does not compute any matrices
    // parameters should *not* be a Math<Float>.Prism because the z coordinates 
    // are reversed
    mutating 
    func frustum(_ a:Math<Float>.V3, _ b:Math<Float>.V3)
    {
        self.a = a
        self.b = b
    }
    
    // flattens the projection parameters and view matrix into the `U` matrix 
    mutating 
    func matrices()
    {
        // can be optimized, the zeroes do not need to be multiplied, but the 
        // compiler cannot optimize them out because of floating point rules
        self.U = Math.mult(Camera.projection(self.a, self.b), self.V)
    }
    
    
    struct Matrices 
    {
        let U:Math<Float>.Mat4, 
            V:Math<Float>.Mat4, 
            F:Math<Float>.Mat3, 
            position:Math<Float>.V3
        var _viewport:Math<Float>.V2
        
        typealias Storage = 
        (
            U0:Math<Float>.V4, 
            U1:Math<Float>.V4, 
            U2:Math<Float>.V4, 
            U3:Math<Float>.V4, 
            
            V0:Math<Float>.V4, 
            V1:Math<Float>.V4, 
            V2:Math<Float>.V4, 
            V3:Math<Float>.V4, 
            
            F0:Math<Float>.V4, 
            F1:Math<Float>.V4, 
            F2:Math<Float>.V4, 
            F3:Math<Float>.V4, 
            
            _viewport:Math<Float>.V4
        )
        
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
            position: (0, 0, 0), 
            _viewport: (0, 0)
        )
        
        func withUnsafeBytes<Result>(_ body:(UnsafeRawBufferPointer) throws -> Result) rethrows -> Result
        {
            let storage:Storage = 
            (
                U0: self.U.0, 
                U1: self.U.1, 
                U2: self.U.2, 
                U3: self.U.3, 
                
                V0: self.V.0, 
                V1: self.V.1, 
                V2: self.V.2, 
                V3: self.V.3, 
                
                F0: Math.extend(self.F.0,       0), 
                F1: Math.extend(self.F.1,       0),  
                F2: Math.extend(self.F.2,       0),  
                F3: Math.extend(self.position,  1), 
                
                _viewport: Math.extend(self._viewport, 0, 0)
            )
            
            return try Swift.withUnsafeBytes(of: storage, body)                 
        }
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
            
            return .init(U: Math.mult(P, V), V: V, F: F, position: Math.neg(t), _viewport: viewport)
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
