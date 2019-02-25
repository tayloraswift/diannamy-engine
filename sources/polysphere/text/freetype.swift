import FreeType

enum FreeType
{
    private final 
    class Library 
    {
        let handle:OpaquePointer  
        
        init()
        {
            guard let handle:FT_Library =
            {
                var handle:FT_Library?
                FT_Init_FreeType(&handle)
                return handle
            }()
            else
            {
                Log.fatal("failed to initialize freetype library")
            }
            
            self.handle = handle
        }

        deinit
        {
            FT_Done_FreeType(self.handle)
        }
    }
    
    struct Face 
    {
        let object:FT_Face 
        
        static 
        func create(_ fontname:String) -> Face?
        {
            guard let face:FT_Face =
            {
                var face:FT_Face?
                FreeType.checkError
                {
                    FT_New_Face(FreeType.freetype.handle, fontname, 0, &face)
                }

                return face
            }()
            else
            {
                Log.error("failed to load font '\(fontname)'")
                return nil 
            }
            
            return .init(object: face)
        }
        
        func retain() 
        {
            FT_Reference_Face(self.object)
        }
        
        func release() 
        {
            FT_Done_Face(self.object)
        }
    }
    
    private static 
    let freetype:Library = .init() 

    private static
    let errors:[Int32: String] =
    {
        return .init(uniqueKeysWithValues: (0 ..< FT_ErrorTableCount).map
        {
            (i:Int) -> (Int32, String) in
            return withUnsafePointer(to: FT_ErrorTable)
            {
                let raw:UnsafeRawPointer = .init($0),
                    count:Int            = FT_ErrorTableCount
                let entry:FT_ErrorTableEntry =
                    raw.bindMemory(to: FT_ErrorTableEntry.self, capacity: count)[i]
                return (entry.code, .init(cString: entry.message))
            }
        })
    }()


    @discardableResult
    static
    func checkError(body:() -> Int32) -> Bool
    {
        let error:Int32 = body()
        switch error
        {
            case FT_Err_Ok:
                return true

            default:
                Log.error(FreeType.errors[error] ?? "unknown error", from: .freetype)
                return false
        }
    }
    
    static 
    func withFace<Result>(_ fontname:String, _ body:(FT_Face) throws -> Result) rethrows -> Result
    {
        guard let face:FT_Face =
        {
            var face:FT_Face?
            FreeType.checkError
            {
                FT_New_Face(FreeType.freetype.handle, fontname, 0, &face)
            }

            return face
        }()
        else
        {
            Log.fatal("failed to load font '\(fontname)'")
        }

        defer 
        {
            FT_Done_Face(face)
        }
        
        return try body(face)
    }
    
    static 
    func warnMonospace(_ face:FT_Face, fontname:String = "<anonymous>") 
    {
        if face.pointee.face_flags & FT_FACE_FLAG_FIXED_WIDTH == 0
        {
            Log.warning("attempting to create monospace font atlas from variable-width font '\(fontname)'")
        }
    }
    
    static 
    func warnVerticalAdvance(_ face:FT_Face, fontname:String = "<anonymous>") 
    {
        // determine cell width of the glyphs
        FT_Load_Glyph(face, 0, FT_LOAD_DEFAULT)
        if face.pointee.glyph.pointee.advance.y != 0
        {
            Log.warning("font '\(fontname)' has nonzero y advance")
        }
    }
}
