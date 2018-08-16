struct Array2D<Element> 
{
    var shape:Math<Int>.V2, 
        buffer:[Element]
    
    subscript(y y:Int, x:Int) -> Element 
    {
        get 
        {
            return self.buffer[y * shape.x + x]
        }
        set(v) 
        {
            self.buffer[y * shape.x + x] = v
        }
    }
    
    init(_ buffer:[Element] = [], shape:Math<Int>.V2 = (0, 0))
    {
        assert(Math.vol(shape) == buffer.count)
        self.shape  = shape
        self.buffer = buffer
    }
    
    init(repeating repeated:Element, shape:Math<Int>.V2)
    {
        self.shape  = shape
        self.buffer = .init(repeating: repeated, count: Math.vol(shape))
    }
    
    mutating 
    func assign(a:Math<Int>.V2, b:Math<Int>.V2, from source:[Element])
    {
        for y:Int in a.y ..< b.y 
        {
            for x:Int in a.x ..< b.x 
            {
                self[y: y, x] = source[(y - a.y) * (b.x - a.x) + x - a.x]
            }
        }
    }
}

struct Array3D<Element> 
{
    var shape:Math<Int>.V3, 
        buffer:[Element]
    
    subscript(z:Int, y:Int, x:Int) -> Element 
    {
        get 
        {
            return self.buffer[(z * shape.y + y) * shape.x + x]
        }
        set(v) 
        {
            self.buffer[(z * shape.y + y) * shape.x + x] = v
        }
    }
    
    init(_ buffer:[Element] = [], shape:Math<Int>.V3 = (0, 0, 0))
    {
        assert(Math.vol(shape) == buffer.count)
        self.shape  = shape
        self.buffer = buffer
    }
    
    init(repeating repeated:Element, shape:Math<Int>.V3)
    {
        self.shape  = shape
        self.buffer = .init(repeating: repeated, count: Math.vol(shape))
    }
}
