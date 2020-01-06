extension Algorithm 
{
    enum Delaunay 
    {
        private 
        struct Triangulation<F> where F:SwiftFloatingPoint
        {
            struct Triangle 
            {
                enum Index:Int
                {
                    case a, b, c
                    
                    static 
                    func + (lhs:Self, rhs:Int) -> Self 
                    {
                        guard let index:Index = Index.init(rawValue: (lhs.rawValue + rhs) % 3) 
                        else 
                        {
                            Log.unreachable()
                        }
                        return index
                    }
                }
                enum Children 
                {
                    case none 
                    case two(Int, Int) 
                    case three(Int, Int, Int)
                } 
                
                let vertices:(Int, Int, Int)
                var neighbors:(Int?, Int?, Int?)
                
                var children:Children
                
                subscript(vertex:Index) -> Int 
                {
                    switch vertex 
                    {
                    case .a:
                        return self.vertices.0
                    case .b:
                        return self.vertices.1
                    case .c:
                        return self.vertices.2
                    }
                }
                
                init(vertices:(Int, Int, Int), neighbors:(Int?, Int?, Int?), children:Children) 
                {
                    self.vertices = vertices 
                    self.neighbors = neighbors 
                    self.children = children
                }
                
                mutating 
                func set(neighbor:Index, to triangle:Int?) 
                {
                    switch neighbor 
                    {
                    case .a:
                        self.neighbors.0 = triangle
                    case .b:
                        self.neighbors.1 = triangle
                    case .c:
                        self.neighbors.2 = triangle
                    }
                }
                mutating 
                func get(neighbor:Index) -> Int?
                {
                    switch neighbor 
                    {
                    case .a:
                        return self.neighbors.0
                    case .b:
                        return self.neighbors.1
                    case .c:
                        return self.neighbors.2
                    }
                }
            }
            
            var vertices:[Vector3<F>], 
                triangles:[Triangle] 
            
            mutating 
            func triangulate(poles:(Int, Int, Int, Int, Int, Int)) 
            {
                for p:Int in self.vertices.indices
                {
                    guard   p != poles.0, 
                            p != poles.1,
                            p != poles.2,
                            p != poles.3,
                            p != poles.4,
                            p != poles.5 
                    else 
                    {
                        continue 
                    }
                    
                    let index:Int                    = self.findTriangle(containing: p)
                    let subdivisions:(Int, Int, Int) = self.subdivide(index, at: p)
                    
                    self.enforceDelaunay(subdivisions.0)
                    self.enforceDelaunay(subdivisions.1)
                    self.enforceDelaunay(subdivisions.2)
                }
            }
            
            private mutating 
            func enforceDelaunay(_ index:Int) 
            {
                guard let opposite:Int = self.triangles[index].neighbors.0
                else 
                {
                    return 
                }
                
                let vertices:(Vector3<F>, Vector3<F>, Vector3<F>) = self.vertices(of: opposite)
                let circumcenter:Vector3<F> = Self.circumcenter(of: vertices), 
                    circumradius:F          = Self.arc(vertices.0, circumcenter)
                if Self.arc(self.vertices(of: index).0, circumcenter) < circumradius 
                {
                    let trans:(Int, Int) = self.flip(index)
                    self.enforceDelaunay(trans.0)
                    self.enforceDelaunay(trans.1)
                }
            }
            
            private 
            func vertices(of index:Int) -> (Vector3<F>, Vector3<F>, Vector3<F>) 
            {
                let vindices:(Int, Int, Int) = self.triangles[index].vertices
                return (self.vertices[vindices.0], self.vertices[vindices.1], self.vertices[vindices.2])
            }
            
            private 
            func findRoot(containing point:Vector3<F>) -> Int 
            {
                for i:Int in 0 ..< 8 where Self.contains(point, in: self.vertices(of: i)) 
                {
                    return i
                }
                
                Log.unreachable()
            }
            private 
            func findTriangle(containing p:Int) -> Int 
            {
                let point:Vector3<F> = self.vertices[p]
                // segregate by octant
                var current:Int = self.findRoot(containing: point)
                while true 
                {
                    let children:Triangle.Children = self.triangles[current].children
                    switch children 
                    {
                    case .none:
                        return current 
                    case .two(let c0, let c1):
                        if      Self.contains(point, in: self.vertices(of: c0)) 
                        {
                            current = c0 
                        }
                        else 
                        {
                            current = c1 
                        }
                    case .three(let c0, let c1, let c2):
                        if      Self.contains(point, in: self.vertices(of: c0)) 
                        {
                            current = c0 
                        }
                        else if Self.contains(point, in: self.vertices(of: c1)) 
                        {
                            current = c1 
                        }
                        else 
                        {
                            current = c2 
                        }
                    }
                }
            }
            
            private 
            func order(_ triangle:Int, _ edge:(Int, Int)) -> Triangle.Index 
            {
                switch self.triangles[triangle].vertices
                {
                case (_, edge.0, edge.1):
                    return .a
                
                case (edge.1, _, edge.0):
                    return .b
                    
                case (edge.0, edge.1, _):
                    return .c
                    
                default:
                    Log.unreachable()
                }
            }
            
            private mutating 
            func subdivide(_ A:Int, at p:Int) -> (Int, Int, Int) 
            {
                guard   case .none = self.triangles[A].children
                else 
                {
                    Log.unreachable()
                }
                /*
                   i.2 ------ 0 ------ i.1
                     \       / \       /
                      \ A'2 /   \ A'1 /
                       \   /  A  \   /
                        \ /       \ /
                         1---------2
                          \       /
                           \ A'0 /
                            \   /
                             \ /
                             i.0
                */
                let a:(Int, Int, Int)       = self.triangles[A].vertices 
                let NA:(Int?, Int?, Int?)   = self.triangles[A].neighbors
                
                let B:Int = self.triangles.count, 
                    C:Int = self.triangles.count + 1, 
                    D:Int = self.triangles.count + 2
                
                let b:(Int, Int, Int)       = (p, a.0, a.1), 
                    c:(Int, Int, Int)       = (p, a.1, a.2),
                    d:(Int, Int, Int)       = (p, a.2, a.0)
                
                let NB:(Int?, Int?, Int?)   = (NA.2, C, D),
                    NC:(Int?, Int?, Int?)   = (NA.0, D, B),
                    ND:(Int?, Int?, Int?)   = (NA.1, B, C)
                
                self.triangles.append(.init(vertices: b, neighbors: NB, children: .none))
                self.triangles.append(.init(vertices: c, neighbors: NC, children: .none))
                self.triangles.append(.init(vertices: d, neighbors: ND, children: .none))
                
                // update opposite triangle relationships 
                if let O:Int = NA.0 
                {
                    let i:Triangle.Index = self.order(O, (a.2, a.1))
                    self.triangles[O].set(neighbor: i, to: C)
                } 
                if let O:Int = NA.1
                {
                    let i:Triangle.Index = self.order(O, (a.0, a.2))
                    self.triangles[O].set(neighbor: i, to: D)
                } 
                if let O:Int = NA.2
                {
                    let i:Triangle.Index = self.order(O, (a.1, a.0))
                    self.triangles[O].set(neighbor: i, to: B)
                } 
                
                self.triangles[A].children = .three(B, C, D)
                
                return (B, C, D)
            }
            
            private mutating 
            func flip(_ A:Int) -> (Int, Int)
            {
                let a:(Int, Int, Int)       = self.triangles[A].vertices 
                let NA:(Int?, Int?, Int?)   = self.triangles[A].neighbors
                guard let B:Int             = NA.0 
                else 
                {
                    // existence of opposite triangle should have been verified by caller
                    Log.unreachable()
                }
                
                guard   case .none = self.triangles[A].children, 
                        case .none = self.triangles[B].children 
                else 
                {
                    Log.unreachable()
                }
                
                let i:Triangle.Index = self.order(B, (a.2, a.1))
                let C:Int? = self.triangles[B].get(neighbor: i + 2),
                    D:Int? = self.triangles[B].get(neighbor: i + 1)
                
                let e:(Int, Int, Int)       = (a.0, self.triangles[B][i], a.2), 
                    f:(Int, Int, Int)       = (a.0, a.1, self.triangles[B][i])
                
                let E:Int                   = self.triangles.count, 
                    F:Int                   = self.triangles.count + 1
                let NE:(Int?, Int?, Int?)   = (C, NA.1, F),
                    NF:(Int?, Int?, Int?)   = (D, E, NA.2)
                
                self.triangles.append(.init(vertices: e, neighbors: NE, children: .none))
                self.triangles.append(.init(vertices: f, neighbors: NF, children: .none))
                
                // update opposite triangle relationships 
                let edge:((Int, Int), (Int, Int), (Int, Int), (Int, Int)) = 
                (
                    (a.0, a.2), 
                    (a.1, a.0), 
                    (self.triangles[B][i + 1], self.triangles[B][i    ]), 
                    (self.triangles[B][i    ], self.triangles[B][i + 2])
                )
                if let O:Int = NA.1 
                {
                    let i:Triangle.Index = self.order(O, edge.0)
                    self.triangles[O].set(neighbor: i, to: E)
                }
                if let O:Int = NA.2 
                {
                    let i:Triangle.Index = self.order(O, edge.1)
                    self.triangles[O].set(neighbor: i, to: F)
                }
                if let O:Int = C 
                {
                    let i:Triangle.Index = self.order(O, edge.2)
                    self.triangles[O].set(neighbor: i, to: E)
                }
                if let O:Int = D 
                {
                    let i:Triangle.Index = self.order(O, edge.3)
                    self.triangles[O].set(neighbor: i, to: F)
                }
                
                self.triangles[A].children = .two(E, F)
                self.triangles[B].children = .two(E, F)
                
                return (E, F)
            }
            
            static 
            func circumcenter(of points:(Vector3<F>, Vector3<F>, Vector3<F>)) -> Vector3<F> 
            {
                let x:Vector3<F> = (points.1 - points.0) >< (points.2 - points.0)
                let center:Vector3<F> = x.normalized()
                return center
            }
            
            static 
            func arc(_ p0:Vector3<F>, _ p1:Vector3<F>) -> F 
            {
                return F.acos(p0 <> p1)
            }
            
            private static 
            func contains(_ point:Vector3<F>, in v:(Vector3<F>, Vector3<F>, Vector3<F>)) -> Bool 
            {
                let normals:(Vector3<F>, Vector3<F>, Vector3<F>) = 
                (
                    v.0 >< v.1, 
                    v.1 >< v.2, 
                    v.2 >< v.0
                )
                
                return (point <> normals.0 >= 0) && (point <> normals.1 >= 0) && (point <> normals.2 >= 0)
            }
        }
        
        static 
        func triangulate<F>(_ points:[Vector3<F>]) -> [(Int, Int, Int)] where F:SwiftFloatingPoint
        {
            let poles:(Int, Int, Int, Int, Int, Int)
            guard points.count >= 6 
            else 
            {
                return []
            }
            
            func poles(_ component:KeyPath<Vector3<F>, F>) -> (Int, Int) 
            {
                var minimum:F =  .infinity,
                    maximum:F = -.infinity
                var index:(minimum:Int, maximum:Int) = (0, 0)
                for i:Int in points.indices 
                {
                    let value:F = points[i][keyPath: component]
                    if value < minimum 
                    {
                        minimum = value 
                        index.minimum = i
                    }
                    if value >= maximum
                    {
                        maximum = value 
                        index.maximum = i
                    }
                }
                return index
            }
            (poles.5, poles.0) = poles(_:)(\.z)
            (poles.4, poles.2) = poles(_:)(\.y)
            (poles.3, poles.1) = poles(_:)(\.x)
            let triangles:[Triangulation<F>.Triangle] = 
            [
                .init(
                    vertices: (poles.0, poles.1, poles.2), 
                    neighbors: (4, 1, 3), 
                    children: .none),
                .init(
                    vertices: (poles.0, poles.2, poles.3), 
                    neighbors: (5, 2, 0), 
                    children: .none),
                .init(
                    vertices: (poles.0, poles.3, poles.4), 
                    neighbors: (6, 3, 1), 
                    children: .none),
                .init(
                    vertices: (poles.0, poles.4, poles.1), 
                    neighbors: (7, 0, 2), 
                    children: .none), 
                
                .init(
                    vertices: (poles.5, poles.2, poles.1), 
                    neighbors: (0, 7, 5), 
                    children: .none),
                .init(
                    vertices: (poles.5, poles.3, poles.2), 
                    neighbors: (1, 4, 6), 
                    children: .none),
                .init(
                    vertices: (poles.5, poles.4, poles.3), 
                    neighbors: (2, 5, 7), 
                    children: .none),
                .init(
                    vertices: (poles.5, poles.1, poles.4), 
                    neighbors: (3, 6, 4), 
                    children: .none),
            ]
            
            var triangulation:Triangulation<F> = .init(vertices: points, triangles: triangles)
            triangulation.triangulate(poles: poles)
            
            var output:[(Int, Int, Int)] = []
            for triangle:Triangulation<F>.Triangle in triangulation.triangles 
            {
                guard case .none = triangle.children
                else 
                {
                    continue 
                }
                
                let points:(Vector3<F>, Vector3<F>, Vector3<F>) = 
                (
                    triangulation.vertices[triangle.vertices.0],
                    triangulation.vertices[triangle.vertices.1],
                    triangulation.vertices[triangle.vertices.2]
                )
                
                guard points.0.length > 0.5, points.1.length > 0.5, points.2.length > 0.5
                else 
                {
                    Log.fatal("\(points)")
                }
                
                /*
                let circumcenter:Vector3<F> = Triangulation.circumcenter(of: points)
                guard circumcenter.z >= 0 
                else 
                {
                    continue 
                } */
                
                output.append(triangle.vertices)
            }
            
            return output
        }
    }
}
