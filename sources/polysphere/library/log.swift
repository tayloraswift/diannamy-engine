enum Log 
{
    enum Source 
    {
        case diannamy, opengl, glsl, glfw, freetype, harfbuzz
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
            Swift.print("\u{1B}[1A\u{1B}[K\(string) \u{1B}[1m\u{1B}[38;2;20;120;255m(\(multiplicity))\u{1B}[39;0m")
        }
        else 
        {
            previous        = string 
            multiplicity    = 1
            Swift.print(string)
        }
    }
    
    static 
    func note(splitting messages:String, from source:Source, file:String = #file, line:Int = #line)
    {
        for message:Substring in messages.split(separator: "\n")
        {
            note(.init(message), from: source, file: file, line: line)
        }
    }
    
    static 
    func note(_ message:String, from source:Source = .diannamy, file _:String = #file, line _:Int = #line)
    {
        print("\u{1B}[1m(\(source))\u{1B}[0m \(message)")
    }
    
    static 
    func warning(_ message:String, from source:Source = .diannamy, file _:String = #file, line _:Int = #line)
    {
        print("\u{1B}[1m(\(source)) \u{1B}[38;2;255;100;255mwarning:\u{1B}[39m \(message)\u{1B}[0m")
    }
    
    static 
    func dump(_ items:Any..., from source:Source = .diannamy, file:String = #file, line:Int = #line)
    {
        print("\u{1B}[1m(\(source)) \u{1B}[38;2;2;255;152mdump \(file):\(line):\u{1B}[39m \n\(items.map{ "\($0)" }.joined(separator: " "))\u{1B}[0m")
    }
    
    static 
    func error(_ message:String, from source:Source = .diannamy, file _:String = #file, line _:Int = #line)
    {
        print("\u{1B}[1m(\(source)) \u{1B}[38;2;255;80;90merror:\u{1B}[39m \(message)\u{1B}[0m")
    }
    
    static 
    func fatal(_ message:String, from source:Source = .diannamy, file _:String = #file, line _:Int = #line) -> Never
    {
        print("\u{1B}[1m(\(source)) \u{1B}[38;2;255;80;90mfatal error:\u{1B}[39m \(message)\u{1B}[0m")
        fatalError()
    }
    
    /* static 
    func fatal(_ problem:Problem, file:String = #file, line:Int = #line)  -> Never
    {
        print("\u{1B}[1m\(file):\(line): \u{1B}[38;2;255;80;90mfatal error:\u{1B}[39m \(problem)\u{1B}[0m")
        fatalError()
    } */
    
    static 
    func unreachable(file:String = #file, line:Int = #line) -> Never
    {
        print("\u{1B}[1m\(file):\(line): \u{1B}[38;2;255;80;90munreachable code executed\u{1B}[0m")
        fatalError()
    }
}
