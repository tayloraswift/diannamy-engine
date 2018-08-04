extension UI 
{
    struct View 
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
            static
            let borders:GL.Program = .create(
                shaders:
                [
                    (.vertex  , "shaders/border.vert"),
                    (.geometry, "shaders/point.geom"),
                    (.fragment, "shaders/point.frag")
                ],
                uniforms:
                [
                    .block("Camera", binding: 0), 
                    .int("selected"), 
                    .int("preselected"), 
                    .int("snapped"), 
                    .int("deleted")
                ]
            )!
        }
        
        struct Geo 
        {
            struct Borders 
            {
                @_fixed_layout
                @usableFromInline 
                struct Vertex 
                {
                    let position:Math<Float>.V3, 
                        id:Int32
                }
                
                private 
                let vao:GL.VertexArray, 
                    vbo:GL.Buffer<Vertex>
                
                private 
                var count:Int = 0
                
                private 
                var selected:Int?, 
                    preselected:Int?, 
                    snapped:Int?, 
                    deleted:Int?
                
                init()
                {
                    self.vbo   = .generate()
                    self.vao   = .generate()
                    self.count = 0
                    
                    self.vbo.bind(to: .array)
                    {
                        self.vao.bind 
                        {
                            $0.setVertexLayout(.float(from: .float3), .int(from: .int))
                        }
                    }
                }
                
                mutating 
                func rebuild(from scene:inout Controller.Geo.Scene) 
                {
                    if let vertices = scene.vertices.pop()
                    {
                        let buffer:[Vertex] = vertices.enumerated().map 
                        {
                            .init(position: $0.1, id: Int32(truncatingIfNeeded: $0.0))
                        }
                        
                        self.vbo.bind(to: .array)
                        {
                            if buffer.count == self.count
                            {
                                guard buffer.count > 0 
                                else 
                                {
                                    return  
                                }
                                
                                $0.subData(buffer)
                            }
                            else 
                            {
                                $0.data(buffer, usage: .dynamic)
                                self.count = buffer.count
                            }
                        }
                    }
                    
                    self.selected    = scene.selected
                    self.preselected = scene.preselected
                    self.snapped     = scene.snapped
                    self.deleted     = scene.deleted
                }
                
                func draw() 
                {
                    Programs.borders.bind 
                    {
                        $0.set(int: "selected",    Int32(self.selected    ?? -1))
                        $0.set(int: "preselected", Int32(self.preselected ?? -1))
                        $0.set(int: "snapped",     Int32(self.snapped     ?? -1))
                        $0.set(int: "deleted",     Int32(self.deleted     ?? -1))
                        self.vao.draw(0 ..< self.count, as: .points)
                    }
                }
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
            
            private 
            var borders:Borders
            private
            let globe:Globe 
            
            init()
            {
                self.borders = .init()
                self.globe   = .init()
            }
            
            mutating 
            func rebuild(from scene:inout Controller.Geo.Scene) 
            {
                self.borders.rebuild(from: &scene)
            }
            
            func draw()
            {
                GL.enable(.culling)
                
                GL.enable(.blending)
                GL.blend(.mix)
                GL.disable(.multisampling)
                
                self.globe.draw()
                
                GL.blend(.add)
                self.borders.draw()
            }
        }
    }
}
