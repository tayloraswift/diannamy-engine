protocol _UIStyleSheetEnumeration:Hashable
{
    static 
    var type:UI.Style.Sheet.Parse.Expression.Keyword 
    {
        get
    }
    
    init?(string:String)
}

extension UI.Style 
{
    enum Sheet 
    {
        typealias Enumeration = _UIStyleSheetEnumeration
        
        enum Error:RecursiveError 
        {
            typealias Location = (line:Int, column:Int)
            
            static 
            var namespace:String 
            {
                "stylesheet error"
            }
            
            case source(name:String, error:Swift.Error?)
            case syntax(name:String, source:String, error:Swift.Error)
            
            func unpack() -> (String, Swift.Error?)
            {
                switch self 
                {
                case .source(name: let name, error: let error):
                    return ("failed to load source(s) for stylesheet '\(name)'", error)
                
                case .syntax(name: let name, source: let source, error: let error):
                    switch error 
                    {
                    case let error as Lex.Error:
                        let location:Location = Self.location(of: error.index, in: source)
                        let snippet:String = Self.snippet((location, location), in: source)
                        return ("\(name):\(location.line + 1):\(location.column + 1): syntax error\n\(snippet)", error)
                    
                    case let error as Parse.Error:
                        let indices:Range<String.Index> = error.indices 
                        let range:(Location, Location) = 
                        (
                            Self.location(of: indices.lowerBound, in: source), 
                            Self.location(of: indices.upperBound, in: source)
                        )
                        let snippet:String = Self.snippet(range, in: source)
                        return ("\(name):\(range.0.line + 1):\(range.0.column + 1): syntax error\n\(snippet)", error)
                    
                    default:
                        return ("\(name): parser error", error)
                    }
                }
            }
            
            private static 
            func location(of index:String.Index, in string:String) -> Location
            {
                var location:Location = (0, 0)
                for (c, character):(String.Index, Character) in zip(string.indices, string) 
                {
                    if c == index 
                    {
                        break 
                    }
                    
                    if character.isNewline 
                    {
                        location.line   += 1
                        location.column  = 0
                    }
                    else 
                    {
                        location.column += 1
                    }
                }
                return location
            }
            
            private static 
            func snippet(_ range:(Location, Location), in string:String) -> String 
            {
                let text:Substring = string.split(separator: "\n", 
                    omittingEmptySubsequences: false)[range.0.line]
                let width:Int 
                if range.0.line == range.1.line 
                {
                    width = range.1.column - range.0.column
                }
                else 
                {
                    width = text.count - range.0.column
                }
                
                let (blank, caret, highlight):(String, String, String) = 
                (
                    .init(repeatElement(" ", count: range.0.column)), 
                    "^", 
                    .init(repeatElement("~", count: max(0, width - 1)))
                )
                return "    \(Log.Highlight.fg(.gray))\(text)\(Log.Highlight.reset)\n    \(blank)\(Log.Highlight.bold)\(Log.Highlight.fg(.red))\(caret)\(highlight)\(Log.Highlight.reset)"
            }
        }
        
        enum Lex 
        {
            enum Literal 
            {
                case numeric 
                
                var prosaicDescription:String 
                {
                    switch self 
                    {
                    case .numeric:
                        return "numeric"
                    }
                }
            }
            
            enum Error:RecursiveError 
            {
                static 
                var namespace:String 
                {
                    "stylesheet lexing error"
                }
                
                case unexpected(Character, at:String.Index)
                case cast(String, from:Literal, to:[Any.Type], at:String.Index)
                
                func unpack() -> (String, Swift.Error?)
                {
                    switch self 
                    {
                    case .unexpected(let character, at: _):
                        return ("unexpected character '\(character)'", nil)
                    case .cast(let literal, from: let source, to: let types, at: _):
                        let destination:String 
                        switch types.count 
                        {
                        case Int.min ... 0:
                            destination = "_"
                        case 1:
                            destination = "\(types[0])"
                        case 2:
                            destination = "\(types[0]) or \(types[1])"
                        case _:
                            destination = "\(types.dropLast().map{ "\($0)" }.joined(separator: ", ")), or \(types[types.endIndex - 1])"
                        }
                        return ("cannot convert \(source.prosaicDescription) literal '\(literal)' to \(destination)", nil)
                    }
                }
                
                var index:String.Index 
                {
                    switch self 
                    {
                    case    .unexpected(_, at: let index), 
                            .cast(_, from: _, to: _, at: let index):
                        return index
                    }
                }
            }
            
            enum Lexeme:Equatable, CustomStringConvertible
            {
                case identifier(String)
                case bool(Bool)
                case int(Int)
                case float(Float)
                case string(String)
                case comment(String)
                case parenthesisLeft, parenthesisRight
                case braceLeft, braceRight 
                case divide 
                case minus 
                case comma 
                case period 
                case colon 
                case chevron
                case star
                case hashtag
                case at
                case newline
                case whitespace 
                
                enum Partial 
                {
                    case identifier(String)
                    case minus 
                    case slash 
                    case number(String)
                    case string(String, quote:Character?, escape:Bool)
                    case comment(String)
                    case punctuation(Character)
                    case whitespace
                    
                    private static 
                    func begin(_ character:Character, at index:String.Index) throws -> Self 
                    {
                        if character.isLetter || character == "_"
                        {
                            return .identifier(.init(character))
                        }
                        else if let ascii:UInt8 = character.asciiValue, 
                            0x30 ... 0x39 ~= ascii 
                        {
                            return .number("\(character)")
                        }
                        else if character.isNewline 
                        {
                            return .punctuation("\n")
                        }
                        switch character 
                        {
                        case "'":
                            return .string("", quote: "'", escape: false)
                        case "\"":
                            return .string("", quote: "\"", escape: false)
                        case "-":
                            return .minus 
                        case "/":
                            return .slash
                        case "(", ")", "{", "}", ",", ".", ":", ">", "*", "#", "@":
                            return .punctuation(character)
                        case " ", "\t":
                            return .whitespace
                        default:
                            throw Error.unexpected(character, at: index)
                        }
                    }
                    
                    mutating 
                    func append(_ character:Character, at index:String.Index) throws -> Lexeme?
                    {
                        atom: 
                        switch self 
                        {
                        case .identifier(var identifier):
                            if character.isLetter || character.isNumber || character == "_"
                            {
                                identifier.append(character)
                                self = .identifier(identifier)
                                return nil 
                            }
                        
                        case .number(var literal):
                            switch character
                            {
                            case "b":
                                guard literal.contains("x") 
                                else 
                                {
                                    fallthrough
                                }
                            case "o", "x":
                                guard   literal == "0" || literal == "-0"
                                else 
                                {
                                    break atom 
                                }
                            
                            case ".":
                                guard   literal.last?.isHexDigit ?? false
                                else 
                                {
                                    break atom 
                                }
                            
                            case "e":
                                guard   literal.last?.isHexDigit ?? false, 
                                        !literal.contains("b"),
                                        !literal.contains("o")
                                else 
                                {
                                    break atom 
                                }
                                
                            
                            case "p":
                                guard   literal.last?.isHexDigit ?? false, 
                                        literal.contains("x")
                                else 
                                {
                                    break atom 
                                }
                            
                            case "_":
                                guard   literal.last?.isHexDigit ?? false
                                else 
                                {
                                    break atom 
                                }
                            
                            case "a",      "c", "d",      "f", "A", "B", "C", "D", "E", "F":
                                guard literal.contains("x") 
                                else 
                                {
                                    break atom 
                                }
                            case "8", "9":
                                guard !literal.contains("o") 
                                else 
                                {
                                    break atom 
                                }
                                fallthrough
                            case "2", "3", "4", "5", "6", "7":
                                guard !literal.contains("b") 
                                else 
                                {
                                    break atom 
                                }
                                fallthrough
                            
                            case "0", "1":
                                break 
                            
                            case "-":
                                guard (literal.last.map{ $0 == "e" || $0 == "p" }) ?? false 
                                else 
                                {
                                    break atom 
                                } 
                            
                            default:
                                break atom 
                            }
                            
                            literal.append(character)
                            self = .number(literal)
                            return nil 
                        
                        case .string(var string, quote: let quote?, escape: let escape):
                            if !escape 
                            {
                                switch character 
                                {
                                case "\\":
                                    self = .string(string, quote: quote, escape: true)
                                    return nil 
                                
                                case quote:
                                    self = .string(string, quote: nil, escape: false)
                                    return nil
                                
                                default:
                                    break 
                                }
                            }
                            
                            string.append(character)
                            self = .string(string, quote: quote, escape: false)
                            return nil 
                        case .string(var string, quote: nil, escape: let escape):
                            break atom 
                        
                        case .comment(var comment):
                            switch character 
                            {
                            case "\n":
                                break atom 
                            default:
                                comment.append(character)
                                self = .comment(comment) 
                                return nil 
                            }
                        
                        case .minus, .slash, .punctuation(_):
                            break atom 
                        
                        case .whitespace:
                            // cannot use `.isWhitespace` property bc it matches 
                            // newlines.
                            if character == " " || character == "\t" 
                            {
                                return nil 
                            }
                        }
                        
                        let next:Self = try .begin(character, at: index)
                        switch (self, next) 
                        {
                        case    (.punctuation, .identifier), 
                                (.whitespace, .identifier):
                            break // ok 
                        case    (_, .identifier):
                            throw Error.unexpected(character, at: index)
                        
                        case    (.minus, .number(let literal)):
                            self = .number("-\(literal)")
                            return nil 
                        
                        case    (.slash, .slash):
                            self = .comment("")
                            return nil 
                        
                        default:
                            break // ok 
                        }
                        
                        defer 
                        {
                            self = next 
                        }
                        
                        switch self 
                        {
                        case .identifier(let identifier):
                            switch identifier 
                            {
                            case "true":
                                return .bool(true)
                            case "false":
                                return .bool(false)
                            default:
                                return .identifier(identifier)
                            }
                        
                        case .comment(let comment):
                            return .comment(comment)
                        
                        case .number(let literal):
                            let compact:String = .init(literal.filter{ $0 != "_" })
                            if      let value:Int   = Int.init(compact)
                            {
                                return .int(value)
                            }
                            else if let value:Float = Float.init(compact)
                            {
                                return .float(value)
                            }
                            else 
                            {
                                throw Error.cast(literal, from: .numeric, to: [Int.self, Float.self], at: index)
                            }
                        
                        case    .string(let string, quote: nil, escape: false):
                            return .string(string)
                        
                        case    .string(_, quote: nil, escape: true), 
                                .string(_, quote: _?, escape: _):
                            Log.unreachable()
                        
                        case .punctuation(let p):
                            switch p 
                            {
                            case "(":
                                return .parenthesisLeft 
                            case ")":
                                return .parenthesisRight 
                            case "{":
                                return .braceLeft 
                            case "}":
                                return .braceRight 
                            case ",":
                                return .comma 
                            case ".":
                                return .period 
                            case ":":
                                return .colon 
                            case ">":
                                return .chevron 
                            case "*":
                                return .star 
                            case "#":
                                return .hashtag 
                            case "@":
                                return .at 
                            case "\n":
                                return .newline
                            default:
                                return nil 
                            }
                        
                        case .slash:
                            return .divide 
                        case .minus:
                            return .minus
                        case .whitespace:
                            return .whitespace
                        }
                    }
                }
                
                var description:String 
                {
                    switch self 
                    {
                    case .identifier(let identifier):
                        return identifier
                    case .bool(let value):
                        return "<\(value)>"
                    case .int(let value):
                        return "<\(value)>"
                    case .float(let value):
                        return "<\(value)>"
                    case .string(let string):
                        return "'\(string)'"
                    case .comment(let comment):
                        return "/* \(comment) */"
                    case .parenthesisLeft:
                        return "<LPAREN>"
                    case .parenthesisRight:
                        return "<RPAREN>"
                    case .braceLeft:
                        return "<LBRACE>"
                    case .braceRight:
                        return "<RBRACE>"
                    case .divide:
                        return "<DIVIDE>"
                    case .minus:
                        return "<MINUS>"
                    case .comma:
                        return "<COMMA>"
                    case .period:
                        return "<PERIOD>"
                    case .colon:
                        return "<COLON>"
                    case .chevron:
                        return "<CHEVRON>"
                    case .star:
                        return "<STAR>"
                    case .hashtag:
                        return "<HASHTAG>"
                    case .at:
                        return "<AT>"
                    case .newline:
                        return "<NEWLINE>"
                    case .whitespace:
                        return "."
                    }
                }
                var prosaicDescription:String 
                {
                    switch self 
                    {
                    case .identifier(let identifier):
                        return "identifier '\(identifier)'"
                    case .bool(let value):
                        return "boolean value '\(value)'"
                    case .int(let value):
                        return "integer \(value)"
                    case .float(let value):
                        return "floating-point value \(value)"
                    case .string(let string):
                        return "string '\(string)'"
                    case .comment(let comment):
                        return "comment '\(comment)'"
                    case .parenthesisLeft:
                        return "'('"
                    case .parenthesisRight:
                        return "')'"
                    case .braceLeft:
                        return "'{'"
                    case .braceRight:
                        return "'}'"
                    case .divide:
                        return "'/'"
                    case .minus:
                        return "'-'"
                    case .comma:
                        return "','"
                    case .period:
                        return "'.'"
                    case .colon:
                        return "':'"
                    case .chevron:
                        return "'>'"
                    case .star:
                        return "'*'"
                    case .hashtag:
                        return "'#'"
                    case .at:
                        return "'@'"
                    case .newline:
                        return "newline"
                    case .whitespace:
                        return "' '"
                    }
                }
                
                static 
                func load(identifier lexeme:Self) -> String? 
                {
                    switch lexeme
                    {
                    case .identifier(let identifier):
                        return identifier
                    default:
                        return nil 
                    }
                }
                static 
                func load(bool lexeme:Self) -> Bool? 
                {
                    switch lexeme
                    {
                    case .bool(let value):
                        return value
                    default:
                        return nil 
                    }
                }
                static 
                func load(int lexeme:Self) -> Int? 
                {
                    switch lexeme
                    {
                    case .int(let value):
                        return value
                    default:
                        return nil 
                    }
                }
                static 
                func load(float lexeme:Self) -> Float? 
                {
                    switch lexeme
                    {
                    case .int(let value):
                        return .init(value)
                    case .float(let value):
                        return value
                    default:
                        return nil 
                    }
                }
                static 
                func load(string lexeme:Self) -> String? 
                {
                    switch lexeme
                    {
                    case .string(let string):
                        return string
                    default:
                        return nil 
                    }
                }
            }
            
            static 
            func lex(_ string:String) throws -> [(Range<String.Index>, Lexeme)]
            {
                let string:String = string + " "
                var lexemes:[(Range<String.Index>, Lexeme)] = []
                var pending:(start:String.Index, state:Lexeme.Partial) = (string.startIndex, .whitespace)
                for (c, character):(String.Index, Character) in zip(string.indices, string) 
                {
                    if let lexeme:Lexeme = try pending.state.append(character, at: c)
                    {
                        lexemes.append((pending.start ..< c, lexeme))
                        pending.start = c 
                    }
                }
                
                return lexemes
            }
            
            static 
            func highlight(_ lexemes:[(range:Range<String.Index>, lexeme:Lex.Lexeme)], in source:String) 
                -> String 
            {
                return lexemes.map 
                {
                    (token:(range:Range<String.Index>, lexeme:Lex.Lexeme)) in 
                    
                    let text:Substring = source[token.range]
                    let highlight:String 
                    switch token.lexeme 
                    {
                    case .identifier, .star:
                        highlight = "\(Log.Highlight.bg(.white))\(Log.Highlight.fg(.black))\(Log.Highlight.bold)\(text)\(Log.Highlight.reset)"
                    case .bool:
                        highlight = "\(Log.Highlight.bg(.blue))\(text)\(Log.Highlight.reset)"
                    case .int, .float:
                        highlight = "\(Log.Highlight.bg(.indigo))\(text)\(Log.Highlight.reset)"
                    case .string:
                        highlight = "\(Log.Highlight.bg(.red))\(text)\(Log.Highlight.reset)"
                    case .comment:
                        highlight = "\(Log.Highlight.bg(.darkGray))\(text)\(Log.Highlight.reset)"
                    case .whitespace:
                        highlight = "\(text)"
                    case .newline:
                        highlight = "\(Log.Highlight.fg(.cyan))↵\(text)\(Log.Highlight.reset)"
                    default:
                        highlight = "\(Log.Highlight.bg(.purple))\(Log.Highlight.fg(.black))\(text)\(Log.Highlight.reset)"
                    }
                    
                    return highlight
                }.joined(separator: "")
            }
        }
        enum Parse 
        {
            enum Expression 
            {
                enum Keyword 
                {
                    case element, property, feature, positioning, alignment, colortype
                    
                    var prosaicDescription:String 
                    {
                        switch self 
                        {
                        case .element:
                            return "element type"
                        case .property:
                            return "stylesheet property"
                        case .feature:
                            return "font feature"
                        case .positioning:
                            return "positioning mode"
                        case .alignment:
                            return "alignment mode"
                        case .colortype:
                            return "color type"
                        }
                    }
                }
                
                case selector 
                case combinator 
                case rules
                case rule 
                
                indirect 
                case value(Property, Self?)
                
                case keyword(Keyword)
                case bool, int, float, string, color
                
                indirect 
                case tuple(Int, Self)
                
                indirect 
                case metrics(Self)
                case rawcolor
                
                var prosaicDescription:String 
                {
                    switch self 
                    {
                    case .selector:
                        return "selector expression"
                    case .combinator: 
                        return "selector combinator expression"
                    case .rules:
                        return "stylesheet rules block"
                    case .rule:
                        return "stylesheet rule"
                        
                    case .keyword(let keyword):
                        return keyword.prosaicDescription
                    
                    case .bool:
                        return "boolean"
                    case .int:
                        return "integer"
                    case .float:
                        return "floating-point"
                    case .string:
                        return "string"
                    case .color:
                        return "color"
                    
                    case .tuple(let count, let type):
                        return "\(type.prosaicDescription) \(count)-tuple"
                    
                    case .metrics(let type):
                        return "\(type.prosaicDescription) metrics expression"
                    case .rawcolor:
                        return "floating-point raw color expression"
                        
                    case .value(let property, let expected):
                        return "\(property.prosaicDescription) expression\(expected.map{ ", expected \($0.prosaicDescription) literal" } ?? "")"
                    }
                }
            }
            
            enum Error:RecursiveError 
            {
                static 
                var namespace:String 
                {
                    "stylesheet parsing error"
                }
                
                case undefined(Expression.Keyword, String, in:Expression, range:Range<String.Index>)
                case duplicate(Lex.Lexeme, in:Expression, range:Range<String.Index>)
                case unexpected(Lex.Lexeme?, in:Expression, range:Range<String.Index>)
                case missing(Lex.Lexeme, before:Lex.Lexeme, in:Expression, range:Range<String.Index>)
                case other(String, range:Range<String.Index>)
                
                func unpack() -> (String, Swift.Error?)
                {
                    switch self 
                    {
                    case .undefined(let type, let identifier, in: let expression, range: _):
                        return ("'\(identifier)' is not a valid \(type.prosaicDescription) in \(expression.prosaicDescription)", nil)
                    
                    case .duplicate(let lexeme,     in: let expression, range: _):
                        return ("duplicate \(lexeme.prosaicDescription) in \(expression.prosaicDescription)", nil)
                    case .unexpected(let lexeme?,   in: let expression, range: _):
                        return ("unexpected \(lexeme.prosaicDescription) in \(expression.prosaicDescription)", nil)
                    case .unexpected(nil,           in: let expression, range: _):
                        return ("unexpected end of stylesheet while parsing \(expression.prosaicDescription)", nil)
                    
                    case .missing(let expected, before: let lexeme, in: let expression, range: _):
                        return ("missing \(expected.prosaicDescription) before \(lexeme.prosaicDescription) in \(expression.prosaicDescription)", nil)
                    case .other(let message, range: _):
                        return (message, nil)
                    }
                }
                
                var indices:Range<String.Index> 
                {
                    switch self 
                    {
                    case    .undefined(_, _, in: _,         range: let range), 
                            .duplicate(_, in: _,            range: let range), 
                            .unexpected(_, in: _,           range: let range), 
                            .missing(_, before: _, in: _,   range: let range), 
                            .other(_,                       range: let range):
                        return range
                    }
                }
            }
            
            private 
            struct Buffer 
            {
                private 
                let lexemes:[(range:Range<String.Index>, lexeme:Lex.Lexeme)], 
                    end:String.Index
                private 
                var index:Int
                
                private 
                var next:(range:Range<String.Index>, lexeme:Lex.Lexeme?)
                {
                    guard self.index < self.lexemes.endIndex 
                    else 
                    {
                        return (self.end ..< self.end, nil)
                    }
                    
                    return self.lexemes[self.index]
                }
                
                private mutating 
                func advance() 
                {
                    self.index += 1
                }
                
                init?(_ lexemes:[(range:Range<String.Index>, lexeme:Lex.Lexeme)])
                {
                    guard let end:String.Index = lexemes.last?.0.upperBound 
                    else 
                    {
                        return nil 
                    }
                    
                    // strip comments 
                    self.lexemes    = lexemes.filter
                    { 
                        if case .comment(_) = $0.lexeme 
                        {
                            return false 
                        }
                        return true
                    }
                    self.end        = end 
                    self.index      = lexemes.startIndex
                }
                
                // parsing functions 
                mutating 
                func selector() throws -> Selector.Pattern?
                {

                    enum State 
                    {
                        enum Component 
                        {
                            case `class`, identifier
                        }
                        
                        // text foo.bar.baz 
                        // ~~~~ ^
                        case startHead(first:Bool)
                        
                        // text foo.bar.baz
                        // ~~~~~~~~^
                        case startBodyComponent
                        
                        // text foo.bar.baz 
                        // ~~~~~~~~~^
                        case expectBodyComponent(Component)
                    }
                    
                    var levels:[(vector:Bool, level:Selector.Level)] = []
                    var vector:Bool = true, 
                        level:Selector.Level = .any
                    var state:State = .startHead(first: true)
                    
                    while true 
                    {
                        let (range, lexeme):(Range<String.Index>, Lex.Lexeme?) = self.next
                        
                        switch (state, lexeme) 
                        {
                        case    (.startHead,            .identifier("text")?):
                            level.element = UI.Text.self 
                            state = .startBodyComponent
                        
                        case    (.startHead,            .identifier(let identifier)?):
                            throw Error.undefined(.element, identifier, in: .selector, range: range)
                            
                        case    (.startHead,            .star?):
                            state = .startBodyComponent
                        
                        case    (.startHead,            .period?), 
                                (.startBodyComponent,   .period?):
                            state = .expectBodyComponent(.class)
                        
                        case    (.startBodyComponent,   .hashtag?):
                            guard level.identifier == nil 
                            else 
                            {
                                throw Error.duplicate(.hashtag, in: .selector, range: range)
                            }
                            fallthrough
                        case    (.startHead,            .hashtag?):
                            state = .expectBodyComponent(.identifier)
                        
                        case    (.startHead,            .chevron?):
                            guard vector 
                            else 
                            {
                                throw Error.duplicate(.chevron, in: .combinator, range: range)
                            }
                            
                            vector = false 
                        
                        case    (.startHead,            .whitespace?), 
                                (.startHead,            .newline?):
                            break 
                        
                        
                        case    (.startBodyComponent,   .whitespace?), 
                                (.startBodyComponent,   .newline?):
                            levels.append((vector, level))
                            vector = true 
                            level  = .any 
                            
                            state = .startHead(first: false)
                        
                        case    (.startBodyComponent,   .chevron?):
                            throw Error.missing(.whitespace, before: .chevron, in: .selector, range: range)
                        
                        
                        case    (.expectBodyComponent(.class),      .identifier(let identifier)?):
                            level.classes.update(with: identifier)
                            state = .startBodyComponent
                    
                        case    (.expectBodyComponent(.identifier), .identifier(let identifier)?):
                            level.identifier = identifier
                            state = .startBodyComponent
                        
                        // exit paths and failure conditions 
                        case    (.startBodyComponent,               .braceLeft?), 
                                (.startBodyComponent,               nil):
                            levels.append((vector, level))
                            fallthrough
                        case    (.startHead(first: false),          _):
                            return .init(levels: levels)
                        
                        case    (.startHead(first: true),          nil):
                            return nil 
                        case    (.startHead(first: true),          .braceLeft?):
                            throw Error.other("\(Expression.selector.prosaicDescription) cannot be empty, use the `*` selector to match all elements", range: range)
                        
                        // `{` is the only character that can occur immediately after 
                        // a selector expression without whitespace 
                        case    (.startHead(first: true),           let lexeme?), 
                                (.startBodyComponent,               let lexeme?), 
                                (.expectBodyComponent(_),           let lexeme?):
                            throw Error.unexpected(lexeme, in: .selector, range: range)
                        
                        case    (.expectBodyComponent(_),           nil):
                            throw Error.unexpected(nil,    in: .selector, range: range)
                        }
                        
                        self.advance()
                    }
                }
                
                mutating 
                func rules() throws -> [Property: Any]
                {
                    // ...
                    try self.consumeWhitespaceAndNewlines()
                    // {
                    try self.expect(expression: .rules){ $0 == .braceLeft }
                    
                    var properties:[Property: Any] = [:]
                    while true 
                    {
                        // ...
                        try self.consumeWhitespaceAndNewlines()
                        // } (?)
                        switch self.next.lexeme 
                        {
                        case .braceRight?:
                            self.advance()
                            return properties
                        default:
                            break
                        }
                        
                        // foo
                        let range:Range<String.Index> = self.next.range
                        let name:String = try self.expect(expression: .rules, where: Lex.Lexeme.load(identifier:))
                        guard let property:Property = Property.init(name) 
                        else 
                        {
                            throw Error.undefined(.property, name, in: .rules, range: range)
                        }
                        
                        // ...
                        try self.consumeWhitespaceAndNewlines()
                        // :
                        try self.expect(expression: .rule){ $0 == .colon }
                        // ...
                        try self.consumeWhitespaceAndNewlines()
                        
                        // <value>
                        let value:Any = try self.value(property)
                        properties[property] = value 
                        
                        // ...
                        try self.consumeWhitespace()
                        // catch closing '}' on the same line 
                        switch self.next.lexeme 
                        {
                        // } (?)
                        case .braceRight?:
                            continue 
                        // \n 
                        case .newline?:
                            self.advance()
                            continue 
                        
                        case let lexeme:
                            throw Error.unexpected(lexeme, in: .rule, range: self.next.range)
                        }
                    }
                }
                
                private mutating 
                func value(_ property:Property) throws -> Any 
                {
                    switch property 
                    {
                    case .wrap:
                        let value:Bool = try self.expect(expression: .value(property, .bool), 
                            where: Lex.Lexeme.load(bool:)) 
                        return value 
                    
                    case .indent, .line_height:
                        let value:Int = try self.expect(expression: .value(property, .int), 
                            where: Lex.Lexeme.load(int:)) 
                        return value 
                    
                    case .padding:
                        let v:[Int] = try self.vector(1 ..< 5, expression: .value(property, .metrics(.int)), 
                            innerExpression: .metrics(.int), 
                            whereElement: Lex.Lexeme.load(int:)) 
                                                
                        let value:Metrics 
                        switch v.count 
                        {
                        case 1:
                            value = .init(v[0])
                        case 2:
                            value = .init(vertical: v[0], horizontal: v[1])
                        case 3:
                            value = .init(top: v[0], horizontal: v[1], bottom: v[2])
                        case 4:
                            value = .init(top: v[0], right: v[1], bottom: v[2], left: v[3])
                        default:
                            Log.unreachable()
                        }
                        return value 
                    
                    case .color:
                        return try self.color(property: property)
                    
                    case .trace:
                        let value:Vector3<Float>
                        switch self.next.lexeme 
                        {
                        // none ?
                        case .identifier("none")?:
                            self.advance()
                            value = .init(.nan, .nan, .nan)
                        default:
                            let vector:[Float] = try self.tuple(3, expression: .value(property, .tuple(3, .float)),
                                innerExpression: .tuple(3, .float), 
                                whereElement: Lex.Lexeme.load(float:)) 
                            value = .init(vector[0], vector[1], vector[2])
                        }
                        
                        return value 
                    
                    case .offset:
                        let vector:[Float] = try self.tuple(2, expression: .value(property, .tuple(2, .float)),
                            innerExpression: .tuple(2, .float), 
                            whereElement: Lex.Lexeme.load(float:))
                        let value:Vector2<Float> = .init(vector[0], vector[1])
                        return value 
                    
                    case .font:
                        // 'foo'
                        let fontfile:String = try self.expect(expression: .value(property, .string), 
                            where: Lex.Lexeme.load(string:))
                        // ...
                        try self.consumeWhitespaceAndNewlines()
                        // @
                        try self.expect(expression: .value(property, nil)){ $0 == .at }
                        // ...
                        try self.consumeWhitespaceAndNewlines()
                        // 16
                        let size:Int = try self.expect(expression: .value(property, .int), 
                            where: Lex.Lexeme.load(int:)) 
                        let fontSelection:FontSelection = .init(fontfile: fontfile, size: size)
                        return fontSelection
                    
                    case .features:
                        var features:[Feature] = []
                        list:
                        while true 
                        {
                            // kern 
                            let range:Range<String.Index> = self.next.range
                            let string:String = try self.expect(expression: .value(property, .keyword(.feature)), 
                                where: Lex.Lexeme.load(identifier:)) 
                            // ... 
                            // cannot have newline between font feature name and 
                            // opening `(`.
                            try self.consumeWhitespace()
                            
                            let value:Int
                            // ( ?
                            switch self.next.lexeme 
                            {
                            case .parenthesisLeft?:
                                self.advance()
                                // ... 
                                try self.consumeWhitespaceAndNewlines()
                                
                                switch self.next.lexeme 
                                {
                                // true ?
                                case .bool(let boolean)?:
                                    value = boolean ? 1 : 0
                                // 1 ?
                                case .int(let integer)?:
                                    value = integer 
                                case let lexeme:
                                    throw Error.unexpected(lexeme, in: .keyword(.feature), range: self.next.range)
                                }
                                self.advance()
                                
                                // ... 
                                try self.consumeWhitespaceAndNewlines()
                                // )
                                try self.expect(expression: .keyword(.feature)){ $0 == .parenthesisRight }
                                // ... 
                                try self.consumeWhitespace()
                                
                            default:
                                value = 1
                            }
                            
                            guard let feature:Feature = Feature.init(string: string, value: value) 
                            else 
                            {
                                throw Error.undefined(.feature, string, in: .value(property, nil), range: range)
                            }
                            
                            features.append(feature)
                            
                            // , ?
                            switch self.next.lexeme 
                            {
                            case .comma?:
                                self.advance()
                                // ... 
                                try self.consumeWhitespaceAndNewlines()
                            default:
                                break list 
                            }
                        }
                        
                        return features
                    
                    case .position:
                        return try self.enumeration(as: Positioning.self, expression: .value(property, nil))
                    
                    case .align:
                        return try self.enumeration(as: Alignment.self, expression: .value(property, nil))
                    }
                }
                
                private mutating 
                func color(property:Property) throws -> Vector4<Float> 
                {
                    let value:Vector4<Float>
                    switch self.next.lexeme 
                    {
                    // rgb ?
                    case .identifier("rgb")?:
                        self.advance()
                        try self.consumeWhitespaceAndNewlines()
                        let vector:[Int] = try self.tuple(3, expression: .value(property, .tuple(3, .int)), 
                            innerExpression: .tuple(3, .int), 
                            whereElement: Lex.Lexeme.load(int:)) 
                        
                        let factor:Float = .init(UInt8.max)
                        value = .init(
                            .init(vector[0]) / factor, 
                            .init(vector[1]) / factor, 
                            .init(vector[2]) / factor, 
                            1)
                    
                    case .identifier("rgba")?:
                        self.advance()
                        try self.consumeWhitespaceAndNewlines()
                        let vector:[Int] = try self.tuple(4, expression: .value(property, .tuple(4, .int)), 
                            innerExpression: .tuple(4, .int), 
                            whereElement: Lex.Lexeme.load(int:)) 
                        
                        let factor:Float = .init(UInt8.max)
                        value = .init(
                            .init(vector[0]) / factor, 
                            .init(vector[1]) / factor, 
                            .init(vector[2]) / factor, 
                            .init(vector[3]) / factor)
                    
                    case .identifier(let string)?:
                        throw Error.undefined(.colortype, string, in: .value(property, nil), range: self.next.range)
                    
                    default:
                        let v:[Float] = try self.vector(1 ..< 5, expression: .value(property, .rawcolor), 
                            innerExpression: .rawcolor, 
                            whereElement: Lex.Lexeme.load(float:)) 
                                                
                        switch v.count 
                        {
                        case 1:
                            value = .init(v[0], v[0], v[0], 1)
                        case 2:
                            value = .init(v[0], v[0], v[0], v[1])
                        case 3:
                            value = .init(v[0], v[1], v[2], 1)
                        case 4:
                            value = .init(v[0], v[1], v[2], v[3])
                        default:
                            Log.unreachable()
                        }
                    }
                    return value 
                }
                
                private mutating  
                func tuple<Element>(_ count:Int, expression:Expression, innerExpression:Expression, 
                    whereElement predicate:(Lex.Lexeme) throws -> Element?) throws -> [Element] 
                {
                    // (
                    try self.expect(expression: expression){ $0 == .parenthesisLeft }
                    
                    let values:[Element] = try (0 ..< count).map 
                    {
                        index in 
                        
                        // ...
                        try self.consumeWhitespaceAndNewlines()
                        
                        // diagnose premature )
                        switch self.next.lexeme 
                        {
                        case .parenthesisRight?:
                            throw Error.other("expected tuple of length \(count), but only parsed \(index) elements", range: self.next.range)
                        default:
                            break
                        }
                        
                        if index != 0 
                        {
                            // ,
                            try self.expect(expression: innerExpression) 
                            {
                                switch $0 
                                {
                                case .comma:
                                    return true 
                                default:
                                    return false 
                                }
                            }
                            // ...
                            try self.consumeWhitespaceAndNewlines()
                        }
                        
                        return try self.expect(expression: innerExpression, where: predicate)
                    }
                    // ...
                    try self.consumeWhitespaceAndNewlines()
                    // )
                    try self.expect(expression: innerExpression){ $0 == .parenthesisRight }
                    
                    return values 
                }
                
                private mutating 
                func vector<Element>(_ constraints:Range<Int>, expression:Expression, innerExpression:Expression, 
                    whereElement predicate:(Lex.Lexeme) throws -> Element?) throws -> [Element] 
                {
                    var elements:[Element] = []
                    while true 
                    {
                        switch self.next.lexeme 
                        {
                        // \n ?
                        case .newline, nil:
                            guard elements.count >= constraints.lowerBound
                            else 
                            {
                                throw Error.unexpected(self.next.lexeme, in: innerExpression, range: self.next.range)
                            }
                            return elements 
                        
                        case let lexeme?:
                            guard elements.count < constraints.upperBound
                            else 
                            {
                                throw Error.unexpected(lexeme, in: innerExpression, range: self.next.range)
                            }
                            break 
                        }
                        
                        // E
                        elements.append(try self.expect(expression: 
                            elements.isEmpty ? expression : innerExpression, where: predicate))
                        // ...
                        try self.consumeWhitespace()
                    }
                }
                
                private mutating 
                func enumeration<E>(as _:E.Type, expression:Expression) throws -> E where E:Enumeration 
                {
                    let range:Range<String.Index> = self.next.range
                    let string:String = try self.expect(expression: expression, 
                        where: Lex.Lexeme.load(identifier:))
                                        
                    guard let enumeration:E = E.init(string: string) 
                    else 
                    {
                        throw Error.undefined(E.type, string, in: expression, range: range)
                    }
                    return enumeration
                }
                
                private mutating  
                func expect<R>(expression:Expression, 
                    where predicate:(Lex.Lexeme) throws -> R?) throws -> R
                {
                    let (range, lexeme):(Range<String.Index>, Lex.Lexeme?) = self.next
                    if  let lexeme:Lex.Lexeme = lexeme, 
                        let value:R           = try predicate(lexeme)
                    {
                        self.advance()
                        return value
                    }
                    
                    throw Error.unexpected(lexeme, in: expression, range: range)
                }
                private mutating  
                func expect(expression:Expression, 
                    where predicate:(Lex.Lexeme) throws -> Bool) throws 
                {
                    let _:Void = try self.expect(expression: expression) 
                    {
                        try predicate($0) ? () : nil 
                    }
                }
                
                private mutating 
                func consume(where predicate:(Lex.Lexeme) throws -> Bool) throws
                {
                    while true 
                    {
                        let (_, dereference):(Range<String.Index>, Lex.Lexeme?) = self.next
                        if  let lexeme:Lex.Lexeme = dereference, 
                            try predicate(lexeme)
                        {
                            self.advance()
                        }
                        else 
                        {
                            return 
                        }
                    }
                }
                private mutating 
                func consumeWhitespaceAndNewlines() throws
                {
                    try self.consume{ $0 == .whitespace || $0 == .newline }
                }
                private mutating 
                func consumeWhitespace() throws
                {
                    try self.consume{ $0 == .whitespace }
                }
            }
            
            static 
            func stylesheet(_ lexemes:[(Range<String.Index>, Lex.Lexeme)]) throws
            {
                guard var buffer:Buffer = Buffer.init(lexemes)
                else 
                {
                    return 
                }
                
                var styles:[(Selector.Pattern, [Property: Any])] = []
                while let selector:Selector.Pattern = try buffer.selector()
                {
                    styles.append((selector, try buffer.rules()))
                }
                print(styles.map{ "\($0.0)\n\($0.1)" }.joined(separator: "\n\n"))
            }
            
            static 
            func selector(_ lexemes:[(Range<String.Index>, Lex.Lexeme)]) throws
                -> Selector.Pattern 
            {
                guard   var buffer:Buffer = Buffer.init(lexemes), 
                        let selector:Selector.Pattern = try buffer.selector()
                else 
                {
                    throw Sheet.Error.source(name: "<anonymous>", error: nil)
                }
                
                return selector 
            }
            
        }
        
        static 
        func parse(path:String) throws 
        {
            let source:String
            do 
            {
                source = .init(decoding: try File.read(path), as: Unicode.UTF8.self)
            }
            catch
            {
                throw Error.source(name: path, error: error)
            }
            
            let lexemes:[(range:Range<String.Index>, lexeme:Lex.Lexeme)] 
            do 
            {
                lexemes = try Lex.lex(source)
            }
            catch 
            {
                throw Error.syntax(name: path, source: source, error: error)
            }
            
            print(Lex.highlight(lexemes, in: source))
            
            do 
            {
                try Parse.stylesheet(lexemes)
            }
            catch 
            {
                throw Error.syntax(name: path, source: source, error: error)
            }
        }
        
        // useful for debugging, generates Selector and Selector.Pattern values 
        // from string representation
        static 
        func parse(selectorPattern:String) throws -> Selector.Pattern
        {
            do 
            {
                let lexemes:[(range:Range<String.Index>, lexeme:Lex.Lexeme)] = 
                    try Lex.lex(selectorPattern)
                return try Parse.selector(lexemes)
            }
            catch 
            {
                throw Error.syntax(name: "<anonymous>", source: selectorPattern, error: error)
            }
        }
    }
}

extension UI 
{
    struct Style 
    {
        private 
        let fonts:[FontSelection: Typeface.Font]
        let atlas:Atlas 
        
        private 
        var cache:
        (
            inline:[Selector: (sequence:UInt, style:Inline)],
            block:[Selector: (sequence:UInt, style:Block)]
        )
            
        private 
        let stack:
        (
            inline:[(pattern:Selector.Pattern, rules:Rules.Inline)], 
            block: [(pattern:Selector.Pattern, rules:Rules.Block )]
        ) = 
        (
            [
                (
                    "text", 
                    .init(
                        color:      .init(repeating: .max), 
                        font:       .init(fontfile: "assets/fonts/SourceSansPro-Regular.ttf", size: 16), 
                        features:  [.kern(true), .onum(true), .liga(true), .calt(true)]
                    )
                ), 
                (
                    "text.emphasis", 
                    .init(
                        font:       .init(fontfile: "assets/fonts/SourceSansPro-Italic.ttf", size: 16)
                    )
                ), 
                (
                    "text.strong", 
                    .init(
                        font:       .init(fontfile: "assets/fonts/SourceSansPro-Bold.ttf", size: 16)
                    )
                ), 
                (
                    "text.strong.emphasis", 
                    .init(
                        font:       .init(fontfile: "assets/fonts/SourceSansPro-BoldItalic.ttf", size: 16)
                    )
                ), 
            ], 
            [
                (
                    "text", 
                    .init(
                        lineheight: 20
                    )
                ), 
            ]
        )
        
        init() 
        {
            // distinct fonts (differ by size) and distinct faces
            var fontSelections:Set<FontSelection>   = []
            for (_, rules):(Selector.Pattern, Rules.Inline) in self.stack.inline 
            {
                if let fontSelection:FontSelection = rules.font 
                {
                    fontSelections.update(with: fontSelection)
                }
            }
            
            let selections:[FontSelection]  = .init(fontSelections)
            let fonts:[Typeface.Font]
            (self.atlas, fonts)             = Typeface.assemble(selections)
            
            self.fonts = .init(uniqueKeysWithValues: zip(selections, fonts))
            self.cache = ([:], [:])
        }
        
        func font(_ selection:FontSelection) -> Typeface.Font
        {
            guard let font:Typeface.Font = self.fonts[selection] 
            else 
            {
                Log.fatal("unrendered font selection \(selection) requested")
            }
            
            return font
        }
        
        mutating 
        func resolve(inline selector:Selector) -> (UInt, Inline) 
        {
            if let entry:(UInt, Inline) = self.cache.inline[selector] 
            {
                return entry 
            }
            
            var style:Inline = .init()
            for (pattern, rules):(Selector.Pattern, Rules.Inline) in self.stack.inline 
                where pattern ~= selector
            {
                style.update(with: rules)
            } 
            
            let entry:(UInt, Inline)  = (0, style)
            self.cache.inline[selector] = entry
            return entry
        }
        mutating
        func resolve(block selector:Selector) -> (UInt, Block) 
        {
            if let entry:(UInt, Block) = self.cache.block[selector] 
            {
                return entry 
            }
            
            var style:Block = .init()
            for (pattern, rules):(Selector.Pattern, Rules.Block) in self.stack.block 
                where pattern ~= selector 
            {
                style.update(with: rules)
            } 
            
            let entry:(UInt, Block) = (0, style)
            self.cache.block[selector] = entry
            
            return entry
        }
    }
}
