extension BinaryFloatingPoint 
{
    static 
    var phi:Self 
    {
        (1 + (5 as Self).squareRoot()) / 2
    }
}

enum Algorithm 
{
    struct FibonacciSphere<F> 
        where F:SIMDScalar & ExpressibleByFloatLiteral & BinaryFloatingPoint & ElementaryFunctions
    {
        struct Address 
        {
            let triangle:(Int, Int, Int)
            let coordinates:(F, F, F)
        }
        
        let points:[Vector3<F>]
        let triangulation:[(Int, Int, Int)]
        let neighbors:[[(triangle:Int, point:Int)]]
        
        // http://extremelearning.com.au/evenly-distributing-points-on-a-sphere/
        init(count:Int) 
        {
            let N:F = .init(count)
            var points:[Vector3<F>] = []
                points.reserveCapacity(count)
            for i:Int in 0 ..< count 
            {
                let i:F          = .init(i)
                let t:(x:F, y:F) = ((i + 0.5) / N, i / .phi)
                
                let sin:(theta:F, phi:F), 
                    cos:(theta:F, phi:F)
                
                sin.theta = 1 - 2 * t.x 
                cos.theta = F.sqrt(4 * t.x * (1 - t.x))
                sin.phi   = F.sin(2 * .pi * t.y)
                cos.phi   = F.cos(2 * .pi * t.y)
                
                points.append(.init(cos.theta * cos.phi, cos.theta * sin.phi, sin.theta)) 
            }
            
            self.points             = points
            self.triangulation      = Delaunay.triangulate(points)
            
            var neighbors:[[(triangle:Int, point:Int)]] = .init(repeating: [], count: points.count)
            
            for (t, triangle):(Int, (Int, Int, Int)) in zip(self.triangulation.indices, self.triangulation) 
            {
                neighbors[triangle.0].append((t, triangle.1))
                neighbors[triangle.1].append((t, triangle.2))
                neighbors[triangle.2].append((t, triangle.0))
            }
            
            // sort neighbors in counterclockwise order 
            for (i, point) in zip(neighbors.indices, points) 
            {
                let tangents:(x:Vector3<F>, y:Vector3<F>) = Algorithm.tangents(normal: point)
                
                let keyed:[(phi:F, triangle:Int, point:Int)] = neighbors[i].map 
                {
                    let v:Vector3<F> = points[$0.1] - point
                    let x:F = v <> tangents.x, 
                        y:F = v <> tangents.y
                    return (.argument(y: y, x: x), $0.0, $0.1)
                }
                
                neighbors[i] = keyed.sorted 
                {
                    $0.phi < $1.phi 
                }.map 
                {
                    ($0.triangle, $0.point) 
                }
            } 
            
            self.neighbors = neighbors
        }
        
        func nearest(to point:Vector3<F>) -> Int 
        {
            func frac(_ a:F, _ b:F) -> F 
            {
                return (-((a * b).rounded(.down))).addingProduct(a, b)
            }
            
            let N:F         = .init(self.points.count)
            
            let zone:F      = F.log((5 as F).squareRoot() * N * F.pi * (1 - point.z * point.z)) / F.log(F.phi * F.phi)
            let k:F         = max(2, zone.rounded(.down))
            
            let f:F         = .power(.phi, to: k) / (5 as F).squareRoot()
            let E:(F, F)    = (f.rounded(), (f * .phi).rounded())
            
            let bx:(F, F) = 
            (
                F.pi * (frac(E.0 + 1, F.phi - 1) - F.phi + 1), 
                F.pi * (frac(E.1 + 1, F.phi - 1) - F.phi + 1)
            )
            let b:(Vector2<F>, Vector2<F>) = 
            (
                2 * .init(bx.0, -1 / N * E.0),
                2 * .init(bx.1, -1 / N * E.1)
            )
            let B:Matrix2<F>    = .init(b.0, b.1), 
                B_1:Matrix2<F>  = B.inversed()
            
            let c:Vector2<F>    = (B_1 >< .init(.argument(y: point.y, x: point.x), point.z - 1 + 1 / N)).rounded(.down)
            var d:F = .infinity, 
                j:Int   = 0
            for corner:Vector2<F> in [.init(0, 0), .init(0, 1), .init(1, 0), .init(1, 1)]
            {
                let ct:F    = .init(B[0].y, B[1].y) <> (c + corner) + 1 - 1 / N
                let z:F     = min(max(ct, -1), 1) * 2 - ct
                
                let ii:Int  = .init((N * 0.5 * (1 - z))), 
                    i:F     = .init(ii)
                
                let t:(x:F, y:F) = ((i + 0.5) / N, i / .phi)
                
                let sin:(theta:F, phi:F), 
                    cos:(theta:F, phi:F)
                
                sin.theta = 1 - 2 * t.x 
                cos.theta = F.sqrt(4 * t.x * (1 - t.x))
                sin.phi   = F.sin(2 * .pi * t.y)
                cos.phi   = F.cos(2 * .pi * t.y)
                
                let q:Vector3<F> = .init(cos.theta * cos.phi, cos.theta * sin.phi, sin.theta)
                let r2:F = (q - point) <> (q - point)
                if r2 < d 
                {
                    d = r2 
                    j = ii
                }
            }
            
            return j
        }
        
        func triangle(containing point:Vector3<F>) -> Int 
        {
            let i:Int        = self.nearest(to: point), 
                k:Int        = self.neighbors[i].count
            let c:Vector3<F> = self.points[i]
            // divider 
            if (c >< self.points[self.neighbors[i][0].point]) <> point < 0 
            {
                // quadrant III, IV
                for j:Int in 1 ..< k
                {
                    guard (c >< self.points[self.neighbors[i][k - j].point]) <> point < 0 
                    else 
                    {
                        return self.neighbors[i][k - j].triangle
                    }
                }
                return self.neighbors[i][0].triangle
            }
            else 
            {
                // quadrant I, II
                for j:Int in 1 ..< k
                {
                    guard (c >< self.points[self.neighbors[i][j].point]) <> point >= 0 
                    else 
                    {
                        return self.neighbors[i][j - 1].triangle
                    }
                }
                return self.neighbors[i][k - 1].triangle
            }
        }
        
        func address(of point:Vector3<F>) -> Address 
        {
            let triangle:(Int, Int, Int) = self.triangulation[self.triangle(containing: point)]
            let (a, b, c):(Vector3<F>, Vector3<F>, Vector3<F>) = 
            (
                self.points[triangle.0],
                self.points[triangle.1],
                self.points[triangle.2]
            )
            
            let v:(Vector3<F>, Vector3<F>, Vector3<F>) = (b - a, c - a, point - a)
            let d:((F, F), F, (F, F)) = 
            (
                (v.0 <> v.0, v.0 <> v.1),
                v.1 <> v.1, 
                (v.2 <> v.0, v.2 <> v.1)
            )
            
            let denominator:F = d.0.0 * d.1 - d.0.1 * d.0.1
            let coordinates:(u:F, v:F, w:F)
            coordinates.v = (d.1   * d.2.0 - d.0.1 * d.2.1) / denominator
            coordinates.w = (d.0.0 * d.2.1 - d.0.1 * d.2.0) / denominator
            coordinates.u = 1 - coordinates.v - coordinates.w
            
            return .init(triangle: triangle, coordinates: coordinates)
        }
    }
}
