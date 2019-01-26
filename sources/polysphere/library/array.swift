struct Array2D<Element> 
{
    var size:Math<Int>.V2, 
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
    
    init(_ buffer:[Element] = [], size:Math<Int>.V2 = (0, 0))
    {
        assert(Math.vol(size) == buffer.count)
        self.size   = size
        self.buffer = buffer
    }
    
    init(repeating repeated:Element, size:Math<Int>.V2)
    {
        self.size   = size
        self.buffer = .init(repeating: repeated, count: Math.vol(size))
    }
    
    init(size:Math<Int>.V2, _ generator:(Math<Int>.V2) throws -> Element) rethrows
    {
        var mapped:[Element] = []
            mapped.reserveCapacity(Math.vol(size))
        for y:Int in 0 ..< size.y 
        {
            for x:Int in 0 ..< size.x 
            {
                mapped.append(try generator((x, y)))
            }
        }
        
        self.init(mapped, size: size)
    }
    
    init<RAC>(_ source:RAC, pitch:Int, size:Math<Int>.V2) 
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
    func assign(at r0:Math<Int>.V2, from source:Array2D<Element>)
    {
        for y:Int in max(0, r0.y) ..< min(r0.y + source.size.y, self.size.y) 
        {
            for x:Int in max(0, r0.x) ..< min(r0.x + source.size.x, self.size.x)
            {
                self[y: y, x] = source[y: y - r0.y, x - r0.x]
            }
        }
    }
    
    func mapEnumerated<Result>(_ body:(Math<Int>.V2, Element) throws -> Result) rethrows -> [Result]
    {
        var mapped:[Result] = []
            mapped.reserveCapacity(Math.vol(self.size))
        for y:Int in 0 ..< size.y 
        {
            for x:Int in 0 ..< size.x 
            {
                mapped.append(try body((x, y), self[y: y, x]))
            }
        }
        
        return mapped
    }
}

struct Array3D<Element> 
{
    var size:Math<Int>.V3, 
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
    
    init(_ buffer:[Element] = [], size:Math<Int>.V3 = (0, 0, 0))
    {
        assert(Math.vol(size) == buffer.count)
        self.size   = size
        self.buffer = buffer
    }
    
    init(repeating repeated:Element, size:Math<Int>.V3)
    {
        self.size   = size
        self.buffer = .init(repeating: repeated, count: Math.vol(size))
    }
}
