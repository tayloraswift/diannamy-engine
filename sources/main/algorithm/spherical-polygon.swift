import struct Foundation.Data
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder

import enum File.File

extension Algorithm 
{
    // resolution in radians
    static 
    func slerp<F>(_ a:Vector3<F>, _ b:Vector3<F>, resolution:F) -> [Vector3<F>]
        where F:SwiftFloatingPoint
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
    
    static 
    func project<F>(ray:Camera<F>.Ray, onSphere sphere:(center:Vector3<F>, radius:F)) -> Vector3<F>
        where F:SwiftFloatingPoint
    {
        // need to deal with case of sphere not centered at origin
        let c:Vector3<F>    = sphere.center - ray.source, 
            l:F             = c <> ray.vector
        
        let a:F 
        
        let c2:F            = c <> c
        let discriminant:F  = sphere.radius * sphere.radius + l * l - c2
        if discriminant < 0 
        {
            // sin(C - B - A)   = sin C cos -B cos -A + sin -B cos -A cos C + sin -A cos C cos -B - sin C sin -B sin -A
            //                  = sin C cos B cos A - sin B cos A cos C - sin A cos C cos B - sin C sin B sin A
            // sin(π - B - A)   = sin π cos B cos A - sin B cos A cos π - sin A cos π cos B - sin π sin B sin A
            //                  = sin B cos A + sin A cos B
            //            sin C = sin B cos A + sin A cos B
            //                  = sqrt(1 - cos^2 B) cos A + sqrt(1 - cos^2 A) cos B
            
            //            sin A = h / c 
            //                  = sqrt(c^2 - r^2) / c
            //                a = c sin A / sin C
            //                  = c sin A / (sin B cos A + sin A cos B)
            // 
            // this is numerically stable for A, B >> 0, which will be satisfied so long 
            // as the camera is not too far from the planet that the disk reduces to a point.
            let h:F = (c2 - sphere.radius * sphere.radius).squareRoot(), 
                g:F = c.normalized() <> ray.vector
                
            a = (F.sqrt(c2) * h as F) / (sphere.radius * F.sqrt(1 - g * g as F) + g * h as F)
        }
        else 
        {
            a = l - discriminant.squareRoot()
        }
        
        return ray.source + a * ray.vector
    }
    
    struct Isolines:Codable, RandomAccessCollection
    {
        struct Isoline:Codable, RandomAccessCollection 
        {
            let height:Int, 
                group:String, 
                name:String
            private 
            var points:[Vector3<Double>]
            
            var startIndex:Int 
            {
                self.points.startIndex
            }
            var endIndex:Int 
            {
                self.points.endIndex
            }
            
            subscript(index:Int) -> Vector3<Double>
            {
                get 
                {
                    self.points[index]
                }
                set(v) 
                {
                    self.points[index] = v
                }
            }
            subscript(edge index:Int) -> (Vector3<Double>, Vector3<Double>) 
            {
                let previous:Int = index + (index < 1 ? self.points.count : 0) - 1
                return (self.points[previous], self.points[index])
            }
            
            mutating 
            func insert(_ point:Vector3<Double>, at index:Int) 
            {
                self.points.insert(point, at: index)
            }
            mutating 
            func remove(at index:Int) 
            {
                self.points.remove(at: index)
            }
            
            init(_ points:[Vector3<Double>], name:String, group:String) 
            {
                self.height = 0 
                self.group  = group 
                self.name   = name 
                self.points = points
            }
        }
        
        var background:String
        private 
        var isolines:[Isoline]
        
        var startIndex:Int 
        {
            self.isolines.startIndex
        }
        var endIndex:Int 
        {
            self.isolines.endIndex
        }
        
        subscript(i:Int) -> Isoline 
        {
            self.isolines[i]
        }
        subscript(i:Int, j:Int) -> Vector3<Double> 
        {
            get 
            {
                self.isolines[i][j]
            }
            set(v) 
            {
                self.isolines[i][j] = v
            }
        }
        
        mutating 
        func insert(_ point:Vector3<Double>, at index:(Int, Int)) 
        {
            self.isolines[index.0].insert(point, at: index.1)
        }
        mutating 
        func remove(at index:(Int, Int)) 
        {
            self.isolines[index.0].remove(at: index.1)
        }
        
        mutating 
        func append(_ isoline:Isoline) 
        {
            self.isolines.append(isoline)
        }
        
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
                let data:Foundation.Data            = .init(try File.read(from: filename))
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
        
        func save(filename:String) 
        {
            do 
            {
                let encoder:Foundation.JSONEncoder  = .init()
                let data:Foundation.Data = try encoder.encode(self)
                try File.write(.init(data), to: filename, overwrite: true)
            }
            catch 
            {
                Log.trace(error: error)
            }
        }
        
        func distance(to x:Vector3<Double>) -> Double 
        {
            var minimum:Double = .infinity
            for isoline:Isoline in self 
            {
                for e:Int in isoline.indices  
                {
                    let edge:(Vector3<Double>, Vector3<Double>) = isoline[edge: e]
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
                        let predecessor:Vector3<Double> = isoline[index]
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
