extension Editor 
{
    final 
    class Isolines
    {
        private(set)
        var model:Algorithm.Isolines, 
            view:View 
        
        // UI 
        private 
        var indicator:
        (
            selected:UI.DrawElement.Geometry,
            preselected:UI.DrawElement.Geometry
        )
        
        private(set)
        var selected:(Int, Int)?            = nil, 
            preselected:(Int, Int)?         = nil
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
            
            self.indicator = 
            (
                .rectangle(at: .zero, 
                    padding: .init(7),
                    radius: 100, 
                    color: (fill: .init(repeating: .max), border: .init(repeating: .max))),
                .rectangle(at: .zero, 
                    padding: .init(5), 
                    border: .init(2), 
                    radius: 100, 
                    color: (fill: .init(.max, .max, .max, 0), border: .init(repeating: .max)))
            )
        }
        
        // should be called after self.update(_:style:viewport:frame) for the same renderframe
        func update(projection U:Matrix4<Float>, camera:Vector3<Float>, center:Vector3<Float>) 
        {
            self.projected = self.model.isolines.map 
            {
                $0.points.map 
                {
                    let node:Vector3<Float> = .cast($0)
                    guard (camera - node) <> (node - center) >= 0 
                    else 
                    {
                        return nil 
                    } 
                    
                    let p:Vector4<Float> = U >< .extend(node, 1), 
                        n:Vector2<Float> = p.xy / p.w * .init(1, -1)
                    return (n * 0.5 + 0.5) * self.viewport
                }
            }
        }
        
        func render() -> (vertices:[Mesh.ColorVertex], indices:[UInt32])
        {
            self.view.render(self.model)
            return (self.view.vertices, self.view.indices)
        }
        
        func contribute(
            text    :inout [UI.DrawElement.Text], 
            geometry:inout [UI.DrawElement.Geometry])
        {
            if  let index:(Int, Int)        = self.selected, 
                let facing:Vector2<Float>   = self.projected[index.0][index.1]
            {
                self.indicator.selected.s0 = facing 
                geometry.append(self.indicator.selected)
            }
            if  let index:(Int, Int)        = self.preselected, 
                let facing:Vector2<Float>   = self.projected[index.0][index.1]
            {
                if  let selected:(Int, Int) = self.selected, 
                        selected == index 
                {
                    return 
                }
                self.indicator.preselected.s0 = facing
                geometry.append(self.indicator.preselected)
            }
        }
    }
}

extension Editor.Isolines:UI.Group 
{
    func contains(_ s:Vector2<Float>) -> UI.Group?
    {
        guard let _:(Int, Int) = self.find(s)
        else 
        {
            return nil 
        }
        return self
    }
    
    func action(_ action:UI.Event.Action)
    {
        switch action 
        {
            case .primary(let s):
                self.selected = self.find(s)
                print("select node \(self.selected ?? (-1, -1))")
            
            case .hover(let s):
                self.preselected = self.find(s)
            
            case .deactivate:
                print("deselected")
                self.selected = nil 
            case .dehover:
                self.preselected = nil 
            
            default:
                break
        }
    }
    
    func update(_:Int, styles _:UI.Styles, viewport:Vector2<Int>, frame _:Rectangle<Int>)
    {
        self.viewport = .cast(viewport)
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
}

extension Editor.Isolines 
{
    struct View 
    {
        private(set)
        var vertices:[Mesh.ColorVertex] = [], 
            indices:[UInt32]            = []
        
        mutating 
        func render(_ model:Algorithm.Isolines) 
        {
            var vertices:[Mesh.ColorVertex] = [], 
                indices:[UInt32]            = []
            for isoline:Algorithm.Isolines.Isoline in model.isolines 
            {
                let base:UInt32 = .init(vertices.count)
                for edge:(Vector3<Double>, Vector3<Double>) in isoline 
                {
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
        }
    }
}
