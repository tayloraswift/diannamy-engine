import func Glibc.fopen
import func Glibc.fseek
import func Glibc.ftell
import func Glibc.fclose
import func Glibc.fread
import func Glibc.fwrite

import var Glibc.errno

import var Glibc.SEEK_END
import var Glibc.SEEK_SET

import typealias Glibc.FILE

enum File 
{
    static 
    func read(_ path:String) throws -> [UInt8]
    {
        guard let descriptor:UnsafeMutablePointer<FILE> = fopen(path, "rb")
        else
        {
            throw Error.FileError(thrower: .fopen, path: path, errno: errno)
        }
        defer
        { 
            fclose(descriptor)
        }
        
        guard fseek(descriptor, 0, SEEK_END) == 0
        else
        {
            throw Error.FileError(thrower: .fseek, path: path, errno: errno)
        }

        let n:Int = ftell(descriptor)
        guard n >= 0
        else
        {
            throw Error.FileError(thrower: .ftell, path: path, errno: errno)
        }
        
        guard fseek(descriptor, 0, SEEK_SET) == 0 
        else 
        {
            throw Error.FileError(thrower: .fseek, path: path, errno: errno)
        }
        
        let data:[UInt8] = .init(unsafeUninitializedCapacity: n) 
        {
            (buffer:inout UnsafeMutableBufferPointer<UInt8>, count:inout Int) in 
            
            count = fread(buffer.baseAddress, 1, n, descriptor)
        }
        
        guard data.count == n
        else
        {
            throw Error.FileError(thrower: .fread, path: path, errno: errno)
        }

        return data
    }
    
    static 
    func read(asUTF8 path:String) throws -> String
    {
        return .init(decoding: try read(path), as: Unicode.UTF8.self)
    }
    
    static 
    func write(_ data:[UInt8], to path:String, overwrite:Bool = false) throws 
    {
        guard let descriptor:UnsafeMutablePointer<FILE> = 
            overwrite ? fopen(path, "w") : fopen(path, "wx") 
        else 
        {
            throw Error.FileError(thrower: .fopen, path: path, errno: errno)
        }
        defer 
        { 
            fclose(descriptor)
        }
        
        let n:Int = fwrite(data, 1, data.count, descriptor)
        guard n == data.count
        else 
        {
            throw Error.FileError(thrower: .fwrite, path: path, errno: errno)
        }
    }
}

extension Model.Map:Codable 
{
    enum CodingKeys:String, CodingKey 
    {
        case points
        case backgroundImage = "background_image"
    }
    
    struct _Vector3<T>:Codable where T:Codable
    {
        var x:T, y:T, z:T
        
        init(_ v:Math<T>.V3) 
        {
            self.x = v.x 
            self.y = v.y 
            self.z = v.z
        }
    }
    
    init(from decoder:Decoder) throws 
    {
        let serialized:KeyedDecodingContainer<CodingKeys> = 
            try decoder.container(keyedBy: CodingKeys.self)
        
        let points:[_Vector3<Float>]    = try serialized.decode([_Vector3<Float>].self, forKey: .points)
        let backgroundImage:String?     = try serialized.decode(String?.self, forKey: .backgroundImage)
        self.init(quasiUnitLengthPoints: points.map{ ($0.x, $0.y, $0.z) }, 
                        backgroundImage: backgroundImage)
    }
    
    func encode(to encoder:Encoder) throws 
    {
        var serialized:KeyedEncodingContainer<CodingKeys> = 
            encoder.container(keyedBy: CodingKeys.self)
        
        try serialized.encode(self.points.map(_Vector3.init(_:)), forKey: .points)
        try serialized.encode(self.backgroundImage, forKey: .backgroundImage)
    }
}
