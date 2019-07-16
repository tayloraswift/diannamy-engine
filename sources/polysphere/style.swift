struct Style 
{
    struct Definitions 
    {
        
        
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
                    color:Vector4<UInt8>
            }
            
            let font:Font?, 
                features:[Feature]?, 
                color:Vector4<UInt8>?
            
            init(font:Font? = nil, features:[Feature]? = nil, color:Vector4<UInt8>? = nil) 
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
                color:      .init(repeating: .max)
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
            
            
            .init([.mapeditor, .label], 
            .init(
                font:       .text55_12, 
                features:   [.kern(true), .onum(true), .tnum(true)], 
                color:      .init(255, 0, 0, .max)
            )), 
            .init([.mapeditor, .label, .strong], 
            .init(
                font:       .text75_12
            )), 
            
            .init([.mapeditor, .label, .move], 
            .init(
                color:      .init(255, 153, 0, .max)
            )), 
            .init([.mapeditor, .label, .new], 
            .init(
                color:      .init(77, 51, 255, .max)
            )), 
            .init([.mapeditor, .label, .preselection], 
            .init(
                color:      .init(255, 0, 255, .max)
            ))
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
            let typefaces:[Face: (Typeface, Int)] = specifications.compactMapValues
            {
                (specification:(String, Int)) in 
                
                return Typeface.init(specification.0).map 
                {
                    ($0, specification.1)
                }
            }
            
            (self.atlas, self.fonts) = Typeface.Font.assemble(Font.allCases, from: typefaces)
        }
        
        func compute(inline selectors:Set<Selector>) -> Inline.Computed 
        {
            let styles:[Inline] = self.inlineRules.compactMap 
            {
                $0.select(accordingTo: selectors)
            }
            
            let font:Definitions.Font           = Rule.collapse(styles, keyPath: \.font)     ?? .mono55_12, 
                features:[Definitions.Feature]  = Rule.collapse(styles, keyPath: \.features) ?? [], 
                color:Vector4<UInt8>            = Rule.collapse(styles, keyPath: \.color)    ?? .init(repeating: .max)
            
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
        
        func line(_ runs:[(Set<Selector>, String)]) -> Text
        {
            let computed:[(Inline.Computed, String)] = runs.map 
            {
                (self.compute(inline: $0.0), $0.1)
            }
            
            return Text.line(computed, atlas: self.atlas)
        }
        func paragraph(_ runs:[(Set<Selector>, String)], linebox:Vector2<Int>, block:Set<Selector> = []) -> Text
        {
            let computed:[(Inline.Computed, String)] = runs.map 
            {
                (self.compute(inline: $0.0.union(block)), $0.1)
            }
            
            return Text.paragraph(computed, linebox: linebox, atlas: self.atlas)
        }
    }
    
    enum Selector 
    {
        case paragraph 
        case mapeditor 
        
        case emphasis 
        case strong 
        
        case label 
        case selection 
        case preselection
        case move 
        case new 
    }
}
