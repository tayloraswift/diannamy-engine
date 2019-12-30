extension Algorithm 
{
    static 
    func tangent<F>(normal:Vector3<F>) -> Vector3<F> 
        where F:SIMDScalar & FloatingPoint
    {
        let tangent:Vector3<F>
        if abs(normal.x) < abs(normal.y) 
        {
            if abs(normal.y) < abs(normal.z) 
            {
                // z is the longest component 
                tangent = .init(normal.z, .zero, -normal.x)
            }
            else 
            {
                // y is longest component 
                tangent = .init(.zero, -normal.z, normal.y)
            }
        }
        else 
        {
            if abs(normal.x) < abs(normal.z) 
            {
                // z is the longest component 
                tangent = .init(normal.z, .zero, -normal.x)
            }
            else 
            {
                // x is longest component 
                tangent = .init(-normal.y, normal.x, .zero)
            }
        }
        
        return tangent.normalized()
    }
    static 
    func tangents<F>(normal:Vector3<F>) -> (Vector3<F>, Vector3<F>) 
        where F:SIMDScalar & FloatingPoint
    {
        let x:Vector3<F> = Self.tangent(normal: normal), 
            y:Vector3<F> = normal >< x
        return (x, y)
    }
    
    struct Fluid<F> 
        where F:SIMDScalar & ExpressibleByFloatLiteral & BinaryFloatingPoint & ElementaryFunctions 
    {
        
        
        struct Cell 
        {
            var mass:F 
            var velocity:Vector3<F>
            var temperature:F
            
            mutating 
            func combine(with other:Self) 
            {
                self = .combine(self, other)
            }
            
            static 
            func combine(_ a:Self, _ b:Self) -> Self 
            {
                let momentum:Vector3<F> = a.mass * a.velocity + b.mass * b.velocity, 
                    mass:F              = a.mass + b.mass
                let velocity:Vector3<F> = momentum / mass
                let temperature:F = (a.mass * a.temperature + b.mass * b.temperature) / mass  
                return .init(mass: mass, velocity: velocity, temperature: temperature) 
            }
            
            static 
            func * (_ fraction:F, cell:Self) -> Self 
            {
                var cell = cell 
                cell.mass *= fraction 
                return cell
            }
        }
        
        var buffer:[Cell]
        private 
        var current:Int
               
        let sphere:FibonacciSphere<F>
        
        var count:Int 
        {
            self.sphere.points.count
        }
        
        subscript(current index:Int) -> Cell 
        {
            get 
            {
                self.buffer[self.count * self.current + index]
            }
            set(cell) 
            {
                self.buffer[self.count * self.current + index] = cell
            }
        }
        subscript(next index:Int) -> Cell 
        {
            get 
            {
                self.buffer[self.count * (1 - self.current) + index]
            }
            set(cell) 
            {
                self.buffer[self.count * (1 - self.current) + index] = cell
            }
        }
        
        init(count:Int) 
        {
            self.sphere = .init(count: count)
            self.buffer = .init(repeating: .init(mass: 1, velocity: .zero, temperature: 273), count: 2 * count)
            
            self.current = 0 
        }
        
        mutating 
        func advect() 
        {
            // clear next buffer 
            for i:Int in 0 ..< self.count 
            {
                self[next: i] = .init(mass: 0, velocity: .zero, temperature: 0)
            }
            
            for i:Int in 0 ..< self.count 
            {
                let a:Vector3<F>    = self.sphere.points[i], 
                    cell:Cell       = self[current: i]
                let x:Vector3<F>    = Algorithm.tangent(normal: a)
                let p:Quaternion    = .init(axis: x, angle: .pi / 40)
                let samples:Int     = 32
                for s:Int in 0 ..< samples
                {
                    let q:Quaternion = .init(axis: a, angle: 2 * .pi * .init(s) / .init(samples))
                    let b:Vector3<F> = (p >< q).rotate(a)
                    
                    let perimeter:FibonacciSphere.Address = self.sphere.address(of: b)
                    let other:(Cell, Cell, Cell) = 
                    (
                        self[current: perimeter.triangle.0],
                        self[current: perimeter.triangle.1],
                        self[current: perimeter.triangle.2]
                    )
                    
                    
                    let m:(F, F)
                    m.0 = cell.mass
                    m.1 = other.0.mass * perimeter.coordinates.0 
                        + other.1.mass * perimeter.coordinates.1
                        + other.2.mass * perimeter.coordinates.2
                    let dp:F = m.0 + m.1 > 0 ? max(0, m.0 / (m.0 + m.1) - 0.5) : 0
                    let omega:Vector3<F> = dp * F.pi / 40 * q.rotate(x) + cell.velocity, 
                        speed:F = omega.length 
                    
                    var packet:Cell     = cell 
                        packet.velocity = omega
                        packet.mass    /= .init(samples)
                    
                    guard speed > 0 
                    else 
                    {
                        self[next: i].combine(with: packet)
                        continue 
                    }
                    
                    let r:Quaternion = .init(axis: omega / speed, angle: speed)
                    let c:Vector3<F> = r.rotate(a)
                    let destination:FibonacciSphere.Address = self.sphere.address(of: c)
                    
                    self[next: destination.triangle.0].combine(with: destination.coordinates.0 * packet)
                    self[next: destination.triangle.1].combine(with: destination.coordinates.1 * packet)
                    self[next: destination.triangle.2].combine(with: destination.coordinates.2 * packet)
                }
            }
            
            self.current = 1 - self.current
        }
    }
}
