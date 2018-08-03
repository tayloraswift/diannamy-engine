struct Sphere 
{
    private 
    var points:[Math<Float>.V3]
    
    enum MovePreview 
    {
        case unconstrained, snapped(Math<Float>.V3), deleted(Int)
    }
    
    // the two points are not guaranteed to be distinct (i.e. if we have a digon), 
    // but are guaranteed to be different from the input
    private 
    func adjacent(to index:Int) -> (Int, Int)?
    {
        guard self.points.count > 1 
        else 
        {
            return nil 
        }
        
        let before:Int, 
            after:Int 
        
        if index != self.points.startIndex 
        {
            before = self.points.index(before: index)
        }
        else 
        {
            before = self.points.index(before: self.points.endIndex)
        }
        
        if index != self.points.index(before: self.points.endIndex)
        {
            after  = self.points.index(after: index)
        }
        else 
        {
            after  = self.points.startIndex
            
        }
        
        return (before, after)
    }
    
    @inline(__always)
    private static 
    func proximity(_ a:Math<Float>.V3, _ b:Math<Float>.V3, distance:Float) -> Bool
    {
        return Math.dot(a, b) > Float.cos(distance)
    }
    
    func nearest(to target:Math<Float>.V3, threshold:Float) -> Int? 
    {
        var gamma:Float = -1, 
            index:Int?  = nil 
        for (i, point):(Int, Math<Float>.V3) in self.points.enumerated()
        {
            let g:Float = Math.dot(point, target)
            if g < gamma 
            {
                gamma = g
                index = i
            }
        }
        
        return gamma > Float.cos(threshold) ? index : nil
    }
    func nearest(to target:Math<Float>.V3, threshold:Float, without exclude:Int) -> Int? 
    {
        var gamma:Float = -1, 
            index:Int?  = nil 
        for (i, point):(Int, Math<Float>.V3) in self.points.enumerated()
        {
            guard i != exclude 
            else 
            {
                continue 
            }
        
            let g:Float = Math.dot(point, target)
            if g < gamma 
            {
                gamma = g
                index = i
            }
        }
        
        return gamma > Float.cos(threshold) ? index : nil
    }
    
    func movePreview(_ active:Int, to destination:Math<Float>.V3) -> MovePreview
    {
        // check if the destination is within the radius of the adjacent points 
        if let (before, after):(Int, Int) = self.adjacent(to: active)
        {
            if Sphere.proximity(self.points[before], destination, distance: 0.1)
            {
                return .deleted(before)
            }
            if Sphere.proximity(destination, self.points[after],  distance: 0.1)
            {
                return .deleted(after)
            }
        }
        
        if let nearest:Int = Sphere.nearest(to: destination, threshold: 0.1, without: active)
        {
            return .snapped(self.points[nearest])
        }
        
        return .unconstrained
    }
    
    mutating 
    func move(_ active:Int, to destination:Math<Float>.V3)
    {
        switch self.movePreview(active, to: destination)
        {
            case .unconstrained:
                self.points[active] = destination 
            
            case .snapped(let latticePoint):
                self.points[active] = latticePoint 
            
            case .deleted:
                self.points.remove(at: active)
        }
    }
    
    // static 
    func cast(_ ray:Math<Float>.V3, from position:Math<Float>.V3) -> Math<Float>.V3?
    {
        let c:Math<Float>.V3 = Math.sub((0, 0, 0), position), 
            l:Float          = Math.dot(c, ray)
        
        let discriminant:Float = 1 * 1 + l * l - Math.eusq(c)
        guard discriminant >= 0 
        else 
        {
            return nil
        }
        
        return Math.add(position, Math.scale(ray, by: l - discriminant.squareRoot()))
    }
    
    struct Control 
    {
        internal private(set)
        var selection:Int?, 
            preselection:Int?, 
            changed:Bool = true
        
        private 
        var sphere:Sphere
        
        enum Action 
        {
            case move, add
        }
        
        @_fixed_layout
        struct Vertex 
        {
            let position:Math<Float>.V3, 
                id:Int32
        }
        
        struct Ray 
        {
            let source:Math<Float>.V3, 
                vector:Math<Float>.V3
        }
        
        func open(_ ray:Ray, action:Action) -> Bool
        {
            let c:Math<Float>.V3 = Math.sub((0, 0, 0), ray.source), 
                l:Float          = Math.dot(c, ray.vector)
            
            let discriminant:Float = 1 * 1 + l * l - Math.eusq(c)
            guard discriminant >= 0 
            else 
            {
                return false 
            }
            
            let z:Math<Float>.V3 = Math.scale(ray.vector, by: l - discriminant.squareRoot())
            let intersect:Math<Float>.V3 = Math.normalize(Math.add(ray.source, z))
            
            guard let nearest:Int = self.sphere.nearest(to: intersect, threshold: 0.1)
            else 
            {
                return false
            }
            
        }
        
        func preview(_ ray:Ray)
        {
            
        }
        
        func commit(_ ray:Ray)
        {
            
        }
        
        func cancel()
        {
            
        }
        
        func render() -> [Vertex]
        {
            self.changed = false
            return []
        }
    }
    
    struct View 
    {
        static 
        func draw(control:Control)
        {
            
        }
    }
}
