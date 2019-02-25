import HarfBuzz
import FreeType

extension Style.Definitions.Feature 
{
    fileprivate 
    var feature:hb_feature_t 
    {
        let tag:Math<UInt8>.V4 = self.tag, 
            slug:UInt32 = .init(tag.0) << 24 | .init(tag.1) << 16 | .init(tag.2) << 8 | .init(tag.3)
        return .init(tag: slug, value: .init(self.value), start: 0, end: .max)
    }
    
    private 
    var value:Int 
    {
        switch self 
        {
        case    .kern(let on), 
                .calt(let on), 
                .liga(let on), 
                .hlig(let on), 
                .`case`(let on), 
                .cpsp(let on), 
                .smcp(let on), 
                .pcap(let on), 
                .c2sc(let on), 
                .c2pc(let on), 
                .unic(let on), 
                .ordn(let on), 
                .zero(let on), 
                .frac(let on), 
                .afrc(let on), 
                .sinf(let on), 
                .subs(let on), 
                .sups(let on), 
                .ital(let on), 
                .mgrk(let on), 
                .lnum(let on), 
                .onum(let on), 
                .pnum(let on), 
                .tnum(let on), 
                .rand(let on), 
                .titl(let on):
            return on ? 1 : 0
        
        case    .salt(let value), 
                .swsh(let value):
            return value
        }
    }
    
    private 
    var tag:Math<UInt8>.V4 
    {
        switch self 
        {
        case .kern:
            return 
                (
                    .init(("k" as Unicode.Scalar).value), 
                    .init(("e" as Unicode.Scalar).value), 
                    .init(("r" as Unicode.Scalar).value), 
                    .init(("n" as Unicode.Scalar).value)
                )
        case .calt:
            return 
                (
                    .init(("c" as Unicode.Scalar).value), 
                    .init(("a" as Unicode.Scalar).value), 
                    .init(("l" as Unicode.Scalar).value), 
                    .init(("t" as Unicode.Scalar).value)
                )
        case .liga:
            return 
                (
                    .init(("l" as Unicode.Scalar).value), 
                    .init(("i" as Unicode.Scalar).value), 
                    .init(("g" as Unicode.Scalar).value), 
                    .init(("a" as Unicode.Scalar).value)
                )
        case .hlig:
            return 
                (
                    .init(("h" as Unicode.Scalar).value), 
                    .init(("l" as Unicode.Scalar).value), 
                    .init(("i" as Unicode.Scalar).value), 
                    .init(("g" as Unicode.Scalar).value)
                )
        case .`case`:
            return 
                (
                    .init(("c" as Unicode.Scalar).value), 
                    .init(("a" as Unicode.Scalar).value), 
                    .init(("s" as Unicode.Scalar).value), 
                    .init(("e" as Unicode.Scalar).value)
                )
        case .cpsp:
            return 
                (
                    .init(("c" as Unicode.Scalar).value), 
                    .init(("p" as Unicode.Scalar).value), 
                    .init(("s" as Unicode.Scalar).value), 
                    .init(("p" as Unicode.Scalar).value)
                )
        case .smcp:
            return 
                (
                    .init(("s" as Unicode.Scalar).value), 
                    .init(("m" as Unicode.Scalar).value), 
                    .init(("c" as Unicode.Scalar).value), 
                    .init(("p" as Unicode.Scalar).value)
                )
        case .pcap:
            return 
                (
                    .init(("p" as Unicode.Scalar).value), 
                    .init(("c" as Unicode.Scalar).value), 
                    .init(("a" as Unicode.Scalar).value), 
                    .init(("p" as Unicode.Scalar).value)
                )
        case .c2sc:
            return 
                (
                    .init(("c" as Unicode.Scalar).value), 
                    .init(("2" as Unicode.Scalar).value), 
                    .init(("s" as Unicode.Scalar).value), 
                    .init(("c" as Unicode.Scalar).value)
                )
        case .c2pc:
            return 
                (
                    .init(("c" as Unicode.Scalar).value), 
                    .init(("2" as Unicode.Scalar).value), 
                    .init(("p" as Unicode.Scalar).value), 
                    .init(("c" as Unicode.Scalar).value)
                )
        case .unic:
            return 
                (
                    .init(("u" as Unicode.Scalar).value), 
                    .init(("n" as Unicode.Scalar).value), 
                    .init(("i" as Unicode.Scalar).value), 
                    .init(("c" as Unicode.Scalar).value)
                )
        case .ordn:
            return 
                (
                    .init(("o" as Unicode.Scalar).value), 
                    .init(("r" as Unicode.Scalar).value), 
                    .init(("d" as Unicode.Scalar).value), 
                    .init(("n" as Unicode.Scalar).value)
                )
        case .zero:
            return 
                (
                    .init(("z" as Unicode.Scalar).value), 
                    .init(("e" as Unicode.Scalar).value), 
                    .init(("r" as Unicode.Scalar).value), 
                    .init(("o" as Unicode.Scalar).value)
                )
        case .frac:
            return 
                (
                    .init(("f" as Unicode.Scalar).value), 
                    .init(("r" as Unicode.Scalar).value), 
                    .init(("a" as Unicode.Scalar).value), 
                    .init(("c" as Unicode.Scalar).value)
                )
        case .afrc:
            return 
                (
                    .init(("a" as Unicode.Scalar).value), 
                    .init(("f" as Unicode.Scalar).value), 
                    .init(("r" as Unicode.Scalar).value), 
                    .init(("c" as Unicode.Scalar).value)
                )
        case .sinf:
            return 
                (
                    .init(("s" as Unicode.Scalar).value), 
                    .init(("i" as Unicode.Scalar).value), 
                    .init(("n" as Unicode.Scalar).value), 
                    .init(("f" as Unicode.Scalar).value)
                )
        case .subs:
            return 
                (
                    .init(("s" as Unicode.Scalar).value), 
                    .init(("u" as Unicode.Scalar).value), 
                    .init(("b" as Unicode.Scalar).value), 
                    .init(("s" as Unicode.Scalar).value)
                )
        case .sups:
            return 
                (
                    .init(("s" as Unicode.Scalar).value), 
                    .init(("u" as Unicode.Scalar).value), 
                    .init(("p" as Unicode.Scalar).value), 
                    .init(("s" as Unicode.Scalar).value)
                )
        case .ital:
            return 
                (
                    .init(("i" as Unicode.Scalar).value), 
                    .init(("t" as Unicode.Scalar).value), 
                    .init(("a" as Unicode.Scalar).value), 
                    .init(("l" as Unicode.Scalar).value)
                )
        case .mgrk:
            return 
                (
                    .init(("m" as Unicode.Scalar).value), 
                    .init(("g" as Unicode.Scalar).value), 
                    .init(("r" as Unicode.Scalar).value), 
                    .init(("k" as Unicode.Scalar).value)
                )
        case .lnum:
            return 
                (
                    .init(("l" as Unicode.Scalar).value), 
                    .init(("n" as Unicode.Scalar).value), 
                    .init(("u" as Unicode.Scalar).value), 
                    .init(("m" as Unicode.Scalar).value)
                )
        case .onum:
            return 
                (
                    .init(("o" as Unicode.Scalar).value), 
                    .init(("n" as Unicode.Scalar).value), 
                    .init(("u" as Unicode.Scalar).value), 
                    .init(("m" as Unicode.Scalar).value)
                )
        case .pnum:
            return 
                (
                    .init(("p" as Unicode.Scalar).value), 
                    .init(("n" as Unicode.Scalar).value), 
                    .init(("u" as Unicode.Scalar).value), 
                    .init(("m" as Unicode.Scalar).value)
                )
        case .tnum:
            return 
                (
                    .init(("t" as Unicode.Scalar).value), 
                    .init(("n" as Unicode.Scalar).value), 
                    .init(("u" as Unicode.Scalar).value), 
                    .init(("m" as Unicode.Scalar).value)
                )
        case .rand:
            return 
                (
                    .init(("r" as Unicode.Scalar).value), 
                    .init(("a" as Unicode.Scalar).value), 
                    .init(("n" as Unicode.Scalar).value), 
                    .init(("d" as Unicode.Scalar).value)
                )
        case .salt:
            return 
                (
                    .init(("s" as Unicode.Scalar).value), 
                    .init(("a" as Unicode.Scalar).value), 
                    .init(("l" as Unicode.Scalar).value), 
                    .init(("t" as Unicode.Scalar).value)
                )
        case .swsh:
            return 
                (
                    .init(("s" as Unicode.Scalar).value), 
                    .init(("w" as Unicode.Scalar).value), 
                    .init(("s" as Unicode.Scalar).value), 
                    .init(("h" as Unicode.Scalar).value)
                )
        case .titl:
            return 
                (
                    .init(("t" as Unicode.Scalar).value), 
                    .init(("i" as Unicode.Scalar).value), 
                    .init(("t" as Unicode.Scalar).value), 
                    .init(("l" as Unicode.Scalar).value)
                )
        }
    }
}

enum HarfBuzz 
{
    struct Glyph 
    {
        let position:Math<Int>.V2, 
            index:Int
    }
    
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
        
        private 
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
            
            var cursor:Math<Int>.V2             = (0, 0), 
                result:[Line.ShapingElement]    = []
                result.reserveCapacity(count)
            
            for (info, delta):(hb_glyph_info_t, hb_glyph_position_t) in zip(infos, deltas) 
            {
                let o64:Math<Int>.V2 = Math.cast((delta.x_offset,  delta.y_offset),  as: Int.self), 
                    a64:Math<Int>.V2 = Math.cast((delta.x_advance, delta.y_advance), as: Int.self), 
                    p64:Math<Int>.V2 = Math.add(cursor, o64) 
                
                cursor = Math.add(cursor, a64)
                let element:Line.ShapingElement  = .init(position: (   p64.x >> 6,    p64.y >> 6), 
                                                cumulativeAdvance: (cursor.x >> 6, cursor.y >> 6), 
                                                          cluster: .init(info.cluster), 
                                                       glyphIndex: .init(info.codepoint), 
                                                        breakable: info.mask & HB_GLYPH_FLAG_UNSAFE_TO_BREAK.rawValue == 0)
                result.append(element)
            }
            
            return .init(result)
        }
        
        private 
        func subshape(_ text:ArraySlice<Character>, features:[hb_feature_t], from cached:Line) -> Line
        {
            let a:Int = cached.bisect{ $0.cluster >= text.startIndex }, 
                b:Int = cached.bisect{ $0.cluster >= text.endIndex }
            
            guard   a == cached.endIndex || cached[a].breakable && cached[a].cluster == text.startIndex, 
                    b == cached.endIndex || cached[b].breakable && cached[b].cluster == text.endIndex 
            else 
            {
                // we have to reshape 
                return self.shape(text, features: features)
            }
            
            return cached.slice(a ..< b)
        }
        
        private 
        struct Line:RandomAccessCollection 
        {
            struct ShapingElement 
            {
                let position:Math<Int>.V2, 
                    cumulativeAdvance:Math<Int>.V2, 
                    cluster:Int, 
                    glyphIndex:Int, 
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
            
            var origin:Math<Int>.V2 
            {
                if self.startIndex > self.shapingBuffer.startIndex
                {
                    // need to use direct subscript since `a - 1` is out of range 
                    return self.shapingBuffer[self.startIndex - 1].cumulativeAdvance
                }
                else 
                {
                    return (0, 0)
                }
            }
            
            subscript(_ index:Int) -> ShapingElement 
            {
                precondition(self.startIndex ..< self.endIndex ~= index, "index out of range")
                return self.shapingBuffer[index]
            }
            
            subscript(advance index:Int) -> Math<Int>.V2 
            {
                return Math.sub(self[index].cumulativeAdvance, self.origin)
            }
            
            var footprint:Math<Int>.V2 
            {
                if let last:ShapingElement = self.last 
                {
                    return Math.sub(last.cumulativeAdvance, self.origin)
                }
                else 
                {
                    return (0, 0)
                }
            }
            
            func cluster(after index:Int) -> Int? 
            {
                let key:Int = self[index].cluster 
                for element:ShapingElement in self.dropFirst(index) 
                    where element.cluster != key 
                {
                    return element.cluster 
                }
                
                return nil
            }
            
            func slice(_ range:Range<Int>) -> Line 
            {
                return .init(self.shapingBuffer, range: range)
            }
            
            func glyphs() -> [Glyph] 
            {
                return self.map 
                {
                    .init(position: Math.sub($0.position, self.origin), index: $0.glyphIndex)
                }
            }
        }
        
        func line(_ text:String, features:[Style.Definitions.Feature], indent:inout Int) -> [Glyph] 
        {
            let features:[hb_feature_t] = features.map{ $0.feature }
            let characters:[Character]  = .init(text) 
            
            let shaped:Line = self.shape(characters[...], features: features)
            indent += shaped.footprint.x 
            return shaped.glyphs()
        }
         
        func paragraph(_ text:String, features:[Style.Definitions.Feature], indent:inout Int?, width:Int) -> [[Glyph]] 
        {
            let features:[hb_feature_t] = features.map{ $0.feature }
            let characters:[Character]  = .init(text) 
            
            var lines:[[Glyph]] = [], 
                first:Bool      = true 
            for superline:ArraySlice<Character> in characters.split(separator: "\n", omittingEmptySubsequences: false)
            {
                if !first 
                {
                    indent = nil 
                    first  = false 
                }
                
                var unshaped:ArraySlice<Character>  = superline, 
                    shaped:Line                     = self.shape(unshaped, features: features)
                
                flow: 
                while true 
                {
                    let start = indent ?? 0 
                    
                    // find violating glyph and its associated cluster 
                    guard let overrun:Int = 
                    (
                        shaped.indices.first 
                        {
                            start + shaped[advance: $0].x > width
                        }
                    ) 
                    else 
                    {
                        lines.append(shaped.glyphs())
                        indent = start + shaped.footprint.x
                        break flow 
                    }
                    
                    defer 
                    {
                        indent = nil 
                    }
                    
                    // need to explicitly find nextCluster, because cluster 
                    // values may jump by more than 1 
                    let nextCluster:Int = shaped.cluster(after: overrun) ?? unshaped.endIndex
                    
                    // consider each possible breakpoint before `nextCluster`
                    for b:Int in (unshaped.startIndex ..< nextCluster).reversed() where unshaped[b] == " "
                    {
                        let candidate:Line = self.subshape(unshaped[..<b], features: features, from: shaped)
                        // check if the candidate fits 
                        guard start + candidate.footprint.x <= width 
                        else 
                        {
                            continue 
                        }
                        
                        lines.append(candidate.glyphs())
                        unshaped    = unshaped[(b + 1)...].drop{ $0 == " " } 
                        if unshaped.isEmpty 
                        {
                            break flow 
                        }
                        else 
                        {
                            shaped  = self.subshape(unshaped, features: features, from: shaped)
                            continue flow 
                        }
                    }
                    
                    if start > 0 
                    {
                        lines.append([])
                        continue flow 
                    }
                    
                    // break failure 
                    for c:Int in (unshaped.startIndex ..< nextCluster).reversed().dropLast()
                    {
                        let candidate:Line = self.subshape(unshaped[..<c], features: features, from: shaped)
                        
                        guard start + candidate.footprint.x <= width 
                        else 
                        {
                            continue 
                        }
                        
                        lines.append(candidate.glyphs())
                        unshaped    = unshaped[c...]
                        if unshaped.isEmpty 
                        {
                            break flow 
                        }
                        else 
                        {
                            shaped  = self.subshape(unshaped, features: features, from: shaped)
                            continue flow 
                        }
                    }
                    
                    // last resort, just place one character on the line 
                    let single:Line = self.subshape(unshaped.prefix(1), features: features, from: shaped)
                    lines.append(single.glyphs())
                    unshaped        = unshaped.dropFirst(1)
                    if unshaped.isEmpty 
                    {
                        break flow 
                    }
                    else 
                    {
                        shaped  = self.subshape(unshaped, features: features, from: shaped)
                    }
                }
            }
            
            return lines
        }
    }
}
