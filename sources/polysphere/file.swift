import func Glibc.fopen
import func Glibc.fseek
import func Glibc.ftell
import func Glibc.fclose
import func Glibc.fread
import func Glibc.fwrite
import func Glibc.strerror

import var Glibc.errno

import var Glibc.SEEK_END
import var Glibc.SEEK_SET

import typealias Glibc.FILE

enum File 
{
    enum Error:RecursiveError
    {
        static 
        var namespace:String 
        {
            "file error"
        }
        
        case fopen(path:String, code:Int32)
        case fseek(path:String, code:Int32)
        case ftell(path:String, code:Int32)
        case fread(path:String, code:Int32)
        case fwrite(path:String, code:Int32)
        case fclose(path:String, code:Int32)
        
        func unpack() -> (String, Swift.Error?)
        {
            let thrower:String
            switch self 
            {
            case .fopen:
                thrower = "fopen"
            case .fseek:
                thrower = "fseek"
            case .ftell:
                thrower = "ftell"
            case .fread:
                thrower = "fread"
            case .fwrite:
                thrower = "fwrite"
            case .fclose:
                thrower = "fclose"
            }
            
            switch self 
            {
            case    .fopen(path: let path, code: let code),
                    .fseek(path: let path, code: let code),
                    .ftell(path: let path, code: let code),
                    .fread(path: let path, code: let code),
                    .fwrite(path: let path, code: let code),
                    .fclose(path: let path, code: let code):
                let message:String = .init(cString: strerror(code))
                return ("\(thrower) '\(path)': \(message)", nil)
            }
        }
    }
    
    static 
    func read(_ path:String) throws -> [UInt8]
    {
        guard let descriptor:UnsafeMutablePointer<FILE> = fopen(path, "rb")
        else
        {
            throw Error.fopen(path: path, code: errno)
        }
        defer
        { 
            fclose(descriptor)
        }
        
        guard fseek(descriptor, 0, SEEK_END) == 0
        else
        {
            throw Error.fseek(path: path, code: errno)
        }

        let n:Int = ftell(descriptor)
        guard n >= 0
        else
        {
            throw Error.ftell(path: path, code: errno)
        }
        
        guard fseek(descriptor, 0, SEEK_SET) == 0 
        else 
        {
            throw Error.fseek(path: path, code: errno)
        }
        
        let data:[UInt8] = .init(unsafeUninitializedCapacity: n) 
        {
            (buffer:inout UnsafeMutableBufferPointer<UInt8>, count:inout Int) in 
            
            count = fread(buffer.baseAddress, 1, n, descriptor)
        }
        
        guard data.count == n
        else
        {
            throw Error.fread(path: path, code: errno)
        }

        return data
    }
    
    static 
    func write(_ data:[UInt8], to path:String, overwrite:Bool = false) throws 
    {
        guard let descriptor:UnsafeMutablePointer<FILE> = 
            overwrite ? fopen(path, "w") : fopen(path, "wx") 
        else 
        {
            throw Error.fopen(path: path, code: errno)
        }
        defer 
        { 
            fclose(descriptor)
        }
        
        let n:Int = fwrite(data, 1, data.count, descriptor)
        guard n == data.count
        else 
        {
            throw Error.fwrite(path: path, code: errno)
        }
    }
}
