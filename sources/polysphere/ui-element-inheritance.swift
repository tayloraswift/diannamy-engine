extension UI 
{
    enum DrawElement 
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
            let s0:Vector2<Float>, 
                r0:Vector3<Float>, 
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
        }
        
        struct Geometry:RandomAccessCollection
        {
            typealias Triangle = (Int, Int, Int)
            
            struct Vertex:GPU.Vertex.Structured
            {
                // screen coordinates (pixels)
                let s:(Float, Float) 
                // implicit parameters 
                let hb:(Float, Float)
                // tracer coordinates
                let r:(Float, Float, Float)
                // implicit parameters 
                let hr:Float 
                // color horizontal(inner, outer), vertical(inner, outer)
                let c:
                (
                    ((UInt8, UInt8, UInt8, UInt8), (UInt8, UInt8, UInt8, UInt8)),
                     (UInt8, UInt8, UInt8, UInt8)
                )
                // implicit coordinates 
                let i:(UInt8, UInt8)
                
                static 
                var attributes:[GPU.Vertex.Attribute<Self>] = 
                [
                        .float32x2(\.s,     as: .float32),
                        .float32x2(\.hb,    as: .float32),
                        .float32x3(\.r,     as: .float32),
                        .float32(  \.hr,    as: .float32),
                        .uint8x4(  \.c.0.0, as: .float32(normalized: true)),
                        .uint8x4(  \.c.0.1, as: .float32(normalized: true)),
                        .uint8x4(  \.c.1,   as: .float32(normalized: true)),
                        .uint8x2(  \.i,     as: .float32(normalized: false)),
                ] 
            }
            
            // 3D tracing is disabled using a (.nan, .nan, .nan) triple
            // screen coordinates (pixels), color 
            let vertices:
            [(
                s:Vector2<Float>, 
                hb:Vector2<Float>, 
                hr:Float,
                c:((Vector4<UInt8>, Vector4<UInt8>), Vector4<UInt8>),
                i:Vector2<UInt8>
            )] 
            let triangles:[Triangle]
            let s0:Vector2<Float>, 
                r0:Vector3<Float> 
            
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
                let (s, hb, hr, c, i):
                (
                    s:Vector2<Float>, 
                    hb:Vector2<Float>, 
                    hr:Float,
                    c:((Vector4<UInt8>, Vector4<UInt8>), Vector4<UInt8>),
                    i:Vector2<UInt8>
                ) 
                (s, hb, hr, c, i) = self.vertices[index]
                return .init(
                    s: (self.s0 + s).tuple, 
                    hb: hb.tuple,
                    r: (self.r0    ).tuple, 
                    hr: hr, 
                    c: ((c.0.0.tuple, c.0.1.tuple), c.1.tuple),
                    i: (          i).tuple) 
            }
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
        
        final 
        var elements:[UI.Element]
        
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
        //
        
        init(identifier:String?, classes:Set<String>, style:UI.Style.Rules)
        {
            self.classes    = classes 
            self.identifier = identifier
            self.style      = style
            
            self.path       = .init()
            
            self.elements   = []
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
        
        func contribute(
            text     _:inout [UI.DrawElement.Text], 
            geometry _:inout [UI.DrawElement.Geometry], 
            s        _:Vector2<Float>) 
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
            let (a, b, r):(Vector2<Float>, Vector2<Float>, Float) = 
                self.boundingBox(  padding: self.computedStyle.padding, 
                                    border: self.computedStyle.border, 
                                    radius: self.computedStyle.borderRadius)
            
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
        func contribute(
            text    :inout [UI.DrawElement.Text], 
            geometry:inout [UI.DrawElement.Geometry], 
            s      _:Vector2<Float>) 
        {    
            let r:Vector3<Float>         = self.computedStyle.trace
            
            let bg:Vector4<UInt8>        = self.computedStyle.backgroundColor, 
                bd:Vector4<UInt8>        = self.computedStyle.borderColor
            let padding:UI.Style.Metrics = self.computedStyle.padding
            let border:UI.Style.Metrics  = self.computedStyle.border
            
            let color:
            (
                lt:(Vector4<UInt8>, Vector4<UInt8>), 
                rt:(Vector4<UInt8>, Vector4<UInt8>), 
                lb:(Vector4<UInt8>, Vector4<UInt8>), 
                rb:(Vector4<UInt8>, Vector4<UInt8>)
            ) = 
            (
                (bd, bd),
                (bd, bd),
                (bd, bd),
                (bd, bd)
            )
            
            let a:(Vector2<Float>, Vector2<Float>), 
                b:(Vector2<Float>, Vector2<Float>) 
            
            // outer edges of border box
            let radius:Float
            (a.0, b.1, radius) = self.boundingBox(padding: padding, border: border, radius: self.computedStyle.borderRadius)
            
            let d:(top:Float, right:Float, bottom:Float, left:Float) = 
            (
                max(radius, .init(border.top)),
                max(radius, .init(border.right)),
                max(radius, .init(border.bottom)),
                max(radius, .init(border.left))
            )
            // inset edges
            a.1 = a.0 + .init(d.left, d.top)
            b.0 = b.1 - .init(d.right, d.bottom)
            
            let vertices:
            [(
                s:Vector2<Float>, 
                hb:Vector2<Float>, 
                hr:Float,
                c:((Vector4<UInt8>, Vector4<UInt8>), Vector4<UInt8>),
                i:Vector2<UInt8>
            )] =
            [
                (.init(a.0.x, a.0.y), .cast(.init(border.left,  border.top)),    radius, (color.lt, bg), .init(1, 1)),
                (.init(a.1.x, a.0.y), .cast(.init(border.left,  border.top)),    radius, (color.lt, bg), .init(0, 1)),
                (.init(b.0.x, a.0.y), .cast(.init(border.right, border.top)),    radius, (color.rt, bg), .init(0, 1)),
                (.init(b.1.x, a.0.y), .cast(.init(border.right, border.top)),    radius, (color.rt, bg), .init(1, 1)),
                
                (.init(a.0.x, a.1.y), .cast(.init(border.left,  border.top)),    radius, (color.lt, bg), .init(1, 0)),
                (.init(a.1.x, a.1.y), .cast(.init(border.left,  border.top)),    radius, (color.lt, bg), .init(0, 0)),
                (.init(b.0.x, a.1.y), .cast(.init(border.right, border.top)),    radius, (color.rt, bg), .init(0, 0)),
                (.init(b.1.x, a.1.y), .cast(.init(border.right, border.top)),    radius, (color.rt, bg), .init(1, 0)),
                
                (.init(a.0.x, b.0.y), .cast(.init(border.left,  border.bottom)), radius, (color.lb, bg), .init(1, 0)),
                (.init(a.1.x, b.0.y), .cast(.init(border.left,  border.bottom)), radius, (color.lb, bg), .init(0, 0)),
                (.init(b.0.x, b.0.y), .cast(.init(border.right, border.bottom)), radius, (color.rb, bg), .init(0, 0)),
                (.init(b.1.x, b.0.y), .cast(.init(border.right, border.bottom)), radius, (color.rb, bg), .init(1, 0)),
                
                (.init(a.0.x, b.1.y), .cast(.init(border.left,  border.bottom)), radius, (color.lb, bg), .init(1, 1)),
                (.init(a.1.x, b.1.y), .cast(.init(border.left,  border.bottom)), radius, (color.lb, bg), .init(0, 1)),
                (.init(b.0.x, b.1.y), .cast(.init(border.right, border.bottom)), radius, (color.rb, bg), .init(0, 1)),
                (.init(b.1.x, b.1.y), .cast(.init(border.right, border.bottom)), radius, (color.rb, bg), .init(1, 1)),
            ]
            
            //  0   1           2   3
            //  4   5           6   7
            // 
            //  8   9          10  11
            // 12  13          14  15
            let triangles:[(Int, Int, Int)] = 
            [
                ( 0,  4,  5),   // ◣
                ( 0,  5,  1),   // ◥
                
                ( 1,  5,  6),   // ◣
                ( 1,  6,  2),   // ◥
                
                ( 2,  6,  7),   // ◣
                ( 2,  7,  3),   // ◥
                
                ( 4,  8,  9),   // ◣
                ( 4,  9,  5),   // ◥
                
                ( 5,  9, 10),   // ◣
                ( 5, 10,  6),   // ◥
                
                ( 6, 10, 11),   // ◣
                ( 6, 11,  7),   // ◥
                
                ( 8, 12, 13),   // ◣
                ( 8, 13,  9),   // ◥
                
                ( 9, 13, 14),   // ◣
                ( 9, 14, 10),   // ◥
                
                (10, 14, 15),   // ◣
                (10, 15, 11),   // ◥
            ]
            
            geometry.append(.init(vertices: vertices, triangles: triangles, s0: self.s, r0: r))
            
            for element:UI.Element in self.elements 
            {
                element.contribute(text: &text, geometry: &geometry, s: self.s)
            }
        }
        
        /* final 
        func frame(rectangle:Rectangle<Int>, definitions:inout UI.Styles) 
            -> (text:[UI.DrawElement.Text], geometry:[UI.DrawElement.Geometry])?
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
                var text:[UI.DrawElement.Text]         = []
                var geometry:[UI.DrawElement.Geometry] = []
                self.contribute(text: &text, geometry: &geometry, s0: .cast(self.offset)) 
                return (text, geometry)
            }
            else 
            {
                return nil 
            }
        } */
        
        private 
        func boundingBox(padding:UI.Style.Metrics, border:UI.Style.Metrics, radius:Int) 
            -> (Vector2<Float>, Vector2<Float>, radius:Float) 
        {
            // outer edges of border box
            let a:Vector2<Float>    = .cast(.init(-padding.left  - border.left,   -padding.top    - border.top)),
                b:Vector2<Float>    = .cast(.init( padding.right + border.right,   padding.bottom + border.bottom) &+ self.size) 
            let area:Vector2<Float> = b - a
            let radius:Float        = min((min(area.x, area.y) / 2).rounded(.down), .init(radius))
            return (a, b, radius)
        }
    }
    
    
    class Div:UI.Element.Block 
    {
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
        
        init(_ children:[UI.Element.Block], identifier:String? = nil, classes:Set<String> = [], 
            style:UI.Style.Rules = .init()) 
        {
            super.init(identifier: identifier, classes: classes, style: style)
            self.elements = children
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
            let children:[Block] = self.elements.compactMap{ $0 as? Block }
            /* guard self.recomputeConstraints != .no 
            else 
            {
                return 
            } */
            
            // update soft layouts for children 
            for block:Block in children
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
            for block:Block in children
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
            let children:[Block]   = self.elements.compactMap{ $0 as? Block }
            let axis:UI.Style.Axis = self.computedStyle.axis
            
            // add up total claims 
            let claims:(main:Float, cross:Float) = 
            (
                max(1, children.reduce(0){ $0 + $1.computedStyle.grow }), 
                children.reduce(1){    max($0,  $1.computedStyle.stretch) }
            )
            var claimed:Float = 0
            
            let min:(main:Int, cross:Int)       = self.computedConstraints
            let area:(main:Int, cross:Int)      = axis.unpack(size)
            
            var content:(main:Int, cross:[Int]) = (0, [])
                content.main                   += self.childConstraints.emptyMain
            for (block, (_, emptyCross)):(Block, (offset:(main:Int, cross:Int), emptyCross:Int)) in 
                zip(children, self.childConstraints.elements)
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
            
            let size:(main:Int, cross:Int) 
            // TODO: WHAT??
            if (children.contains{ $0.identifier == "container" } )
            {
                size = area
            }  
            else 
            {
                size = 
                (
                    max(content.main,             area.main), 
                    max(content.cross.max() ?? 0, area.cross)
                )
            }
            
            self.size = axis.pack(size)
        }
        
        final override 
        func distribute(at base:Vector2<Float>) 
        {
            super.distribute(at: base)
            let children:[Block] = self.elements.compactMap{ $0 as? Block }
            
            let axis:UI.Style.Axis = self.computedStyle.axis
            
            let size:(main:Int, cross:Int) = axis.unpack(self.size)
            
            var free:(main:Int, cross:Int)
            free.main = size.main - self.childConstraints.emptyMain 
            for block:Block in children 
            {
                let (main, _):(Int, Int) = axis.unpack(block.size)
                free.main -= main 
            }
            
            var advance:Int = 0
            for ((offset, emptyCross), (i, block)):((offset:(main:Int, cross:Int), emptyCross:Int), (Int, Block)) in 
                zip(self.childConstraints.elements, children.enumerated())
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
                    space.main = .init(Double.init(free.main) * Double.init(i) / Double.init(children.count - 1))
                case .spaceAround:
                    space.main = .init(Double.init(free.main) * Double.init(i * 2 + 1) / Double.init(2 * children.count))
                case .spaceEvenly:
                    space.main = .init(Double.init(free.main) * Double.init(i * 2 + 2) / Double.init(2 * children.count + 2))
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
    
    class Button:UI.Element.Div 
    {
        override
        var cursor:(inactive:UI.Cursor, active:UI.Cursor) 
        {
            (.hand, .hand)
        }
        
        final 
        var click:Int = 0
        
        init(label:String, identifier:String? = nil, classes:Set<String> = [], 
            style:UI.Style.Rules = .init()) 
        {
            let label:UI.Element.P = .init([.init(label)])
            super.init([label], identifier: identifier, classes: classes, style: style)
        }
        
        override 
        func action(_ action:UI.Event.Action)
        {
            super.action(action)
            switch action 
            {
            case .complete:
                self.click &+= 1
            default:
                break
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
            willSet 
            {
                self.reshape = true
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
        func contribute(
            text    :inout [UI.DrawElement.Text], 
            geometry:inout [UI.DrawElement.Geometry], 
            s       :Vector2<Float>) 
        {
            super.contribute(text: &text, geometry: &geometry, s: s)
            
            text.append(.init(
                vertices:   self.vertices, 
                s0:         self.computedStyle.offset + s, 
                r0:         self.computedStyle.trace,
                color:      self.computedStyle.color))
        }
    }
    
    class P:UI.Element.Block
    {
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
        
        init(_ spans:[Span], identifier:String? = nil, classes:Set<String> = [], 
            style:UI.Style.Rules = .init()) 
        {
            super.init(identifier: identifier, classes: classes, style: style)
            self.elements = spans 
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
                let margin:UI.Style.Metrics = $0.computedStyle.margin
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
