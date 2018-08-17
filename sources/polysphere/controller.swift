struct Sphere 
{
    private 
    var points:[Math<Float>.V3]
    
    enum Operation 
    {
        case unconstrained(Math<Float>.V3), snapped(Math<Float>.V3), deleted(Int)
    }
    
    init(_ points:[Math<Float>.V3] = [])
    {
        self.points = points 
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
        let c:Math<Float>.V3 = ray.source, 
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
        let c:Math<Float>.V3 = ray.source, 
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
    
    @discardableResult
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
    
    @discardableResult
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
        return self.points
    }
    
    func apply(_ operation:Operation, addingAt index:Int) -> [Math<Float>.V3]
    {
        var vertices:[Math<Float>.V3] = self.apply()
        switch operation 
        {
            case .unconstrained(let destination), 
                 .snapped(      let destination):
                
                vertices.insert(destination, at: index)
            
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
                
                vertices[index] = destination
            
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
                enum Indicator 
                {
                    case unconfirmed(snapped:Bool), 
                         selected(snapped:Bool), 
                         deleted
                }
                
                var vertices:Lazy<[Math<Float>.V3]>
                
                var indicator:(index:Int, type:Indicator)?, 
                    preselection:Int?
                
                init(sphere:Sphere) 
                {
                    self.vertices = .mutated(sphere.apply())
                }
            }
            
            private 
            enum Anchor 
            {
                case addition(Int), movement(Int), navigation(Action)
            }
            
            private 
            var sphere:Sphere, 
                _selection:Int?, 
                anchor:Anchor?
            
            private 
            var selection:Int? 
            {
                return self._selection
            }
            
            init(sphere:Sphere)
            {
                self.sphere = sphere
            }
            
            private mutating  
            func select(_ index:Int?, scene:inout Scene)
            {
                self._selection = index                 
                scene.indicator = index.flatMap
                { 
                    ($0, Scene.Indicator.selected(snapped: false))
                }
            }
            private  
            func selectionSync(scene:inout Scene)
            {            
                scene.indicator = self.selection.flatMap
                { 
                    ($0, Scene.Indicator.selected(snapped: false))
                }
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
                let ray:ControlPlane.Ray = plane.raycast(position)
                defer 
                {
                    self.move(position, scene: &scene, plane: &plane)
                }
                
                if let anchor:Anchor = self.anchor 
                {
                    switch (action, anchor)
                    {
                        case (.tertiary, .addition), 
                             (.tertiary, .movement):
                            
                            self.selectionSync(scene: &scene)
                            scene.vertices.push(self.sphere.apply())
                            
                            plane.down(position, action: .pan)
                            fallthrough
                        
                        case (.tertiary, .navigation):
                            self.anchor = .navigation(.tertiary)                // ← anchor down (navigation)
                            
                            return nil
                        
                            
                        // confirm a point drag 
                        case (.double,  .addition(let index)), 
                             (.primary, .addition(let index)), 
                             (.double,  .movement(let index)), 
                             (.primary, .movement(let index)):
                            if case .addition = anchor 
                            {
                                if case .deleted = self.sphere.add(at: index, ray: ray) 
                                {
                                    self.selectionSync(scene: &scene)
                                }
                                else 
                                {
                                    self.select(index, scene: &scene)
                                }
                            }
                            else 
                            {
                                if case .deleted = self.sphere.move(index, ray: ray)
                                {
                                    self.select(nil, scene: &scene)
                                }
                                else 
                                {
                                    self.selectionSync(scene: &scene)
                                }
                            }
                            
                            scene.vertices.push(self.sphere.apply())
                            
                            self.anchor = nil                                   // → anchor up
                            return nil 
                            
                        
                        // cancel a point addition/drag
                        case (.secondary, .addition), 
                             (.secondary, .movement):
                            self.selectionSync(scene: &scene)
                            scene.vertices.push(self.sphere.apply())
                            
                            self.anchor = nil                                   // → anchor up
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
                    switch action 
                    {
                        case .double, .primary:
                            guard let hit:Hit = self.probe(ray)
                            else 
                            {
                                self.select(nil, scene: &scene)
                                
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
                                        let operation:Sphere.Operation = 
                                            self.sphere.previewAdd(at: index, ray: ray)
                                        
                                        scene.vertices.push(self.sphere.apply(operation, addingAt: index))
                                        
                                        self.select(nil, scene: &scene)
                                        switch operation 
                                        {
                                            case .unconstrained:
                                                scene.indicator = (index, .unconfirmed(snapped: false))
                                            case .snapped:
                                                scene.indicator = (index, .unconfirmed(snapped: true))
                                            case .deleted(let identifier):
                                                scene.indicator = (identifier, .deleted)
                                        }
                                    }
                                    else 
                                    {
                                        self.select(identifier, scene: &scene)
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
                                    self.select(identifier, scene: &scene)
                                    self.anchor = .movement(identifier)         // ← anchor down (vertex)
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
                let ray:ControlPlane.Ray = plane.raycast(position)
                if let anchor:Anchor = self.anchor 
                {
                    switch anchor 
                    {
                        case .addition(let index):
                            let operation:Sphere.Operation = self.sphere.previewAdd(at: index, ray: ray), 
                                vertices:[Math<Float>.V3]  = self.sphere.apply(operation, addingAt: index)
                            
                            switch operation
                            {
                                case .unconstrained:
                                    scene.indicator = (index, .unconfirmed(snapped: false))
                                case .snapped:
                                    scene.indicator = (index, .unconfirmed(snapped: true))
                                case .deleted(let identifier):
                                    scene.indicator = (identifier, .deleted)
                            }
                            
                            scene.vertices.push(vertices)
                            return 
                        
                        case .movement(let index):
                            
                            let operation:Sphere.Operation = self.sphere.previewMove(index, ray: ray), 
                                vertices:[Math<Float>.V3]  = self.sphere.apply(operation, moving: index)
                            
                            switch operation
                            {
                                case .unconstrained:
                                    scene.indicator    = (index, .selected(snapped: false))
                                    scene.preselection = index
                                case .snapped:
                                    scene.indicator    = (index, .selected(snapped: true))
                                    scene.preselection = index
                                case .deleted(let identifier):
                                    scene.indicator    = (identifier, .deleted)
                                    scene.preselection = nil
                            }
                            
                            scene.vertices.push(vertices)
                            return 
                        
                        case .navigation:
                            plane.move(position)
                    }
                }
                
                self.selectionSync(scene: &scene)
                self.preselect(position, ray, scene: &scene)
            }
            
            mutating 
            func up(_ position:Math<Float>.V2, action:Action, 
                scene:inout Scene, plane:inout ControlPlane) 
            {
                let ray:ControlPlane.Ray = plane.raycast(position)
                defer 
                {
                    self.preselect(position, ray, scene: &scene)
                }
                
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
            
            private 
            func preselect(_ position:Math<Float>.V2, _ ray:ControlPlane.Ray, scene:inout Scene)
            {
                if let anchor:Anchor = self.anchor 
                {
                    switch anchor 
                    {
                        case .addition:
                            scene.preselection = nil
                            return
                        
                        case .movement(let index):
                            scene.preselection = index
                            return
                        
                        case .navigation:
                            break
                    }
                }
                
                // purpose of preselect is to indicate what would happen in a 
                // primary or secondary action is taken at the current position 
                scene.preselection = nil
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
                            scene.preselection = identifier
                    }
                }
            }
        }
    }
}
