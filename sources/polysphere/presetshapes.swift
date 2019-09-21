enum Mesh 
{
    enum Preset 
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
            let attributes:[GPU.Vertex.Attribute<Mesh.Preset.ColorVertex>] = 
            [
                .float32x3(\Mesh.Preset.ColorVertex.position, as: .float32), 
                .uint8x4(  \Mesh.Preset.ColorVertex.color,    as: .float32(normalized: true))
            ]
            
            var position:(Float, Float, Float)
            var color:(UInt8, UInt8, UInt8, UInt8)
            
            init(_ position:Vector3<Float>, color:Vector4<UInt8>) 
            {
                self.position = position.tuple
                self.color    = color.tuple
            }
        }
        
        static 
        func cube() -> GPU.Vertex.Array<Vertex, UInt8>
        {
            let vertices:[Vertex] = 
            [
                .init(.init( 1,  1, -1, 0)),
                .init(.init(-1,  1, -1, 0)),
                .init(.init(-1, -1, -1, 0)),
                .init(.init( 1, -1, -1, 0)),
                
                .init(.init( 1,  1,  1, 0)),
                .init(.init(-1,  1,  1, 0)),
                .init(.init(-1, -1,  1, 0)),
                .init(.init( 1, -1,  1, 0)),
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
                indices:    .init(hint: .static,    debugName: "mesh/presets/cube/buffers/index"))
            
            vao.buffers.vertex.assign(vertices)
            vao.buffers.index.assign(indices)
            
            return vao
        }
    }
}
