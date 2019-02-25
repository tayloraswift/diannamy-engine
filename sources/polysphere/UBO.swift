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
        typealias Storage = (U:Math<Float>.Mat4, V:Math<Float>.Mat4, F:Math<Float>.Mat4)
        
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
            let F:Math<Float>.Mat4 = 
            (
                Math.extend(matrices.F.0,       0), 
                Math.extend(matrices.F.1,       0),  
                Math.extend(matrices.F.2,       0),  
                Math.extend(matrices.position,  1)
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
        typealias Storage = (frame_a:Math<Float>.V2, frame_b:Math<Float>.V2, viewport:Math<Float>.V2)
        
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
        func encode(frame:Math<Float>.Rectangle, viewport:Math<Float>.V2, 
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
