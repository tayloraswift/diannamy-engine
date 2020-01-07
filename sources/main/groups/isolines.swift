extension Editor 
{
    final 
    class Isolines
    {
        // visual constants 
        private 
        enum Constants 
        {
            static 
            let color:
            (
                new:Vector3<UInt8>,
                moving:Vector3<UInt8>,
                selected:Vector3<UInt8>,
                preselected:Vector3<UInt8>,
                adjacent:Vector3<UInt8>
            ) 
            = 
            (
                .init(255, 120,   0), 
                .init(255,  60,   0), 
                .init(255,   0,  40), 
                .init(255,   0, 100),
                .init(255, 255, 255)
            )
        }
        
        private 
        enum Edit 
        {
            // use `Double` to store locations since that is what the underlying 
            // model uses as its representation
            case select((Int, Int)?)
            case move((Int, Int), Vector3<Double>)
            case insert((Int, Int), Vector3<Double>)
            
            // payload is optional because not all locations are valid insertion 
            // points (also makes initialization simpler). it stores a projected 
            // screen coordinate (itself optional, to handle situations where the 
            // point is not visible on-screen)
            // it stores an existing index, which is used to inherit continent/island 
            // names
            case new((Int, Int)?, (Vector3<Double>, projected:Vector2<Float>?)?)
        }
        
        private(set)
        var model:Algorithm.Isolines
        {
            didSet 
            {
                self.view.fresh = false
            }
        }
        private 
        var view:View 
        
        // UI 
        private 
        var indicator:
        (
            new:UI.Canvas.Geometry,
            moving:UI.Canvas.Geometry,
            selected:UI.Canvas.Geometry,
            preselected:UI.Canvas.Geometry,
            adjacent:UI.Canvas.Geometry
        )
        private 
        var symbol:
        (
            plus:UI.Canvas.Text, 
            _:Void
        )? 
        = nil
        
        private 
        var edit:Edit = .select(nil)
        private(set)
        var preselected:(Int, Int)?         = nil
        
        private 
        var viewport:Vector2<Float>         = .zero 
        
        private 
        var projected:[[Vector2<Float>?]]   = []
        {
            willSet 
            {
                self.lookup = nil
            }
        }
        private 
        var rayfilm:Camera<Float>.Rayfilm = .init(matrix: .identity, source: .zero)
        
        // place to cache the lookups done by self.contains(_:) so we don’t 
        // have to do another search on a .hover event 
        private 
        var lookup:(s:Vector2<Float>, index:(Int, Int))? = nil
        
        // Group conformance 
        var state:(focus:Bool, active:Bool, hover:Bool) = (false, false, false)
        
        init(filename:String)
        {
            self.model = .init(filename: filename)
            self.view  = .init()
            
            func ring(_ color:Vector3<UInt8>, alpha:(UInt8, UInt8)) -> UI.Canvas.Geometry 
            {
                .rectangle(at: .zero, 
                    padding: .init(5), 
                    border: .init(2), 
                    radius: 100, 
                    color: (fill: .extend(color, alpha.0), border: .extend(color, alpha.1)))
            }
            
            self.indicator = 
            (
                ring(Constants.color.new,           alpha: (.min, .max)), 
                ring(Constants.color.moving,        alpha: (.min, .max)), 
                ring(Constants.color.selected,      alpha: (.min, .max)), 
                ring(Constants.color.preselected,   alpha: (.min, .max)), 
                ring(Constants.color.adjacent,      alpha: (.min,  100))
            )
        }
        
        func reinit(filename:String) 
        {
            self.model          = .init(filename: filename)
            self.view           = .init()
            self.edit           = .select(nil)
            self.preselected    = nil 
            self.projected      = []
        }
        
        // should be called after self.update(_:style:viewport:frame) for the same renderframe
        func update(matrices:Camera<Float>.Matrices) 
        {
            let U:Matrix4<Float>        = matrices.U
            let camera:Vector3<Float>   = matrices.position
            let center:Vector3<Float>   = .zero // planet center
            
            func transform(_ r:Vector3<Double>) -> Vector2<Float>?
            {
                let node:Vector3<Float> = .cast(r)
                guard (camera - node) <> (node - center) >= 0 
                else 
                {
                    return nil 
                } 
                
                let p:Vector4<Float> = U >< .extend(node, 1), 
                    n:Vector2<Float> = p.xy / p.w * .init(1, -1)
                return (n * 0.5 + 0.5) * self.viewport
            }
            
            self.projected = self.model.indices.map 
            {
                // we load the previews, not the ground truth, so that the indicators 
                // rendered by `draw(_:)` follow the cursor around
                Editor.Isolines.preview(isoline: $0, in: self.model, edit: self.edit).map(transform(_:))
            }
            
            if case .new(let selected, let (r, projected: _)?) = self.edit 
            {
                self.edit = .new(selected, (r, projected: transform(r)))
            }
            
            self.rayfilm = matrices.rayfilm
        }
        
        func render() -> (vertices:[Mesh.ColorVertex], indices:[UInt32])?
        {
            guard !self.view.fresh
            else 
            {
                return nil 
            }
            
            self.view.render(self.model, edit: self.edit)
            return (self.view.vertices, self.view.indices)
        }
        
        func draw(_ canvas:UI.Canvas)
        {
            let fixed:(Int, Int)?, 
                occupied:(Int, Int)?
            switch self.edit 
            {
            case .select(nil):
                fixed       = nil 
                occupied    = nil 
                if  let index:(Int, Int)            = self.preselected, 
                    let s:Vector2<Float>            = self.projected[index.0   ][index.1   ]
                {
                    self.indicator.preselected.s0   = s
                    canvas.geometry(self.indicator.preselected, layer: .highlight)
                }
            
            case .select(let selected?):
                if  let s:Vector2<Float>            = self.projected[selected.0][selected.1]
                {
                    self.indicator.selected.s0      = s 
                    canvas.geometry(self.indicator.selected, layer: .highlight)
                }
                fixed       = nil 
                occupied    = selected 
                if  let index:(Int, Int)            = self.preselected, index != selected, 
                    let s:Vector2<Float>            = self.projected[index.0   ][index.1   ]
                {
                    self.indicator.preselected.s0   = s
                    canvas.geometry(self.indicator.preselected, layer: .highlight)
                }
            
            case .move(let selected, _):
                if  let s:Vector2<Float>            = self.projected[selected.0][selected.1]
                {
                    self.indicator.moving.s0        = s
                    canvas.geometry(self.indicator.moving, layer: .highlight)
                }
                fixed       = selected 
                occupied    = selected 
            
            case .insert(let selected, _):
                if  let s:Vector2<Float>            = self.projected[selected.0][selected.1]
                {
                    self.indicator.new.s0           = s
                    canvas.geometry(self.indicator.new, layer: .highlight)
                    
                    if var symbol:UI.Canvas.Text    = self.symbol?.plus
                    {
                        symbol.s0                   = s 
                        canvas.text(symbol, layer: .highlight)
                    }
                }
                fixed       = selected 
                occupied    = selected 
            
            case .new(let selected, let (_, projected: s)?):
                if  let selected:(Int, Int)         = selected, 
                    let s:Vector2<Float>            = self.projected[selected.0][selected.1]
                {
                    self.indicator.selected.s0      = s 
                    canvas.geometry(self.indicator.selected, layer: .highlight)
                }
                if  let s:Vector2<Float>            = s 
                {
                    self.indicator.new.s0           = s 
                    canvas.geometry(self.indicator.new, layer: .highlight)
                    
                    if var symbol:UI.Canvas.Text    = self.symbol?.plus
                    {
                        symbol.s0                   = s 
                        canvas.text(symbol, layer: .highlight)
                    }
                }
                
                return 
            
            case .new(_, nil):
                return
            }
            
            // draw adjacent indicators 
            guard let center:(Int, Int) = fixed ?? self.preselected ?? occupied
            else 
            {
                return 
            }
            let loop:[Vector2<Float>?] = self.projected[center.0]
            let before:Int = Self.wrap(center.1, under:  loop.indices),  
                after:Int  = Self.wrap(center.1, beyond: loop.indices)
            
            adjacent1:
            if before != center.1
            {
                if let occupied:(Int, Int) = occupied, occupied == (center.0, before) 
                {
                    break adjacent1
                }
                
                if let s:Vector2<Float> = loop[before]
                {
                    self.indicator.adjacent.s0 = s
                    canvas.geometry(self.indicator.adjacent, layer: .highlight)
                }
            }
            adjacent2:
            if after != center.1, after != before 
            {
                if let occupied:(Int, Int) = occupied, occupied == (center.0, after) 
                {
                    break adjacent2
                }
                
                if let s:Vector2<Float> = loop[after]
                {
                    self.indicator.adjacent.s0 = s
                    canvas.geometry(self.indicator.adjacent, layer: .highlight)
                }
            }
        }
    }
}

extension Editor.Isolines:UI.Group 
{
    // convenience function to perform index wraparound 
    private static 
    func wrap(_ index:Int, beyond indices:Range<Int>) -> Int 
    {
        return (index < indices.upperBound - 1 ? index : indices.lowerBound - 1) + 1
    }
    private static 
    func wrap(_ index:Int, under indices:Range<Int>) -> Int 
    {
        return (index > indices.lowerBound     ? index : indices.upperBound    ) - 1
    }
    // convenience function that performs left-hand → right-hand 
    private 
    func cast(_ s:Vector2<Float>) -> Camera<Float>.Ray 
    {
        let s:Vector2<Float> = .init(s.x, self.viewport.y - s.y)
        return self.rayfilm.cast(s)
    }
    
    func contains(_ s:Vector2<Float>) -> UI.Group?
    {
        switch self.edit 
        {
        case .select:
            return self.find(s) == nil ? nil : self
        case .move, .insert, .new:
            return self 
        }
    }
    
    func action(_ action:UI.Event.Action)
    {
        switch action 
        {
            case .primary(let s, doubled: let doubled):
                switch self.edit 
                {
                case .select(let selected):
                    if  doubled, 
                        let index:(Int, Int) = selected 
                    {
                        let r:Vector3<Double>       = 
                            .cast(Algorithm.project(ray: self.cast(s), onSphere: (.zero, 1)))
                        self.edit                   = .insert((index.0, index.1 + 1), r)
                        self.preselected            = nil
                    }
                    else 
                    {
                        self.edit                   = .select(self.find(s))
                    }
                
                case .move(let index, let r):
                    // commit edit 
                    self.model[index.0, index.1]    = r
                    self.edit                       = .select(index)
                
                case .insert(let index, let r):
                    // commit edit 
                    self.model.insert(r, at: index)
                    self.edit                       = .select(index)
                
                case .new(let selected, let (r, projected: _)?):
                    let name:String, 
                        group:String 
                    if let (i, _):(Int, Int) = selected 
                    {
                        let parent:Algorithm.Isolines.Isoline = self.model[i]
                        
                        group   = parent.group
                        name    = "\(group)-landmass-\(self.model.count{ $0.group == group })"
                    }
                    else 
                    {
                        // generate a unique continent name 
                        let continents:Set<String> = .init(self.model.map(\.group))
                        group   = "continent-\(continents.count)"
                        name    = "\(group)-landmass-0"
                    }
                    
                    self.model.append(.init([r], name: name, group: group))
                    self.edit   = .select((self.model.endIndex - 1, 0))
                
                case .new(let selected, nil):
                    self.edit   = .select(selected)
                }
            
            case .secondary(let s, doubled: _):
                switch self.edit 
                {
                case .select(_):
                    guard let index:(Int, Int) = self.find(s) 
                    else 
                    {
                        self.edit           = .select(nil)
                        break 
                    }
                    
                    let r:Vector3<Double>   = .cast(Algorithm.project(ray: self.cast(s), onSphere: (.zero, 1)))
                    self.edit               = .move(index, r.normalized())
                    self.view.fresh         = false
                
                case .move(let index, _):
                    // cancel edit 
                    self.edit               = .select(index)
                    self.view.fresh         = false
                
                case .insert(_, _), .new(_, _):
                    // cancel edit 
                    self.edit               = .select(nil)
                    self.view.fresh         = false 
                }
            
            case .hover(let s):
                switch self.edit 
                {
                case .select(_):
                    self.preselected        = self.find(s)
                
                case .move(let index, let old):
                    let r:Vector3<Double>   = .cast(Algorithm.project(ray: self.cast(s), onSphere: (.zero, 1)))
                    self.edit               = .move(index, r.normalized())
                    // almost always true, except when mouse is stationary and 
                    // ui engine is firing off regular `.hover` events 
                    if r != old 
                    {
                        // force an update of the displayed isolines, even though 
                        // no change has been committed to the model yet
                        self.view.fresh     = false
                    }
                
                case .insert(let index, let old):
                    let r:Vector3<Double>   = .cast(Algorithm.project(ray: self.cast(s), onSphere: (.zero, 1)))
                    self.edit               = .insert(index, r.normalized())
                    if r != old 
                    {
                        self.view.fresh     = false
                    }
                
                case .new(let selected, _):
                    let r:Vector3<Double>   = .cast(Algorithm.project(ray: self.cast(s), onSphere: (.zero, 1)))
                    // round-trip the projected value rather than storing the `s` cursor position 
                    // for ui truth/consistency
                    self.edit               = .new(selected, (r.normalized(), projected: .zero))
                }
                
            case .deactivate:
                self.edit                   = .select(nil) 
            case .dehover:
                self.preselected            = nil 
            
            case .key(.delete, .none):
                self.removeSelected()
            case .key(.backspace, .none):
                self.removeSelected()
                switch self.edit 
                {
                case .select(let selected?):
                    let before:(Int, Int) = 
                    (
                        selected.0, 
                        Self.wrap(selected.1, under: self.model[selected.0].indices)
                    )
                    self.edit = .select(before)
                default:
                    break 
                }
            
            default:
                break
        }
    }
    
    private 
    func removeSelected() 
    {
        switch self.edit 
        {
        case .select(let selected?):
            self.model.remove(at: selected)
            if self.model[selected.0].isEmpty 
            {
                self.edit = .select(nil)
            }
        default:
            break 
        }
    }
    
    func update(_:Int, styles:UI.Styles, viewport:Vector2<Int>, frame _:Rectangle<Int>)
    {
        self.viewport = .cast(viewport)
        
        // render the emblems, if they haven’t already been rendered 
        if self.symbol == nil 
        {
            let plus:UI.Canvas.Text = .symbol(.magnet, at: .x1, color: .extend(Constants.color.new, .max), 
                offset: .init(4, -4), 
                styles: styles)
            
            self.symbol = (plus, ())
        }
    }
    
    var cursor:(inactive:UI.Cursor, active:UI.Cursor)
    {
        (.hand, .hand)
    }
    
    private 
    func find(_ s:Vector2<Float>) -> (Int, Int)?
    {
        // look in 1-element cache first 
        if  let lookup:(s:Vector2<Float>, index:(Int, Int)) = self.lookup, 
            s == lookup.s 
        {
            return lookup.index 
        }
        
        for (i, isoline):(Int, [Vector2<Float>?]) in self.projected.enumerated()
        {
            for (j, node):(Int, Vector2<Float>?) in isoline.enumerated()
            {
                guard let node:Vector2<Float> = node 
                else 
                {
                    continue 
                }
                
                if (s - node) <> (s - node) < 7 * 7
                {
                    self.lookup = (s, (i, j))
                    return (i, j)
                }
            }
        }
        
        return nil
    }
    
    // helper function that performs edit substitutions
    private static 
    func preview(isoline i:Int, in model:Algorithm.Isolines, edit:Edit) -> Algorithm.Isolines.Isoline 
    {
        switch edit 
        {
        case .move((i, let j), let r):
            var edited:Algorithm.Isolines.Isoline   = model[i] 
            edited[j]                               = r 
            return edited
        
        case .insert((i, let j), let r):
            var edited:Algorithm.Isolines.Isoline   = model[i]
            edited.insert(r, at: j)
            return edited
        
        default:
            return model[i]
        }
    }
}

extension Editor.Isolines 
{
    private 
    struct View 
    {
        var fresh:Bool = false 
        private(set)
        var vertices:[Mesh.ColorVertex] = [], 
            indices:[UInt32]            = []
        
        mutating 
        func render(_ model:Algorithm.Isolines, edit:Edit) 
        {
            var vertices:[Mesh.ColorVertex] = [], 
                indices:[UInt32]            = []
            for i:Int in model.indices 
            {
                let isoline:Algorithm.Isolines.Isoline = 
                    Editor.Isolines.preview(isoline: i, in: model, edit: edit)
                
                let base:UInt32 = .init(vertices.count)
                for e:Int in isoline.indices  
                {
                    let edge:(Vector3<Double>, Vector3<Double>) = isoline[edge: e]
                    let subdivided:[Mesh.ColorVertex] = Algorithm.slerp(edge.0, edge.1, resolution: 0.01).map 
                    {
                        .init(.cast($0), color: .init(repeating: .max))
                    }
                    vertices.append(contentsOf: subdivided)
                }
                let count:UInt32 = .init(vertices.count) - base
                
                for k:UInt32 in 0 ..< count 
                {
                    let line:(UInt32, UInt32, UInt32, UInt32) = 
                    (
                        k &+ (k < 3 ? count : 0) &- 3,
                        k &+ (k < 2 ? count : 0) &- 2,
                        k &+ (k < 1 ? count : 0) &- 1,
                        k
                    )
                    
                    indices.append(base + line.0)
                    indices.append(base + line.1)
                    indices.append(base + line.2)
                    indices.append(base + line.3)
                }
            }
            
            self.vertices = vertices
            self.indices  = indices
            self.fresh    = true 
        }
    }
}
