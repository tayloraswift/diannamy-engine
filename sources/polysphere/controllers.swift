import PNG

/* struct Sphere 
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
        // need to deal with case of sphere not centered at origin
        let c:Math<Float>.V3 = Math.sub((0, 0, 0), ray.source), 
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
        // need to deal with case of sphere not centered at origin
        let c:Math<Float>.V3 = Math.sub((0, 0, 0), ray.source), 
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
        
        return self.nearest(to: target, threshold: 0.02)
    }
    
    private static 
    func collapse(index:Int, around deleted:Int) -> Int 
    {
        return index <= deleted ? index : index - 1
    }
    
    func previewAdd(at index:Int, ray:ControlPlane.Ray) -> Operation
    {
        let destination:Math<Float>.V3 = self.attract(ray: ray)
        if let nearest:Int = self.nearest(to: destination, threshold: 0.02)
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
        if let nearest:Int = self.nearest(to: destination, threshold: 0.02, without: index)
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
} */

struct Model 
{
    struct Log 
    {
        var contents:[Unicode.Scalar] = []
    }
    
    var log:Log = .init()
    var map:[Math<Float>.V3] = [(0, 1, 1), (-1, -1, 1), (1, -1, 1)].map(Math.normalize(_:))
}

struct Coordinator 
{
    enum Event 
    {
        case terminalInput([Unicode.Scalar])
    }
    
    var controller:Controller.Root, 
        model:Model
        
    init()
    {
        self.model = .init()
        self.controller = .init()
        
        self.controller.sync(to: self.model)
    }
    
    mutating
    func resize(to size:Math<Float>.V2)
    {
        GL.viewport(anchor: (0, 0), size: Math.cast(size, as: Int.self))
        self.controller.resize(to: size)
    }
    
    mutating 
    func char(_ codepoint:Unicode.Scalar) 
    {
        self.handle(self.controller.char(self.model, codepoint))
    }
    
    mutating 
    func keypress(_ key:UI.Key) 
    {
        self.handle(self.controller.keypress(self.model, key))
    }
    
    mutating 
    func scroll(_ direction:UI.Direction) 
    {
        self.handle(self.controller.scroll(self.model, direction))
    }
    
    mutating 
    func down(_ action:UI.Action, _ position:Math<Float>.V2) 
    {
        self.handle(self.controller.down(self.model, action, position))
    }
    
    mutating 
    func move(_ position:Math<Float>.V2) 
    {
        self.handle(self.controller.move(self.model, position))
    }
    
    mutating 
    func up(_ action:UI.Action, _ position:Math<Float>.V2) 
    {
        self.handle(self.controller.up(self.model, action, position))
    }
    
    private mutating 
    func handle(_ event:Event?) 
    {
        guard let event:Event = event
        else 
        {
            return 
        }
        
        switch event 
        {
            case .terminalInput(let input):
                self.model.log.contents.append(contentsOf: input)
        }
    }
    
    mutating 
    func process(_ delta:Int) 
    {
        self.controller.process(self.model, delta)
    }
    
    mutating 
    func draw() 
    {
        self.controller.draw(self.model)
    }
}

enum Controller
{
    struct Root 
    {
        var mapEditor:MapEditor 
        
        init() 
        {
            self.mapEditor = .init()
        }
        
        mutating 
        func resize(to size:Math<Float>.V2) 
        {
            self.mapEditor.resize(to: size)
        }
        
        mutating 
        func char(_ model:Model, _ codepoint:Unicode.Scalar) -> Coordinator.Event?
        {
            return nil
        }
        
        mutating 
        func keypress(_ model:Model, _ key:UI.Key) -> Coordinator.Event?
        {
            return self.mapEditor.keypress(model, key)
        }
        
        mutating
        func scroll(_ model:Model, _ direction:UI.Direction) -> Coordinator.Event?
        {
            return self.mapEditor.scroll(model, direction)
        }
        
        mutating 
        func down(_ model:Model, _ action:UI.Action, _ position:Math<Float>.V2) -> Coordinator.Event?
        {
            return self.mapEditor.down(model, action, position)
        }
        
        mutating 
        func move(_ model:Model, _ position:Math<Float>.V2) -> Coordinator.Event?
        {
            return self.mapEditor.move(model, position)
        }
        
        mutating 
        func up(_ model:Model, _ action:UI.Action, _ position:Math<Float>.V2) -> Coordinator.Event?
        {
            return self.mapEditor.up(model, action, position)
        }
        
        mutating 
        func sync(to model:Model) 
        {
            self.mapEditor.sync(to: model)
        }
        
        mutating 
        func process(_ model:Model, _ delta:Int) 
        {
            self.mapEditor.process(model, delta)
        }
        
        mutating 
        func draw(_ model:Model)
        {
            GL.clear(color: true, depth: true)
            self.mapEditor.draw(model)
        }
    }
    
    struct MapEditor 
    {
        enum State 
        {
            case    none,
                    anchorSelected(Int), 
                    anchorMoving(Int, Math<Float>.V3), 
                    anchorNew(Int, Math<Float>.V3)
        }
        
        private 
        var state:State, 
            preselection:Int?
        
        private 
        var plane:ControlPlane, 
            cameraBlock:GL.Buffer<Camera.Storage>
        
        private 
        var view:View 
        
        init()
        {
            self.state        = .none 
            self.preselection = nil
            
            self.plane  = .init(.init(pivot: (0, 0, 0),
                                      angle: (0.25 * Float.pi, 1.75 * Float.pi),
                                   distance: 4,
                                focalLength: 32))
            
            self.cameraBlock = .generate()
            self.cameraBlock.bind(to: .uniform)
            {
                $0.reserve(capacity: 1, usage: .dynamic)
            }
            
            self.view = .init()
        }
        
        mutating 
        func resize(to size:Math<Float>.V2) 
        {
            // figure out center point of screen
            let shift:Math<Float>.V2 = Math.scale(size, by: -0.5)
            self.plane.sensor = (shift, Math.add(size, shift))
        }
        
        mutating 
        func keypress(_ model:Model, _ key:UI.Key) -> Coordinator.Event?
        {
            switch key
            {
                case .up:
                    self.plane.bump(.up, action: .track)
                case .down:
                    self.plane.bump(.down, action: .track)
                case .left:
                    self.plane.bump(.left, action: .track)
                case .right:
                    self.plane.bump(.right, action: .track)
                
                case .period:
                    self.plane.jump(to: (0, 0, 0))

                default:
                    Log.note("unrecognized key press (\(key))")
            }
            return nil
        }
        
        mutating
        func scroll(_ model:Model, _ direction:UI.Direction) -> Coordinator.Event?
        {
            self.plane.bump(direction, action: .zoom)
            return nil
        }
        
        mutating 
        func down(_ model:Model, _ action:UI.Action, _ position:Math<Float>.V2) -> Coordinator.Event?
        {
            self.plane.down(position, action: .pan)
            return nil
        }
        
        mutating 
        func move(_ model:Model, _ position:Math<Float>.V2) -> Coordinator.Event?
        {
            self.plane.move(position)
            return nil
        }
        
        mutating 
        func up(_ model:Model, _ action:UI.Action, _ position:Math<Float>.V2) -> Coordinator.Event?
        {
            self.plane.up(position, action: .pan)
            return nil
        }
        
        mutating 
        func sync(to model:Model) 
        {
            self.view.borders.push(state: self.state, model: model.map, sync: true)
        }
        
        mutating 
        func process(_ model:Model, _ delta:Int) 
        {
            self.plane.process(delta)
        }
        
        mutating 
        func draw(_ model:Model) 
        {
            self.cameraBlock.bind(to: .uniform, index: 0)
            {
                (target:GL.Buffer.BoundTarget) in

                // check if camera needs updating
                if let camera:Camera = self.plane.pop() 
                {
                    camera.withUnsafeBytes
                    {
                        target.subData($0)
                    }
                }
                
                self.view.draw()
            }
        }
    }
}

extension Controller.MapEditor 
{
    struct View 
    {
        struct Globe
        {
            private 
            let vao:GL.VertexArray, 
                vbo:GL.Buffer<Math<Float>.V3>,
                ebo:GL.Buffer<Math<UInt8>.V3>
            
            private 
            let _globetex:GL.Texture<PNG.RGBA<UInt8>>
            
            init()
            {
                self.ebo = .generate()
                self.vbo = .generate()
                self.vao = .generate()
                
                self._globetex = .generate()

                let cube:[Math<Float>.V3] =
                [
                     (-1, -1, -1),
                     ( 1, -1, -1),
                     ( 1,  1, -1),
                     (-1,  1, -1),

                     (-1, -1,  1),
                     ( 1, -1,  1),
                     ( 1,  1,  1),
                     (-1,  1,  1)
                ]

                let indices:[Math<UInt8>.V3] =
                [
                    (0, 2, 1),
                    (0, 3, 2),

                    (0, 1, 5),
                    (0, 5, 4),

                    (1, 2, 6),
                    (1, 6, 5),

                    (2, 3, 7),
                    (2, 7, 6),

                    (3, 0, 4),
                    (3, 4, 7),

                    (4, 5, 6),
                    (4, 6, 7)
                ]

                self.vbo.bind(to: .array)
                {
                    $0.data(cube, usage: .static)

                    self.vao.bind().setVertexLayout(.float(from: .float3))

                    self.ebo.bind(to: .elementArray)
                    {
                        $0.data(indices, usage: .static)
                        self.vao.unbind()
                    }
                }
                
                let (image, size):([PNG.RGBA<UInt8>], (x:Int, y:Int)) = 
                    try! PNG.rgba(path: "/home/klossy/downloads/world.topo.bathy.200401.3x5400x2700.png", of: UInt8.self)
                
                
                self._globetex.bind(to: .texture2d)
                {
                    $0.data(.init(image, shape: size), layout: .rgba8, storage: .rgba8)
                    $0.setMagnificationFilter(.linear)
                    $0.setMinificationFilter(.linear, mipmap: .linear)
                    $0.generateMipmaps()
                }
            }
            
            func draw()
            {
                Programs.sphere.bind
                {
                    $0.set(float4: "sphere", (0, 0, 0, 1))
                    self._globetex.bind(to: .texture2d, index: 1)
                    {
                        self.vao.drawElements(0 ..< 36, as: .triangles, indexType: UInt8.self)
                    }
                }
            }
        }
        
        struct Borders 
        {
            typealias Index = UInt32 
            
            @_fixed_layout
            @usableFromInline
            struct Vertex 
            {
                let position:Math<Float>.V3, 
                    id:Int32
                
                init(_ position:Math<Float>.V3, id:Int)
                {
                    self.init(position, id: Int32(truncatingIfNeeded: id))
                }
                
                init(_ position:Math<Float>.V3, id:Int32)
                {
                    self.position = position 
                    self.id       = id
                }
            }
            
            struct Indices
            {
                let indices:[Index]
                
                private 
                let partition:Int 
                
                var segments:(fixed:Range<Int>, interpolated:Range<Int>)
                {
                    let fixed:Range<Int>        = 0              ..< self.partition, 
                        interpolated:Range<Int> = self.partition ..< indices.count
                    return (fixed, interpolated)
                }
                
                init(fixed:[Index], interpolated:[Index]) 
                {
                    self.partition = fixed.count 
                    self.indices   = fixed + interpolated
                }
            }
            
            private 
            let vao:GL.VertexArray
            private 
            var vvo:GL.Vector<Vertex>, 
                evo:GL.Vector<Index>
                
            private 
            var indexSegments:(fixed:Range<Int>, interpolated:Range<Int>)
            
            private 
            var indicator:Int32     = -1, 
                preselection:Int32  = -1, 
                fixed:[Vertex]?     = nil
            
            init()
            {
                self.evo = .generate()
                self.vvo = .generate()
                self.vao = .generate()
                
                self.indexSegments = (0 ..< 0, 0 ..< 0)
                
                self.vvo.buffer.bind(to: .array)
                {
                    self.vao.bind().setVertexLayout(.float(from: .float3), .int(from: .int))
                    self.evo.buffer.bind(to: .elementArray)
                    {
                        self.vao.unbind()
                    }
                }
            }
            
            private static 
            func subdivide(_ loops:[[Vertex]], resolution:Float = 0.1) 
                -> (vertices:[Vertex], indices:Indices)
            {
                var vertices:[Vertex] = [], 
                    indices:(fixed:[Index], interpolated:[Index]) = ([], []) 
                for loop:[Vertex] in loops
                {
                    let base:Index = Index(vertices.count) 
                    for j:Int in loop.indices
                    {
                        let i:Int = loop.index(before: j == loop.startIndex ? loop.endIndex : j)
                        // get two vertices and angle between
                        let edge:Math<Vertex>.V2 = (loop[i], loop[j])
                        let d:Float     = Math.dot(edge.0.position, edge.1.position), 
                            φ:Float     = .acos(d), 
                            scale:Float = 1 / (1 - d * d).squareRoot()
                        // determine subdivisions 
                        let subdivisions:Int = Int(φ / resolution) + 1
                        
                        // push the fixed vertex 
                        indices.fixed.append(Index(vertices.count))
                        vertices.append(edge.0)
                        // push the interpolated vertices 
                        for s:Int in 1 ..< subdivisions
                        {
                            let t:Float = Float(s) / Float(subdivisions)
                            
                            // slerp!
                            let sines:Math<Float>.V2   = (.sin(φ - φ * t), .sin(φ * t)), 
                                factors:Math<Float>.V2 = Math.scale(sines, by: scale)
                            
                            let components:Math<Math<Float>.V3>.V2 
                            components.0 = Math.scale(edge.0.position, by: factors.0) 
                            components.1 = Math.scale(edge.1.position, by: factors.1) 
                            
                            let interpolated:Math<Float>.V3 = Math.add(components.0, components.1)
                            
                            vertices.append(.init(interpolated, id: edge.0.id))
                        }
                    }
                    
                    // compute lines-adjacency indices
                    let totalDivisions:Index = Index(vertices.count) - base
                    for primitive:Index in 0 ..< totalDivisions
                    {
                        indices.interpolated.append(base +  primitive    )
                        indices.interpolated.append(base + (primitive + 1) % totalDivisions)
                        indices.interpolated.append(base + (primitive + 2) % totalDivisions)
                        indices.interpolated.append(base + (primitive + 3) % totalDivisions)
                    }
                }
                
                return (vertices, .init(fixed: indices.fixed, interpolated: indices.interpolated))
            }
            
            mutating 
            func push(state:State, model:[Math<Float>.V3], sync:Bool = false) 
            {
                switch state
                {
                    case .none:
                        if sync 
                        {
                            self.fixed = model.enumerated().map{ .init($0.1, id: $0.0) }
                        }
                        self.indicator = -1
                    
                    case .anchorSelected(let index):
                        if sync 
                        {
                            self.fixed = model.enumerated().map{ .init($0.1, id: $0.0) }
                        }
                        self.indicator = .init(index)
                    
                    case .anchorMoving(let index, let position):
                        var fixed:[Vertex] = model.enumerated().map{ .init($0.1, id: $0.0) }
                        fixed[index] = .init(position, id: -2)
                        self.fixed = fixed
                        self.indicator = -1
                    
                    case .anchorNew(let index, let position):
                        var fixed:[Vertex] = model.enumerated().map{ .init($0.1, id: $0.0) }
                        fixed.insert(.init(position, id: -3), at: index)
                        self.fixed = fixed
                        self.indicator = -1
                }
            }
            
            mutating 
            func push(preselection:Int?) 
            {
                self.preselection = .init(preselection ?? -1)
            }
            
            mutating 
            func draw() 
            {
                if let fixed:[Vertex] = self.fixed 
                {
                    let (vertices, indices):([Vertex], Indices) = Borders.subdivide([fixed])
                    self.vvo.assign(data: vertices,        in: .array,        usage: .dynamic)
                    self.evo.assign(data: indices.indices, in: .elementArray, usage: .dynamic)
                    
                    self.indexSegments = indices.segments
                    
                    self.fixed = nil
                }
                
                Programs.borderPolyline.bind 
                {
                    $0.set(float:  "thickness", 2)
                    $0.set(float4: "frontColor", (1, 1, 1, 1))
                    $0.set(float4: "backColor",  (1, 1, 1, 0))
                    self.vao.drawElements(self.indexSegments.interpolated, as: .linesAdjacency, indexType: Index.self)
                }
                
                Programs.borders.bind 
                {
                    $0.set(int: "indicator",    self.indicator)
                    $0.set(int: "preselection", self.preselection)
                    self.vao.drawElements(self.indexSegments.fixed, as: .points, indexType: Index.self)
                }
                
                Programs.borderLabels.bind 
                {
                    $0.set(int: "indicator",    self.indicator)
                    $0.set(int: "preselection", self.preselection)
                    
                    $0.set(float4: "monoFontMetrics", Programs.monofont.metrics)
                    Programs.monofont.texture.bind(to: .texture2d, index: 0)
                    {
                        self.vao.drawElements(self.indexSegments.fixed, as: .points, indexType: Index.self)
                    }
                }
            }
        }
        
        var globe:Globe, 
            borders:Borders
        
        init()
        {
            self.globe   = .init()
            self.borders = .init()
        }
        
        mutating 
        func draw()
        {
            GL.enable(.culling)
            
            GL.disable(.multisampling)
            
            GL.enable(.blending)
            GL.blend(.mix)
            self.globe.draw() 
            
            GL.enable(.multisampling)
            GL.blend(.add)
            self.borders.draw()
        }
    }
}
/* 
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
} */
