struct Sphere 
{
    private 
    var points:[Math<Float>.V3], 
        center:Math<Float>.V3
    
    enum Operation 
    {
        case unconstrained(Math<Float>.V3), snapped(Math<Float>.V3), deleted(Int)
    }
    
    init(_ points:[Math<Float>.V3] = [], center:Math<Float>.V3 = (0, 0, 0))
    {
        self.points = points 
        self.center = center
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
            if g > gamma 
            {
                gamma = g
                index = i
            }
        }
        
        return gamma > Float.cos(threshold) ? index : nil
    }
    private 
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
            if g > gamma 
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
    
    private static 
    func collapse(index:Int, around deleted:Int) -> Int 
    {
        return index <= deleted ? index : index - 1
    }
    
    func movePreview(_ active:Int, ray:ControlPlane.Ray) -> Operation
    {
        let destination:Math<Float>.V3 = self.attract(ray: ray)
        // check if the destination is within the radius of the adjacent points 
        if let (before, after):(Int, Int) = self.adjacent(to: active)
        {
            if Sphere.proximity(self.points[before], destination, distance: 0.1)
            {
                return .deleted(Sphere.collapse(index: before, around: active))
            }
            if Sphere.proximity(destination, self.points[after],  distance: 0.1)
            {
                return .deleted(Sphere.collapse(index: after,  around: active))
            }
        }
        
        if let nearest:Int = nearest(to: destination, threshold: 0.1, without: active)
        {
            return .snapped(self.points[nearest])
        }
        
        return .unconstrained(destination)
    }
    
    mutating 
    func move(_ active:Int, ray:ControlPlane.Ray) -> Operation
    {
        let operation:Operation = self.movePreview(active, ray: ray)
        switch operation
        {
            case .unconstrained(let destination), 
                 .snapped(      let destination):
                self.points[active] = destination 
            
            case .deleted:
                self.points.remove(at: active)
        }
        
        return operation
    }
    
    mutating 
    func duplicate(_ active:Int) -> Int 
    {
        let index:Int = self.points.count
        self.points.append(self.points[active])
        return index
    }
    
    
    func apply() -> [Math<Float>.V3]
    {
        return self.points.map 
        {
            Math.add($0, self.center)
        }
    }
    func apply(to active:Int, operation:Operation) -> [Math<Float>.V3]
    {
        switch operation 
        {
            case .unconstrained(let destination), 
                 .snapped(      let destination):
                var vertices:[Math<Float>.V3] = self.points.map 
                {
                    Math.add($0, self.center)
                }
                
                vertices[active] = Math.add(destination, self.center)
                return vertices
            
            case .deleted:
                return self.points.enumerated().filter 
                {
                    return $0.0 != active
                }.map  
                {
                    Math.add($0.1, self.center)
                }
        }
    }
}

extension UI 
{
    enum Controller 
    {
        private 
        enum Hit 
        {
            case gate(Mode), local(Int)
        }
        
        struct Geo 
        {
            // view interface
            struct Scene 
            {
                var vertices:Lazy<[Math<Float>.V3]>
                
                var selected:Int?, 
                    preselected:Int?, 
                    snapped:Int?, 
                    deleted:Int?
                
                init(sphere:Sphere) 
                {
                    self.vertices = .mutated(sphere.apply())
                }
            }
            
            private 
            enum Anchor 
            {
                case vertex(Int), planar, navigation
            }
            
            private 
            var sphere:Sphere, 
                active:Int?, 
                anchor:Anchor?
            
            init(sphere:Sphere)
            {
                self.sphere = sphere
            }
            
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
            
            mutating 
            func down(_ position:Math<Float>.V2, action:Action, 
                scene:inout Scene, plane:inout ControlPlane) -> Mode?
            {
                if let anchor:Anchor = self.anchor 
                {
                    switch (action, anchor)
                    {
                        case (.tertiary, .vertex):
                            scene.vertices.push(self.sphere.apply())
                            scene.snapped      = nil
                            scene.deleted      = nil
                            
                            plane.down(position, action: .pan)
                            fallthrough
                        
                        case (.tertiary, .planar), (.tertiary, .navigation):
                            self.anchor = .navigation                           // ← anchor down (tertiary)
                            
                            return nil
                        
                        // confirm a point drag 
                        case (.double,  .vertex(let active)), 
                             (.primary, .vertex(let active)):
                            let ray:ControlPlane.Ray = plane.raycast(position)
                            
                            if case .deleted = self.sphere.move(active, ray: ray)
                            {
                                self.active    = nil
                                scene.selected = nil 
                            }
                            
                            fallthrough
                            
                        // cancel a point drag
                        case (.secondary, .vertex):
                            self.anchor = nil                                   // → anchor up
                            
                            scene.vertices.push(self.sphere.apply())
                            scene.snapped      = nil
                            scene.deleted      = nil
                            return nil 
                        
                        
                        case (.double,    .planar), (.double,    .navigation), 
                             (.primary,   .planar), (.primary,   .navigation), 
                             (.secondary, .planar), (.secondary, .navigation):
                            plane.up(position, action: .pan)
                    }
                }
                
                self.anchor = nil                                               // → anchor up
                if self.intersectsFloating(position)
                {
                    
                }
                else 
                {
                    let ray:ControlPlane.Ray = plane.raycast(position)
                    switch action 
                    {
                        case .double, .primary:
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
                                    if action == .double 
                                    {
                                        let active:Int = self.sphere.duplicate(identifier) 
                                        self.active = active
                                        self.anchor = .vertex(active)           // ← anchor down (vertex)
                                        scene.vertices.push(self.sphere.apply())
                                    }
                                    else 
                                    {
                                        self.active = identifier
                                    }
                                    
                                    scene.selected  = self.active 
                            }
                        
                        case .secondary:
                            guard let hit:Hit = self.probe(ray)
                            else 
                            {
                                plane.down(position, action: .pan)
                                self.anchor = .planar                           // ← anchor down (planar)
                                break
                            }
                            
                            switch hit 
                            {
                                case .gate(let mode):
                                    return mode 
                                
                                case .local(let identifier):
                                    self.active    = identifier
                                    self.anchor    = .vertex(identifier)        // ← anchor down (vertex)
                                    
                                    scene.selected = self.active 
                            } 
                        
                        case .tertiary:
                            plane.down(position, action: .pan)
                            self.anchor = .navigation                           // ← anchor down (tertiary)
                    }
                }
                
                return nil
            }
            
            func move(_ position:Math<Float>.V2, 
                scene:inout Scene, plane:inout ControlPlane)
            {
                scene.preselected = nil
                scene.snapped     = nil
                scene.deleted     = nil
                
                if let anchor:Anchor = self.anchor 
                {
                    switch anchor 
                    {
                        case .vertex(let active):
                            let ray:ControlPlane.Ray = plane.raycast(position)
                            let operation:Sphere.Operation = self.sphere.movePreview(active, ray: ray)
                            
                            scene.vertices.push(self.sphere.apply(to: active, operation: operation))
                            
                            switch operation 
                            {
                                case .unconstrained:
                                    scene.selected = active
                                
                                case .snapped:
                                    scene.selected = active
                                    scene.snapped  = active 
                                
                                case .deleted(let identifier):
                                    scene.deleted  = identifier
                                    scene.selected = nil
                            }
                            
                            return 
                        
                        case .planar, .navigation:
                            plane.move(position)
                    }
                }
                
                // purpose of preselect is to indicate what would happen in a 
                // primary or secondary action is taken at the current position 
                if self.intersectsFloating(position)
                {
                    
                }
                else 
                {
                    let ray:ControlPlane.Ray = plane.raycast(position)
                    guard let hit:Hit = self.probe(ray)
                    else 
                    {
                        return 
                    }
                    switch hit 
                    {
                        case .gate:
                            break 
                        
                        case .local(let identifier):
                            scene.preselected = identifier
                    }
                }
            }
            
            mutating 
            func up(_ position:Math<Float>.V2, action:Action, 
                scene:inout Scene, plane:inout ControlPlane) 
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
                        
                        case (.primary, .planar):
                            break
                            
                        case (.secondary, .planar), 
                             (.tertiary,  .navigation):
                            plane.up(position, action: .pan)
                            self.anchor = nil 
                        
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
    }
}
