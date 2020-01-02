import protocol Error.RecursiveError
import enum File.File

protocol ContiguousCollection:RandomAccessCollection 
{
    func withUnsafeBufferPointer<R>(_ body:(UnsafeBufferPointer<Element>) throws -> R) rethrows -> R
    func withUnsafeBytes<R>(_ body:(UnsafeRawBufferPointer) throws -> R) rethrows -> R
}
extension ArraySlice:ContiguousCollection 
{
}
extension Array:ContiguousCollection 
{
}
extension UnsafeBufferPointer:ContiguousCollection 
{
    func withUnsafeBufferPointer<R>(_ body:(UnsafeBufferPointer<Element>) throws -> R)  
        rethrows -> R 
    {
        return try body(self)
    }
    func withUnsafeBytes<R>(_ body:(UnsafeRawBufferPointer) throws -> R) 
        rethrows -> R 
    {
        return try body(.init(self))
    }
}
extension UnsafeRawBufferPointer:ContiguousCollection 
{
    func withUnsafeBufferPointer<R>(_ body:(UnsafeBufferPointer<UInt8>) throws -> R) 
        rethrows -> R 
    {
        return try body(self.bindMemory(to: UInt8.self))
    }
    func withUnsafeBytes<R>(_ body:(UnsafeRawBufferPointer) throws -> R) 
        rethrows -> R 
    {
        return try body(self)
    }
}

protocol _GPUVertexAnyArray:AnyObject
{
    var count:(vertex:Int, index:Int)
    {
        get
    }
    
    func draw(_ range:Range<Int>, as primitive:GPU.Primitive)
    func draw(indices range:Range<Int>, as primitive:GPU.Primitive)
}
protocol _GPUVertexStructured 
{
    static 
    var attributes:[GPU.Vertex.Attribute<Self>] 
    {
        get 
    }
}
protocol _GPUVertexElement
{
    static 
    var code:Int32 
    {
        get 
    }
}
extension UInt8:GPU.Vertex.Element 
{
    static 
    var code:OpenGL.Enum 
    {
        OpenGL.UNSIGNED_BYTE
    }
}
extension UInt16:GPU.Vertex.Element 
{
    static 
    var code:OpenGL.Enum 
    {
        OpenGL.UNSIGNED_SHORT
    }
}
extension UInt32:GPU.Vertex.Element 
{
    static 
    var code:OpenGL.Enum 
    {
        OpenGL.UNSIGNED_INT 
    }
}

protocol _GPUAnyBuffer:AnyObject
{
    static 
    var stride:Int 
    {
        get 
    }
    static 
    var target:GPU.Buffer.AnyTarget.Type
    {
        get 
    }
    var buffer:UInt32 
    {
        get 
    }
    var debugName:String 
    {
        get 
    }
    
    var count:Int 
    {
        get
    }
} 
protocol _GPUAnyBufferTarget
{
    static 
    var code:Int32 
    {
        get 
    }
}

protocol _GPUAnyBufferUniform:GPU.AnyBuffer 
{
}
protocol _GPUAnyBufferArray:GPU.AnyBuffer 
{
}
protocol _GPUAnyBufferIndexArray:GPU.AnyBuffer 
{
}

protocol _GPUAnyTexture:AnyObject
{
    static 
    var stride:Int 
    {
        get 
    }
    static 
    var target:GPU.Texture.AnyTarget.Type
    {
        get 
    }
    var texture:UInt32
    {
        get 
    }
    var debugName:String 
    {
        get 
    }
} 
protocol _GPUAnyTextureTarget
{
    static 
    var code:Int32 
    {
        get 
    }
}

protocol _GPUAnyTextureD2:GPU.AnyTexture 
{
}
protocol _GPUAnyTextureD3:GPU.AnyTexture 
{
}
protocol _GPUAnyTextureCube:GPU.AnyTexture 
{
}

enum GPU 
{
    enum Primitive 
    {
        case points 
        case lines 
        case triangles
        case linesAdjacency
        
        fileprivate 
        var code:OpenGL.Enum 
        {
            switch self 
            {
            case .points:
                return OpenGL.POINTS 
            case .lines:
                return OpenGL.LINES 
            case .triangles:
                return OpenGL.TRIANGLES
            case .linesAdjacency:
                return OpenGL.LINES_ADJACENCY
            }
        }
        
        var stride:Int 
        {
            switch self 
            {
            case .points:
                return 1
            case .lines:
                return 2
            case .triangles:
                return 3
            case .linesAdjacency:
                return 4
            }
        }
    }
    
    enum Vertex 
    {
        typealias Structured = _GPUVertexStructured
        typealias Element = _GPUVertexElement
        typealias AnyArray = _GPUVertexAnyArray

        enum Attribute<Vertex> where Vertex:Structured
        {
            enum Destination 
            {
                enum General 
                {
                    case float32
                }
                enum HighPrecision
                {
                    case float32, float64
                }
                enum FixedPoint 
                {
                    case float32(normalized:Bool)
                }
                enum Integral
                {
                    case float32(normalized:Bool), int32
                }
                
                case int32, float32(normalized:Bool), float64
            }
            
            case float16    (KeyPath<Vertex,  UInt16>,                          as:Destination.General)
            case float16x2  (KeyPath<Vertex, (UInt16, UInt16)>,                 as:Destination.General)
            case float16x3  (KeyPath<Vertex, (UInt16, UInt16, UInt16)>,         as:Destination.General)
            case float16x4  (KeyPath<Vertex, (UInt16, UInt16, UInt16, UInt16)>, as:Destination.General)
            
            case float32    (KeyPath<Vertex,  Float>,                           as:Destination.General)
            case float32x2  (KeyPath<Vertex, (Float, Float)>,                   as:Destination.General)
            case float32x3  (KeyPath<Vertex, (Float, Float, Float)>,            as:Destination.General)
            case float32x4  (KeyPath<Vertex, (Float, Float, Float, Float)>,     as:Destination.General)
            
            case float64    (KeyPath<Vertex,  Double>,                          as:Destination.HighPrecision)
            case float64x2  (KeyPath<Vertex, (Double, Double)>,                 as:Destination.HighPrecision)
            case float64x3  (KeyPath<Vertex, (Double, Double, Double)>,         as:Destination.HighPrecision)
            case float64x4  (KeyPath<Vertex, (Double, Double, Double, Double)>, as:Destination.HighPrecision)
            
            case int8       (KeyPath<Vertex,  Int8>,                            as:Destination.Integral)
            case int8x2     (KeyPath<Vertex, (Int8, Int8)>,                     as:Destination.Integral)
            case int8x3     (KeyPath<Vertex, (Int8, Int8, Int8)>,               as:Destination.Integral)
            case int8x4     (KeyPath<Vertex, (Int8, Int8, Int8, Int8)>,         as:Destination.Integral)
            
            case int16      (KeyPath<Vertex,  Int16>,                           as:Destination.Integral)
            case int16x2    (KeyPath<Vertex, (Int16, Int16)>,                   as:Destination.Integral)
            case int16x3    (KeyPath<Vertex, (Int16, Int16, Int16)>,            as:Destination.Integral)
            case int16x4    (KeyPath<Vertex, (Int16, Int16, Int16, Int16)>,     as:Destination.Integral)
            
            case int32      (KeyPath<Vertex,  Int32>,                           as:Destination.Integral)
            case int32x2    (KeyPath<Vertex, (Int32, Int32)>,                   as:Destination.Integral)
            case int32x3    (KeyPath<Vertex, (Int32, Int32, Int32)>,            as:Destination.Integral)
            case int32x4    (KeyPath<Vertex, (Int32, Int32, Int32, Int32)>,     as:Destination.Integral)
            
            case uint10x3   (KeyPath<Vertex,  UInt32>,                          as:Destination.FixedPoint)
            case uint8_bgra (KeyPath<Vertex, (UInt8, UInt8, UInt8, UInt8)>,     as:Destination.FixedPoint)
            
            case uint8      (KeyPath<Vertex,  UInt8>,                           as:Destination.Integral)
            case uint8x2    (KeyPath<Vertex, (UInt8, UInt8)>,                   as:Destination.Integral)
            case uint8x3    (KeyPath<Vertex, (UInt8, UInt8, UInt8)>,            as:Destination.Integral)
            case uint8x4    (KeyPath<Vertex, (UInt8, UInt8, UInt8, UInt8)>,     as:Destination.Integral)
            
            case uint16     (KeyPath<Vertex,  UInt16>,                          as:Destination.Integral)
            case uint16x2   (KeyPath<Vertex, (UInt16, UInt16)>,                 as:Destination.Integral)
            case uint16x3   (KeyPath<Vertex, (UInt16, UInt16, UInt16)>,         as:Destination.Integral)
            case uint16x4   (KeyPath<Vertex, (UInt16, UInt16, UInt16, UInt16)>, as:Destination.Integral)
            
            case uint32     (KeyPath<Vertex,  UInt32>,                          as:Destination.Integral)
            case uint32x2   (KeyPath<Vertex, (UInt32, UInt32)>,                 as:Destination.Integral)
            case uint32x3   (KeyPath<Vertex, (UInt32, UInt32, UInt32)>,         as:Destination.Integral)
            case uint32x4   (KeyPath<Vertex, (UInt32, UInt32, UInt32, UInt32)>, as:Destination.Integral)
            
            var destination:Destination 
            {
                switch self 
                {
                case    .float16    (_, as: let destination),
                        .float16x2  (_, as: let destination),
                        .float16x3  (_, as: let destination),
                        .float16x4  (_, as: let destination), 
                        
                        .float32    (_, as: let destination),
                        .float32x2  (_, as: let destination),
                        .float32x3  (_, as: let destination),
                        .float32x4  (_, as: let destination):
                    
                    switch destination 
                    {
                    case .float32: 
                        return .float32(normalized: false)
                    }
                
                case    .float64    (_, as: let destination),
                        .float64x2  (_, as: let destination),
                        .float64x3  (_, as: let destination),
                        .float64x4  (_, as: let destination):
                    
                    switch destination 
                    {
                    case .float32: 
                        return .float32(normalized: false)
                    case .float64: 
                        return .float64
                    }
                
                case    .uint10x3   (_, as: let destination),
                        .uint8_bgra (_, as: let destination):
                    switch destination 
                    {
                    case .float32(normalized: let normalize): 
                        return .float32(normalized: normalize)
                    }
                
                case    .int8       (_, as: let destination),
                        .int8x2     (_, as: let destination),
                        .int8x3     (_, as: let destination),
                        .int8x4     (_, as: let destination),
                        
                        .int16      (_, as: let destination),
                        .int16x2    (_, as: let destination),
                        .int16x3    (_, as: let destination),
                        .int16x4    (_, as: let destination),
                        
                        .int32      (_, as: let destination),
                        .int32x2    (_, as: let destination),
                        .int32x3    (_, as: let destination),
                        .int32x4    (_, as: let destination),
                        
                        .uint8      (_, as: let destination),
                        .uint8x2    (_, as: let destination),
                        .uint8x3    (_, as: let destination),
                        .uint8x4    (_, as: let destination),
                        
                        .uint16     (_, as: let destination),
                        .uint16x2   (_, as: let destination),
                        .uint16x3   (_, as: let destination),
                        .uint16x4   (_, as: let destination),
                
                        .uint32     (_, as: let destination),
                        .uint32x2   (_, as: let destination),
                        .uint32x3   (_, as: let destination),
                        .uint32x4   (_, as: let destination):
                    
                    switch destination 
                    {
                    case .float32(normalized: let normalize): 
                        return .float32(normalized: normalize)
                    case .int32: 
                        return .int32 
                    }
                }
            }
            
            var keyPath:PartialKeyPath<Vertex> 
            {
                switch self 
                {
                case    .float16    (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .float16x2  (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .float16x3  (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .float16x4  (let keyPath as PartialKeyPath<Vertex>, as: _), 
                        .float32    (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .float32x2  (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .float32x3  (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .float32x4  (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .float64    (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .float64x2  (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .float64x3  (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .float64x4  (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .uint10x3   (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .uint8_bgra (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .int8       (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .int8x2     (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .int8x3     (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .int8x4     (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .int16      (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .int16x2    (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .int16x3    (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .int16x4    (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .int32      (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .int32x2    (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .int32x3    (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .int32x4    (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .uint8      (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .uint8x2    (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .uint8x3    (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .uint8x4    (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .uint16     (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .uint16x2   (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .uint16x3   (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .uint16x4   (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .uint32     (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .uint32x2   (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .uint32x3   (let keyPath as PartialKeyPath<Vertex>, as: _),
                        .uint32x4   (let keyPath as PartialKeyPath<Vertex>, as: _):
                    return keyPath
                }
            }
            
            var count:Int 
            {
                switch self 
                {
                case    .int32, .int16, .int8, .uint32, .uint16, .uint8, 
                        .float64, .float32, .float16:
                    return 1 
                case    .int32x2, .int16x2, .int8x2, .uint32x2, .uint16x2, .uint8x2, 
                        .float64x2, .float32x2, .float16x2:
                    return 2 
                case    .int32x3, .int16x3, .int8x3, .uint32x3, .uint16x3, .uint8x3, 
                        .float64x3, .float32x3, .float16x3:
                    return 3
                case    .uint10x3, .uint8_bgra, // counting `.uint10x3` as `.uint8x4` equivalent
                        .int32x4, .int16x4, .int8x4, .uint32x4, .uint16x4, .uint8x4, 
                        .float64x4, .float32x4, .float16x4:
                    return 4
                }
            }
            
            var size:Int 
            {
                switch self 
                {
                case    .uint10x3, .uint8_bgra, // ditto 
                        .int8, .int8x2, .int8x3, .int8x4, 
                        .uint8, .uint8x2, .uint8x3, .uint8x4:
                    return self.count * 1
                case    .int16, .int16x2, .int16x3, .int16x4, 
                        .uint16, .uint16x2, .uint16x3, .uint16x4, 
                        .float16, .float16x2, .float16x3, .float16x4:
                    return self.count * 2
                case    .int32, .int32x2, .int32x3, .int32x4, 
                        .uint32, .uint32x2, .uint32x3, .uint32x4, 
                        .float32, .float32x2, .float32x3, .float32x4:
                    return self.count * 4
                case    .float64, .float64x2, .float64x3, .float64x4:
                    return self.count * 8
                }
            }
        }
        
        final 
        class Array<Vertex, Index>:AnyArray
            where Vertex:Structured, Index:Element
        {
            fileprivate 
            struct Core 
            {
                let vertexArray:OpenGL.UInt 
                
                static 
                func create() -> Self 
                {
                    let vertexArray:OpenGL.UInt = directReturn(default: 0) 
                    {
                        OpenGL.glGenVertexArrays(1, $0)
                    }
                    return .init(vertexArray: vertexArray)
                }
                
                func destroy() 
                {
                    withUnsafePointer(to: self.vertexArray)
                    {
                        OpenGL.glDeleteVertexArrays(1, $0)
                    }
                }
                
                func attach(vertices:Buffer.Array<Vertex>, indices:Buffer.IndexArray<Index>)
                {
                    OpenGL.glBindVertexArray(self.vertexArray)
                    OpenGL.glBindBuffer(Buffer.Target.Array.code, vertices.core.buffer)
                    
                    // set vertex attributes 
                    let stride:Int = MemoryLayout<Vertex>.stride
                    // warn unusual stride 
                    if (stride.nextPowerOfTwo - stride).isPowerOfTwo 
                    {
                        Log.advisory("Vertex type '\(String.init(reflecting: Vertex.self))' has stride of \(stride) bytes, which is \(stride.nextPowerOfTwo - stride) bytes less than \(stride.nextPowerOfTwo)")
                    }
                    
                    for (index, attribute):(Int, Attribute) in Vertex.attributes.enumerated() 
                    {
                        let code:(count:OpenGL.Enum, type:OpenGL.Enum)
                        
                        switch attribute 
                        {
                        case .uint8_bgra:
                            code.count = OpenGL.BGRA 
                        default:
                            code.count = .init(attribute.count)
                        }
                        
                        switch attribute 
                        {
                        case .int32, .int32x2, .int32x3, .int32x4:
                            code.type = OpenGL.INT 
                        case .int16, .int16x2, .int16x3, .int16x4:
                            code.type = OpenGL.SHORT
                        case .int8, .int8x2, .int8x3, .int8x4:
                            code.type = OpenGL.BYTE
                        
                        case .uint10x3:
                            code.type = OpenGL.UNSIGNED_INT_2_10_10_10_REV
                        
                        case .uint32, .uint32x2, .uint32x3, .uint32x4:
                            code.type = OpenGL.UNSIGNED_INT 
                        case .uint16, .uint16x2, .uint16x3, .uint16x4:
                            code.type = OpenGL.UNSIGNED_SHORT
                        case .uint8, .uint8x2, .uint8x3, .uint8x4, .uint8_bgra:
                            code.type = OpenGL.UNSIGNED_BYTE
                        
                        case .float64, .float64x2, .float64x3, .float64x4:
                            code.type = OpenGL.DOUBLE
                        case .float32, .float32x2, .float32x3, .float32x4:
                            code.type = OpenGL.FLOAT
                        case .float16, .float16x2, .float16x3, .float16x4:
                            code.type = OpenGL.HALF_FLOAT
                        }
                        
                        guard let offset:Int = MemoryLayout<Vertex>.offset(of: attribute.keyPath)
                        else 
                        {
                            Log.error("property '\(attribute.keyPath)' does not have storage in type '\(String.init(reflecting: Vertex.self))', vertex attribute \(index) disabled")
                            continue 
                        }
                        
                        switch attribute.destination 
                        {
                        case .int32:
                            OpenGL.glVertexAttribIPointer(
                                .init(index), code.count, code.type, .init(stride), 
                                UnsafeRawPointer.init(bitPattern: offset))
                        
                        case .float32(normalized: let normalize):
                            OpenGL.glVertexAttribPointer(
                                .init(index), code.count, code.type, normalize, .init(stride), UnsafeRawPointer.init(bitPattern: offset))
                        
                        case .float64:
                            OpenGL.glVertexAttribLPointer(
                                .init(index), code.count, code.type, .init(stride), UnsafeRawPointer.init(bitPattern: offset))
                        }
                        
                        OpenGL.glEnableVertexAttribArray(.init(index))
                    }
                    
                    OpenGL.glBindBuffer(Buffer.Target.IndexArray.code, indices.core.buffer)
                    OpenGL.glBindVertexArray(0)
                    OpenGL.glBindBuffer(Buffer.Target.Array.code, 0)
                    OpenGL.glBindBuffer(Buffer.Target.IndexArray.code, 0)
                }
                
                func draw(_ range:Range<Int>, as primitive:Primitive)
                {
                    OpenGL.glBindVertexArray(self.vertexArray)
                    OpenGL.glDrawArrays(primitive.code, .init(range.lowerBound), .init(range.count))
                    OpenGL.glBindVertexArray(0)
                }
                
                func draw(elements range:Range<Int>, as primitive:Primitive)
                {
                    OpenGL.glBindVertexArray(self.vertexArray)
                    OpenGL.glDrawElements(primitive.code, .init(range.count), Index.code, 
                        UnsafeRawPointer.init(bitPattern: range.lowerBound * MemoryLayout<Index>.stride))
                    OpenGL.glBindVertexArray(0)
                }
            }
            
            fileprivate 
            let core:Core 
            var buffers:(vertex:Buffer.Array<Vertex>, index:Buffer.IndexArray<Index>)
            
            var count:(vertex:Int, index:Int) 
            {
                (self.buffers.vertex.count, self.buffers.index.count)
            }
            
            init(vertices:Buffer.Array<Vertex>, indices:Buffer.IndexArray<Index>) 
            {
                self.core    = .create()
                self.buffers = (vertex: vertices, index: indices)
                
                // self.bind()
                self.core.attach(vertices: vertices, indices: indices)
            }
            
            deinit
            {
                self.core.destroy()
            }
            
            func draw(_ range:Range<Int>, as primitive:Primitive)
            {
                // self.bind()
                if range.count % primitive.stride != 0 
                {
                    Log.error("vertex count \(range.count) is not divisible by \(primitive.stride), as required by draw mode '\(primitive)'")
                }
                self.core.draw(range, as: primitive)
            }
            
            func draw(indices range:Range<Int>, as primitive:Primitive)
            {
                // self.bind()
                if range.count % primitive.stride != 0 
                {
                    Log.error("indices count \(range.count) is not divisible by \(primitive.stride), as required by draw mode '\(primitive)'")
                }
                self.core.draw(elements: range, as: primitive)
            }
        }
    }
    
    
    typealias AnyBuffer = _GPUAnyBuffer
    enum Buffer 
    {
        enum Hint 
        {
            case `static`, dynamic, streaming
            
            fileprivate 
            var code:OpenGL.Enum 
            {
                switch self 
                {
                case .`static`:
                    return OpenGL.STATIC_DRAW
                case .dynamic:
                    return OpenGL.DYNAMIC_DRAW 
                case .streaming:
                    return OpenGL.STREAM_DRAW
                }
            }
        }
        
        enum Layout 
        {
            enum STD140 
            {
                case float32    (Float)
                case float32x2  (Vector2<Float>)
                case float32x4  (Vector4<Float>)
                
                case float64    (Double)
                case float64x2  (Vector2<Double>)
                case float64x4  (Vector4<Double>)
                
                case int32      (Int32)
                case int32x2    (Vector2<Int32>)
                case int32x4    (Vector4<Int32>)
                
                case uint32     (UInt32)
                case uint32x2   (Vector2<UInt32>)
                case uint32x4   (Vector4<UInt32>)
                
                case matrix2    (Matrix2<Float>)
                case matrix3    (Matrix3<Float>)
                case matrix4    (Matrix4<Float>)
                
                
                var alignment:Int 
                {
                    let component:Int 
                    switch self 
                    {
                    case    .float32,  .float32x2, .float32x4, 
                            .matrix2,  .matrix3,   .matrix4:
                        component = MemoryLayout<Float>.stride 
                    case    .float64,  .float64x2, .float64x4:
                        component = MemoryLayout<Double>.stride 
                    case    .int32,    .int32x2,   .int32x4:
                        component = MemoryLayout<Int32>.stride 
                    case    .uint32,   .uint32x2,  .uint32x4:
                        component = MemoryLayout<UInt32>.stride 
                    }
                    
                    let count:Int 
                    switch self 
                    {
                    case    .float32,   .float64,   .int32,     .uint32:
                        count = 1 
                    case    .float32x2, .float64x2, .int32x2,   .uint32x2:
                        count = 2
                    case    .float32x4, .float64x4, .int32x4,   .uint32x4, 
                            .matrix2,   .matrix3,   .matrix4:
                        count = 4
                    }
                    
                    return component * count 
                }
            }
        }
        
        typealias AnyTarget = _GPUAnyBufferTarget
        enum Target 
        {
            enum Uniform:AnyTarget 
            {
                static 
                var code:OpenGL.Enum 
                {
                    OpenGL.UNIFORM_BUFFER
                }
            }
            enum Array:AnyTarget 
            {
                static 
                var code:OpenGL.Enum 
                {
                    OpenGL.ARRAY_BUFFER
                }
            }
            enum IndexArray:AnyTarget 
            {
                static 
                var code:OpenGL.Enum 
                {
                    OpenGL.ELEMENT_ARRAY_BUFFER
                }
            }
        }
        
        fileprivate 
        struct Core<Target> where Target:AnyTarget
        {
            let buffer:OpenGL.UInt 
            
            static 
            func create() -> Self 
            {
                let buffer:OpenGL.UInt = directReturn(default: 0) 
                {
                    OpenGL.glGenBuffers(1, $0)
                } 
                return .init(buffer: buffer)
            }
            
            func destroy() 
            {
                withUnsafePointer(to: self.buffer)
                {
                    OpenGL.glDeleteBuffers(1, $0)
                }
            }
            
            func data<CC>(_ data:CC, hint:Hint) 
                where CC:ContiguousCollection
            {
                OpenGL.glBindBuffer(Target.code, self.buffer)
                data.withUnsafeBytes 
                {
                    OpenGL.glBufferData(Target.code, $0.count, $0.baseAddress, hint.code)
                }
                OpenGL.glBindBuffer(Target.code, 0)
            }
            func subData<CC>(_ data:CC, offset:Int)
                where CC:ContiguousCollection
            {
                let offset:Int = offset * MemoryLayout<CC.Element>.stride
                OpenGL.glBindBuffer(Target.code, self.buffer)
                data.withUnsafeBytes 
                {
                    OpenGL.glBufferSubData(Target.code, offset, $0.count, $0.baseAddress)
                }
                OpenGL.glBindBuffer(Target.code, 0)
            }
        }
        
        typealias AnyUniform            = _GPUAnyBufferUniform
        typealias AnyArray              = _GPUAnyBufferArray
        typealias AnyIndexArray         = _GPUAnyBufferIndexArray
        
        typealias Uniform<Element>      = Buffer<Target.Uniform,    Element>
        typealias Array<Element>        = Buffer<Target.Array,      Element>
        typealias IndexArray<Element>   = Buffer<Target.IndexArray, Element> 
            where Element:Vertex.Element
        
        final 
        class Buffer<Target, Element>:AnyBuffer where Target:AnyTarget
        {
            private 
            let hint:Hint 
            private(set)
            var count:Int
            private  
            var capacity:Int
            
            fileprivate 
            let core:Core<Target>
            
            // `AnyBuffer` conformance 
            static 
            var stride:Int 
            {
                MemoryLayout<Element>.stride 
            }
            static 
            var target:AnyTarget.Type  
            {
                Target.self 
            }
            var buffer:OpenGL.UInt 
            {
                self.core.buffer  
            }
            let debugName:String
            
            init(hint:Hint, debugName:String = "<anonymous>") 
            {
                self.hint       = hint  
                self.count      = 0
                self.capacity   = 0
                self.core       = .create()
                self.debugName  = debugName
            }
            
            deinit 
            {
                self.core.destroy()
            }
            
            func assign<CC>(_ data:CC) 
                where CC:ContiguousCollection, CC.Element == Element 
            {
                if data.count > self.capacity || data.count < self.capacity / 2
                {
                    self.core.data(data, hint: self.hint)
                    self.count      = data.count 
                    self.capacity   = data.count 
                }
                else 
                {
                    self.core.subData(data, offset: 0)
                    self.count      = data.count 
                }
            }
            func assign<CC>(_ data:CC, at offset:Int) 
                where CC:ContiguousCollection, CC.Element == Element 
            {
                guard   offset >= 0, 
                        offset + data.count < self.count 
                else 
                {
                    Log.fatal("buffer assignment indices out of range (\(offset) ..< \(offset + data.count) in \(self.count)-element buffer")
                }
                
                self.core.subData(data, offset: offset)
            }
        }
    }
    
    typealias AnyTexture = _GPUAnyTexture
    enum Texture 
    {    
        enum Layout
        {
            case r8, rg8, rgb8, rgba8, bgra8, argb32atomic
            case rgba32f
            
            fileprivate 
            var storage:OpenGL.Enum 
            {
                switch self 
                {
                case .r8:
                    return OpenGL.R8
                case .rg8:
                    return OpenGL.RG8
                case .rgb8, .rgba8, .bgra8, .argb32atomic:
                    return OpenGL.RGBA8
                // case .rgba16f:
                //     return OpenGL.RGBA16F
                case .rgba32f:
                    return OpenGL.RGBA32F
                }
            }
            
            fileprivate 
            var layout:OpenGL.Enum 
            {
                switch self 
                {
                case .r8:
                    return OpenGL.RED 
                case .rg8:
                    return OpenGL.RG 
                case .rgb8:
                    return OpenGL.RGB 
                case .rgba8, .rgba32f:
                    return OpenGL.RGBA 
                case .bgra8, .argb32atomic:
                    return OpenGL.BGRA
                }
            }
            
            fileprivate 
            var type:OpenGL.Enum 
            {
                switch self 
                {
                case .r8, .rg8, .rgb8, .rgba8, .bgra8:
                    return OpenGL.UNSIGNED_BYTE
                case .argb32atomic:
                    return OpenGL.UNSIGNED_INT_8_8_8_8
                case .rgba32f:
                    return OpenGL.FLOAT
                }
            }
        }

        enum Filter 
        {
            case nearest, linear
        }
        
        typealias AnyTarget = _GPUAnyTextureTarget
        enum Target 
        {
            enum D2:AnyTarget 
            {
                static 
                var code:OpenGL.Enum 
                {
                    OpenGL.TEXTURE_2D
                }
            }
            enum D3:AnyTarget 
            {
                static 
                var code:OpenGL.Enum 
                {
                    OpenGL.TEXTURE_3D
                }
            }
            enum Cube:AnyTarget 
            {
                static 
                var code:OpenGL.Enum 
                {
                    OpenGL.TEXTURE_CUBE_MAP
                }
            }
        }
        
        fileprivate 
        struct Core<Target> where Target:AnyTarget
        {
            let texture:OpenGL.UInt 
            
            static 
            func create() -> Self 
            {
                let texture:OpenGL.UInt = directReturn(default: 0) 
                {
                    OpenGL.glGenTextures(1, $0)
                }
                
                return .init(texture: texture)
            }
            
            func destroy() 
            {
                withUnsafePointer(to: self.texture)
                {
                    OpenGL.glDeleteTextures(1, $0)
                }
            }
            
            func set(magnification:Filter, minification:Filter, mipmap:Filter?) 
            {
                let code:(minification:OpenGL.Enum, magnification:OpenGL.Enum)
                switch (minification, mipmap) 
                {
                case (.nearest, nil):
                    code.minification = OpenGL.NEAREST 
                case (.linear, nil):
                    code.minification = OpenGL.LINEAR
                case (.nearest, .nearest):
                    code.minification = OpenGL.NEAREST_MIPMAP_NEAREST 
                case (.nearest, .linear):
                    code.minification = OpenGL.NEAREST_MIPMAP_LINEAR
                
                case (.linear, .nearest):
                    code.minification = OpenGL.LINEAR_MIPMAP_NEAREST
                case (.linear, .linear):
                    code.minification = OpenGL.LINEAR_MIPMAP_LINEAR
                }
                switch magnification 
                {
                case .nearest:
                    code.magnification = OpenGL.NEAREST 
                case .linear:
                    code.magnification = OpenGL.LINEAR
                }
                
                OpenGL.glTexParameteri(Target.code, OpenGL.TEXTURE_MAG_FILTER, code.magnification)
                OpenGL.glTexParameteri(Target.code, OpenGL.TEXTURE_MIN_FILTER, code.minification)
            }
            
            func assign<Atom>(_ data:Array2D<Atom>, layout:Layout, mipmap:Bool)
            {
                let size:Vector2<OpenGL.Size> = .cast(data.size)
                OpenGL.glTexImage2D(Target.code, 0, layout.storage, 
                    size.x, size.y, 0, layout.layout, layout.type, data.buffer)
                if mipmap 
                {
                    OpenGL.glGenerateMipmap(Target.code)
                }
            }
            func assign<Atom>(_ data:Array3D<Atom>, layout:Layout, mipmap:Bool)
            {
                let size:Vector3<OpenGL.Size> = .cast(data.size)
                OpenGL.glTexImage3D(Target.code, 0, layout.storage, 
                    size.x, size.y, size.z, 0, layout.layout, layout.type, data.buffer)
                if mipmap 
                {
                    OpenGL.glGenerateMipmap(Target.code)
                }
            }
            func assign<Atom>(cubemap data:Array2D<Atom>, layout:Layout, mipmap:Bool)
            {
                let size:Vector2<OpenGL.Size> = .cast(.init(data.size.x, data.size.y / 6))
                for k:Int in 0 ..< 6 
                {
                    data.buffer.withUnsafeBufferPointer 
                    {
                        OpenGL.glTexImage2D(OpenGL.TEXTURE_CUBE_MAP_POSITIVE_X + .init(k), 0, layout.storage, 
                            size.x, size.y, 0, layout.layout, layout.type, $0.baseAddress.map{ $0 + k * .init(size.x * size.y) })
                    }
                }
                if mipmap 
                {
                    OpenGL.glGenerateMipmap(Target.code)
                }
            }
        }
        
        typealias AnyD2         = _GPUAnyTextureD2
        typealias AnyD3         = _GPUAnyTextureD3
        typealias AnyCube       = _GPUAnyTextureCube
        typealias D2<Element>   = Texture<Target.D2, Element>
        typealias D3<Element>   = Texture<Target.D3, Element>
        typealias Cube<Element> = Texture<Target.Cube, Element>
        
        final 
        class Texture<Target, Element>:AnyTexture where Target:AnyTarget
        {
            private 
            let layout:Layout, 
                mipmap:Bool
            
            fileprivate 
            let core:Core<Target>
            
            // `AnyTexture` conformance 
            static 
            var stride:Int 
            {
                MemoryLayout<Element>.stride 
            }
            static 
            var target:AnyTarget.Type  
            {
                Target.self
            }
            var texture:OpenGL.UInt 
            {
                self.core.texture 
            }
            let debugName:String 
            
            init(layout:Layout, 
                magnification:Filter, 
                minification:Filter, 
                mipmap:Filter? = nil, 
                debugName:String = "<anonymous>") 
            {
                self.layout     = layout 
                self.mipmap     = mipmap != nil 
                self.core       = .create()
                self.debugName  = debugName
                Manager.Texture.with(self) 
                {
                    self.core.set(magnification: magnification, minification: minification, mipmap: mipmap)
                }
            }
            
            deinit 
            {
                self.core.destroy()
            }
        }
    }
    
    final 
    class Program 
    {
        enum Error:RecursiveError 
        {
            case shader(name:String, error:Swift.Error)
            case linking(name:String, info:String)
            
            static 
            var namespace:String 
            {
                "program error"
            }
            var message:String 
            {
                switch self 
                {
                case .shader(name: let name, error: _):
                    return "failed to compile shader in program '\(name)'"
                case .linking(name: let name, info: let message):
                    return "failed to link program '\(name)' \n\(message)"
                }
            }
            var next:Swift.Error?
            {
                switch self 
                {
                case .shader(name: _, error: let error):
                    return error
                case .linking(name: _, info: _):
                    return nil
                }
            }
        }
        
        enum Shader 
        {
            case vertex, geometry, fragment
            
            enum Error:RecursiveError
            {
                case source(type:Shader, name:String, error:Swift.Error)
                case compilation(type:Shader, name:String, info:String)
                
                static 
                var namespace:String 
                {
                    "shader error"
                }
                var message:String
                {
                    switch self 
                    {
                    case .source(type: let type, name: let name, error: _):
                        return "failed to load source(s) for \(String.init(describing: type)) shader '\(name)'"
                    case .compilation(type: let type, name: let name, info: let message):
                        return "failed to compile \(String.init(describing: type)) shader '\(name)' \n\(message)"
                    }
                }
                var next:Swift.Error?
                {
                    switch self 
                    {
                    case .source(type: _, name: _, error: let error):
                        return error
                    case .compilation(type: _, name: _, info: _):
                        return nil
                    }
                }
            }
            
            fileprivate 
            struct Core 
            {
                let shader:OpenGL.UInt
                
                static 
                func create(type:Shader) -> Self
                {
                    let code:OpenGL.Enum 
                    switch type 
                    {
                    case .vertex:
                        code = OpenGL.VERTEX_SHADER
                    case .geometry:
                        code = OpenGL.GEOMETRY_SHADER 
                    case .fragment:
                        code = OpenGL.FRAGMENT_SHADER
                    }
                    
                    return .init(shader: OpenGL.glCreateShader(code))
                }
                
                // true if successful. does *not* delete the shader on failure
                func compile<CC>(_ source:CC) -> Bool  
                    where CC:ContiguousCollection, CC.Element == UInt8
                {
                    source.withUnsafeBufferPointer 
                    {
                        $0.withMemoryRebound(to: Int8.self) 
                        {
                            let length:OpenGL.Int           = .init(source.count), 
                                string:UnsafePointer<Int8>? = $0.baseAddress
                            withUnsafePointer(to: string) 
                            {
                                string in 
                                withUnsafePointer(to: length) 
                                {
                                    length in 
                                    OpenGL.glShaderSource(self.shader, 1, string, length)
                                }
                            }
                        }
                    }
                    
                    OpenGL.glCompileShader(self.shader)
                    return self.check() 
                }
                
                func destroy() 
                {
                    OpenGL.glDeleteShader(self.shader)
                }
                
                func info() -> String
                {
                    let count:OpenGL.Size = directReturn(default: 0) 
                    {
                        OpenGL.glGetShaderiv(self.shader, OpenGL.INFO_LOG_LENGTH, $0)
                    }
                    
                    return stringFromBuffer(capacity: .init(count))
                    {
                        OpenGL.glGetShaderInfoLog(self.shader, count, nil, $0)
                    }
                }
                
                private 
                func check() -> Bool
                {
                    return 1 == directReturn(default: 0) 
                    {
                        OpenGL.glGetShaderiv(self.shader, OpenGL.COMPILE_STATUS, $0)
                    }
                }
            }
        }
        
        enum Constant:Equatable
        {
            case float32    (Float)
            case float32x2  (Vector2<Float>)
            case float32x3  (Vector3<Float>)
            case float32x4  (Vector4<Float>)
            
            case int32      (Int32)
            case int32x2    (Vector2<Int32>)
            case int32x3    (Vector3<Int32>)
            case int32x4    (Vector4<Int32>)
            
            case uint32     (UInt32)
            case uint32x2   (Vector2<UInt32>)
            case uint32x3   (Vector3<UInt32>)
            case uint32x4   (Vector4<UInt32>)
            
            case matrix2    (Matrix2<Float>)
            case matrix3    (Matrix3<Float>)
            case matrix4    (Matrix4<Float>)
            
            case texture2   (Texture.AnyD2)
            case texture3   (Texture.AnyD3)
            case textureCube(Texture.AnyCube)
            
            case block      (Buffer.AnyUniform, range:Range<Int>)
            
            static 
            func float32<T>(normalizing int:T) -> Self 
                where T:FixedWidthInteger & UnsignedInteger
            {
                return .float32(.init(int) / .init(T.max))
            }
            static 
            func float32x2<T>(normalizing int:Vector2<T>) -> Self 
                where T:FixedWidthInteger & UnsignedInteger & SIMDScalar
            {
                return .float32x2(.cast(int) / .init(T.max))
            }
            static 
            func float32x3<T>(normalizing int:Vector3<T>) -> Self 
                where T:FixedWidthInteger & UnsignedInteger & SIMDScalar
            {
                return .float32x3(.cast(int) / .init(T.max))
            }
            static 
            func float32x4<T>(normalizing int:Vector4<T>) -> Self 
                where T:FixedWidthInteger & UnsignedInteger & SIMDScalar
            {
                return .float32x4(.cast(int) / .init(T.max))
            }
            
            static 
            func block(_ block:Buffer.AnyUniform) -> Self 
            {
                return .block(block, range: 0 ..< block.count)
            }
            
            fileprivate 
            var typeIdentifier:String 
            {
                switch self 
                {
                case    .float32    (let value as Any),
                        .float32x2  (let value as Any),
                        .float32x3  (let value as Any),
                        .float32x4  (let value as Any),
                
                        .int32      (let value as Any),
                        .int32x2    (let value as Any),
                        .int32x3    (let value as Any),
                        .int32x4    (let value as Any),
                
                        .uint32     (let value as Any),
                        .uint32x2   (let value as Any),
                        .uint32x3   (let value as Any),
                        .uint32x4   (let value as Any),
                
                        .matrix2    (let value as Any),
                        .matrix3    (let value as Any),
                        .matrix4    (let value as Any),
                
                        .texture2   (let value as Any),
                        .texture3   (let value as Any),
                        .textureCube(let value as Any):
                    return .init(describing: type(of: value))
                
                case    .block      (let value as Any, range: let range):
                    return "\(String.init(describing: type(of: value)))[\(range.count)]"
                }
            }
            
            // has to be manual 
            static 
            func == (lhs:Self, rhs:Self) -> Bool 
            {
                switch (lhs, rhs) 
                {
                case (.float32    (let v1), .float32    (let v2)):
                    return v1 == v2
                case (.float32x2  (let v1), .float32x2  (let v2)):
                    return v1 == v2
                case (.float32x3  (let v1), .float32x3  (let v2)):
                    return v1 == v2
                case (.float32x4  (let v1), .float32x4  (let v2)):
                    return v1 == v2
                
                case (.int32      (let v1), .int32      (let v2)):
                    return v1 == v2
                case (.int32x2    (let v1), .int32x2    (let v2)):
                    return v1 == v2
                case (.int32x3    (let v1), .int32x3    (let v2)):
                    return v1 == v2
                case (.int32x4    (let v1), .int32x4    (let v2)):
                    return v1 == v2
                
                case (.uint32     (let v1), .uint32     (let v2)):
                    return v1 == v2
                case (.uint32x2   (let v1), .uint32x2   (let v2)):
                    return v1 == v2
                case (.uint32x3   (let v1), .uint32x3   (let v2)):
                    return v1 == v2
                case (.uint32x4   (let v1), .uint32x4   (let v2)):
                    return v1 == v2
                
                case (.matrix2    (let v1), .matrix2    (let v2)):
                    return v1 == v2
                case (.matrix3    (let v1), .matrix3    (let v2)):
                    return v1 == v2
                case (.matrix4    (let v1), .matrix4    (let v2)):
                    return v1 == v2
                
                case (.texture2   (let t1), .texture2   (let t2)):
                    return t1 === t2
                case (.texture3   (let t1), .texture3   (let t2)):
                    return t1 === t2
                case (.textureCube(let t1), .textureCube(let t2)):
                    return t1 === t2
                
                case (.block      (let b1, range: let r1), .block      (let b2, range: let r2)):
                    return b1 === b2 && r1 == r2
                
                default:
                    return false
                }
            }
        }
        
        fileprivate 
        struct Core 
        {
            private 
            struct Parameter:CustomStringConvertible
            {
                enum Datatype 
                {
                    case float32, float32x2, float32x3, float32x4
                    case int32, int32x2, int32x3, int32x4 
                    case uint32, uint32x2, uint32x3, uint32x4
                    
                    case matrix2, matrix3, matrix4
                    case texture2, texture3, textureCube
                    case block(size:Int)
                    
                    fileprivate 
                    var identifier:String 
                    {
                        let metatype:Any.Type
                        switch self 
                        {
                        case .float32:
                            metatype = Float.self 
                        case .float32x2: 
                            metatype = Vector2<Float>.self 
                        case .float32x3:
                            metatype = Vector3<Float>.self 
                        case .float32x4:
                            metatype = Vector4<Float>.self 
                            
                        case .int32:
                            metatype = Int.self 
                        case .int32x2: 
                            metatype = Vector2<Int>.self 
                        case .int32x3:
                            metatype = Vector3<Int>.self 
                        case .int32x4:
                            metatype = Vector4<Int>.self 
                            
                        case .uint32:
                            metatype = UInt.self 
                        case .uint32x2: 
                            metatype = Vector2<UInt>.self 
                        case .uint32x3:
                            metatype = Vector3<UInt>.self 
                        case .uint32x4:
                            metatype = Vector4<UInt>.self 
                        
                        case .matrix2:
                            metatype = Matrix2<Float>.self
                        case .matrix3:
                            metatype = Matrix3<Float>.self
                        case .matrix4:
                            metatype = Matrix4<Float>.self
                        
                        case .texture2:
                            metatype = Texture.AnyD2.self 
                        case .texture3:
                            metatype = Texture.AnyD3.self 
                        case .textureCube:
                            metatype = Texture.AnyCube.self 
                        
                        case .block(size: let size):
                            metatype = Buffer.AnyUniform.self 
                            return "\(String.init(describing: metatype))[\(size)]"
                        }
                        
                        return .init(describing: metatype)
                    }
                }
                
                let name:String, 
                    type:Datatype, 
                    location:OpenGL.Int
                
                var description:String 
                {
                    "@\(location): var \(name):\(type)"
                }
            }
            
            let program:OpenGL.UInt 
            private 
            var parameters:[Parameter]
            
            static 
            func create() -> Self 
            {
                let program:OpenGL.UInt = OpenGL.glCreateProgram()
                return .init(program: program, parameters: [])
            }
            
            func destroy()
            {
                OpenGL.glDeleteProgram(self.program)
            }
            
            mutating 
            func link(_ shaders:[Shader.Core]) -> Bool 
            {
                for shader:Shader.Core in shaders
                {
                    OpenGL.glAttachShader(self.program, shader.shader)
                }
                
                OpenGL.glLinkProgram(self.program)
                
                for shader:Shader.Core in shaders
                {
                    OpenGL.glDetachShader(self.program, shader.shader)
                }
                
                defer 
                {
                    self.parameters = self.inspectBlocks() + self.inspectParameters()
                }
                
                return self.check()
            }
            
            // requires program to be bound
            mutating 
            func push(constants:[String: Constant]) 
            {
                var unused:Set<String> = .init(constants.keys)
                for parameter:Parameter in self.parameters 
                {
                    guard let constant:Constant = constants[parameter.name] 
                    else 
                    {
                        continue 
                    }
                    
                    unused.remove(parameter.name)
                    
                    switch (parameter.type, constant) 
                    {
                    case (.float32,     .float32    (let v)):
                        OpenGL.glUniform1f(parameter.location, v)
                    case (.float32x2,   .float32x2  (let v)):
                        OpenGL.glUniform2f(parameter.location, v.x, v.y)
                    case (.float32x3,   .float32x3  (let v)):
                        OpenGL.glUniform3f(parameter.location, v.x, v.y, v.z)
                    case (.float32x4,   .float32x4  (let v)):
                        OpenGL.glUniform4f(parameter.location, v.x, v.y, v.z, v.w)
                    
                    case (.int32,       .int32      (let v)):
                        OpenGL.glUniform1i(parameter.location, v)
                    case (.int32x2,     .int32x2    (let v)):
                        OpenGL.glUniform2i(parameter.location, v.x, v.y)
                    case (.int32x3,     .int32x3    (let v)):
                        OpenGL.glUniform3i(parameter.location, v.x, v.y, v.z)
                    case (.int32x4,     .int32x4    (let v)):
                        OpenGL.glUniform4i(parameter.location, v.x, v.y, v.z, v.w)
                    
                    case (.uint32,      .uint32     (let v)):
                        OpenGL.glUniform1ui(parameter.location, v)
                    case (.uint32x2,    .uint32x2   (let v)):
                        OpenGL.glUniform2ui(parameter.location, v.x, v.y)
                    case (.uint32x3,    .uint32x3   (let v)):
                        OpenGL.glUniform3ui(parameter.location, v.x, v.y, v.z)
                    case (.uint32x4,    .uint32x4   (let v)):
                        OpenGL.glUniform4ui(parameter.location, v.x, v.y, v.z, v.w)
                    
                    // matrices need to be explicitly flattened, as swift may 
                    // insert padding in between columns.
                    // swift should allocate local `Array`s here on the stack 
                    // since they never leave the local scope.
                    case (.matrix2,     .matrix2    (let M)):
                        let flattened:[Float] = 
                        [
                            M[0].x, M[0].y, 
                            M[1].x, M[1].y
                        ]
                        OpenGL.glUniformMatrix2fv(parameter.location, 4, false, flattened)
                    case (.matrix3,     .matrix3    (let M)):
                        let flattened:[Float] = 
                        [
                            M[0].x, M[0].y, M[0].z, 
                            M[1].x, M[1].y, M[1].z, 
                            M[2].x, M[2].y, M[2].z
                        ]
                        OpenGL.glUniformMatrix3fv(parameter.location, 9, false, flattened)
                    case (.matrix4,     .matrix4    (let M)):
                        let flattened:[Float] = 
                        [
                            M[0].x, M[0].y, M[0].z, M[0].w, 
                            M[1].x, M[1].y, M[1].z, M[1].w, 
                            M[2].x, M[2].y, M[2].z, M[2].w, 
                            M[3].x, M[3].y, M[3].z, M[3].w
                        ]
                        OpenGL.glUniformMatrix4fv(parameter.location, 16, false, flattened)
                    
                    case    (.texture2,     .texture2   (let texture as AnyTexture)), 
                            (.texture3,     .texture3   (let texture as AnyTexture)),
                            (.textureCube,  .textureCube(let texture as AnyTexture)):
                        if let index:Int = Manager.Texture.pin(texture) 
                        {
                            OpenGL.glUniform1i(parameter.location, .init(index))
                        }
                        else 
                        {
                            Log.error("could not push texture constant '\(texture.debugName)' to texture parameter '\(parameter.name)' (no free texture units)")
                            OpenGL.glUniform1i(parameter.location, -1)
                        }
                    
                    case (.block(size: let size), .block(let buffer, let range)):
                        if size < range.count 
                        {
                            Log.warning("uniform (sub)buffer '\(buffer.debugName)' has size \(range.count), but block parameter '\(parameter.name)' has size \(size)")
                        }
                        
                        if let index:Int = Manager.UniformBuffer.pin((buffer, range)) 
                        {
                            OpenGL.glUniformBlockBinding(self.program, .init(parameter.location), .init(index))
                        }
                        else 
                        {
                            Log.error("could not push uniform (sub)buffer '\(buffer.debugName)' to block parameter '\(parameter.name)' (no free uniform buffer binding points)")
                            OpenGL.glUniformBlockBinding(self.program, .init(parameter.location), .max)
                        }
                    
                    default:
                        Log.error("cannot push constant of type '\(constant.typeIdentifier)' to parameter '\(parameter.name)' of type '\(parameter.type.identifier)'")
                    }
                }
                
                guard unused.isEmpty 
                else 
                {
                    for identifier:String in unused 
                    {
                        Log.warning("could not push constant of type '\(constants[identifier]?.typeIdentifier ?? "")' to non-existent parameter '\(identifier)'")
                    }
                    return
                }
            }
            
            private 
            func inspectParameters() -> [Parameter] 
            {
                let count:OpenGL.Int = self.countResources(OpenGL.UNIFORM)
                // should generate stack-allocated local array
                let properties:[OpenGL.Enum] = 
                [
                    OpenGL.NAME_LENGTH, 
                    OpenGL.TYPE, 
                    OpenGL.ARRAY_SIZE,
                    OpenGL.LOCATION
                ]
                
                return (0 ..< .init(count)).compactMap 
                {
                    (i:OpenGL.UInt) in
                    
                    // https://forums.swift.org/t/can-i-use-a-tuple-to-force-a-certain-memory-layout/6358/10
                    let buffer:
                    (
                        nameCount:OpenGL.Int, 
                        type:OpenGL.Int, 
                        count:OpenGL.Int, 
                        location:OpenGL.Int
                    ) = directReturn(default: (0, 0, 0, 0)) 
                    {
                        $0.withMemoryRebound(to: OpenGL.Int.self, capacity: properties.count) 
                        {
                            OpenGL.glGetProgramResourceiv(self.program, 
                                OpenGL.UNIFORM, i, .init(properties.count), properties, 
                                .init(properties.count), nil, $0)
                        }
                    }
                    
                    // skip uniforms nested in blocks
                    guard buffer.location != -1 
                    else 
                    {
                        return nil  
                    }
                    
                    let name:String = stringFromBuffer(capacity: .init(buffer.nameCount))
                    {
                        OpenGL.glGetProgramResourceName(self.program, 
                            OpenGL.UNIFORM, i, buffer.nameCount, nil, $0)
                    }
                    
                    let type:Parameter.Datatype
                    switch buffer.type 
                    {
                        case OpenGL.FLOAT:
                            type = .float32
                        case OpenGL.FLOAT_VEC2:
                            type = .float32x2
                        case OpenGL.FLOAT_VEC3:
                            type = .float32x3
                        case OpenGL.FLOAT_VEC4:
                            type = .float32x4
                        
                        case OpenGL.INT:
                            type = .int32
                        case OpenGL.INT_VEC2:
                            type = .int32x2
                        case OpenGL.INT_VEC3:
                            type = .int32x3
                        case OpenGL.INT_VEC4:
                            type = .int32x4
                        
                        case OpenGL.UNSIGNED_INT:
                            type = .uint32
                        case OpenGL.UNSIGNED_INT_VEC2:
                            type = .uint32x2
                        case OpenGL.UNSIGNED_INT_VEC3:
                            type = .uint32x3
                        case OpenGL.UNSIGNED_INT_VEC4:
                            type = .uint32x4
                        
                        case OpenGL.FLOAT_MAT2:
                            type = .matrix2
                        case OpenGL.FLOAT_MAT3:
                            type = .matrix3
                        case OpenGL.FLOAT_MAT4:
                            type = .matrix4
                        
                        case OpenGL.SAMPLER_2D:
                            type = .texture2
                        case OpenGL.SAMPLER_3D:
                            type = .texture3
                        case OpenGL.SAMPLER_CUBE:
                            type = .textureCube
                        
                        default:
                            Log.warning("uniform '\(name)' has unsupported glsl type (code \(buffer.type))")
                            return nil 
                    }
                    
                    return .init(name: name, type: type, location: buffer.location)
                }
            }
            
            private 
            func inspectBlocks() -> [Parameter] 
            {
                let count:OpenGL.Int = self.countResources(OpenGL.UNIFORM_BLOCK)
                
                // https://forums.swift.org/t/can-i-use-a-tuple-to-force-a-certain-memory-layout/6358/10
                let properties:[OpenGL.Enum] = 
                [
                    OpenGL.NAME_LENGTH, 
                    OpenGL.BUFFER_DATA_SIZE
                ]
                
                return (0 ..< .init(count)).map 
                {
                    (i:OpenGL.UInt) in
                    
                    let buffer:
                    (
                        nameCount:OpenGL.Int, 
                        size:OpenGL.Int
                    ) = directReturn(default: (0, 0)) 
                    {
                        $0.withMemoryRebound(to: OpenGL.Int.self, capacity: properties.count) 
                        {
                            OpenGL.glGetProgramResourceiv(self.program, 
                                OpenGL.UNIFORM_BLOCK, i, .init(properties.count), properties, 
                                .init(properties.count), nil, $0)
                        }
                    }
                    
                    let name:String = stringFromBuffer(capacity: .init(buffer.nameCount))
                    {
                        OpenGL.glGetProgramResourceName(self.program, 
                            OpenGL.UNIFORM_BLOCK, i, buffer.nameCount, nil, $0)
                    }
                    
                    let location:OpenGL.Int = .init(i)
                    return .init(name: name, type: .block(size: .init(buffer.size)), 
                        location: location)
                }
            }
            
            private 
            func countResources(_ interface:OpenGL.Enum) -> OpenGL.Int 
            {
                return directReturn(default: 0) 
                {
                    OpenGL.glGetProgramInterfaceiv(self.program, 
                        interface, OpenGL.ACTIVE_RESOURCES, $0)
                }
            }
            
            func info() -> String
            {
                let count:OpenGL.Int = directReturn(default: 0) 
                {
                    OpenGL.glGetProgramiv(self.program, OpenGL.INFO_LOG_LENGTH, $0)
                }
                
                return stringFromBuffer(capacity: .init(count))
                {
                    OpenGL.glGetProgramInfoLog(self.program, count, nil, $0)
                }
            }
            
            private 
            func check() -> Bool
            {
                return 1 == directReturn(default: 0) 
                {
                    OpenGL.glGetProgramiv(self.program, OpenGL.LINK_STATUS, $0)
                }
            }
        }
        
        fileprivate 
        var core:Core 
        
        let debugName:String 
        
        convenience 
        init(_ paths:[(type:Shader, path:String)], debugName:String = "<anonymous>") throws
        {
            let sources:[(type:Shader, source:[UInt8], name:String)] = try paths.map 
            {
                let (type, path):(Shader, String) = $0 
                do 
                {
                    return (type, try File.read(from: path), path)
                }
                catch 
                {
                    throw   Error.shader(name: debugName, error: 
                            Shader.Error.source(type: type, name: path, error: error)
                            )
                }
            }
            
            try self.init(sources, debugName: debugName)
        }
        
        private 
        init<CC>(_ sources:[(type:Shader, source:CC, name:String)], debugName:String) throws 
            where CC:ContiguousCollection, CC.Element == UInt8
        {
            var shaders:[Shader.Core] = []
            for (type, source, name):(Shader, CC, String) in sources 
            {
                let core:Shader.Core = .create(type: type)
                
                guard core.compile(source)
                else 
                {
                    defer 
                    {
                        core.destroy()
                        for core:Shader.Core in shaders 
                        {
                            core.destroy()
                        }    
                    }
                    
                    throw   Error.shader(name: debugName, error: 
                            Shader.Error.compilation(type: type, name: name, info: core.info())
                            )
                }
                
                Log.note("compiled \(String.init(describing: type)) shader '\(name)' in program '\(debugName)'")
                let log:String = core.info()
                if !log.isEmpty 
                {
                    Log.note(log, from: .glsl)
                }
                shaders.append(core)
            }
            
            defer 
            {
                for core:Shader.Core in shaders 
                {
                    core.destroy()
                }
            }
            
            self.core       = .create()
            self.debugName  = debugName
            guard self.core.link(shaders) 
            else 
            {
                defer 
                {
                    self.core.destroy() 
                }
                
                throw Error.linking(name: debugName, info: self.core.info())
            }
            
            Log.note("linked program '\(debugName)' (\(shaders.count) shaders)")
            let log:String = self.core.info()
            if !log.isEmpty 
            {
                Log.note(log, from: .glsl)
            }
        }
        
        deinit 
        {
            self.core.destroy()
        }
        
        private 
        func bind() 
        {
            if let old:Program = Manager.Program.bound
            {
                guard old !== self 
                else 
                {
                    return 
                }
            }
            
            OpenGL.glUseProgram(self.core.program)
            Manager.Program.bound = self
        }
        
        func push(constants:[String: Constant]) 
        {
            self.bind()
            self.core.push(constants: constants)
        }
    }
}
extension GPU.Texture.D2:GPU.Texture.AnyD2
{
    func assign(_ data:Array2D<Element>)
    {
        GPU.Manager.Texture.with(self) 
        {
            self.core.assign(data, layout: self.layout, mipmap: self.mipmap)
        }
    }
}
extension GPU.Texture.D3:GPU.Texture.AnyD3
{
    func assign(_ data:Array3D<Element>)
    {
        GPU.Manager.Texture.with(self) 
        {
            self.core.assign(data, layout: self.layout, mipmap: self.mipmap)
        }
    }
}
extension GPU.Texture.Cube:GPU.Texture.AnyCube
{
    func assign(cubemap data:Array2D<Element>)
    {
        GPU.Manager.Texture.with(self) 
        {
            self.core.assign(cubemap: data, layout: self.layout, mipmap: self.mipmap)
        }
    }
}

extension GPU.Buffer.Uniform:GPU.Buffer.AnyUniform
{
}
extension GPU.Buffer.Uniform where Element == UInt8
{
    func assign(std140:GPU.Buffer.Layout.STD140...)
    {
        var data:[UInt8] = []
            data.reserveCapacity(self.count)
        for attribute:GPU.Buffer.Layout.STD140 in std140 
        {
            // insert padding if needed 
            let padding:Int = attribute.alignment - data.count % attribute.alignment
            if padding != attribute.alignment 
            {
                data.append(contentsOf: repeatElement(0, count: padding))
            }
            
            switch attribute 
            {
            case .float32(let value):
                withUnsafeBytes(of: value)          { data.append(contentsOf: $0) }
            case .float32x2(let value):
                withUnsafeBytes(of: value.tuple)    { data.append(contentsOf: $0) }
            case .float32x4(let value):
                withUnsafeBytes(of: value.tuple)    { data.append(contentsOf: $0) }
            case .float64(let value):
                withUnsafeBytes(of: value)          { data.append(contentsOf: $0) }
            case .float64x2(let value):
                withUnsafeBytes(of: value.tuple)    { data.append(contentsOf: $0) }
            case .float64x4(let value):
                withUnsafeBytes(of: value.tuple)    { data.append(contentsOf: $0) }
            case .int32(let value):
                withUnsafeBytes(of: value)          { data.append(contentsOf: $0) }
            case .int32x2(let value):
                withUnsafeBytes(of: value.tuple)    { data.append(contentsOf: $0) }
            case .int32x4(let value):
                withUnsafeBytes(of: value.tuple)    { data.append(contentsOf: $0) }
            case .uint32(let value):
                withUnsafeBytes(of: value)          { data.append(contentsOf: $0) }
            case .uint32x2(let value):
                withUnsafeBytes(of: value.tuple)    { data.append(contentsOf: $0) }
            case .uint32x4(let value):
                withUnsafeBytes(of: value.tuple)    { data.append(contentsOf: $0) }
            
            case .matrix2(let M):
                let slug:
                (
                    (Float, Float, Float, Float),
                    (Float, Float, Float, Float)
                ) = 
                (
                    (M[0].x, M[0].y, 0, 0),
                    (M[1].x, M[1].y, 0, 0)
                )
                withUnsafeBytes(of: slug){ data.append(contentsOf: $0) }
            
            case .matrix3(let M):
                let slug:
                (
                    (Float, Float, Float, Float),
                    (Float, Float, Float, Float),
                    (Float, Float, Float, Float)
                ) = 
                (
                    (M[0].x, M[0].y, M[0].z, 0),
                    (M[1].x, M[1].y, M[1].z, 0),
                    (M[2].x, M[2].y, M[2].z, 0)
                )
                withUnsafeBytes(of: slug){ data.append(contentsOf: $0) }
            
            case .matrix4(let M):
                let slug:
                (
                    (Float, Float, Float, Float),
                    (Float, Float, Float, Float),
                    (Float, Float, Float, Float),
                    (Float, Float, Float, Float)
                ) = 
                (
                    (M[0].x, M[0].y, M[0].z, M[0].w),
                    (M[1].x, M[1].y, M[1].z, M[1].w),
                    (M[2].x, M[2].y, M[2].z, M[2].w),
                    (M[3].x, M[3].y, M[3].z, M[3].w)
                )
                withUnsafeBytes(of: slug){ data.append(contentsOf: $0) }
            }
        }
        
        self.assign(data)
    }
}
extension GPU.Buffer.Array:GPU.Buffer.AnyArray
{
}
extension GPU.Buffer.IndexArray:GPU.Buffer.AnyIndexArray
{
}

fileprivate 
protocol _StateManager 
{
    associatedtype Instance 
    
    static 
    var active:Int 
    {
        get 
        set 
    }
    
    static 
    var indices:Range<Int> 
    {
        get 
    }
    
    // reserved index, for anonymous transactions
    static 
    var reserved:Int 
    {
        get 
    }
    
    static 
    subscript(index:Int) -> (instance:Instance, pinned:Bool)? 
    {
        get 
        set
    }
    
    static 
    var initialized:Bool 
    {
        get 
    }
    
    static 
    func initialize()
    
    // used to bypass retain/releases when toggling the pin flag
    // does nothing if the instance unit at `index` is uninhabited
    static 
    func set(pin index:Int, to pinned:Bool)
    
    static 
    func identical(_ instance1:Instance, _ instance2:Instance) -> Bool 
    
    static 
    func bind(_ new:Instance)
    
    static 
    func bind(_ new:Instance, replacing old:Instance)
    
    static 
    func unbind(_ old:Instance) 
}
extension GPU.StateManager  
{
    static 
    var reserved:Int 
    {
        0
    }
    
    private static 
    var binding:(instance:Instance, pinned:Bool)? 
    {
        get 
        {
            Self[Self.active] 
        }
        set(new) // setter does not update pinnings (but will clear them if set to `nil`)
        {
            switch (Self.binding?.instance, new)
            {
            case (let old?, let (new, pinned)?):
                if Self.identical(old, new) 
                {
                    Self.set(pin: Self.active, to: pinned)
                }
                else 
                {
                    Self.bind(new, replacing: old)
                    Self[Self.active] = (new, pinned)
                }
            
            case (nil,      let (new, pinned)?):
                Self.bind(new)
                Self[Self.active] = (new, pinned)
            
            case (let old?, nil):
                Self.unbind(old)
                Self[Self.active] = nil 
            
            case (nil,      nil):
                break
            }
        }
    }
    
    // look for a free texture unit, or one that is already bound to 
    // the texture we’re trying to pin.
    // this is a stateful API. the given texture is bound in the gl context 
    // until the next call to this API.
    static 
    func pin(_ instance:Instance) -> Int? 
    {
        if !Self.initialized 
        {
            Self.initialize()
        }
        
        var slot:Int? = nil 
        // reverse search just so empty slots with low indices get picked 
        // first.
        for index:Int in Self.indices.reversed() where index != Self.reserved
        {
            if let (occupant, pinned):(Instance, Bool) = Self[index]
            {
                if Self.identical(occupant, instance) 
                {
                    Self.active = index 
                    Self.set(pin: index, to: true)
                    return Self.active
                }
                else if pinned 
                {
                    continue 
                }
            }
            
            slot = index 
        }
        
        if let slot:Int = slot 
        {
            Self.active  = slot 
            Self.binding = (instance, true) 
            return Self.active 
        }
        
        return nil
    }
    
    // switches to the given texture unit, binds the given texture, executes the 
    // given closure, then restores the state. 
    static 
    func with<R>(_ instance:Instance, boundTo index:Int = 0, body:() throws -> R) 
        rethrows -> R
    {
        if !Self.initialized 
        {
            Self.initialize()
        }
        
        let old:(Instance, Bool)?   = Self[index],
            active:Int              = Self.active 
        
        Self.active = index
        defer 
        {
            Self.active = active
        }
        
        Self.binding = (instance, true) 
        defer 
        {
            Self.binding = old 
        }
        
        return try body()
    }
    
    static 
    func unpin(_ index:Int) 
    {
        Self.set(pin: index, to: false)
    }
    
    static 
    func unpinAll() 
    {
        for index:Int in Self.indices 
        {
            Self.unpin(index)
        }
    }
}

// global state management 
fileprivate 
extension GPU 
{
    typealias StateManager = _StateManager
    enum Manager 
    {
        /*
        enum VertexArray 
        {
            static 
            var bound:GPU.Vertex.AnyArray? = nil
        }
        */
        enum Program 
        {
            static 
            var bound:GPU.Program? = nil
        }
        
        enum Texture:StateManager
        {
            typealias Instance = AnyTexture
            
            // need this because an eraser type can’t be used as a generic parameter with 
            // constraints (like `AnyObject`)
            private 
            struct Unit 
            {
                private weak 
                var object:AnyTexture?
                private 
                var flag:Bool 
                
                var load:(instance:Instance, pinned:Bool)?
                {
                    self.object.map{ ($0, self.flag) }
                }
                
                static 
                func store(_ element:(instance:Instance, pinned:Bool)?) -> Self 
                {
                    return .init(object: element?.instance, flag: element?.pinned ?? false)
                }
                
                mutating 
                func pin(_ pinned:Bool) 
                {
                    self.flag = pinned && self.object != nil
                }
            }
            
            // unit 0 is reserved as scratch space 
            private static 
            var units:[Unit] = []
            
            static 
            var active:Int = 0 
            {
                willSet(index) 
                {
                    if Self.active != index 
                    {
                        OpenGL.glActiveTexture(OpenGL.TEXTURE0 + .init(index))
                    }
                }
            } 
            
            static 
            var indices:Range<Int> 
            {
                self.units.indices
            }
            
            static 
            subscript(index:Int) -> (instance:Instance, pinned:Bool)? 
            {
                get 
                {
                    self.units[index].load 
                }
                set(new)
                {
                    self.units[index] = .store(new)
                }
            }
            
            static 
            var initialized:Bool 
            {
                !self.units.isEmpty 
            }
            
            static 
            func initialize() 
            {
                let count:Int = directReturn(default: 0, as: Int.self) 
                {
                    OpenGL.glGetIntegerv(OpenGL.MAX_COMBINED_TEXTURE_IMAGE_UNITS, $0)
                } 
                
                Self.units = .init(repeating: .store(nil), count: count)
                Log.note("initialized texture units (\(count) available)")
            }
            
            static 
            func set(pin index:Int, to pinned:Bool)
            {
                Self.units[index].pin(pinned)
            }
            
            static 
            func identical(_ instance1:Instance, _ instance2:Instance) -> Bool 
            {
                return instance1 === instance2
            }
            
            static 
            func bind(_ new:Instance)
            {
                OpenGL.glBindTexture(type(of: new).target.code, new.texture)
            }
            
            static 
            func bind(_ new:Instance, replacing old:Instance)
            {
                if type(of: old).target != type(of: new).target 
                {
                    Self.unbind(old)
                }
                Self.bind(new)
            }
            
            static 
            func unbind(_ old:Instance) 
            {
                OpenGL.glBindTexture(type(of: old).target.code, 0)
            }
        }
        
        enum UniformBuffer:StateManager
        {
            typealias Instance = (Buffer.AnyUniform, Range<Int>)
            
            // need this because an eraser type can’t be used as a generic parameter with 
            // constraints (like `AnyObject`)
            private 
            struct Unit 
            {
                private weak 
                var object:Buffer.AnyUniform?
                private 
                let range:Range<Int>
                private 
                var flag:Bool 
                
                var load:(instance:Instance, pinned:Bool)?
                {
                    self.object.map{ (($0, self.range), self.flag) }
                }
                
                static 
                func store(_ element:(instance:Instance, pinned:Bool)?) -> Self 
                {
                    return .init(object: element?.instance.0, 
                        range: element?.instance.1 ?? 0 ..< 0, 
                        flag: element?.pinned ?? false)
                }
                
                mutating 
                func pin(_ pinned:Bool) 
                {
                    self.flag = pinned && self.object != nil
                }
            }
            
            // unit 0 is reserved as scratch space 
            private static 
            var units:[Unit] = []
            
            static 
            var active:Int = 0 
            
            static 
            var indices:Range<Int> 
            {
                self.units.indices
            }
            
            static 
            subscript(index:Int) -> (instance:Instance, pinned:Bool)? 
            {
                get 
                {
                    self.units[index].load 
                }
                set(new)
                {
                    self.units[index] = .store(new)
                }
            }
            
            static 
            var initialized:Bool 
            {
                !self.units.isEmpty 
            }
            
            static 
            func initialize() 
            {
                let count:Int = directReturn(default: 0, as: Int.self) 
                {
                    OpenGL.glGetIntegerv(OpenGL.MAX_UNIFORM_BUFFER_BINDINGS, $0)
                } 
                
                Self.units = .init(repeating: .store(nil), count: count)
                Log.note("initialized uniform buffer binding points (\(count) available)")
            }
            
            static 
            func set(pin index:Int, to pinned:Bool)
            {
                Self.units[index].pin(pinned)
            }
            
            static 
            func identical(_ instance1:Instance, _ instance2:Instance) -> Bool 
            {
                return instance1.0 === instance2.0 && instance1.1 == instance2.1
            }
            
            static 
            func bind(_ new:Instance)
            {
                let stride:Int = type(of: new.0).stride
                OpenGL.glBindBufferRange(type(of: new.0).target.code, .init(Self.active), new.0.buffer, new.1.lowerBound * stride, new.1.count * stride)
            }
            
            static 
            func bind(_ new:Instance, replacing old:Instance)
            {
                if type(of: old.0).target != type(of: new.0).target 
                {
                    Self.unbind(old)
                }
                Self.bind(new)
            }
            
            static 
            func unbind(_ old:Instance) 
            {
                OpenGL.glBindBufferBase(type(of: old.0).target.code, .init(Self.active), 0)
            }
        }
    }
}


final 
class Renderer 
{
    var viewport:Rectangle<Int> = .zero 
    
    init() 
    {
    }
    
    func execute(_ commands:[Command]) 
    {
        let a:Vector2<Int32> = .cast(self.viewport.a),
            s:Vector2<Int32> = .cast(self.viewport.size)
        OpenGL.glViewport(a.x, a.y, s.x, s.y)
        // should really do some sorting
        var state:
        (
            program:GPU.Program?, 
            arguments:[String: GPU.Program.Constant], 
            
            blendMode:Command.BlendMode,
            depthTest:Command.DepthTest, 
            cull:Bool, 
            multisample:Bool 
        )
        
        OpenGL.glDisable(OpenGL.DEPTH_TEST)
        OpenGL.glDisable(OpenGL.MULTISAMPLE)
        OpenGL.glEnable(OpenGL.BLEND)
        OpenGL.glBlendFunc(OpenGL.SRC_ALPHA, OpenGL.ONE_MINUS_SRC_ALPHA)
        OpenGL.glBlendEquation(OpenGL.FUNC_ADD)
        
        state.program       = nil 
        state.arguments     = [:] 
        state.blendMode     = .mix 
        state.depthTest     = .off 
        state.cull          = false 
        state.multisample   = false 
        for command:Command in commands 
        {
            switch command 
            {
            case .clear(color: let color, depth: let depth):
                OpenGL.glClear(
                    (color ? OpenGL.COLOR_BUFFER_BIT : 0) | 
                    (depth ? OpenGL.DEPTH_BUFFER_BIT : 0))
            case .draw(let command):
                if let program:GPU.Program = state.program, program === command.program 
                {
                } 
                else 
                {
                    state.arguments = [:]
                }
                
                var update:[String: GPU.Program.Constant] = [:]
                for (parameter, value):(String, GPU.Program.Constant) in command.arguments 
                {
                    guard   let old:GPU.Program.Constant = state.arguments[parameter], 
                                old == value 
                    else 
                    {
                        state.arguments[parameter]  = value 
                        update[parameter]           = value 
                        continue
                    }
                } 
                
                if command.blend != state.blendMode 
                {
                    switch command.blend 
                    {
                    case .mix:
                        OpenGL.glBlendFunc(OpenGL.SRC_ALPHA, OpenGL.ONE_MINUS_SRC_ALPHA)
                    case .add:
                        OpenGL.glBlendFunc(OpenGL.ONE, OpenGL.ONE)
                    }
                    state.blendMode = command.blend
                }
                
                if command.depth != state.depthTest 
                {
                    switch (state.depthTest, command.depth) 
                    {
                    case (.off, .off):
                        break 
                    case (_, .off):
                        OpenGL.glDisable(OpenGL.DEPTH_TEST)
                    case (.off, _):
                        OpenGL.glEnable(OpenGL.DEPTH_TEST)
                    default:
                        break
                    }
                    
                    switch command.depth 
                    {
                    case .never:
                        OpenGL.glDepthFunc(OpenGL.NEVER)
                    case .less:
                        OpenGL.glDepthFunc(OpenGL.LESS)
                    case .lessEqual:
                        OpenGL.glDepthFunc(OpenGL.LEQUAL)
                    case .equal:
                        OpenGL.glDepthFunc(OpenGL.EQUAL)
                    case .greaterEqual:
                        OpenGL.glDepthFunc(OpenGL.GEQUAL)
                    case .greater:
                        OpenGL.glDepthFunc(OpenGL.GREATER)
                    case .notEqual:
                        OpenGL.glDepthFunc(OpenGL.NOTEQUAL)
                    case .always:
                        OpenGL.glDepthFunc(OpenGL.ALWAYS)
                    case .off:
                        break
                    }
                    state.depthTest = command.depth
                }
                
                if command.cull != state.cull 
                {
                    if command.cull 
                    {
                        OpenGL.glEnable(OpenGL.CULL_FACE)
                    }
                    else 
                    {
                        OpenGL.glDisable(OpenGL.CULL_FACE)
                    }
                    state.cull = command.cull 
                }
                if command.multisample != state.multisample 
                {
                    if command.multisample 
                    {
                        OpenGL.glEnable(OpenGL.MULTISAMPLE)
                    }
                    else 
                    {
                        OpenGL.glDisable(OpenGL.MULTISAMPLE)
                    }
                    state.multisample = command.multisample 
                }
                
                // push command binds the program, even if the update is empty. 
                // program binding also checks cached state, but there’s no harm
                // in checking twice (and can prevent a smal number of rebinds across
                // render command groups)
                command.program.push(constants: update)
                if command.indexed 
                {
                    command.vertexArray.draw(indices: command.range, as: command.primitive)
                }
                else 
                {
                    command.vertexArray.draw(command.range, as: command.primitive)
                }
            }
            
        }
    }
}
extension Renderer 
{
    enum Backend 
    {
        enum Option 
        {
            case debug
            case clear(r:Float, g:Float, b:Float, a:Float)
            case clearDepth(Double)
            
            static 
            func clear(color:Vector4<Float>) -> Self 
            {
                return .clear(r: color.x, g: color.y, b: color.z, a: color.w)
            }
        }
        
        private static 
        var initialized:Bool = false 
        
        static 
        func initialize(loader:@escaping (UnsafePointer<Int8>) -> UnsafeMutableRawPointer?, 
            options:Option...) 
        {
            if Self.initialized 
            {
                Log.warning("`Renderer.Backend.initialize()` called, but renderer has already been initialized")
            }
            
            // set the opengl loader function
            OpenGL.loader = loader 
            
            for option:Option in options 
            {
                switch option 
                {
                case .debug:
                    Self.enableDebugOutput()
                
                case .clear(r: let r, g: let g, b: let b, a: let a):
                    OpenGL.glClearColor(r, g, b, a)
                
                case .clearDepth(let depth):
                    OpenGL.glClearDepth(depth)
                }
            }
            
            // options always set to constant value 
            OpenGL.glPolygonMode(OpenGL.FRONT_AND_BACK, OpenGL.FILL)
            OpenGL.glCullFace(OpenGL.BACK)
            OpenGL.glFrontFace(OpenGL.CCW)
            OpenGL.glEnable(OpenGL.TEXTURE_CUBE_MAP_SEAMLESS)
            
            Self.initialized = true
        }
        
        // debug tools 
        private static 
        func enableDebugOutput()
        {
            OpenGL.glEnable(OpenGL.DEBUG_OUTPUT)
            OpenGL.glEnable(OpenGL.DEBUG_OUTPUT_SYNCHRONOUS)
            
            OpenGL.glDebugMessageCallback(
            {
                (
                    source:OpenGL.Enum, 
                    type:OpenGL.Enum, 
                    id:OpenGL.UInt, 
                    severityCode:OpenGL.Enum, 
                    length:OpenGL.Size, 
                    message:UnsafePointer<OpenGL.Char>?,
                    userParameter:UnsafeRawPointer?
                ) in
                
                guard let message:String = (message.map{ .init(cString: $0) })
                else 
                {
                    return
                }
                
                let severity:Log.Severity 
                switch severityCode 
                {
                case OpenGL.DEBUG_SEVERITY_HIGH:
                    severity = .error 
                case OpenGL.DEBUG_SEVERITY_MEDIUM:
                    severity = .warning  
                case OpenGL.DEBUG_SEVERITY_LOW:
                    severity = .advisory
                case OpenGL.DEBUG_SEVERITY_NOTIFICATION:
                    fallthrough
                default:
                    severity = .note 
                }
                
                Log.print(severity, message, from: .opengl)
            }, nil)
        }
    }
}
extension Renderer 
{
    enum Command 
    {
        enum BlendMode 
        {
            case mix, add 
        }

        enum DepthTest
        {
            case off, 
                 never, 
                 less, 
                 lessEqual, 
                 equal, 
                 greaterEqual, 
                 greater, 
                 notEqual, 
                 always
        }
        
        struct Draw 
        {
            let program:GPU.Program
            let arguments:[String: GPU.Program.Constant]
            let vertexArray:GPU.Vertex.AnyArray
            let range:Range<Int>
            let indexed:Bool
            let primitive:GPU.Primitive
            
            let blend:BlendMode
            let depth:DepthTest 
            let cull:Bool
            let multisample:Bool
        }
        
        case draw(Draw)
        case clear(color:Bool, depth:Bool)
        
        static 
        func draw<R>(elements:R, 
            of vertexArray:GPU.Vertex.AnyArray, 
            as primitive:GPU.Primitive, 
            
            blendMode:BlendMode = .mix, 
            depthTest:DepthTest = .greaterEqual, 
            cull:Bool           = true, 
            multisample:Bool    = false, 
            
            using program:GPU.Program,
            _ arguments:[String: GPU.Program.Constant]) -> Self
            where R:RangeExpression, R.Bound == Int
        {
            let indices:Range<Int> = 0 ..< vertexArray.count.index
            let draw:Draw = .init(
                program: program, 
                arguments: arguments, 
                vertexArray: vertexArray, 
                range: indices[elements], 
                indexed: true, 
                primitive: primitive, 
                
                blend: blendMode, 
                depth: depthTest, 
                cull: cull, 
                multisample: multisample 
                )
            return .draw(draw)
        }
        static 
        func draw<R>(_ vertices:R, 
            of vertexArray:GPU.Vertex.AnyArray, 
            as primitive:GPU.Primitive, 
            
            blendMode:BlendMode = .mix, 
            depthTest:DepthTest = .greaterEqual, 
            cull:Bool           = true, 
            multisample:Bool    = false, 
            
            using program:GPU.Program,
            _ arguments:[String: GPU.Program.Constant]) -> Self
            where R:RangeExpression, R.Bound == Int
        {
            let indices:Range<Int> = 0 ..< vertexArray.count.vertex
            let draw:Draw = .init(
                program: program, 
                arguments: arguments, 
                vertexArray: vertexArray, 
                range: indices[vertices], 
                indexed: false, 
                primitive: primitive, 
                
                blend: blendMode, 
                depth: depthTest, 
                cull: cull, 
                multisample: multisample 
                )
            return .draw(draw)
        }
    }
}
