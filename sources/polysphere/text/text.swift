import FreeType

import PNG 

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
        let sprites:[(Vector2<Int>, Array2D<UInt8>)] = (0 ..< self.ftface.object.pointee.num_glyphs).map 
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
                return (.zero, .init()) 
            }
            
            let bitmap:FT_Bitmap    = self.ftface.object.pointee.glyph.pointee.bitmap, 
                size:Vector2<Int>   = Vector2.init(bitmap.width, bitmap.rows).map(Int.init(_:)), 
                pitch:Int           = .init(bitmap.pitch)
            let buffer:UnsafeBufferPointer<UInt8> = .init(start: bitmap.buffer, count: pitch * size.y)
            let image:Array2D<UInt8>    = .init(buffer, pitch: pitch, size: size)
            
            let origin:Vector2<Int32>   = .init(self.ftface.object.pointee.glyph.pointee.bitmap_left,
                                               -self.ftface.object.pointee.glyph.pointee.bitmap_top)
            
            return (origin.map(Int.init(_:)), image)
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
            let buffer:[(Vector2<Int>, Array2D<UInt8>)], 
                hbfont:HarfBuzz.Font // hbfonts are preretained +1
            
            var bitmaps:[Array2D<UInt8>] 
            {
                return self.buffer.map{ $0.1 }
            }
            
            var glyphCount:Int 
            {
                return self.buffer.count
            }
            
            init(_ buffer:[(Vector2<Int>, Array2D<UInt8>)], hbfont:HarfBuzz.Font) 
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
            let sprites:[Rectangle<Float>]
            
            subscript(index:Int) -> Rectangle<Float> 
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
                
                let height:Int                  = rows.reduce(0){ $0 + ($1.last?.1.size.y ?? 0) }
                var packed:Array2D<UInt8>       = .init(repeating: 0, size: .init(width, height)), 
                    position:Vector2<Int>       = .zero
                var sprites:[Rectangle<Float>]  = .init(repeating: .zero, count: bitmaps.count)
                
                let divisor:Vector2<Float> = .cast(.init(width, height))
                for row:[(Int, Array2D<UInt8>)] in rows 
                {
                    for (index, bitmap):(Int, Array2D<UInt8>) in row 
                    {
                        packed.assign(at: position, from: bitmap)
                        sprites[index] = .init(
                            .cast(position               ) / divisor,
                            .cast(position &+ bitmap.size) / divisor
                        )
                        
                        position.x += bitmap.size.x
                    }
                    
                    position.x  = 0
                    position.y += row.last?.1.size.y ?? 0
                }
                
                try!    PNG.encode(v: packed.buffer, 
                                size: (packed.size.x, packed.size.y), 
                                  as: .v8, 
                                path: "fontatlas-debug.png")
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
            func optimalWidth(sizes:[Vector2<Int>]) -> Int 
            {
                let slate:Vector2<Int> = .init(
                    sizes.reduce(0){ $0 + $1.x }, 
                    sizes.last?.y ?? 0
                )
                let minWidth:Int    = .nextPowerOfTwo(sizes.map{ $0.x }.max() ?? 0)
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
            let vertices:Rectangle<Int>, 
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
                let vertices:Rectangle<Int> = .init($0.1.0, $0.1.0 &+ $0.1.1.size)
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
        let physicalCoordinates:Rectangle<Float>,  
            textureCoordinates:Rectangle<Float> 
    }
    
    @_fixed_layout
    @usableFromInline
    struct Vertex 
    {
        // make this a perfect 32 B
        var anchor:(Float, Float),  // UV anchor, in normalized coordinates
            offset:(Float, Float),  // screen offset, in pixels 
            trace:(Float, Float, Float),    // 3D trace source
            color:(UInt8, UInt8, UInt8, UInt8)   // glyph color 
        
        init(anchor:Vector2<Float>, offset:Vector2<Float>, color:Vector4<UInt8>, trace:Vector3<Float> = .zero) 
        {
            self.anchor = (anchor.x, anchor.y)
            self.offset = (offset.x, offset.y)
            self.trace  = (trace.x, trace.y, trace.z)
            self.color  = (color.x, color.y, color.z, color.w)
        }
    }
    
    private 
    let glyphs:[Glyph]
    
    var color:Vector4<UInt8>
    
    static 
    func line(_ runs:[(Style.Definitions.Inline.Computed, String)], indent:Int = 0, atlas:Typeface.Font.Atlas) -> [Text] 
    {
        var texts:[Text] = []
        var lineorigin:Vector2<Int> = .init(indent, 0)
        for (style, text):(Style.Definitions.Inline.Computed, String) in runs 
        {
            var glyphs:[Glyph]  = []
            var cursor:Int      = lineorigin.x
            for reference:HarfBuzz.Glyph in style.font.hbfont.line(text, features: style.features, indent: &cursor)  
            {
                let fontglyph:Typeface.Font.Glyph   = style.font.glyphs[reference.index], 
                    position:Vector2<Int>           = reference.position &+ lineorigin
                
                let physicalCoordinates:Rectangle<Float> = .init(
                    .cast(fontglyph.vertices.a &+ position), 
                    .cast(fontglyph.vertices.b &+ position)
                )
                
                let glyph:Glyph    = .init(physicalCoordinates: physicalCoordinates, 
                                            textureCoordinates: atlas[fontglyph.sprite])
                glyphs.append(glyph)
            }
            
            lineorigin.x = cursor 
            
            texts.append(.init(glyphs: glyphs, color: style.color))
        }
        
        return texts
    }
    
    static 
    func paragraph(_ runs:[(Style.Definitions.Inline.Computed, String)], linebox:Vector2<Int>, indent:Int = 0, atlas:Typeface.Font.Atlas) -> [Text]
    {
        var texts:[Text] = []
        var lineorigin:Vector2<Int> = .init(indent, 0) 
        for (style, text):(Style.Definitions.Inline.Computed, String) in runs 
        {
            var glyphs:[Glyph]  = []
            var cursor:Int?     = lineorigin.x
            for line:[HarfBuzz.Glyph] in style.font.hbfont.paragraph(text, features: style.features, indent: &cursor, width: linebox.x) 
            {
                for reference:HarfBuzz.Glyph in line 
                {
                    let fontglyph:Typeface.Font.Glyph = style.font.glyphs[reference.index], 
                        position:Vector2<Int> = reference.position &+ lineorigin
                    
                    let physicalCoordinates:Rectangle<Float> = .init(
                        .cast(fontglyph.vertices.a &+ position), 
                        .cast(fontglyph.vertices.b &+ position)
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
    
    func vertices(at origin:Vector2<Int>, tracing point:Vector3<Float> = .zero) -> [Vertex] 
    {
        let offset:Vector2<Float>   = .cast(origin)
        var vertices:[Vertex]       = []
            vertices.reserveCapacity(self.glyphs.count * 2)
        for glyph:Glyph in self.glyphs
        {
            let physical:Rectangle<Float> = .init(
                glyph.physicalCoordinates.a + offset,
                glyph.physicalCoordinates.b + offset
            )
            vertices.append(.init(anchor: glyph.textureCoordinates.a, offset: physical.a, color: self.color, trace: point))
            vertices.append(.init(anchor: glyph.textureCoordinates.b, offset: physical.b, color: self.color, trace: point))
        }
        
        return vertices
    }
}
