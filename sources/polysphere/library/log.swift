protocol RecursiveError:Swift.Error 
{
    func unpack() -> (String, Swift.Error?)
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
    
    private 
    enum Color 
    {
        static 
        var reset:String    { "\u{1B}[39m" }
        static 
        var teal:String     { "\u{1B}[38;2;2;255;152m" }
        static 
        var blue:String     { "\u{1B}[38;2;20;120;255m" }
        static 
        var indigo:String   { "\u{1B}[38;2;120;0;255m" }
        static 
        var purple:String   { "\u{1B}[38;2;255;100;255m" }
        static 
        var red:String      { "\u{1B}[38;2;255;80;90m" }
    }
    private 
    enum Bold 
    {
        static 
        var on:String       { "\u{1B}[1m" }
        static 
        var off:String      { "\u{1B}[0m" }
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
            Swift.print("\u{1B}[1A\u{1B}[K\(string) \(Bold.on)\(Color.blue)(\(multiplicity))\(Color.reset)\(Bold.off)")
        }
        else 
        {
            previous        = string 
            multiplicity    = 1
            Swift.print(string)
        }
    }
    
    static 
    func print(_ severity:Severity, _ message:String, from source:Source) 
    {
        let interjection:String 
        switch severity 
        {
        case .note:
            Self.print("\(Bold.on)(\(source))\(Bold.off) \(message)")
            return 
        
        // only used for the opengl `SEVERITY_LOW` alert level
        case .advisory:
            interjection = "\(Color.indigo)advisory:\(Color.reset)"
        
        case .warning:
            interjection = "\(Color.purple)warning:\(Color.reset)"
        case .error:
            interjection = "\(Color.red)error:\(Color.reset)"
        case .fatal:
            interjection = "\(Color.red)fatal error:\(Color.reset)"
        }
        
        Self.print("\(Bold.on)(\(source)) \(interjection) \(message)\(Bold.off)")
    }
    
    static 
    func note(_ message:String, from source:Source = .diannamy, file _:String = #file, line _:Int = #line)
    {
        Self.print(.note, message, from: source)
    }
    
    static 
    func warning(_ message:String, from source:Source = .diannamy, file _:String = #file, line _:Int = #line)
    {
        Self.print(.warning, message, from: source)
    }
    
    static 
    func dump(_ items:Any..., from source:Source = .diannamy, file:String = #file, line:Int = #line)
    {
        Self.print("\(Bold.on)(\(source)) \(Color.teal)\(file):\(line):\(Color.reset)\n\(items.map{ "\($0)" }.joined(separator: " "))\(Bold.off)")
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
            Self.print("\(Bold.on)\(Color.red)[\(i)]:\(Color.reset) \(String.init(describing: type))\(Bold.off)")
            Self.print(message)
        }
    }
    
    static 
    func unreachable(file:String = #file, line:Int = #line) -> Never
    {
        Self.print("\(Bold.on)\(file):\(line): \(Color.red)unreachable code executed\(Color.reset)\(Bold.off)")
        fatalError()
    }
}
