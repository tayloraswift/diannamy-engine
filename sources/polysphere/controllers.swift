import PNG

import class Foundation.JSONEncoder
import class Foundation.JSONDecoder
import struct Foundation.Data

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
    
        mutating 
        func print(_ string:[Unicode.Scalar]) 
        {
            self.contents.append(contentsOf: string)
        }
        
        mutating 
        func print(_ string:String, terminator:String = "\n") 
        {
            self.contents.append(contentsOf: string.unicodeScalars)
            self.contents.append(contentsOf: terminator.unicodeScalars)
        }
    }
    
    struct Map 
    {
        // points are quasi-normalized, meaning we do our best to keep them sensible 
        // unit-length vectors, but should make no hard assumptions
        var points:[Math<Float>.V3], 
            backgroundImage:String?
        
        var background:GL.Texture<PNG.RGBA<UInt8>>
        
        init(quasiUnitLengthPoints points:[Math<Float>.V3], backgroundImage:String? = nil) 
        {
            self.points             = points 
            self.background         = .generate()
            self.backgroundImage    = backgroundImage
            
            self.reloadBackgroundImage()
        }
        
        mutating 
        func replace(background path:String) -> String?
        {
            // "/home/klossy/downloads/world.topo.bathy.png"
            self.backgroundImage = path
            return self.reloadBackgroundImage()
        }
        
        mutating 
        func clear() -> String?
        {
            self.backgroundImage = nil 
            return self.reloadBackgroundImage()
        }
        
        @discardableResult
        private mutating 
        func reloadBackgroundImage() -> String?
        {
            guard let path:String = self.backgroundImage 
            else 
            {
                // generate checkerboard
                let image:Array2D<PNG.RGBA<UInt8>> = .init(size: (16, 16)) 
                {
                    ($0.y & 1 + $0.x) & 1 == 0 ? .init(60, .max) : .init(200, .max)
                }
                
                self.background.bind(to: .texture2d)
                {
                    $0.data(image, layout: .rgba8, storage: .rgba8)
                    $0.setMagnificationFilter(.nearest)
                    $0.setMinificationFilter(.nearest, mipmap: nil)
                }
                
                return nil
            }
            
            guard let (image, size):([PNG.RGBA<UInt8>], (x:Int, y:Int)) = 
                try? PNG.rgba(path: path, of: UInt8.self)
            else 
            {
                return "could not read file '\(path)'"
            }
            
            self.background.bind(to: .texture2d)
            {
                $0.data(.init(image, size: size), layout: .rgba8, storage: .rgba8)
                $0.setMagnificationFilter(.linear)
                $0.setMinificationFilter(.linear, mipmap: .linear)
                $0.generateMipmaps()
            }
            
            return nil
        }
        
        func findNearest(to location:Math<Float>.V3, threshold:Float) -> Int? 
        {
            var gamma:Float = -1, 
                index:Int?  = nil 
            for (i, point):(Int, Math<Float>.V3) in self.points.enumerated()
            {
                let g:Float = Math.dot(point, location)
                if g > gamma 
                {
                    gamma = g
                    index = i
                }
            }
            
            return gamma > Float.cos(threshold) ? index : nil
        }
    }
    
    var log:Log 
    var map:Map
    
    init() 
    {
        self.log = .init()
        self.map = .init(quasiUnitLengthPoints: [(1, 0, 1), (0, 1, 1), (-1, 0, 1), (0, -1, 1)].map(Math.normalize(_:)))
        
        self.log.print("> ", terminator: "")
    }
    
    mutating 
    func input(_ input:[Unicode.Scalar]) -> Coordinator.Event?
    {
        self.log.print(input)
        
        let commands:[ArraySlice<Unicode.Scalar>] = input.dropLast().split(separator: " ")
        
        defer 
        {
            self.log.print("> ", terminator: "")
        }
        
        guard let first:String = (commands.first.map{ .init($0.map(Character.init(_:))) })
        else 
        {
            return nil
        }
        
        let arguments:[String] = commands.dropFirst().map{ .init($0.map(Character.init(_:))) }
        
        switch first 
        {
        case "help":
            self.log.print("press ctrl-1 to toggle terminal")
        case "exit":
            return .toggleTerminal
        
        case "mapedit":
            guard let second:String = arguments.first
            else 
            {
                self.log.print("Usage: mapedit COMMAND [PARAMS]...")
                return nil
            }
            
            switch second 
            {
            case "background":
                var suppliedPath:String?    = nil, 
                    clear:Bool              = false
                for argument:String in arguments[1...] 
                {
                    switch argument 
                    {
                    case "-c", "--clear":
                        clear = true 
                    case "-h", "--help":
                        self.log.print(
                            """
                            Usage: mapedit background [OPTION] FILE
                            Change the background image on the globe.
                            
                              -h, --help        display this message
                              -c, --clear       remove the background image from the globe
                            """)
                        return nil
                    case "":
                        break
                    default:
                        guard argument[argument.startIndex] != "-" 
                        else 
                        {
                            self.log.print("unrecognized option '\(argument)'")
                            return nil
                        }
                        
                        if suppliedPath != nil 
                        {
                            self.log.print("error: too many outputs specified")
                            return nil
                        }
                        
                        suppliedPath = argument
                    }
                }
                
                if clear 
                {
                    self.map.clear().map 
                    {
                        self.log.print($0)
                    }
                }
                else 
                {
                    self.map.replace(background: suppliedPath ?? "mapeditor-background.png").map
                    { 
                        self.log.print($0) 
                    }
                }
            
            case "save":
                var suppliedPath:String?    = nil, 
                    force:Bool              = false
                for argument:String in arguments[1...] 
                {
                    switch argument 
                    {
                    case "-f", "--force":
                        force = true 
                    case "":
                        break
                    default:
                        guard argument[argument.startIndex] != "-" 
                        else 
                        {
                            self.log.print("unrecognized option '\(argument)'")
                            return nil
                        }
                        
                        if suppliedPath != nil 
                        {
                            self.log.print("error: too many outputs specified")
                            return nil
                        }
                        
                        suppliedPath = argument
                    }
                }
                
                let encoder:Foundation.JSONEncoder  = .init()
                encoder.outputFormatting = .prettyPrinted
                
                do 
                {
                    let data:Foundation.Data = try encoder.encode(self.map), 
                        buffer:[UInt8]       = .init(data)
                    
                    let path:String = suppliedPath ?? "map.json"
                    do 
                    {
                        try File.write(buffer, to: path, overwrite: force)
                        self.log.print("(mapedit) saved map as '\(path)'")
                    }
                    catch
                    {
                        self.log.print("(mapedit) \(error)")
                    }
                }
                catch
                {
                    self.log.print("(mapedit) error: \(error)")
                }
            
            case "load": 
                var suppliedPath:String?    = nil
                for argument:String in arguments[1...] 
                {
                    switch argument 
                    {
                    case "":
                        break
                    default:
                        guard argument[argument.startIndex] != "-" 
                        else 
                        {
                            self.log.print("unrecognized option '\(argument)'")
                            return nil
                        }
                        
                        if suppliedPath != nil 
                        {
                            self.log.print("error: too many inputs specified")
                            return nil
                        }
                        
                        suppliedPath = argument
                    }
                }
                
                let decoder:Foundation.JSONDecoder  = .init()
                
                do 
                {
                    let path:String          = suppliedPath ?? "map.json"
                    let data:Foundation.Data = .init(try File.read(path))
                    
                    self.map = try decoder.decode(Map.self, from: data)
                    self.log.print("(mapedit) loaded map '\(path)'")
                    
                    return .mapSync(reset: true)
                }
                catch
                {
                    self.log.print("(mapedit) error: \(error)")
                }
            
            default:
                self.log.print("(mapedit) unrecognized command '\(second)'")
            }
            
        default:
            self.log.print("unrecognized command '\(first)'")
        }
        
        return nil
    }
    
    mutating 
    func input(_ string:String) -> Coordinator.Event?
    {
        return self.input([Unicode.Scalar](string.unicodeScalars) + ["\n"])
    }
}

struct Coordinator 
{
    struct Context 
    {
        var viewport:Math<Float>.V2, 
            model:Model 
        
        enum Mutation 
        {
            case viewport
            case model 
        }
    }
    
    struct Base:LayerController 
    {
        var frame:Math<Float>.Rectangle = ((0, 0), (0, 0))
    }
    
    enum Event 
    {
        case toggleTerminal
        case terminalInput([Unicode.Scalar])
        
        case mapSync(reset:Bool)
        
        case mapPointMoved(Int, Math<Float>.V3)
        case mapPointAdded(Int, Math<Float>.V3)
        case mapPointRemoved(Int)
    }
    
    var context:Context
    var controllers:[LayerController] 
    
    var definitions:Style.Definitions 
    
    var buttons:UI.Action.BitVector, 
        active:Int, 
        hover:Int? // only managed by emitLeaveCalls(_:)
    
    let displayBlock:UBO.DisplayBlock
    
    var activeController:LayerController
    {
        get 
        {
            return self.controllers[self.active]
        }
        set(v)
        {
            self.controllers[self.active] = v
        }
    }
    
    init()
    {
        self.context        = .init(viewport: (0, 0), model: .init())
        self.controllers    = 
        [
            Base.init(), 
            Controller.MapEditor.init()
        ]
        
        let faceinfo:[Style.Definitions.Face: (String, Int)] = 
        [
            .mono55:    ("assets/fonts/SourceCodePro-Medium.otf",      16), 
            .text55:    ("assets/fonts/SourceSansPro-Regular.ttf",     16), 
            .text56:    ("assets/fonts/SourceSansPro-Italic.ttf",      16), 
            .text75:    ("assets/fonts/SourceSansPro-Bold.ttf",        16), 
            .text76:    ("assets/fonts/SourceSansPro-BoldItalic.ttf",  16)
        ]
        
        self.definitions    = .init(faces: faceinfo)
        
        self.buttons        = .init()
        self.active         = self.controllers.endIndex - 1
        self.hover          = nil
        
        self.displayBlock   = .init()
    }
    
    private mutating 
    func emitLeaveCalls(newHover index:Int?) 
    {
        guard let old:Int = self.hover 
        else 
        {
            self.hover = index 
            return 
        }
        
        guard   let new:Int = index, 
                    new == old 
        else 
        {
            self.handle(self.controllers[old].leave(self.context))
            self.hover = index 
            return 
        }
    }
    
    private 
    func find(_ position:Math<Float>.V2) -> Int
    {
        // search controllers from top to bottom, 
        // can bind by let value since `LayerController.test(_:)` is non-mutating
        for (index, controller):(Int, LayerController) in 
            zip(self.controllers.indices, self.controllers).reversed() 
        {
            if controller.test(position) 
            {
                return index 
            }
        }
        
        Log.fatal("base layer went missing!")
    }
    
    mutating
    func window(size:Math<Float>.V2)
    {
        GL.viewport(anchor: (0, 0), size: Math.cast(size, as: Int.self))
        self.context.viewport = size 
        
        for index:Int in self.controllers.indices 
        {
            self.controllers[index].frame = ((0, 0), size)
            
            self.controllers[index].notify(.viewport, in: self.context, reset: false) 
        }
    }
    
    mutating 
    func paste(_ string:String) 
    {
        for character:Character in string 
        {
            self.character(character)
        }
    }
    
    mutating 
    func character(_ character:Character) 
    {
        self.handle(self.activeController.character(self.context, character)) 
    }
    
    mutating 
    func keypress(_ key:UI.Key, _ modifiers:UI.Key.Modifiers) 
    {
        self.handle(self.activeController.keypress(self.context, key, modifiers)) 
    }
    
    mutating 
    func scroll(_ direction:UI.Direction, _ position:Math<Float>.V2) 
    {
        let index:Int = self.find(position) 
        self.handle(self.controllers[index].scroll(self.context, direction, position))
    }
    
    mutating 
    func down(_ action:UI.Action, _ position:Math<Float>.V2, doubled:Bool) 
    {
        self.buttons[action] = true 
        
        self.active = self.find(position)  
        self.handle(self.activeController.down(self.context, action, position, doubled: doubled))
        
        self.move(position)
    }
    
    mutating 
    func move(_ position:Math<Float>.V2) 
    {
        let index:Int = self.buttons.any ? self.active : self.find(position)
        self.emitLeaveCalls(newHover: index)
        self.handle(self.controllers[index].move(self.context, position))
    }
    
    mutating 
    func up(_ action:UI.Action, _ position:Math<Float>.V2) 
    {
        self.buttons[action] = false 
        
        self.handle(self.activeController.up(self.context, action, position))
        
        self.move(position)
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
        case .toggleTerminal:
            break
            
        case .terminalInput(let input):
            // self.handle(self.model.input(input))
            // self.controller.terminal.sync(to: self.model)
            break 
        
        case .mapSync(let reset):
            self.notify(.model, to: .all(Controller.MapEditor.self), reset: reset)
        
        case .mapPointMoved(let index, let location):
            // notify isn’t strictly necessary for this case or .mapPointAdded, 
            // as the controllers will already be in a clean state, but we notify 
            // as confirmation anyway
            self.context.model.map.points[index] = Math.normalize(location)
            self.notify(.model, to: .all(Controller.MapEditor.self))
        
        case .mapPointAdded(let index, let location):
            self.context.model.map.points.insert(Math.normalize(location), at: index)
            self.notify(.model, to: .all(Controller.MapEditor.self))
        
        case .mapPointRemoved(let index):
            self.context.model.map.points.remove(at: index)
            self.notify(.model, to: .all(Controller.MapEditor.self))
        }
    }
    
    mutating 
    func process(_ delta:Int) -> Bool 
    {
        var redraw:Bool = false 
        for index:Int in self.controllers.indices 
        {
            redraw = self.controllers[index].process(self.context, delta) || redraw
        }
        
        return redraw
    }
    
    mutating 
    func draw() 
    {
        GL.clear(color: true, depth: true)
        for index:Int in self.controllers.indices 
        {
            self.displayBlock.bind(index: 0) 
            {
                UBO.DisplayBlock.encode( frame: self.controllers[index].frame, 
                                      viewport: self.context.viewport, 
                                            to: $0)
                self.controllers[index].draw(self.context, definitions: self.definitions)
            }
        }
    }
    
    
    // broadcasting APIs 
    enum Target 
    {
        case all(LayerController.Type)
    }
    
    private mutating 
    func notify(_ mutation:Context.Mutation, to target:Target, reset:Bool = false) 
    {
        switch target 
        {
        case .all(let metatype):
            for index:Int in self.controllers.indices where type(of: self.controllers[index]) == metatype
            {
                self.controllers[index].notify(mutation, in: self.context, reset: reset)
            }
        }
    }
}

protocol LayerController 
{
    var frame:Math<Float>.Rectangle { get set }
    
    // context mutation notifier
    mutating 
    func notify(_:Coordinator.Context.Mutation, in:Coordinator.Context, reset:Bool)
    
    // geometric intersection function 
    func test(_ position:Math<Float>.V2) -> Bool 
    
    // event handlers
    mutating 
    func character(_:Coordinator.Context, _ character:Character) -> Coordinator.Event?
    
    mutating 
    func keypress(_:Coordinator.Context, _ key:UI.Key, _ modifiers:UI.Key.Modifiers) -> Coordinator.Event?
    
    mutating
    func scroll(_:Coordinator.Context, _ direction:UI.Direction, _ position:Math<Float>.V2) -> Coordinator.Event?
    
    mutating 
    func down(_:Coordinator.Context, _ action:UI.Action, _ position:Math<Float>.V2, doubled:Bool) -> Coordinator.Event?
    
    mutating 
    func move(_:Coordinator.Context, _ position:Math<Float>.V2) -> Coordinator.Event?
    
    mutating 
    func leave(_:Coordinator.Context) -> Coordinator.Event?
    
    mutating 
    func up(_:Coordinator.Context, _ action:UI.Action, _ position:Math<Float>.V2) -> Coordinator.Event?
    
    // stream-called functions
    mutating 
    func process(_:Coordinator.Context, _ delta:Int) -> Bool 
    
    mutating 
    func draw(_:Coordinator.Context, definitions:Style.Definitions)
}
extension LayerController 
{
    func notify(_:Coordinator.Context.Mutation, in _:Coordinator.Context, reset _:Bool)
    {
    }
    
    // default implementations (ignore all events)
    func test(_ position:Math<Float>.V2) -> Bool 
    {
        return true 
    }
    
    func character(_:Coordinator.Context, _:Character) -> Coordinator.Event?
    {
        return nil 
    }
    func keypress(_:Coordinator.Context, _:UI.Key, _:UI.Key.Modifiers) -> Coordinator.Event?
    {
        return nil
    }
    func scroll(_:Coordinator.Context, _:UI.Direction, _:Math<Float>.V2) -> Coordinator.Event?
    {
        return nil
    }
    func down(_:Coordinator.Context, _:UI.Action, _:Math<Float>.V2, doubled _:Bool) -> Coordinator.Event?
    {
        return nil
    }
    func move(_:Coordinator.Context, _:Math<Float>.V2) -> Coordinator.Event?
    {
        return nil
    }
    func leave(_:Coordinator.Context) -> Coordinator.Event?
    {
        return nil
    }
    func up(_:Coordinator.Context, _:UI.Action, _:Math<Float>.V2) -> Coordinator.Event?
    {
        return nil
    }
    
    func process(_:Coordinator.Context, _:Int) -> Bool
    { 
        return false
    }
    func draw(_:Coordinator.Context, definitions _:Style.Definitions) 
    { 
    }
}

// Equatable conformance not required in base type definition to allow Latest<Void> 
// to work. Basic definition does not expose self.value, but there’s no point in 
// reading self.value if T is Void.
protocol ViewEquatable 
{
    static 
    func viewEquivalent(_:Self, _:Self) -> Bool 
}
struct Latest<T>
{
    private 
    var _value:T, 
        dirty:Bool 
    
    var isDirty:Bool 
    {
        return self.dirty
    }
    
    init(_ value:T) 
    {
        self._value = value 
        self.dirty  = true 
    }
    
    mutating 
    func reset() 
    {
        self.dirty = true
    }
    
    mutating 
    func pop() -> T? 
    {
        if self.dirty 
        {
            self.dirty = false 
            return self._value 
        }
        else 
        {
            return nil 
        }        
    }
    
    mutating 
    func get() -> T 
    {
        self.dirty = false 
        return self._value
    }
}
extension Latest where T:Equatable 
{
    var value:T 
    {
        get 
        {
            return self._value 
        }
        set(value)
        {
            if value != self._value  
            {
                self.dirty  = true 
            }
            self._value = value 
        }
    }
}
extension Latest where T:ViewEquatable
{
    var value:T 
    {
        get 
        {
            return self._value 
        }
        set(value)
        {
            if !T.viewEquivalent(value, self._value)  
            {
                self.dirty  = true 
            }
            self._value = value 
        }
    }
}

enum Controller
{
    /* struct Terminal 
    {
        struct History 
        {
            private 
            var history:[[Unicode.Scalar]]
            
            private(set)
            var active:Int, 
                cursor:Int 
            
            init() 
            {
                self.history = [[]]
                self.active  = self.history.endIndex - 1
                self.cursor  = 0
            }
            
            var input:[Unicode.Scalar] 
            {
                get 
                {
                    return self.history[self.active]
                }
                set(value) 
                {
                    self.history[self.active] = value
                }
            }
            
            mutating 
            func prev() 
            {
                guard self.active > self.history.startIndex 
                else 
                {
                    return 
                }
                
                self.active -= 1 
                self.cursor  = self.input.endIndex
            }
            
            mutating 
            func next() 
            {
                guard self.active < self.history.endIndex - 1 
                else 
                {
                    return 
                }
                
                self.active += 1 
                self.cursor  = self.input.endIndex
            }
            
            mutating 
            func new() -> [Unicode.Scalar] 
            {
                defer 
                {
                    if self.history[self.history.endIndex - 1].isEmpty 
                    {
                        self.active = self.history.endIndex - 1
                    }
                    else 
                    {
                        self.history.append([])
                        self.active = self.history.endIndex - 1
                    }
                }
                
                return self.input
            }
            
            mutating 
            func left()
            {
                guard self.cursor > self.input.startIndex 
                else 
                {
                    return 
                }
                
                self.cursor -= 1
            }
            
            mutating 
            func right()
            {
                guard self.cursor < self.input.endIndex 
                else 
                {
                    return 
                }
                
                self.cursor += 1
            }
            
            mutating 
            func insert(_ codepoint:Unicode.Scalar) 
            {
                self.input.insert(codepoint, at: self.cursor)
                self.cursor += 1
            }
            
            mutating 
            func backspace() 
            {
                guard self.cursor > self.input.startIndex 
                else 
                {
                    return 
                }
                
                self.cursor -= 1
                self.input.remove(at: self.cursor)
            }
            
            mutating 
            func clear() 
            {
                self.input  = []
                self.cursor = self.input.endIndex
            }
        }
        
        private 
        var history:History, 
        
            area:Math<Float>.Rectangle, 
            viewport:Math<Float>.V2, 
        
            view:View 
        
        init()
        {
            self.history    = .init()
            
            self.area       = ((0, 0), (0, 0))
            self.viewport   = (0, 0)
            
            self.view       = .init()
        }
        
        private 
        func composeText(_ log:Model.Log) -> [(Unicode.Scalar, Math<UInt8>.V4)] 
        {
            return log.contents.map{ ($0, (100, 255, 255, 255)) } + self.history.input.map{ ($0, (.max, .max, .max, .max)) }
        }
        
        private 
        func layout(_ text:[(Unicode.Scalar, Math<UInt8>.V4)], atlas:FontAtlas) 
            -> (layout:[(Unicode.Scalar, Math<UInt8>.V4, Math<Int>.V2)], template:Math<Float>.Rectangle)
        {
            let delta64:Math<Int>.V2 = Math.maskUp((atlas["\u{0}"].advance64, atlas.height64), exponent: 6), 
                linelength:Int       = Int(self.area.b.x - self.area.a.x) / (delta64.x >> 6)
            
            let cursorIndex:Int = text.endIndex - self.history.input.count + self.history.cursor
            
            var line:Int = 0, 
                layout:[(Unicode.Scalar, Math<UInt8>.V4, Math<Int>.V2)] = []
                layout.reserveCapacity(text.count + 1)
            var n:Int = text.endIndex
            while line < Int(self.area.b.y - self.area.a.y) / (delta64.y >> 6)
            {
                guard n >= text.startIndex 
                else 
                {
                    break
                }
                
                var begin:Int = n - 1
                split: 
                while begin >= text.startIndex 
                {
                    switch text[begin].0
                    {    
                    case "\r":
                        line  -= 1
                        fallthrough
                    case "\n":
                        break split 
                    default:
                        begin -= 1
                    }
                }
                
                // count how many physical lines this line will span 
                let height:Int = (n - begin) / linelength + ((n - begin) % linelength).signum()
                line += height
                
                var position:Math<Int>.V2 = (0, line)
                for (codepoint, color):(Unicode.Scalar, Math<UInt8>.V4) in text[begin + 1 ..< n] 
                {
                    if position.x == linelength 
                    {
                        position.x  = 0
                        position.y -= 1
                    }
                    
                    layout.append((codepoint, color, position))
                    
                    position.x += 1
                }
                
                // place cursor 
                if begin + 1 ... n ~= cursorIndex 
                {
                    let offset:Int = cursorIndex - begin - 1
                    
                    layout.append(("_", (0, 255, 255, .max), (offset % linelength, line - offset / linelength)))
                }
                
                n = begin
            }
            
            let delta:Math<Float>.V2  = Math.cast((delta64.x >> 6, delta64.y >> 6), as: Float.self), 
                origin:Math<Float>.V2 = Math.round(self.area.a)
            
            return (layout, (origin, Math.add(origin, delta)))
        }
        
        private mutating 
        func show(with model:Model) 
        {
            let atlas:FontAtlas = Fonts.terminal.atlas
            let (layout, template):([(Unicode.Scalar, Math<UInt8>.V4, Math<Int>.V2)], Math<Float>.Rectangle) = 
                self.layout(self.composeText(model.log), atlas: atlas)
            self.view.render(layout, template: template, atlas: atlas)
        }
        
        mutating 
        func setViewport(_ model:Model, _ viewport:Math<Float>.V2) 
        {
            // figure out center point of screen
            let a:Math<Float>.V2 = (20,                                                              20), 
                b:Math<Float>.V2 = (max((viewport.x * 0.5).rounded() - 20, 30), max(viewport.y - 20, 30))
            self.area = (a, b)
            
            self.show(with: model)
            
            self.viewport = viewport
        }
        
        mutating 
        func char(_ model:Model, _ codepoint:Unicode.Scalar) -> Coordinator.Event?
        {
            self.history.insert(codepoint)
            self.show(with: model)
            
            return nil
        }
        mutating 
        func keypress(_ model:Model, _ key:UI.Key, _ modifiers:UI.Key.Modifiers) -> Coordinator.Event?
        {
            switch key 
            {
                case .enter:
                    let input:[Unicode.Scalar] = self.history.new() + ["\n"]
                    return .terminalInput(input)
                
                case .backspace:
                    self.history.backspace()
                    self.show(with: model)
                
                case .left:
                    self.history.left()
                    self.show(with: model)
                
                case .right:
                    self.history.right()
                    self.show(with: model)
                
                case .up:
                    self.history.prev()
                    self.show(with: model)
                
                case .down:
                    self.history.next()
                    self.show(with: model)
                
                default:
                    break
            }
            
            return nil
        }
        
        mutating 
        func sync(to model:Model) 
        {
            self.history.clear()
            self.show(with: model)
        }
        
        mutating 
        func draw(_ model:Model)
        {
            self.view.draw(viewport: self.viewport)
        }
    } */
    
    struct MapEditor:LayerController
    {
        enum Action:Equatable
        {
            case    none,
                    anchorSelected(Int), 
                    anchorMoving(Int, Math<Float>.V3), 
                    anchorNew(Int, Math<Float>.V3)
            // adding new case? REMEMBER TO ADD `==` IMPLEMENTATION
            
            static 
            func == (a:Action, b:Action) -> Bool 
            {
                switch (a, b) 
                {
                    case (.none, .none):
                        return true 
                    case (.anchorSelected(let i1), .anchorSelected(let i2)):
                        return i1 == i2 
                    case (.anchorMoving(let i1, let p1), .anchorMoving(let i2, let p2)):
                        return i1 == i2 && p1 == p2 
                    case (.anchorNew(let i1, let p1), .anchorNew(let i2, let p2)):
                        return i1 == i2 && p1 == p2
                    
                    default:
                        return false 
                }
            }
        }
        
        // interface for communicating with Self.View 
        struct State 
        {
            var model:Latest<Void>
            
            var action:Latest<Action> 
            var preselection:Latest<Int?>
            
            var plane:ControlPlane
        }
        
        
        var frame:Math<Float>.Rectangle = ((0, 0), (0, 0))
        {
            didSet 
            {
                self.plane.queueUpdate()
            }
        }
        
        
        private 
        var view:View, 
            state:State 
        
        // other properties 
        private 
        var hotspots:[Math<Float>.V2?]
        
        // state variables 
        private 
        var action:Action 
        {
            get         { return    self.state.action.value }
            set(value)  {           self.state.action.value = value }
        }
        private 
        var preselection:Int? 
        {
            get         { return    self.state.preselection.value }
            set(value)  {           self.state.preselection.value = value }
        }
        
        private 
        var plane:ControlPlane 
        {
            get         { return    self.state.plane }
            set(value)  {           self.state.plane = value }
        }
        
        
        init()
        {
            let plane:ControlPlane = .init(  .init(center: (0, 0, 0),
                                orientation: .init(),
                                   distance: 4,
                                focalLength: 32))
                                
            self.state  = .init(model: .init(()), 
                               action: .init(.none), 
                         preselection: .init(nil), 
                                plane: plane)
            self.view   = .init()
            
            self.hotspots = []
        }
        
        
        mutating 
        func notify(_ member:Coordinator.Context.Mutation, in context:Coordinator.Context, reset:Bool)
        {
            switch member 
            {
            case .viewport:
                self.plane.viewport(context.viewport)
            
            case .model:
                self.state.model.reset() 
                if reset
                {
                    self.action         = .none
                    self.preselection   = nil 
                }
            }
        }
        
        
        func test(_ position:Math<Float>.V2) -> Bool  
        {
            return true 
        }
        
        
        // project a sphere point into 2D
        private  
        func trace(_ point:Math<Float>.V3, viewport:Math<Float>.V2) -> Math<Float>.V2?
        {
            guard Math.dot(Math.sub(point, self.plane.position), Math.sub(point, (0, 0, 0))) < 0 
            else 
            {
                return nil 
            }
            
            return Math.mult(viewport, self.plane.trace(point))
        }
        
        private mutating 
        func updateHotspots(_ points:[Math<Float>.V3], viewport:Math<Float>.V2) 
        {
            self.hotspots = points.map 
            {
                self.trace($0, viewport: viewport)
            }
        }
        
        private mutating 
        func updateHotspot(_ point:Math<Float>.V3, at index:Int, viewport:Math<Float>.V2) 
        {
            self.hotspots[index] = self.trace(point, viewport: viewport)
        }
        
        private mutating 
        func insertHotspot(_ point:Math<Float>.V3, at index:Int, viewport:Math<Float>.V2) 
        {
            self.hotspots.insert(self.trace(point, viewport: viewport), at: index)
            self.reindex(after: index, offset: 1)
        }
        
        private mutating 
        func removeHotspot(at index:Int) 
        {
            self.hotspots.remove(at: index)
            self.reindex(after: index, offset: -1)
        }
        
        private mutating 
        func reindex(after index:Int, offset:Int) 
        {
            if let preselection:Int = self.preselection
            {
                if preselection > index 
                {
                    self.preselection = preselection + offset
                }
                else if preselection == index 
                {
                    self.preselection = nil
                }
            }
        }
        
        private 
        func findHotspot(_ position:Math<Float>.V2, threshold:Float) -> Int? 
        {
            var g2:Float   = .infinity, 
                index:Int? = nil 
            for (i, hotspot):(Int, Math<Float>.V2?) in self.hotspots.enumerated()
            {
                guard let hotspot:Math<Float>.V2 = hotspot 
                else 
                {
                    continue 
                }
                
                let r2:Float = Math.eusq(Math.sub(hotspot, position))
                if  r2 < g2
                {
                    g2    = r2
                    index = i
                }
            }
            
            return g2 < threshold * threshold ? index : nil
        }
        
        mutating 
        func keypress(_ context:Coordinator.Context, _ key:UI.Key, _ modifiers:UI.Key.Modifiers) -> Coordinator.Event?
        {
            switch key
            {
            case .up:
                self.plane.bump(.up,    action: .track)
            case .down:
                self.plane.bump(.down,  action: .track)
            case .left:
                self.plane.bump(.left,  action: .track)
            case .right:
                self.plane.bump(.right, action: .track)
            
            case .period:
                self.plane.jump(to: (0, 0, 0))
            
            case .backspace, .delete:
                switch self.action 
                {
                case .none:
                    break 
                case .anchorSelected(let index):
                    if case .backspace = key 
                    {
                        if context.model.map.points.count > 1 
                        {
                            self.action = .anchorSelected((index == 0 ? context.model.map.points.count - 1 : index) - 1)
                        }
                        else 
                        {
                            self.action = .none 
                        }
                    }
                    else 
                    {
                        if context.model.map.points.count > 1 
                        {
                            self.action = .anchorSelected(index == context.model.map.points.count - 1 ? 0 : index)
                        }
                        else 
                        {
                            self.action = .none 
                        }
                    }
                    self.removeHotspot(at: index)
                    return .mapPointRemoved(index)
                
                case .anchorMoving(let index, _):
                    self.action = .none 
                    self.removeHotspot(at: index)
                    return .mapPointRemoved(index)
                case .anchorNew:
                    self.action = .none 
                }
            
            case .tab:
                switch self.action 
                {
                case .anchorSelected(let index):
                    let next:Int 
                    if modifiers.shift 
                    {
                        next = index - 1 < 0 ? context.model.map.points.count - 1 : index - 1
                    }
                    else 
                    {
                        next = index + 1 < context.model.map.points.count ? index + 1 : 0
                    }
                    self.action = .anchorSelected(next)
                
                default:
                    break
                }

            default:
                break
            }
            return nil
        }
        
        mutating
        func scroll(_:Coordinator.Context, _ direction:UI.Direction, _:Math<Float>.V2) -> Coordinator.Event?
        {
            self.plane.bump(direction, action: .zoom)
            return nil
        }
        
        mutating 
        func down(_ context:Coordinator.Context, _ button:UI.Action, _ position:Math<Float>.V2, doubled:Bool) -> Coordinator.Event?
        {
            switch button 
            {
            case .primary:
                if  doubled, 
                    case .anchorSelected(let index) = self.action
                {
                    let p:Math<Float>.V3 = self.plane.project(position, on: (0, 0, 0), radius: 1)
                    self.action = .anchorNew(index + 1, Math.normalize(p)) 
                    break 
                }
                
                switch self.action 
                {
                case .none, .anchorSelected:
                    if let i:Int = self.findHotspot(position, threshold: 8) 
                    {
                        self.action = .anchorSelected(i)
                    }
                    else 
                    {
                        self.action = .none
                        self.plane.down(position, button: button)
                    }
                
                case .anchorMoving(let index, let location):
                    self.action = .anchorSelected(index)
                    self.updateHotspot(location, at: index, viewport: context.viewport)
                    return .mapPointMoved(index, location)
                
                case .anchorNew(let index, let location):
                    self.action = .anchorSelected(index)
                    self.insertHotspot(location, at: index, viewport: context.viewport)
                    return .mapPointAdded(index, location)
                }
            
            case .secondary:
                switch self.action 
                {
                case .none, .anchorSelected:
                    if let i:Int = self.findHotspot(position, threshold: 8) 
                    {
                        self.action = .anchorMoving(i, context.model.map.points[i])
                    }
                    else 
                    {
                        self.action = .none
                    }
                
                case .anchorMoving(let index, _), .anchorNew(let index, _):
                    self.action = .anchorSelected(index)
                }
            
            default:
                break
            }
            
            return nil
        }
        
        mutating 
        func move(_:Coordinator.Context, _ position:Math<Float>.V2) -> Coordinator.Event?
        {
            // prevents meaningless preselection toggles, which needlessly set 
            // dirty flags in the state structure
            var preselection:Int? = nil 
            defer 
            {
                self.preselection = preselection
            }
            
            switch self.action 
            {
            case .none, .anchorSelected:
                if let i:Int = self.findHotspot(position, threshold: 8) 
                {
                    preselection = i
                }
            
                self.plane.move(position)
            
            case .anchorMoving(let index, _):
                let p:Math<Float>.V3 = self.plane.project(position, on: (0, 0, 0), radius: 1)
                self.action = .anchorMoving(index, Math.normalize(p))
            
            case .anchorNew(let index, _):
                let p:Math<Float>.V3 = self.plane.project(position, on: (0, 0, 0), radius: 1)
                self.action = .anchorNew(index, Math.normalize(p))
            }
            
            return nil
        }
        
        mutating 
        func leave(_:Coordinator.Context) -> Coordinator.Event? 
        {
            self.preselection = nil
            return nil 
        }
        
        mutating 
        func up(_:Coordinator.Context, _ button:UI.Action, _ position:Math<Float>.V2) -> Coordinator.Event?
        {
            self.plane.up(position, button: button)
            return nil
        }
        
        mutating 
        func process(_ context:Coordinator.Context, _ delta:Int) -> Bool 
        {
            return self.plane.process(delta, viewport: context.viewport, frame: self.frame)
        }
        
        mutating 
        func draw(_ context:Coordinator.Context, definitions:Style.Definitions) 
        {
            if self.plane.mutated 
            {
                self.updateHotspots(context.model.map.points, viewport: context.viewport)
            }
            
            self.view.draw(context.model, definitions: definitions, state: &self.state)
        }
    }
}

/* extension Controller.Terminal 
{
    struct View 
    {
        @_fixed_layout
        @usableFromInline
        struct Vertex 
        {
            var xy:Math<Float>.V2, 
                uv:Math<Float>.V2, 
                
                color:Math<UInt8>.V4
            
            init(_ xy:Math<Float>.V2, uv:Math<Float>.V2, color:Math<UInt8>.V4)
            {
                self.xy = xy
                self.uv = uv
                self.color = color
            }
        }
        
        private 
        let vao:GL.VertexArray
        var vvo:GL.Vector<Math<Vertex>.V2>
        
        init() 
        {
            self.vao = .generate()
            self.vvo = .generate()
            
            self.vvo.buffer.bind(to: .array)
            {
                self.vao.bind().setVertexLayout(.float(from: .float2), .float(from: .float2), .float(from: .ubyte4_rgba))
                self.vao.unbind()
            }
        }
        
        mutating 
        func render(_ layout:[(Unicode.Scalar, Math<UInt8>.V4, Math<Int>.V2)], template:Math<Float>.Rectangle, atlas:FontAtlas) 
        {
            let delta:Math<Float>.V2        = Math.sub(template.b, template.a), 
                glyphs:[Math<Vertex>.V2]    = layout.map 
            {
                let origin:Math<Float>.V2   = 
                    Math.add(template.a, Math.mult(delta, Math.cast($0.2, as: Float.self)))
                
                let glyph:FontAtlas.Glyph   = atlas[$0.0]
                
                return 
                    (
                        .init(Math.add(origin, Math.cast(glyph.rectangle.a, as: Float.self)), uv: glyph.uv.a, color: $0.1), 
                        .init(Math.add(origin, Math.cast(glyph.rectangle.b, as: Float.self)), uv: glyph.uv.b, color: $0.1)
                    )
            }
            
            self.vvo.assign(data: glyphs, in: .array, usage: .dynamic)
        }
        
        func draw(viewport:Math<Float>.V2) 
        {
            Programs.text.bind 
            {
                $0.set(float2: "viewport", viewport)
                Fonts.terminal.texture.bind(to: .texture2d, index: 2)
                {
                    self.vao.draw(0 ..< self.vvo.count << 1, as: .lines)
                }
            }
        }
    }
} */

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
            
            init()
            {
                self.ebo = .generate()
                self.vbo = .generate()
                self.vao = .generate()

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
            }
            
            func draw(_ model:Model.Map)
            {
                Programs.sphere.bind
                {
                    $0.set(float4: "sphere", (0, 0, 0, 1))
                    model.background.bind(to: .texture2d, index: 1)
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
                var position:Math<Float>.V3, 
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
            
            enum Selection:Equatable
            {
                // when adding cases UPDATE EQUATABLE CONFORMANCE
                case select(Int, Math<Float>.V3)
                case move(Int, Math<Float>.V3)
                case new(Math<Float>.V3)
                case none
                
                func labelSphere(at offset:Math<Float>.V3) -> (Math<Float>.V3, [(Set<Style.Selector>, String)])?
                {
                    let selectors:Set<Style.Selector> = [.mapeditor, .label, .selection], 
                        bold:Set<Style.Selector> = selectors.union([.strong])
                    let parts:(String, String), 
                        point:Math<Float>.V3, 
                        classes:Set<Style.Selector>
                    
                    switch self 
                    {
                    case    .select(let index, _), 
                            .move(let index, _):
                        parts.0 = "0:\(index)"
                                        
                    case .new:
                        parts.0 = "0:+"
                    
                    case .none:
                        return nil
                    }
                    
                    switch self 
                    {
                    case    .select(_, let location), 
                            .move(_, let location), 
                            .new(let location):
                        parts.1 = "   \(Selection.formatLL(Math.spherical(normalized: location)))"
                        point   = Math.add(location, offset)
                    
                    case .none:
                        return nil
                    }
                    
                    switch self 
                    {
                    case .select:
                        classes = []
                    case .move:
                        classes = [.move]
                                        
                    case .new:
                        classes = [.new]
                    
                    case .none:
                        return nil
                    }
                    
                    return (point, [(bold.union(classes), parts.0), (selectors.union(classes), parts.1)])
                }
                
                private static 
                func formatLL(_ s:Math<Float>.S2) -> String 
                {
                    let degreesN:Float = 90 - s.θ * (180 / Float.pi), 
                        degreesE:Float =      s.φ * (180 / Float.pi)
                    
                    let N:(d:Int, m:Int, s:Int) = sexagesimal(abs(degreesN)),
                        E:(d:Int, m:Int, s:Int) = sexagesimal(abs(degreesE))
                    
                    let Nm:String = padZero(N.m, to: 2), 
                        Ns:String = padZero(N.s, to: 2)
                    let Em:String = padZero(E.m, to: 2), 
                        Es:String = padZero(E.s, to: 2)
                    return "\(N.d)° \(Nm)′ \(Ns)′′ \(degreesN < 0 ? "S" : "N"), \(E.d)° \(Em)′ \(Es)′′ \(degreesE < 0 ? "W" : "E")"
                }
                
                private static 
                func sexagesimal(_ rd:Float) -> (d:Int, m:Int, s:Int) 
                {
                    let  s:Int                          = .init((60 * 60 * rd).rounded())
                    let (m,       seconds):(Int, Int)   = s.quotientAndRemainder(dividingBy: 60), 
                        (degrees, minutes):(Int, Int)   = m.quotientAndRemainder(dividingBy: 60)
                    
                    return (degrees, minutes, seconds)
                }
                
                private static 
                func padZero(_ x:Int, to count:Int) -> String 
                {
                    let string:String = .init(x)
                    return .init(repeating: "0", count: max(count - string.count, 0)) + string
                }
                
                static 
                func == (a:Selection, b:Selection) -> Bool 
                {
                    switch (a, b) 
                    {
                    case    (.select(let a0, let a1), .select(let b0, let b1)), 
                            (.move(let a0, let a1), .move(let b0, let b1)):
                        return a0 == b0 && a1 == b1
                    
                    case    (.new(let a0), .new(let b0)):
                        return a0 == b0
                    
                    case    (.none, .none):
                        return true 
                    
                    default:
                        return false
                    }
                }
            }
            enum Preselection:Equatable 
            {
                case preselect(Int, Math<Float>.V3)
                case occluded(Int)
                case none
                
                func labelSphere(at offset:Math<Float>.V3) -> (Math<Float>.V3, [(Set<Style.Selector>, String)])?
                {
                    let bold:Set<Style.Selector> = [.mapeditor, .label, .preselection, .strong]
                    switch self 
                    {
                    case .preselect(let index, let location):
                        return (Math.add(offset, location), [(bold, "0:\(index)")])
                    
                    case .occluded, .none:
                        return nil
                    }
                }
                
                static 
                func == (a:Preselection, b:Preselection) -> Bool 
                {
                    switch (a, b) 
                    {
                    case (.preselect(let i1, let l1), .preselect(let i2, let l2)):
                        return i1 == i2 && l1 == l2 
                    
                    case (.occluded(let i1), .occluded(let i2)):
                        return i1 == i2 
                    
                    case (.none, .none):
                        return true 
                    
                    default:
                        return false 
                    }
                }
            }
            
            private 
            let vao:GL.VertexArray
            private 
            var vvo:GL.Vector<Vertex>, 
                evo:GL.Vector<Index>
                
            private 
            var textvao:GL.VertexArray, 
                textvvo:GL.Vector<Text.Vertex>
                
            private 
            var indexSegments:(fixed:Range<Int>, interpolated:Range<Int>)
            
            private 
            var selection:Selection         = .none, 
                preselection:Preselection   = .none
            
            // whether the constructued border geometry deviates from the model
            private 
            var deviance:Bool = false 
            
            init()
            {
                self.evo = .generate()
                self.vvo = .generate()
                self.vao = .generate()
                self.textvao = .generate()
                self.textvvo = .generate()
                
                self.indexSegments = (0 ..< 0, 0 ..< 0)
                
                self.vvo.buffer.bind(to: .array)
                {
                    self.vao.bind().setVertexLayout(.float(from: .float3), .int(from: .int))
                    self.evo.buffer.bind(to: .elementArray)
                    {
                        self.vao.unbind()
                    }
                }
                
                self.textvvo.buffer.bind(to: .array)
                {
                    self.textvao.bind().setVertexLayout(
                        .float(from: .float2), 
                        .float(from: .float2), 
                        .float(from: .ubyte4_rgba), 
                        .float(from: .float3))
                    self.textvao.unbind()
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
                            φ:Float     = .acos(max(-1, min(d, 1))), 
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
            func rebuild(_ loops:[[Vertex]]) 
            {
                let (vertices, indices):([Vertex], Indices) = Borders.subdivide(loops)
                self.vvo.assign(data: vertices,        in: .array,        usage: .dynamic)
                self.evo.assign(data: indices.indices, in: .elementArray, usage: .dynamic)
                
                self.indexSegments = indices.segments
            }
            
            mutating 
            func draw(_ model:Model.Map, definitions:Style.Definitions, state controllerState:inout State) 
            {
                let preselection:Preselection, 
                    selection:Selection
                rebuild:
                if let action:Action = controllerState.action.pop()
                {
                    let controlPoints:[Vertex]
                    
                    switch action
                    {
                    case .none:
                        selection = .none
                        
                        if controllerState.model.pop() != nil || self.deviance 
                        {
                            controlPoints = model.points.enumerated().map{ .init($0.1, id: $0.0) }
                            self.deviance = false
                        }
                        else 
                        {
                            break rebuild 
                        }
                    
                    case .anchorSelected(let index):
                        selection = .select(index, model.points[index])
                        
                        if controllerState.model.pop() != nil || self.deviance 
                        {
                            controlPoints = model.points.enumerated().map{ .init($0.1, id: $0.0) }
                            self.deviance = false
                        }
                        else 
                        {
                            break rebuild
                        }
                    
                    case .anchorMoving(let index, let position):
                        // get() call clears dirty flag
                        controllerState.model.get() 
                        
                        selection = .move(index, position)
                        
                        var fixed:[Vertex] = model.points.enumerated().map{ .init($0.1, id: $0.0) }
                        fixed[index].position   = position
                        controlPoints           = fixed
                        
                        self.deviance = true
                    
                    case .anchorNew(let index, let position):
                        controllerState.model.get() 
                        
                        selection = .new(position)
                        
                        var fixed:[Vertex] = model.points.enumerated().map{ .init($0.1, id: $0.0) }
                        fixed.insert(.init(position, id: -1), at: index)
                        controlPoints           = fixed
                        
                        self.deviance = true
                    }
                    
                    self.rebuild([controlPoints])
                }
                else if controllerState.model.pop() != nil
                {
                    selection = self.selection 
                    self.rebuild([model.points.enumerated().map{ .init($0.1, id: $0.0) }])
                    self.deviance = false 
                }
                else 
                {
                    selection = self.selection
                }
                
                // clear preselection if both the selection and preselection point 
                // to the same vertex
                let selectionIndex:Int?, 
                    preselectionIndex:Int?
                switch selection 
                {
                case    .select(let index, _), 
                        .move(let index, _):
                    selectionIndex = index
                
                case    .new, .none:
                    selectionIndex = nil 
                }
                
                if let update:Int? = controllerState.preselection.pop() 
                {
                    preselectionIndex = update 
                }
                else 
                {
                    switch self.preselection 
                    {
                    case    .preselect(let index, _), 
                            .occluded(let index):
                        preselectionIndex = index 
                    case    .none:
                        preselectionIndex = nil 
                    }
                }
                
                if let i1:Int = preselectionIndex 
                {
                    if let i2:Int = selectionIndex, i1 == i2 
                    {
                        preselection = .occluded(i1)
                    }
                    else 
                    {
                        preselection = .preselect(i1, model.points[i1])
                    }
                }
                else 
                {
                    preselection = .none
                }
                
                if selection != self.selection || preselection != self.preselection 
                {
                    var textVertices:[Text.Vertex]  = []
                    if let (point, label):(Math<Float>.V3, [(Set<Style.Selector>, String)]) = selection.labelSphere(at: (0, 0, 0)) 
                    {
                        for text:Text in definitions.line(label) 
                        {
                            textVertices.append(contentsOf: text.vertices(at: (20, 20), tracing: point))
                        }
                    } 
                    if let (point, label):(Math<Float>.V3, [(Set<Style.Selector>, String)]) = preselection.labelSphere(at: (0, 0, 0)) 
                    {
                        for text:Text in definitions.line(label) 
                        {
                            textVertices.append(contentsOf: text.vertices(at: (20, 20), tracing: point))
                        }
                    } 
                    
                    self.textvvo.assign(data: textVertices, in: .array, usage: .dynamic)
                    
                    self.selection     = selection 
                    self.preselection  = preselection 
                }
                
                Programs.borderPolyline.bind 
                {
                    $0.set(float:  "thickness", 2)
                    $0.set(float4: "frontColor", (0.5, 0.5, 0.5, 1))
                    $0.set(float4: "backColor",  (0.1, 0.1, 0.1, 1))
                    self.vao.drawElements(self.indexSegments.interpolated, as: .linesAdjacency, indexType: Index.self)
                }
                
                Programs.borderNodes.bind 
                {
                    let indicator:Int32
                    switch self.selection 
                    {
                        case .select(let index, _):
                            indicator = .init(index) << 1 | 0
                        
                        case .move(let index, _):
                            indicator = .init(index) << 1 | 1
                        
                        case .new, .none:
                            indicator = -1
                    }
                    let preselection:Int32
                    switch self.preselection 
                    {
                        case .preselect(let index, _):
                            preselection = .init(index)
                        
                        case .occluded, .none:
                            preselection = -1
                    }
                    $0.set(int: "indicator",    indicator)
                    $0.set(int: "preselection", preselection)
                    self.vao.drawElements(self.indexSegments.fixed, as: .points, indexType: Index.self)
                }
                
                Programs.tracingText.bind 
                {
                    _ in 
                    definitions.atlas.texture.bind(to: .texture2d, index: 2)
                    {
                        self.textvao.draw(0 ..< self.textvvo.count, as: .lines)
                    }
                }
            }
        }
        
        private 
        var globe:Globe, 
            borders:Borders
        
        private 
        let cameraBlock:UBO.CameraBlock
        
        private 
        var textvao:GL.VertexArray, 
            textvvo:GL.Vector<Text.Vertex>, 
            textRendered:Bool = false 
        
        init()
        {
            self.globe   = .init()
            self.borders = .init()
            
            self.cameraBlock = .init()
            
            self.textvao = .generate()
            self.textvvo = .generate()
            
            self.textvvo.buffer.bind(to: .array)
            {
                self.textvao.bind().setVertexLayout(
                    .float(from: .float2), 
                    .float(from: .float2), 
                    .float(from: .ubyte4_rgba), 
                    .padding(MemoryLayout<Math<Float>.V3>.stride))
                self.textvao.unbind()
            }
        }
        
        mutating 
        func draw(_ model:Model, definitions:Style.Definitions, state controllerState:inout State)
        {
            if !textRendered 
            {
                let runs:[(Set<Style.Selector>, String)] = 
                [
                    ([],                    "012345 Hello world! "), 
                    ([.emphasis],           "This text is italic! There \n\nonce was a girl known by "), 
                    ([.emphasis, .strong],  "everyone"), 
                    ([.strong],             " and no one. efficiency. 012345") 
                ]
                
                let text:[Text] = definitions.paragraph(runs, linebox: (150, 20), block: [.paragraph])
                let vertices:[Text.Vertex] = text.flatMap 
                {
                    $0.vertices(at: (20, 20))
                }
                self.textvvo.assign(data: vertices, in: .array, usage: .static)
                textRendered = true 
            }
            
            self.cameraBlock.bind(index: 1)
            {
                // check if camera needs updating
                if let matrices:Camera.Matrices = controllerState.plane.pop()
                {
                    UBO.CameraBlock.encode(matrices: matrices, to: $0)
                    Log.note("camera updated")
                }
                
                GL.enable(.culling)
                
                GL.disable(.multisampling)
                
                GL.enable(.blending)
                GL.blend(.mix)
                self.globe.draw(model.map) 
                
                GL.enable(.multisampling)
                GL.blend(.add)
                self.borders.draw(model.map, definitions: definitions, state: &controllerState)
            }
            
            Programs.text.bind 
            {
                _ in 
                definitions.atlas.texture.bind(to: .texture2d, index: 2)
                {
                    self.textvao.draw(0 ..< self.textvvo.count, as: .lines)
                }
            }
        }
    }
}

/* enum Layout 
{
    enum Element 
    {
        case block(Block)
        case inlineBlock(InlineBlock)
        case inline(Inline)
    }
    
    struct Block 
    {
        var children:[Element]
    }
    struct InlineBlock 
    {
        var children:[Element]
    }
} */
