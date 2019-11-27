import struct Foundation.Data
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder

extension Algorithm 
{
    // resolution in radians
    static 
    func slerp<F>(_ a:Vector3<F>, _ b:Vector3<F>, resolution:F) -> [Vector3<F>]
        where F:SIMDScalar & ExpressibleByFloatLiteral & BinaryFloatingPoint & ElementaryFunctions
    {
        // get two vertices and angle between
        let d:F     = a <> b, 
            theta:F = .acos(d.clipped(to: -1 ... 1)), 
            scale:F = 1 / (1 - d * d).squareRoot()
        // determine subdivisions 
        let subdivisions:Int = .init(theta / resolution) + 1
        
        // push the fixed vertex 
        var vertices:[Vector3<F>] = [a]
        // push the interpolated vertices 
        for s:Int in 1 ..< subdivisions
        {
            let t:F                 = .init(s) / .init(subdivisions)
            let sines:Vector2<F>    = .init(.sin(.init(theta - theta * t, theta * t))), 
                factors:Vector2<F>  = scale * sines
            
            let components:(Vector3<F>, Vector3<F>) = (factors.x * a, factors.y * b)
            vertices.append(components.0 + components.1)
        }
        
        return vertices
    }
    
    struct Isolines:Codable 
    {
        struct Isoline:Codable, RandomAccessCollection 
        {
            let height:Int, 
                group:String, 
                name:String,
                points:[Vector3<Double>]
            
            var startIndex:Int 
            {
                self.points.startIndex
            }
            var endIndex:Int 
            {
                self.points.endIndex
            }
            subscript(index:Int) -> (Vector3<Double>, Vector3<Double>) 
            {
                let previous:Int = index + (index < 1 ? self.points.count : 0) - 1
                return (self.points[previous], self.points[index])
            }
        }
        
        var background:String
        var isolines:[Isoline]
        
        enum CodingKeys:String, CodingKey 
        {
            case background = "background-image"
            case isolines = "isolines"
            
            case foo
        }
        
        init(from decoder:Decoder) throws 
        {
            let serialized:KeyedDecodingContainer<CodingKeys> = 
                try decoder.container(keyedBy: CodingKeys.self)
            
            self.background = try serialized.decode(String.self,    forKey: .background)
            self.isolines   = try serialized.decode([Isoline].self, forKey: .isolines)
        }
        
        func encode(to encoder:Encoder) throws 
        {
            var serialized:KeyedEncodingContainer<CodingKeys> = 
                encoder.container(keyedBy: CodingKeys.self)
            
            try serialized.encode(self.background, forKey: .background)
            try serialized.encode(self.isolines,   forKey: .isolines)
        }
        
        init(filename:String)  
        {
            do 
            {
                let data:Foundation.Data            = .init(try File.read(filename))
                let decoder:Foundation.JSONDecoder  = .init()
                self = try decoder.decode(Self.self, from: data)
            }
            catch 
            {
                Log.trace(error: error)
                self.background = ""
                self.isolines   = []
            }
        }
        
        func distance(to x:Vector3<Double>) -> Double 
        {
            var minimum:Double = .infinity
            for isoline:Isoline in self.isolines 
            {
                for e:Int in isoline.indices  
                {
                    let edge:(Vector3<Double>, Vector3<Double>) = isoline[e]
                    let n:Vector3<Double> = (edge.0 >< edge.1).normalized()
                    
                    let a:Vector3<Double> = n >< edge.0,
                        b:Vector3<Double> = edge.1 >< n 
                    
                    let distance:Double
                    // point is within arc shadow 
                    if x <> a >= 0, x <> b >= 0 
                    {
                        distance = .acos(n <> x) - .pi / 2
                    }
                    // point is closer to edge.0 than edge.1
                    else if x <> edge.0 >= x <> edge.1 
                    {
                        let index:Int                   = e + (e < 2 ? isoline.count : 0) - 2
                        let predecessor:Vector3<Double> = isoline.points[index]
                        let m:Vector3<Double> = (predecessor >< edge.0).normalized()
                        
                        let magnitude:Double = .acos(edge.0 <> x)
                        // width of slice is greater than 180°
                        if predecessor <> n < 0 
                        {
                            if x <> n > 0 || x <> m > 0 
                            {
                                distance = -magnitude
                            }
                            else 
                            {
                                distance = magnitude
                            }
                        }
                        // width of slice is less than 180°
                        else 
                        {
                            if x <> n > 0 && x <> m > 0 
                            {
                                distance = -magnitude
                            }
                            else 
                            {
                                distance = magnitude
                            }
                        }
                    }
                    else 
                    {
                        continue 
                    }
                    
                    if abs(distance) < abs(minimum) 
                    {
                        minimum = distance
                    }
                }
            }
            
            return minimum
        }
    }
}
