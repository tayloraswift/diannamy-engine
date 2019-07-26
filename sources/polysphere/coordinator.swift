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



protocol LayerController 
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
}

struct Coordinator 
{
    @State 
    var style:UI.Style
    var controllers:[LayerController]
    
    private 
    let renderer:Renderer 
    private 
    var redraw:Bool = true 
    
    private 
    let shaders:
    (
        text:GPU.Program, 
        sphere:GPU.Program 
    )
    private 
    let display:GPU.Buffer.Uniform<UInt8>
    private 
    let text:GPU.Vertex.Array<UI.Text.DrawElement.Vertex, UInt8>
    private 
    var ui:UI.Text
    
    // window framebuffer size is distinct from viewport size, 
    // as multiple viewports can be tiled in the same window 
    var window:Vector2<Int> = .zero 
    {
        didSet 
        {
            self.renderer.viewport(.init(.zero, self.window))
            self.display.assign(std140: .float32x2(.cast(self.window)))
        }
    }
    
    init(renderer:Renderer)
    {
        self.renderer       = renderer 
        self.controllers    = []
        self._style         = .init(wrappedValue: .init())
        
        do 
        {
            // compile shaders 
            self.shaders.text   = try .init(
                [
                    (.vertex,   "shaders/text.vert"),
                    (.geometry, "shaders/text.geom"),
                    (.fragment, "shaders/text.frag"),
                ], 
                debugName: "diannamy://engine/shaders/text*")
            self.shaders.sphere = try .init(
                [
                    (.vertex,   "shaders/sphere.vert"),
                    (.fragment, "shaders/sphere.frag"),
                ], 
                debugName: "diannamy://engine/shaders/sphere*")
            
            // display UBO 
            self.display = .init(hint: .dynamic, debugName: "ubo/display")
            
            // ui elements 
            let text:UI.Text = .init(
                [
                    .init("hello world!\n", selector: "text.strong.emphasis"), 
                    .init("", selector: "text")
                ], 
                selector: "text", 
                style: .init(position2: .init(0, 50)))
            self.ui = text
            
            // geometry 
            let vertices:GPU.Buffer.Array<UI.Text.DrawElement.Vertex> = 
                .init(hint: .streaming, debugName: "text/buffers/vertex")
            let indices:GPU.Buffer.IndexArray<UInt8> = 
                .init(hint: .static)
            self.text = .init(vertices: vertices, indices: indices)
        }
        catch 
        {
            Log.trace(error: error)
            Log.fatal("failed to compile one or more shader programs")
        }
    }
    
    mutating 
    func event(_ event:UI.Event) 
    {
        self.ui.event(event, pass: .global)
    }
    
    mutating 
    func process(delta:Int) -> Bool 
    {
        guard self.ui.process(delta: delta, allotment: self.window) 
        else 
        {
            return false 
        }
        
        self.draw()
        return true 
    }
    
    private mutating 
    func draw() 
    {
        self.ui.layout(styledefs: &self.style)
        
        // collect text 
        let text:[UI.Text.DrawElement] = self.ui.contribute(textOffset: .zero)
        var buffer:[UI.Text.DrawElement.Vertex] = []
            buffer.reserveCapacity(2 * text.map{ $0.count }.reduce(0, +))
        for element:UI.Text.DrawElement in text
        {
            for (v1, v2):(UI.Text.DrawElement.Vertex, UI.Text.DrawElement.Vertex) in element 
            {
                buffer.append(v1)
                buffer.append(v2)
            }
        }
        
        self.text.buffers.vertex.assign(buffer)
        self.renderer.draw()
        
        self.shaders.text._push(constants: 
            [
                "Display"   : .block(self.display), 
                "fontatlas" : .texture2(self.style.atlas.texture)
            ])
        self.text.draw(0 ..< buffer.count)
    }
}

struct Controller:LayerController
{
    @State.Binding private 
    var style:UI.Style 
    
    init(style:State<UI.Style>.Binding) 
    {
        self._style = style
    }
}
