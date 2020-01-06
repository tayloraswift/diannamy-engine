// useful functions 
func directReturn<T>(default defaultValue:T, 
    initializer:(UnsafeMutablePointer<T>) throws -> ()) rethrows -> T 
{
    var value:T = defaultValue
    try initializer(&value)
    return value 
}
func directReturn<T, U>(default defaultValue:T, as destinationType:U.Type, 
    initializer:(UnsafeMutablePointer<T>) throws -> ()) rethrows -> U
    where T:BinaryInteger, U:BinaryInteger
{
    return .init(try directReturn(default: defaultValue, initializer: initializer))
}

func stringFromBuffer(capacity:Int, 
    _ body:(UnsafeMutablePointer<CChar>) throws -> ()) rethrows -> String 
{
    guard capacity > 0
    else
    {
        return ""
    }

    let buffer:UnsafeMutablePointer<CChar> = .allocate(capacity: capacity)
    defer
    {
        buffer.deallocate()
    }

    try body(buffer)
    return .init(cString: buffer)
}

struct Weak<T> where T:AnyObject
{
    weak 
    var object:T? 
    
    init(_ object:T?) 
    {
        self.object = object
    }
}

struct Unique<T>
{
    private final  
    class Reference
    { 
        var value:T
        
        init(_ value:T)
        {
            self.value = value
        }
    }
    
    private 
    var reference:Reference
    
    init(_ value:T)
    {
        self.reference = .init(value)
    }
    
    var value:T
    {
        get 
        {
            return self.reference.value
        }
        set(value)
        {
            guard isKnownUniquelyReferenced(&self.reference)
            else 
            {
                self.reference = .init(value) 
                return 
            }
            
            self.reference.value = value
        }
    }
    
    func withUnsafeBytes<Result>(body:(UnsafeRawBufferPointer) -> Result) -> Result 
    {
        return Swift.withUnsafeBytes(of: self.reference.value)
        {
            return body($0)
        }
    }
}

// blocked by this: https://github.com/apple/swift/pull/22289
extension Sequence 
{
    @inlinable
    func count(where predicate:(Element) throws -> Bool) rethrows -> Int 
    {
        var count:Int = 0
        for e:Element in self where try predicate(e)   
        {
            count += 1
        }
        return count
    }
}
