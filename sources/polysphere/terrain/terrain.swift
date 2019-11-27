import Noise
import PNG

import class Dispatch.DispatchQueue 

enum Terrain 
{
    static 
    func generate<Root>(isolines:Algorithm.Isolines, _ root:Root, 
        progress:WritableKeyPath<Root, Double?>, 
        return:WritableKeyPath<Root, Array2D<Vector4<UInt8>>?>) 
        where Root:AnyObject
    {
        DispatchQueue.global(qos: .userInitiated).async 
        {
            [weak root] in 
            
            guard var root:Root = root 
            else 
            {
                return 
            }
            
            let noise:(r:GradientNoise3D, g:GradientNoise3D, b:GradientNoise3D) = 
            (
                .init(amplitude: 1.2 * 0.5 * 255, frequency: 4, seed: 0),
                .init(amplitude: 1.2 * 0.5 * 255, frequency: 2, seed: 1),
                .init(amplitude: 1.2 * 0.5 * 255, frequency: 1, seed: 2)
            ) 
            
            let d:Int     = 512 
            let count:Int = 6 * d * d
            var j:Int     = 0
            let cubemap:Array2D<Vector4<UInt8>> = Algorithm.cubemap(size: d) 
            {
                let offset:Double = 0.75 * 255
                let r:UInt8 = .init(clamping: Int.init(offset + noise.r.evaluate($0.x, $0.y, $0.z))), 
                    g:UInt8 = .init(clamping: Int.init(offset + noise.g.evaluate($0.x, $0.y, $0.z))), 
                    b:UInt8 = .init(clamping: Int.init(offset + noise.b.evaluate($0.x, $0.y, $0.z)))
                let d:Double = isolines.distance(to: $0), 
                    i:UInt8  = .init(min(max(0, 128 + 800 * d), 255))
                
                j += 1
                if j & 0xff == 0 
                {
                    let percent:Double = .init(j) / .init(count)
                    root[keyPath: progress] = percent
                }
                return .init(r, g, b, i)
                // return .extend(.cast(128 + 127 * $0), .max)
            }
            
            root[keyPath: `return`] = cubemap
        }
    }
}
