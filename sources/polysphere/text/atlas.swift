// import PNG 

// now that Texture has reference semantics, can we downgrade this to a struct?
final 
class Atlas 
{
    let texture:GPU.Texture.D2<UInt8> 
    
    private 
    let sprites:[Rectangle<Float>]
    
    subscript(index:Int) -> Rectangle<Float> 
    {
        return self.sprites[index]
    }
    
    init(_ bitmaps:[Array2D<UInt8>])
    {
        // sort rectangles in increasing height 
        let sorted:[(Int, Array2D<UInt8>)] = zip(bitmaps.indices, bitmaps).sorted 
        {
            $0.1.size.y < $1.1.size.y
        }
        
        // guaranteed to be at least the width of the widest glyph
        let width:Int                       = Atlas.optimalWidth(sizes: sorted.map{ $0.1.size }) 
        var rows:[[(Int, Array2D<UInt8>)]]  = [], 
            row:[(Int, Array2D<UInt8>)]     = [], 
            x:Int                           = 0
        for (index, bitmap):(Int, Array2D<UInt8>) in sorted 
        {        
            x += bitmap.size.x 
            if x > width 
            {
                rows.append(row)
                row = []
                x   = bitmap.size.x
            }
            
            row.append((index, bitmap))
        }
        rows.append(row)
        
        let height:Int                  = rows.reduce(0){ $0 + ($1.last?.1.size.y ?? 0) }
        var packed:Array2D<UInt8>       = .init(repeating: 0, size: .init(width, height)), 
            position:Vector2<Int>       = .zero
        var sprites:[Rectangle<Float>]  = .init(repeating: .zero, count: bitmaps.count)
        
        let divisor:Vector2<Float> = .cast(.init(width, height))
        for row:[(Int, Array2D<UInt8>)] in rows 
        {
            for (index, bitmap):(Int, Array2D<UInt8>) in row 
            {
                packed.assign(at: position, from: bitmap)
                sprites[index] = .init(
                    .cast(position               ) / divisor,
                    .cast(position &+ bitmap.size) / divisor
                )
                
                position.x += bitmap.size.x
            }
            
            position.x  = 0
            position.y += row.last?.1.size.y ?? 0
        }
        
        /* try!    PNG.encode(v: packed.buffer, 
                        size: (packed.size.x, packed.size.y), 
                          as: .v8, 
                        path: "fontatlas-debug.png") */
        Log.note("rendered font atlas of \(sprites.count) glyphs, \(packed.buffer.count >> 10) KB")
        
        let texture:GPU.Texture.D2<UInt8> = .init(
            layout:         .r8, 
            magnification:  .nearest, 
            minification:   .nearest, 
            debugName:      "diannamy://fontatlas")
        
        texture.assign(packed)
        
        self.texture = texture 
        self.sprites = sprites 
    }
    
    deinit 
    {
    }
    
    private static 
    func optimalWidth(sizes:[Vector2<Int>]) -> Int 
    {
        let slate:Vector2<Int> = .init(
            sizes.reduce(0){ $0 + $1.x }, 
            sizes.last?.y ?? 0
        )
        let minWidth:Int    = (sizes.map{ $0.x }.max() ?? 0).nextPowerOfTwo
        var width:Int       = minWidth
        while width * width < slate.y * slate.x 
        {
            width <<= 1
        }
        
        return max(minWidth, width >> 1)
    }
}
