extension UI.Controller.Geo 
{
    struct Scene 
    {
        var basepoints:[Math<Float>.V3]?, 
            active:Int?, 
            preselected:Int?, 
            deleted:Int?
        
        init() {}
    }
}

extension UI 
{
    struct View 
    {
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
                
                let vao:GL.VertexArray, 
                    vbo:GL.Buffer<Vertex>
                
                init()
                {
                    self.vbo = .generate()
                    self.vao = .generate()
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
            }
            
            let borders:Borders, 
                globe:Globe 
            
        }
    }
}
