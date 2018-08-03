struct Sphere 
{
    internal private(set) 
    var points:[Math<Float>.V3], 
        center:Math<Float>.V3
    
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
    
    private 
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
    
    private 
    func intersect(ray:ControlPlane.Ray) -> Math<Float>.V3? 
    {
        let c:Math<Float>.V3 = Math.sub(self.center, ray.source), 
            l:Float          = Math.dot(c, ray.vector)
        
        let discriminant:Float = 1 * 1 + l * l - Math.eusq(c)
        guard discriminant >= 0 
        else 
        {
            return nil
        }
        
        let offset:Math<Float>.V3 = Math.scale(ray.vector, by: l - discriminant.squareRoot())
        return Math.normalize(Math.add(ray.source, offset))
    }
    private 
    func attract(ray:ControlPlane.Ray) -> Math<Float>.V3
    {
        let c:Math<Float>.V3 = Math.sub(self.center, ray.source), 
            l:Float          = Math.dot(c, ray.vector)
        
        let discriminant:Float    = max(1 * 1 + l * l - Math.eusq(c), 0), 
            offset:Math<Float>.V3 = Math.scale(ray.vector, by: l - discriminant.squareRoot())
        return Math.normalize(Math.add(ray.source, offset))
    }
    
    func find(_ ray:ControlPlane.Ray) -> Int? 
    {
        guard let target:Math<Float>.V3 = self.intersect(ray: ray)
        else 
        {
            return nil
        }
        
        return self.nearest(to: target, threshold: 0.1)
    }
    
    func movePreview(_ active:Int, ray _:ControlPlane.Ray) -> MovePreview
    {
        return .unconstrained
    }
    
    mutating 
    func move(_ active:Int, ray:ControlPlane.Ray) 
    {
        self.points[active] = self.attract(ray: ray)
    }
    
    mutating 
    func duplicate(_ active:Int) -> Int 
    {
        let index:Int = self.points.count
        self.points.append(self.points[active])
        return index
    }
}

struct UI 
{    
    enum Action 
    {
        case double, primary, secondary, tertiary
    }
    
    private 
    enum Mode 
    {
    }
    
    private 
    enum Hit 
    {
        case gate(Mode), local(Int)
    }
    
    struct Controller 
    {
        struct Geo 
        {
            private 
            enum Anchor 
            {
                case vertex(Int), planar, navigation
            }
            
            private 
            var sphere:Sphere, 
                active:Int?, 
                anchor:Anchor?
            
            private 
            var controlplane:ControlPlane
            
            private 
            func probe(_ ray:ControlPlane.Ray) -> Hit?
            {
                guard let index:Int = self.sphere.find(ray)
                else 
                {
                    return nil
                }
                
                return .local(index)
            }
            
            private 
            func intersectsFloating(_:Math<Float>.V2) -> Bool 
            {
                return false 
            }
            
            fileprivate mutating 
            func down(_ position:Math<Float>.V2, action:Action, scene:inout Scene) 
                -> Mode?
            {            
                if let anchor:Anchor = self.anchor 
                {
                    switch (action, anchor)
                    {
                        case (.tertiary, .vertex):
                            self.controlplane.down(position, action: .pan)
                            fallthrough
                        
                        case (.tertiary, .planar), (.tertiary, .navigation):
                            self.anchor = .navigation                           // ← anchor down (tertiary)
                            
                            return nil
                        
                        // confirm a point drag 
                        case (.double,  .vertex(let active)), 
                             (.primary, .vertex(let active)):
                            let ray:ControlPlane.Ray = self.controlplane.raycast(position)
                            
                            self.sphere.move(active, ray: ray)
                            scene.basepoints = self.sphere.points.map
                            {
                                Math.add($0, self.sphere.center)
                            }
                            fallthrough 
                        // cancel a point drag
                        case (.secondary, .vertex):
                            self.anchor = nil                                   // → anchor up
                            
                            return nil 
                        
                        
                        case (.double,    .planar), (.double,    .navigation), 
                             (.primary,   .planar), (.primary,   .navigation), 
                             (.secondary, .planar), (.secondary, .navigation):
                            self.controlplane.up(position, action: .pan)
                    }
                }
                
                self.anchor = nil                                               // → anchor up
                if self.intersectsFloating(position)
                {
                    
                }
                else 
                {
                    let ray:ControlPlane.Ray = self.controlplane.raycast(position)
                    switch action 
                    {
                        case .double, .primary:
                            guard let hit:Hit = self.probe(ray)
                            else 
                            {
                                self.controlplane.down(position, action: .pan)
                                self.anchor = .planar                           // ← anchor down (planar)
                                break
                            }
                            
                            switch hit 
                            {
                                case .gate(let mode):
                                    return mode 
                                
                                case .local(let identifier):
                                    if action == .double 
                                    {
                                        self.active = self.sphere.duplicate(identifier)
                                    }
                                    else 
                                    {
                                        self.active = identifier
                                    }
                            }
                        
                        case .secondary:
                            guard let hit:Hit = self.probe(ray)
                            else 
                            {
                                break
                            }
                            
                            switch hit 
                            {
                                case .gate(let mode):
                                    return mode 
                                
                                case .local(let identifier):
                                    self.active = identifier
                                    self.anchor = .vertex(identifier)           // ← anchor down (vertex)
                            } 
                        
                        case .tertiary:
                            self.controlplane.down(position, action: .pan)
                            self.anchor = .navigation                           // ← anchor down (tertiary)
                    }
                }
                
                return nil
            }
            
            fileprivate mutating 
            func up(_ position:Math<Float>.V2, action:Action, scene:inout Scene) 
            {
                if let anchor:Anchor = self.anchor 
                {
                    switch (action, anchor)
                    {
                        // double never occurs in up
                        case (.double, _):
                            Log.unreachable()
                        
                        
                        case (.primary,   .vertex), 
                             (.secondary, .vertex):
                            break 
                        
                        case (.primary,   .planar), 
                             (.tertiary,  .navigation):
                            self.controlplane.up(position, action: .pan)
                            self.anchor = nil 
                        
                        case (.secondary, .planar):
                            break
                            
                        
                        case (.primary,   .navigation), 
                             (.secondary, .navigation):
                            break
                        
                        case (.tertiary,  .vertex), 
                             (.tertiary,  .planar):
                            break
                    }
                }
            }
        }
        
        private 
        var interface:Geo 
        
        mutating 
        func down(_ position:Math<Float>.V2, action:Action)
        {
            assert(self.interface.down(position, action: action) == nil)
        }
        
        mutating 
        func up(_ position:Math<Float>.V2, action:Action)
        {
            self.interface.up(position, action: action)
        }
    }
}
