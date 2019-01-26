import FreeType

import PNG 


enum Fonts 
{
    static let terminal:(atlas:FontAtlas, texture:GL.Texture<UInt8>) = 
    {    
        let font:FontAtlas    = .init("assets/fonts/SourceCodePro-Medium.otf", fontsize: 16), 
            texture:GL.Texture<UInt8> = .generate()
        
        texture.bind(to: .texture2d)
        {
            $0.data(font.atlas, layout: .r8, storage: .r8)
            $0.setMagnificationFilter(.nearest)
            $0.setMinificationFilter(.nearest, mipmap: nil)
        }
        
        return (font, texture)
    }()
}

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
        (self.atlas, self.metrics) = Libraries.freetype.withFace(fontname)
        {
            (face:FT_Face) in 
            
            FreeType.checkError
            {
                FT_Set_Pixel_Sizes(face, 0, UInt32(size))
            }
            
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
                let size:Math<Int>.V2 = Math.cast((bitmap.width, bitmap.rows), as: Int.self),
                    buffer:[UInt8] = .init(unsafeUninitializedCapacity: Math.vol(size))
                {
                    $1 = Math.vol(size)
                    
                    let pitch:Int = .init(bitmap.pitch)
                    
                    guard   let base:UnsafeMutablePointer<UInt8>   = $0.baseAddress, 
                            let buffer:UnsafeMutablePointer<UInt8> = bitmap.buffer
                    else 
                    {
                        $0.initialize(repeating: 0)
                        return 
                    }
                    
                    for row:Int in 0 ..< size.y
                    {
                        (base + row * size.x).initialize(from: buffer + row * pitch, count: size.x)
                    }
                }

                let image:Array2D<UInt8>  = .init(buffer, size: size)
                let origin:Math<Int32>.V2 = (face.pointee.glyph.pointee.bitmap_left,
                                             face.pointee.glyph.pointee.bitmap_top)
                return .init(image: image, origin: Math.cast(origin, as: Int.self), codepoint: codepoint)
            }

            // determine maximum bounds
            let bounds:Math<Int>.V2
            bounds.0 = bitmaps.lazy.compactMap{             $0?.origin.y                     }.max() ?? 0
            bounds.1 = bitmaps.lazy.compactMap{ $0.flatMap{ $0.origin.y - $0.image.size.y } }.min() ?? 0

            // assemble font atlas
            var atlas:Array2D<UInt8> = .init(repeating: 0, size: (advance * codepoints, bounds.0 - bounds.1))
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
        let rectangle:Math<Int>.Rectangle, 
            uv:Math<Float>.Rectangle, 
            advance64:Int
    }
    
    let atlas:Array2D<UInt8>, 
        charmap:[Unicode.Scalar: Glyph], 
        height64:Int
    
    subscript(u:Unicode.Scalar) -> Glyph
    {
        return self.charmap[u] ?? self.charmap["\u{0}"]!
    }
    
    init(_ fontname:String, fontsize:Int) 
    {
        (self.atlas, self.charmap, self.height64) = Libraries.freetype.withFace(fontname)
        {
            (face:FT_Face) in 
            
            FreeType.checkError
            {
                FT_Set_Pixel_Sizes(face, 0, UInt32(fontsize))
            }
            
            Libraries.freetype.warnVerticalAdvance(face, fontname: fontname)
            
            var glyphs:[(Unicode.Scalar, Math<Int>.Rectangle, Int, Array2D<UInt8>)] = []
            for codepoint:Unicode.Scalar in (0 ..< 256).compactMap(Unicode.Scalar.init(_:)) 
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
                let size:Math<Int>.V2 = Math.cast((bitmap.width, bitmap.rows), as: Int.self),
                    buffer:[UInt8]     = .init(unsafeUninitializedCapacity: Math.vol(size))
                {
                    $1 = Math.vol(size)
                    
                    let pitch:Int = .init(bitmap.pitch)
                    
                    guard   let base:UnsafeMutablePointer<UInt8>   = $0.baseAddress, 
                            let buffer:UnsafeMutablePointer<UInt8> = bitmap.buffer
                    else 
                    {
                        $0.initialize(repeating: 0)
                        return 
                    }
                    
                    for row:Int in 0 ..< size.y
                    {
                        (base + row * size.x).initialize(from: buffer + row * pitch, count: size.x)
                    }
                }
                
                let origin:Math<Int32>.V2 = (face.pointee.glyph.pointee.bitmap_left,
                                            -face.pointee.glyph.pointee.bitmap_top)
                let rectangle:Math<Int>.Rectangle
                    rectangle.a   = Math.cast(origin, as: Int.self)
                    rectangle.b   = Math.add(rectangle.a, size)
                let advance64:Int = face.pointee.glyph.pointee.advance.x
                let image:Array2D<UInt8> = .init(buffer, size: size)
                glyphs.append((codepoint, rectangle, advance64, image))
            }
            
            // determine width of atlas 
            let size:Math<Int>.V2 = 
            (
                Math.maskUp(glyphs.map{ $0.3.size.x }.reduce(0, (+)), exponent: 2), 
                glyphs.map{ $0.3.size.y }.max() ?? 0
            )
            
            let factor:Math<Float>.V2 = Math.reciprocal(Math.cast(size, as: Float.self))
            
            var atlas:Array2D<UInt8>            = .init(repeating: 0, size: size), 
                charmap:[Unicode.Scalar: Glyph] = [:], 
                x:Int                           = 0
            for (codepoint, rectangle, advance64, image):
                (Unicode.Scalar, Math<Int>.Rectangle, Int, Array2D<UInt8>) in glyphs
            {
                atlas.assign(at: (x, 0), from: image)
                let uv:Math<Float>.Rectangle = 
                (
                    Math.mult(Math.cast(         (x, 0),              as: Float.self), factor),
                    Math.mult(Math.cast(Math.add((x, 0), image.size), as: Float.self), factor)
                )
                
                //Log.dump(Math.mult(uv.0, Math.cast(size, as: Float.self)), Math.mult(uv.1, Math.cast(size, as: Float.self)))
                charmap[codepoint] = .init( rectangle: (Math.mult(rectangle.a, (1, -1)), Math.mult(rectangle.b, (1, -1))), 
                                                   uv: uv, 
                                            advance64: advance64)
                x += image.size.x
            }
            
            let height64:Int = fontsize * Int(face.pointee.height) << 6 / Int(face.pointee.units_per_EM)
            
            return (atlas, charmap, height64)
        }
    }
}

struct Font 
{
    struct Text 
    {
        @_fixed_layout
        @usableFromInline
        struct Vertex 
        {
            var xy:Math<Float>.V2, 
                uv:Math<Float>.V2, 
                
                color:Math<UInt8>.V4
            
            init(_ xy:Math<Float>.V2, uv:Math<Float>.V2, color:Math<UInt8>.V4)
            {
                self.xy = xy
                self.uv = uv
                self.color = color
            }
        }
        
        private 
        let vao:GL.VertexArray 
        private 
        var vvo:GL.Vector<Math<Vertex>.V2>
        
        init() 
        {
            self.vao = .generate()
            self.vvo = .generate()
            
            self.vvo.buffer.bind(to: .array)
            {
                self.vao.bind().setVertexLayout(.float(from: .float2), .float(from: .float2), .float(from: .ubyte4_rgba))
                self.vao.unbind()
            }
        }
    }
    enum TextAlign 
    {
        case left, center, right
    }
    
    struct Glyph 
    {
        let rectangle:Math<Int>.Rectangle, 
            uv:Math<Float>.Rectangle
    }
    
    let glyphs:[Glyph], 
        texture:GL.Texture<UInt8>, 
        hbfont:HarfBuzz.Font 
    
    static 
    func create(_ fontname:String, size fontsize:Int) -> Font 
    {
        return Libraries.freetype.withFace(fontname)
        {
            (face:FT_Face) in 
            
            return create(face: face, size: fontsize)
        }
    }
    
    func shape(_ text:String, origin:Math<Int>.V2, align:TextAlign = .left) 
    {
        let line:[(Int, Math<Int>.V2)] = self.hbfont.shape(text)
        let width:Int = (line.last?.1.x ?? 0) - (line.first?.1.x ?? 0)
        let offset:Math<Int>.V2 
        switch align 
        {
            case .left:
                offset =  origin 
            case .center:
                offset = (origin.x - width / 2, origin.y)
            case .right:
                offset = (origin.x - width,     origin.y)
        }
        
        /* return line.map 
        {
            let position:Math<Int>.V2 = Math.add($0.1, offset) 
            
        } */
    }

    private static 
    func create(face:FT_Face, size fontsize:Int) -> Font 
    {
        FreeType.checkError
        {
            FT_Set_Pixel_Sizes(face, 0, .init(fontsize))
        }
        
        // load ALL the glyphs         
        let glyphImages:[(Math<Int>.Rectangle, Array2D<UInt8>)] = 
            (0 ..< face.pointee.num_glyphs).map 
        {
            (index:Int) in
            
            guard 
            (
                FreeType.checkError
                {
                    // dumb integer cast because Freetype defines all the bitfield
                    // constants (except for FT_LOAD_DEFAULT) as `long`s
                    FT_Load_Glyph(face, .init(index), .init(FT_LOAD_RENDER))
                }
            )
            else
            {
                return (((0, 0), (0, 0)), .init()) 
            }
            
            let bitmap:FT_Bitmap    = face.pointee.glyph.pointee.bitmap, 
                size:Math<Int>.V2   = Math.cast((bitmap.width, bitmap.rows), as: Int.self), 
                pitch:Int           = .init(bitmap.pitch)
            let buffer:UnsafeBufferPointer<UInt8> = .init(start: bitmap.buffer, count: pitch * size.y)
            let image:Array2D<UInt8>    = .init(buffer, pitch: pitch, size: size)
            
            let origin:Math<Int32>.V2   = (face.pointee.glyph.pointee.bitmap_left,
                                          -face.pointee.glyph.pointee.bitmap_top)
            let rectangle:Math<Int>.Rectangle
                rectangle.a   = Math.cast(origin, as: Int.self)
                rectangle.b   = Math.add(rectangle.a, size)
            
            return (rectangle, image)
        }
        
        let (offsets, atlas):([Math<Int>.V2], Array2D<UInt8>) = pack(glyphImages.map{ $0.1 }) 
        
        // debug 
        do 
        {
            try PNG.encode(v: atlas.buffer, size: (atlas.size.x, atlas.size.y), as: .v8, path: "font.png")
        }
        catch 
        {
            print(error)
        }
        
        let divisor:Math<Float>.V2  = Math.cast(atlas.size, as: Float.self)
        let glyphs:[Glyph]          = zip(glyphImages.map{ $0.0 }, offsets).map 
        {
            let a:Math<Float>.V2    = Math.cast($0.1,                       as: Float.self), 
                size:Math<Float>.V2 = Math.cast(Math.sub($0.0.b, $0.0.a),   as: Float.self)
            let uv:Math<Float>.Rectangle = 
            (
                Math.div(         a,        divisor), 
                Math.div(Math.add(a, size), divisor)
            )
            
            return .init(rectangle: $0.0, uv: uv)
        }
        
        let texture:GL.Texture<UInt8> = .generate()
        
        texture.bind(to: .texture2d)
        {
            $0.data(atlas, layout: .r8, storage: .r8)
            $0.setMagnificationFilter(.nearest)
            $0.setMinificationFilter(.nearest, mipmap: nil)
        }
        
        let family:String = .init(cString: face.pointee.family_name), 
            style:String  = .init(cString: face.pointee.style_name)
        Log.note("loaded \(glyphs.count) glyphs @ \(fontsize) px from font '\(family):\(style)' (\(atlas.buffer.count >> 10) KB)")
        
        let hbface:HarfBuzz.Face = .create(fromFreetype: face), 
            hbfont:HarfBuzz.Font = hbface.font(size: fontsize) 
        hbface.destroy()
        
        return .init(glyphs: glyphs, texture: texture, hbfont: hbfont)
    }
    
    private static 
    func pack(_ sprites:[Array2D<UInt8>]) -> ([Math<Int>.V2], Array2D<UInt8>)
    {
        // sort rectangles in increasing height 
        let sorted:[Array2D<UInt8>] = sprites.sorted 
        {
            $0.size.y < $1.size.y
        }
        
        // guaranteed to be at least the width of the widest glyph
        let width:Int               = optimalWidth(sorted: sorted) 
        var rows:[[Array2D<UInt8>]] = [], 
            row:[Array2D<UInt8>]    = [], 
            x:Int                   = 0
        for sprite:Array2D<UInt8> in sorted 
        {        
            x += sprite.size.x 
            if x > width 
            {
                rows.append(row)
                row = []
                x   = sprite.size.x
            }
            
            row.append(sprite)
        }
        rows.append(row)
        
        let height:Int              = rows.reduce(0){ $0 + ($1.last?.size.y ?? 0) }
        var packed:Array2D<UInt8>   = .init(repeating: 0, size: (width, height)), 
            position:Math<Int>.V2   = (0, 0)
        var positions:[Math<Int>.V2] = []
        for row:[Array2D<UInt8>] in rows 
        {
            for sprite:Array2D<UInt8> in row 
            {
                packed.assign(at: position, from: sprite)
                positions.append(position)
                position.x += sprite.size.x
            }
            
            position.x  = 0
            position.y += row.last?.size.y ?? 0
        }
        
        return (positions, packed)
    }
    
    private static 
    func optimalWidth(sorted:[Array2D<UInt8>]) -> Int 
    {
        let slate:Math<Int>.V2 = 
        (
            sorted.reduce(0){ $0 + $1.size.x }, 
            sorted.last?.size.y ?? 0
        )
        let minWidth:Int    = Math.nextPowerOfTwo(sorted.map{ $0.size.x }.max() ?? 0)
        var width:Int       = minWidth
        while width * width < slate.y * slate.x 
        {
            width <<= 1
        }
        
        return max(minWidth, width >> 1)
    }
}
