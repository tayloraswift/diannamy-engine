extension Array where Element == UInt8
{
    /// Loads a misaligned big-endian integer value from the given byte offset
    /// and casts it to a desired format.
    /// - Parameters:
    ///     - bigEndian: The size and type to interpret the data to load as.
    ///     - type: The type to cast the read integer value to.
    ///     - offset: The byte offset to load the big-endian integer from.
    /// - Returns: The read integer value, cast to `U`.
    fileprivate
    func load<T, U>(bigEndian:T.Type, as type:U.Type, at offset:Int) -> U
        where T:FixedWidthInteger, U:BinaryInteger
    {
        return self[offset ..< offset + MemoryLayout<T>.size].load(bigEndian: T.self, as: U.self)
    }

    /// Decomposes the given integer value into its constituent bytes, in big-endian order.
    /// - Parameters:
    ///     - value: The integer value to decompose.
    ///     - type: The big-endian format `T` to store the given `value` as. The given
    ///             `value` is truncated to fit in a `T`.
    /// - Returns: An array containing the bytes of the given `value`, in big-endian order.
    fileprivate static
    func store<U, T>(_ value:U, asBigEndian type:T.Type) -> [UInt8]
        where U:BinaryInteger, T:FixedWidthInteger
    {
        return .init(unsafeUninitializedCapacity: MemoryLayout<T>.size)
        {
            (buffer:inout UnsafeMutableBufferPointer<UInt8>, count:inout Int) in

            let bigEndian:T = T.init(truncatingIfNeeded: value).bigEndian,
                destination:UnsafeMutableRawBufferPointer = .init(buffer)
            Swift.withUnsafeBytes(of: bigEndian)
            {
                destination.copyMemory(from: $0)
                count = $0.count
            }
        }
    }
    fileprivate mutating
    func store<U, T>(_ value:U, asBigEndian type:T.Type, at offset:Int)
        where U:BinaryInteger, T:FixedWidthInteger
    {
        let bigEndian:T = T.init(truncatingIfNeeded: value).bigEndian
        Swift.withUnsafeBytes(of: bigEndian)
        {
            for (i, byte):(Int, UInt8) in $0.enumerated() 
            {
                self[offset + i] = byte
            }
        }
    }
    fileprivate mutating
    func append<U, T>(_ value:U, asBigEndian type:T.Type)
        where U:BinaryInteger, T:FixedWidthInteger
    {
        let bigEndian:T = T.init(truncatingIfNeeded: value).bigEndian
        Swift.withUnsafeBytes(of: bigEndian)
        {
            for byte:UInt8 in $0 
            {
                self.append(byte)
            }
        }
    }
}

extension ArraySlice where Element == UInt8
{
    /// Loads this array slice as a misaligned big-endian integer value,
    /// and casts it to a desired format.
    /// - Parameters:
    ///     - bigEndian: The size and type to interpret this array slice as.
    ///     - type: The type to cast the read integer value to.
    /// - Returns: The read integer value, cast to `U`.
    fileprivate
    func load<T, U>(bigEndian:T.Type, as type:U.Type) -> U
        where T:FixedWidthInteger, U:BinaryInteger
    {
        return self.withUnsafeBufferPointer
        {
            (buffer:UnsafeBufferPointer<UInt8>) in

            assert(buffer.count >= MemoryLayout<T>.size,
                "attempt to load \(T.self) from slice of size \(buffer.count)")

            var storage:T = .init()
            let value:T   = withUnsafeMutablePointer(to: &storage)
            {
                $0.deinitialize(count: 1)

                let source:UnsafeRawPointer     = .init(buffer.baseAddress!),
                    raw:UnsafeMutableRawPointer = .init($0)

                raw.copyMemory(from: source, byteCount: MemoryLayout<T>.size)

                return raw.load(as: T.self)
            }

            return U(T(bigEndian: value))
        }
    }
}

public 
extension File 
{
    // can format:
    // [ 0...3 ]: checksum (of everything that follows, including size information)
    // [ 4...7 ]: dimension count (0, 2 or 3)
    // [ 8...11]: x
    // [12...15]: y (optional)
    // [16...19]: z (optional)
    // [20...  ]: data (big-endian)
    enum Typed 
    {
        case float32([Float])
        case float32x4D2([SIMD4<Float>], x:Int, y:Int)
        case float32x4D3([SIMD4<Float>], x:Int, y:Int, z:Int)
    }
    
    private static 
    func checksum(_ data:ArraySlice<UInt8>) -> UInt32 
    {
        var sum:UInt32 = 0
        for (i, byte):(Int, UInt8) in data.enumerated() 
        {
            sum &+= .init(byte) ^ .init(i)
        }
        return sum
    }
    
    private static 
    func store(_ x:UInt32, into buffer:inout [UInt8]) 
    {
        buffer.append(.init(truncatingIfNeeded: x >> 24))
        buffer.append(.init(truncatingIfNeeded: x >> 16))
        buffer.append(.init(truncatingIfNeeded: x >>  8))
        buffer.append(.init(truncatingIfNeeded: x      ))
    }
    // index is by UInt32 stride 
    private static 
    func store(_ x:UInt32, into buffer:inout [UInt8], at index:Int) 
    {
        let offset:Int     = index * MemoryLayout<UInt32>.stride
        buffer[offset]     = .init(truncatingIfNeeded: x >> 24)
        buffer[offset | 1] = .init(truncatingIfNeeded: x >> 16)
        buffer[offset | 2] = .init(truncatingIfNeeded: x >>  8)
        buffer[offset | 3] = .init(truncatingIfNeeded: x      )
    }
    
    static 
    func can(_ data:[Float], to path:String, overwrite:Bool = false) throws
    {
        try Self.can(.float32(data), to: path, overwrite: overwrite)
    }
    static 
    func can(_ data:[SIMD4<Float>], size:(x:Int, y:Int), to path:String, overwrite:Bool = false) throws
    {
        try Self.can(.float32x4D2(data, x: size.x, y: size.y), to: path, overwrite: overwrite)
    }
    static 
    func can(_ data:[SIMD4<Float>], size:(x:Int, y:Int, z:Int), to path:String, overwrite:Bool = false) throws
    {
        try Self.can(.float32x4D3(data, x: size.x, y: size.y, z: size.z), to: path, overwrite: overwrite)
    }
    static 
    func can(_ typed:Typed, to path:String, overwrite:Bool = false) throws 
    {
        let w:Int = MemoryLayout<UInt32>.stride
        var buffer:[UInt8] = [0, 0, 0, 0] 
        switch typed 
        {
        case .float32(let data):
            buffer.reserveCapacity(w * 3 + MemoryLayout<Float>.stride * data.count)
            buffer.append(0, asBigEndian: UInt32.self)
            buffer.append(data.count, asBigEndian: UInt32.self)
            for f:Float in data 
            {
                buffer.append(f.bitPattern, asBigEndian: UInt32.self)
            }
            
        case .float32x4D2(let data, x: let x, y: let y):
            guard x * y == data.count 
            else 
            {
                throw Error.can(path: path, message: "expected \(x) × \(y) = \(x * y) elements, but buffer is of size \(data.count)")
            }
            
            buffer.reserveCapacity(w * 4 + MemoryLayout<SIMD4<Float>>.stride * data.count)
            buffer.append(2, asBigEndian: UInt32.self)
            buffer.append(x, asBigEndian: UInt32.self)
            buffer.append(y, asBigEndian: UInt32.self)
            for v4:SIMD4<Float> in data 
            {
                buffer.append(v4.x.bitPattern, asBigEndian: UInt32.self)
                buffer.append(v4.y.bitPattern, asBigEndian: UInt32.self)
                buffer.append(v4.z.bitPattern, asBigEndian: UInt32.self)
                buffer.append(v4.w.bitPattern, asBigEndian: UInt32.self)
            }
        case .float32x4D3(let data, x: let x, y: let y, z: let z):
            guard x * y * z == data.count 
            else 
            {
                throw Error.can(path: path, message: "expected \(x) × \(y) × \(z) = \(x * y * z) elements, but buffer is of size \(data.count)")
            }
            
            buffer.reserveCapacity(w * 5 + MemoryLayout<SIMD4<Float>>.stride * data.count)
            buffer.append(3, asBigEndian: UInt32.self)
            buffer.append(x, asBigEndian: UInt32.self)
            buffer.append(y, asBigEndian: UInt32.self)
            buffer.append(z, asBigEndian: UInt32.self)
            for v4:SIMD4<Float> in data 
            {
                buffer.append(v4.x.bitPattern, asBigEndian: UInt32.self)
                buffer.append(v4.y.bitPattern, asBigEndian: UInt32.self)
                buffer.append(v4.z.bitPattern, asBigEndian: UInt32.self)
                buffer.append(v4.w.bitPattern, asBigEndian: UInt32.self)
            }
        }
        
        let checksum:UInt32 = Self.checksum(buffer[w...])
        buffer.store(checksum, asBigEndian: UInt32.self, at: 0)
        
        try Self.write(buffer, to: path, overwrite: overwrite)
    }
    
    static 
    func uncan(from path:String) throws -> Typed 
    {
        let w:Int = MemoryLayout<UInt32>.stride
        let buffer:[UInt8] = try Self.read(from: path)
        
        guard buffer.count >= w * 2 
        else 
        {
            throw Error.uncan(path: path, message: "unexpected end-of-file (offset +\(buffer.count))")
        }
        
        // validate checksum 
        let checksum:(declared:UInt32, computed:UInt32)
        checksum.declared = buffer.load(bigEndian: UInt32.self, as: UInt32.self, at: 0)
        checksum.computed = Self.checksum(buffer[w...])
        
        guard checksum.declared == checksum.computed 
        else
        {
            throw Error.uncan(path: path, message: "invalid checksum (declared \(checksum.declared), computed \(checksum.computed))")
        }
        
        func loadFloat32(_ raw:ArraySlice<UInt8>) -> Float
        {
            let v:UInt32 = raw.load(bigEndian: UInt32.self, as: UInt32.self)
            return .init(bitPattern: v)
        }
        func loadFloat32x4(_ raw:ArraySlice<UInt8>) -> SIMD4<Float> 
        {
            let p:Int   = raw.startIndex, 
                Δp:Int  = MemoryLayout<Float>.stride
            let v:(UInt32, UInt32, UInt32, UInt32) = 
            (
                raw[p          ..< p +     Δp].load(bigEndian: UInt32.self, as: UInt32.self),
                raw[p +     Δp ..< p + 2 * Δp].load(bigEndian: UInt32.self, as: UInt32.self),
                raw[p + 2 * Δp ..< p + 3 * Δp].load(bigEndian: UInt32.self, as: UInt32.self),
                raw[p + 3 * Δp ..< p + 4 * Δp].load(bigEndian: UInt32.self, as: UInt32.self)
            )
            return .init(.init(bitPattern: v.0), .init(bitPattern: v.1), .init(bitPattern: v.2), .init(bitPattern: v.3))
        }
        func data<T>(_ raw:ArraySlice<UInt8>, count:Int, decoder:(ArraySlice<UInt8>) -> T) throws -> [T] 
        {
            let expected:Int = count * MemoryLayout<T>.stride
            guard raw.count == expected
            else 
            {
                if raw.count < expected
                {
                    throw Error.uncan(path: path, message: "not enough data in file (missing \(expected - raw.count) bytes)")
                }
                else 
                {
                    throw Error.uncan(path: path, message: "extraneous data at end of file (\(raw.count - expected) bytes)")
                }
            }
            
            return (0 ..< count).map 
            {
                let p:(Int, Int) = 
                (
                    raw.startIndex +  $0      * MemoryLayout<T>.stride,
                    raw.startIndex + ($0 + 1) * MemoryLayout<T>.stride
                )
                return decoder(raw[p.0 ..< p.1])
            }
        }
        
        let tag:UInt32 = buffer.load(bigEndian: UInt32.self, as: UInt32.self, at: w)
        switch tag 
        {
        case 0: // .float32 
            guard buffer.count >= 3 * w
            else 
            {
                throw Error.uncan(path: path, message: "unexpected end-of-file (offset +\(buffer.count))")
            }
            let count:Int               = buffer.load(bigEndian: UInt32.self, as: Int.self, at: 2 * w)
            
            let tail:ArraySlice<UInt8>  = buffer[(3 * w)...]
            let samples:[Float]         = try data(tail, count: count, decoder: loadFloat32(_:))
            return .float32(samples)
            
        case 2: // .float32x4D2
            guard buffer.count >= 4 * w
            else 
            {
                throw Error.uncan(path: path, message: "unexpected end-of-file (offset +\(buffer.count))")
            }
            
            let x:Int = buffer.load(bigEndian: UInt32.self, as: Int.self, at: 2 * w),
                y:Int = buffer.load(bigEndian: UInt32.self, as: Int.self, at: 3 * w)
            
            let tail:ArraySlice<UInt8> = buffer[(4 * w)...]
            let samples:[SIMD4<Float>] = try data(tail, count: x * y, decoder: loadFloat32x4(_:))
            return .float32x4D2(samples, x: x, y: y)
        
        case 3: // .float32x4D3
            guard buffer.count >= 5 * w 
            else 
            {
                throw Error.uncan(path: path, message: "unexpected end-of-file (offset +\(buffer.count))")
            }
            
            let x:Int = buffer.load(bigEndian: UInt32.self, as: Int.self, at: 2 * w),
                y:Int = buffer.load(bigEndian: UInt32.self, as: Int.self, at: 3 * w),
                z:Int = buffer.load(bigEndian: UInt32.self, as: Int.self, at: 4 * w) 
            
            let tail:ArraySlice<UInt8> = buffer[(5 * w)...]
            let samples:[SIMD4<Float>] = try data(tail, count: x * y * z, decoder: loadFloat32x4(_:))
            return .float32x4D3(samples, x: x, y: y, z: z)
        
        default:
            throw Error.uncan(path: path, message: "unrecognized format code (\(tag))")
        }
    }
}
