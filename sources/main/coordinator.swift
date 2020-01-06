import enum File.File

// different view rects:
//
//                    window 
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
    
    // GPU resources
    private 
    let ubo:
    (
        camera:GPU.Buffer.Uniform<UInt8>,
        atmosphere:GPU.Buffer.Uniform<UInt8>
    )
    private 
    let vao: 
    (
        hull:GPU.Vertex.Array<Mesh.Vertex, UInt8>, 
        points:GPU.Vertex.Array<Mesh.ColorVertex, UInt32>,
        isolines:GPU.Vertex.Array<Mesh.ColorVertex, UInt32>
    )
    private 
    let texture:
    (
        globeAlbedo:GPU.Texture.Cube<Vector4<UInt8>>, 
        globeTransmittance:GPU.Texture.D2<Vector4<Float>>,
        globeScattering:GPU.Texture.D3<Vector4<Float>>,
        globeIrradiance:GPU.Texture.D2<Vector4<Float>>
    )
    
    
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
        let plane:Editor.Plane3D = .init(.init(
            center:         .zero, 
            orientation:    .identity, 
            distance:       6))
        
        self.ubo.camera                 = .init(hint: .dynamic, debugName: "ubo/camera")
        self.ubo.atmosphere             = .init(hint: .static,  debugName: "ubo/atmosphere")
        self.plane                      = plane
        
        // ui elements 
        self.buttons.labels.renormalize = .init([.init("Renormalize")])
        self.buttons.labels.background  = .init([.init("Background")])
        self.buttons.labels.bake        = .init([.init("Bake")])
        
        self.buttons.renormalize        = .init([self.buttons.labels.renormalize])
        self.buttons.background         = .init([self.buttons.labels.background])
        self.buttons.bake               = .init([self.buttons.labels.bake])
        
        let toolbar:UI.Element.Div      = .init([self.buttons.0, self.buttons.1, self.buttons.2], identifier: "toolbar")
        let container:UI.Element.Div    = .init([toolbar], identifier: "container")
        self.ui = UI.Element.Div.init([container])
        
        // geometry 
        // generate sphere with 256 fibonacci points, and its delaunay triangulation
        self.sphere = .init(count: 1 << 8)
        let points:(vertices:[Mesh.ColorVertex], indices:[UInt32]) 
        points.vertices = self.sphere.points.map // zip(samples, sphere.points).map 
        {
            // let (cell, position):([UInt8], Vector3<Double>) = $0
            // let height:UInt8 = .init(cell.map(Double.init(_:)).reduce(0, +) / .init(cell.count))
            /* let offset:Double = 0.75 * 255
            let r:UInt8 = .init(clamping: Int.init(offset + noise.r.evaluate($0.x, $0.y, $0.z))), 
                g:UInt8 = .init(clamping: Int.init(offset + noise.g.evaluate($0.x, $0.y, $0.z))), 
                b:UInt8 = .init(clamping: Int.init(offset + noise.b.evaluate($0.x, $0.y, $0.z)))
             */
            .init(.cast($0), color: .init(0, 0, 0, .max))
        }
        points.indices = self.sphere.triangulation.flatMap 
        {
            [.init($0.0), .init($0.1), .init($0.2)]
        }
        
        // load and compute isolines 
        self.isolines = .init(filename: "map.json")
        
        // GPU resources 
        self.vao.hull       = Mesh.Preset.icosahedron(inscribedRadius: 1 + 1/64)
        
        self.vao.points     = .init(vertices: .init(hint: .static),  indices: .init(hint: .static))
        self.vao.points.buffers.vertex.assign(points.vertices)
        self.vao.points.buffers.index.assign(points.indices)
        
        self.vao.isolines   = .init(vertices: .init(hint: .dynamic), indices: .init(hint: .dynamic))
        
        self.texture.globeAlbedo        = .init(layout: .rgba8,   magnification: .linear, minification: .linear, mipmap: .linear)
        self.texture.globeTransmittance = .init(layout: .rgba32f, magnification: .linear, minification: .linear, mipmap: nil)
        self.texture.globeScattering    = .init(layout: .rgba32f, magnification: .linear, minification: .linear, mipmap: nil)
        self.texture.globeIrradiance    = .init(layout: .rgba32f, magnification: .linear, minification: .linear, mipmap: nil)
        
        // load precomputed scattering textures and parameters 
        do 
        {
            switch try File.uncan(from: "assets/tables/atmospheric-scattering/earth-atmosphere-parameters-3x.float32")
            {
            case .float32(let data):
                guard data.count == 22 
                else 
                {
                    Log.error("failed to load atmospheric parameters, expected 22 `Float`s, found \(data.count)")
                    break 
                }
                
                let radius:(bottom:Float, top:Float, sun:Float) = (data[0], data[1], data[2])
                let μsmin:Float                                 =  data[3]
                
                let rayleigh:Vector3<Float>                     = .init(data[4], data[5], data[6])
                let mie:Vector3<Float>                          = .init(data[7], data[8], data[9])
                let g:Float                                     = data[10]
                
                let resolution:
                (
                    transmittance:Vector2<Float>, 
                    scattering:(Float, Float, Float, Float), 
                    irradiance:Vector2<Float>
                ) = 
                (
                    .init(data[11], data[12]),
                    (data[13], data[14], data[15], data[16]),
                    .init(data[17], data[18])
                )
                
                let irradiance:Vector3<Float>                   = .init(data[19], data[20], data[21])
                
                self.ubo.atmosphere.assign(std140:
                    .float32(radius.bottom),
                    .float32(radius.top),
                    .float32(radius.sun),
                    .float32(μsmin),
                    
                    .float32x4(.extend(rayleigh, 0)),
                    .float32x4(.extend(mie, g)),
                    
                    .float32x2(resolution.transmittance),
                    .float32(resolution.scattering.0), 
                    .float32(resolution.scattering.1), 
                    .float32(resolution.scattering.2), 
                    .float32(resolution.scattering.3), 
                    .float32x2(resolution.irradiance),
                    
                    .float32x4(.extend(irradiance, 0)))
            
            default:
                Log.error("failed to load atmospheric parameters")
            }
            
            switch try File.uncan(from: "assets/tables/atmospheric-scattering/earth-transmittance-3x.float32") 
            {
            case .float32x4D2(let data, x: let x, y: let y):
                let table:Array2D<Vector4<Float>> = .init(data.map(Vector4<Float>.init(_:)), size: .init(x, y))
                self.texture.globeTransmittance.assign(table)
            default:
                Log.error("failed to load atmospheric transmittance table")
            }
            switch try File.uncan(from: "assets/tables/atmospheric-scattering/earth-scattering-combined-3x.float32") 
            {
            case .float32x4D3(let data, x: let x, y: let y, z: let z):
                let table:Array3D<Vector4<Float>> = .init(data.map(Vector4<Float>.init(_:)), size: .init(x, y, z))
                self.texture.globeScattering.assign(table)
            default:
                Log.error("failed to load atmospheric scattering table")
            }
            switch try File.uncan(from: "assets/tables/atmospheric-scattering/earth-irradiance-3x.float32") 
            {
            case .float32x4D2(let data, x: let x, y: let y):
                let table:Array2D<Vector4<Float>> = .init(data.map(Vector4<Float>.init(_:)), size: .init(x, y))
                self.texture.globeIrradiance.assign(table)
            default:
                Log.error("failed to load atmospheric irradiance table")
            }
        }
        catch 
        {
            Log.trace(error: error)
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
            case    .primary(.down, let s, doubled: let doubled):
                self.focus  = self.hover
                self.active = self.hover // self.collision(s)
                self.active?.action(.primary(s, doubled: doubled))
                
            case    .secondary(.down, let s, doubled: let doubled):
                self.focus  = self.hover
                self.active = self.hover // self.collision(s)
                self.active?.action(.secondary(s, doubled: doubled))
                
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
            self.texture.globeAlbedo.assign(cubemap: new)
            self.depot.cubemap.value    = nil 
            self.depot.cubemap.progress = nil 
            
            self.buttons.labels.bake.spans[0].text = "Bake"
        }
        
        for layer:UI.Group in self.layers 
        {
            layer.update(delta, styles: styles, viewport: viewport, frame: frame)
        }
        
        let matrices:Camera<Float>.Matrices = self.plane.matrices
        self.isolines.update(matrices: matrices)
        self.ubo.camera.assign(std140: 
            .matrix4(matrices.U), 
            .matrix4(matrices.V), 
            .matrix3(matrices.F), 
            .float32x4(.extend(matrices.position, 0)))
        
        // check if any graphics need to be refreshed 
        if let (vertices, indices):([Mesh.ColorVertex], [UInt32]) = self.isolines.render()
        {
            self.vao.isolines.buffers.vertex.assign(vertices)
            self.vao.isolines.buffers.index.assign(indices)
        }
    }
    
    func canvas(context:Coordinator.Context) -> UI.Canvas 
    {
        let canvas:UI.Canvas = .init()
        let commands:[Renderer.Command] = 
        [
            .draw(elements: 0..., of: self.vao.hull, as: .triangles, 
                depthTest: .off,
                depthMask: false,
                using: context.shaders.implicitSphere,
                [
                    // "Display"   : .block(context.display),
                    "Camera"    : .block(self.ubo.camera),
                    "Atmosphere": .block(self.ubo.atmosphere),
                    
                    "origin"    : .float32x3(.init(repeating: 0.0)),
                    "scale"     : .float32(1.0),
            
                    "globetex"  : .textureCube(self.texture.globeAlbedo),
                    
                    "transmittance_table"   : .texture2(self.texture.globeTransmittance),
                    "scattering_table"      : .texture3(self.texture.globeScattering),
                    "irradiance_table"      : .texture2(self.texture.globeIrradiance),
                ]), 
            // .draw(elements: 0..., of: self.vao.points, as: .triangles, 
            //     depthTest: .off, 
            //     using: context.shaders.colorTriangles,
            //     [
            //         "Camera"    : .block(self.ubo.camera),
            //     ]), 
            // .draw(0..., of: self.vao.points, as: .points, 
            //     depthTest: .off, 
            //     using: context.shaders.colorPoints,
            //     [
            //         "Display"   : .block(context.display),
            //         "Camera"    : .block(self.ubo.camera),
            //         "radius"    : .float32(4),
            //     ]),
            .draw(self._active ... self._active, of: self.vao.points, as: .points, 
                depthTest: .off, 
                using: context.shaders.colorPoints,
                [
                    "Display"   : .block(context.display),
                    "Camera"    : .block(self.ubo.camera),
                    "radius"    : .float32(8),
                ]), 
            .draw(elements: 0..., of: self.vao.isolines, as: .linesAdjacency, 
                depthTest: .off, 
                multisample: true, 
                using: context.shaders.colorLines,
                [
                    "Display"   : .block(context.display),
                    "Camera"    : .block(self.ubo.camera),
                    "thickness" : .float32(1),
                ]) 
        ]
        canvas.push(layer: .overlay, commands: commands)
        self.isolines.draw(canvas)
        self.ui.draw(canvas, s: .zero) 
        return canvas
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
    let window:GPU.FrameBuffer 
    private 
    let framebuffers:
    (
        (texture:GPU.Texture.Multisample, framebuffer:GPU.FrameBuffer),
        (texture:GPU.Texture.D2<Void>,    framebuffer:GPU.FrameBuffer),
        (texture:GPU.Texture.D2<Void>,    framebuffer:GPU.FrameBuffer)
    )
    private 
    let vao:
    (
        text:GPU.Vertex.Array<UI.Canvas.Text.Vertex, UInt8>, 
        geometry:GPU.Vertex.Array<UI.Canvas.Geometry.Vertex, UInt32>
    )
    private 
    let quad:GPU.Vertex.Array<Mesh.Vertex, UInt8>
    
    private 
    let context:Context, 
        styles:UI.Styles
    
    private 
    let controller:Controller 
    
    // window framebuffer size is distinct from viewport size, 
    // as multiple viewports can be tiled in the same window 
    var size:Vector2<Int> = .zero 
    {
        didSet 
        {
            // the window framebuffer is an empty dummy object, but we update its 
            // size variable for consistency anyway
            self.window.resize(self.size)
            // the framebuffers will resize the textures for us, so we don’t need 
            // to resize the texture handles 
            self.framebuffers.0.framebuffer.resize(self.size)
            self.framebuffers.1.framebuffer.resize(self.size)
            self.framebuffers.2.framebuffer.resize(self.size)
            
            let viewport:Rectangle<Int> = .init(.zero, self.size)
            // set the viewport variables so that `glViewport(_:_:_:_:)` gets 
            // called with the right arguments in the rendering phase 
            self.window.viewport                     = viewport 
            self.framebuffers.0.framebuffer.viewport = viewport
            self.framebuffers.1.framebuffer.viewport = viewport
            self.framebuffers.2.framebuffer.viewport = viewport
            
            self.context.display.assign(std140: .float32x2(.cast(self.size)))
        }
    }
    
    private static 
    func colorImage() -> GPU.Texture.D2<Void> 
    {
        return .init(layout: .rgba8, magnification: .nearest, minification: .nearest, 
            wrap: (.clamp, .clamp)) 
    }
    private static 
    func colorImageMultisample(_ samples:Int) -> GPU.Texture.Multisample  
    {
        return .init(layout: .rgba8, samples: samples) 
    }
    private static 
    func framebuffer(_ color:GPU.FrameBuffer.Image) -> GPU.FrameBuffer
    {
        let samples:Int 
        switch color 
        {
        case .texture2(_):
            samples = 0
        case .texture2MS(let texture):
            samples = texture.parameters.samples 
        case .renderbuffer(let renderbuffer):
            samples = renderbuffer.samples
        }
        let depth:GPU.RenderBuffer      = .init(layout: .depth32f, samples: samples)
        let images:[(GPU.FrameBuffer.Attachment, GPU.FrameBuffer.Image)] = 
        [
            (.color, color),
            (.depth, .renderbuffer(depth))
        ]
        return .init(images)
    }
    
    init(multisampling samples:Int)
    {
        self.window         = .default
        
        self.framebuffers.0.texture     = Self.colorImageMultisample(samples) 
        self.framebuffers.0.framebuffer = Self.framebuffer(.texture2MS(self.framebuffers.0.texture)) 
        self.framebuffers.1.texture     = Self.colorImage() 
        self.framebuffers.1.framebuffer = Self.framebuffer(.texture2(self.framebuffers.1.texture))
        self.framebuffers.2.texture     = Self.colorImage() 
        self.framebuffers.2.framebuffer = Self.framebuffer(.texture2(self.framebuffers.2.texture))
        
        self.vao.text       = .init(
            vertices:   .init(hint: .streaming, debugName: "ui/text/buffers/vertex"), 
            indices:    .init(hint: .static))
        self.vao.geometry   = .init(
            vertices:   .init(hint: .streaming, debugName: "ui/geometry/buffers/vertex"), 
            indices:    .init(hint: .static,    debugName: "ui/geometry/buffers/index"))
        
        self.quad           = Mesh.Preset.square()
        self.context        = 
        (
            // display UBO 
            .init(hint: .dynamic, debugName: "ubo/display"), 
            // compile shaders 
            Shader.programs()
        )
        
        // parse styles
        let stylesheet:[(selector:UI.Style.Selector, rules:UI.Style.Rules)]
        do 
        {
            stylesheet  = try UI.Style.Sheet.parse(path: "mapeditor")
        }
        catch 
        {
            Log.trace(error: error)
            stylesheet  = []
        }
        
        // print(stylesheet.map{ "\($0.0)\n\($0.1)" }.joined(separator: "\n\n"))
        self.styles     = .init(stylesheet: stylesheet) 
        self.controller = .init()
    }
    
    func event(_ event:UI.Event) -> UI.State
    {
        return self.controller.event(event)
    }
    
    mutating 
    func process(_ delta:Int)  
    {
        self.controller.process(delta, styles: self.styles, 
            viewport: self.size, frame: .init(.zero, self.size)) 
        
        let canvas:UI.Canvas = self.controller.canvas(context: self.context)
        canvas.flatten(assigning: self.vao, 
            programs:  (text: self.context.shaders.text, geometry: self.context.shaders.xo), 
            fontatlas:  self.styles.fonts.atlas.texture, 
            display:    self.context.display)
        
        let layers:[([Renderer.Command], GPU.Program)] = canvas.layers.map 
        {
            let (layer, commands):(UI.Canvas.Layer, [Renderer.Command]) = $0
            
            let integrator:GPU.Program 
            switch layer 
            {
            case .frost:
                fatalError()
            case .overlay:
                integrator = self.context.shaders.integrator.overlay
            case .highlight:
                integrator = self.context.shaders.integrator.highlight
            }
            
            return (commands, integrator)
        }
        
        self.composite(layers)
    }
    
    private 
    func composite(_ layers:[([Renderer.Command], GPU.Program)])
    {
        var (foreground, background, destination):
        (
            (texture:GPU.Texture.Multisample, framebuffer:GPU.FrameBuffer), 
            (texture:GPU.Texture.D2<Void>,    framebuffer:GPU.FrameBuffer),
            
            (texture:GPU.Texture.D2<Void>?,   framebuffer:GPU.FrameBuffer)
        )
        
        foreground = self.framebuffers.0
        background = self.framebuffers.1
        if layers.count > 1 
        {
            destination = (self.framebuffers.2.texture, self.framebuffers.2.framebuffer)
        }
        else 
        {
            destination = (nil, self.window)
        }
        
        // initialize background background color
        background.framebuffer.execute([])
        for (i, (commands, integrator)):(Int, ([Renderer.Command], GPU.Program)) in 
            layers.enumerated() 
        {
            foreground.framebuffer.execute(commands)
            
            let integration:[Renderer.Command] = 
            [
                .draw(0..., of: self.quad, as: .triangles, 
                    using: integrator,
                    [
                        "background": .texture2(background.texture),
                        "foreground": .texture2MS(foreground.texture), 
                        "samples":    .int32(.init(foreground.texture.parameters.samples)), 
                        "Display":    .block(self.context.display)
                    ])
            ]
            
            destination.framebuffer.execute(integration)
            
            if let combined:GPU.Texture.D2<Void> = destination.texture 
            {
                let next:GPU.FrameBuffer = destination.framebuffer
                if (i == layers.count - 2)
                {
                    // i == N - 2
                    destination = (nil,                self.window)
                    background  = (combined,           next)
                }
                else 
                {
                    // i == 0 ..< N - 2
                    destination = (background.texture, background.framebuffer)
                    background  = (combined,           next)
                }
                
            }
            else 
            {
                break 
            }
        }
    }
}
