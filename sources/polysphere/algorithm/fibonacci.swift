enum Algorithm 
{
    // http://extremelearning.com.au/evenly-distributing-points-on-a-sphere/
    static 
    func fibonacci<F>(_ count:Int, as:F.Type) -> [Vector3<F>] 
        where F:SIMDScalar & ExpressibleByFloatLiteral & BinaryFloatingPoint & ElementaryFunctions
    {
        let phi:F = (1 + F.sqrt(5)) / 2
        func k(_ n:F) -> Int 
        {
            return .init(((F.log(n / 1.5) / F.log(phi))).rounded(.down))
        }
        func g(_ n:F) -> F 
        {
            return k(n) & 1 == 0 ? 3 - phi : phi
        }
        let N:F = .init(count), 
            g:F = g(_:)(N)
        var points:[Vector3<F>] = []
            points.reserveCapacity(count)
        for i:Int in 0 ..< count 
        {
            let i:F          = .init(i)
            let t:(x:F, y:F) = ((i + 0.5) / N, i / g)
            
            let sin:(theta:F, phi:F), 
                cos:(theta:F, phi:F)
            
            sin.theta = 1 - 2 * t.x 
            cos.theta = F.sqrt(4 * t.x * (1 - t.x))
            sin.phi   = F.sin(2 * .pi * t.y)
            cos.phi   = F.cos(2 * .pi * t.y)
            
            points.append(.init(cos.theta * cos.phi, cos.theta * sin.phi, sin.theta)) 
        }
        
        return points
    }
}
