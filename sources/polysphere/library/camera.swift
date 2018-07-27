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
        mat4 U;
        mat4 V;
        mat4 W;
        
        // projection parameters 
        vec3 a;
        vec3 b;
        
        // view parameters
        vec3 position;
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
            _padf0:Float = 0, 
            
            b:Math<Float>.V3, 
            _padf1:Float = 0, 
            
            position:Math<Float>.V3, 
            _padf2:Float = 0
        
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
            
            self.a        = (-1, -1, -0.5)
            self.b        = ( 1,  1, -2)
            self.position = ( 0,  0,  0)
            
            assert(MemoryLayout<Storage>.size == 240)
        }
    }
    
    private 
    var storage:Unique<Storage>
    
    // private field accessors, unimportant to the logic of the engine
    private 
    var U:Math<Float>.Mat4 
    {
        get 
        {
            return self.storage.value.U
        }
        set(U)
        {
            return self.storage.value.U = U
        }
    }
    private 
    var V:Math<Float>.Mat4 
    {
        get 
        {
            return self.storage.value.V
        }
        set(V)
        {
            return self.storage.value.V = V
        }
    }
    private 
    var F:Math<Float>.Mat4 
    {
        get 
        {
            return self.storage.value.F
        }
        set(F)
        {
            return self.storage.value.F = F
        }
    }
    private 
    var a:Math<Float>.V3
    {
        get 
        {
            return self.storage.value.a
        }
        set(a)
        {
            return self.storage.value.a = a
        }
    }
    private 
    var b:Math<Float>.V3
    {
        get 
        {
            return self.storage.value.b
        }
        set(b)
        {
            return self.storage.value.b = b
        }
    }
    private 
    var position:Math<Float>.V3 
    {
        get 
        {
            return self.storage.value.position
        }
        set(position)
        {
            return self.storage.value.position = position
        }
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
    
    // all vectors must be normalized
    private static 
    func view(_ space:Space) -> Math<Float>.Mat4
    {
        let translation:Math<Float>.V4 = 
        (
            -Math.dot(space.origin, space.basis.x), 
            -Math.dot(space.origin, space.basis.y), 
            -Math.dot(space.origin, space.basis.z), 
            1
        )
        
        return 
            (
                (space.basis.x.x, space.basis.y.x, space.basis.z.x, 0), 
                (space.basis.x.y, space.basis.y.y, space.basis.z.y, 0), 
                (space.basis.x.z, space.basis.y.z, space.basis.z.z, 0), 
                translation
            )
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
    
    // computes the `F` (“fragment”) matrix. its purpose is to convert `gl_FragCoord`s 
    // into world space vectors (not necessarily normalized)
    private static  
    func fragment(_ a:Math<Float>.V3, _ b:Math<Float>.V3, 
        sensor:Math<Float>.Rectangle, space:Space) -> Math<Float>.Mat4
    {
        let k:Math<Float>.V2  = Math.div(Math.sub((b.x, b.y), (a.x, a.y)), 
                                         Math.sub(sensor.1, sensor.0))
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
                (space.origin.x, space.origin.y, space.origin.z, 1)
            )
    }

    // sets the view matrix. does not update the combined `U` matrix
    mutating 
    func view(_ space:Space)
    {
        self.V = Camera.view(space)
        self.position = space.origin
    }

    mutating 
    func view(position:Math<Float>.V3, z:Math<Float>.V3, x:Math<Float>.V3)
    {
        let y:Math<Float>.V3 = Math.normalize(Math.cross(z, x))
        self.view(.init(origin: position, basis: (x, y, z)))
    }
    
    mutating 
    func view(position:Math<Float>.V3, y:Math<Float>.V3, z:Math<Float>.V3)
    {
        let x:Math<Float>.V3 = Math.normalize(Math.cross(y, z))
        self.view(.init(origin: position, basis: (x, y, z)))
    }
    
    // sets the `F` (“fragment”) matrix. its purpose is to convert `gl_FragCoord`s 
    // into world space vectors (not necessarily normalized)
    mutating 
    func fragment(sensor:Math<Float>.Rectangle, space:Space)
    {
        self.F = Camera.fragment(self.a, self.b, sensor: sensor, space: space)
    }
    
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
    
    
    struct Rig
    {
        var pivot:Math<Float>.V3, 
            angle:Math<Float>.S2, 
            distance:Float, // negative is outwards, positive is inwards
            focalLength:Float

        init(pivot:Math<Float>.V3 = (0, 0, 0), angle:Math<Float>.S2 = (0, 0), 
            distance:Float = 0, focalLength:Float = 35)
        {
            self.pivot       = pivot
            self.angle       = angle
            self.distance    = distance
            self.focalLength = focalLength
        }
        
        static 
        func lerp(_ a:Rig, _ b:Rig, _ t:Float) -> Rig 
        {
            // this isn’t quite right for angles, it only works if going along a 
            // line of latitude or longitude
            let (θ, φ):(Float, Float) = Math.lerp((a.angle.0, a.angle.1), (b.angle.0, b.angle.1), t)
            return .init(pivot: Math.lerp(a.pivot, b.pivot, t), 
                angle: (θ, φ), 
                distance: Math.lerp(a.distance, b.distance, t), 
                focalLength: Math.lerp(a.focalLength, b.focalLength, t))
        }
        
        func basis() -> Math<Math<Float>.V3>.V3 
        {
            // Math.cartesian already evaluates _sin(self.angle.φ) and _cos(self.angle.φ)
            // so when it gets inlines it this method of computing tangent will get
            // factored into common sub expressions
            let basis:Math<Math<Float>.V3>.V3
            basis.z = Math.cartesian(self.angle)
            basis.x = (-_sin(self.angle.φ), _cos(self.angle.φ), 0)
            basis.y = Math.cross(basis.z, basis.x)
            
            return basis
        }
        
        func space() -> Space 
        {
            let basis:Math<Math<Float>.V3>.V3 = self.basis()
            let origin:Math<Float>.V3 = Math.scadd(self.pivot, basis.z, self.distance)
            
            return .init(origin: origin, basis: basis)
        }
        
        // focal length is 35mm equivalent
        func frustum(sensor:Math<Float>.Rectangle, clip:Math<Float>.V2) 
            -> (a:Math<Float>.V3, b:Math<Float>.V3)
        {
            // c = 43.3mm / length(p.xy)
            // f = q / c
            // a.xy = p.xy * a.z / f
            //      = p.xy * a.z * c / q
            //      = p.xy * a.z * 43.3mm / (length(p.xy) * q)
            // where `f` is the physical focal length, `q` is the 35mm equivalent focal 
            // length (units of mm), `p` is a pixel coordinate of a viewport boundary
            // (units of px), and `c` is the crop factor (units of mm)
            let factor:Float = -clip.0 * Math.length((24, 36)) / 
                               (self.focalLength * Math.length(Math.sub(sensor.1, sensor.0)))
            
            let a:Math<Float>.V2 = Math.scale(sensor.0, by: factor), 
                b:Math<Float>.V2 = Math.scale(sensor.1, by: factor)
            
            return ((a.x, a.y, clip.0), (b.x, b.y, clip.1))
        }
    }
}
