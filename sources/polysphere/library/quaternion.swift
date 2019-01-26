struct Quaternion<F>:Equatable where F:BinaryFloatingPoint
{
    var a:F, 
        b:Math<F>.V3

    var length:F
    {
        return (self.a * self.a + Math.eusq(self.b)).squareRoot()
    }
    
    init(from s:Math<F>.V3, to t:Math<F>.V3) 
    {
        let a:F             = (2 * (1 + Math.dot(s, t))).squareRoot(), 
            x:Math<F>.V3    = Math.cross(s, t)
        self.init(0.5 * a, Math.scale(x, by: 1 / a))
    }
    
    init(_ a:F, _ b:Math<F>.V3)
    {
        self.a = a
        self.b = b
    }

    init()
    {
        self.init(1, (0, 0, 0))
    }
    
    init(axis:Math<F>.V3, c:F, s:F) 
    {
        self.init(c, Math.scale(axis, by: s))
    }

    var matrix:Math<F>.Mat3
    {
        let xx:F = self.b.x * self.b.x,
            yy:F = self.b.y * self.b.y,
            zz:F = self.b.z * self.b.z,

            xy:F = self.b.x * self.b.y,
            xz:F = self.b.x * self.b.z,
            yz:F = self.b.y * self.b.z,
            ax:F = self.a   * self.b.x,
            ay:F = self.a   * self.b.y,
            az:F = self.a   * self.b.z
        //fill in the first row
        return 
            (
                (1 - 2 * (yy + zz),      2 * (xy + az),      2 * (xz - ay)),
                (    2 * (xy - az),  1 - 2 * (xx + zz),      2 * (yz + ax)),
                (    2 * (xz + ay),      2 * (yz - ax),  1 - 2 * (xx + yy))
            )
    }

    func normalized() -> Quaternion
    {
        let factor:F = 1 / self.length
        return .init(self.a * factor, Math.scale(self.b, by: factor))
    }
    
    var inverse:Quaternion
    {
        return .init(self.a, Math.neg(self.b))
    }
    
    func rotate(_ point:Math<F>.V3) -> Math<F>.V3 
    {
        return  Math.add(
                Math.add(   Math.scale(self.b, by:               2 * Math.dot(self.b, point)), 
                            Math.scale(point,  by: self.a * self.a - Math.dot(self.b, self.b))), 
                            Math.scale(Math.cross(self.b, point), by: 2 * self.a)
                            )
    }

    static
    func * (q1:Quaternion, q2:Quaternion) -> Quaternion
    {
        let a:F          = q1.a * q2.a - Math.dot(q1.b, q2.b), 
            b:Math<F>.V3 = 
            Math.add(   Math.add(Math.scale(q2.b, by: q1.a), Math.scale(q1.b, by: q2.a)), 
                        Math.cross(q1.b, q2.b))
        return Quaternion(a, b).normalized()
    }
    
    static
    func == (q1:Quaternion, q2:Quaternion) -> Bool
    {
        return q1.a == q2.a && q1.b == q2.b
    }
}

extension Quaternion where F:_SwiftFloatingPoint 
{
    init(axis:Math<F>.V3, angle:F)
    {
        self.init(axis: axis, c: F.cos(0.5 * angle), s: F.sin(0.5 * angle))
    }
}
