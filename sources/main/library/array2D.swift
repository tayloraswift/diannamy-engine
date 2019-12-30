struct Array2D<Element> 
{
    var size:Vector2<Int>, 
        buffer:[Element]
    
    subscript(y y:Int, x:Int) -> Element 
    {
        get 
        {
            return self.buffer[y * size.x + x]
        }
        set(v) 
        {
            self.buffer[y * size.x + x] = v
        }
    }
    
    init(_ buffer:[Element] = [], size:Vector2<Int> = .zero)
    {
        assert(size.wrappingVolume == buffer.count)
        self.size   = size
        self.buffer = buffer
    }
    
    init(repeating repeated:Element, size:Vector2<Int>)
    {
        self.size   = size
        self.buffer = .init(repeating: repeated, count: size.wrappingVolume)
    }
    
    init(size:Vector2<Int>, _ generator:(Vector2<Int>) throws -> Element) rethrows
    {
        var mapped:[Element] = []
            mapped.reserveCapacity(size.wrappingVolume)
        for y:Int in 0 ..< size.y 
        {
            for x:Int in 0 ..< size.x 
            {
                mapped.append(try generator(.init(x, y)))
            }
        }
        
        self.init(mapped, size: size)
    }
    
    init<RAC>(_ source:RAC, pitch:Int, size:Vector2<Int>) 
        where RAC:RandomAccessCollection, RAC.Element == Element, RAC.Index == Int
    {
        guard pitch * size.y <= source.count 
        else 
        {
            fatalError("input buffer not long enough")
        }
        
        self.size  = size 
        self.buffer = (0 ..< size.y).flatMap
        {
            source[$0 * pitch ..< $0 * pitch + size.x]
        } 
    }
    
    mutating 
    func assign(at r0:Vector2<Int>, from source:Array2D<Element>)
    {
        for y:Int in (r0.y ..< r0.y + source.size.y).clamped(to: 0 ..< self.size.y) 
        {
            for x:Int in (r0.x ..< r0.x + source.size.x).clamped(to: 0 ..< self.size.x)
            {
                self[y: y, x] = source[y: y - r0.y, x - r0.x]
            }
        }
    }
    
    func mapEnumerated<Result>(_ body:(Vector2<Int>, Element) throws -> Result) rethrows -> [Result]
    {
        var mapped:[Result] = []
            mapped.reserveCapacity(self.size.wrappingVolume)
        for y:Int in 0 ..< size.y 
        {
            for x:Int in 0 ..< size.x 
            {
                mapped.append(try body(.init(x, y), self[y: y, x]))
            }
        }
        
        return mapped
    }
}

struct Array3D<Element> 
{
    var size:Vector3<Int>, 
        buffer:[Element]
    
    subscript(z:Int, y:Int, x:Int) -> Element 
    {
        get 
        {
            return self.buffer[(z * size.y + y) * size.x + x]
        }
        set(v) 
        {
            self.buffer[(z * size.y + y) * size.x + x] = v
        }
    }
    
    init(_ buffer:[Element] = [], size:Vector3<Int> = .zero)
    {
        assert(size.wrappingVolume == buffer.count)
        self.size   = size
        self.buffer = buffer
    }
    
    init(repeating repeated:Element, size:Vector3<Int>)
    {
        self.size   = size
        self.buffer = .init(repeating: repeated, count: size.wrappingVolume)
    }
}
