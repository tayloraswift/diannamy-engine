extension Algorithm 
{
    static 
    func cubemap<R>(size:Int, generator:(Vector3<Double>) throws -> R) rethrows -> Array2D<R> 
    {
        var output:[R] = []
            output.reserveCapacity(size * size * 6)
        for (x, y):(Vector3<Double>, Vector3<Double>) in 
        [
            (-Vector3<Double>.k, -Vector3<Double>.j), // +x
            ( Vector3<Double>.k, -Vector3<Double>.j), // -x
            ( Vector3<Double>.i,  Vector3<Double>.k), // +y
            ( Vector3<Double>.i, -Vector3<Double>.k), // -y
            ( Vector3<Double>.i, -Vector3<Double>.j), // +z
            (-Vector3<Double>.i, -Vector3<Double>.j), // -z
        ]
        {
            let z:Vector3<Double> = x >< y
            for i:Int in 0 ..< size 
            {
                for j:Int in 0 ..< size
                {
                    let t:Vector2<Double> = 2 * (.cast(.init(j, i)) + 0.5) / .init(repeating: .init(size)) - 1
                    let n:Vector3<Double> = (x * t.x + y * t.y - z).normalized()
                    output.append(try generator(n))
                }
            }
        }
        
        return .init(output, size: .init(size, size * 6))
    }
}
