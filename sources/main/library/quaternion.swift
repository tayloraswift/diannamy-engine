struct Quaternion<F>:Equatable, Interpolable where F:SwiftFloatingPoint
{
    private 
    var q:Vector4<F> 
    
    var a:F 
    {
        return self.q.w
    } 
    var b:Vector3<F> 
    {
        return self.q.xyz
    }
    
    static 
    var identity:Quaternion<F> 
    {
        return .init(1, .zero)
    }
    
    init(from s:Vector3<F>, to t:Vector3<F>) 
    {
        let a:F = (2 * (1 + s <> t)).squareRoot()
        self.init(0.5 * a, s >< t / a)
    }
    
    init(axis:Vector3<F>, angle:F)
    {
        self.init(F.cos(0.5 * angle), F.sin(0.5 * angle) * axis)
    }
    
    init(_ a:F, _ b:Vector3<F>)
    {
        self.init(.extend(b, a))
    }
    
    private 
    init(_ q:Vector4<F>) 
    {
        self.q = q
    }

    var matrix:Matrix3<F>
    {
        let r:Vector3<F>    = .init(self.b.y, self.b.z, self.b.x)
        let o:Vector3<F>    = self.b * r, 
            i:Vector3<F>    = self.b * self.b, 
            a:Vector3<F>    = self.b * self.a
        
        let v0:Vector3<F>   = .init(1 - 2 * (i.y + i.z) as F,     2 * (o.x + a.z) as F,     2 * (o.z - a.y) as F),
            v1:Vector3<F>   = .init(    2 * (o.x - a.z) as F, 1 - 2 * (i.x + i.z) as F,     2 * (o.y + a.x) as F),
            v2:Vector3<F>   = .init(    2 * (o.z + a.y) as F,     2 * (o.y - a.x) as F, 1 - 2 * (i.x + i.y) as F)
        return .init(v0, v1, v2)
    }
    
    mutating 
    func normalize() 
    {
        self.q.normalize()
    }
    func normalized() -> Quaternion<F>
    {
        return .init(self.q.normalized())
    }
    
    var inverse:Quaternion<F>
    {
        return .init(self.a, -self.b)
    }
    
    func rotate(_ point:Vector3<F>) -> Vector3<F> 
    {
        let r:Vector3<F> = 2 * ((self.b <> point) * self.b + self.a * (self.b >< point)), 
            s:Vector3<F> = point * (self.q <> self.inverse.q)
        return r + s
    }

    static
    func >< (q1:Quaternion<F>, q2:Quaternion<F>) -> Quaternion<F>
    {
        let a:F          = q1.a * q2.a               - q1.b <> q2.b, 
            b:Vector3<F> = q1.a * q2.b + q2.a * q1.b + q1.b >< q2.b
        return Quaternion.init(a, b).normalized()
    }
    
    // wrong implementation, need slerp 
    static 
    func interpolate(_ a:Quaternion<F>, _ b:Quaternion<F>, by t:F) -> Quaternion<F> 
    {
        let dot:F = a.q <> b.q 
        let v:(Vector4<F>, Vector4<F>) = 
        (
            dot < 0 ? -a.q : a.q, 
            b.q
        )
        
        let adot:F = abs(dot)
        guard adot < (1 - 0x1p-5) 
        else 
        {
            return .init((a.q * (1 - t) + b.q * t).normalized())
        }
        
        let theta:(F, F)
        theta.0         = .acos(adot)
        theta.1         = theta.0 * t
        let f:F         = .sin(theta.1) / .sin(theta.0)
        let s:(F, F)    = (.cos(theta.1) - adot * f, f)
        
        return .init((s.0 * v.0) + (s.1 * v.1))
    }
}
