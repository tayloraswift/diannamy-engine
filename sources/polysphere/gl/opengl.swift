protocol _GLIndex
{
    static 
    var typecode:OpenGL.Enum { get }
}
extension UInt8:_GLIndex 
{
    static
    var typecode:OpenGL.Enum 
    {
        return OpenGL.UNSIGNED_BYTE
    }
}
extension UInt16:_GLIndex 
{
    static
    var typecode:OpenGL.Enum 
    {
        return OpenGL.UNSIGNED_SHORT
    }
}
extension UInt32:_GLIndex 
{
    static
    var typecode:OpenGL.Enum 
    {
        return OpenGL.UNSIGNED_INT
    }
}

enum GL 
{
    enum Functionality:OpenGL.Enum 
    {
        case blending           = 0x0BE2, 
             multisampling      = 0x809D, 
             culling            = 0x0B44
    }
    
    enum DrawMode:OpenGL.Enum 
    {
        case point = 0x1B00, 
             line, 
             fill
    }
    
    enum DepthMode:OpenGL.Enum 
    {
        case never = 0x0200, 
             less, 
             equal, 
             lessEqual, 
             greater, 
             notEqual, 
             greaterEqual, 
             always
    }
    
    enum BlendMode 
    {
        case mix, add
    }
    
    static 
    func viewport(anchor:Math<Int>.V2, size:Math<Int>.V2)
    {
        OpenGL.glViewport(OpenGL.Int(anchor.x), OpenGL.Int(anchor.y), OpenGL.Size(size.x), OpenGL.Size(size.y))
    }
    
    static 
    func enable(_ functionality:Functionality)
    {
        OpenGL.glEnable(functionality.rawValue)
    }
    static 
    func disable(_ functionality:Functionality)
    {
        OpenGL.glDisable(functionality.rawValue)
    }
    
    static 
    func depthTest(_ test:DepthMode)
    {
        OpenGL.glDepthFunc(test.rawValue)
    }
    
    static 
    func blend(_ mode:BlendMode)
    {
        switch mode 
        {
        case .mix:
            OpenGL.glBlendFuncSeparate(OpenGL.SRC_ALPHA, OpenGL.ONE_MINUS_SRC_ALPHA, OpenGL.ONE_MINUS_DST_ALPHA, OpenGL.ONE)
        
        case .add:
            OpenGL.glBlendFuncSeparate(OpenGL.SRC_ALPHA, OpenGL.ONE, OpenGL.ONE_MINUS_DST_ALPHA, OpenGL.ONE)
        }
    }
    
    static 
    func clearColor(_ color:Math<Float>.V3, _ alpha:Float)
    {
        OpenGL.glClearColor(color.x, color.y, color.z, alpha)
    }
    static 
    func clearDepth(_ depth:Double)
    {
        OpenGL.glClearDepth(depth)
    }
    
    static 
    func clear(color:Bool = false, depth:Bool = false, stencil:Bool = false)
    {
        OpenGL.glClear(
            (color   ? OpenGL.COLOR_BUFFER_BIT   : 0) | 
            (depth   ? OpenGL.DEPTH_BUFFER_BIT   : 0) | 
            (stencil ? OpenGL.STENCIL_BUFFER_BIT : 0) )
    }
    
    static 
    func polygonMode(_ mode:DrawMode)
    {
        OpenGL.glPolygonMode(OpenGL.FRONT_AND_BACK, mode.rawValue)
    }
    
    struct Vector<Element> 
    {
        let buffer:Buffer<Element>
        internal private(set)
        var count:Int
        private 
        var capacity:Int 
        
        static 
        func generate() -> Vector
        {
            return .init(buffer: .generate(), count: 0, capacity: 0)
        }
        
        func destroy()
        {
            self.buffer.destroy()
        }
        
        mutating 
        func assign(data:[Element], in target:Buffer<Element>.Target, usage:Buffer<Element>.Usage)
        {
            self.buffer.bind(to: target)
            {
                guard self.capacity != 0 || data.count != 0
                else 
                {
                    return 
                }
                
                let bin:Int = max(16, Math.nextPowerOfTwo(data.count))
                if self.capacity != bin 
                {
                    $0.reserve(capacity: bin, usage: usage)
                    self.capacity = bin
                }
                
                $0.subData(data)
                self.count = data.count
            }
        }
    }
    
    struct Buffer<Element> 
    {
        private 
        let id:OpenGL.UInt
        
        static 
        func generate() -> Buffer 
        {
            var id:OpenGL.UInt = 0
            OpenGL.glGenBuffers(1, &id)
            
            return .init(id: id)
        }
        
        func destroy() 
        {
            withUnsafePointer(to: self.id)
            {
                OpenGL.glDeleteBuffers(1, $0)
            }
        }
        
        enum Usage:OpenGL.Enum
        {
            case `static` = 0x88E4,
                 dynamic  = 0x88E8,
                 stream   = 0x88E0
        }

        enum Target:OpenGL.Enum
        {
            case array        = 0x8892,
                 elementArray = 0x8893,
                 uniform      = 0x8A11
        }
        
        struct BoundTarget 
        {
            let rawValue:OpenGL.Enum 
            
            func data(_ data:[Element], usage:Usage)
            {
                data.withUnsafeBufferPointer
                {
                    self.data(UnsafeRawBufferPointer($0), usage: usage)
                }
            }
            func subData(_ data:[Element], offset:Int = 0)
            {
                data.withUnsafeBufferPointer
                {
                    self.subData(UnsafeRawBufferPointer($0), offset: offset)
                }
            }
            
            func data(_ data:UnsafeRawBufferPointer, usage:Usage)
            {
                OpenGL.glBufferData(self.rawValue, data.count, data.baseAddress, usage.rawValue)
            }
            func subData(_ data:UnsafeRawBufferPointer, offset:Int = 0)
            {
                OpenGL.glBufferSubData(self.rawValue, offset, data.count, data.baseAddress)
            }
            
            func reserve(capacity:Int, usage:Usage)
            {
                OpenGL.glBufferData(self.rawValue, capacity * MemoryLayout<Element>.stride, 
                    nil, usage.rawValue)
            }
        }
        
        func bind<Result>(to target:Target, body:(BoundTarget) -> Result) -> Result
        {
            OpenGL.glBindBuffer(target.rawValue, self.id)
            defer 
            {
                OpenGL.glBindBuffer(target.rawValue, 0)
            }
            
            return body(.init(rawValue: target.rawValue))
        }
        func bind<Result>(to target:Target, body:() -> Result) -> Result
        {
            OpenGL.glBindBuffer(target.rawValue, self.id)
            defer 
            {
                OpenGL.glBindBuffer(target.rawValue, 0)
            }
            
            return body()
        }
        
        func bind<Result>(to target:Target, index:Int, body:(BoundTarget) -> Result) -> Result
        {
            assert(target == .uniform)
            
            OpenGL.glBindBufferBase(target.rawValue, OpenGL.UInt(index), self.id)
            defer 
            {
                OpenGL.glBindBufferBase(target.rawValue, OpenGL.UInt(index), 0)
            }
            
            return body(.init(rawValue: target.rawValue))
        }
        func bind<Result>(to target:Target, index:Int, body:() -> Result) -> Result
        {
            assert(target == .uniform)
            
            OpenGL.glBindBufferBase(target.rawValue, OpenGL.UInt(index), self.id)
            defer 
            {
                OpenGL.glBindBufferBase(target.rawValue, OpenGL.UInt(index), 0)
            }
            
            return body()
        }
    }
    
    struct VertexArray
    {
        enum Primitive:OpenGL.Enum
        {
            case points = 0, 
                 lines, 
                 lineLoop, 
                 lineStrip, 
                 triangles, 
                 triangleStrip, 
                 triangleFan, 
                 
                 linesAdjacency = 0xA
        }
        
        // GL vertex attribute pointer stuff 
        enum Attribute
        {
            case int(from: Integer),
                 float(from: FloatingPoint),
                 padding(Int)
            
            enum Integer
            {
                case int, int2, int3, int4,
                     uint, uint2, uint3, uint4,
                     short, short2, short3, short4,
                     ushort, ushort2, ushort3, ushort4,
                     byte, byte2, byte3, byte4,
                     ubyte, ubyte2, ubyte3, ubyte4

                private 
                var count:OpenGL.Int
                {
                    switch self
                    {
                    case .int, .uint, .short, .ushort, .byte, .ubyte:
                        return 1
                    case .int2, .uint2, .short2, .ushort2, .byte2, .ubyte2:
                        return 2
                    case .int3, .uint3, .short3, .ushort3, .byte3, .ubyte3:
                        return 3
                    case .int4, .uint4, .short4, .ushort4, .byte4, .ubyte4:
                        return 4
                    }
                }

                var size:Int
                {
                    switch self
                    {
                    case .int4, .uint4:
                        return 16
                    case .int2, .uint2, .short4, .ushort4:
                        return 8
                    case .int, .uint, .short2, .ushort2, .byte4, .ubyte4:
                        return 4
                    case .short, .ushort, .byte2, .ubyte2:
                        return 2
                    case .byte, .ubyte:
                        return 1
                    case .byte3, .ubyte3:
                        return 3
                    case .short3, .ushort3:
                        return 6
                    case .int3, .uint3:
                        return 12
                    }
                }

                private 
                var typeCode:OpenGL.Enum
                {
                    switch self
                    {
                    case .int, .int2, .int3, .int4:
                        return OpenGL.INT
                    case .uint, .uint2, .uint3, .uint4:
                        return OpenGL.UNSIGNED_INT
                    case .short, .short2, .short3, .short4:
                        return OpenGL.SHORT
                    case .ushort, .ushort2, .ushort3, .ushort4:
                        return OpenGL.UNSIGNED_SHORT
                    case .byte, .byte2, .byte3, .byte4:
                        return OpenGL.BYTE
                    case .ubyte, .ubyte2, .ubyte3, .ubyte4:
                        return OpenGL.UNSIGNED_BYTE
                    }
                }

                func setPointer(index:Int, stride:Int, byteOffset:Int)
                {
                    OpenGL.glVertexAttribIPointer(OpenGL.UInt(index), self.count, self.typeCode, 
                        OpenGL.Size(stride), UnsafeRawPointer(bitPattern: byteOffset))
                    OpenGL.glEnableVertexAttribArray(OpenGL.UInt(index))
                }
            }
            
            enum FloatingPoint
            {
                case double, double2, double3, double4,
                     float, float2, float3, float4,
                     half, half2, half3, half4,
                     ushort, ushort2, ushort3, ushort4,
                     ubyte4_rgba, ubyte4_bgra,
                     normal

                private 
                var count:OpenGL.Int
                {
                    switch self
                    {
                    case .double, .float, .half, .ushort:
                        return 1
                    case .double2, .float2, .half2, .ushort2:
                        return 2
                    case .double3, .float3, .half3, .ushort3:
                        return 3
                    case .double4, .float4, .half4, .ushort4, .ubyte4_rgba, .normal:
                        return 4
                    case .ubyte4_bgra:
                        return OpenGL.BGRA
                    }
                }

                var size:Int
                {
                    switch self
                    {
                    case .double4:
                        return 32
                    case .double3:
                        return 24
                    case .double2, .float4:
                        return 16
                    case .double, .float2, .half4, .ushort4:
                        return 8
                    case .float, .half2, .ushort2, .ubyte4_rgba, .ubyte4_bgra, .normal:
                        return 4
                    case .half, .ushort:
                        return 2
                    case .half3, .ushort3:
                        return 6
                    case .float3:
                        return 12
                    }
                }

                private 
                var typeCode:OpenGL.Enum
                {
                    switch self
                    {
                    case .double, .double2, .double3, .double4:
                        return OpenGL.DOUBLE
                    case .float, .float2, .float3, .float4:
                        return OpenGL.FLOAT
                    case .half, .half2, .half3, .half4:
                        return OpenGL.HALF_FLOAT
                    case .ushort, .ushort2, .ushort3, .ushort4:
                        return OpenGL.UNSIGNED_SHORT
                    case .ubyte4_rgba, .ubyte4_bgra:
                        return OpenGL.UNSIGNED_BYTE
                    case .normal:
                        return OpenGL.INT_2_10_10_10_REV
                    }
                }
                
                private 
                var normalized:Bool 
                {
                    switch self 
                    {
                    case .ubyte4_rgba, .ubyte4_bgra, .normal:
                        return true 
                    default:
                        return false
                    }
                }

                func setPointer(index:Int, stride:Int, byteOffset:Int)
                {
                    OpenGL.glVertexAttribPointer(OpenGL.UInt(index), self.count, self.typeCode,
                        self.normalized, OpenGL.Size(stride), UnsafeRawPointer(bitPattern: byteOffset))
                    OpenGL.glEnableVertexAttribArray(OpenGL.UInt(index))
                }
            }
            
            var size:Int
            {
                switch self
                {
                case .int(let integer):
                    return integer.size

                case .float(let floatingPoint):
                    return floatingPoint.size

                case .padding(let byteCount):
                    return byteCount
                }
            }
        }
        
        // empty struct
        struct BoundTarget 
        {
            func setVertexLayout(_ layout:Attribute...)
            {
                let stride:Int     = layout.map{ $0.size }.reduce(0, +)
                var byteOffset:Int = 0,
                    index:Int      = 0
                for attribute:Attribute in layout
                {
                    switch attribute
                    {
                    case .int(let attribute):
                        attribute.setPointer(index: index, stride: stride, byteOffset: byteOffset)
                        index += 1

                    case .float(let attribute):
                        attribute.setPointer(index: index, stride: stride, byteOffset: byteOffset)
                        index += 1

                    default: 
                        break 
                    }
                    
                    byteOffset += attribute.size
                }
            }
        }
        
        private
        let id:OpenGL.UInt

        static
        func generate() -> VertexArray
        {
            var id:OpenGL.UInt = 0
            OpenGL.glGenVertexArrays(1, &id)
            return VertexArray(id: id)
        }

        func destroy()
        {
            withUnsafePointer(to: self.id)
            {
                OpenGL.glDeleteVertexArrays(1, $0)
            }
        }
        
        @discardableResult
        func bind() -> BoundTarget
        {
            OpenGL.glBindVertexArray(self.id)
            return .init()
        }

        func unbind()
        {
            OpenGL.glBindVertexArray(0)
        }

        func bind<Result>(_ body:(BoundTarget) -> Result) -> Result
        {
            self.bind()
            defer
            {
                self.unbind()
            }

            return body(.init())
        }
        func bind<Result>(_ body:() -> Result) -> Result
        {
            self.bind()
            defer
            {
                self.unbind()
            }

            return body()
        }
        
        func draw(_ range:Range<Int>, as mode:Primitive)
        {
            self.bind
            {
                OpenGL.glDrawArrays(mode.rawValue, OpenGL.Int(range.lowerBound), 
                    OpenGL.Size(range.count))
            }
        }

        func drawElements<Index>(_ range:Range<Int>, as mode:Primitive, indexType:Index.Type)
            where Index:_GLIndex
        {
            self.bind
            {
                let byteOffset:Int = range.lowerBound * MemoryLayout<Index>.stride
                OpenGL.glDrawElements(mode.rawValue, OpenGL.Size(range.count), 
                    Index.typecode, UnsafeRawPointer(bitPattern: byteOffset))
            }
        }
    }
    
    // debug tools 
    static 
    func enableDebugOutput(synchronous:Bool = false)
    {
        OpenGL.glEnable(OpenGL.DEBUG_OUTPUT)
        if synchronous 
        {
            OpenGL.glEnable(OpenGL.DEBUG_OUTPUT_SYNCHRONOUS)
        }
        
        OpenGL.glDebugMessageCallback(
        {
            (source:OpenGL.Enum, type:OpenGL.Enum, id:OpenGL.UInt, 
            severity:OpenGL.Enum, length:OpenGL.Size, 
            message:UnsafePointer<OpenGL.Char>?, userParameter:UnsafeRawPointer?) in
            
            guard let message:UnsafePointer<OpenGL.Char> = message 
            else 
            {
                return
            }
            
            switch severity 
            {
            case OpenGL.DEBUG_SEVERITY_HIGH:
                Log.error(.init(cString: message), from: .opengl)
            case OpenGL.DEBUG_SEVERITY_MEDIUM, OpenGL.DEBUG_SEVERITY_LOW:
                Log.warning(.init(cString: message), from: .opengl)
            default:
                Log.note(.init(cString: message), from: .opengl)
            }
        }, nil)
    }
}
