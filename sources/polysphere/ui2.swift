protocol _UIElement 
{
    typealias Block = _UIElementBlock
    var classes:Set<String> 
    {
        get 
    }
    var identifier:String? 
    {
        get 
    }
}
protocol _UIElementBlock:UI.Element
{
    func contribute(text:inout [UI.Text.DrawElement], offset:Vector2<Float>)
    func contribute(geometry:inout [UI.Geometry.DrawElement], offset:Vector2<Float>)
    
    // returns true if the event was captured in the given pass
    mutating 
    func event(_ event:UI.Event, pass:UI.Event.Pass)  
    
    // shifts focus in the given "direction", returns true if end is reached 
    // up and down should provide complete traversal, left and right can offer 
    // skips and shortcuts
    mutating 
    func navigate(_ direction:UI.Event.Direction.D2) -> Bool 
    
    // returns true if state changed (for example, updating an animation)
    mutating 
    func process(delta:Int, allotment:Vector2<Int>) -> Bool 
    
    // the equivalent of draw()
    mutating 
    func layout(styledefs:inout UI.Style, path:UI.Style.Path) -> Vector2<Int>
}
extension UI.Element.Block
{
    func contribute(textOffset offset:Vector2<Float>) -> [UI.Text.DrawElement]
    {
        var elements:[UI.Text.DrawElement] = [] 
        self.contribute(text: &elements, offset: offset)
        return elements
    }
    func contribute(geometryOffset offset:Vector2<Float>) -> [UI.Geometry.DrawElement]
    {
        var elements:[UI.Geometry.DrawElement] = [] 
        self.contribute(geometry: &elements, offset: offset)
        return elements
    }
    
    func contribute(text _:inout [UI.Text.DrawElement], offset _:Vector2<Float>) 
    {
    }
    func contribute(geometry _:inout [UI.Geometry.DrawElement], offset _:Vector2<Float>)
    {
    }
    
    func event(_:UI.Event, pass _:UI.Event.Pass)  
    {
    }
    
    func navigate(_:UI.Event.Direction.D2) -> Bool 
    {
        return true 
    }
    
    func process(delta _:Int, allotment:Vector2<Int>) -> Bool 
    {
        return false 
    }
    
    func layout(styledefs _:inout UI.Style, path _:UI.Style.Path) -> Vector2<Int> 
    {
        return .zero 
    }
}

extension UI 
{
    typealias Element = _UIElement
    
    enum Geometry
    {
        struct DrawElement:RandomAccessCollection
        {
            struct Point 
            {
                var s:Vector2<Float>, // screen coordinates (pixels)
                    color:Vector4<UInt8>
            }
            typealias Triangle = (Int, Int, Int)
            
            struct Vertex:GPU.Vertex.Structured
            {
                // screen coordinates (pixels)
                let s:(Float, Float) 
                // padding 
                let p:(Float, Float) = (0, 0)
                // tracer coordinates
                var r:(Float, Float, Float)
                // color coordinates
                var c:(UInt8, UInt8, UInt8, UInt8)
                
                static 
                let attributes:[GPU.Vertex.Attribute<Self>] =
                [
                    .float32x2(\.s, as: .float32),
                    .float32x3(\.r, as: .float32),
                    .uint8x4(  \.c, as: .float32(normalized: true))
                ]
            }
            
            // 3D tracing is disabled using a (.nan, .nan, .nan) triple
            private(set)
            var points:[Point]
            let triangles:[Triangle]
            var s0:Vector2<Float>, 
                r0:Vector3<Float> 
            
            var startIndex:Int 
            {
                return self.points.startIndex 
            }
            var endIndex:Int 
            {
                return self.points.endIndex 
            }
            
            subscript(index:Int) -> Vertex
            {
                let p:Point = self.points[index]
                return .init(
                    s: (self.s0 + p.s).tuple, 
                    r: self.r0.tuple, 
                    c: p.color.tuple)
            }
            
            mutating 
            func color(_ range:Range<Int>, _ color:Vector4<UInt8>) 
            {
                for i:Int in range.clamped(to: self.points.indices) 
                {
                    self.points[i].color = color
                }
            }
            
            func offsetted(by offset:Vector2<Float>) -> Self 
            {
                return 
                    .init(
                        points:     self.points, 
                        triangles:  self.triangles, 
                        s0:         self.s0 + offset, 
                        r0:         self.r0
                    )
            }
        }
    }
    
    struct Text:Element.Block
    {
        struct DrawElement:RandomAccessCollection
        {
            struct Glyph 
            {
                var s:Rectangle<Float>, // screen coordinates (pixels)
                    t:Rectangle<Float>, // texture coordinates 
                    color:Vector4<UInt8>
            }
            
            struct Vertex:GPU.Vertex.Structured
            {
                // screen coordinates (pixels)
                let s:(Float, Float) 
                // texture coordinates 
                let t:(Float, Float)
                // tracer coordinates
                var r:(Float, Float, Float)
                // color coordinates
                var c:(UInt8, UInt8, UInt8, UInt8)
                
                static 
                let attributes:[GPU.Vertex.Attribute<Self>] =
                [
                    .float32x2(\.s, as: .float32),
                    .float32x2(\.t, as: .float32),
                    .float32x3(\.r, as: .float32),
                    .uint8x4(  \.c, as: .float32(normalized: true))
                ]
            }
            
            // 3D tracing is disabled using a (.nan, .nan, .nan) triple
            private(set)
            var glyphs:[Glyph]
            var s0:Vector2<Float>, 
                r0:Vector3<Float> 
            
            var startIndex:Int 
            {
                return self.glyphs.startIndex 
            }
            var endIndex:Int 
            {
                return self.glyphs.endIndex 
            }
            
            init(glyphs:[Glyph], s0:Vector2<Float>, r0:Vector3<Float>) 
            {
                self.glyphs    = glyphs 
                self.s0 = s0 
                self.r0 = r0
            }
            
            private 
            func vertex(s:Vector2<Float>, t:Vector2<Float>, color:Vector4<UInt8>) -> Vertex 
            {
                return .init(
                    s: s.tuple, 
                    t: t.tuple, 
                    r: self.r0.tuple, 
                    c: color.tuple)
            }
            
            subscript(index:Int) -> (Vertex, Vertex) 
            {
                let g:Glyph = self.glyphs[index]
                return 
                    (
                        self.vertex(s: g.s.a + self.s0, t: g.t.a, color: g.color), 
                        self.vertex(s: g.s.b + self.s0, t: g.t.b, color: g.color)
                    )
            }
            
            mutating 
            func color(_ range:Range<Int>, _ color:Vector4<UInt8>) 
            {
                for i:Int in range.clamped(to: self.glyphs.indices) 
                {
                    self.glyphs[i].color = color
                }
            }
            
            func offsetted(by offset:Vector2<Float>) -> Self 
            {
                return 
                    .init(
                        glyphs: self.glyphs, 
                        s0:     self.s0 + offset, 
                        r0:     self.r0
                    )
            }
        }
        
        struct Run:Element
        {
            let classes:Set<String>, 
                identifier:String?
            
            var text:String, 
                style:Style.Rules 
            
            init(_ text:String, classes:Set<String> = [], identifier:String? = nil, 
                style:Style.Rules = .init()) 
            {
                self.text       = text 
                self.classes    = classes 
                self.identifier = identifier 
                self.style      = style 
            }
        }
        
        private 
        enum Cache 
        {
            struct Content 
            {
                var draw:DrawElement, 
                    ranges:[Range<Int>]
                
                var size:Vector2<Int>
            }
            
            case invalid
            case semivalid(Content)
            case valid(Content)
            
            mutating 
            func invalidate() 
            {
                self = .invalid 
            }
            
            mutating 
            func semiinvalidate() 
            {
                switch self 
                {
                case .invalid, .semivalid:
                    break 
                case .valid(let cache):
                    self = .semivalid(cache)
                }
            }
        }
        
        let classes:Set<String>, 
            identifier:String?
        
        private 
        var runs:[(run:Run, sequence:UInt?)], 
            _style:Style.Rules
            
        private 
        var cache:Cache, 
            sequence:UInt?
        
        private 
        var allotment:Vector2<Int>
        {
            willSet(allotment)
            {
                if allotment != self.allotment  
                {
                    self.cache.invalidate()
                }
            }
        }
        
        private 
        var description:String 
        {
            "UI.Text{\(self.runs.map{ $0.run.text }.joined(separator: ""))}"
        }
        
        init(_ runs:[Run], classes:Set<String> = [], identifier:String? = nil, 
            style:Style.Rules = .init()) 
        {
            self.runs       = runs.map{ ($0, nil) }
            self.classes    = classes 
            self.identifier = identifier 
            self._style     = style 
            
            self.cache      = .invalid 
            self.sequence   = nil
            self.allotment  = .zero
        }
        
        // setting the style as a whole (through the .style property) will 
        // trigger a deep invalidation, guaranteeing a reshape to occur. 
        // style changes that do not require a reshape, such as changing 
        // text run colors, or changing the offset positioning of the element, 
        // should be done through individual property setters (.top, .left, etc)
        
        // invalidation: deep
        subscript(index:Int) -> Run 
        {
            get         { return self.runs[index].run }
            set(run)    { self.runs[index].run = run    ; self.cache.invalidate() }
        }
        
        // invalidation: deep
        var style:Style.Rules
        {
            get         { return self._style }
            set(style)  { self._style = style           ; self.cache.invalidate() }
        }
        
        // invalidation: shallow
        var offset:Vector2<Float>? 
        {
            get         { return self._style.offset }
            set(p2)     { self._style.set(offset: p2)   ; self.cache.semiinvalidate() }
        }
        var trace:Vector3<Float>? 
        {
            get         { return self._style.trace }
            set(p3)     { self._style.set(trace: p3)    ; self.cache.semiinvalidate() }
        }
        
        
        // invalidation: shallow 
        func color(_ index:Int) -> Vector4<UInt8>?
        {
            return self.runs[index].run.style.color
        }
        mutating 
        func color(_ index:Int, _ color:Vector4<UInt8>?)
        {
            self.runs[index].run.style.set(color: color)
            self.cache.semiinvalidate()
        }
        
        
        // UIElement conformance 
        func contribute(text:inout [Self.DrawElement], offset:Vector2<Float>) 
        {
            switch self.cache 
            {
            case .valid(let cache):
                text.append(cache.draw.offsetted(by: offset))
            case .semivalid(let cache):
                text.append(cache.draw.offsetted(by: offset))
                Log.warning("text element \(self.description) was drawn with semivalid cache")
            case .invalid:
                Log.error("text element \(self.description) could not be drawn (invalid cache)")
            }
        }
        
        mutating 
        func event(_ event:UI.Event, pass _:UI.Event.Pass) 
        {
            switch event 
            {
            case .character(let character):
                self[1].text.append(character)
            
            case .paste(let string):
                self[1].text += string
            default:
                return 
            }
        }
        
        mutating 
        func process(delta _:Int, allotment:Vector2<Int>) -> Bool 
        {
            self.allotment = allotment
            
            if case .valid = self.cache 
            {
                return false 
            }
            else 
            {
                return true 
            }
        }
        
        mutating 
        func layout(styledefs:inout Style, path:Style.Path) -> Vector2<Int>
        {
            let path:Style.Path = path.appended(self)
            // check block styles 
            let lookup:(sequence:UInt, style:Style.Rules) = styledefs.resolve(path)
            if (self.sequence.map{ $0 != lookup.sequence }) ?? true 
            {
                self.cache.invalidate()
                self.sequence = lookup.sequence
            }
            
            let style:Style.Rules    = lookup.style.overlaid(with: self._style)
            var styles:[Style.Rules] = []
                styles.reserveCapacity(self.runs.count)
            // compute styling for inline runs 
            for i:Int in self.runs.indices
            {
                // check inline styles
                let lookup:(sequence:UInt, style:Style.Rules) = 
                    styledefs.resolve(path.appended(self[i]))
                if (self.runs[i].sequence.map{ $0 != lookup.sequence }) ?? true
                {
                    self.cache.invalidate()
                    self.runs[i].sequence = lookup.sequence
                }
                
                styles.append(lookup.style.overlaid(with: self[i].style))
            }
            
            switch self.cache 
            {
            case .valid(let cache):
                return cache.size 
            
            case .semivalid(var cache):
                cache.draw.s0 = style.offset
                cache.draw.r0 = style.trace 
                for (runstyle, range):(Style.Rules, Range<Int>) in zip(styles, cache.ranges) 
                {
                    cache.draw.color(range, runstyle.color)
                }
                
                self.cache = .valid(cache)
                return cache.size
            
            case .invalid:
                let texts:[String]      = self.runs.map{ $0.run.text }
                let cache:Cache.Content = Self.reshape((texts, styles), 
                    style: style, allotment: self.allotment, styledefs: &styledefs)
                
                self.cache = .valid(cache)
                return cache.size
            }
        }
        
        private static  
        func reshape(_ runs:(texts:[String], styles:[Style.Rules]), style:Style.Rules, 
            allotment:Vector2<Int>, styledefs:inout Style)
            -> Cache.Content
        {
            // fill in shaping parameters 
            let parameters:[HarfBuzz.ShapingParameters] = runs.styles.map 
            {
                let parameters:HarfBuzz.ShapingParameters = 
                    .init(
                        font: styledefs.font($0.font), 
                        features: $0.features.map{ ($0.tag, .init($0.value)) }
                    )
                return parameters
            }
            
            var stc:[DrawElement.Glyph] = []
            let ranges:[Range<Int>], 
                size:Vector2<Int>
            if style.wrap
            {
                // no concept of 2D grid layout, new lines just reset the x coordinate to 0 (or indent)
                let (glyphs, indices):([HarfBuzz.Glyph], (runs:[Range<Int>], lines:[Range<Int>])) = 
                    HarfBuzz.paragraph(zip(runs.texts, parameters), indent: style.indent, width: allotment.x << 6)
                ranges = indices.runs 
                stc.reserveCapacity(glyphs.count)
                // line number, should start at 0
                var l:Int = indices.lines.startIndex
                for ((runstyle, parameters), range):((Style.Rules, HarfBuzz.ShapingParameters), Range<Int>) in 
                    zip(zip(runs.styles, parameters), indices.runs) 
                {
                    for (i, g):(Int, HarfBuzz.Glyph) in zip(range, glyphs[range])
                    {
                        while !(indices.lines[l] ~= i) 
                        {
                            l += 1
                        }
                        
                        let sort:Typeface.Font.SortInfo = parameters.font.sorts[g.index]
                        // convert 64-point fractional units to ints to floats 
                        let p:Vector2<Int> = g.position &+ .init(0, l * style.line_height) &<< 6, 
                            a:Vector2<Int> = sort.vertices.a &+ p, 
                            b:Vector2<Int> = sort.vertices.b &+ p
                        
                        let s:Rectangle<Float> = .init(.cast(a &>> 6), .cast(b &>> 6))
                        stc.append(.init(s: s, t: styledefs.atlas[sort.sprite], color: runstyle.color))
                    }
                }
                
                size = .init(allotment.x, indices.lines.count * style.line_height)
            }
            else 
            {
                let glyphs:[HarfBuzz.Glyph], 
                    width:Int 
                (glyphs, ranges, width) = HarfBuzz.line(zip(runs.texts, parameters))
                stc.reserveCapacity(glyphs.count)
                
                for ((runstyle, parameters), range):((Style.Rules, HarfBuzz.ShapingParameters), Range<Int>) in 
                    zip(zip(runs.styles, parameters), ranges) 
                {
                    for g:HarfBuzz.Glyph in glyphs[range]
                    {
                        let sort:Typeface.Font.SortInfo = parameters.font.sorts[g.index]
                        let s:Rectangle<Float> = .init(
                            .cast((sort.vertices.a &+ g.position) &>> 6), 
                            .cast((sort.vertices.b &+ g.position) &>> 6)
                        )
                        
                        stc.append(.init(s: s, t: styledefs.atlas[sort.sprite], color: runstyle.color))
                    }
                }
                
                size = .init(width, style.line_height)
            }
            
            let draw:DrawElement = .init(glyphs: stc, s0: style.offset, r0: style.trace)
            
            return .init(draw: draw, ranges: ranges, size: size)
        }
    }
    
    enum Layout 
    {
        /* enum HorizontalBox<Child> where Child:Element
        {
            private 
            enum Cache 
            {
                case invalid  
                case valid(size:Vector2<Int>)
                
                mutating 
                func invalidate() 
                {
                    self = .invalid 
                }
            }
            
            var style:Style.Rules.Block
            {
                willSet(style)
                {
                    if style.padding != self.style.padding 
                    {
                        self.cache.invalidate()
                    }
                }
            }
            
            private 
            var allotment:Vector2<Int>
            {
                willSet(allotment)
                {
                    if allotment != self.allotment  
                    {
                        self.cache.invalidate()
                    }
                }
            }
            
            func contribute(text:inout [UI.Text.DrawElement], offset:Vector2<Float>) 
            {
                self.child.contribute(text: &text, offset: self.offset)
            }
            func contribute(geometry _:inout [UI.Geometry.DrawElement], offset _:Vector2<Float>)
            {
                self.child.contribute(geometry: &geometry, offset: self.offset)
            }
            
            mutating 
            func event(_ event:UI.Event, pass:UI.Event.Pass) 
            {
                self.child.event(event, pass: pass)
            }
            
            mutating 
            func navigate(_ direction:UI.Event.Direction.D2) -> Bool 
            {
                return self.child.navigate(direction)
            }
            
            mutating 
            func process(delta _:Int, allotment:Vector2<Int>) -> Bool 
            {
                self.allotment = allotment
                
                if case .valid = self.cache 
                {
                    return false 
                }
                else 
                {
                    return true 
                }
            }
            
            func layout(allotment _:Vector2<Int>, styledefs _:inout UI.Style) -> Vector2<Int> 
            {
                return .zero 
            }
        } */
    }
    
    /*
    struct VerticalList:UIElement
    {
        private 
        var children:[UIElement], 
            offsets:[Int]
        
        private 
        var allotment:Vector2<Int>, 
            size:Vector2<Int>
        
        // UIElement conformance 
        var focused:Bool 
        {
            return !self.children.allSatisfy{ !$0.focused }
        }
        
        func contribute(text:inout [Text.DrawElement], offset:Vector2<Float>) 
        {
            for (child, y):(UIElement, Int) in zip(self.children, self.offsets)
            { 
                text.contribute(&text, offset: offset + .cast(0, y))
            }
        }
        func contribute(geometry:inout [Text.DrawElement], offset:Vector2<Float>) 
        {
            for (child, y):(UIElement, Int) in zip(self.children, self.offsets)
            { 
                geometry.contribute(&text, offset: offset + .cast(0, y))
            }
        }
        
        init(_ children:[UIElement] = [])
        {
            self.children  = children
            self.offsets   = .init(repeating: 0, count: children.count)
            self.allotment = .zero 
        }
        
        mutating 
        func keypress(_ key:UI.Key, _ modifiers:UI.Key.Modifiers) -> [Response]
        {
            var responses:[Response] = []
            for i:Int in self.children.indices where self.children[i].focused 
            {
                responses.append(contentsOf: self.children[i].keypress(key, modifiers))
            }
            return responses
        }
        mutating 
        func character(_ character:Character) -> [Response]
        {
            var responses:[Response] = []
            for i:Int in self.children.indices where self.children[i].focused 
            {
                responses.append(contentsOf: self.children[i].character(character))
            }
            return responses
        }
        
        mutating 
        func leave() -> [Response]
        {
            var responses:[Response] = []
            for i:Int in self.children.indices where self.children[i].focused 
            {
                responses.append(contentsOf: self.children[i].leave())
            }
            return responses
        }
        mutating 
        func next() -> ([UI.Response], Bool)
        {
            var responses:[Response] = []
            for i:Int in self.children.indices where self.children[i].focused 
            {
                let next:(responses:[UI.Response], empty:Bool) = self.children[i].next()
                responses.append(contentsOf: next.responses)
                
                // defocus all other children 
                for j:Int in (i + 1) ..< self.children.endIndex where self.children[j].focused 
                {
                    responses.append(contentsOf: self.children[j].leave())
                }
                
                if next.empty 
                {
                    for j:Int in (i + 1) ..< self.children.endIndex 
                    {
                        responses.append(contentsOf: self.children[j].enter())
                        if self.children[j].focused 
                        {
                            return (responses, false)
                        }
                    }
                    
                    break 
                }
                else 
                {
                    return (responses, false)
                }
            }
            
            return (responses, true)
        }
        mutating 
        func enter() -> [Response] 
        {
            if self.children.isEmpty 
            {
                return []
            }
            else 
            {
                return self.children[self.children.startIndex].enter()
            }
        }
        
        func process(model:Model, delta:Int) -> Bool 
        {
            var mutated:Bool = false 
            for i:Int in self.children.indices 
            {
                mutated = self.children[i].process(model: model, delta: delta) || mutated 
            }
            return mutated 
        }
        
        mutating 
        func layout(allotment:Vector2<Int>) -> Vector2<Int>
        {
            guard allotment != self.allotment 
            else 
            {
                return self.size 
            }
            
            self.allotment = allotment 
            
            self.size = .zero            
            for i:Int in self.children.indices 
            {
                self.offsets[i] = bb.y
                
                let allotment:Vector2<Int>  = .init(allotment.x, allotment.y - bb.y), 
                    size:Vector2<Int>       = self.children[i].layout(allotment: allotment)
                
                self.size.x  = max(self.size.x, size.x)
                self.size.y += size.y
            }
            
            return self.size
        }
    }
    
    struct Label:UIElement 
    {
        private 
        var allotment:Vector2<Int>, 
            size:Vector2<Int>
            
        private 
        var text:[(Style.Inline, String)], 
            style:Style.Block 
        
        // cache 
        private 
        var glyphs:[(glyph:Text.Glyph, color:Vector4<UInt8>)], 
            runs:[Range<Int>]
        
        var fixedText:[Text.Vertex] 
        {
            return []
        } 

        mutating 
        func push(text:[(Style.Inline, String)], style:Style.Block)
        {
            let linebox:Vector2<Int> = .init()
        }
        
        mutating 
        func size(available:Vector2<Int>) -> Vector2<Int>
    }
    
    struct Console 
    {
        private 
        var cells:[(history:String, field:[Character])], 
            arrow:Int
        
        private(set)
        var hash:UInt64 = 0
        
        private(set)
        var cursors:Range<Int>
        {
            didSet 
            {
                self.hash &+= 1
            }
        }
        
        private(set)
        var field:[Character] 
        {
            get 
            {
                return self.cells[self.arrow].field
            }
            set(v) 
            {
                self.cells[self.arrow].field = v
                self.hash &+= 1
            }
        }
        
        init() 
        {
            self.cells = [(history: "", field: [])]
            self.arrow = self.cells.endIndex - 1
            
            self.cursors = 0 ..< 0
        }
        
        mutating 
        func keypress(_ key:UI.Key, _ modifiers:UI.Key.Modifiers) -> [Response]
        {
            switch key 
            {
            case .enter:
                let command:String = .init(self.field)
                self.cells[self.cells.endIndex - 1] = (command, self.field)
                self.cells.append(("", []))
                self.field   = .init(self.cells[self.arrow].history)
                self.arrow   = self.cells.endIndex - 1
                self.cursors = 0 ..< 0
                
                Log.note(command)
                return [.text(command)]
            
            case .up:
                if self.arrow > self.cells.startIndex 
                {
                    self.arrow  -= 1
                    self.cursors = self.field.endIndex ..< self.field.endIndex
                }
            
            case .down:
                if self.arrow < self.cells.endIndex - 1 
                {
                    self.arrow  += 1
                    self.cursors = self.field.endIndex ..< self.field.endIndex
                }
            
            case .left:
                let i:Int 
                if modifiers.control 
                {
                    i    = self.field[..<self.cursors.lowerBound].lastIndex{ $0 != " " } 
                        ?? self.field.startIndex
                }
                else 
                {
                    i    = max(self.cursors.lowerBound - 1, self.field.startIndex)
                }
                
                self.cursors = i ..< (modifiers.shift ? self.cursors.upperBound : i)
            
            case .right:
                let j:Int 
                if modifiers.control 
                {
                    j    = self.field[self.cursors.upperBound...].firstIndex{ $0 != " " } 
                        ?? self.field.endIndex
                }
                else 
                {
                    j    = min(self.cursors.upperBound + 1, self.field.endIndex)
                }
                
                self.cursors = (modifiers.shift ? self.cursors.lowerBound : j) ..< j
            
            case .backspace:
                if self.cursors.count == 0 
                {
                    self.keypress(.left, modifiers | .init(shift: true))
                }
                
                self.field.removeSubrange(self.cursors)
            
            case .delete:
                if self.cursors.count == 0 
                {
                    self.keypress(.right, modifiers | .init(shift: true))
                }
                
                self.field.removeSubrange(self.cursors)
            
            default:
                break 
            }
            
            return []
        }
        
        mutating 
        func character(_ character:Character) -> [Response]
        {
            Log.note("\(character)")
            self.field[self.cursors] = [character]
            self.cursors = self.cursors.lowerBound + 1 ..< self.cursors.upperBound + 1
            
            return [] 
        }
    }
    */
}
