import FreeType

import PNG 

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
        (self.atlas, self.metrics) = FreeType.withFace(fontname)
        {
            (face:FT_Face) in 
            
            FreeType.checkError
            {
                FT_Set_Pixel_Sizes(face, 0, UInt32(size))
            }
            
            FreeType.warnMonospace(face, fontname: fontname)
            FreeType.warnVerticalAdvance(face, fontname: fontname)
            
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

final 
class Typeface 
{
    private 
    let ftface:FreeType.Face
     
    let family:String, 
        style:String 
    
    init?(_ fontname:String) 
    {
        guard let ftface:FreeType.Face = .create(fontname) 
        else 
        {
            return nil 
        }
        
        self.ftface = ftface 
        
        self.family = .init(cString: ftface.object.pointee.family_name)
        self.style  = .init(cString: ftface.object.pointee.style_name)
    }
    
    deinit 
    {
        self.ftface.release()
    }
    
    fileprivate 
    func render(size fontsize:Int) -> Font.Unassembled 
    {
        FreeType.checkError
        {
            FT_Set_Pixel_Sizes(self.ftface.object, 0, .init(fontsize))
        }
        
        // load ALL the glyphs         
        let sprites:[(Math<Int>.V2, Array2D<UInt8>)] = (0 ..< self.ftface.object.pointee.num_glyphs).map 
        {
            (index:Int) in
            
            guard 
            (
                FreeType.checkError
                {
                    // dumb integer cast because Freetype defines all the bitfield
                    // constants (except for FT_LOAD_DEFAULT) as `long`s
                    FT_Load_Glyph(self.ftface.object, .init(index), .init(FT_LOAD_RENDER | FT_LOAD_NO_HINTING))
                }
            )
            else
            {
                return ((0, 0), .init()) 
            }
            
            let bitmap:FT_Bitmap    = self.ftface.object.pointee.glyph.pointee.bitmap, 
                size:Math<Int>.V2   = Math.cast((bitmap.width, bitmap.rows), as: Int.self), 
                pitch:Int           = .init(bitmap.pitch)
            let buffer:UnsafeBufferPointer<UInt8> = .init(start: bitmap.buffer, count: pitch * size.y)
            let image:Array2D<UInt8>    = .init(buffer, pitch: pitch, size: size)
            
            let origin:Math<Int32>.V2   = (self.ftface.object.pointee.glyph.pointee.bitmap_left,
                                          -self.ftface.object.pointee.glyph.pointee.bitmap_top)
            
            return (Math.cast(origin, as: Int.self), image)
        }
        
        return .init(sprites, hbfont: .create(fromFreetype: self.ftface))
    }
    
    final 
    class Font 
    {
        // used to hold glyph images, which are combined among many fonts to make 
        // one atlas 
        fileprivate 
        struct Unassembled 
        {
            let buffer:[(Math<Int>.V2, Array2D<UInt8>)], 
                hbfont:HarfBuzz.Font // hbfonts are preretained +1
            
            var bitmaps:[Array2D<UInt8>] 
            {
                return self.buffer.map{ $0.1 }
            }
            
            var glyphCount:Int 
            {
                return self.buffer.count
            }
            
            init(_ buffer:[(Math<Int>.V2, Array2D<UInt8>)], hbfont:HarfBuzz.Font) 
            {
                self.buffer = buffer 
                self.hbfont = hbfont 
            }
        }
        
        final 
        class Atlas 
        {
            let texture:GL.Texture<UInt8> 
            
            private 
            let sprites:[Math<Float>.Rectangle]
            
            subscript(index:Int) -> Math<Float>.Rectangle 
            {
                return self.sprites[index]
            }
            
            fileprivate 
            init(_ bitmaps:[Array2D<UInt8>])
            {
                // sort rectangles in increasing height 
                let sorted:[(Int, Array2D<UInt8>)] = zip(bitmaps.indices, bitmaps).sorted 
                {
                    $0.1.size.y < $1.1.size.y
                }
                
                // guaranteed to be at least the width of the widest glyph
                let width:Int                       = Atlas.optimalWidth(sizes: sorted.map{ $0.1.size }) 
                var rows:[[(Int, Array2D<UInt8>)]]  = [], 
                    row:[(Int, Array2D<UInt8>)]     = [], 
                    x:Int                           = 0
                for (index, bitmap):(Int, Array2D<UInt8>) in sorted 
                {        
                    x += bitmap.size.x 
                    if x > width 
                    {
                        rows.append(row)
                        row = []
                        x   = bitmap.size.x
                    }
                    
                    row.append((index, bitmap))
                }
                rows.append(row)
                
                let height:Int              = rows.reduce(0){ $0 + ($1.last?.1.size.y ?? 0) }
                var packed:Array2D<UInt8>   = .init(repeating: 0, size: (width, height)), 
                    position:Math<Int>.V2   = (0, 0)
                var sprites:[Math<Float>.Rectangle] = .init(repeating: ((0, 0), (0, 0)), count: bitmaps.count)
                
                let divisor:Math<Float>.V2  = Math.cast((width, height), as: Float.self)
                for row:[(Int, Array2D<UInt8>)] in rows 
                {
                    for (index, bitmap):(Int, Array2D<UInt8>) in row 
                    {
                        packed.assign(at: position, from: bitmap)
                        sprites[index] = 
                        (
                            Math.div(Math.cast(         position,               as: Float.self), divisor),
                            Math.div(Math.cast(Math.add(position, bitmap.size), as: Float.self), divisor)
                        )
                        
                        position.x += bitmap.size.x
                    }
                    
                    position.x  = 0
                    position.y += row.last?.1.size.y ?? 0
                }
                
                try! PNG.encode(v: packed.buffer, size: packed.size, as: .v8, path: "fontatlas-debug.png")
                Log.note("rendered font atlas of \(sprites.count) glyphs, \(packed.buffer.count >> 10) KB")
                
                let texture:GL.Texture<UInt8> = .generate()
                texture.bind(to: .texture2d)
                {
                    $0.data(packed, layout: .r8, storage: .r8)
                    $0.setMagnificationFilter(.nearest)
                    $0.setMinificationFilter(.nearest, mipmap: nil)
                }
                
                self.texture = texture 
                self.sprites = sprites 
            }
            
            deinit 
            {
                self.texture.destroy()
            }
            
            private static 
            func optimalWidth(sizes:[Math<Int>.V2]) -> Int 
            {
                let slate:Math<Int>.V2 = 
                (
                    sizes.reduce(0){ $0 + $1.x }, 
                    sizes.last?.y ?? 0
                )
                let minWidth:Int    = Math.nextPowerOfTwo(sizes.map{ $0.x }.max() ?? 0)
                var width:Int       = minWidth
                while width * width < slate.y * slate.x 
                {
                    width <<= 1
                }
                
                return max(minWidth, width >> 1)
            }
        }
        
        struct Glyph 
        {
            let vertices:Math<Int>.Rectangle, 
                sprite:Int
        }
        
        let glyphs:[Glyph], 
            hbfont:HarfBuzz.Font 
        
        static 
        func assemble(_ requests:[Style.Definitions.Font], from typefaces:[Style.Definitions.Face: (Typeface, Int)]) -> (Atlas, [Font])
        {
            var fallback:Typeface? = nil 
            let unassembled:[Unassembled] = requests.map
            {
                let typeface:Typeface 
                if let lookup:Typeface = typefaces[$0.face]?.0 ?? fallback
                {
                    typeface = lookup 
                }
                else 
                {
                    fallback = Typeface.init("assets/fonts/fallback") 
                    
                    guard let fallback:Typeface = fallback 
                    else 
                    {
                        Log.fatal("failed to load fallback font")
                    }
                    
                    typeface = fallback 
                }
                
                let scale:Int = typefaces[$0.face]?.1 ?? 16
                return typeface.render(size: $0.size * scale / 16)
            }
            
            var indices:[Range<Int>]        = [], 
                bitmaps:[Array2D<UInt8>]    = []
            for unassembled:Unassembled in unassembled
            {
                let base:Int = bitmaps.endIndex 
                bitmaps.append(contentsOf: unassembled.bitmaps)
                indices.append(base ..< bitmaps.endIndex) 
            }
            
            let atlas:Atlas  = .init(bitmaps)
            let fonts:[Font] = zip(unassembled, indices).map 
            {
                return .init($0.0, indices: $0.1)
            }
            
            return (atlas, fonts)
        }
        
        private 
        init(_ unassembled:Unassembled, indices:Range<Int>) 
        {
            self.glyphs = zip(indices, unassembled.buffer).map 
            {
                let vertices:Math<Int>.Rectangle  = 
                (
                             $0.1.0, 
                    Math.add($0.1.0, $0.1.1.size)
                )
                
                return .init(vertices: vertices, sprite: $0.0)
            }
            
            self.hbfont  = unassembled.hbfont 
        }
        
        deinit 
        {
            self.hbfont.release()
        }
    }
}

struct Text 
{
    struct Glyph 
    {
        let physicalCoordinates:Math<Float>.Rectangle,  
            textureCoordinates:Math<Float>.Rectangle 
    }
    
    @_fixed_layout
    @usableFromInline
    struct Vertex 
    {
        // make this a perfect 32 B
        var anchor:Math<Float>.V2,  // UV anchor, in normalized coordinates
            offset:Math<Float>.V2,  // screen offset, in pixels 
            color:Math<UInt8>.V4,   // glyph color 
            trace:Math<Float>.V3    // 3D trace source
    }
    
    private 
    let glyphs:[Glyph]
    
    var color:Math<UInt8>.V4
    
    static 
    func line(_ runs:[(Style.Definitions.Inline.Computed, String)], indent:Int = 0, atlas:Typeface.Font.Atlas) -> [Text] 
    {
        var texts:[Text] = []
        var lineorigin:Math<Int>.V2 = (indent, 0)
        for (style, text):(Style.Definitions.Inline.Computed, String) in runs 
        {
            var glyphs:[Glyph]  = []
            var cursor:Int      = lineorigin.x
            for reference:HarfBuzz.Glyph in style.font.hbfont.line(text, features: style.features, indent: &cursor)  
            {
                let fontglyph:Typeface.Font.Glyph = style.font.glyphs[reference.index], 
                    position:Math<Int>.V2 = Math.add(reference.position, lineorigin)
                
                let physicalCoordinates:Math<Float>.Rectangle = 
                (
                    Math.cast(Math.add(fontglyph.vertices.a, position), as: Float.self), 
                    Math.cast(Math.add(fontglyph.vertices.b, position), as: Float.self)
                )
                
                let glyph:Glyph    = .init(physicalCoordinates: physicalCoordinates, 
                                            textureCoordinates: atlas[fontglyph.sprite])
                glyphs.append(glyph)
            }
            
            lineorigin.x  = cursor 
            
            texts.append(.init(glyphs: glyphs, color: style.color))
        }
        
        return texts
    }
    
    static 
    func paragraph(_ runs:[(Style.Definitions.Inline.Computed, String)], linebox:Math<Int>.V2, indent:Int = 0, atlas:Typeface.Font.Atlas) -> [Text]
    {
        var texts:[Text] = []
        var lineorigin:Math<Int>.V2 = (indent, 0) 
        for (style, text):(Style.Definitions.Inline.Computed, String) in runs 
        {
            var glyphs:[Glyph]  = []
            var cursor:Int?     = lineorigin.x
            for line:[HarfBuzz.Glyph] in style.font.hbfont.paragraph(text, features: style.features, indent: &cursor, width: linebox.x) 
            {
                for reference:HarfBuzz.Glyph in line 
                {
                    let fontglyph:Typeface.Font.Glyph = style.font.glyphs[reference.index], 
                        position:Math<Int>.V2 = Math.add(reference.position, lineorigin)
                    
                    let physicalCoordinates:Math<Float>.Rectangle = 
                    (
                        Math.cast(Math.add(fontglyph.vertices.a, position), as: Float.self), 
                        Math.cast(Math.add(fontglyph.vertices.b, position), as: Float.self)
                    )
                    
                    let glyph:Glyph    = .init(physicalCoordinates: physicalCoordinates, 
                                                textureCoordinates: atlas[fontglyph.sprite])
                    glyphs.append(glyph)
                }
                
                lineorigin.x  = 0 
                lineorigin.y += linebox.y
            }
            
            if let cursor:Int = cursor 
            {
                lineorigin.x  = cursor 
                lineorigin.y -= linebox.y 
            } 
            else 
            {
                lineorigin.x  = 0
            }
            
            texts.append(.init(glyphs: glyphs, color: style.color))
        }
        
        return texts
    }
    
    func vertices(at origin:Math<Int>.V2, tracing point:Math<Float>.V3 = (0, 0, 0)) -> [Vertex] 
    {
        let offset:Math<Float>.V2   = Math.cast(origin, as: Float.self)
        var vertices:[Vertex]       = []
            vertices.reserveCapacity(self.glyphs.count * 2)
        for glyph:Glyph in self.glyphs
        {
            let physical:Math<Float>.Rectangle = 
            (
                Math.add(glyph.physicalCoordinates.a, offset),
                Math.add(glyph.physicalCoordinates.b, offset)
            )
            vertices.append(.init(anchor: glyph.textureCoordinates.a, offset: physical.a, color: self.color, trace: point))
            vertices.append(.init(anchor: glyph.textureCoordinates.b, offset: physical.b, color: self.color, trace: point))
        }
        
        return vertices
    }
}
