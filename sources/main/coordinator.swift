/* @propertyWrapper 
final 
class State<Value>
{
    private(set)
    var sequence:UInt = 0
    var wrappedValue:Value 
    {
        didSet 
        {
            self.sequence &+= 1
        }
    }
    var projectedValue:State
    {
        self 
    }
    
    var binding:Binding 
    {
        .init(self)
    }
    
    init(wrappedValue:Value) 
    {
        self.wrappedValue = wrappedValue
    }
    
    @propertyWrapper 
    struct Binding  
    {
        @State 
        var wrappedValue:Value 
        var projectedValue:Binding  
        {
            get 
            {
                self
            }
            set(binding)
            {
                self = binding
            }
        }
        
        private 
        var sequence:UInt? 
        
        var mutated:Bool 
        {
            self.sequence.map{ $0 != self.$wrappedValue.sequence } ?? true
        }
        
        fileprivate 
        init(_ state:State<Value>)
        {
            self._wrappedValue  = state
            self.sequence       = nil 
        }
        
        mutating 
        func update() 
        {
            self.sequence = self.$wrappedValue.sequence 
        }
        
        mutating 
        func reset() 
        {
            self.sequence = nil 
        }
    }
} */



/* protocol LayerController 
{
    func contribute(text:inout [UI.Text.DrawElement])
    func contribute(geometry:inout [UI.Geometry.DrawElement])
    
    mutating 
    func event(_ event:UI.Event, pass:UI.Event.Pass) -> Bool 
    
    mutating 
    func process(delta:Int) -> Bool 
    
    mutating 
    func viewport(_ viewport:Vector2<Float>)
}
extension LayerController 
{
    func contribute(text _:inout [UI.Text.DrawElement])
    {
    }
    func contribute(geometry _:inout [UI.Geometry.DrawElement])
    {
    }
    
    func event(_:UI.Event, pass _:UI.Event.Pass) -> Bool 
    {
        return false 
    }
    
    func process(delta _:Int) -> Bool 
    {
        return false 
    }
    
    func viewport(_ viewport:Vector2<Float>) 
    {
    }
} */

// different view rects:
//
//                      window 
//            -1,1                             1,1
//  +-----------+-------------------------------+
//  |           |        frame                  |
//  |           |     +---------+               |
//  |           |     |         |               |
//  |           |     |         |               |
//  |           |     +---------+               |
//  |           |                               |
//  +-----------+-------------------------------+
//            -1,-1        viewport            1,-1 

class Controller//:LayerController
{
    // UI
    private 
    var focus:UI.Group? 
    {
        didSet(old) 
        {
            switch (old, self.focus) 
            {
            case (let old?, let new?):
                if old !== new 
                {
                    old.state.focus = false 
                    new.state.focus = true 
                    
                    old.action(.defocus)
                }
            
            case (let old?, nil):
                old.state.focus = false 
                old.action(.defocus)
            
            case (nil, let new?):
                new.state.focus = true 
            
            case (nil, nil):
                break 
            }
        }
    }
    private 
    var active:UI.Group? 
    {
        didSet(old) 
        {
            switch (old, self.active) 
            {
            case (let old?, let new?):
                if old !== new 
                {
                    old.state.active = false 
                    new.state.active = true 
                    
                    old.action(.deactivate)
                }
            
            case (let old?, nil):
                old.state.active = false 
                old.action(.deactivate)
            
            case (nil, let new?):
                new.state.active = true 
            
            case (nil, nil):
                break 
            }
        }
    }
    private 
    var hover:UI.Group? 
    {
        didSet(old) 
        {
            switch (old, self.hover) 
            {
            case (let old?, let new?):
                if old !== new 
                {
                    old.state.hover = false 
                    new.state.hover = true 
                    
                    old.action(.dehover)
                }
            
            case (let old?, nil):
                old.state.hover = false 
                old.action(.dehover)
            
            case (nil, let new?):
                new.state.hover = true 
            
            case (nil, nil):
                break 
            }
        }
    }
    
    private 
    let ui:UI.Element.Block, 
        isolines:Editor.Isolines,
        plane:Editor.Plane3D
    private 
    var layers:[UI.Group] 
    {
        [self.ui, self.isolines, self.plane]
    }
    
    // button and label handles 
    private 
    let buttons:
    (
        renormalize:UI.Element.Button,
        background:UI.Element.Button, 
        bake:UI.Element.Button, 
        
        labels:
        (
            renormalize:UI.Element.P,
            background:UI.Element.P,
            bake:UI.Element.P
        )
    )
    private 
    var allButtons:[UI.Element.Button] 
    {
        [
            self.buttons.renormalize,
            self.buttons.background,
            self.buttons.bake,
        ]
    }
    //
    
    private 
    let cameraBuffer:GPU.Buffer.Uniform<UInt8>
    
    private 
    let cube: 
    (
        vao:GPU.Vertex.Array<Mesh.Vertex, UInt8>, 
        texture:GPU.Texture.Cube<Vector4<UInt8>>
    )
    private 
    let points:GPU.Vertex.Array<Mesh.ColorVertex, UInt32>,
        isolineVertices:GPU.Vertex.Array<Mesh.ColorVertex, UInt32>
    private 
    var sphere:Algorithm.FibonacciSphere<Double>
    //var fluid:Algorithm.Fluid<Double>
    
    private 
    var _active:Int = 0, 
        _activeTriangle:Int = 0 
    
    // async depot 
    private 
    var depot:
    (
        cubemap:(progress:Double?, value:Array2D<Vector4<UInt8>>?), 
        _:Void? 
    )
    = 
    (
        (nil, nil),
        nil 
    )
    
    // private 
    // var _phase:Int = 0
    
    init() 
    {
        // ui elements 
        self.buttons.labels.renormalize = .init([.init("Renormalize")])
        self.buttons.labels.background  = .init([.init("Background")])
        self.buttons.labels.bake        = .init([.init("Bake")])
        
        self.buttons.renormalize    = .init([self.buttons.labels.renormalize])
        self.buttons.background     = .init([self.buttons.labels.background])
        self.buttons.bake           = .init([self.buttons.labels.bake])
        
        do 
        {
            let toolbar:UI.Element.Div   = .init([self.buttons.0, self.buttons.1, self.buttons.2], identifier: "toolbar")
            let container:UI.Element.Div = .init([toolbar], identifier: "container")
            self.ui = UI.Element.Div.init([container])
        }
        
        let plane:Editor.Plane3D = .init(.init(
            center:         .zero, 
            orientation:    .identity, 
            distance:       6))
        
        self.cameraBuffer       = .init(hint: .dynamic, debugName: "ubo/camera")
        self.plane              = plane
        // cube 
        self.cube.vao = Mesh.Preset.cube()
        /* let checkerboard:Array2D<Vector4<UInt8>> = .init(size: .init(16, 16)) 
        {
            return .init(repeating: (($0.x &+ $0.y) & 1) == 1 ? 80 : 40)
        } */
        self.cube.texture = .init(layout: .rgba8, magnification: .linear, minification: .linear)
        
        
        let vertices:GPU.Buffer.Array<Mesh.ColorVertex>  = .init(hint: .static)
        let triangulation:GPU.Buffer.IndexArray<UInt32>  = .init(hint: .static)
        
        //let fluid:Algorithm.Fluid<Double> = .init(count: 1 << 8)
        let sphere:Algorithm.FibonacciSphere<Double> = .init(count: 1 << 8)
        // delaunay 
        let triangles:[UInt32] = sphere.triangulation.flatMap 
        {
            [.init($0.0), .init($0.1), .init($0.2)]
        }
        
        // compute elevations 
        
        // let (pixels, n):([UInt8], (x:Int, y:Int)) = try! PNG.v(path: "/home/klossy/downloads/earth.png", of: UInt8.self)
        // var samples:[[UInt8]] = .init(repeating: [], count: sphere.points.count)
        // for y:Int in 0 ..< n.y 
        // {
        //     for x:Int in 0 ..< n.x 
        //     {
        //         let theta:Double =     .pi * (.init(y) + 0.5) / .init(n.y), 
        //             phi:Double   = 2 * .pi * (.init(x) + 0.5) / .init(n.x)
        //         let index:Int    = sphere.nearest(to: .init(spherical: .init(theta, phi)))
        //         samples[index].append(pixels[y * n.x + x])
        //     }
        // }
        
        let points:[Mesh.ColorVertex] = sphere.points.map // zip(samples, sphere.points).map 
        {
            // let (cell, position):([UInt8], Vector3<Double>) = $0
            // let height:UInt8 = .init(cell.map(Double.init(_:)).reduce(0, +) / .init(cell.count))
            /* let offset:Double = 0.75 * 255
            let r:UInt8 = .init(clamping: Int.init(offset + noise.r.evaluate($0.x, $0.y, $0.z))), 
                g:UInt8 = .init(clamping: Int.init(offset + noise.g.evaluate($0.x, $0.y, $0.z))), 
                b:UInt8 = .init(clamping: Int.init(offset + noise.b.evaluate($0.x, $0.y, $0.z)))
             */
            return .init(.cast($0), color: .init(0, 0, 0, .max))
        }
        vertices.assign(points)
        triangulation.assign(triangles) 
        //self.fluid = fluid
        self.sphere = sphere
        self.points = .init(vertices: vertices, indices: triangulation)
        
        self.isolines           = .init(filename: "map.json")
        self.isolineVertices    = .init(vertices: .init(hint: .dynamic), indices: .init(hint: .dynamic))
        
        do 
        {
            let (vertices, indices):([Mesh.ColorVertex], [UInt32]) = self.isolines.render()
            self.isolineVertices.buffers.vertex.assign(vertices)
            self.isolineVertices.buffers.index.assign (indices)
        }
    }
    
    private 
    func collision(_ s:Vector2<Float>) -> UI.Group? 
    {
        for layer:UI.Group in self.layers 
        {
            if let result:UI.Group = layer.contains(s) 
            {
                return result
            }
        }
        return nil 
    }
    
    func event(_ event:UI.Event) -> UI.State 
    {
        // clear buttons 
        self.allButtons.forEach 
        {
            $0.click = 0
        }
        
        if let focus:UI.Group = self.focus 
        {
            switch event 
            {
            case    .primary(.down, _, doubled: _), 
                    .secondary(.down, _, doubled: _):
                self.focus = nil  
            case    .primary(.up, let s, doubled: _), 
                    .secondary(.up, let s, doubled: _):
                if self.focus === self.collision(s)
                {
                    focus.action(.complete(s))
                }
                self.focus = nil
            
            case    .cursor(let s):
                focus.action(.drag(s))
            
            case    .scroll, .key, .character:
                break 
            }
        }
        else 
        {
            switch event 
            {
            case    .primary(.down, let s, doubled: _):
                self.focus  = self.hover
                self.active = self.hover // self.collision(s)
                self.active?.action(.primary(s))
                
            case    .secondary(.down, let s, doubled: _):
                self.focus  = self.hover
                self.active = self.hover // self.collision(s)
                self.active?.action(.secondary(s))
                
            case    .primary(.up, _, doubled: _), 
                    .secondary(.up, _, doubled: _):
                break
            
            case    .cursor(let s):
                self.hover = self.collision(s)
                self.hover?.action(.hover(s))
                
            case    .scroll(let direction, _):
                self.hover?.action(.scroll(direction))
                
            case    .key(let key, let modifiers):
                if self.active !== self.hover 
                {
                    self.hover?.action(.key(key, modifiers))
                }
                self.active?.action(.key(key, modifiers))
                
            case    .character(let character):
                self.active?.action(.character(character))
            }
        }
        
        background:
        if self.buttons.background.click > 0 
        {
            guard self.depot.cubemap.progress == nil 
            else 
            {
                self.buttons.background.click = 0
                break background
            }
            
            self.depot.cubemap.progress = 0
            Terrain.background(cylindrical: "assets/textures/blue-marble-cylindrical.png", self, 
                progress:   \.depot.cubemap.progress, 
                return:     \.depot.cubemap.value)
        }
        bake:
        if self.buttons.bake.click > 0 
        {
            guard self.depot.cubemap.progress == nil 
            else 
            {
                self.buttons.bake.click = 0
                break bake
            }
            
            self.depot.cubemap.progress = 0
            Terrain.generate(isolines: self.isolines.model, self, 
                progress:   \.depot.cubemap.progress, 
                return:     \.depot.cubemap.value)
        }
        
        let cursor:UI.Cursor = self.focus?.cursor.active ?? self.hover?.cursor.inactive ?? .arrow
        return .init(cursor: cursor)
    }
    /* mutating 
    func event(_ event:UI.Event) -> UI.Event.Response
    {
        for button:UI.Element.Button in self.buttons 
        {
        //    button.click =
        }
        switch event 
        {
        case .cursor(let s):
            if let preselection:UI.Entity = self.ui.find(s)
            {
                self.preselection = .element(preselection)
            }
            else 
            {
                self.preselection = .plane(s)
            }
        case .action(let a):
            switch self.preselection 
            {
            case .element(let element):
                break
            }
        }
        var event:(l:UI.Event, r:UI.Event) = (event, event.reflect(self.viewport.size.y)) 
        
        for pass:Int in 0 ... 2
        {
            if self.ui.event(event.l, pass: pass) 
            {
                event = (.leave, .leave) 
            }
            
            switch event.r 
            {
                case    .primary    (_, let s, doubled: _), 
                        .secondary  (_, let s, doubled: _), 
                        .cursor     (   let s):
                    let point:Vector3<Float> = self.plane.project(s, on: .zero, radius: 1)
                    
                    let dpoint:Vector3<Double> = .cast(point)
                    self._active         = self.sphere.nearest(to: dpoint)
                    self._activeTriangle = self.sphere.triangle(containing: dpoint)
                    
                default: 
                    break 
            }
            
            if self.plane.event(event.r, pass: pass) 
            {
                event = (.leave, .leave) 
            }
        }
        
        for (i, button):(Int, UI.Element.Button) in self.buttons.enumerated() 
        {
            if button.click > 0 
            {
                print("click \(i)")
            }
        }
        //return .init(cursor: report.handcursor ? .hand : .crosshair)
        return .init(cursor: .hand)
    } */
    
    func process(_ delta:Int, styles:UI.Styles, viewport:Vector2<Int>, frame:Rectangle<Int>)
    {
        // check async depot 
        if let percent:Double = self.depot.cubemap.progress 
        {
            let text:String = "generating texture (\((percent * 100).rounded()) percent)"
            self.buttons.labels.bake.spans[0].text = text
        }
        if let new:Array2D<Vector4<UInt8>> = self.depot.cubemap.value
        {
            self.cube.texture.assign(cubemap: new)
            self.depot.cubemap.value    = nil 
            self.depot.cubemap.progress = nil 
            
            self.buttons.labels.bake.spans[0].text = "Bake"
        }
        
        for layer:UI.Group in self.layers 
        {
            layer.update(delta, styles: styles, viewport: viewport, frame: frame)
        }
        
        let matrices:Camera<Float>.Matrices = self.plane.matrices
        self.cameraBuffer.assign(std140: 
            .matrix4(matrices.U), 
            .matrix4(matrices.V), 
            .matrix3(matrices.F), 
            .float32x4(.extend(matrices.position, 0)))
        
        self.isolines.update(projection: matrices.U, camera: matrices.position, center: .zero)
        // self.ui.process(delta) 
        // self.plane.process(delta)
        
        /* self._phase -= delta
        if self._phase < 0 
        {
            self._phase = 64
            self.fluid.advect()
            
            let points:[Mesh.ColorVertex] = zip(self.fluid.sphere.points.indices, self.fluid.sphere.points).map  
            {
                /* let offset:Double = 0.75 * 255
                let r:UInt8 = .init(clamping: Int.init(offset + noise.r.evaluate($0.x, $0.y, $0.z))), 
                    g:UInt8 = .init(clamping: Int.init(offset + noise.g.evaluate($0.x, $0.y, $0.z))), 
                    b:UInt8 = .init(clamping: Int.init(offset + noise.b.evaluate($0.x, $0.y, $0.z)))
                */
                let v:UInt8 = .init(clamping: Int.init(self.fluid[current: $0.0].mass * 24))
                return .init(.cast($0.1), color: .init(v, v, v, .max))
            }
            self.points.buffers.vertex.assign(points)
            self._mutated = true
        } */
        
    }
    
    func vector() -> (text:[UI.DrawElement.Text], geometry:[UI.DrawElement.Geometry]) 
    {
        var text:[UI.DrawElement.Text]         = []
        var geometry:[UI.DrawElement.Geometry] = []
        self.isolines.contribute(text: &text, geometry: &geometry)
        self.ui.contribute(text: &text, geometry: &geometry, s: .zero) 
        
        return (text, geometry)
    }
    
    func draw(_ context:Coordinator.Context) -> [Renderer.Command] 
    {
        [
            .draw(elements: 0..., of: self.cube.vao, as: .triangles, 
                depthTest: .off,
                using: context.shaders.implicitSphere,
                [
                    // "Display"   : .block(context.display),
                    "Camera"    : .block(self.cameraBuffer),
                    "origin"    : .float32x3(.init(repeating: 0.0)),
                    "scale"     : .float32(1.0),
            
                    "globetex"  : .textureCube(self.cube.texture),
                ]), 
            // .draw(elements: 0..., of: self.points, as: .triangles, 
            //     depthTest: .off, 
            //     using: context.shaders.colorTriangles,
            //     [
            //         "Camera"    : .block(self.cameraBuffer),
            //     ]), 
            // .draw(0..., of: self.points, as: .points, 
            //     depthTest: .off, 
            //     using: context.shaders.colorPoints,
            //     [
            //         "Display"   : .block(context.display),
            //         "Camera"    : .block(self.cameraBuffer),
            //         "radius"    : .float32(4),
            //     ]),
            .draw(self._active ... self._active, of: self.points, as: .points, 
                depthTest: .off, 
                using: context.shaders.colorPoints,
                [
                    "Display"   : .block(context.display),
                    "Camera"    : .block(self.cameraBuffer),
                    "radius"    : .float32(8),
                ]), 
            .draw(elements: 0..., of: self.isolineVertices, as: .linesAdjacency, 
                depthTest: .off, 
                multisample: true, 
                using: context.shaders.colorLines,
                [
                    "Display"   : .block(context.display),
                    "Camera"    : .block(self.cameraBuffer),
                    "thickness" : .float32(1),
                ]) 
        ]
    }
} 

struct Coordinator 
{
    typealias Context =  
    (
        display:GPU.Buffer.Uniform<UInt8>,
        shaders:Shader.Programs
    )
    
    private 
    let renderer:Renderer 
    
    private 
    let context:Context
    
    let styles:UI.Styles
    
    private 
    let text:GPU.Vertex.Array<UI.DrawElement.Text.Vertex, UInt8>, 
        geometry:GPU.Vertex.Array<UI.DrawElement.Geometry.Vertex, UInt32>
    
    private 
    let controller:Controller 
    
    // window framebuffer size is distinct from viewport size, 
    // as multiple viewports can be tiled in the same window 
    var window:Vector2<Int> = .zero 
    {
        didSet 
        {
            let viewport:Rectangle<Int> = .init(.zero, self.window)
            
            self.context.display.assign(std140: .float32x2(.cast(self.window)))
            self.renderer.viewport      = viewport
        }
    }
    
    init()
    {
        self.renderer           = .init() 
        
        // display UBO 
        self.context.display    = .init(hint: .dynamic, debugName: "ubo/display")
        // compile shaders 
        self.context.shaders    = Shader.programs()
        
        // parse styles
        let stylesheet:[(selector:UI.Style.Selector, rules:UI.Style.Rules)]
        do 
        {
            stylesheet = try UI.Style.Sheet.parse(path: "mapeditor")
        }
        catch 
        {
            Log.trace(error: error)
            stylesheet = []
        }
        
        // print(stylesheet.map{ "\($0.0)\n\($0.1)" }.joined(separator: "\n\n"))
        self.styles = .init(stylesheet: stylesheet) 
        
        // UI layers 
        self.text     = .init(
            vertices:   .init(hint: .streaming, debugName: "ui/text/buffers/vertex"), 
            indices:    .init(hint: .static))
        self.geometry = .init(
            vertices:   .init(hint: .streaming, debugName: "ui/geometry/buffers/vertex"), 
            indices:    .init(hint: .static,    debugName: "ui/geometry/buffers/index"))
        
        self.controller = .init()
    }
    
    func event(_ event:UI.Event) -> UI.State
    {
        return self.controller.event(event)
    }
    
    mutating 
    func process(_ delta:Int)  
    {
        self.controller.process(delta, styles: self.styles, viewport: self.window, frame: .init(.zero, self.window)) 
        
        let (text, geometry):([UI.DrawElement.Text], [UI.DrawElement.Geometry]) = self.controller.vector()
        var buffer:
        (
            text:[UI.DrawElement.Text.Vertex], 
            geometry:
            (
                vertices:[UI.DrawElement.Geometry.Vertex], 
                indices:[UInt32]
            )
        ) 
        
        buffer.geometry.indices  = []
        buffer.geometry.indices.reserveCapacity(3 * geometry.map{ $0.triangles.count }.reduce(0, +))
        var z:Float = -1
        buffer.geometry.vertices = []
        buffer.geometry.vertices.reserveCapacity(geometry.map{ $0.count }.reduce(0, +))
        for element:UI.DrawElement.Geometry in geometry 
        {
            let base:Int = buffer.geometry.vertices.count
            for triangle:(Int, Int, Int) in element.triangles 
            {
                buffer.geometry.indices.append(.init(triangle.0 + base))
                buffer.geometry.indices.append(.init(triangle.1 + base))
                buffer.geometry.indices.append(.init(triangle.2 + base))
            }
            
            z = z.nextUp
            buffer.geometry.vertices.append(contentsOf: element)
        }
                
        buffer.text = []
        buffer.text.reserveCapacity(text.map{ $0.count }.reduce(0, +))
        for element:UI.DrawElement.Text in text
        {
            z = z.nextUp
            buffer.text.append(contentsOf: element)
        }
        
        self.text.buffers.vertex.assign(buffer.text)
        self.geometry.buffers.vertex.assign(buffer.geometry.vertices)
        self.geometry.buffers.index.assign(buffer.geometry.indices)
        
        self.renderer.execute(
            [
                .clear(color: true, depth: true), 
            ] as [Renderer.Command]
            +
            self.controller.draw(self.context) 
            +
            [
                .clear(color: false, depth: true), 
                .draw(elements: 0..., of: self.geometry, as: .triangles, 
                    using: self.context.shaders.xo,
                    [
                        "Display"   : .block(self.context.display)
                    ]), 
                .draw(0..., of: self.text, as: .lines,
                    using: self.context.shaders.text,  
                    [
                        "Display"   : .block(self.context.display), 
                        "fontatlas" : .texture2(self.styles.fonts.atlas.texture)
                    ])
            ] as [Renderer.Command])
    }
}
