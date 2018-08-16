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
    
    private 
    func index(before index:Int) -> Int 
    {
        let initial:Int = index == self.points.startIndex ? self.points.endIndex : index
        return self.points.index(before: initial)
    }
    private 
    func index(after index:Int) -> Int 
    {
        let increment:Int = self.points.index(after: index)
        return increment == self.points.endIndex ? self.points.startIndex : increment
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
        
        return (self.index(before: index), self.index(after: index))
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
    
    func previewAdd(at index:Int, ray:ControlPlane.Ray) -> Operation
    {
        let destination:Math<Float>.V3 = self.attract(ray: ray)
        if let nearest:Int = self.nearest(to: destination, threshold: 0.1)
        {
            // check if the destination is within the radius of the adjacent points 
            let before:Int = self.index(before: index)
            if      nearest == before 
            {
                return .deleted(before)
            }
            else if nearest == index 
            {
                return .deleted(index)
            }
            
            return .snapped(self.points[nearest])
        }
        
        return .unconstrained(destination)
    }
    
    func previewMove(_ index:Int, ray:ControlPlane.Ray) -> Operation
    {
        let destination:Math<Float>.V3 = self.attract(ray: ray)
        if let nearest:Int = self.nearest(to: destination, threshold: 0.1, without: index)
        {
            // check if the destination is within the radius of the adjacent points 
            if  self.points.count > 1 
            {
                let before:Int = self.index(before: index), 
                    after:Int  = self.index(after: index)
                if      nearest == before 
                {
                    return .deleted(Sphere.collapse(index: before, around: index))
                }
                else if nearest == after 
                {
                    return .deleted(Sphere.collapse(index: after,  around: index))
                }
            }
            
            return .snapped(self.points[nearest])
        }
        
        return .unconstrained(destination)
    }
    
    mutating 
    func add(at index:Int, ray:ControlPlane.Ray) -> Operation
    {
        let operation:Operation = self.previewAdd(at: index, ray: ray)
        switch operation
        {
            case .unconstrained(let destination), 
                 .snapped(      let destination):
                self.points.insert(destination, at: index) 
            
            case .deleted:
                break
        }
        
        return operation
    }
    
    mutating 
    func move(_ index:Int, ray:ControlPlane.Ray) -> Operation
    {
        let operation:Operation = self.previewMove(index, ray: ray)
        switch operation
        {
            case .unconstrained(let destination), 
                 .snapped(      let destination):
                self.points[index] = destination 
            
            case .deleted:
                self.points.remove(at: index)
        }
        
        return operation
    }
    
    func apply() -> [Math<Float>.V3]
    {
        return self.points.map 
        {
            Math.add($0, self.center)
        }
    }
    
    func apply(_ operation:Operation, addingAt index:Int) -> [Math<Float>.V3]
    {
        var vertices:[Math<Float>.V3] = self.apply()
        switch operation 
        {
            case .unconstrained(let destination), 
                 .snapped(      let destination):
                
                vertices.insert(Math.add(destination, self.center), at: index)
            
            case .deleted:
                break
        }
        
        return vertices
    }
    
    func apply(_ operation:Operation, moving index:Int) -> [Math<Float>.V3]
    {
        var vertices:[Math<Float>.V3] = self.apply()
        switch operation 
        {
            case .unconstrained(let destination), 
                 .snapped(      let destination):
                
                vertices[index] = Math.add(destination, self.center)
            
            case .deleted:
                vertices.remove(at: index)
        }
        
        return vertices
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
                
                mutating 
                func updateIndicators(operation:Sphere.Operation, at index:Int)
                {
                    switch operation 
                    {
                        case .unconstrained:
                            self.selected = index
                        
                        case .snapped:
                            self.selected = index
                            self.snapped  = index 
                        
                        case .deleted(let identifier):
                            self.deleted  = identifier
                            self.selected = nil
                    }
                }
            }
            
            private 
            enum Anchor 
            {
                case addition(Int), movement(Int), navigation(Action)
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
                @inline(__always)
                func _reset()
                {
                    scene.vertices.push(self.sphere.apply())
                    scene.snapped      = nil
                    scene.deleted      = nil
                }
                
                if let anchor:Anchor = self.anchor 
                {
                    switch (action, anchor)
                    {
                        case (.tertiary, .addition), 
                             (.tertiary, .movement):
                            _reset()
                            
                            plane.down(position, action: .pan)
                            fallthrough
                        
                        case (.tertiary, .navigation):
                            self.anchor = .navigation(.tertiary)                // ← anchor down (navigation)
                            
                            return nil
                        
                            
                        // confirm a point drag 
                        case (.double,  .addition(let active)), 
                             (.primary, .addition(let active)), 
                             (.double,  .movement(let active)), 
                             (.primary, .movement(let active)):
                            let ray:ControlPlane.Ray = plane.raycast(position)
                            
                            let outcome:Sphere.Operation
                            if case .addition = anchor 
                            {
                                outcome = self.sphere.add(at: active, ray: ray)
                            }
                            else 
                            {
                                outcome = self.sphere.move(active, ray: ray)
                            }
                            
                            if case .deleted = outcome
                            {
                                self.active    = nil
                                scene.selected = nil 
                            }
                            
                            self.anchor = nil                                   // → anchor up
                            _reset()
                            return nil 
                            
                        
                        // cancel a point addition
                        case (.secondary, .addition):
                            self.active    = nil
                            scene.selected = nil 
                            fallthrough
                            
                        // cancel a point drag
                        case (.secondary, .movement):
                            self.anchor = nil                                   // → anchor up
                            _reset()
                            return nil 
                        
                        
                        case (.double,    .navigation), 
                             (.primary,   .navigation), 
                             (.secondary, .navigation):
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
                                plane.down(position, action: .pan)
                                self.anchor = .navigation(.primary)             // ← anchor down (navigation)
                                break
                            }
                            
                            switch hit 
                            {
                                case .gate(let mode):
                                    return mode 
                                
                                case .local(let identifier):
                                    if action == .double 
                                    {
                                        let index:Int = identifier + 1
                                        self.anchor   = .addition(index)        // ← anchor down (vertex)
                                        self.active   = index
                                        let operation:Sphere.Operation = 
                                            self.sphere.previewAdd(at: index, ray: ray)
                                        scene.vertices.push(self.sphere.apply(operation, addingAt: index))
                                        
                                        scene.updateIndicators(operation: operation, at: identifier)
                                    }
                                    else 
                                    {
                                        self.active    = identifier
                                        scene.selected = identifier
                                    }
                            }
                        
                        case .secondary:
                            guard let hit:Hit = self.probe(ray)
                            else 
                            {
                                plane.down(position, action: .pan)
                                self.anchor = .navigation(.secondary)           // ← anchor down (navigation)
                                break
                            }
                            
                            switch hit 
                            {
                                case .gate(let mode):
                                    return mode 
                                
                                case .local(let identifier):
                                    self.active    = identifier
                                    self.anchor    = .movement(identifier)      // ← anchor down (vertex)
                                    
                                    scene.selected = self.active 
                            } 
                        
                        case .tertiary:
                            plane.down(position, action: .pan)
                            self.anchor = .navigation(.tertiary)                // ← anchor down (tertiary)
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
                
                let ray:ControlPlane.Ray = plane.raycast(position)
                if let anchor:Anchor = self.anchor 
                {
                    switch anchor 
                    {
                        case .addition(let index), 
                             .movement(let index):
                            
                            let operation:Sphere.Operation, 
                                vertices:[Math<Float>.V3]
                            if case .addition = anchor 
                            {
                                operation = self.sphere.previewAdd(at: index, ray: ray)
                                vertices  = self.sphere.apply(operation, addingAt: index)
                            }
                            else 
                            {
                                operation = self.sphere.previewMove(index, ray: ray)
                                vertices  = self.sphere.apply(operation, moving: index)
                            }
                            
                            scene.vertices.push(vertices)
                            scene.updateIndicators(operation: operation, at: index)
                            
                            return 
                        
                        case .navigation:
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
                        
                        
                        case (_, .addition), 
                             (_, .movement):
                            break 
                            
                        case (_, .navigation(let beginning)):
                            guard action == beginning 
                            else 
                            {
                                break 
                            }
                            
                            plane.up(position, action: .pan)
                            self.anchor = nil 
                    }
                }
            }
        }
    }
}
