extension GL 
{
    struct Texture<Atom>
    {
        private 
        let id:OpenGL.UInt 
        
        static 
        func generate() -> Texture 
        {
            var id:OpenGL.UInt = 0 
            OpenGL.glGenTextures(1, &id)
            
            return .init(id: id)
        }
        
        func destroy() 
        {
            withUnsafePointer(to: self.id)
            {
                OpenGL.glDeleteTextures(1, $0)
            }
        }
        
        enum Target:OpenGL.Enum 
        {
            case texture1d   = 0x0DE0, 
                 texture2d   = 0x0DE1, 
                 texture3d   = 0x806F, 
                 textureCube = 0x8513
        }
        
        enum Layout
        {
            case r8, rg8, rgb8, rgba8, bgra8, argb32atomic
            
            var ordering:OpenGL.Enum 
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
        
        enum Storage:OpenGL.Enum  
        {
            case r8    = 0x8229, 
                 rg8   = 0x822B, 
                 rgba8 = 0x8058
        }

        enum Filter 
        {
            case nearest, linear
        }
        
        struct BoundTarget 
        {
            let target:Target 
            
            func data(_ data:Array2D<Atom>, layout:Layout, storage:Storage)
            {
                assert(target == .texture2d)
                
                let shape:Math<OpenGL.Size>.V2 = Math.cast(data.shape, as: OpenGL.Size.self)
                OpenGL.glTexImage2D(self.target.rawValue, 0, storage.rawValue, 
                    shape.x, shape.y, 0, layout.ordering, layout.type, data.buffer)
            }
            
            func setMagnificationFilter(_ filter:Filter)
            {
                let filtercode:OpenGL.Enum 
                switch filter 
                {
                    case .nearest:
                        filtercode = OpenGL.NEAREST 
                    case .linear:
                        filtercode = OpenGL.LINEAR
                }
                
                OpenGL.glTexParameteri(self.target.rawValue, OpenGL.TEXTURE_MAG_FILTER, filtercode)
            }
            
            func setMinificationFilter(_ filter:Filter, mipmap mipmapFilter:Filter?)
            {
                let filtercode:OpenGL.Enum 
                
                if let mipmapFilter:Filter = mipmapFilter 
                {
                    switch (filter, mipmapFilter) 
                    {    
                        case (.nearest, .nearest):
                            filtercode = OpenGL.NEAREST_MIPMAP_NEAREST 
                        case (.nearest, .linear):
                            filtercode = OpenGL.NEAREST_MIPMAP_LINEAR
                        
                        case (.linear, .nearest):
                            filtercode = OpenGL.LINEAR_MIPMAP_NEAREST
                        case (.linear, .linear):
                            filtercode = OpenGL.LINEAR_MIPMAP_LINEAR
                    }
                }
                else 
                {
                    switch filter 
                    {
                        case .nearest:
                            filtercode = OpenGL.NEAREST 
                        case .linear:
                            filtercode = OpenGL.LINEAR
                    }
                }

                OpenGL.glTexParameteri(self.target.rawValue, OpenGL.TEXTURE_MIN_FILTER, filtercode)
            }
            
            func generateMipmaps()
            {
                OpenGL.glGenerateMipmap(self.target.rawValue)
            }
        }
        
        func bind<Result>(to target:Target, index:Int = 0, body:(BoundTarget) -> Result) -> Result 
        {
            assert(index < OpenGL.MAX_COMBINED_TEXTURE_IMAGE_UNITS)
            
            OpenGL.glActiveTexture(OpenGL.TEXTURE0 + OpenGL.Int(index))
            OpenGL.glBindTexture(target.rawValue, self.id)
            defer 
            {
                OpenGL.glBindTexture(target.rawValue, 0)
                OpenGL.glActiveTexture(OpenGL.TEXTURE0)
            }
            
            return body(.init(target: target))
        }
        func bind<Result>(to target:Target, index:Int = 0, body:() -> Result) -> Result 
        {
            assert(index < OpenGL.MAX_COMBINED_TEXTURE_IMAGE_UNITS)
            
            OpenGL.glActiveTexture(OpenGL.TEXTURE0 + OpenGL.Int(index))
            OpenGL.glBindTexture(target.rawValue, self.id)
            defer 
            {
                OpenGL.glBindTexture(target.rawValue, 0)
                OpenGL.glActiveTexture(OpenGL.TEXTURE0)
            }
            
            return body()
        }
    }
}
