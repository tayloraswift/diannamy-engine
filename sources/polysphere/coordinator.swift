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
    
    // window framebuffer size is distinct from viewport size, 
    // as multiple viewports can be tiled in the same window 
    var window:Vector2<Float> = .zero 
    {
        didSet 
        {
            self.renderer.viewport(.init(.zero, self.window))
        }
    }
    
    init(renderer:Renderer)
    {
        self.renderer       = renderer 
        self.controllers    = []
        self._style         = .init(wrappedValue: .init())
    }
    
    mutating 
    func event(_:UI.Event) 
    {
        self.redraw = true 
    }
    
    mutating 
    func process(delta:Int) -> Bool 
    {
        guard ({ true }()) || self.redraw 
        else 
        {
            return false 
        }
        
        self.redraw = false 
        self.draw()
        return true 
    }
    
    private 
    func draw() 
    {
        self.renderer.draw()
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
