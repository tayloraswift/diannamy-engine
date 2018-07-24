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
            assert($0.count == 44 * 4)
            return body($0)
        }
    }
}
