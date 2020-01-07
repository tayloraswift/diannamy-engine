extension UI 
{
    private static
    func bbox(content:Vector2<Int>, padding:UI.Style.Metrics<Int>, border:UI.Style.Metrics<Int>, radius:Int) 
        -> (Vector2<Int>, Vector2<Int>, diameter:Int) 
    {
        // outer edges of border box
        let a:Vector2<Int>      = .init(-padding.left  - border.left,   -padding.top    - border.top),
            b:Vector2<Int>      = .init( padding.right + border.right,   padding.bottom + border.bottom) &+ content
        let area:Vector2<Int>   = b &- a
        let diameter:Int        = min(area.x, area.y, radius * 2)
        return (a, b, diameter)
    }
    
    final 
    class Canvas 
    {
        struct Text:RandomAccessCollection
        {
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
            let vertices:[(s:Vector2<Float>, t:Vector2<Float>)]
            var s0:Vector2<Float>
            let r0:Vector3<Float>, 
                color:Vector4<UInt8>
            
            //var z:Float = 0
            
            var startIndex:Int 
            {
                return self.vertices.startIndex 
            }
            var endIndex:Int 
            {
                return self.vertices.endIndex 
            }
            
            subscript(index:Int) -> Vertex
            {
                let (s, t):(Vector2<Float>, Vector2<Float>) = self.vertices[index]
                return .init(
                    s: (self.s0 + s).tuple, 
                    t: (          t).tuple, 
                    r: (self.r0    ).tuple, 
                    c:  self.color.tuple)
            }
            
            static 
            func symbol(_ symbol:UI.Styles.FontLibrary.Symbol, at size:UI.Styles.FontLibrary.Symbol.Size, 
                color:Vector4<UInt8>, 
                offset:Vector2<Float> = .zero,
                styles:UI.Styles)
                -> Self 
            {
                let font:Typeface.Font = styles.fonts[symbols: size]
                let (s, t):(s:Rectangle<Float>, t:Rectangle<Float>) = 
                    Self.glyph(symbol.rawValue, of: font, styles: styles)
                return .init(vertices: [(s: s.a + offset, t: t.a), (s: s.b + offset, t: t.b)], 
                    s0: .zero, r0: .init(repeating: .nan), color: color)
            }
            
            // used to render symbols from emblem font 
            private static 
            func glyph(_ index:Int, of font:Typeface.Font, styles:UI.Styles) 
                -> (s:Rectangle<Float>, t:Rectangle<Float>)
            {
                let sort:Typeface.Font.SortInfo = font.sorts[index]
                // convert 64-point fractional units to ints to floats 
                let a:Vector2<Float> = .cast(sort.vertices.a &>> 6), 
                    b:Vector2<Float> = .cast(sort.vertices.b &>> 6)
                
                let s:Rectangle<Float> = .init(a, b), 
                    t:Rectangle<Float> = styles.fonts.atlas[sort.sprite]
                return (s, t)
            }
        }
        
        struct Geometry:RandomAccessCollection
        {
            typealias Triangle = (Int, Int, Int)
            
            struct Vertex:GPU.Vertex.Structured
            {
                // screen coordinates (pixels)
                let s:(Float, Float) 
                // implicit parameters 
                // we use the diameter to avoid having to represent fractional radii
                let p:(UInt16, UInt16, UInt16)
                // implicit coordinates 
                let i:(UInt8, UInt8)
                // color horizontal(inner, outer), vertical(inner, outer)
                let c:
                (
                    ((UInt8, UInt8, UInt8, UInt8), (UInt8, UInt8, UInt8, UInt8)),
                     (UInt8, UInt8, UInt8, UInt8)
                )
                
                // padding 
                let padding:UInt32 = 0
                
                static 
                var attributes:[GPU.Vertex.Attribute<Self>] = 
                [
                        .float32x2(\.s,     as: .float32),
                        .uint16x3( \.p,     as: .float32(normalized: false)),
                        .uint8x2(  \.i,     as: .float32(normalized: false)),
                        .uint8x4(  \.c.0.0, as: .float32(normalized: true)),
                        .uint8x4(  \.c.0.1, as: .float32(normalized: true)),
                        .uint8x4(  \.c.1,   as: .float32(normalized: true)),
                ] 
            }
            
            // 3D tracing is disabled using a (.nan, .nan, .nan) triple
            // screen coordinates (pixels), color 
            let vertices:
            [(
                s:Vector2<Float>, 
                p:(x:UInt16, y:UInt16, d:UInt16), 
                i:Vector2<UInt8>,
                c:((Vector4<UInt8>, Vector4<UInt8>), Vector4<UInt8>)
            )] 
            let triangles:[Triangle]
            var s0:Vector2<Float>//, 
            //    r0:Vector3<Float> 
            
            var startIndex:Int 
            {
                return self.vertices.startIndex 
            }
            var endIndex:Int 
            {
                return self.vertices.endIndex 
            }
            
            subscript(index:Int) -> Vertex
            {
                let (s, p, i, c):
                (
                    s:Vector2<Float>, 
                    p:(x:UInt16, y:UInt16, d:UInt16), 
                    i:Vector2<UInt8>,
                    c:((Vector4<UInt8>, Vector4<UInt8>), Vector4<UInt8>)
                ) = self.vertices[index]
                return .init(
                    s: (self.s0 + s).tuple, 
                    p: p, 
                    i: (i.x, i.y),
                    c: ((c.0.0.tuple, c.0.1.tuple), c.1.tuple))
            }
            
            static 
            func rectangle(
                at s:Vector2<Float>,
                content:Vector2<Int>            = .zero,
                padding:UI.Style.Metrics<Int>   = .zero, 
                border:UI.Style.Metrics<Int>    = .zero, 
                radius:Int                      = 0, 
                crease:UI.Style.Metrics<Bool>   = .false, 
                color:(fill:Vector4<UInt8>, border:Vector4<UInt8>)) -> Self 
            {
                let crease:(lt:Bool, rt:Bool, lb:Bool, rb:Bool) = 
                (
                    crease.top,
                    crease.right,
                    crease.left,
                    crease.bottom
                )
                let color:
                (
                    fill:Vector4<UInt8>,
                    lt:(Vector4<UInt8>, Vector4<UInt8>), 
                    rt:(Vector4<UInt8>, Vector4<UInt8>), 
                    lb:(Vector4<UInt8>, Vector4<UInt8>), 
                    rb:(Vector4<UInt8>, Vector4<UInt8>)
                ) = 
                (
                    color.fill,
                    (color.border, color.border),
                    (color.border, color.border),
                    (color.border, color.border),
                    (color.border, color.border)
                )
                
                return Self.rectangle(at: s, metrics: (content, padding, border), radius: radius, crease: crease, color: color)
            }
            
            private static 
            func rectangle(
                at s:Vector2<Float>,
                metrics:(content:Vector2<Int>, padding:UI.Style.Metrics<Int>, border:UI.Style.Metrics<Int>), 
                radius:Int, 
                crease:(lt:Bool, rt:Bool, lb:Bool, rb:Bool), 
                color:
                (
                    fill:Vector4<UInt8>,
                    lt:(Vector4<UInt8>, Vector4<UInt8>), 
                    rt:(Vector4<UInt8>, Vector4<UInt8>), 
                    lb:(Vector4<UInt8>, Vector4<UInt8>), 
                    rb:(Vector4<UInt8>, Vector4<UInt8>)
                )) -> Self 
            {
                // outer edges of border box
                let bounds:(Vector2<Int>, Vector2<Int>, diameter:Int) = 
                    UI.bbox(content: metrics.content, padding: metrics.padding, border: metrics.border, radius: radius)
                let a:(Vector2<Float>, Vector2<Float>), 
                    b:(Vector2<Float>, Vector2<Float>)
                
                a.0 = .cast(bounds.0 &- 1)
                b.1 = .cast(bounds.1 &+ 1)
                
                // perform UInt16 encoding 
                let border:(top:UInt16, right:UInt16, bottom:UInt16, left:UInt16), 
                    diameter:UInt16
                border.top      = .init(clamping: metrics.border.top)
                border.right    = .init(clamping: metrics.border.right)
                border.bottom   = .init(clamping: metrics.border.bottom)
                border.left     = .init(clamping: metrics.border.left)
                diameter        = .init(clamping: bounds.diameter)
                
                // use `diameter / 2`, not `radius` because the diameter is constrained 
                // to the size of the element
                // also, add a 1px apron to accomodate fractional coordinates
                let d:(top:Float, right:Float, bottom:Float, left:Float) = 
                (
                    1 + Swift.max(.init(diameter) / 2, .init(border.top)),
                    1 + Swift.max(.init(diameter) / 2, .init(border.right)),
                    1 + Swift.max(.init(diameter) / 2, .init(border.bottom)),
                    1 + Swift.max(.init(diameter) / 2, .init(border.left))
                )
                // inset edges
                a.1 = a.0 + .init(d.left,  d.top)
                b.0 = b.1 - .init(d.right, d.bottom)
                
                let vertices:
                [(
                    s:Vector2<Float>, 
                    p:(x:UInt16, y:UInt16, d:UInt16), 
                    i:Vector2<UInt8>,
                    c:((Vector4<UInt8>, Vector4<UInt8>), Vector4<UInt8>)
                )] =
                [
                    (.init(a.0.x, a.0.y), (border.left,  border.top,    diameter), .init(1, 1), (color.lt, color.fill)),
                    (
                        crease.lt ? a.0                 : .init(a.1.x, a.0.y), 
                                          (border.left,  border.top,    diameter), .init(0, 1), (color.lt, color.fill)
                    ),
                    (
                        crease.rt ? .init(b.1.x, a.0.y) : .init(b.0.x, a.0.y), 
                                          (border.right, border.top,    diameter), .init(0, 1), (color.rt, color.fill)
                    ),
                    (.init(b.1.x, a.0.y), (border.right, border.top,    diameter), .init(1, 1), (color.rt, color.fill)),
                    
                    (
                        crease.lt ? a.0                 : .init(a.0.x, a.1.y), 
                                          (border.left,  border.top,    diameter), .init(1, 0), (color.lt, color.fill)
                    ),
                    (.init(a.1.x, a.1.y), (border.left,  border.top,    diameter), .init(0, 0), (color.lt, color.fill)),
                    (.init(b.0.x, a.1.y), (border.right, border.top,    diameter), .init(0, 0), (color.rt, color.fill)),
                    (
                        crease.rt ? .init(b.1.x, a.0.y) : .init(b.1.x, a.1.y), 
                                          (border.right, border.top,    diameter), .init(1, 0), (color.rt, color.fill)
                    ),
                    
                    (
                        crease.lb ? .init(a.0.x, b.1.y) : .init(a.0.x, b.0.y), 
                                          (border.left,  border.bottom, diameter), .init(1, 0), (color.lb, color.fill)
                    ),
                    (.init(a.1.x, b.0.y), (border.left,  border.bottom, diameter), .init(0, 0), (color.lb, color.fill)),
                    (.init(b.0.x, b.0.y), (border.right, border.bottom, diameter), .init(0, 0), (color.rb, color.fill)),
                    (
                        crease.rb ? b.1                 : .init(b.1.x, b.0.y), 
                                          (border.right, border.bottom, diameter), .init(1, 0), (color.rb, color.fill)
                    ),
                    
                    (.init(a.0.x, b.1.y), (border.left,  border.bottom, diameter), .init(1, 1), (color.lb, color.fill)),
                    (
                        crease.lb ? .init(a.0.x, b.1.y) : .init(a.1.x, b.1.y), 
                                          (border.left,  border.bottom, diameter), .init(0, 1), (color.lb, color.fill)
                    ),
                    (
                        crease.rb ? b.1                 : .init(b.0.x, b.1.y), 
                                          (border.right, border.bottom, diameter), .init(0, 1), (color.rb, color.fill)
                    ),
                    (.init(b.1.x, b.1.y), (border.right, border.bottom, diameter), .init(1, 1), (color.rb, color.fill)),
                ]
                
                //  0   1           2   3
                //  4   5           6   7
                // 
                //  8   9          10  11
                // 12  13          14  15
                var triangles:[(Int, Int, Int)] = 
                [
                    ( 1,  5,  6),   // ◣
                    ( 1,  6,  2),   // ◥
                    
                    ( 4,  8,  9),   // ◣
                    ( 4,  9,  5),   // ◥
                    
                    ( 5,  9, 10),   // ◣
                    ( 5, 10,  6),   // ◥
                    
                    ( 6, 10, 11),   // ◣
                    ( 6, 11,  7),   // ◥
                    
                    ( 9, 13, 14),   // ◣
                    ( 9, 14, 10),   // ◥
                ] 
                if !crease.lt 
                {
                    triangles += [( 0,  4,  5), ( 0,  5,  1)] // ◣,◥
                }
                if !crease.rt 
                {
                    triangles += [( 2,  6,  7), ( 2,  7,  3)] // ◣,◥
                }
                if !crease.lb 
                {
                    triangles += [( 8, 12, 13), ( 8, 13,  9)] // ◣,◥
                }
                if !crease.rb 
                {
                    triangles += [(10, 14, 15), (10, 15, 11)] // ◣,◥
                }
                
                return .init(vertices: vertices, triangles: triangles, s0: s)
            }
        }
        
        enum Layer:CaseIterable 
        {
            case frost // stencil blur effect 
            case overlay 
            case highlight 
        }
        private(set)
        var vector:[Layer: (text:[Text], geometry:[Geometry])], 
            layers:[(Layer, [Renderer.Command])]
        
        func push(layer:Layer, commands:[Renderer.Command]) 
        {
            // merge indentical-adjacent layers to cut down the number of compositing passes
            if  let last:Layer = self.layers.last?.0, 
                last == layer 
            {
                self.layers[self.layers.endIndex - 1].1.append(.clear(color: false, depth: true))
                self.layers[self.layers.endIndex - 1].1.append(contentsOf: commands)
            }
            else 
            {
                self.layers.append((layer, commands))
            }
        }
        func text(_ text:Text, layer:Layer = .overlay) 
        {
            self.vector[layer, default: ([], [])].text.append(text)
        }
        func geometry(_ geometry:Geometry, layer:Layer = .overlay) 
        {
            self.vector[layer, default: ([], [])].geometry.append(geometry)
        }
        
        init()
        {
            self.vector = [:]
            self.layers = []
        }
        
        private 
        func capacities() -> (text:Int, geometry:(Int, indices:Int)) 
        {
            var capacity:(text:Int, geometry:(Int, indices:Int)) = (0, (0, 0))
            for (text, geometry):([Text], [Geometry]) in self.vector.values 
            {
                for text:Text in text 
                {
                    capacity.text              += text.count 
                }
                for geometry:Geometry in geometry 
                {
                    capacity.geometry.0        += geometry.count 
                    capacity.geometry.indices  += 3 * geometry.triangles.count
                }
            }
            return capacity
        }
        private 
        func assign(to vao:
            (
            text:GPU.Vertex.Array<UI.Canvas.Text.Vertex, UInt8>, 
            geometry:GPU.Vertex.Array<UI.Canvas.Geometry.Vertex, UInt32>
            )) 
            -> [Layer: (text:Range<Int>, geometry:Range<Int>)]
        {
            var buffer:
            (
                text:[UI.Canvas.Text.Vertex], 
                geometry:
                (
                    vertices:[UI.Canvas.Geometry.Vertex], 
                    indices:[UInt32]
                ) 
            ) 
            var ranges:[Layer: (text:Range<Int>, geometry:Range<Int>)] = [:]
            
            let capacity:(text:Int, geometry:(Int, indices:Int)) = self.capacities()
            // fill geometry first so we can compute monotonically increasing z values
            buffer.geometry.indices     = []
            buffer.geometry.indices.reserveCapacity(capacity.geometry.indices)
            buffer.geometry.vertices    = []
            buffer.geometry.vertices.reserveCapacity(capacity.geometry.0)
            
            buffer.text                 = []
            buffer.text.reserveCapacity(capacity.text)
            for layer:Layer in Layer.allCases 
            {
                guard let (text, geometry):([Text], [Geometry]) = self.vector[layer]
                else 
                {
                    continue 
                }
                
                let base:(text:Int, geometry:Int) = 
                (
                    buffer.text.count, 
                    buffer.geometry.indices.count 
                )
                var z:Float = -1
                for element:UI.Canvas.Geometry in geometry 
                {
                    let base:Int = buffer.geometry.vertices.count
                    for triangle:(Int, Int, Int) in element.triangles 
                    {
                        buffer.geometry.indices.append(.init(triangle.0 + base))
                        buffer.geometry.indices.append(.init(triangle.1 + base))
                        buffer.geometry.indices.append(.init(triangle.2 + base))
                    }
                    
                    z = z.nextUp
                    buffer.geometry.vertices.append(contentsOf: element)
                }
                        
                for element:UI.Canvas.Text in text
                {
                    z = z.nextUp
                    buffer.text.append(contentsOf: element)
                }
                
                ranges[layer] = 
                (
                    text:       base.text     ..< buffer.text.count,
                    geometry:   base.geometry ..< buffer.geometry.indices.count
                )
            }
            
            vao.text.buffers.vertex.assign(buffer.text)
            vao.geometry.buffers.vertex.assign(buffer.geometry.vertices)
            vao.geometry.buffers.index.assign(buffer.geometry.indices)
            
            return ranges
        }
        
        func flatten(assigning vao:
            (
            text:GPU.Vertex.Array<UI.Canvas.Text.Vertex, UInt8>, 
            geometry:GPU.Vertex.Array<UI.Canvas.Geometry.Vertex, UInt32>
            ), 
            programs:(text:GPU.Program, geometry:GPU.Program), 
            fontatlas:GPU.Texture.D2<UInt8>, 
            display:GPU.Buffer.Uniform<UInt8>)
        {
            let ranges:[Layer: (text:Range<Int>, geometry:Range<Int>)] = self.assign(to: vao)
            for layer:Layer in Layer.allCases 
            {
                guard let (text, geometry):(Range<Int>, Range<Int>) = ranges[layer]
                else 
                {
                    continue 
                }
                
                var commands:[Renderer.Command] = []
                if !geometry.isEmpty 
                {
                    commands.append(.draw(elements: geometry, 
                        of: vao.geometry, 
                        as: .triangles, 
                        using: programs.geometry,
                        [
                            "Display"   : .block(display)
                        ]))
                }
                if !text.isEmpty 
                {
                    commands.append(.draw(text, 
                        of: vao.text, 
                        as: .lines,
                        using: programs.text,  
                        [
                            "Display"   : .block(display), 
                            "fontatlas" : .texture2(fontatlas)
                        ]))
                }
                self.push(layer: layer, commands: commands)
            }
            
            // clear vector commands, since it has been merged into the normal layers 
            self.vector = [:]
        }
    }
}

protocol _UIGroup:AnyObject 
{
    func contains(_:Vector2<Float>) -> UI.Group?
    func action(_:UI.Event.Action)
    func update(_:Int, styles:UI.Styles, viewport:Vector2<Int>, frame:Rectangle<Int>)
    
    var state:(focus:Bool, active:Bool, hover:Bool) 
    {
        get 
        set
    }
    
    var cursor:(inactive:UI.Cursor, active:UI.Cursor)
    {
        get 
    }
}
extension UI 
{
    typealias Group = _UIGroup 
    
    class Element
    {
        /* enum Recompute 
        {
            enum Style 
            {
                case intrinsic, no
            }
            enum Constraints 
            {
                case extrinsic, intrinsic, no
            }
            enum Layout 
            {
                case physical, cosmetic, no
            }
        } */
        
        final 
        var classes:Set<String>
        final 
        var identifier:String?
        
        final private 
        var path:UI.Style.Path 
        
        var elements:[UI.Element]
        {
            []
        }
        
        final 
        var style:UI.Style.Rules 
        
        var computedStyle:UI.Style.Rules = .init()
        /* {
            willSet(new)
            {
                if  new.color               != self.computedStyle.color             ||
                    new.backgroundColor     != self.computedStyle.backgroundColor   ||
                    new.borderColor         != self.computedStyle.borderColor       ||
                    new.trace               != self.computedStyle.trace             ||
                    new.offset              != self.computedStyle.offset 
                {
                    if self.recomputeLayout == .no 
                    {
                        self.recomputeLayout = .cosmetic 
                    }
                }
            }
        } */
        
        // final 
        // var recomputeLayout:Recompute.Layout = .physical
        
        // Group conformance 
        final 
        var state:(focus:Bool, active:Bool, hover:Bool) = (false, false, false)
        
        var pseudoclasses:Set<UI.Style.PseudoClass> 
        {
            var pseudoclasses:Set<UI.Style.PseudoClass> = []
            if self.state.hover 
            {
                pseudoclasses.insert(.hover)
            }
            if self.state.focus 
            {
                pseudoclasses.insert(.focus)
            }
            if self.state.active 
            {
                pseudoclasses.insert(.active)
            }
            return pseudoclasses
        }
        //
        
        init(identifier:String?, classes:Set<String>, style:UI.Style.Rules)
        {
            self.classes    = classes 
            self.identifier = identifier
            self.style      = style
            
            self.path       = .init()
        }
        
        final 
        func postorder(_ body:(UI.Element) throws -> ()) rethrows 
        {
            for element:UI.Element in self.elements 
            {
                try element.postorder(body)
            }
            
            try body(self)
        }
        
        final 
        func set(prefix:UI.Style.Path) 
        {
            self.path = prefix.appended(self) 
            for element:UI.Element in self.elements
            {
                element.set(prefix: self.path)
            }
        }
        
        final 
        func restyle(_ styles:UI.Styles) 
        {
            self.computedStyle = styles.resolve(self.path).overlaid(with: self.style)  
        }
        
        func process(_:Int) 
        {
        }
        
        func draw(_:UI.Canvas, s _:Vector2<Float>) 
        {
        }
    }
}
extension UI.Element 
{
    class Block:UI.Element, UI.Group
    {
        // final 
        // var recomputeConstraints:Recompute.Constraints = .intrinsic 
        final 
        var computedConstraints:(main:Int, cross:Int) = (0, 0) // represents minimum size 
        
        final fileprivate(set) 
        var size:Vector2<Int>   = .zero, 
            s:Vector2<Float>    = .zero 
        
        /* override 
        var computedStyle:UI.Style.Rules  */
        /* {
            willSet(new) 
            {
                if  new.axis    != self.computedStyle.axis     ||
                    new.align   != self.computedStyle.align 
                {
                    self.recomputeConstraints = .intrinsic 
                }
                else if  
                    new.margin  != self.computedStyle.margin   ||
                    new.border  != self.computedStyle.border   ||
                    new.padding != self.computedStyle.padding  ||
                    new.grow    != self.computedStyle.grow     || 
                    new.stretch != self.computedStyle.stretch
                {
                    self.recomputeConstraints = .extrinsic 
                }
            }
        } */
        
        // Group conformance 
        var cursor:(inactive:UI.Cursor, active:UI.Cursor) 
        {
            (.arrow, .arrow)
        }
        
        func action(_:UI.Event.Action)
        {
        }
        
        final 
        func contains(_ point:Vector2<Float>) -> UI.Group? 
        {
            for element:UI.Element in self.elements 
            {
                if  let group:UI.Group  = element as? UI.Group, 
                    let result:UI.Group = group.contains(point) 
                {
                    return result 
                }
            }
            
            guard self.computedStyle.occlude
            else 
            {
                return nil
            }
            
            let l:Vector2<Float> = point - self.s
            let bounds:(Vector2<Int>, Vector2<Int>, diameter:Int) = 
                UI.bbox(content: self.size, 
                        padding: self.computedStyle.padding, 
                        border: self.computedStyle.border, 
                        radius: self.computedStyle.borderRadius)
            let (a, b, r):(Vector2<Float>, Vector2<Float>, Float) =
            (
                .cast(bounds.0), 
                .cast(bounds.1), 
                .init(bounds.diameter) / 2
            )
            if (a.x ... b.x) ~= l.x, (a.y ... b.y) ~= l.y 
            {
                let q:Vector2<Float>
                //      left           right          top            bottom 
                switch (l.x - a.x < r, b.x - l.x < r, l.y - a.y < r, b.y - l.y < r)
                {
                case (true, false, true, false):
                    q =       a            + r
                case (false, true, true, false):
                    q = .init(b.x - r, a.y + r)
                case (true, false, false, true):
                    q = .init(a.x + r, b.y - r)
                case (false, true, false, true):
                    q =       b            - r
                default:
                    return self 
                }
                // radial test 
                return (l - q) <> (l - q) < r * r ? self : nil 
            }
            else 
            {
                return nil
            }
        }
        //
        
        final 
        func update(_ delta:Int, styles:UI.Styles, viewport _:Vector2<Int>, frame:Rectangle<Int>) 
        {
            self.set(prefix: .init())
            self.postorder 
            {
                (element:UI.Element) in 
                
                element.process(delta)
                element.restyle(styles)
            }
            
            self.reconstrain()
            self.layout(max: frame.size, fonts: styles.fonts)
            self.distribute(at: .cast(frame.a))
        }
        
        /* final override 
        func restyle(definitions:inout UI.Styles, prefix:UI.Style.Path) 
        {
            super.restyle(definitions: &definitions, prefix: prefix)
            let prefix:UI.Style.Path = prefix.appended(self)
            for element:UI.Element in self.elements
            {
                element.restyle(definitions: &definitions, prefix: prefix)
            }
        }
        
        // raise constraint flags 
        final 
        func raiseFlags() -> Bool 
        {
            for element:UI.Element in self.elements 
            {
                if  let block:Block = element as? Block, 
                        block.raiseFlags() 
                {
                    self.recomputeConstraints = .intrinsic
                }
                
                switch (self.recomputeLayout, element.recomputeLayout)
                {
                case (.no, .cosmetic), (.no, .physical), (.cosmetic, .physical):
                    self.recomputeLayout = element.recomputeLayout
                default:
                    break 
                }
            }
            switch self.recomputeConstraints 
            {
            case .no:
                return false 
            case .extrinsic:
                self.recomputeConstraints = .no 
                return true 
            case .intrinsic:
                self.recomputeLayout = .physical
                return true 
            }
        } */
        
        func reconstrain() 
        {
            /* guard self.recomputeConstraints != .no 
            else 
            {
                return 
            } */
            
            self.computedConstraints  = (0, 0)
            // self.recomputeConstraints = .no
        }
        
        func layout(max size:Vector2<Int>, fonts _:UI.Styles.FontLibrary)
        {
            self.size = size 
        }
        
        func distribute(at base:Vector2<Float>) 
        {
            switch self.computedStyle.position 
            {
            case .absolute:
                self.s = self.computedStyle.offset
            case .relative:
                self.s = self.computedStyle.offset + base 
            }
        }
        
        final override
        func draw(_ canvas:UI.Canvas, s _:Vector2<Float>) 
        {
            let shape:UI.Canvas.Geometry = .rectangle(
                at:      self.s,
                content: self.size,
                padding: self.computedStyle.padding, 
                border:  self.computedStyle.border, 
                radius:  self.computedStyle.borderRadius, 
                crease:  self.computedStyle.crease, 
                color:  (self.computedStyle.backgroundColor, self.computedStyle.borderColor))
            
            canvas.geometry(shape)
            
            for element:UI.Element in self.elements 
            {
                element.draw(canvas, s: self.s)
            }
        }
        
        /* final 
        func frame(rectangle:Rectangle<Int>, definitions:inout UI.Styles) 
            -> (text:[UI.Canvas.Text], geometry:[UI.Canvas.Geometry])?
        {
            self.restyle(definitions: &definitions, prefix: .init())
            let _ = self.raiseFlags()
            
            var recompute:Recompute.Layout = self.recomputeLayout
            if  self.recomputeConstraints == .intrinsic
            {
                recompute = .physical
                self.reconstrain()
            }
            if recompute == .physical 
            {
                self.layout(max: rectangle.size, fonts: definitions.fonts)
                self.distribute(at: rectangle.a)
            }
            if recompute != .no 
            {
                var text:[UI.Canvas.Text]         = []
                var geometry:[UI.Canvas.Geometry] = []
                self.draw(canvas, s0: .cast(self.offset)) 
                return (text, geometry)
            }
            else 
            {
                return nil 
            }
        } */

    }
    
    
    class Div:UI.Element.Block 
    {
        var children:[UI.Element.Block]
        
        private 
        var childConstraints:
        (
            emptyMain:Int, 
            elements:[(offset:(main:Int, cross:Int), emptyCross:Int)]
        ) 
        = 
        (
            0, 
            []
        )
        
        override 
        var elements:[UI.Element] 
        {
            self.children as [UI.Element]
        }
        
        init(_ children:[UI.Element.Block], identifier:String? = nil, classes:Set<String> = [], 
            style:UI.Style.Rules = .init()) 
        {
            self.children = children
            super.init(identifier: identifier, classes: classes, style: style)
        }
        
        private 
        enum Region
        {
            case margin(Int), border(Int), padding(Int), content(Int)
            
            var exists:Bool 
            {
                switch self 
                {
                case .margin(let a), .border(let a):
                    return a > 0
                default:
                    return true
                }
            }
            
            var width:Int 
            {
                switch self 
                {
                case    .margin(let width),
                        .border(let width),
                        .padding(let width),
                        .content(let width):
                    return width
                }
            }
            
            static 
            func innermost(margin:Int, border:Int, padding:Int) -> Self 
            {
                if      padding > 0 
                {
                    return .padding(padding)
                }
                else if border > 0 
                {
                    return .border(border)
                }
                else if margin > 0 
                {
                    return .margin(margin)
                }
                else 
                {
                    return .content(0)
                }
            }
            
            static 
            func collapse(begin:Self, middle:[Self], end:Self) -> [Self] 
            {
                // collapse inner 
                var collapsed:[Self] = []
                for region:Self in middle 
                {
                    switch (collapsed.last, region) 
                    {
                    case (.margin(let a)?, .margin(let b)):
                        // let negative margins work 
                        collapsed[collapsed.endIndex - 1] = .margin(b > 0 ? max(a, b) : a + b)
                    case (.border(let a)?, .border(let b)):
                        collapsed[collapsed.endIndex - 1] = .border(max(a, b))
                    default:
                        collapsed.append(region)
                    }
                }
                // collapse outer 
                switch (begin, collapsed.first) 
                {
                case (.margin(let a), .margin(let b)?):
                    collapsed[collapsed.startIndex] = .margin(max(0, b - a))
                case (.border(let a), .border(let b)?):
                    collapsed[collapsed.startIndex] = .border(max(0, b - a))
                default:
                    break 
                }
                switch (collapsed.last, end) 
                {
                case (.margin(let a)?, .margin(let b)):
                    collapsed[collapsed.endIndex - 1] = .margin(max(0, a - b))
                case (.border(let a)?, .border(let b)):
                    collapsed[collapsed.endIndex - 1] = .border(max(0, a - b))
                default:
                    break 
                }
                
                return collapsed
            }
        }
        
        final override  
        func reconstrain() 
        {
            /* guard self.recomputeConstraints != .no 
            else 
            {
                return 
            } */
            
            // update soft layouts for children 
            for block:Block in self.children
            {
                block.reconstrain() 
            }
            
            let axis:UI.Style.Axis = self.computedStyle.axis
            
            let margin:( (main:Int, cross:Int), (main:Int, cross:Int)) = 
                axis.unpack(self.computedStyle.margin),
                border:( (main:Int, cross:Int), (main:Int, cross:Int)) = 
                axis.unpack(self.computedStyle.border),
                padding:((main:Int, cross:Int), (main:Int, cross:Int)) = 
                axis.unpack(self.computedStyle.padding)
            
            let begin:(main:Region, cross:Region) = 
            (
                .innermost(margin: margin.0.main,  border: border.0.main,  padding: padding.0.main), 
                .innermost(margin: margin.0.cross, border: border.0.cross, padding: padding.0.cross)
            )
            let end:(main:Region, cross:Region) = 
            (
                .innermost(margin: margin.1.main,  border: border.1.main,  padding: padding.1.main), 
                .innermost(margin: margin.1.cross, border: border.1.cross, padding: padding.1.cross)
            )
            
            var mains:[Region]                  = [], 
                crosses:[[Region]]              = []
            for block:Block in self.children
            {
                let inner:(axis:UI.Style.Axis, min:(main:Int, cross:Int)) 
                inner.axis = block.computedStyle.axis
                inner.min  = inner.axis.repack(block.computedConstraints, as: axis)
                
                let margin:( (main:Int, cross:Int), (main:Int, cross:Int)) = 
                    axis.unpack(block.computedStyle.margin),
                    border:( (main:Int, cross:Int), (main:Int, cross:Int)) = 
                    axis.unpack(block.computedStyle.border),
                    padding:((main:Int, cross:Int), (main:Int, cross:Int)) = 
                    axis.unpack(block.computedStyle.padding)
                
                let cross:[Region] = 
                [
                    .margin(margin.0.cross),
                    .border(border.0.cross),
                    .padding(padding.0.cross),
                    .content(inner.min.cross),
                    .padding(padding.1.cross),
                    .border(border.1.cross),
                    .margin(margin.1.cross),
                ]
                crosses.append(cross)
                
                mains.append(.margin(margin.0.main))
                mains.append(.border(border.0.main))
                mains.append(.padding(padding.0.main))
                mains.append(.content(inner.min.main))
                mains.append(.padding(padding.1.main))
                mains.append(.border(border.1.main))
                mains.append(.margin(margin.1.main))
            }
            
            var min:(main:Int,   cross:Int)     = (0, 0)
            var emptyMain:Int                   = 0, 
                elements:[(offset:(main:Int, cross:Int), emptyCross:Int)] = []
            var i:Int = 0
            for region:Region in Region.collapse(begin: begin.main, middle: mains, end: end.main)
                where region.exists
            {
                if case .content(let width) = region 
                {
                    defer 
                    {
                        i += 1
                    }
                    
                    var totem:(Int, Int, Int) = (0, 0, 0)
                    for region:Region in Region.collapse(begin: begin.cross, middle: crosses[i], end: end.cross)
                        where region.exists
                    {
                        if case .content(let width) = region 
                        {
                            totem.0  = totem.2
                            totem.1  = width
                            totem.2  = 0
                        }
                        else 
                        {
                            totem.2 += region.width
                        }
                    }
                    
                    elements.append(((emptyMain, totem.0), totem.0 + totem.2))
                    
                    min.main += width
                    min.cross = max(min.cross, totem.0 + totem.1 + totem.2)
                }
                else 
                {
                    emptyMain += region.width 
                    min.main  += region.width
                }
            }
            
            self.computedConstraints  = min
            // self.recomputeConstraints = .no
            
            self.childConstraints = (emptyMain, elements)
        }
        
        // it would be nice if we could avoid recomputing all the margin collapsing, 
        // the the max() operation on the cross-axis makes computation reuse hard 
        final override 
        func layout(max size:Vector2<Int>, fonts:UI.Styles.FontLibrary) 
        {
            let axis:UI.Style.Axis = self.computedStyle.axis
            
            // add up total claims 
            let claims:(main:Float, cross:Float) = 
            (
                max(1, self.children.reduce(0){ $0 + $1.computedStyle.grow }), 
                self.children.reduce(1){    max($0,  $1.computedStyle.stretch) }
            )
            var claimed:Float = 0
            
            let min:(main:Int, cross:Int)       = self.computedConstraints
            let area:(main:Int, cross:Int)      = axis.unpack(size)
            
            var content:(main:Int, cross:[Int]) = (0, [])
                content.main                   += self.childConstraints.emptyMain
            for (block, (_, emptyCross)):(Block, (offset:(main:Int, cross:Int), emptyCross:Int)) in 
                zip(self.children, self.childConstraints.elements)
            {
                // believe it or not, the order of the repacking axes is irrelevant
                let inner:(axis:UI.Style.Axis, min:(main:Int, cross:Int)) 
                inner.axis = block.computedStyle.axis
                inner.min  = inner.axis.repack(block.computedConstraints, as: axis)
                let available:(main:Float, cross:Float) = 
                (
                    .init(area.main  - min.main), 
                    .init(area.cross - inner.min.cross - emptyCross)
                )
                
                let grow:(main:Float, cross:Float) = 
                (
                    block.computedStyle.grow,
                    block.computedStyle.stretch
                )
                // calculate flex space
                let flex:(main:Int, cross:Int) = 
                (
                     .init((claimed + grow.main) / claims.main  * available.main) - 
                     .init( claimed              / claims.main  * available.main) , 
                     .init(           grow.cross / claims.cross * available.cross)
                )
                claimed += grow.main 
                
                let max:Vector2<Int> = axis.pack((inner.min.main + flex.main, inner.min.cross + flex.cross))
                block.layout(max: max, fonts: fonts)
                
                let size:(main:Int, cross:Int) = axis.unpack(block.size)
                
                content.main += size.main 
                
                content.cross.append(size.cross + emptyCross)
            }
            
            let size:(main:Int, cross:Int) = 
            (
                max(content.main,             area.main), 
                max(content.cross.max() ?? 0, area.cross)
            )
            
            self.size = axis.pack(size)
        }
        
        final override 
        func distribute(at base:Vector2<Float>) 
        {
            super.distribute(at: base)
            
            let axis:UI.Style.Axis = self.computedStyle.axis
            
            let size:(main:Int, cross:Int) = axis.unpack(self.size)
            
            var free:(main:Int, cross:Int)
            free.main = size.main - self.childConstraints.emptyMain 
            for block:Block in self.children 
            {
                let (main, _):(Int, Int) = axis.unpack(block.size)
                free.main -= main 
            }
            
            var advance:Int = 0
            for ((offset, emptyCross), (i, block)):((offset:(main:Int, cross:Int), emptyCross:Int), (Int, Block)) in 
                zip(self.childConstraints.elements, self.children.enumerated())
            {
                let (main, cross):(Int, Int) = axis.unpack(block.size)
                
                free.cross = size.cross - emptyCross - cross 
                
                let space:(main:Int, cross:Int)
                switch self.computedStyle.justify 
                {
                case .start:
                    space.main = 0 
                case .end:
                    space.main = free.main 
                case .center:
                    space.main = free.main / 2
                case .spaceBetween:
                    space.main = .init(Double.init(free.main) * Double.init(i) / Double.init(self.children.count - 1))
                case .spaceAround:
                    space.main = .init(Double.init(free.main) * Double.init(i * 2 + 1) / Double.init(2 * self.children.count))
                case .spaceEvenly:
                    space.main = .init(Double.init(free.main) * Double.init(i * 2 + 2) / Double.init(2 * self.children.count + 2))
                }
                switch (block.computedStyle.alignSelf, self.computedStyle.align) 
                {
                case (.start, _),   (.auto, .start):
                    space.cross = 0 
                case (.end, _),     (.auto, .end):
                    space.cross = free.cross 
                case (.center, _),  (.auto, .center),  (.auto, .auto):
                    space.cross = free.cross / 2
                }
                
                let position:(main:Int, cross:Int) = 
                (
                    offset.main  + space.main + advance,
                    offset.cross + space.cross
                )
                
                block.distribute(at: self.s + .cast(axis.pack(position)))
                
                advance += main 
            }
        }
    }
    
    // unidirectional boolean event handling 
    class Button:UI.Element.Div 
    {
        override
        var cursor:(inactive:UI.Cursor, active:UI.Cursor) 
        {
            (.hand, .hand)
        }
        
        final private 
        var value:Bool = false 
        
        override 
        func action(_ action:UI.Event.Action)
        {
            super.action(action)
            switch action 
            {
            case .complete:
                self.value = true 
            default:
                break
            }
        }
        
        func communicate<Root>(_ path:ReferenceWritableKeyPath<Root, Bool>, to root:Root) 
        {
            if self.value 
            {
                if !root[keyPath: path]
                {
                    root[keyPath: path] = true 
                }
                self.value = false 
            }
        }
    }
    
    // bidirectional boolean event handling
    class StickyButton:UI.Element.Div 
    {
        private 
        enum Value 
        {
            case off, on, submit, cancel
        }
        
        final private
        var value:Value = .off
        
        override
        var cursor:(inactive:UI.Cursor, active:UI.Cursor) 
        {
            (.hand, .hand)
        }
        
        override
        var pseudoclasses:Set<UI.Style.PseudoClass> 
        {
            var pseudoclasses:Set<UI.Style.PseudoClass> = super.pseudoclasses
            if case .on = self.value
            {
                pseudoclasses.insert(.indicating)
            }
            return pseudoclasses
        }
        
        override 
        func action(_ action:UI.Event.Action)
        {
            super.action(action)
            switch action 
            {
            case .complete:
                switch self.value 
                {
                case .off, .cancel:
                    self.value = .submit 
                case .on, .submit:
                    self.value = .cancel
                }
            default:
                break
            }
        }
        
        func communicate<Root>(_ path:ReferenceWritableKeyPath<Root, Bool>, to root:Root) 
        {
            switch self.value 
            {
            case .off: 
                if root[keyPath: path]
                {
                    // state of value is true, so we make sure the stickybutton reflects that 
                    self.value = .on
                }
            case .on:
                if !root[keyPath: path]
                {
                    // state of value is false, so we return the stickybutton to the inactive state
                    self.value = .off
                }
            case .submit:
                if !root[keyPath: path]
                {
                    // push event to value 
                    root[keyPath: path] = true 
                }
                self.value = .on
            case .cancel:
                if root[keyPath: path]
                {
                    // push cancellation to value 
                    root[keyPath: path] = false 
                }
                self.value = .off 
            }
        }
    }
}


extension UI.Element  
{
    final 
    class Span:UI.Element
    {
        fileprivate 
        var reshape:Bool = true 
        var text:String
        {
            willSet(new) 
            {
                if new != self.text 
                {
                    self.reshape = true
                }
            }
        }
        
        override 
        var computedStyle:UI.Style.Rules 
        {
            willSet(new)
            {
                if  new.font        != self.computedStyle.font      ||
                    new.features    != self.computedStyle.features  
                {
                    self.reshape = true
                }
            }
        }
        
        var vertices:[(s:Vector2<Float>, t:Vector2<Float>)] = []
        
        var description:String 
        {
            "<Span>\(self.text)</Span>"
        }
        
        init(_ text:String, identifier:String? = nil, classes:Set<String> = [], 
            style:UI.Style.Rules = .init()) 
        {
            self.text = text 
            super.init(identifier: identifier, classes: classes, style: style)
        }
        
        final override 
        func draw(_ canvas:UI.Canvas, s:Vector2<Float>) 
        {
            super.draw(canvas, s: s)
            
            canvas.text(.init(
                vertices:   self.vertices, 
                s0:         self.computedStyle.offset + s, 
                r0:         self.computedStyle.trace,
                color:      self.computedStyle.color))
        }
    }
    
    class P:UI.Element.Block
    {
        var spans:[UI.Element.Span]
        
        private 
        var reshape:Bool = true 
        var description:String 
        {
            "<P>\n\(self.elements.compactMap{ ($0 as? Span)?.description }.joined(separator: "\n"))\n</P>"
        }
        
        override 
        var computedStyle:UI.Style.Rules 
        {
            willSet(new)
            {
                if  new.wrap       != self.computedStyle.wrap      ||
                    new.indent     != self.computedStyle.indent    ||
                    new.lineHeight != self.computedStyle.lineHeight
                {
                    self.reshape = true
                }
            }
        }
        
        override 
        var elements:[UI.Element] 
        {
            self.spans as [UI.Element]
        }
        
        init(_ spans:[Span], identifier:String? = nil, classes:Set<String> = [], 
            style:UI.Style.Rules = .init()) 
        {
            self.spans = spans 
            super.init(identifier: identifier, classes: classes, style: style)
        }
        
        /* override 
        func event(_ event:UI.Event, pass _:Int, response:inout UI.Event.Response) -> Bool
        {
            switch event 
            {
            case .character(let character):
                self.spans[1].text.append(character)
                return .consumed 
            
            case .paste(let string):
                self.spans[1].text += string
                return .consumed
            default:
                return .unconsumed
            }
        } */
        
        override 
        func layout(max size:Vector2<Int>, fonts:UI.Styles.FontLibrary) 
        {
            let spans:[Span] = self.elements.compactMap{ $0 as? Span }
            guard self.size != size || self.reshape || spans.contains(where: \.reshape)
            else  
            {
                return 
            }
            
            // fill in shaping parameters 
            let texts:[String] = spans.map{ $0.text }
            let parameters:[HarfBuzz.ShapingParameters] = spans.map 
            {
                let margin:UI.Style.Metrics<Int> = $0.computedStyle.margin
                let parameters:HarfBuzz.ShapingParameters = 
                    .init(
                        font: fonts[$0.computedStyle.font], 
                        features: $0.computedStyle.features, 
                        letterspacing: $0.computedStyle.letterSpacing, 
                        margin: (margin.left, margin.right)
                    )
                return parameters
            }
            
            let cx:Int = self.computedStyle.indent
            let dy:Int = self.computedStyle.lineHeight
            if self.computedStyle.wrap
            {
                // no concept of 2D grid layout, new lines just reset the x coordinate to 0 (or indent)
                let (glyphs, indices):([HarfBuzz.Glyph], (runs:[Range<Int>], lines:[Range<Int>])) = 
                    HarfBuzz.paragraph(zip(texts, parameters), 
                        indent: cx, 
                        width: size.x << 6)
                // line number, should start at 0
                var l:Int = indices.lines.startIndex
                for ((span, font), range):((Span, Typeface.Font), Range<Int>) in 
                    zip(zip(spans, parameters.map{ $0.font }), indices.runs) 
                {
                    var vertices:[(s:Vector2<Float>, t:Vector2<Float>)] = []
                        vertices.reserveCapacity(range.count * 2)
                    for (i, g):(Int, HarfBuzz.Glyph) in zip(range, glyphs[range])
                    {
                        while !(indices.lines[l] ~= i) 
                        {
                            l += 1
                        }
                        
                        let sort:Typeface.Font.SortInfo = font.sorts[g.index]
                        // convert 64-point fractional units to ints to floats 
                        let p:Vector2<Int> = g.position &+ .init(0, (l + 1) * dy) &<< 6, 
                            a:Vector2<Int> = sort.vertices.a &+ p, 
                            b:Vector2<Int> = sort.vertices.b &+ p
                        
                        let s:Rectangle<Float> = .init(.cast(a &>> 6), .cast(b &>> 6)), 
                            t:Rectangle<Float> = fonts.atlas[sort.sprite]
                        vertices.append((s: s.a, t: t.a))
                        vertices.append((s: s.b, t: t.b))
                    }
                    
                    span.vertices = vertices
                }
                
                self.size = .init(size.x, indices.lines.count * dy)
            }
            else 
            {
                let (glyphs, indices, width):([HarfBuzz.Glyph], [Range<Int>], Int) = 
                    HarfBuzz.line(zip(texts, parameters))
                for ((span, font), range):((Span, Typeface.Font), Range<Int>) in 
                    zip(zip(spans, parameters.map{ $0.font }), indices) 
                {
                    var vertices:[(s:Vector2<Float>, t:Vector2<Float>)] = []
                        vertices.reserveCapacity(range.count * 2)
                    for g:HarfBuzz.Glyph in glyphs[range]
                    {
                        let sort:Typeface.Font.SortInfo = font.sorts[g.index]
                        let p:Vector2<Int> = g.position &+ .init(0, dy) &<< 6
                        let s:Rectangle<Float> = .init(
                            .cast((sort.vertices.a &+ p) &>> 6), 
                            .cast((sort.vertices.b &+ p) &>> 6)
                        )
                        let t:Rectangle<Float> = fonts.atlas[sort.sprite]
                        vertices.append((s: s.a, t: t.a))
                        vertices.append((s: s.b, t: t.b))
                    }
                    
                    span.vertices = vertices
                }
                
                self.size = .init(width &>> 6, dy)
            }
        }
    }
}
