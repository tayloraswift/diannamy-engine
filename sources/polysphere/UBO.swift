enum UBO 
{
    //  standard uniform view blocks

    //  layout(std140) uniform Camera
    //  {
    //      mat4 U;         // P × V
    //      mat4 V;         // V
    //      mat3 F;         // F[0 ..< 3]
    //      vec3 position;  // F[3]]
    //  } camera; 
    final 
    class CameraBlock 
    {
        typealias Storage = (U:Matrix4<Float>, V:Matrix4<Float>, F:Matrix4<Float>)
        
        private 
        let block:GL.Buffer<UInt8>
        
        init() 
        {
            self.block = .generate()
            self.block.bind(to: .uniform)
            {
                $0.reserve(capacity: MemoryLayout<Storage>.size, usage: .dynamic)
            }
        }
        
        deinit 
        {
            self.block.destroy()
        }
        
        func bind<Result>(index:Int, _ body:(GL.Buffer<UInt8>.BoundTarget) throws -> Result) 
            rethrows -> Result  
        {
            return try self.block.bind(to: .uniform, index: index, body) 
        }
        
        static 
        func encode(matrices:Camera.Matrices, to target:GL.Buffer<UInt8>.BoundTarget) 
        {
            let F:Matrix4<Float> = .init(
                .extend(matrices.F[0], 0), 
                .extend(matrices.F[1], 0),  
                .extend(matrices.F[2], 0),  
                .extend(matrices.position,    1)
            )
                
            let storage:Storage = (matrices.U, matrices.V, F)
            withUnsafeBytes(of: storage) 
            {
                target.subData($0)
            }
        }
    }
    
    // layout(std140) uniform Display 
    // {
    //     vec2 frame_a;
    //     vec2 frame_b;
    //     vec2 viewport;
    // } display;
    final 
    class DisplayBlock
    {
        typealias Storage = (frame_a:Vector2<Float>, frame_b:Vector2<Float>, viewport:Vector2<Float>)
        
        private 
        let block:GL.Buffer<UInt8>
        
        init() 
        {
            self.block = .generate()
            self.block.bind(to: .uniform)
            {
                $0.reserve(capacity: MemoryLayout<Storage>.size, usage: .dynamic)
            }
        }
        
        deinit 
        {
            self.block.destroy()
        }
        
        func bind<Result>(index:Int, _ body:(GL.Buffer<UInt8>.BoundTarget) throws -> Result) 
            rethrows -> Result  
        {
            return try self.block.bind(to: .uniform, index: index, body) 
        }
        
        static 
        func encode(frame:Rectangle<Float>, viewport:Vector2<Float>, 
            to target:GL.Buffer<UInt8>.BoundTarget)
        {
            let storage:Storage = (frame.a, frame.b, viewport)
            withUnsafeBytes(of: storage) 
            {
                target.subData($0)
            }
        }
    }
}
