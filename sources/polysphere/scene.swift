struct Globe
{
    let vbo:GL.Buffer,
        ebo:GL.Buffer,
        vao:GL.VertexArray

    init()
    {
        self.ebo = .generate()
        self.vbo = .generate()
        self.vao = .generate()

        let cube:[Float] =
        [
             -1, -1, -1,
              1, -1, -1,
              1,  1, -1,
             -1,  1, -1,

             -1, -1,  1,
              1, -1,  1,
              1,  1,  1,
             -1,  1,  1,
        ]

        let indices:[UInt32] =
        [
            0, 2, 1,
            0, 3, 2,

            0, 1, 5,
            0, 5, 4,

            1, 2, 6,
            1, 6, 5,

            2, 3, 7,
            2, 7, 6,

            3, 0, 4,
            3, 4, 7,

            4, 5, 6,
            4, 6, 7
        ]

        self.vbo.bind(to: .array)
        {


            $0.data(cube, usage: .static)

            self.vao.bind()
            GL.setVertexLayout(.float(from: .float3))

            self.ebo.bind(to: .elementArray)
            {
                $0.data(indices, usage: .static)
                self.vao.unbind()
            }
        }
    }
}
