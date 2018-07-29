struct Scene 
{
    enum Programs
    {
        static
        let debug:GL.Program = .create(
            shaders:
            [
                (.vertex  , "shaders/debug.vert"),
                (.fragment, "shaders/debug.frag")
            ],
            uniforms:
            [
                .block("Camera", binding: 0)
            ]
        )!
        static
        let sphere:GL.Program = .create(
            shaders:
            [
                (.vertex  , "shaders/sphere.vert"),
                (.fragment, "shaders/sphere.frag")
            ],
            uniforms:
            [
                .block("Camera", binding: 0), 
                .float4("sphere")
            ]
        )!
        static
        let point:GL.Program = .create(
            shaders:
            [
                (.vertex  , "shaders/point.vert"),
                (.geometry, "shaders/point.geom"),
                (.fragment, "shaders/point.frag")
            ],
            uniforms:
            [
                .block("Camera", binding: 0), 
                .int("preselected")
            ]
        )!
    }
    
    struct Globe
    {
        private 
        let vao:GL.VertexArray, 
            vbo:GL.Buffer<Math<Float>.V3>,
            ebo:GL.Buffer<Math<UInt8>.V3>

        init()
        {
            self.ebo = .generate()
            self.vbo = .generate()
            self.vao = .generate()

            let cube:[Math<Float>.V3] =
            [
                 (-1, -1, -1),
                 ( 1, -1, -1),
                 ( 1,  1, -1),
                 (-1,  1, -1),

                 (-1, -1,  1),
                 ( 1, -1,  1),
                 ( 1,  1,  1),
                 (-1,  1,  1)
            ]

            let indices:[Math<UInt8>.V3] =
            [
                (0, 2, 1),
                (0, 3, 2),

                (0, 1, 5),
                (0, 5, 4),

                (1, 2, 6),
                (1, 6, 5),

                (2, 3, 7),
                (2, 7, 6),

                (3, 0, 4),
                (3, 4, 7),

                (4, 5, 6),
                (4, 6, 7)
            ]

            self.vbo.bind(to: .array)
            {
                $0.data(cube, usage: .static)

                self.vao.bind().setVertexLayout(.float(from: .float3))

                self.ebo.bind(to: .elementArray)
                {
                    $0.data(indices, usage: .static)
                    self.vao.unbind()
                }
            }
        }
        
        func draw()
        {
            Programs.sphere.bind
            {
                $0.set(float4: "sphere", (0, 0, 0, 1))
                self.vao.drawElements(0 ..< 36, as: .triangles, indexType: UInt8.self)
            }
        }
    }
    
    struct Resources 
    {
        @_fixed_layout
        @usableFromInline
        struct Vertex 
        {
            let position:Math<Float>.V3, 
                weight:Int16, 
                index:Int16
            
            init(_ position:Math<Float>.V3, weight:Int, index:Int)
            {
                self.position = position 
                self.weight   = Int16(truncatingIfNeeded: weight)
                self.index    = Int16(truncatingIfNeeded: index)
            }
        }
        
        private 
        let vao:GL.VertexArray, 
            vbo:GL.Buffer<Vertex>
        
        private 
        var count:Int = 0
        
        init()
        {
            self.vao = .generate()
            self.vbo = .generate()
            self.vbo.bind(to: .array)
            {
                $0.reserve(capacity: 1024, usage: .dynamic)
                
                self.vao.bind 
                {
                    $0.setVertexLayout(.float(from: .float3), .int(from: .short), .int(from: .short))
                }
            }
        }
        
        mutating 
        func upload(_ vertices:[Vertex])
        {
            assert(vertices.count < 1024)
            
            self.vbo.bind(to: .array)
            {
                $0.subData(vertices)
            }
            self.count = vertices.count
        }
        
        func draw(preselected:Int? = nil)
        {
            Programs.point.bind 
            {
                $0.set(int: "preselected", Int32(preselected ?? -1))
                self.vao.draw(0 ..< self.count, as: .points)
            }
        }
    }
    
    private 
    let globe:Globe
    private 
    var resources:Resources
    
    init() 
    {
        self.globe     = .init() 
        self.resources = .init()
    }
    
    func cast(_ ray:Math<Float>.V3, from position:Math<Float>.V3) -> Math<Float>.V3?
    {
        let c:Math<Float>.V3 = Math.sub((0, 0, 0), position), 
            l:Float          = Math.dot(c, ray)
        
        let discriminant:Float = 1 * 1 + l * l - Math.eusq(c)
        guard discriminant >= 0 
        else 
        {
            return nil
        }
        
        return Math.add(position, Math.scale(ray, by: l - discriminant.squareRoot()))
    }
    
    mutating 
    func rebuild(_ world:World)
    {
        self.resources.upload(world.food.enumerated().map
            { 
                .init($0.1.location.coordinates, weight: $0.1.amount, index: $0.0) 
            })
    }
    
    func draw(preselectedResource:Int?)
    {
        GL.enable(.culling)
        
        GL.enable(.blending)
        GL.blend(.mix)
        GL.disable(.multisampling)
        
        self.globe.draw()
        
        GL.blend(.add)
        self.resources.draw(preselected: preselectedResource)
    }
}
