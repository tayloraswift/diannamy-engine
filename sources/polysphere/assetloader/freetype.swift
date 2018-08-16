import FreeType

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
    
    func renderBasicMonospaceFont(_ fontname:String, size:Int, codepoints:Int = 128) 
        -> Assets.BasicMonospaceFont
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
        
        if face.pointee.face_flags & FT_FACE_FLAG_FIXED_WIDTH == 0
        {
            Log.warning("attempting to create monospace font atlas from variable-width font '\(fontname)'")
        }
    
        FreeType.checkError 
        {
            FT_Set_Pixel_Sizes(face, 0, UInt32(size))
        }
        
        // determine cell width of the glyphs 
        FT_Load_Glyph(face, 0, FT_LOAD_DEFAULT)
        if face.pointee.glyph.pointee.advance.y != 0 
        {
            Log.warning("font '\(fontname)' has nonzero y advance")
        }
        
        // round x advance up to nearest multiple of 64 and divide by 64
        let advance64:Int = face.pointee.glyph.pointee.advance.x, 
            advance:Int   = advance64 >> 6 + (advance64 & (1 << 6 - 1) == 0 ? 0 : 1)
        
        // iterate over all ascii
        struct Bitmap 
        {
            let image:Array2D<UInt8>, 
                origin:Math<Int>.V2, 
                codepoint:Int
        }
        let bitmaps:[Bitmap?] = (0 ..< codepoints).map
        {
            (codepoint:Int) in 
            
            guard (FreeType.checkError
            {
                // dumb integer cast because Freetype defines all the bitfield 
                // constants (except for FT_LOAD_DEFAULT) as `long`s
                FT_Load_Char(face, UInt(codepoint), Int32(FT_LOAD_RENDER))
            })
            else 
            {
                return nil
            }
            
            let bitmap:FT_Bitmap = face.pointee.glyph.pointee.bitmap
            let shape:Math<Int>.V2 = Math.cast((bitmap.width, bitmap.rows), as: Int.self), 
                buffer:[UInt8] = .init(_unsafeUninitializedCapacity: Math.vol(shape))
            {
                var source:Int = 0
                for row:Int in 0 ..< shape.y 
                {
                    for column:Int in 0 ..< shape.x 
                    {
                        $0[row * shape.x + column] = bitmap.buffer[source + column]
                    }
                    
                    source += Int(bitmap.pitch)
                }
                $1 = Math.vol(shape)
            }
            
            let image:Array2D<UInt8>  = .init(buffer, shape: shape)
            let origin:Math<Int32>.V2 = (face.pointee.glyph.pointee.bitmap_left, 
                                         face.pointee.glyph.pointee.bitmap_top)
            return .init(image: image, origin: Math.cast(origin, as: Int.self), codepoint: codepoint)
        }
        
        // determine maximum bounds 
        let bounds:Math<Int>.V2 
        bounds.0 = bitmaps.lazy.compactMap{             $0?.origin.y                     }.max() ?? 0
        bounds.1 = bitmaps.lazy.compactMap{ $0.flatMap{ $0.origin.y - $0.image.shape.y } }.min() ?? 0
        
        // assemble font atlas 
        var atlas:Array2D<UInt8> = .init(repeating: 0, shape: (advance * codepoints, bounds.0 - bounds.1))
        for bitmap:Bitmap in bitmaps.compactMap({$0})
        {
            let base:Math<Int>.V2 = (advance * bitmap.codepoint + bitmap.origin.x, 
                                     bounds.0 - bitmap.origin.y)
            let end:Math<Int>.V2  = Math.add(base, bitmap.image.shape)
            atlas.assign(a: base, b: end, from: bitmap.image.buffer)
        }
        
        FT_Done_Face(face)
        
        return .init(metrics: .init(bounds: bounds, advance: advance), atlas: atlas)
    }
}
