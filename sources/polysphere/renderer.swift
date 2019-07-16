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

protocol StructuredVertex 
{
    static 
    var layout:[_FX.Geometry.Attribute] 
    {
        get 
    }
}

protocol _AnyBuffer:AnyObject
{
    static 
    var target:_FX.Buffer.AnyTarget.Type
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
protocol _AnyBufferTarget
{
    static 
    var code:Int32 
    {
        get 
    }
}

protocol _AnyBufferUniform:_FX.AnyBuffer 
{
}
protocol _AnyBufferArray:_FX.AnyBuffer 
{
}
protocol _AnyBufferIndexArray:_FX.AnyBuffer 
{
}

protocol _AnyTexture:AnyObject
{
    static 
    var target:_FX.Texture.AnyTarget.Type
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
protocol _AnyTextureTarget
{
    static 
    var code:Int32 
    {
        get 
    }
}

protocol _AnyTextureD2:_FX.AnyTexture 
{
}
protocol _AnyTextureD3:_FX.AnyTexture 
{
}

enum _FX 
{
    final 
    class Geometry 
    {
        enum Attribute 
        {
            enum Destination 
            {
                enum General 
                {
                    case padding, float32
                }
                enum HighPrecision
                {
                    case padding, float32, float64
                }
                enum FixedPoint 
                {
                    case padding, float32(normalized:Bool)
                }
                enum Integral
                {
                    case padding, float32(normalized:Bool), int32
                }
                
                case padding, int32, float32(normalized:Bool), float64
            }
            
            case float16    (as:Destination.General)
            case float16x2  (as:Destination.General)
            case float16x3  (as:Destination.General)
            case float16x4  (as:Destination.General)
            
            case float32    (as:Destination.General)
            case float32x2  (as:Destination.General)
            case float32x3  (as:Destination.General)
            case float32x4  (as:Destination.General)
            
            case float64    (as:Destination.HighPrecision)
            case float64x2  (as:Destination.HighPrecision)
            case float64x3  (as:Destination.HighPrecision)
            case float64x4  (as:Destination.HighPrecision)
            
            
            case int8       (as:Destination.Integral)
            case int8x2     (as:Destination.Integral)
            case int8x3     (as:Destination.Integral)
            case int8x4     (as:Destination.Integral)
            
            case int16      (as:Destination.Integral)
            case int16x2    (as:Destination.Integral)
            case int16x3    (as:Destination.Integral)
            case int16x4    (as:Destination.Integral)
            
            case int32      (as:Destination.Integral)
            case int32x2    (as:Destination.Integral)
            case int32x3    (as:Destination.Integral)
            case int32x4    (as:Destination.Integral)
            
            case uint10x3   (as:Destination.FixedPoint)
            case uint8_bgra (as:Destination.FixedPoint)
            
            case uint8      (as:Destination.Integral)
            case uint8x2    (as:Destination.Integral)
            case uint8x3    (as:Destination.Integral)
            case uint8x4    (as:Destination.Integral)
            
            case uint16     (as:Destination.Integral)
            case uint16x2   (as:Destination.Integral)
            case uint16x3   (as:Destination.Integral)
            case uint16x4   (as:Destination.Integral)
            
            case uint32     (as:Destination.Integral)
            case uint32x2   (as:Destination.Integral)
            case uint32x3   (as:Destination.Integral)
            case uint32x4   (as:Destination.Integral)
            
            var destination:Destination 
            {
                switch self 
                {
                case    .float16    (as: let destination),
                        .float16x2  (as: let destination),
                        .float16x3  (as: let destination),
                        .float16x4  (as: let destination), 
                        
                        .float32    (as: let destination),
                        .float32x2  (as: let destination),
                        .float32x3  (as: let destination),
                        .float32x4  (as: let destination):
                    
                    switch destination 
                    {
                    case .padding:
                        return .padding 
                    case .float32: 
                        return .float32(normalized: false)
                    }
                
                case    .float64    (as: let destination),
                        .float64x2  (as: let destination),
                        .float64x3  (as: let destination),
                        .float64x4  (as: let destination):
                    
                    switch destination 
                    {
                    case .padding:
                        return .padding 
                    case .float32: 
                        return .float32(normalized: false)
                    case .float64: 
                        return .float64
                    }
                
                case    .uint10x3   (as: let destination),
                        .uint8_bgra (as: let destination):
                    switch destination 
                    {
                    case .padding:
                        return .padding 
                    case .float32(normalized: let normalize): 
                        return .float32(normalized: normalize)
                    }
                
                case    .int8       (as: let destination),
                        .int8x2     (as: let destination),
                        .int8x3     (as: let destination),
                        .int8x4     (as: let destination),
                        
                        .int16      (as: let destination),
                        .int16x2    (as: let destination),
                        .int16x3    (as: let destination),
                        .int16x4    (as: let destination),
                        
                        .int32      (as: let destination),
                        .int32x2    (as: let destination),
                        .int32x3    (as: let destination),
                        .int32x4    (as: let destination),
                        
                        .uint8      (as: let destination),
                        .uint8x2    (as: let destination),
                        .uint8x3    (as: let destination),
                        .uint8x4    (as: let destination),
                        
                        .uint16     (as: let destination),
                        .uint16x2   (as: let destination),
                        .uint16x3   (as: let destination),
                        .uint16x4   (as: let destination),
                
                        .uint32     (as: let destination),
                        .uint32x2   (as: let destination),
                        .uint32x3   (as: let destination),
                        .uint32x4   (as: let destination):
                    
                    switch destination 
                    {
                    case .padding:
                        return .padding 
                    case .float32(normalized: let normalize): 
                        return .float32(normalized: normalize)
                    case .int32: 
                        return .int32 
                    }
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
        
        fileprivate 
        struct Core 
        {
            let vertexarray:OpenGL.UInt 
            
            static 
            func create() -> Self 
            {
                let vertexarray:OpenGL.UInt = directReturn(default: 0) 
                {
                    OpenGL.glGenVertexArrays(1, $0)
                }
                return .init(vertexarray: vertexarray)
            }
            
            func destroy() 
            {
                withUnsafePointer(to: self.vertexarray)
                {
                    OpenGL.glDeleteVertexArrays(1, $0)
                }
            }
            
            func attach<Vertex, Index>(vertices:Buffer.Array<Vertex>, indices:Buffer.IndexArray<Index>)
                where Vertex:StructuredVertex
            {
                OpenGL.glBindVertexArray(self.vertexarray)
                OpenGL.glBindBuffer(Buffer.Target.Array.code, vertices.core.buffer)
                
                // set vertex attributes 
                let stride:Int = Vertex.layout.map{ $0.size }.reduce(0, +)
                var offset:Int = 0, 
                    index:Int  = 0
                for attribute:Attribute in Vertex.layout 
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
                    
                    defer 
                    {
                        offset += attribute.size 
                    }
                    
                    switch attribute.destination 
                    {
                    case .padding:
                        continue 
                    
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
                    index += 1
                }
                
                OpenGL.glBindBuffer(Buffer.Target.IndexArray.code, indices.core.buffer)
                OpenGL.glBindVertexArray(0)
                OpenGL.glBindBuffer(Buffer.Target.Array.code, 0)
                OpenGL.glBindBuffer(Buffer.Target.IndexArray.code, 0)
            }
        }
        
        fileprivate 
        let core:Core 
        
        init<Vertex, Index>(vertices:Buffer.Array<Vertex>, indices:Buffer.IndexArray<Index>) 
            where Vertex:StructuredVertex, Index:FixedWidthInteger & UnsignedInteger
        {
            self.core = .create()
            self.core.attach(vertices: vertices, indices: indices)
        }
        
        deinit
        {
            self.core.destroy()
        }
    }
    
    typealias AnyBuffer = _AnyBuffer
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
        
        typealias AnyTarget = _AnyBufferTarget
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
        
        typealias AnyUniform            = _AnyBufferUniform
        typealias AnyArray              = _AnyBufferArray
        typealias AnyIndexArray         = _AnyBufferIndexArray
        
        typealias Uniform<Element>      = Buffer<Target.Uniform,    Element>
        typealias Array<Element>        = Buffer<Target.Array,      Element>
        typealias IndexArray<Element>   = Buffer<Target.IndexArray, Element> 
            where Element:FixedWidthInteger & UnsignedInteger
        
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
    
    typealias AnyTexture = _AnyTexture
    enum Texture 
    {
        // global state management 
        fileprivate
        enum Manager 
        {
            // unit 0 is reserved as scratch space 
            private static 
            var units:[(unit:Weak<AnyTexture>, pinned:Bool)] = []
            
            private static 
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
            
            private static 
            var binding:AnyTexture? 
            {
                get 
                {
                    Self.units[Self.active].unit.object 
                }
                set(new) 
                {
                    switch (Self.units[Self.active].unit.object, new)
                    {
                    case (.some(let old),   .some(let new)):
                        guard old !== new 
                        else 
                        {
                            break 
                        }
                        
                        if type(of: old).target != type(of: new).target 
                        {
                            OpenGL.glBindTexture(type(of: old).target.code, 0)
                        }
                        OpenGL.glBindTexture(type(of: new).target.code, new.core.texture)
                    
                    case (nil,              .some(let new)):
                        OpenGL.glBindTexture(type(of: new).target.code, new.core.texture)
                        Self.units[Self.active].unit.object = new 
                    
                    case (.some(let old),   nil):
                        OpenGL.glBindTexture(type(of: old).target.code, 0)
                        Self.units[Self.active] = (unit: .init(nil), pinned: false)
                    
                    case (nil,              nil):
                        Self.units[Self.active].pinned = false
                    }
                    
                }
            }
            
            static 
            func initialize() 
            {
                let unitsCount:Int = directReturn(default: 0, as: Int.self) 
                {
                    OpenGL.glGetIntegerv(OpenGL.MAX_COMBINED_TEXTURE_IMAGE_UNITS, $0)
                } 
                
                Self.units = .init(repeating: (.init(), false), count: unitsCount)
                Log.note("initialized texture units (\(unitsCount) available)")
            }
            
            // look for a free texture unit, or one that is already bound to 
            // the texture we’re trying to pin.
            // this is a stateful API. the given texture is bound in the gl context 
            // until the next call to this API.
            static 
            func pin(_ texture:AnyTexture) -> Int? 
            {
                assert(!Self.units.count.isEmpty, "call to texture APIs without initializing texture manager")
                
                var slot:Int? = nil 
                // reverse search just so empty slots with low indices get picked 
                // first.
                for index:Int in Self.units.indices.reversed().dropLast()
                {
                    if let occupant:AnyTexture = Self.units[index].unit.object
                    {
                        if occupant === texture 
                        {
                            Self.active = index 
                            Self.units[Self.active].pinned = true
                            return Self.active 
                        }
                    }
                    else 
                    {
                        Self.unpin(index)
                    }
                    
                    if !Self.units[index].pinned 
                    {
                        slot = index 
                    }
                }
                
                if let slot:Int = slot 
                {
                    Self.active  = slot 
                    Self.binding = texture 
                    Self.units[Self.active].pinned = true
                    return Self.active 
                }
                else 
                {
                    return nil
                }
            }
            
            // switches to the given texture unit, binds the given texture, executes the 
            // given closure, then restores the state. 
            static 
            func with<R>(_ texture:AnyTexture, boundTo index:Int = 0, body:() throws -> R) 
                rethrows -> R
            {
                let (unit, pinned):(Weak<AnyTexture>, Bool) = Self.units[index], 
                    active:Int                              = Self.active 
                
                Self.active = index
                defer 
                {
                    Self.active = active
                }
                
                Self.binding = texture 
                defer 
                {
                    Self.binding = unit.object 
                }
                
                Self.units[Self.active].pinned = true 
                defer 
                {
                    Self.units[Self.active].pinned = pinned 
                }
                
                return try body()
            }
            
            static 
            func unpin(_ index:Int) 
            {
                Self.units[index].pinned = false
            }
            
            static 
            func unpinAll() 
            {
                for index:Int in Self.units.indices 
                {
                    Self.unpin(index)
                }
            }
        }
        
        enum Layout
        {
            case r8, rg8, rgb8, rgba8, bgra8, argb32atomic
            
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
                case .rgba8:
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
                }
            }
        }

        enum Filter 
        {
            case nearest, linear
        }
        
        typealias AnyTarget = _AnyTextureTarget
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
        }
        
        typealias AnyD2         = _AnyTextureD2
        typealias AnyD3         = _AnyTextureD3
        typealias D2<Element>   = Texture<Target.D2, Element>
        typealias D3<Element>   = Texture<Target.D3, Element>
        
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
                Manager.with(self) 
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
            
            func unpack() -> (String, Swift.Error?)
            {
                switch self 
                {
                case .shader(name: let name, error: let error):
                    return ("failed to compile shader in program '\(name)'", error)
                case .linking(name: let name, info: let message):
                    return ("failed to link program '\(name)' \n\(message)", nil)
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
                
                func unpack() -> (String, Swift.Error?)
                {
                    switch self 
                    {
                    case .source(type: let type, name: let name, error: let error):
                        return ("failed to load source(s) for \(String.init(describing: type)) shader '\(name)'", error)
                    case .compilation(type: let type, name: let name, info: let message):
                        return ("failed to compile \(String.init(describing: type)) shader '\(name)' \n\(message)", nil)
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
        
        enum Constant
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
                        .texture3   (let value as Any):
                    return .init(describing: type(of: value))
                
                case    .block      (let value as Any, range: let range):
                    return "\(String.init(describing: type(of: value)))[\(range.count)]"
                }
            }
        }
        
        fileprivate 
        struct Core 
        {
            private 
            struct Parameter  
            {
                enum Datatype 
                {
                    case float32, float32x2, float32x3, float32x4
                    case int32, int32x2, int32x3, int32x4 
                    case uint32, uint32x2, uint32x3, uint32x4
                    
                    case matrix2, matrix3, matrix4
                    case texture2, texture3
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
                for parameter:Parameter in self.parameters 
                {
                    guard let constant:Constant = constants[parameter.name] 
                    else 
                    {
                        continue 
                    }
                    
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
                    
                    case    (.texture2, .texture2   (let texture as AnyTexture)), 
                            (.texture3, .texture3   (let texture as AnyTexture)):
                        if let index:Int = Texture.Manager.pin(texture) 
                        {
                            OpenGL.glUniform1i(parameter.location, .init(index))
                        }
                        else 
                        {
                            Log.error("could not push texture constant '\(texture.debugName)' to texture parameter '\(parameter.name)' (no free texture units)")
                            OpenGL.glUniform1i(parameter.location, -1)
                        }
                    
                    case (.block(size: let size), .block(let buffer, let range)):
                        if range.count != size 
                        {
                            Log.warning("uniform (sub)buffer '\(buffer.debugName)' has size \(range.count), but block parameter '\(parameter.name)' has size \(size)")
                        }
                        
                        if let index:Int = Buffer.Uniform.Manager.pin(buffer, range: range) 
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
            }
            
            private 
            func inspectParameters() -> [Parameter] 
            {
                let count:OpenGL.Int = self.countResources(OpenGL.UNIFORM)
                // should generate stack-allocated local array
                let properties:[OpenGL.Enum] = 
                [
                    OpenGL.NAME_LENGTH, 
                    OpenGL.TYPE​, 
                    OpenGL.ARRAY_SIZE​,
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
                    OpenGL.glGetShaderiv(self.program, OpenGL.LINK_STATUS, $0)
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
                    return (type, try File.read(path), path)
                }
                catch 
                {
                    throw Error.source(type: type, name: path, error: error)
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
                    
                    throw Error.shader(name: debugName, 
                        error: Shader.Error.compilation(type: type, name: name, info: core.info()))
                }
                
                Log.note("compiled \(String.init(describing: type)) shader '\(name)' in program '\(debugName)'")
                Log.note(core.info())
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
            Log.note(self.core.info())
        }
        
        deinit 
        {
            self.core.destroy()
        }
    }
}
extension _FX.Texture.D2:_FX.Texture.AnyD2
{
    func assign(_ data:Array2D<Element>)
    {
        _FX.Texture.Manager.with(self) 
        {
            self.core.assign(data, layout: self.layout, mipmap: self.mipmap)
        }
    }
}
extension _FX.Texture.D3:_FX.Texture.AnyD3
{
    func assign(_ data:Array3D<Element>)
    {
        _FX.Texture.Manager.with(self) 
        {
            self.core.assign(data, layout: self.layout, mipmap: self.mipmap)
        }
    }
}

extension _FX.Buffer.Uniform:_FX.Buffer.AnyUniform
{
}
extension _FX.Buffer.Array:_FX.Buffer.AnyArray
{
}
extension _FX.Buffer.IndexArray:_FX.Buffer.AnyIndexArray
{
}

final 
class Renderer 
{
    /* struct Command 
    {
        enum Indexing 
        {
            case direct 
            case indexed 
        }
        
        enum Primitive 
        {
            case points 
            case lines 
            case triangles
        }
        
        let shader:Shader 
        let geometry:Geometry 
        let indexing:Indexing, 
            primitive:Primitive, 
            range:Range<Int>
    }
    
    enum Shader 
    {
        enum Selector:Hashable
        {
            case text(Texture)                  // (sx, sy, tx, ty, x, y, z, r, g, b, a)
            case solidVertex(Vector4<UInt8>)    // (x, y, z, _)
            case colorVertex                    // (x, y, z, r, g, b, a) x 3
            case globe(Texture)                 // (x, y, z, _)
        }
    }
    
    struct Element<Vertex>
    {
        var vertices:[Vertex]
        let shader:Shader.Selector
    } */
}
