import HarfBuzz
import FreeType

extension Style.Definitions.Feature 
{
    fileprivate 
    var feature:hb_feature_t 
    {
        let slug:UInt32   = .init(self.tag.0) << 24 | 
                            .init(self.tag.1) << 16 | 
                            .init(self.tag.2) << 8  | 
                            .init(self.tag.3)
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
    var tag:(UInt8, UInt8, UInt8, UInt8)
    {
        switch self 
        {
        case .kern:
            return 
                (
                    .init(ascii: "k"), 
                    .init(ascii: "e"), 
                    .init(ascii: "r"), 
                    .init(ascii: "n")
                )
        case .calt:
            return 
                (
                    .init(ascii: "c"), 
                    .init(ascii: "a"), 
                    .init(ascii: "l"), 
                    .init(ascii: "t")
                )
        case .liga:
            return 
                (
                    .init(ascii: "l"), 
                    .init(ascii: "i"), 
                    .init(ascii: "g"), 
                    .init(ascii: "a")
                )
        case .hlig:
            return 
                (
                    .init(ascii: "h"), 
                    .init(ascii: "l"), 
                    .init(ascii: "i"), 
                    .init(ascii: "g")
                )
        case .`case`:
            return 
                (
                    .init(ascii: "c"), 
                    .init(ascii: "a"), 
                    .init(ascii: "s"), 
                    .init(ascii: "e")
                )
        case .cpsp:
            return 
                (
                    .init(ascii: "c"), 
                    .init(ascii: "p"), 
                    .init(ascii: "s"), 
                    .init(ascii: "p")
                )
        case .smcp:
            return 
                (
                    .init(ascii: "s"), 
                    .init(ascii: "m"), 
                    .init(ascii: "c"), 
                    .init(ascii: "p")
                )
        case .pcap:
            return 
                (
                    .init(ascii: "p"), 
                    .init(ascii: "c"), 
                    .init(ascii: "a"), 
                    .init(ascii: "p")
                )
        case .c2sc:
            return 
                (
                    .init(ascii: "c"), 
                    .init(ascii: "2"), 
                    .init(ascii: "s"), 
                    .init(ascii: "c")
                )
        case .c2pc:
            return 
                (
                    .init(ascii: "c"), 
                    .init(ascii: "2"), 
                    .init(ascii: "p"), 
                    .init(ascii: "c")
                )
        case .unic:
            return 
                (
                    .init(ascii: "u"), 
                    .init(ascii: "n"), 
                    .init(ascii: "i"), 
                    .init(ascii: "c")
                )
        case .ordn:
            return 
                (
                    .init(ascii: "o"), 
                    .init(ascii: "r"), 
                    .init(ascii: "d"), 
                    .init(ascii: "n")
                )
        case .zero:
            return 
                (
                    .init(ascii: "z"), 
                    .init(ascii: "e"), 
                    .init(ascii: "r"), 
                    .init(ascii: "o")
                )
        case .frac:
            return 
                (
                    .init(ascii: "f"), 
                    .init(ascii: "r"), 
                    .init(ascii: "a"), 
                    .init(ascii: "c")
                )
        case .afrc:
            return 
                (
                    .init(ascii: "a"), 
                    .init(ascii: "f"), 
                    .init(ascii: "r"), 
                    .init(ascii: "c")
                )
        case .sinf:
            return 
                (
                    .init(ascii: "s"), 
                    .init(ascii: "i"), 
                    .init(ascii: "n"), 
                    .init(ascii: "f")
                )
        case .subs:
            return 
                (
                    .init(ascii: "s"), 
                    .init(ascii: "u"), 
                    .init(ascii: "b"), 
                    .init(ascii: "s")
                )
        case .sups:
            return 
                (
                    .init(ascii: "s"), 
                    .init(ascii: "u"), 
                    .init(ascii: "p"), 
                    .init(ascii: "s")
                )
        case .ital:
            return 
                (
                    .init(ascii: "i"), 
                    .init(ascii: "t"), 
                    .init(ascii: "a"), 
                    .init(ascii: "l")
                )
        case .mgrk:
            return 
                (
                    .init(ascii: "m"), 
                    .init(ascii: "g"), 
                    .init(ascii: "r"), 
                    .init(ascii: "k")
                )
        case .lnum:
            return 
                (
                    .init(ascii: "l"), 
                    .init(ascii: "n"), 
                    .init(ascii: "u"), 
                    .init(ascii: "m")
                )
        case .onum:
            return 
                (
                    .init(ascii: "o"), 
                    .init(ascii: "n"), 
                    .init(ascii: "u"), 
                    .init(ascii: "m")
                )
        case .pnum:
            return 
                (
                    .init(ascii: "p"), 
                    .init(ascii: "n"), 
                    .init(ascii: "u"), 
                    .init(ascii: "m")
                )
        case .tnum:
            return 
                (
                    .init(ascii: "t"), 
                    .init(ascii: "n"), 
                    .init(ascii: "u"), 
                    .init(ascii: "m")
                )
        case .rand:
            return 
                (
                    .init(ascii: "r"), 
                    .init(ascii: "a"), 
                    .init(ascii: "n"), 
                    .init(ascii: "d")
                )
        case .salt:
            return 
                (
                    .init(ascii: "s"), 
                    .init(ascii: "a"), 
                    .init(ascii: "l"), 
                    .init(ascii: "t")
                )
        case .swsh:
            return 
                (
                    .init(ascii: "s"), 
                    .init(ascii: "w"), 
                    .init(ascii: "s"), 
                    .init(ascii: "h")
                )
        case .titl:
            return 
                (
                    .init(ascii: "t"), 
                    .init(ascii: "i"), 
                    .init(ascii: "t"), 
                    .init(ascii: "l")
                )
        }
    }
}

enum HarfBuzz 
{
    struct Glyph 
    {
        let position:Vector2<Int>, 
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
            
            var cursor:Vector2<Int>             = .zero, 
                result:[Line.ShapingElement]    = []
                result.reserveCapacity(count)
            
            for (info, delta):(hb_glyph_info_t, hb_glyph_position_t) in zip(infos, deltas) 
            {
                let o64:Vector2<Int> = .cast(.init(delta.x_offset,  delta.y_offset)), 
                    a64:Vector2<Int> = .cast(.init(delta.x_advance, delta.y_advance)), 
                    p64:Vector2<Int> = cursor &+ o64
                
                cursor &+= a64
                let element:Line.ShapingElement  = .init(position: p64    &>> 6, 
                                                cumulativeAdvance: cursor &>> 6, 
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
                let position:Vector2<Int>, 
                    cumulativeAdvance:Vector2<Int>, 
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
            
            var origin:Vector2<Int> 
            {
                if self.startIndex > self.shapingBuffer.startIndex
                {
                    // need to use direct subscript since `a - 1` is out of range 
                    return self.shapingBuffer[self.startIndex - 1].cumulativeAdvance
                }
                else 
                {
                    return .zero
                }
            }
            
            subscript(_ index:Int) -> ShapingElement 
            {
                precondition(self.startIndex ..< self.endIndex ~= index, "index out of range")
                return self.shapingBuffer[index]
            }
            
            subscript(advance index:Int) -> Vector2<Int> 
            {
                return self[index].cumulativeAdvance &- self.origin
            }
            
            var footprint:Vector2<Int> 
            {
                if let last:ShapingElement = self.last 
                {
                    return last.cumulativeAdvance &- self.origin
                }
                else 
                {
                    return .zero
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
                    .init(position: $0.position &- self.origin, index: $0.glyphIndex)
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
