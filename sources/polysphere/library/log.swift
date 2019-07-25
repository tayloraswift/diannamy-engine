protocol RecursiveError:Swift.Error 
{
    func unpack() -> (String, Swift.Error?)
    
    static 
    var namespace:String 
    {
        get 
    }
}
extension Swift.Error 
{
    static 
    var description:String 
    {
        if let type:RecursiveError.Type = Self.self as? RecursiveError.Type
        {
            return type.namespace
        }
        else 
        {
            return .init(reflecting: Self.self)
        }
    }
}

enum Log 
{
    enum Source 
    {
        case diannamy, opengl, glsl, glfw, freetype, harfbuzz
    }
    
    enum Severity 
    {
        case note, advisory, warning, error, fatal
    }
    
    enum Highlight 
    {
        enum RGB 
        {
            case black
            case white 
            case gray 
            case darkGray
            case red 
            case purple 
            case indigo 
            case blue 
            case cyan 
            case teal 
            
            var rgb:(r:UInt8, g:UInt8, b:UInt8) 
            {
                switch self 
                {
                    case .black:    return (0,   0,   0)
                    case .white:    return (255, 255, 255)
                    case .gray:     return (160, 160, 160)
                    case .darkGray: return (60,  60,  60)
                    case .red:      return (255, 80,  90)
                    case .purple:   return (255, 100, 255)
                    case .indigo:   return (160, 40,  255)
                    case .blue:     return (20,  120, 255)
                    case .cyan:     return (10,  220, 255)
                    case .teal:     return (2,   255, 152)
                }
            } 
        }
        
        static 
        var bold:String     = "\u{1B}[1m"
        static 
        var reset:String    = "\u{1B}[0m"
        
        static 
        func fg(_ color:RGB?) -> String 
        {
            if let color:(r:UInt8, g:UInt8, b:UInt8) = color?.rgb
            {
                return "\u{1B}[38;2;\(color.r);\(color.g);\(color.b)m"
            }
            else 
            {
                return "\u{1B}[39m"
            }
        }
        static 
        func bg(_ color:RGB?) -> String 
        {
            if let color:(r:UInt8, g:UInt8, b:UInt8) = color?.rgb
            {
                return "\u{1B}[48;2;\(color.r);\(color.g);\(color.b)m"
            }
            else 
            {
                return "\u{1B}[49m"
            }
        }
    }
    
    private static 
    var previous:String  = "", 
        multiplicity:Int = 1
    
    private static 
    func print(_ string:String) 
    {
        guard !string.isEmpty
        else 
        {
            return 
        }
        
        if string == previous 
        {
            multiplicity   += 1
            Swift.print("\u{1B}[1A\u{1B}[K\(string) \(Highlight.bold)\(Highlight.fg(.blue))(\(multiplicity))\(Highlight.reset)")
        }
        else 
        {
            previous        = string 
            multiplicity    = 1
            Swift.print(string)
        }
    }
    
    static 
    func print(_ anything:Any...) 
    {
        Self.print(anything.map{ "\($0)" }.joined(separator: " "))
    }
    
    static 
    func print(_ severity:Severity, _ message:String, from source:Source) 
    {
        let interjection:String 
        switch severity 
        {
        case .note:
            Self.print("\(Highlight.bold)(\(source))\(Highlight.reset) \(message)")
            return 
        
        // only used for the opengl `SEVERITY_LOW` alert level
        case .advisory:
            interjection = "\(Highlight.fg(.indigo))advisory:\(Highlight.fg(nil))"
        
        case .warning:
            interjection = "\(Highlight.fg(.purple))warning:\(Highlight.fg(nil))"
        case .error:
            interjection = "\(Highlight.fg(.red))error:\(Highlight.fg(nil))"
        case .fatal:
            interjection = "\(Highlight.fg(.red))fatal error:\(Highlight.fg(nil))"
        }
        
        Self.print("\(Highlight.bold)(\(source)) \(interjection) \(message)\(Highlight.reset)")
    }
    
    static 
    func note(_ message:String, from source:Source = .diannamy, file _:String = #file, line _:Int = #line)
    {
        Self.print(.note, message, from: source)
    }
    
    static 
    func advisory(_ message:String, from source:Source = .diannamy, file _:String = #file, line _:Int = #line)
    {
        Self.print(.advisory, message, from: source)
    }
    
    static 
    func warning(_ message:String, from source:Source = .diannamy, file _:String = #file, line _:Int = #line)
    {
        Self.print(.warning, message, from: source)
    }
    
    static 
    func dump(_ items:Any..., from source:Source = .diannamy, file:String = #file, line:Int = #line)
    {
        Self.print("\(Highlight.bold)(\(source)) \(Highlight.fg(.teal))\(file):\(line):\(Highlight.fg(nil))\n\(items.map{ "\($0)" }.joined(separator: " "))\(Highlight.reset)")
    }
    
    static 
    func error(_ message:String, from source:Source = .diannamy, file _:String = #file, line _:Int = #line)
    {
        Self.print(.error, message, from: source)
    }
    
    static 
    func fatal(_ message:String, from source:Source = .diannamy, file _:String = #file, line _:Int = #line) -> Never
    {
        Self.print(.fatal, message, from: source)
        fatalError()
    }
    
    static 
    func trace(error:Swift.Error) 
    {
        var stack:[(type:Swift.Error.Type, message:String)] = []
        var error:Swift.Error = error 
        while true 
        {
            switch error 
            {
            case let recursive as RecursiveError:
                let (string, next):(String, Swift.Error?) = recursive.unpack()
                stack.append((type(of: recursive), string))
                if let next:Swift.Error = next 
                {
                    error = next 
                    continue 
                }
            
            default:
                stack.append((type(of: error), String.init(describing: error)))
            }
            
            break
        }
        
        for (i, (type, message)):(Int, (type:Swift.Error.Type, message:String)) in 
            stack.reversed().enumerated()
        {
            Self.print("\(Highlight.bold)[\(i)]: \(Highlight.fg(.red))\(type.description)\(Highlight.reset)")
            Self.print(message)
        }
    }
    
    static 
    func unreachable(file:String = #file, line:Int = #line) -> Never
    {
        Self.print("\(Highlight.bold)\(file):\(line): \(Highlight.fg(.red))unreachable code executed\(Highlight.reset)")
        fatalError()
    }
}
