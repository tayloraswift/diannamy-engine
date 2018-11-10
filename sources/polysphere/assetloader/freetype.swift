import FreeType

enum Libraries 
{
    static 
    let freetype:FreeType = 
    {
        guard let library:FreeType = FreeType.init() 
        else 
        {
            Log.fatal("failed to initialize freetype library")
        }
        
        return library
    }()
}

class FreeType
{
    private
    let library:OpaquePointer

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

    init?()
    {
        guard let library:FT_Library =
        {
            var library:FT_Library?
            FT_Init_FreeType(&library)
            return library
        }()
        else
        {
            return nil
        }

        self.library = library
    }

    deinit
    {
        FT_Done_FreeType(self.library)
    }

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
    
    func withFace<Result>(_ fontname:String, size:Int, _ body:(FT_Face) throws -> Result) rethrows -> Result
    {
        guard let face:FT_Face =
        {
            var face:FT_Face?
            FreeType.checkError
            {
                FT_New_Face(self.library, fontname, 0, &face)
            }

            return face
        }()
        else
        {
            Log.fatal("failed to load font '\(fontname)'")
        }
        
        FreeType.checkError
        {
            FT_Set_Pixel_Sizes(face, 0, UInt32(size))
        }

        defer 
        {
            FT_Done_Face(face)
        }
        
        return try body(face)
    }
    
    func warnMonospace(_ face:FT_Face, fontname:String = "<anonymous>") 
    {
        if face.pointee.face_flags & FT_FACE_FLAG_FIXED_WIDTH == 0
        {
            Log.warning("attempting to create monospace font atlas from variable-width font '\(fontname)'")
        }
    }
    
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
