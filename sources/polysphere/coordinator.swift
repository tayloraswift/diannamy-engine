@propertyWrapper 
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
}



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

struct Controller//:LayerController
{
    @State.Binding private 
    var style:UI.Style.Styles
    
    let ui:UI.Element.Block 
    
    private 
    let cameraBuffer:GPU.Buffer.Uniform<UInt8>
    @State.Binding private
    var cameraMatrices:Camera<Float>.Matrices 
    
    private 
    var plane:Display.Plane3D
    private 
    let cube: 
    (
        vao:GPU.Vertex.Array<Mesh.Preset.Vertex, UInt8>, 
        texture:GPU.Texture.D2<Vector4<UInt8>>
    )
    private 
    let points:GPU.Vertex.Array<Mesh.Preset.ColorVertex, UInt8>
    
    var viewport:Rectangle<Int> = .zero 
    {
        didSet 
        {
            self.plane.viewport     =               .cast(self.viewport.size)
            self.plane.frame        = .init(.zero,  .cast(self.viewport.size))
            
            self.ui.recomputeLayout = .physical
        }
    }
    
    init(style:State<UI.Style.Styles>.Binding) 
    {
        self._style = style
        
        // ui elements 
        let container:UI.Element.Div = 
        {
            let top:UI.Element.Div = 
            {
                let header:UI.Element.Div = 
                {
                    let date:UI.Element.P = .init(
                        [
                            .init("Tuesday, August 6, 2019")
                        ],
                        identifier: "time", classes: ["status"])
                    let logo:UI.Element.P = .init(
                        [
                            .init("The New York Times")
                        ],
                        identifier: "logo")
                    let label:UI.Element.P = .init(
                        [
                            .init("Today’s Paper")
                        ],
                        classes: ["status"])
                    
                    return .init([date, logo, label], identifier: "banner")
                }()
                let masthead:UI.Element.Div = 
                {
                    let labels:[String] = 
                    [
                        "World",
                        "U.S.",
                        "Politics",
                        "N.Y.",
                        "Business",
                        "Opinion",
                        "Tech",
                        "Science",
                        "Health",
                        "Sports",
                        "Arts",
                        "Books",
                        "Style",
                        "Food",
                        "Travel",
                        "Magazine",
                        "T Magazine",
                        "Real Estate",
                        "Video",
                    ]
                    let items:[UI.Element.P] = labels.map{ .init([.init($0)]) }
                    return .init(items, identifier: "masthead")
                }()
                
                return .init([header, masthead], identifier: "top")
            }()
            
            let body:UI.Element.Div 
            do 
            {
                let main:UI.Element.Div 
                do
                {
                    let story1:UI.Element.Div 
                    do 
                    {
                        let left:UI.Element.Div 
                        do 
                        {
                            let subtitle:UI.Element.P = .init(
                                [
                                    .init("GUN VIOLENCE")
                                ], 
                                classes: ["topic"])
                            let title:UI.Element.P = .init(
                                [
                                    .init("After Two Mass Shootings, Will Republicans Take a New Stance on Guns?")
                                ], 
                                classes: ["headline", "headline-major"])
                            let p1:UI.Element.P = .init(
                                [
                                    .init("President Trump explored whether to expand background checks for guns, and Senator Mitch McConnell signaled he would be open to considering the idea.")
                                ])
                            let p2:UI.Element.P = .init(
                                [
                                    .init("Both have opposed such legislation in the past. Their willingness to weigh it now suggests Republicans feel pressured to act after two mass shootings.")
                                ])
                            let statusbar:UI.Element.P = .init(
                                [
                                    .init("Live", classes: ["accent", "strong"]), 
                                    .init("9m ago", classes: ["accent", "strong"]), 
                                    .init("595 comments"), 
                                ], 
                                classes: ["statusbar"])
                            
                            left = .init([subtitle, title, p1, p2, statusbar], style: .init([.grow: 1 as Float]))
                        }
                        
                        let right:UI.Element.Div 
                        do 
                        {
                            let top:UI.Element.Div, 
                                bottom:UI.Element.Div 
                            
                            do 
                            {
                                let illustration:UI.Element.Div
                                do 
                                {
                                    let picture:UI.Element.Div = .init([], classes: ["image-placeholder"])
                                    let caption:UI.Element.P = .init(
                                        [
                                            .init("A vigil for victims of the mass shootings in El Paso and Dayton was held outside the National Rifle Association’s headquarters in Fairfax, Va., on Monday.")
                                        ], 
                                        classes: ["caption"])
                                    let creditline:UI.Element.P = .init(
                                        [
                                            .init("Anna Moneymaker/The New York Times")
                                        ], 
                                        classes: ["credit-line"])
                                    
                                    illustration = .init([picture, caption, creditline], classes: ["illustration"], style: .init([.grow: 2 as Float]))
                                }
                                let right:UI.Element.Div
                                do 
                                {
                                    let title:UI.Element.P = .init(
                                        [
                                            .init("Will Shootings Sway Voters? Look First to Virginia Races")
                                        ], 
                                        classes: ["headline"])
                                    let p1:UI.Element.P = .init(
                                        [
                                            .init("The state’s elections in November will test the potency of gun rights as a voting issue.")
                                        ])
                                    let statusbar:UI.Element.P = .init(
                                        [
                                            .init("5m ago"), 
                                            .init("87 comments"), 
                                        ], 
                                        classes: ["statusbar"])
                                    right = .init([title, p1, statusbar])
                                }
                                
                                top = .init([illustration, right], style: .init([.axis: UI.Style.Axis.horizontal]))
                            }
                            do 
                            {
                                let title:UI.Element.P = .init(
                                    [
                                        .init("In the weeks before the El Paso shooting, the suspect’s mother called the police about a gun he had ordered.")
                                    ], 
                                    classes: ["headline"])
                                let statusbar:UI.Element.P = .init(
                                    [
                                        .init("5h ago")
                                    ], 
                                    classes: ["statusbar"])
                                bottom = .init([title, statusbar])
                            }
                            
                            
                            right = .init([top, bottom], style: .init([.grow: 2 as Float]))
                        }
                        
                        story1 = .init([left, right], classes: ["story"], style: .init([.axis: UI.Style.Axis.horizontal]))
                    }
                    
                    
                    main = .init([story1], identifier: "main-panel")
                }
                
                let side:UI.Element.Div 
                do
                {
                    let section:UI.Element.P = .init(
                        [
                            .init("Opinion >")
                        ], 
                        identifier: "opinion-header")
                    let author:UI.Element.P = .init(
                        [
                            .init("Sahil Chinoy")
                        ], 
                        classes: ["author"])
                    let title:UI.Element.P = .init(
                        [
                            .init("Quiz: Let Us Predict Whether You’re a Democrat or a Republican")
                        ], 
                        classes: ["headline"])
                    let summary:UI.Element.P = .init(
                        [
                            .init("Just a handful of questions are very likely to reveal how you vote.")
                        ])
                    let statusbar:UI.Element.P = .init(
                        [
                            .init("1h ago"), 
                            .init("1107 comments"), 
                        ], 
                        classes: ["statusbar"])
                    
                    side = .init([section, author, title, summary, statusbar], identifier: "side-panel")
                }
                
                body = .init([main, side], identifier: "page-body")
            }
            
            
            return .init([top, body], identifier: "container")
        }()
        
        self.ui         = UI.Element.Div.init([container])
        self.ui.path    = UI.Style.Path.init().appended(self.ui)
        
        let plane:Display.Plane3D = .init(.init(
            center:         .zero, 
            orientation:    .identity, 
            distance:       6))
        
        self.cameraBuffer       = .init(hint: .dynamic, debugName: "ubo/camera")
        self._cameraMatrices    = plane.$matrices.binding 
        self.plane              = plane
        // cube 
        self.cube.vao = Mesh.Preset.cube()
        let checkerboard:Array2D<Vector4<UInt8>> = .init(size: .init(16, 16)) 
        {
            return .init(repeating: (($0.x &+ $0.y) & 1) == 1 ? 255 : 40)
        }
        self.cube.texture = .init(layout: .rgba8, magnification: .nearest, minification: .nearest)
        self.cube.texture.assign(checkerboard)
        
        let vertices:GPU.Buffer.Array<Mesh.Preset.ColorVertex> = .init(hint: .static)
        let points:[Mesh.Preset.ColorVertex] = Algorithm.fibonacci(1 << 16, as: Double.self).map 
        {
            .init(.cast($0), color: .extend(.cast(($0 * 0.5 + 0.5) * 255), .max))
        }
        vertices.assign(points)
        self.points = .init(vertices: vertices, indices: .init(hint: .static))
    }
    
    mutating 
    func event(_ event:UI.Event) -> UI.Event.Response
    {
        var response:UI.Event.Response  = .init()
        var event:UI.Event              = event 
        for pass:Int in 0 ... 2
        {
            if  // self.ui.event(event, pass: pass, response: &response) || 
                self.plane.event(event, pass: pass, response: &response) 
            {
                event = .leave
            }
        }
        
        return response
    }
    
    mutating 
    func process(_ delta:Int) -> Bool 
    {
        self.ui.process(delta) 
        self.plane.process(delta)
        
        if self.$cameraMatrices.mutated 
        {
            let matrices:Camera<Float>.Matrices = self.cameraMatrices
            self.cameraBuffer.assign(std140: 
                .matrix4(matrices.U), 
                .matrix4(matrices.V), 
                .matrix3(matrices.F), 
                .float32x4(.extend(matrices.position, 0)))
            self.$cameraMatrices.update()
            return true 
        }
        else 
        {
            return false
        }
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
                    
                    "globetex"  : .texture2(self.cube.texture),
                ]), 
            .draw(0..., of: self.points, as: .points, 
                depthTest: .off, 
                using: context.shaders.solidPoints,
                [
                    "Display"   : .block(context.display),
                    "Camera"    : .block(self.cameraBuffer),
                    "radius"    : .float32(4),
                ])
        ]
    }
} 

struct Coordinator 
{
    typealias Context =  
    (
        display:GPU.Buffer.Uniform<UInt8>,
        shaders: 
        (
            text:           GPU.Program,
            xo:             GPU.Program,
            
            implicitSphere: GPU.Program, 
            
            solidPoints:    GPU.Program
        )
    )
    
    private 
    let renderer:Renderer 
    
    private 
    let context:Context
    @State 
    var style:UI.Style.Styles
    
    private 
    let text:GPU.Vertex.Array<UI.DrawElement.Text.Vertex, UInt8>, 
        geometry:GPU.Vertex.Array<UI.DrawElement.Geometry.Vertex, UInt32>
    
    private 
    var controller:Controller 
    
    // window framebuffer size is distinct from viewport size, 
    // as multiple viewports can be tiled in the same window 
    var window:Vector2<Int> = .zero 
    {
        didSet 
        {
            let viewport:Rectangle<Int> = .init(.zero, self.window)
            
            self.context.display.assign(std140: .float32x2(.cast(self.window)))
            self.renderer.viewport      = viewport
            self.controller.viewport    = viewport 
        }
    }
    
    init()
    {
        self.renderer           = .init() 
        
        // display UBO 
        self.context.display    = .init(hint: .dynamic, debugName: "ubo/display")
        // compile shaders 
        do 
        {
            self.context.shaders.text = try .init(
                [
                    (.vertex,   "shaders/text.vert"),
                    (.geometry, "shaders/text.geom"),
                    (.fragment, "shaders/text.frag"),
                ], 
                debugName: "diannamy://engine/shaders/text*")
            self.context.shaders.xo = try .init(
                [
                    (.vertex,   "shaders/colorD2.vert"),
                    (.fragment, "shaders/colorD2.frag"),
                ], 
                debugName: "diannamy://engine/shaders/colorD2*")
            self.context.shaders.implicitSphere = try .init(
                [
                    (.vertex,   "shaders/sphere.vert"),
                    (.fragment, "shaders/sphere.frag"),
                ], 
                debugName: "diannamy://engine/shaders/sphere*")
            self.context.shaders.solidPoints = try .init(
                [
                    (.vertex,   "shaders/Mesh.Preset.ColorVertex.vert"),
                    (.geometry, "shaders/solid-points.geom"),
                    (.fragment, "shaders/solid-points.frag"),
                ], 
                debugName: "diannamy://engine/shaders/solid-points*")
        }
        catch 
        {
            Log.trace(error: error)
            Log.fatal("failed to compile one or more shader programs")
        }
        
        // parse styles
        let stylesheet:[(selector:UI.Style.Selector, rules:UI.Style.Rules)]
        do 
        {
            stylesheet = try UI.Style.Sheet.parse(path: "default")
        }
        catch 
        {
            Log.trace(error: error)
            stylesheet = []
        }
        
        // print(stylesheet.map{ "\($0.0)\n\($0.1)" }.joined(separator: "\n\n"))
        let style:State<UI.Style.Styles> = .init(wrappedValue: .init(stylesheet: stylesheet))
        self._style = style 
        
        // UI layers 
        self.text     = .init(
            vertices:   .init(hint: .streaming, debugName: "ui/text/buffers/vertex"), 
            indices:    .init(hint: .static))
        self.geometry = .init(
            vertices:   .init(hint: .streaming, debugName: "ui/geometry/buffers/vertex"), 
            indices:    .init(hint: .static,    debugName: "ui/geometry/buffers/index"))
        
        self.controller = .init(style: style.binding)
    }
    
    mutating 
    func event(_ event:UI.Event) -> UI.Event.Response
    {
        return self.controller.event(event)
    }
    
    mutating 
    func process(delta:Int) -> Bool 
    {
        var controllerChanged:Bool = self.controller.process(delta) 
        
        if let (text, geometry):([UI.DrawElement.Text], [UI.DrawElement.Geometry]) = 
            self.controller.ui.frame(rectangle: .init(.zero, self.window), definitions: &self.style)
        {
            controllerChanged = true 
            
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
        }
        
        self.renderer.execute(
            [
                .clear(color: true, depth: true), 
            ]
            +
            self.controller.draw(self.context) 
            /* +
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
                        "fontatlas" : .texture2(self.style.fonts.atlas.texture)
                    ])
            ]*/)
        return controllerChanged
    }
}
