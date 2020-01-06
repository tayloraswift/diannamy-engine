enum Mesh 
{
    struct
    Vertex:GPU.Vertex.Structured
    {
        static 
        let attributes:[GPU.Vertex.Attribute<Self>] = 
        [
            .float32x4(\.r, as: .float32)
        ]
        
        private 
        var r:(Float, Float, Float, Float)
        
        var x:Float 
        {
            get     { self.r.0 }
            set(x)  { self.r.0 = x }
        }
        var y:Float 
        {
            get     { self.r.1 }
            set(y)  { self.r.1 = y }
        }
        var z:Float 
        {
            get     { self.r.2 }
            set(z)  { self.r.2 = z }
        }
        var w:Float 
        {
            get     { self.r.3 }
            set(w)  { self.r.3 = w }
        }
        
        init(_ vector:Vector4<Float>) 
        {
            self.r = vector.tuple
        }
    }
    struct
    ColorVertex:GPU.Vertex.Structured
    {
        static 
        let attributes:[GPU.Vertex.Attribute<Mesh.ColorVertex>] = 
        [
            .float32x3(\Mesh.ColorVertex.position, as: .float32), 
            .uint8x4(  \Mesh.ColorVertex.color,    as: .float32(normalized: true))
        ]
        
        var position:(Float, Float, Float)
        var color:(UInt8, UInt8, UInt8, UInt8)
        
        init(_ position:Vector3<Float>, color:Vector4<UInt8>) 
        {
            self.position = position.tuple
            self.color    = color.tuple
        }
    }
    
    enum Preset 
    {
        static 
        func square(_ k:Float = 1) -> GPU.Vertex.Array<Vertex, UInt8>
        {
            let vertices:[Vertex] = 
            [
                .init(.init( k,  k, 0, 0)),
                .init(.init(-k,  k, 0, 0)),
                .init(.init(-k, -k, 0, 0)),
                
                .init(.init(-k, -k, 0, 0)),
                .init(.init( k, -k, 0, 0)), 
                .init(.init( k,  k, 0, 0))
            ]
            
            let vao:GPU.Vertex.Array<Vertex, UInt8> = .init(
                vertices:   .init(hint: .static, debugName: "mesh/presets/square/buffers/vertex"), 
                indices:    .init(hint: .static))
            
            vao.buffers.vertex.assign(vertices)
            return vao
        }
        static 
        func cube(_ k:Float = 1) -> GPU.Vertex.Array<Vertex, UInt8>
        {
            let vertices:[Vertex] = 
            [
                .init(.init( k,  k, -k, 0)),
                .init(.init(-k,  k, -k, 0)),
                .init(.init(-k, -k, -k, 0)),
                .init(.init( k, -k, -k, 0)),
                
                .init(.init( k,  k,  k, 0)),
                .init(.init(-k,  k,  k, 0)),
                .init(.init(-k, -k,  k, 0)),
                .init(.init( k, -k,  k, 0)),
            ]
            let indices:[UInt8] = 
            [
                // front
                0, 1, 2,
                2, 3, 0,
                // right
                1, 5, 6,
                6, 2, 1,
                // back
                7, 6, 5,
                5, 4, 7,
                // left
                4, 0, 3,
                3, 7, 4,
                // bottom
                4, 5, 1,
                1, 0, 4,
                // top
                3, 2, 6,
                6, 7, 3
            ]
            
            let vao:GPU.Vertex.Array<Vertex, UInt8> = .init(
                vertices:   .init(hint: .static, debugName: "mesh/presets/cube/buffers/vertex"), 
                indices:    .init(hint: .static, debugName: "mesh/presets/cube/buffers/index"))
            
            vao.buffers.vertex.assign(vertices)
            vao.buffers.index.assign(indices)
            
            return vao
        }
        
        static 
        func icosahedron(inscribedRadius r:Float = 1) -> GPU.Vertex.Array<Vertex, UInt8> 
        {
            let a:Float = r * (3 * Float.sqrt(3) - Float.sqrt(15)) / 2
            let b:Float = r * (Float.sqrt(15) - Float.sqrt(3)) / 2
            
            let vertices:[Vertex] = 
            [
                .init(.init(-a,  b,  0, 0)),
                .init(.init( a,  b,  0, 0)),
                .init(.init(-a, -b,  0, 0)),
                .init(.init( a, -b,  0, 0)),

                .init(.init( 0, -a,  b, 0)),
                .init(.init( 0,  a,  b, 0)),
                .init(.init( 0, -a, -b, 0)),
                .init(.init( 0,  a, -b, 0)),

                .init(.init( b,  0, -a, 0)),
                .init(.init( b,  0,  a, 0)),
                .init(.init(-b,  0, -a, 0)),
                .init(.init(-b,  0,  a, 0)),
            ]
            
            let indices:[UInt8] = 
            [
                0,  11, 5,
                0,  5,  1,
                0,  1,  7,
                0,  7,  10,
                0,  10, 11,

                1,  5,  9,
                5,  11, 4,
                11, 10, 2,
                10, 7,  6,
                7,  1,  8,

                3,  9,  4,
                3,  4,  2,
                3,  2,  6,
                3,  6,  8,
                3,  8,  9,

                4,  9,  5,
                2,  4,  11,
                6,  2,  10,
                8,  6,  7,
                9,  8,  1,
            ]
            
            let vao:GPU.Vertex.Array<Vertex, UInt8> = .init(
                vertices:   .init(hint: .static, debugName: "mesh/presets/icosphere/buffers/vertex"), 
                indices:    .init(hint: .static, debugName: "mesh/presets/icosphere/buffers/index"))
            
            vao.buffers.vertex.assign(vertices)
            vao.buffers.index.assign(indices)
            
            return vao
        }
    }
}
