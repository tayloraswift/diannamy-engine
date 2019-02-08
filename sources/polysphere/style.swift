struct Style 
{
    struct Definitions 
    {
        enum Feature 
        {
            case kern(Bool)
            case calt(Bool)
            case liga(Bool)
            case hlig(Bool)
            case `case`(Bool)
            case cpsp(Bool)
            case smcp(Bool)
            case pcap(Bool)
            case c2sc(Bool)
            case c2pc(Bool)
            case unic(Bool)
            case ordn(Bool)
            case zero(Bool)
            case frac(Bool)
            case afrc(Bool)
            case sinf(Bool)
            case subs(Bool)
            case sups(Bool)
            case ital(Bool)
            case mgrk(Bool)
            case lnum(Bool)
            case onum(Bool)
            case pnum(Bool)
            case tnum(Bool)
            case rand(Bool)
            case salt(Int)
            case swsh(Int)
            case titl(Bool)
        }
        
        enum Font:Int, CaseIterable
        {
            case mono55_12
             
            case text55_12
            case text56_12
            
            case text75_12
            case text76_12
            
            var face:Face 
            {
                switch self 
                {
                case .mono55_12:
                    return .mono55
                case .text55_12:
                    return .text55 
                case .text56_12:
                    return .text56 
                case .text75_12:
                    return .text75 
                case .text76_12:
                    return .text76 
                }
            }
            
            var size:Int 
            {
                switch self 
                {
                case    .mono55_12, 
                        .text55_12, 
                        .text56_12,
                        .text75_12, 
                        .text76_12:
                    return 18
                }
            }
        }
        
        enum Face 
        {
            case mono55 
            
            case text55 
            case text56
            case text75 
            case text76
        }
        
        struct Rule<Properties>
        {
            private 
            let selectors:Set<Selector>, 
                properties:Properties
            
            init(_ selectors:Set<Selector>, _ properties:Properties) 
            {
                self.selectors  = selectors 
                self.properties = properties 
            }
            
            func select(accordingTo selectors:Set<Selector>) -> Properties?
            {
                return self.selectors.isSubset(of: selectors) ? self.properties : nil 
            }
            
            static 
            func collapse<T>(_ properties:[Properties], keyPath:KeyPath<Properties, T?>) -> T?
            {
                var value:T? = nil 
                for properties:Properties in properties 
                {
                    value = properties[keyPath: keyPath] ?? value 
                }
                
                return value 
            }
        }
        
        struct Block 
        {
            struct Computed 
            {
                let lineheight:Int
            }
            
            let lineheight:Int? 
            
            init(lineheight:Int? = nil) 
            {
                self.lineheight = lineheight
            }
        }
        
        struct Inline 
        {
            struct Computed 
            {
                let font:Typeface.Font, 
                    features:[Feature], 
                    color:Math<UInt8>.V4
            }
            
            let font:Font?, 
                features:[Feature]?, 
                color:Math<UInt8>.V4?
            
            init(font:Font? = nil, features:[Feature]? = nil, color:Math<UInt8>.V4? = nil) 
            {
                self.font       = font 
                self.features   = features 
                self.color      = color
            }
        }
        
        private(set)
        var atlas:Atlas 
        private 
        var fonts:[Typeface.Font]
        
        private 
        var inlineRules:[Rule<Inline>] = 
        [
            .init([.paragraph], 
            .init(
                font:       .text55_12, 
                features:   [.kern(true), .onum(true), .liga(true), .calt(true)], 
                color:      (.max, .max, .max, .max)
            )), 
            
            .init([.paragraph, .emphasis], 
            .init(
                font:       .text56_12
            )), 
            
            .init([.paragraph, .strong], 
            .init(
                font:       .text75_12
            )), 
            
            .init([.paragraph, .emphasis, .strong], 
            .init(
                font:       .text76_12
            )), 
        ]
        
        private 
        var blockRules:[Rule<Block>] = 
        [
            .init([.paragraph], 
            .init(
                lineheight: 18
            ))
        ]
            
        subscript(font selector:Font) -> Typeface.Font
        {
            return self.fonts[selector.rawValue]
        }
        
        init(faces specifications:[Face: (String, Int)] = [:]) 
        {
            var fallback:Typeface? = nil 
            let typefaces:[Face: (Typeface, Int)] = specifications.compactMapValues
            {
                (specification:(String, Int)) in 
                
                return Typeface.init(specification.0).map 
                {
                    ($0, specification.1)
                }
            }
            
            let unassembled:[Typeface.Font.Unassembled] = Font.allCases.map
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
            for unassembled:Typeface.Font.Unassembled in unassembled
            {
                let base:Int = bitmaps.endIndex 
                bitmaps.append(contentsOf: unassembled.bitmaps)
                indices.append(base ..< bitmaps.endIndex) 
            }
            
            self.atlas = .init(bitmaps)
            self.fonts = zip(unassembled, indices).map 
            {
                return .init($0.0, indices: $0.1)
            }
        }
        
        func compute(inline selectors:Set<Selector>) -> Inline.Computed 
        {
            let styles:[Inline] = self.inlineRules.compactMap 
            {
                $0.select(accordingTo: selectors)
            }
            
            let font:Definitions.Font           = Rule.collapse(styles, keyPath: \.font)     ?? .mono55_12, 
                features:[Definitions.Feature]  = Rule.collapse(styles, keyPath: \.features) ?? [], 
                color:Math<UInt8>.V4            = Rule.collapse(styles, keyPath: \.color)    ?? (.max, .max, .max, .max)
            
            return .init(font: self[font: font], features: features, color: color)
        }
        
        func compute(block selectors:Set<Selector>) -> Block.Computed 
        {
            let styles:[Block] = self.blockRules.compactMap 
            {
                $0.select(accordingTo: selectors)
            }
            
            let lineheight:Int = Rule.collapse(styles, keyPath: \.lineheight) ?? 20
            
            return .init(lineheight: lineheight)
        }
    }
    
    enum Selector 
    {
        case paragraph 
        
        case emphasis 
        case strong 
    }
}
