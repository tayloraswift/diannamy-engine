import func Glibc.getenv

extension GL
{
    
struct Program
{
    struct Uniforms 
    {
        struct Uniform 
        {
            enum Declaration
            {
                case float(String), 
                     float2(String), 
                     float3(String), 
                     float4(String), 
                     
                     int(String), 
                     int2(String), 
                     int3(String), 
                     int4(String), 
                     
                     uint(String), 
                     uint2(String), 
                     uint3(String), 
                     uint4(String), 
                     
                     mat2(String), 
                     mat3(String), 
                     mat4(String), 
                     
                     texture(String, binding:Int), 
                     block(String, binding:Int)
            }
            
            enum Datatype 
            {
                case float, float2, float3, float4, 
                     int,   int2,   int3,   int4, 
                     uint,  uint2,  uint3,  uint4, 
                     mat2, mat3, mat4, 
                     texture
            }
            
            let type:Datatype, 
                location:OpenGL.Int
        }
        
        private  
        let uniforms:[String: Uniform]
        
        static 
        func locate(_ declarations:[Uniform.Declaration], in program:OpenGL.UInt) -> Uniforms
        {
            // we temporarily bind the program so we can set the texture uniforms 
            // to their correct indices
            OpenGL.glUseProgram(program)

            var uniforms:[String: Uniform] = [:]
            for declaration:Uniform.Declaration in declarations 
            {
                let name:String, type:Uniform.Datatype
                switch declaration 
                {
                case .float(let identifier):
                    name = identifier
                    type = .float
                case .float2(let identifier):
                    name = identifier
                    type = .float2
                case .float3(let identifier):
                    name = identifier
                    type = .float3
                case .float4(let identifier):
                    name = identifier
                    type = .float4
                
                case .int(let identifier):
                    name = identifier
                    type = .int
                case .int2(let identifier):
                    name = identifier
                    type = .int2
                case .int3(let identifier):
                    name = identifier
                    type = .int3
                case .int4(let identifier):
                    name = identifier
                    type = .int4
                
                case .uint(let identifier):
                    name = identifier
                    type = .uint
                case .uint2(let identifier):
                    name = identifier
                    type = .uint2
                case .uint3(let identifier):
                    name = identifier
                    type = .uint3
                case .uint4(let identifier):
                    name = identifier
                    type = .uint4
                
                case .mat2(let identifier):
                    name = identifier
                    type = .mat2
                case .mat3(let identifier):
                    name = identifier
                    type = .mat3
                case .mat4(let identifier):
                    name = identifier
                    type = .mat4
                    
                case .texture(let identifier, let defaultBinding):
                    let location:OpenGL.Int = OpenGL.glGetUniformLocation(program, identifier)
                    guard location != -1 
                    else 
                    {
                        Log.warning("texture '\(identifier)' is not used in program")
                        continue
                    }
                    
                    OpenGL.glUniform1i(location, OpenGL.Int(defaultBinding))
                    uniforms[identifier] = Uniform(type: .texture, location: location)
                    continue
                
                case .block(let identifier, let binding):
                    let index:OpenGL.UInt = OpenGL.glGetUniformBlockIndex(program, identifier)
                    guard index != OpenGL.INVALID_INDEX
                    else 
                    {
                        Log.warning("uniform block '\(identifier)' is not used in program")
                        continue
                    }
                    
                    OpenGL.glUniformBlockBinding(program, index, OpenGL.UInt(binding))
                    continue
                }
                
                let location:OpenGL.Int = OpenGL.glGetUniformLocation(program, name)
                guard location != -1 
                else 
                {
                    Log.warning("uniform '\(name)' is not used in program")
                    continue
                }
                
                uniforms[name] = Uniform(type: type, location: location)
            }
            
            OpenGL.glUseProgram(0)
            
            return .init(uniforms: uniforms)
        }
        
        // uniform accessors 
        func set(float name:String, _ value:Float)
        {
            guard let uniform:Uniform = self.uniforms[name]
            else 
            {
                Log.warning("tried to set nonexistent uniform '\(name)'")
                return
            }
            
            assert(uniform.type == .float)
            OpenGL.glUniform1f(uniform.location, value)
        }
        
        func set(float2 name:String, _ value:Vector2<Float>)
        {
            guard let uniform:Uniform = self.uniforms[name]
            else 
            {
                Log.warning("tried to set nonexistent uniform '\(name)'")
                return 
            }
            
            assert(uniform.type == .float2)
            OpenGL.glUniform2f(uniform.location, value.x, value.y)
        }
        
        func set(float3 name:String, _ value:Vector3<Float>)
        {
            guard let uniform:Uniform = self.uniforms[name]
            else 
            {
                Log.warning("tried to set nonexistent uniform '\(name)'")
                return 
            }
            
            assert(uniform.type == .float3)
            OpenGL.glUniform3f(uniform.location, value.x, value.y, value.z)
        }
        
        func set(float4 name:String, _ value:Vector4<Float>)
        {
            guard let uniform:Uniform = self.uniforms[name]
            else 
            {
                Log.warning("tried to set nonexistent uniform '\(name)'")
                return 
            }
            
            assert(uniform.type == .float4)
            OpenGL.glUniform4f(uniform.location, value.x, value.y, value.z, value.w)
        }
        
        
        func set(texture name:String, binding value:Int)
        {
            guard let uniform:Uniform = self.uniforms[name]
            else 
            {
                Log.warning("tried to set nonexistent texture index '\(name)'")
                return 
            }
            
            assert(uniform.type == .texture)
            OpenGL.glUniform1i(uniform.location, .init(value))
        }
        
        
        func set(int name:String, _ value:Int32)
        {
            guard let uniform:Uniform = self.uniforms[name]
            else 
            {
                Log.warning("tried to set nonexistent uniform '\(name)'")
                return 
            }
            
            assert(uniform.type == .int)
            OpenGL.glUniform1i(uniform.location, value)
        }
        
        func set(int2 name:String, _ value:Vector2<Int32>)
        {
            guard let uniform:Uniform = self.uniforms[name]
            else 
            {
                Log.warning("tried to set nonexistent uniform '\(name)'")
                return 
            }
            
            assert(uniform.type == .int2)
            OpenGL.glUniform2i(uniform.location, value.x, value.y)
        }
        
        func set(int3 name:String, _ value:Vector3<Int32>)
        {
            guard let uniform:Uniform = self.uniforms[name]
            else 
            {
                Log.warning("tried to set nonexistent uniform '\(name)'")
                return 
            }
            
            assert(uniform.type == .int3)
            OpenGL.glUniform3i(uniform.location, value.x, value.y, value.z)
        }
        
        func set(int4 name:String, _ value:Vector4<Int32>)
        {
            guard let uniform:Uniform = self.uniforms[name]
            else 
            {
                Log.warning("tried to set nonexistent uniform '\(name)'")
                return 
            }
            
            assert(uniform.type == .int4)
            OpenGL.glUniform4i(uniform.location, value.x, value.y, value.z, value.w)
        }
        
        
        func set(mat3 name:String, _ value:[Matrix3<Float>])
        {
            guard let uniform:Uniform = self.uniforms[name]
            else 
            {
                Log.warning("tried to set nonexistent uniform '\(name)'")
                return 
            }
            
            assert(uniform.type == .mat3)
            
            var flattened:[Float] = []
                flattened.reserveCapacity(3 * 3 * value.count)
            for matrix:Matrix3<Float> in value 
            {
                flattened.append(matrix[0].x)
                flattened.append(matrix[0].y)
                flattened.append(matrix[0].z)
                flattened.append(matrix[1].x)
                flattened.append(matrix[1].y)
                flattened.append(matrix[1].z)
                flattened.append(matrix[2].x)
                flattened.append(matrix[2].y)
                flattened.append(matrix[2].z)
            }
            
            OpenGL.glUniformMatrix3fv(uniform.location, .init(value.count), false, flattened)
        }
        func set(mat4 name:String, _ value:[Matrix4<Float>])
        {
            guard let uniform:Uniform = self.uniforms[name]
            else 
            {
                Log.warning("tried to set nonexistent uniform '\(name)'")
                return 
            }
            
            assert(uniform.type == .mat4)
            
            var flattened:[Float] = []
                flattened.reserveCapacity(4 * 4 * value.count)
            for matrix:Matrix4<Float> in value 
            {
                flattened.append(matrix[0].x)
                flattened.append(matrix[0].y)
                flattened.append(matrix[0].z)
                flattened.append(matrix[0].w)
                flattened.append(matrix[1].x)
                flattened.append(matrix[1].y)
                flattened.append(matrix[1].z)
                flattened.append(matrix[1].w)
                flattened.append(matrix[2].x)
                flattened.append(matrix[2].y)
                flattened.append(matrix[2].z)
                flattened.append(matrix[2].w)
                flattened.append(matrix[3].x)
                flattened.append(matrix[3].y)
                flattened.append(matrix[3].z)
                flattened.append(matrix[3].w)
            }
            
            OpenGL.glUniformMatrix3fv(uniform.location, .init(value.count), false, flattened)
        }
    }
    
    enum ShaderType
    {
        case vertex, geometry, fragment
            
        fileprivate 
        var typeCode:OpenGL.Enum
        {
            switch self
            {
            case .vertex:
                return OpenGL.VERTEX_SHADER

            case .geometry:
                return OpenGL.GEOMETRY_SHADER

            case .fragment:
                return OpenGL.FRAGMENT_SHADER
            }
        }
    }

    private
    enum CompilationStep
    {
        case compile(OpenGL.UInt), link(OpenGL.UInt)
    }

    private
    let id:OpenGL.UInt,
        uniforms:Uniforms
    
    static
    func create(shaders shaderSources:[(type:ShaderType, path:String)],
        uniforms declarations:[Uniforms.Uniform.Declaration] = []) -> Program?
    {
        guard let shaders:[OpenGL.UInt] = compileShaders(shaderSources)
        else
        {
            return nil
        }

        // link program
        let id:OpenGL.UInt = OpenGL.glCreateProgram()
        for shader in shaders
        {
            OpenGL.glAttachShader(id, shader)
        }
        
        OpenGL.glLinkProgram(id)
        
        for shader in shaders
        {
            OpenGL.glDetachShader(id, shader)
            OpenGL.glDeleteShader(shader)
        }
        
        // always read the log for now
        Log.note(splitting: readLog(step: .link(id)), from: .glsl)
        
        guard check(step: .link(id))
        else
        {
            Log.error("failed to compile program (\(shaderSources.count) shaders)")

            OpenGL.glDeleteProgram(id) // cleanup
            return nil
        }

        Log.note("compiled program (\(shaderSources.count) shaders)")

        return .init(id: id, uniforms: .locate(declarations, in: id))
    }

    private static
    func compileShader(type:ShaderType, path:String) -> OpenGL.UInt?
    {
        guard let source:[UInt8] = try? File.read(posixPath(path))
        else
        {
            Log.error("could not read shader '\(path)'")
            return nil
        }

        let shader:OpenGL.UInt = OpenGL.glCreateShader(type.typeCode)
        
        source.withUnsafeBufferPointer 
        {
            $0.withMemoryRebound(to: Int8.self) 
            {
                var length:OpenGL.Int           = .init(source.count), 
                    string:UnsafePointer<Int8>? = $0.baseAddress
                
                OpenGL.glShaderSource(shader, 1, &string, &length)
            }
        }
        
        OpenGL.glCompileShader(shader)
        
        // always print the shader log for now
        Log.note(splitting: readLog(step: .compile(shader)), from: .glsl)

        guard check(step: .compile(shader))
        else
        {
            Log.error("failed to compile shader '\(path)'")
            // clean up
            OpenGL.glDeleteShader(shader)
            return nil
        }

        Log.note("compiled shader '\(path)'")

        return shader
    }

    private static
    func compileShaders(_ sources:[(type:ShaderType, path:String)]) -> [OpenGL.UInt]?
    {
        var shaders:[OpenGL.UInt] = []
        for (type, path):(ShaderType, String) in sources
        {
            guard let shader:OpenGL.UInt = compileShader(type: type, path: path)
            else
            {
                for shader:OpenGL.UInt in shaders
                {
                    OpenGL.glDeleteShader(shader)
                }

                return nil
            }

            shaders.append(shader)
        }

        return shaders
    }

    private static
    func check(step:CompilationStep) -> Bool
    {
        var success:OpenGL.Int = 0

        switch step
        {
        case .compile(let shader):
            OpenGL.glGetShaderiv(shader, OpenGL.COMPILE_STATUS, &success)

        case .link(let program):
            OpenGL.glGetProgramiv(program, OpenGL.LINK_STATUS, &success)
        }

        return success == 1 ? true : false
    }
    
    func bind<Result>(body:(Uniforms) -> Result) -> Result
    {
        OpenGL.glUseProgram(self.id)
        defer 
        {
            OpenGL.glUseProgram(0)
        }
        
        return body(self.uniforms)
    }
    func bind<Result>(body:() -> Result) -> Result
    {
        OpenGL.glUseProgram(self.id)
        defer 
        {
            OpenGL.glUseProgram(0)
        }
        
        return body()
    }

    private static
    func readLog(step:CompilationStep) -> String
    {
        var messageLength:OpenGL.Size = 0

        switch step
        {
        case .compile(let shader):
            OpenGL.glGetShaderiv(shader, OpenGL.INFO_LOG_LENGTH, &messageLength)

        case .link(let program):
            OpenGL.glGetProgramiv(program, OpenGL.INFO_LOG_LENGTH, &messageLength)
        }

        guard messageLength > 0
        else
        {
            return ""
        }

        let message = UnsafeMutablePointer<CChar>.allocate(capacity: Int(messageLength))
        defer
        {
            message.deallocate()
        }

        switch step
        {
        case .compile(let shader):
            OpenGL.glGetShaderInfoLog(shader, messageLength, nil, message)

        case .link(let program):
            OpenGL.glGetProgramInfoLog(program, messageLength, nil, message)
        }

        return String(cString: message)
    }
    
    // fix this to actually be a shell expansion
    private static
    func posixPath(_ path:String) -> String
    {
        guard let firstChar:Character = path.first
        else
        {
            return path
        }
        var expandedPath:String = path
        if firstChar == "~"
        {
            if  expandedPath.count == 1 ||
                expandedPath[expandedPath.index(after: expandedPath.startIndex)] == "/"
            {
                expandedPath = String(cString: getenv("HOME")) + String(expandedPath.dropFirst())
            }
        }
        return expandedPath
    }
}

}
