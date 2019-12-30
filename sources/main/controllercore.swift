/* struct ControllerCore3D
{
    var view:UIElement 
    
    var plane:ControlPlane
    
    var frame:Rectangle<Float> = .zero
    {
        didSet 
        {
            self.plane.invalidate()
        }
    }
    
    init()
    {
        let plane:ControlPlane = .init(  .init(center: .zero,
                            orientation: .identity,
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
            self.plane.invalidate()
        
        case .model:
            self.state.model.reset() 
            if reset
            {
                self.action         = .none
                self.preselection   = nil 
            }
        }
    }
    
    
    func test(_ position:Vector2<Float>) -> Bool  
    {
        return true 
    }
    
    
    // project a sphere point into 2D
    private  
    func trace(_ point:Vector3<Float>, viewport:Vector2<Float>) -> Vector2<Float>?
    {
        guard (point - self.plane.position) <> (point - 0) < 0 
        else 
        {
            return nil 
        }
        
        return viewport * self.plane.trace(point)
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
            self.plane.jump(to: .zero)

        default:
            break
        }
        return nil
    }
    
    mutating
    func scroll(_:Coordinator.Context, _ direction:UI.Direction, _:Vector2<Float>) -> Coordinator.Event?
    {
        self.plane.bump(direction, action: .zoom)
        return nil
    }
    
    
    mutating 
    func down(_ position:Vector2<Float>, _ button:UI.Action, doubled:Bool, plane:ControlPlane) 
        -> [UI.Response]
    {
        switch button 
        {
        case .primary:
            if  doubled, 
                case .selectNode(let (l, i)) = self.action
            {
                // why is this not already normalized?
                let p:Vector3<Float> = plane.project(position, on: .zero, radius: 1).normalized()
                self.action = .addNode((l, i + 1), p) 
                break 
            }
            
            switch self.action 
            {
            case .none, .selectNode:
                if let (l, i):(Int, Int) = self.findTrace(position, threshold: 8) 
                {
                    self.action = .selectNode((l, i))
                }
                else 
                {
                    self.action = .none
                    return .plane(.orbit(position, release: button))
                }
            
            case .moveNode(let (l, i), let location):
                self.action = .selectNode((l, i))
                self.updateTrace(plane.trace(location), at: index)
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
    func move(_:Coordinator.Context, _ position:Vector2<Float>) -> Coordinator.Event?
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
            let p:Vector3<Float> = self.plane.project(position, on: .zero, radius: 1).normalized()
            self.action = .anchorMoving(index, p)
        
        case .anchorNew(let index, _):
            let p:Vector3<Float> = self.plane.project(position, on: .zero, radius: 1).normalized()
            self.action = .anchorNew(index, p)
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
    func up(_:Coordinator.Context, _ button:UI.Action, _ position:Vector2<Float>) -> Coordinator.Event?
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
} */
