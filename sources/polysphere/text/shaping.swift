import HarfBuzz
import FreeType

enum FontStyle 
{
    case mono55i
    case mono56i
    case mono75i
    case mono76i
    
    case text55i
    case text56i
    case text75i
    case text76i
    
    
    case mono55ii
    case mono56ii
    case mono75ii
    case mono76ii
    
    case text45ii
    case text46ii
    case text55ii
    case text56ii
    case text75ii
    case text76ii
    
    
    case mono55iii
    case mono56iii
    case mono75iii
    case mono76iii
    
    case text35iii
    case text36iii
    case text45iii
    case text46iii
    case text55iii
    case text56iii
    case text75iii
    case text76iii
    
    case display35iii
    case display36iii
    case display45iii
    case display46iii
    case display55iii
    case display56iii
    case display75iii
    case display76iii
}

enum FontSize 
{
    case i, ii, iii, iv, v
}

enum HarfBuzz 
{
    struct Face 
    {
        let object:OpaquePointer 
        
        // don’t make this optional since we want to eventually extend memory safety 
        // checks to the freetype wrappers too
        static 
        func create(fromFreetype ftface:FT_Face) -> Face
        {
            let face:OpaquePointer = hb_ft_face_create_referenced(ftface) 
            return .init(object: face)
        }
        
        func destroy() 
        {
            hb_face_destroy(self.object)
        }
        
        func font(size:Int) -> Font 
        {
            let font:OpaquePointer = hb_font_create(self.object) 
            let fixedSize:Int32 = .init(size << 6)
            hb_ft_font_set_funcs(font)
            hb_font_set_scale(font, fixedSize, fixedSize)
            return .init(object: font)
        }
    }
    
    struct Font 
    {
        fileprivate 
        let object:OpaquePointer 
        
        func destroy() 
        {
            hb_font_destroy(self.object)
        }
        
        // last element in output array is end-cap, useful for right-align
        func shape(_ text:String) -> [(Int, Math<Int>.V2)]
        {
            let buffer:OpaquePointer = hb_buffer_create() 
            
            hb_buffer_add_utf8(buffer, text, .init(text.utf8.count), 0, .init(text.utf8.count))
            
            hb_buffer_set_direction(buffer, HB_DIRECTION_LTR)
            hb_buffer_set_script(buffer, HB_SCRIPT_LATIN)
            hb_buffer_set_language(buffer, hb_language_from_string("en-US", -1))
            
            hb_shape(self.object, buffer, nil, 0)
            
            let count:Int = .init(hb_buffer_get_length(buffer))
            let infos:UnsafeBufferPointer<hb_glyph_info_t> = 
                .init(start: hb_buffer_get_glyph_infos(buffer, nil), count: count) 
            let positions:UnsafeBufferPointer<hb_glyph_position_t> = 
                .init(start: hb_buffer_get_glyph_positions(buffer, nil), count: count)
            var shaped:[(Int, Math<Int>.V2)] = [], 
                cursor:Math<Int>.V2 = (0, 0)
            for (info, delta):(hb_glyph_info_t, hb_glyph_position_t) in zip(infos, positions) 
            {
                let offset:Math<Int>.V2     = Math.cast((delta.x_offset, delta.y_offset), as: Int.self)
                let position:Math<Int>.V2   = Math.add(cursor, offset)
                
                shaped.append((.init(info.codepoint), (position.x >> 6, position.y >> 6)))
                
                cursor = Math.add(cursor, Math.cast((delta.x_advance, delta.y_advance), as: Int.self))
            }
            
            shaped.append((-1, (cursor.x >> 6, cursor.y >> 6)))
            return shaped
        }
        
        private 
        struct ShapingElement 
        {
            let position:Math<Int>.V2, 
                cumulativeAdvance:Math<Int>.V2, 
                cluster:Int, 
                glyph:Int, 
                breakable:Bool 
        }
        
        private 
        func shape(_ text:ArraySlice<Character>, origin:Math<Int>.V2) -> [ShapingElement] 
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
            
            hb_buffer_set_direction(buffer, HB_DIRECTION_LTR)
            hb_buffer_set_script(buffer, HB_SCRIPT_LATIN)
            hb_buffer_set_language(buffer, hb_language_from_string("en-US", -1))
            
            hb_shape(self.object, buffer, nil, 0)
            
            let count:Int = .init(hb_buffer_get_length(buffer))
            let infos:UnsafeBufferPointer<hb_glyph_info_t> = 
                .init(start: hb_buffer_get_glyph_infos(buffer, nil), count: count) 
            let deltas:UnsafeBufferPointer<hb_glyph_position_t> = 
                .init(start: hb_buffer_get_glyph_positions(buffer, nil), count: count)
            
            var cursor:Math<Int>.V2     = origin, 
                result:[ShapingElement] = []
                result.reserveCapacity(count)
            
            for (info, delta):(hb_glyph_info_t, hb_glyph_position_t) in zip(infos, deltas).map 
            {
                let offset:Math<Int>.V2     = Math.cast((delta.x_offset,  delta.y_offset),  as: Int.self), 
                    advance:Math<Int>.V2    = Math.cast((delta.x_advance, delta.y_advance), as: Int.self), 
                    position:Math<Int>.V2   = Math.add(cursor, offset) 
                
                cursor = Math.add(cursor, advance)
                let element:ShapingElement   = .init(position: position, 
                                            cumulativeAdvance: cursor, 
                                                      cluster: .init(e.info.cluster), 
                                                        glyph: .init(e.info.codepoint), 
                                                    breakable: e.info.flags & UNSAFE_TO_BREAK == 0)
                result.append(element)
            }
            
            return result
        }
        
        private static 
        func nextCluster(_ shaping:ArraySlice<ShapingElement>) -> Int? 
        {
            let key:Int = shaping[shaping.startIndex].cluster 
            for element:ShapingElement in shaping 
            {
                if element.cluster != key 
                {
                    return element.cluster 
                }
            }
            
            return nil
        }
        
        // `hint` is to maintain linear-ish complexity
        private 
        func select(prefix:ArraySlice<Character>, from shaping:(origin:Math<Int>.V2, slice:ArraySlice<ShapingElement>), hint:inout Int) 
            -> (Math<Int>.V2, ArraySlice<ShapingElement>) 
        {
            for j:Int in (shaping.slice.startIndex ..< hint).reversed() 
            {
                if shaping.slice[j].cluster >= prefix.indices.upperBound 
                {
                    hint = j 
                } 
                else 
                {
                    hint = j + 1
                    break  
                }
            }
            
            // it’s fine if `hint` is initially too low, in that case, the equality 
            // check below will fail, but because `shaping[hint].cluster` is too low 
            // instead of too high. in any case, a reshape will occur, which is 
            // what we need.
            if  shaping.slice[hint].cluster == prefix.indices.upperBound, 
                shaping.slice[hint].breakable 
            {
                // best case, we can reuse our preshaped glyphs 
                assert(prefix.indices.lowerBound == shaping.slice[shaping.slice.startIndex].cluster)
                return (shaping.origin, shaping.slice[..<hint])
            }
            else 
            {
                // worst case, we have to reshape 
                return ((0, 0), self.shape(prefix, origin: (0, 0))[...])
            }
        }
        
        func paragraph(_ text:[Character], indent:Int, width:Int) -> [[(Int, Math<Int>.V2)]] 
        {
            var start:Int = indent 
            for superline:ArraySlice<Character> in text.split(separator: "\n", omittingEmptySubsequences: false)
            {
                var origin:Math<Int>.V2                     = (0, 0)
                var unshaped:ArraySlice<Character>          = superline[...], 
                    remainder:ArraySlice<ShapingElement>    = self.shape(unshaped, origin: origin)[...]
                
                while true 
                {
                    defer 
                    {
                        start       = 0 // clear indent 
                    }
                    
                    // find violating glyph and its associated cluster 
                    for (index, element):(Int, ShapingElement) in zip(remainder.indices, remainder) 
                        where start + element.cumulativeAdvance.x - origin.x > width
                    {
                        // need to explicitly find nextCluster, because cluster 
                        // values may jump by more than 1 
                        let nextCluster:Int = Font.nextCluster(remainder[index...]) ?? unshaped.endIndex
                        
                        // consider each possible breakpoint before `nextCluster`
                        var hint:Int  = index
                        for b:Int in (unshaped.startIndex ..< nextCluster).reversed() where unshaped[b] == " "
                        {
                            let (candidateOrigin, candidate):(Math<Int>.V2, ArraySlice<ShapingElement>) = 
                                self.select(prefix: unshaped[..<b], from: (origin, remainder), hint: &hint)
                            
                            // check if the candidate fits 
                            
                        }
                        
                        // break failure 
                        break 
                    }
                }
            }
        }
    }
}
