enum GL 
{
    enum Functionality:OpenGL.Enum 
    {
        case blending           = 0x0BE2, 
             multisampling      = 0x809D
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
    func blend(_ mode:BlendMode)
    {
        switch mode 
        {
        case .mix:
            OpenGL.glBlendFuncSeparate(OpenGL.SRC_ALPHA, OpenGL.ONE_MINUS_SRC_ALPHA, OpenGL.ONE_MINUS_DST_ALPHA, OpenGL.ONE)
        
        case .add:
            OpenGL.glBlendFuncSeparate(OpenGL.SRC_ALPHA, OpenGL.ONE, OpenGL.ONE, OpenGL.ONE)
        }
    }
    
    static 
    func clearColor(_ color:Math<Float>.V3, _ alpha:Float)
    {
        OpenGL.glClearColor(color.x, color.y, color.z, alpha)
    }
    
    static 
    func clear(color:Bool = false, depth:Bool = false, stencil:Bool = false)
    {
        OpenGL.glClear(
            (color   ? OpenGL.COLOR_BUFFER_BIT   : 0) | 
            (depth   ? OpenGL.DEPTH_BUFFER_BIT   : 0) | 
            (stencil ? OpenGL.STENCIL_BUFFER_BIT : 0) )
    }
    
    struct Buffer 
    {
        private 
        let id:OpenGL.UInt
        
        static 
        func generate() -> Buffer 
        {
            var id:OpenGL.UInt = 0
            OpenGL.glGenBuffers(1, &id)
            
            return Buffer(id: id)
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
            
            func data<T>(_ data:[T], usage:Usage)
            {
                data.withUnsafeBufferPointer
                {
                    self.data(UnsafeRawBufferPointer($0), usage: usage)
                }
            }
            func subData<T>(_ data:[T], offset:Int = 0)
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
            
            func reserve(_ bytes:Int, usage:Usage)
            {
                OpenGL.glBufferData(self.rawValue, bytes, nil, usage.rawValue)
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
        enum DrawMode:OpenGL.Enum
        {
            case points = 0, 
                 lines, 
                 lineLoop, 
                 lineStrip, 
                 triangles, 
                 triangleStrip, 
                 triangleFan
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

        func bind()
        {
            OpenGL.glBindVertexArray(self.id)
        }

        func unbind()
        {
            OpenGL.glBindVertexArray(0)
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

        func draw(_ range:Range<Int>, as mode:DrawMode)
        {
            self.bind
            {
                let byteOffset:Int = range.lowerBound * MemoryLayout<OpenGL.UInt>.stride
                OpenGL.glDrawElements(mode.rawValue, OpenGL.Size(range.count), 
                    OpenGL.UNSIGNED_INT, UnsafeRawPointer(bitPattern: byteOffset))
            }
        }
    }
    
    // GL vertex attribute pointer stuff 
    enum VertexAttribute
    {
        case int(from: IntAttribute),
             float(from: FloatAttribute),
             padding(Int)
        
        enum IntAttribute
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
        
        enum FloatAttribute
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
            case .int(let intAttribute):
                return intAttribute.size

            case .float(let floatAttribute):
                return floatAttribute.size

            case .padding(let byteCount):
                return byteCount
            }
        }
    }

    static
    func setVertexLayout(_ layout:VertexAttribute...)
    {
        let stride:Int     = layout.map{ $0.size }.reduce(0, +)
        var byteOffset:Int = 0,
            index:Int      = 0
        for attribute:VertexAttribute in layout
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
