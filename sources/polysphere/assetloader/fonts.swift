import FreeType

// a basic, grid-based monospace font. good for debug displays, but will probably 
// not display accents or complex typography well, and some glyphs may be clipped
struct BasicFontAtlas
{
    struct Metrics 
    {
        let bounds:Math<Int>.V2, 
            advance:Int
    }
    
    let atlas:Array2D<UInt8>, 
        metrics:Metrics
    
    init(_ fontname:String, size:Int, codepoints:Int = 128)
    {
        (self.atlas, self.metrics) = Libraries.freetype.withFace(fontname, size: size)
        {
            (face:FT_Face) in 
            
            Libraries.freetype.warnMonospace(face, fontname: fontname)
            Libraries.freetype.warnVerticalAdvance(face, fontname: fontname)
            
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
                    buffer:[UInt8] = .init(unsafeUninitializedCapacity: Math.vol(shape))
                {
                    $1 = Math.vol(shape)
                    
                    let pitch:Int = .init(bitmap.pitch)
                    
                    guard   let base:UnsafeMutablePointer<UInt8>   = $0.baseAddress, 
                            let buffer:UnsafeMutablePointer<UInt8> = bitmap.buffer
                    else 
                    {
                        $0.initialize(repeating: 0)
                        return 
                    }
                    
                    for row:Int in 0 ..< shape.y
                    {
                        (base + row * shape.x).initialize(from: buffer + row * pitch, count: shape.x)
                    }
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
                atlas.assign(at: base, from: bitmap.image)
            }
            
            return (atlas, .init(bounds: bounds, advance: advance))
        }
    }
}

struct FontAtlas 
{
    struct Glyph 
    {
        let rectangle:Math<Math<Int>.V2>.V2, 
            uv:Math<Math<Float>.V2>.V2, 
            advance64:Int
    }
    
    let atlas:Array2D<UInt8>, 
        charmap:[Unicode.Scalar: Glyph]
    
    subscript(u:Unicode.Scalar) -> Glyph
    {
        return self.charmap[u] ?? self.charmap["\u{0}"]!
    }
    
    init(_ fontname:String, size:Int) 
    {
        (self.atlas, self.charmap) = Libraries.freetype.withFace(fontname, size: size)
        {
            (face:FT_Face) in 
            
            Libraries.freetype.warnVerticalAdvance(face, fontname: fontname)
            
            var glyphs:[(Unicode.Scalar, Math<Math<Int>.V2>.V2, Int, Array2D<UInt8>)] = []
            for codepoint:Unicode.Scalar in (0 ..< 1 << 16).compactMap(Unicode.Scalar.init(_:)) 
            {
                let index:UInt32 = FT_Get_Char_Index(face, UInt(codepoint.value))
                // only render codepoints with glyphs in the font
                guard index > 0 || codepoint == "\u{0}" 
                else 
                {
                    continue 
                }
                
                guard 
                (
                    FreeType.checkError
                    {
                        // dumb integer cast because Freetype defines all the bitfield
                        // constants (except for FT_LOAD_DEFAULT) as `long`s
                        FT_Load_Glyph(face, index, Int32(FT_LOAD_RENDER))
                    }
                )
                else
                {
                    continue 
                }
                
                let bitmap:FT_Bitmap   = face.pointee.glyph.pointee.bitmap
                let shape:Math<Int>.V2 = Math.cast((bitmap.width, bitmap.rows), as: Int.self),
                    buffer:[UInt8]     = .init(unsafeUninitializedCapacity: Math.vol(shape))
                {
                    $1 = Math.vol(shape)
                    
                    let pitch:Int = .init(bitmap.pitch)
                    
                    guard   let base:UnsafeMutablePointer<UInt8>   = $0.baseAddress, 
                            let buffer:UnsafeMutablePointer<UInt8> = bitmap.buffer
                    else 
                    {
                        $0.initialize(repeating: 0)
                        return 
                    }
                    
                    for row:Int in 0 ..< shape.y
                    {
                        (base + row * shape.x).initialize(from: buffer + row * pitch, count: shape.x)
                    }
                }
                
                let origin:Math<Int32>.V2 = (face.pointee.glyph.pointee.bitmap_left,
                                             face.pointee.glyph.pointee.bitmap_top)
                let rectangle:Math<Math<Int>.V2>.V2
                    rectangle.0   = Math.cast(origin, as: Int.self)
                    rectangle.1   = Math.add(rectangle.0, shape)
                let advance64:Int = face.pointee.glyph.pointee.advance.x
                let image:Array2D<UInt8> = .init(buffer, shape: shape)
                glyphs.append((codepoint, rectangle, advance64, image))
            }
            
            // determine width of atlas 
            let shape:Math<Int>.V2 = 
            (
                glyphs.map{ $0.3.shape.x }.reduce(0, (+)), 
                glyphs.map{ $0.3.shape.y }.max() ?? 0
            )
            
            let factor:Math<Float>.V2 = Math.reciprocal(Math.cast(shape, as: Float.self))
            
            var atlas:Array2D<UInt8>            = .init(repeating: 0, shape: shape), 
                charmap:[Unicode.Scalar: Glyph] = [:], 
                x:Int                           = 0
            for (codepoint, rectangle, advance64, image):
                (Unicode.Scalar, Math<Math<Int>.V2>.V2, Int, Array2D<UInt8>) in glyphs
            {
                atlas.assign(at: (x, 0), from: image)
                let uv:Math<Math<Float>.V2>.V2 = 
                (
                    Math.mult(Math.cast(         (x, 0),               as: Float.self), factor),
                    Math.mult(Math.cast(Math.add((x, 0), image.shape), as: Float.self), factor)
                )
                
                charmap[codepoint] = .init(rectangle: rectangle, uv: uv, advance64: advance64)
                x += image.shape.x
            }
            
            return (atlas, charmap)
        }
    }
}
