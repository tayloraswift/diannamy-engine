import HarfBuzz
import FreeType

struct Text 
{
    // private 
    struct Glyph 
    {
        let tc:Rectangle<Float>,    // texture coordinates
            pc:Rectangle<Float>     // physical coordinates 
    }
    
    @_fixed_layout
    @usableFromInline
    struct Vertex 
    {
        // make this a perfect 32 B
        var tc2:(Float, Float),                 // UV anchor, in normalized coordinates
            pc2:(Float, Float),                 // screen offset, in pixels 
            pc3:(Float, Float, Float),          // 3D trace source
            color:(UInt8, UInt8, UInt8, UInt8)  // glyph color 
        
        init(tc:Vector2<Float>, pc:Vector2<Float>, color:Vector4<UInt8>, trace:Vector3<Float>) 
        {
            self.tc2    = (tc.x, tc.y)
            self.pc2    = (pc.x, pc.y)
            self.pc3    = (trace.x, trace.y, trace.z)
            self.color  = (color.x, color.y, color.z, color.w)
        }
    }
    
        
    func vertices(at origin:Vector2<Int>, tracing point:Vector3<Float> = .zero) -> [Vertex] 
    {
        let offset:Vector2<Float>   = .cast(origin)
        var vertices:[Vertex]       = []
            vertices.reserveCapacity(self.glyphs.count * 2)
        for (style, run):(Style.Definitions.Inline.Computed, Range<Int>) in self.runs 
        {
            for glyph:Glyph in self.glyphs[run]
            {
                let pc:(Vector2<Float>, Vector2<Float>) = 
                (
                    glyph.pc.a + offset,
                    glyph.pc.b + offset
                )
                vertices.append(.init(tc: glyph.tc.a, pc: pc.0, color: style.color, trace: point))
                vertices.append(.init(tc: glyph.tc.b, pc: pc.1, color: style.color, trace: point))
            }
        }
        
        return vertices
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
    
    
    private
    struct Sort 
    {
        let bitmap:Array2D<UInt8>, 
            origin:Vector2<Int>, 
            metric:Vector2<Int>
            
        init(_ bitmap:Array2D<UInt8>, origin:Vector2<Int>, metric:Vector2<Int>)
        {
            self.bitmap = bitmap 
            self.origin = origin 
            self.metric = metric 
        }
    }
    
    private 
    func render(size fontsize:Int) -> ([Font.Sort], HarfBuzz.Font)
    {
        FreeType.checkError
        {
            FT_Set_Pixel_Sizes(self.ftface.object, 0, .init(fontsize))
        }
        
        // load ALL the glyphs         
        let sorts:[Font.Sort] = (0 ..< self.ftface.object.pointee.num_glyphs).map 
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
                return .init(.init(), origin: .zero, metric: .zero) 
            }
            
            let slot:UnsafeMutablePointer<FT_GlyphSlotRec> = self.ftface.object.pointee.glyph 
            
            let bitmap:FT_Bitmap    = slot.pointee.bitmap, 
                size:Vector2<Int>   = .cast(.init(bitmap.width, bitmap.rows)), 
                pitch:Int           = .init(bitmap.pitch)
            
            // copy bitmap buffer into 2D array
            let buffer:UnsafeBufferPointer<UInt8> = .init(start: bitmap.buffer, count: pitch * size.y)
            let image:Array2D<UInt8>    = .init(buffer, pitch: pitch, size: size)
            
            let origin:Vector2<Int>     = .cast(.init(slot.pointee.bitmap_left, -slot.pointee.bitmap_top)), 
                metric:Vector2<Int>     = .cast(.init(slot.pointee.advance.x,    slot.pointee.advance.y)) &>> 6
            
            return .init(image, origin: origin, metric: metric)
        }
        
        // hbfonts are preretained +1
        return (sorts, .create(fromFreetype: self.ftface))
    }
    
    static 
    func assemble(_ selections:[FontSelection]) -> (Atlas, [Font])
    {
        var faces:[String: Typeface]    = [:], 
            fallback:Typeface?          = nil 
        var unassembled:[([Sort], HarfBuzz.Font)] = []
        for selection:FontSelection in selections
        {
            let face:Typeface 
            if let result:Typeface = faces[fontSelection.fontfile] 
            {
                face = result 
            }
            else 
            {
                if let result:Typeface = Typeface.init(fontSelection.fontfile) ?? fallback
                {
                    face = result 
                }
                else 
                {
                    fallback = Typeface.init("assets/fonts/fallback") 
                    
                    guard let fallback:Typeface = fallback 
                    else 
                    {
                        Log.fatal("failed to load fallback font")
                    }
                    
                    face = fallback 
                }
                
                faces[fontSelection.fontfile] = face 
            }
            
            unassembled.append(face.render(size: selection.size))
        }
        
        var indices:[Range<Int>]        = [], 
            bitmaps:[Array2D<UInt8>]    = []
        for (sorts, _):([Sort], HarfBuzz.Font) in unassembled
        {
            let base:Int = bitmaps.endIndex 
            bitmaps.append(contentsOf: sorts.map{ $0.bitmap })
            indices.append(base ..< bitmaps.endIndex) 
        }
        
        let atlas:Atlas  = .init(bitmaps)
        let fonts:[Font] = zip(unassembled, indices).map 
        {
            let ((sorts, hbfont), indices):(([Sort], HarfBuzz.Font), Range<Int>) = $0
            
            let sortInfo:Font.SortInfo = zip(indices, sorts).map 
            {
                let (index, sort):(Int, Sort) = $0 
                
                let vertices:Rectangle<Int> = .init(sort.origin, sort.origin &+ sort.bitmap.size)
                return .init(vertices: vertices, footprint: sort.metric.x, sprite: index)
            }
            
            return .init(sorts: sortInfo, hbfont: hbfont)
        }
        
        return (atlas, fonts)
    }
    
    final 
    class Font 
    { 
        struct SortInfo 
        {
            let vertices:Rectangle<Int>, 
                footprint:Int, 
                sprite:Int
        }
        
        fileprivate 
        let sorts:[SortInfo], 
            hbfont:HarfBuzz.Font 
        
        deinit 
        {
            self.hbfont.release()
        }
    }
}

fileprivate 
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
        let error:Int = .init(body()) // why the cast?
        switch error
        {
            case FT_Err_Ok:
                return true

            default:
                Log.error(FreeType.errors[.init(error)] ?? "unknown error", from: .freetype)
                return false
        }
    }
}

enum HarfBuzz 
{
    struct ShapingParameters 
    {
        let font:Typeface.Font, 
            features:[(UInt32, UInt32)]
    }
    
    struct Glyph 
    {
        let position:Vector2<Int>, 
            cluster:Int, 
            index:Int
        
        func relative(to origin:Vector2<Int>) -> Self 
        {
            return .init(position: self.position &- origin, cluster: self.cluster, index: self.index)
        }
    }
    
    fileprivate
    struct Font 
    {
        private  
        let object:OpaquePointer 
        
        static 
        func create(fromFreetype ftface:FreeType.Face) -> Font 
        {
            let font:OpaquePointer = hb_ft_font_create_referenced(ftface.object) 
            return .init(object: font)
        }
        
        func retain() 
        {
            hb_font_reference(self.object)
        }
        
        func release() 
        {
            hb_font_destroy(self.object)
        }
        
        fileprivate 
        func shape(_ text:ArraySlice<Character>, features:[hb_feature_t]) -> Line 
        {
            let buffer:OpaquePointer = hb_buffer_create() 
            defer 
            {
                hb_buffer_destroy(buffer)
            }
            
            for (i, character):(Int, Character) in zip(text.indices, text) 
            {
                for codepoint:Unicode.Scalar in character.unicodeScalars 
                {
                    hb_buffer_add(buffer, codepoint.value, .init(i))
                }
            }
            
            hb_buffer_set_content_type(buffer, HB_BUFFER_CONTENT_TYPE_UNICODE)
            
            hb_buffer_set_direction(buffer, HB_DIRECTION_LTR)
            hb_buffer_set_script(buffer, HB_SCRIPT_LATIN)
            hb_buffer_set_language(buffer, hb_language_from_string("en-US", -1))
            
            hb_shape(self.object, buffer, features, .init(features.count))
            
            let count:Int = .init(hb_buffer_get_length(buffer))
            let infos:UnsafeBufferPointer<hb_glyph_info_t> = 
                .init(start: hb_buffer_get_glyph_infos(buffer, nil), count: count) 
            let deltas:UnsafeBufferPointer<hb_glyph_position_t> = 
                .init(start: hb_buffer_get_glyph_positions(buffer, nil), count: count)
            
            var cursor:Vector2<Int>             = .zero, 
                result:[Line.ShapingElement]    = []
                result.reserveCapacity(count)
            
            for (info, delta):(hb_glyph_info_t, hb_glyph_position_t) in zip(infos, deltas) 
            {
                let o64:Vector2<Int> = .cast(.init(delta.x_offset,  delta.y_offset)), 
                    a64:Vector2<Int> = .cast(.init(delta.x_advance, delta.y_advance)), 
                    p64:Vector2<Int> = cursor &+ o64
                
                cursor &+= a64
                let glyph:Glyph = .init(position: p64 &>> 6, cluster: .init(info.cluster), index: .init(info.codepoint))
                let element:Line.ShapingElement = .init(glyph: glyph, 
                                                    breakable: info.mask & HB_GLYPH_FLAG_UNSAFE_TO_BREAK.rawValue == 0)
                result.append(element)
            }
            
            return .init(result)
        }
        
        fileprivate 
        func subshape(_ text:ArraySlice<Character>, features:[hb_feature_t], from cached:Line) -> Line
        {
            let a:Int = cached.bisect{ $0.cluster >= text.startIndex }, 
                b:Int = cached.bisect{ $0.cluster >= text.endIndex }
            
            guard   a == cached.endIndex || cached.breakable(at: a) && cached[a].cluster == text.startIndex, 
                    b == cached.endIndex || cached.breakable(at: b) && cached[b].cluster == text.endIndex 
            else 
            {
                // we have to reshape 
                return self.shape(text, features: features)
            }
            
            return cached.slice(a ..< b)
        }
    }
    
    fileprivate 
    struct Line:RandomAccessCollection 
    {
        struct ShapingElement 
        {
            let glyph:Glyph, 
                breakable:Bool 
        }
        
        private 
        let shapingBuffer:[ShapingElement]
        
        let startIndex:Int, 
            endIndex:Int
        
        private 
        init(_ buffer:[ShapingElement], range:Range<Int>) 
        {
            self.shapingBuffer  = buffer 
            self.startIndex     = range.lowerBound
            self.endIndex       = range.upperBound
        }
        
        init(_ buffer:[ShapingElement]) 
        {
            self.init(buffer, range: buffer.indices)
        }
        
        private 
        var origin:Vector2<Int> 
        {
            return self.shapingBuffer[self.startIndex].glyph.position 
        }
        
        subscript(_ index:Int) -> Glyph 
        {
            precondition(self.startIndex ..< self.endIndex ~= index, "index out of range")
            return self.shapingBuffer[index].glyph.relative(to: self.origin)
        }
        
        func breakable(at index:Int) -> Bool 
        {
            precondition(self.startIndex ..< self.endIndex ~= index, "index out of range")
            return self.shapingBuffer[index].breakable
        }
        
        func cluster(after index:Int) -> Int? 
        {
            let key:Int = self.shapingBuffer[index].glyph.cluster 
            for element:ShapingElement in self.shapingBuffer[index ..< self.endIndex] 
                where element.glyph.cluster != key 
            {
                return element.glyph.cluster 
            }
            
            return nil
        }
        
        func slice(_ range:Range<Int>) -> Line 
        {
            return .init(self.shapingBuffer, range: range)
        }
        
        func offset(x:Int) -> [Glyph]
        {
            guard !self.isEmpty 
            else 
            {
                return []
            }
            
            let reference:Vector2<Int> = self.origin &- .init(x, 0)
            return self.shapingBuffer[self.startIndex ..< self.endIndex].map 
            {
                $0.glyph.relative(to: reference)
            }
        }
    }
    
    static 
    func paragraph<Runs>(_ runs:Runs, indent:Int, width:Int) 
        -> ([HarfBuzz.Glyph], (runs:[Range<Int>], lines:[Range<Int>]))
        where Runs:Sequence, Runs.Element == (String, ShapingParameters)
    {
        var glyphs:[HarfBuzz.Glyph]                         =  [], 
            indices:(runs:[Range<Int>], lines:[Range<Int>]) = ([], [])
        
        var x:Int  = indent, 
            ir:Int = glyphs.count, 
            il:Int = glyphs.count
        for (text, parameters):(String, ShapingParameters) in runs 
        {
            let font:Typeface.Font = parameters.font
            func extent(of line:HarfBuzz.Line) -> Int 
            {
                return line.last.map{ $0.position.x + font.sorts[$0.index].footprint } ?? 0
            }
            
            let features:[hb_feature_t] = parameters.features.map
            { 
                (slug, value) in 
                .init(tag: slug, value: value, start: 0, end: .max) 
            } 
            let characters:[Character]  = .init(text)
            
            var newline:Bool = false 
            for superline:ArraySlice<Character> in 
                characters.split(separator: "\n", omittingEmptySubsequences: false)
            {
                var unshaped:ArraySlice<Character>  = superline, 
                    shaped:HarfBuzz.Line            = font.hbfont.shape(unshaped, features: features)
                
                if newline
                {
                    x = 0
                    indices.lines.append(il ..< glyphs.count)
                    il = glyphs.count 
                }
                else 
                {
                    newline = true 
                }
                
                flow: 
                while true 
                {
                    // find violating glyph 
                    guard let overrun:Int = 
                    (
                        shaped.firstIndex 
                        {
                            x + $0.position.x + font.sorts[$0.index].footprint > width 
                        }
                    )
                    else 
                    {
                        glyphs.append(contentsOf: shaped.offset(x: x))
                        x += extent(of: shaped)
                        break flow 
                    }
                    
                    // need to explicitly find nextCluster, because cluster 
                    // values may jump by more than 1 
                    let nextCluster:Int = shaped.cluster(after: overrun) ?? unshaped.endIndex
                    
                    // consider each possible breakpoint before `nextCluster`
                    for b:Int in (unshaped.startIndex ..< nextCluster).reversed() where unshaped[b] == " "
                    {
                        let candidate:HarfBuzz.Line = 
                            font.hbfont.subshape(unshaped[..<b], features: features, from: shaped)
                        // check if the candidate fits 
                        let dx:Int = extent(of: candidate)
                        guard x + dx <= width 
                        else 
                        {
                            continue 
                        }
                        
                        glyphs.append(contentsOf: candidate.offset(x: x))
                        x += dx
                        
                        unshaped = unshaped[(b + 1)...].drop{ $0 == " " } 
                        if unshaped.isEmpty 
                        {
                            break flow 
                        }
                        else 
                        {
                            shaped = font.hbfont.subshape(unshaped, features: features, from: shaped)
                            continue flow 
                        }
                    }
                    
                    // if break failure occured, and we weren’t using the entire 
                    // available line length (because we didn’t start from the 
                    // beginning), move down to the next whole empty line 
                    guard x == 0
                    else 
                    {
                        x = 0
                        indices.lines.append(il ..< glyphs.count)
                        il = glyphs.count 
                        continue flow 
                    }
                    
                    // break failure 
                    for c:Int in (unshaped.startIndex ..< nextCluster).reversed().dropLast()
                    {
                        let candidate:HarfBuzz.Line = 
                            font.hbfont.subshape(unshaped[..<c], features: features, from: shaped)
                        let dx:Int = extent(of: candidate)
                        guard x + dx <= width 
                        else 
                        {
                            continue 
                        }
                        
                        glyphs.append(contentsOf: candidate.offset(x: x))
                        x += dx 
                        
                        unshaped = unshaped[c...]
                        if unshaped.isEmpty 
                        {
                            break flow 
                        }
                        else 
                        {
                            shaped = font.hbfont.subshape(unshaped, features: features, from: shaped)
                            continue flow 
                        }
                    }
                    
                    // last resort, just place one character on the line 
                    let single:HarfBuzz.Line = 
                        font.hbfont.subshape(unshaped.prefix(1), features: features, from: shaped)
                    glyphs.append(contentsOf: single.offset(x: x))
                    x += extent(of: single)
                    
                    unshaped = unshaped.dropFirst()
                    if unshaped.isEmpty 
                    {
                        break flow 
                    }
                    else 
                    {
                        shaped = font.hbfont.subshape(unshaped, features: features, from: shaped)
                    }
                }
            }
            
            indices.runs.append(ir ..< glyphs.count)
            ir = glyphs.count 
        }
        
        indices.lines.append(il ..< glyphs.count)
        
        return (glyphs, indices)
    }
    
    static 
    func line<Runs>(_ runs:Runs) 
        -> ([HarfBuzz.Glyph], [Range<Int>], Int)
        where Runs:Sequence, Runs.Element == (String, ShapingParameters)
    {
        var glyphs:[HarfBuzz.Glyph] = [], 
            runs:[Range<Int>]       = []
        
        var x:Int  = 0, 
            ir:Int = glyphs.count 
        for (text, parameters):(String, ShapingParameters) in runs 
        {
            let font:Typeface.Font = parameters.font 
            func extent(of line:HarfBuzz.Line) -> Int 
            {
                return line.last.map{ $0.position.x + font.sorts[$0.index].footprint } ?? 0
            }
            
            let features:[hb_feature_t] = parameters.features.map
            { 
                (slug, value) in 
                .init(tag: slug, value: value, start: 0, end: .max) 
            } 
            let characters:[Character]  = .init(text)
            
            let shaped:HarfBuzz.Line = font.hbfont.shape(characters[...], features: features)
            glyphs.append(contentsOf: shaped.offset(x: x))
            x += extent(of: shaped)
            
            runs.append(ir ..< glyphs.count)
            ir = glyphs.count 
        }
        
        return (glyphs, runs, x)
    }
    
    // assemble stops (for cursor positions, etc)
    // stops map clusters (character indices) to grid layout positions 
    static 
    func stops(_ run:(String, ShapingParameters), glyphs:ArraySlice<HarfBuzz.Glyph>, lines:[Range<Int>]) 
        -> [(x:SIMD2<Int>, l:Int)] 
    {
        let (string, parameters) = run 
        
        var stops:[(x:SIMD2<Int>, l:Int)] = []
        
        // find l 
        var l:Int = lines.startIndex
        for (i, glyph):(Int, HarfBuzz.Glyph) in zip(glyphs.indices, glyphs) 
        {
            while !(lines[l] ~= i) 
            {
                l += 1
            }
            
            // next cluster 
            let next:Int 
            if i + 1 < glyphs.endIndex 
            {
                next = glyphs[i + 1].cluster 
            }
            else 
            {
                next = string.count 
            }
            
            let left:Int  = glyph.position.x, 
                width:Int = parameters.font.sorts[glyph.index].footprint, 
                count:Int = next - glyph.cluster
            for c:Int in glyph.cluster ..< next 
            {
                let d:SIMD2<Int> = .init(c - glyph.cluster, c - glyph.cluster + 1)
                stops.append((x: left &+ width &* d / count, l: l))
            }
        }
        
        return stops
    }
}
