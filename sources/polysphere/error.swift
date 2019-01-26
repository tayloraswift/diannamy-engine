import func Glibc.strerror

enum Error:Swift.Error 
{
    enum Thrower:String 
    {
        case fopen, fseek, ftell, fread, fwrite, fclose
    }
    
    case FileError(thrower:Thrower, path:String, errno:Int32)
}

extension Error:CustomStringConvertible 
{
    var description:String 
    {
        switch self 
        {
        case .FileError(let thrower, let path, let errno):
            let message:String = .init(cString: strerror(errno))
            return "\(thrower) '\(path)': \(message)"
        }
    }
}
