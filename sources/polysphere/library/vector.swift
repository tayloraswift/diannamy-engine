// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 1)
import func Glibc.sin
import func Glibc.cos
import func Glibc.tan
import func Glibc.asin
import func Glibc.acos
import func Glibc.atan
import func Glibc.atan2

infix operator <> :MultiplicationPrecedence // dot product
infix operator >< :MultiplicationPrecedence // cross product
infix operator &<> :MultiplicationPrecedence // wrapping dot product
infix operator &>< :MultiplicationPrecedence // wrapping cross product

infix operator ~~ :ComparisonPrecedence     // distance test 
infix operator !~ :ComparisonPrecedence     // distance test 

// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 21)

extension FixedWidthInteger 
{
    // rounds up to the next power of two, with 0 rounding up to 1. 
    // numbers that are already powers of two return themselves
    @inline(__always)
    static 
    func nextPowerOfTwo(_ n:Self) -> Self 
    {
        return 1 &<< (Self.bitWidth - (n - 1).leadingZeroBitCount)
    }
}
extension FloatingPoint 
{
    mutating 
    func clip(to interval:ClosedRange<Self>) 
    {
        self = self.clipped(to: interval)
    }
     
    func clipped(to interval:ClosedRange<Self>) -> Self 
    {
        return max(interval.lowerBound, min(self, interval.upperBound))
    }
    
    static 
    func lerp(_ a:Self, _ b:Self, _ t:Self) -> Self 
    {
        return a.addingProduct(a, -t).addingProduct(b, t)
    } 
}

protocol Mathematical
{
    associatedtype Math:MathImplementations where Math.Value == Self
}
protocol MathImplementations 
{
    associatedtype Value
    
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 62)
    static func sin(_:Value) -> Value
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 62)
    static func cos(_:Value) -> Value
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 62)
    static func tan(_:Value) -> Value
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 62)
    static func asin(_:Value) -> Value
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 62)
    static func acos(_:Value) -> Value
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 62)
    static func atan(_:Value) -> Value
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 64)
    static func atan2(y:Value, x:Value) -> Value
}

// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 68)
extension Float:Mathematical
{
    enum Math:MathImplementations
    {
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 73)
        @inline(__always)
        static 
        func sin(_ x:Float) -> Float 
        {
            return Glibc.sin(x)
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 73)
        @inline(__always)
        static 
        func cos(_ x:Float) -> Float 
        {
            return Glibc.cos(x)
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 73)
        @inline(__always)
        static 
        func tan(_ x:Float) -> Float 
        {
            return Glibc.tan(x)
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 73)
        @inline(__always)
        static 
        func asin(_ x:Float) -> Float 
        {
            return Glibc.asin(x)
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 73)
        @inline(__always)
        static 
        func acos(_ x:Float) -> Float 
        {
            return Glibc.acos(x)
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 73)
        @inline(__always)
        static 
        func atan(_ x:Float) -> Float 
        {
            return Glibc.atan(x)
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 80)
        
        @inline(__always)
        static
        func atan2(y:Float, x:Float) -> Float
        {
            return Glibc.atan2(y, x)
        }
    }
}
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 68)
extension Double:Mathematical
{
    enum Math:MathImplementations
    {
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 73)
        @inline(__always)
        static 
        func sin(_ x:Double) -> Double 
        {
            return Glibc.sin(x)
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 73)
        @inline(__always)
        static 
        func cos(_ x:Double) -> Double 
        {
            return Glibc.cos(x)
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 73)
        @inline(__always)
        static 
        func tan(_ x:Double) -> Double 
        {
            return Glibc.tan(x)
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 73)
        @inline(__always)
        static 
        func asin(_ x:Double) -> Double 
        {
            return Glibc.asin(x)
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 73)
        @inline(__always)
        static 
        func acos(_ x:Double) -> Double 
        {
            return Glibc.acos(x)
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 73)
        @inline(__always)
        static 
        func atan(_ x:Double) -> Double 
        {
            return Glibc.atan(x)
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 80)
        
        @inline(__always)
        static
        func atan2(y:Double, x:Double) -> Double
        {
            return Glibc.atan2(y, x)
        }
    }
}
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 90)

// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 92)
extension SIMD2:Mathematical where Scalar:Mathematical
{
    enum Math:MathImplementations
    {
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 97)
        @inline(__always)
        static 
        func sin(_ v:SIMD2<Scalar>) -> SIMD2<Scalar> 
        {
            return .init(Scalar.Math.sin(v.x), Scalar.Math.sin(v.y))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 97)
        @inline(__always)
        static 
        func cos(_ v:SIMD2<Scalar>) -> SIMD2<Scalar> 
        {
            return .init(Scalar.Math.cos(v.x), Scalar.Math.cos(v.y))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 97)
        @inline(__always)
        static 
        func tan(_ v:SIMD2<Scalar>) -> SIMD2<Scalar> 
        {
            return .init(Scalar.Math.tan(v.x), Scalar.Math.tan(v.y))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 97)
        @inline(__always)
        static 
        func asin(_ v:SIMD2<Scalar>) -> SIMD2<Scalar> 
        {
            return .init(Scalar.Math.asin(v.x), Scalar.Math.asin(v.y))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 97)
        @inline(__always)
        static 
        func acos(_ v:SIMD2<Scalar>) -> SIMD2<Scalar> 
        {
            return .init(Scalar.Math.acos(v.x), Scalar.Math.acos(v.y))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 97)
        @inline(__always)
        static 
        func atan(_ v:SIMD2<Scalar>) -> SIMD2<Scalar> 
        {
            return .init(Scalar.Math.atan(v.x), Scalar.Math.atan(v.y))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 104)
        
        @inline(__always)
        static
        func atan2(y:SIMD2<Scalar>, x:SIMD2<Scalar>) -> SIMD2<Scalar>
        {
            return .init(Scalar.Math.atan2(y: y.x, x: x.x), Scalar.Math.atan2(y: y.y, x: x.y))
        }
    }
}

struct Vector2<Scalar>:Hashable, Codable where Scalar:SIMDScalar 
{
    var storage:SIMD2<Scalar>
    
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 119)
    var x:Scalar 
    {
        get 
        {
            return self.storage.x
        }
        set(x)
        {
            self.storage.x = x
        }
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 119)
    var y:Scalar 
    {
        get 
        {
            return self.storage.y
        }
        set(y)
        {
            self.storage.y = y
        }
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 131)
    
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 145)
    
    subscript(index:Int) -> Scalar 
    {
        return self.storage[index]
    }
    
    init(repeating repeatedValue:Scalar)
    {
        self.init(.init(repeatedValue, repeatedValue))
    }
    
    init(_ x:Scalar, _ y:Scalar)
    {
        self.init(.init(x, y))
    }
    
    init(_ storage:SIMD2<Scalar>) 
    {
        self.storage = storage 
    }
    
    func map<Result>(_ transform:(Scalar) throws -> Result) rethrows -> Vector2<Result>
        where Result:SIMDScalar 
    {
        return .init(try transform(self.x), try transform(self.y))
    }
}

extension Vector2 where Scalar:BinaryInteger 
{
    static 
    func cast<T>(_ v:Vector2<T>) -> Vector2<Scalar> where T:BinaryFloatingPoint 
    {
        return v.map(Scalar.init(_:))
    }
    static 
    func cast<T>(_ v:Vector2<T>) -> Vector2<Scalar> where T:BinaryInteger 
    {
        return v.map(Scalar.init(_:))
    }
}
extension Vector2 where Scalar:FloatingPoint 
{
    static 
    func cast<Source>(_ v:Vector2<Source>) -> Vector2<Scalar> where Source:BinaryInteger 
    {
        return v.map(Scalar.init(_:))
    }
}
extension Vector2 where Scalar:BinaryFloatingPoint 
{
    static 
    func cast<Source>(_ v:Vector2<Source>) -> Vector2<Scalar> where Source:BinaryFloatingPoint 
    {
        return v.map(Scalar.init(_:))
    }
}

extension Vector2 where Scalar:FixedWidthInteger
{
    static 
    var zero:Vector2<Scalar> 
    {
        return .init(.zero) 
    }
    
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 212)
    static 
    func &<< (lhs:Vector2<Scalar>, rhs:Vector2<Scalar>) 
        -> Vector2<Scalar>
    {
        return .init(lhs.storage &<< rhs.storage)
    }
    static 
    func &<< (lhs:Vector2<Scalar>, rhs:Scalar) 
        -> Vector2<Scalar>
    {
        return .init(lhs.storage &<< rhs)
    }
    static 
    func &<< (lhs:Scalar, rhs:Vector2<Scalar>) 
        -> Vector2<Scalar>
    {
        return .init(lhs &<< rhs.storage)
    }
    
    static 
    func &<<= (lhs:inout Vector2<Scalar>, rhs:Vector2<Scalar>)
    {
        lhs.storage &<<= rhs.storage
    }
    static 
    func &<<= (lhs:inout Vector2<Scalar>, rhs:Scalar)
    {
        lhs.storage &<<= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 212)
    static 
    func &>> (lhs:Vector2<Scalar>, rhs:Vector2<Scalar>) 
        -> Vector2<Scalar>
    {
        return .init(lhs.storage &>> rhs.storage)
    }
    static 
    func &>> (lhs:Vector2<Scalar>, rhs:Scalar) 
        -> Vector2<Scalar>
    {
        return .init(lhs.storage &>> rhs)
    }
    static 
    func &>> (lhs:Scalar, rhs:Vector2<Scalar>) 
        -> Vector2<Scalar>
    {
        return .init(lhs &>> rhs.storage)
    }
    
    static 
    func &>>= (lhs:inout Vector2<Scalar>, rhs:Vector2<Scalar>)
    {
        lhs.storage &>>= rhs.storage
    }
    static 
    func &>>= (lhs:inout Vector2<Scalar>, rhs:Scalar)
    {
        lhs.storage &>>= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 212)
    static 
    func &+ (lhs:Vector2<Scalar>, rhs:Vector2<Scalar>) 
        -> Vector2<Scalar>
    {
        return .init(lhs.storage &+ rhs.storage)
    }
    static 
    func &+ (lhs:Vector2<Scalar>, rhs:Scalar) 
        -> Vector2<Scalar>
    {
        return .init(lhs.storage &+ rhs)
    }
    static 
    func &+ (lhs:Scalar, rhs:Vector2<Scalar>) 
        -> Vector2<Scalar>
    {
        return .init(lhs &+ rhs.storage)
    }
    
    static 
    func &+= (lhs:inout Vector2<Scalar>, rhs:Vector2<Scalar>)
    {
        lhs.storage &+= rhs.storage
    }
    static 
    func &+= (lhs:inout Vector2<Scalar>, rhs:Scalar)
    {
        lhs.storage &+= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 212)
    static 
    func &- (lhs:Vector2<Scalar>, rhs:Vector2<Scalar>) 
        -> Vector2<Scalar>
    {
        return .init(lhs.storage &- rhs.storage)
    }
    static 
    func &- (lhs:Vector2<Scalar>, rhs:Scalar) 
        -> Vector2<Scalar>
    {
        return .init(lhs.storage &- rhs)
    }
    static 
    func &- (lhs:Scalar, rhs:Vector2<Scalar>) 
        -> Vector2<Scalar>
    {
        return .init(lhs &- rhs.storage)
    }
    
    static 
    func &-= (lhs:inout Vector2<Scalar>, rhs:Vector2<Scalar>)
    {
        lhs.storage &-= rhs.storage
    }
    static 
    func &-= (lhs:inout Vector2<Scalar>, rhs:Scalar)
    {
        lhs.storage &-= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 212)
    static 
    func &* (lhs:Vector2<Scalar>, rhs:Vector2<Scalar>) 
        -> Vector2<Scalar>
    {
        return .init(lhs.storage &* rhs.storage)
    }
    static 
    func &* (lhs:Vector2<Scalar>, rhs:Scalar) 
        -> Vector2<Scalar>
    {
        return .init(lhs.storage &* rhs)
    }
    static 
    func &* (lhs:Scalar, rhs:Vector2<Scalar>) 
        -> Vector2<Scalar>
    {
        return .init(lhs &* rhs.storage)
    }
    
    static 
    func &*= (lhs:inout Vector2<Scalar>, rhs:Vector2<Scalar>)
    {
        lhs.storage &*= rhs.storage
    }
    static 
    func &*= (lhs:inout Vector2<Scalar>, rhs:Scalar)
    {
        lhs.storage &*= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 212)
    static 
    func / (lhs:Vector2<Scalar>, rhs:Vector2<Scalar>) 
        -> Vector2<Scalar>
    {
        return .init(lhs.storage / rhs.storage)
    }
    static 
    func / (lhs:Vector2<Scalar>, rhs:Scalar) 
        -> Vector2<Scalar>
    {
        return .init(lhs.storage / rhs)
    }
    static 
    func / (lhs:Scalar, rhs:Vector2<Scalar>) 
        -> Vector2<Scalar>
    {
        return .init(lhs / rhs.storage)
    }
    
    static 
    func /= (lhs:inout Vector2<Scalar>, rhs:Vector2<Scalar>)
    {
        lhs.storage /= rhs.storage
    }
    static 
    func /= (lhs:inout Vector2<Scalar>, rhs:Scalar)
    {
        lhs.storage /= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 212)
    static 
    func % (lhs:Vector2<Scalar>, rhs:Vector2<Scalar>) 
        -> Vector2<Scalar>
    {
        return .init(lhs.storage % rhs.storage)
    }
    static 
    func % (lhs:Vector2<Scalar>, rhs:Scalar) 
        -> Vector2<Scalar>
    {
        return .init(lhs.storage % rhs)
    }
    static 
    func % (lhs:Scalar, rhs:Vector2<Scalar>) 
        -> Vector2<Scalar>
    {
        return .init(lhs % rhs.storage)
    }
    
    static 
    func %= (lhs:inout Vector2<Scalar>, rhs:Vector2<Scalar>)
    {
        lhs.storage %= rhs.storage
    }
    static 
    func %= (lhs:inout Vector2<Scalar>, rhs:Scalar)
    {
        lhs.storage %= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 242)
    
    func roundedUp(exponent:Int) -> Vector2<Scalar>
    { 
        let mask:Scalar                 = .max &<< exponent 
        let truncated:SIMD2<Scalar>  = self.storage & mask
        let carry:SIMD2<Scalar> = 
            SIMD2<Scalar>.zero.replacing(with: 1 &<< exponent, where: self.storage & ~mask .!= 0)
        return .init(truncated &+ carry)
    } 
    
    var wrappingSum:Scalar 
    {
        return self.x &+ self.y
    }
    var wrappingVolume:Scalar
    {
        return self.x &* self.y
    }
    
    static func &<> (lhs:Vector2<Scalar>, rhs:Vector2<Scalar>) -> Scalar
    {
        return (lhs &* rhs).wrappingSum
    }
}

extension Vector2 where Scalar:FloatingPoint 
{
    static 
    var zero:Vector2<Scalar> 
    {
        return .init(.zero) 
    }
    
    prefix static 
    func - (operand:Vector2<Scalar>) -> Vector2<Scalar>
    {
        return .init(-operand.storage)
    }
    
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 282)
    static 
    func + (lhs:Vector2<Scalar>, rhs:Vector2<Scalar>) 
        -> Vector2<Scalar>
    {
        return .init(lhs.storage + rhs.storage)
    }
    static 
    func + (lhs:Vector2<Scalar>, rhs:Scalar) 
        -> Vector2<Scalar>
    {
        return .init(lhs.storage + rhs)
    }
    static 
    func + (lhs:Scalar, rhs:Vector2<Scalar>) 
        -> Vector2<Scalar>
    {
        return .init(lhs + rhs.storage)
    }
    
    static 
    func += (lhs:inout Vector2<Scalar>, rhs:Vector2<Scalar>)
    {
        lhs.storage += rhs.storage
    }
    static 
    func += (lhs:inout Vector2<Scalar>, rhs:Scalar)
    {
        lhs.storage += rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 282)
    static 
    func - (lhs:Vector2<Scalar>, rhs:Vector2<Scalar>) 
        -> Vector2<Scalar>
    {
        return .init(lhs.storage - rhs.storage)
    }
    static 
    func - (lhs:Vector2<Scalar>, rhs:Scalar) 
        -> Vector2<Scalar>
    {
        return .init(lhs.storage - rhs)
    }
    static 
    func - (lhs:Scalar, rhs:Vector2<Scalar>) 
        -> Vector2<Scalar>
    {
        return .init(lhs - rhs.storage)
    }
    
    static 
    func -= (lhs:inout Vector2<Scalar>, rhs:Vector2<Scalar>)
    {
        lhs.storage -= rhs.storage
    }
    static 
    func -= (lhs:inout Vector2<Scalar>, rhs:Scalar)
    {
        lhs.storage -= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 282)
    static 
    func * (lhs:Vector2<Scalar>, rhs:Vector2<Scalar>) 
        -> Vector2<Scalar>
    {
        return .init(lhs.storage * rhs.storage)
    }
    static 
    func * (lhs:Vector2<Scalar>, rhs:Scalar) 
        -> Vector2<Scalar>
    {
        return .init(lhs.storage * rhs)
    }
    static 
    func * (lhs:Scalar, rhs:Vector2<Scalar>) 
        -> Vector2<Scalar>
    {
        return .init(lhs * rhs.storage)
    }
    
    static 
    func *= (lhs:inout Vector2<Scalar>, rhs:Vector2<Scalar>)
    {
        lhs.storage *= rhs.storage
    }
    static 
    func *= (lhs:inout Vector2<Scalar>, rhs:Scalar)
    {
        lhs.storage *= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 282)
    static 
    func / (lhs:Vector2<Scalar>, rhs:Vector2<Scalar>) 
        -> Vector2<Scalar>
    {
        return .init(lhs.storage / rhs.storage)
    }
    static 
    func / (lhs:Vector2<Scalar>, rhs:Scalar) 
        -> Vector2<Scalar>
    {
        return .init(lhs.storage / rhs)
    }
    static 
    func / (lhs:Scalar, rhs:Vector2<Scalar>) 
        -> Vector2<Scalar>
    {
        return .init(lhs / rhs.storage)
    }
    
    static 
    func /= (lhs:inout Vector2<Scalar>, rhs:Vector2<Scalar>)
    {
        lhs.storage /= rhs.storage
    }
    static 
    func /= (lhs:inout Vector2<Scalar>, rhs:Scalar)
    {
        lhs.storage /= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 312)
    
    func addingProduct(_ lhs:Vector2<Scalar>, _ rhs:Vector2<Scalar>) -> Vector2<Scalar>
    {
        return .init(self.storage.addingProduct(lhs.storage, rhs.storage))
    }
    func addingProduct(_ lhs:Scalar, _ rhs:Vector2<Scalar>) -> Vector2<Scalar>
    {
        return .init(self.storage.addingProduct(lhs, rhs.storage))
    }
    func addingProduct(_ lhs:Vector2<Scalar>, _ rhs:Scalar) -> Vector2<Scalar>
    {
        return .init(self.storage.addingProduct(lhs.storage, rhs))
    }
    mutating 
    func addProduct(_ lhs:Vector2<Scalar>, _ rhs:Vector2<Scalar>)
    {
        self.storage.addProduct(lhs.storage, rhs.storage)
    }
    mutating 
    func addProduct(_ lhs:Scalar, _ rhs:Vector2<Scalar>)
    {
        self.storage.addProduct(lhs, rhs.storage)
    }
    mutating 
    func addProduct(_ lhs:Vector2<Scalar>, _ rhs:Scalar)
    {
        self.storage.addProduct(lhs.storage, rhs)
    }

    func squareRoot() -> Vector2<Scalar>
    {
        return .init(self.storage.squareRoot())
    }

    func rounded(_ rule:FloatingPointRoundingRule) -> Vector2<Scalar>
    {
        return .init(self.storage.rounded(rule))
    }
    mutating 
    func round(_ rule:FloatingPointRoundingRule)
    {
        self.storage.round(rule)
    }
    
    static func lerp(_ a:Vector2<Scalar>, _ b:Vector2<Scalar>, _ t:Scalar) 
        -> Vector2<Scalar> 
    {
        return a.addingProduct(a, -t).addingProduct(b, t)
    } 
    
    
    var sum:Scalar 
    {
        return self.x + self.y
    }
    var volume:Scalar
    {
        return self.x * self.y
    }
    
    static func <> (lhs:Vector2<Scalar>, rhs:Vector2<Scalar>) -> Scalar
    {
        return (lhs * rhs).sum 
    }
    
    var length:Scalar 
    {
        return (self <> self).squareRoot()
    }
    
    mutating 
    func normalize() 
    {
        self /= self.length
    }
    func normalized() -> Vector2<Scalar> 
    {
        return self / self.length
    }

    static func <  (v:Vector2<Scalar>, r:Scalar) -> Bool
    {
        return v <> v <  r 
    }
    static func <= (v:Vector2<Scalar>, r:Scalar) -> Bool
    {
        return v <> v <= r 
    }
    static func ~~ (v:Vector2<Scalar>, r:Scalar) -> Bool
    {
        return v <> v == r 
    }
    static func !~ (v:Vector2<Scalar>, r:Scalar) -> Bool
    {
        return v <> v != r 
    }
    static func >= (v:Vector2<Scalar>, r:Scalar) -> Bool
    {
        return v <> v >= r 
    }
    static func >  (v:Vector2<Scalar>, r:Scalar) -> Bool
    {
        return v <> v >  r 
    }
}

func wrappingAbs<Scalar>(_ v:Vector2<Scalar>) -> Vector2<Scalar> where Scalar:FixedWidthInteger
{
    return .init(v.storage.replacing(with: 0 &- v.storage, where: v.storage .< 0))
}
func         abs<Scalar>(_ v:Vector2<Scalar>) -> Vector2<Scalar> where Scalar:FloatingPoint
{
    return .init(v.storage.replacing(with:     -v.storage, where: v.storage .< 0))
}

extension Vector2:Mathematical where Scalar:Mathematical 
{
    enum Math:MathImplementations 
    {
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 432)
        @inline(__always)
        static 
        func sin(_ v:Vector2<Scalar>) -> Vector2<Scalar>  
        {
            return .init(SIMD2<Scalar>.Math.sin(v.storage))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 432)
        @inline(__always)
        static 
        func cos(_ v:Vector2<Scalar>) -> Vector2<Scalar>  
        {
            return .init(SIMD2<Scalar>.Math.cos(v.storage))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 432)
        @inline(__always)
        static 
        func tan(_ v:Vector2<Scalar>) -> Vector2<Scalar>  
        {
            return .init(SIMD2<Scalar>.Math.tan(v.storage))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 432)
        @inline(__always)
        static 
        func asin(_ v:Vector2<Scalar>) -> Vector2<Scalar>  
        {
            return .init(SIMD2<Scalar>.Math.asin(v.storage))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 432)
        @inline(__always)
        static 
        func acos(_ v:Vector2<Scalar>) -> Vector2<Scalar>  
        {
            return .init(SIMD2<Scalar>.Math.acos(v.storage))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 432)
        @inline(__always)
        static 
        func atan(_ v:Vector2<Scalar>) -> Vector2<Scalar>  
        {
            return .init(SIMD2<Scalar>.Math.atan(v.storage))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 439)
        
        @inline(__always)
        static
        func atan2(y:Vector2<Scalar>, x:Vector2<Scalar>) -> Vector2<Scalar>
        {
            return .init(SIMD2<Scalar>.Math.atan2(y: y.storage, x: x.storage))
        }
    }
}
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 92)
extension SIMD3:Mathematical where Scalar:Mathematical
{
    enum Math:MathImplementations
    {
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 97)
        @inline(__always)
        static 
        func sin(_ v:SIMD3<Scalar>) -> SIMD3<Scalar> 
        {
            return .init(Scalar.Math.sin(v.x), Scalar.Math.sin(v.y), Scalar.Math.sin(v.z))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 97)
        @inline(__always)
        static 
        func cos(_ v:SIMD3<Scalar>) -> SIMD3<Scalar> 
        {
            return .init(Scalar.Math.cos(v.x), Scalar.Math.cos(v.y), Scalar.Math.cos(v.z))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 97)
        @inline(__always)
        static 
        func tan(_ v:SIMD3<Scalar>) -> SIMD3<Scalar> 
        {
            return .init(Scalar.Math.tan(v.x), Scalar.Math.tan(v.y), Scalar.Math.tan(v.z))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 97)
        @inline(__always)
        static 
        func asin(_ v:SIMD3<Scalar>) -> SIMD3<Scalar> 
        {
            return .init(Scalar.Math.asin(v.x), Scalar.Math.asin(v.y), Scalar.Math.asin(v.z))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 97)
        @inline(__always)
        static 
        func acos(_ v:SIMD3<Scalar>) -> SIMD3<Scalar> 
        {
            return .init(Scalar.Math.acos(v.x), Scalar.Math.acos(v.y), Scalar.Math.acos(v.z))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 97)
        @inline(__always)
        static 
        func atan(_ v:SIMD3<Scalar>) -> SIMD3<Scalar> 
        {
            return .init(Scalar.Math.atan(v.x), Scalar.Math.atan(v.y), Scalar.Math.atan(v.z))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 104)
        
        @inline(__always)
        static
        func atan2(y:SIMD3<Scalar>, x:SIMD3<Scalar>) -> SIMD3<Scalar>
        {
            return .init(Scalar.Math.atan2(y: y.x, x: x.x), Scalar.Math.atan2(y: y.y, x: x.y), Scalar.Math.atan2(y: y.z, x: x.z))
        }
    }
}

struct Vector3<Scalar>:Hashable, Codable where Scalar:SIMDScalar 
{
    var storage:SIMD3<Scalar>
    
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 119)
    var x:Scalar 
    {
        get 
        {
            return self.storage.x
        }
        set(x)
        {
            self.storage.x = x
        }
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 119)
    var y:Scalar 
    {
        get 
        {
            return self.storage.y
        }
        set(y)
        {
            self.storage.y = y
        }
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 119)
    var z:Scalar 
    {
        get 
        {
            return self.storage.z
        }
        set(z)
        {
            self.storage.z = z
        }
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 131)
    
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 133)
    var xy:Vector2<Scalar> 
    {
        return .init(self.x, self.y)
    }
    
    static 
    func extend(_ body:Vector2<Scalar>, _ tail:Scalar) 
        -> Vector3<Scalar> 
    {
        return .init(body.x, body.y, tail)
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 145)
    
    subscript(index:Int) -> Scalar 
    {
        return self.storage[index]
    }
    
    init(repeating repeatedValue:Scalar)
    {
        self.init(.init(repeatedValue, repeatedValue, repeatedValue))
    }
    
    init(_ x:Scalar, _ y:Scalar, _ z:Scalar)
    {
        self.init(.init(x, y, z))
    }
    
    init(_ storage:SIMD3<Scalar>) 
    {
        self.storage = storage 
    }
    
    func map<Result>(_ transform:(Scalar) throws -> Result) rethrows -> Vector3<Result>
        where Result:SIMDScalar 
    {
        return .init(try transform(self.x), try transform(self.y), try transform(self.z))
    }
}

extension Vector3 where Scalar:BinaryInteger 
{
    static 
    func cast<T>(_ v:Vector3<T>) -> Vector3<Scalar> where T:BinaryFloatingPoint 
    {
        return v.map(Scalar.init(_:))
    }
    static 
    func cast<T>(_ v:Vector3<T>) -> Vector3<Scalar> where T:BinaryInteger 
    {
        return v.map(Scalar.init(_:))
    }
}
extension Vector3 where Scalar:FloatingPoint 
{
    static 
    func cast<Source>(_ v:Vector3<Source>) -> Vector3<Scalar> where Source:BinaryInteger 
    {
        return v.map(Scalar.init(_:))
    }
}
extension Vector3 where Scalar:BinaryFloatingPoint 
{
    static 
    func cast<Source>(_ v:Vector3<Source>) -> Vector3<Scalar> where Source:BinaryFloatingPoint 
    {
        return v.map(Scalar.init(_:))
    }
}

extension Vector3 where Scalar:FixedWidthInteger
{
    static 
    var zero:Vector3<Scalar> 
    {
        return .init(.zero) 
    }
    
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 212)
    static 
    func &<< (lhs:Vector3<Scalar>, rhs:Vector3<Scalar>) 
        -> Vector3<Scalar>
    {
        return .init(lhs.storage &<< rhs.storage)
    }
    static 
    func &<< (lhs:Vector3<Scalar>, rhs:Scalar) 
        -> Vector3<Scalar>
    {
        return .init(lhs.storage &<< rhs)
    }
    static 
    func &<< (lhs:Scalar, rhs:Vector3<Scalar>) 
        -> Vector3<Scalar>
    {
        return .init(lhs &<< rhs.storage)
    }
    
    static 
    func &<<= (lhs:inout Vector3<Scalar>, rhs:Vector3<Scalar>)
    {
        lhs.storage &<<= rhs.storage
    }
    static 
    func &<<= (lhs:inout Vector3<Scalar>, rhs:Scalar)
    {
        lhs.storage &<<= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 212)
    static 
    func &>> (lhs:Vector3<Scalar>, rhs:Vector3<Scalar>) 
        -> Vector3<Scalar>
    {
        return .init(lhs.storage &>> rhs.storage)
    }
    static 
    func &>> (lhs:Vector3<Scalar>, rhs:Scalar) 
        -> Vector3<Scalar>
    {
        return .init(lhs.storage &>> rhs)
    }
    static 
    func &>> (lhs:Scalar, rhs:Vector3<Scalar>) 
        -> Vector3<Scalar>
    {
        return .init(lhs &>> rhs.storage)
    }
    
    static 
    func &>>= (lhs:inout Vector3<Scalar>, rhs:Vector3<Scalar>)
    {
        lhs.storage &>>= rhs.storage
    }
    static 
    func &>>= (lhs:inout Vector3<Scalar>, rhs:Scalar)
    {
        lhs.storage &>>= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 212)
    static 
    func &+ (lhs:Vector3<Scalar>, rhs:Vector3<Scalar>) 
        -> Vector3<Scalar>
    {
        return .init(lhs.storage &+ rhs.storage)
    }
    static 
    func &+ (lhs:Vector3<Scalar>, rhs:Scalar) 
        -> Vector3<Scalar>
    {
        return .init(lhs.storage &+ rhs)
    }
    static 
    func &+ (lhs:Scalar, rhs:Vector3<Scalar>) 
        -> Vector3<Scalar>
    {
        return .init(lhs &+ rhs.storage)
    }
    
    static 
    func &+= (lhs:inout Vector3<Scalar>, rhs:Vector3<Scalar>)
    {
        lhs.storage &+= rhs.storage
    }
    static 
    func &+= (lhs:inout Vector3<Scalar>, rhs:Scalar)
    {
        lhs.storage &+= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 212)
    static 
    func &- (lhs:Vector3<Scalar>, rhs:Vector3<Scalar>) 
        -> Vector3<Scalar>
    {
        return .init(lhs.storage &- rhs.storage)
    }
    static 
    func &- (lhs:Vector3<Scalar>, rhs:Scalar) 
        -> Vector3<Scalar>
    {
        return .init(lhs.storage &- rhs)
    }
    static 
    func &- (lhs:Scalar, rhs:Vector3<Scalar>) 
        -> Vector3<Scalar>
    {
        return .init(lhs &- rhs.storage)
    }
    
    static 
    func &-= (lhs:inout Vector3<Scalar>, rhs:Vector3<Scalar>)
    {
        lhs.storage &-= rhs.storage
    }
    static 
    func &-= (lhs:inout Vector3<Scalar>, rhs:Scalar)
    {
        lhs.storage &-= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 212)
    static 
    func &* (lhs:Vector3<Scalar>, rhs:Vector3<Scalar>) 
        -> Vector3<Scalar>
    {
        return .init(lhs.storage &* rhs.storage)
    }
    static 
    func &* (lhs:Vector3<Scalar>, rhs:Scalar) 
        -> Vector3<Scalar>
    {
        return .init(lhs.storage &* rhs)
    }
    static 
    func &* (lhs:Scalar, rhs:Vector3<Scalar>) 
        -> Vector3<Scalar>
    {
        return .init(lhs &* rhs.storage)
    }
    
    static 
    func &*= (lhs:inout Vector3<Scalar>, rhs:Vector3<Scalar>)
    {
        lhs.storage &*= rhs.storage
    }
    static 
    func &*= (lhs:inout Vector3<Scalar>, rhs:Scalar)
    {
        lhs.storage &*= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 212)
    static 
    func / (lhs:Vector3<Scalar>, rhs:Vector3<Scalar>) 
        -> Vector3<Scalar>
    {
        return .init(lhs.storage / rhs.storage)
    }
    static 
    func / (lhs:Vector3<Scalar>, rhs:Scalar) 
        -> Vector3<Scalar>
    {
        return .init(lhs.storage / rhs)
    }
    static 
    func / (lhs:Scalar, rhs:Vector3<Scalar>) 
        -> Vector3<Scalar>
    {
        return .init(lhs / rhs.storage)
    }
    
    static 
    func /= (lhs:inout Vector3<Scalar>, rhs:Vector3<Scalar>)
    {
        lhs.storage /= rhs.storage
    }
    static 
    func /= (lhs:inout Vector3<Scalar>, rhs:Scalar)
    {
        lhs.storage /= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 212)
    static 
    func % (lhs:Vector3<Scalar>, rhs:Vector3<Scalar>) 
        -> Vector3<Scalar>
    {
        return .init(lhs.storage % rhs.storage)
    }
    static 
    func % (lhs:Vector3<Scalar>, rhs:Scalar) 
        -> Vector3<Scalar>
    {
        return .init(lhs.storage % rhs)
    }
    static 
    func % (lhs:Scalar, rhs:Vector3<Scalar>) 
        -> Vector3<Scalar>
    {
        return .init(lhs % rhs.storage)
    }
    
    static 
    func %= (lhs:inout Vector3<Scalar>, rhs:Vector3<Scalar>)
    {
        lhs.storage %= rhs.storage
    }
    static 
    func %= (lhs:inout Vector3<Scalar>, rhs:Scalar)
    {
        lhs.storage %= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 242)
    
    func roundedUp(exponent:Int) -> Vector3<Scalar>
    { 
        let mask:Scalar                 = .max &<< exponent 
        let truncated:SIMD3<Scalar>  = self.storage & mask
        let carry:SIMD3<Scalar> = 
            SIMD3<Scalar>.zero.replacing(with: 1 &<< exponent, where: self.storage & ~mask .!= 0)
        return .init(truncated &+ carry)
    } 
    
    var wrappingSum:Scalar 
    {
        return self.x &+ self.y &+ self.z
    }
    var wrappingVolume:Scalar
    {
        return self.x &* self.y &* self.z
    }
    
    static func &<> (lhs:Vector3<Scalar>, rhs:Vector3<Scalar>) -> Scalar
    {
        return (lhs &* rhs).wrappingSum
    }
}

extension Vector3 where Scalar:FloatingPoint 
{
    static 
    var zero:Vector3<Scalar> 
    {
        return .init(.zero) 
    }
    
    prefix static 
    func - (operand:Vector3<Scalar>) -> Vector3<Scalar>
    {
        return .init(-operand.storage)
    }
    
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 282)
    static 
    func + (lhs:Vector3<Scalar>, rhs:Vector3<Scalar>) 
        -> Vector3<Scalar>
    {
        return .init(lhs.storage + rhs.storage)
    }
    static 
    func + (lhs:Vector3<Scalar>, rhs:Scalar) 
        -> Vector3<Scalar>
    {
        return .init(lhs.storage + rhs)
    }
    static 
    func + (lhs:Scalar, rhs:Vector3<Scalar>) 
        -> Vector3<Scalar>
    {
        return .init(lhs + rhs.storage)
    }
    
    static 
    func += (lhs:inout Vector3<Scalar>, rhs:Vector3<Scalar>)
    {
        lhs.storage += rhs.storage
    }
    static 
    func += (lhs:inout Vector3<Scalar>, rhs:Scalar)
    {
        lhs.storage += rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 282)
    static 
    func - (lhs:Vector3<Scalar>, rhs:Vector3<Scalar>) 
        -> Vector3<Scalar>
    {
        return .init(lhs.storage - rhs.storage)
    }
    static 
    func - (lhs:Vector3<Scalar>, rhs:Scalar) 
        -> Vector3<Scalar>
    {
        return .init(lhs.storage - rhs)
    }
    static 
    func - (lhs:Scalar, rhs:Vector3<Scalar>) 
        -> Vector3<Scalar>
    {
        return .init(lhs - rhs.storage)
    }
    
    static 
    func -= (lhs:inout Vector3<Scalar>, rhs:Vector3<Scalar>)
    {
        lhs.storage -= rhs.storage
    }
    static 
    func -= (lhs:inout Vector3<Scalar>, rhs:Scalar)
    {
        lhs.storage -= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 282)
    static 
    func * (lhs:Vector3<Scalar>, rhs:Vector3<Scalar>) 
        -> Vector3<Scalar>
    {
        return .init(lhs.storage * rhs.storage)
    }
    static 
    func * (lhs:Vector3<Scalar>, rhs:Scalar) 
        -> Vector3<Scalar>
    {
        return .init(lhs.storage * rhs)
    }
    static 
    func * (lhs:Scalar, rhs:Vector3<Scalar>) 
        -> Vector3<Scalar>
    {
        return .init(lhs * rhs.storage)
    }
    
    static 
    func *= (lhs:inout Vector3<Scalar>, rhs:Vector3<Scalar>)
    {
        lhs.storage *= rhs.storage
    }
    static 
    func *= (lhs:inout Vector3<Scalar>, rhs:Scalar)
    {
        lhs.storage *= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 282)
    static 
    func / (lhs:Vector3<Scalar>, rhs:Vector3<Scalar>) 
        -> Vector3<Scalar>
    {
        return .init(lhs.storage / rhs.storage)
    }
    static 
    func / (lhs:Vector3<Scalar>, rhs:Scalar) 
        -> Vector3<Scalar>
    {
        return .init(lhs.storage / rhs)
    }
    static 
    func / (lhs:Scalar, rhs:Vector3<Scalar>) 
        -> Vector3<Scalar>
    {
        return .init(lhs / rhs.storage)
    }
    
    static 
    func /= (lhs:inout Vector3<Scalar>, rhs:Vector3<Scalar>)
    {
        lhs.storage /= rhs.storage
    }
    static 
    func /= (lhs:inout Vector3<Scalar>, rhs:Scalar)
    {
        lhs.storage /= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 312)
    
    func addingProduct(_ lhs:Vector3<Scalar>, _ rhs:Vector3<Scalar>) -> Vector3<Scalar>
    {
        return .init(self.storage.addingProduct(lhs.storage, rhs.storage))
    }
    func addingProduct(_ lhs:Scalar, _ rhs:Vector3<Scalar>) -> Vector3<Scalar>
    {
        return .init(self.storage.addingProduct(lhs, rhs.storage))
    }
    func addingProduct(_ lhs:Vector3<Scalar>, _ rhs:Scalar) -> Vector3<Scalar>
    {
        return .init(self.storage.addingProduct(lhs.storage, rhs))
    }
    mutating 
    func addProduct(_ lhs:Vector3<Scalar>, _ rhs:Vector3<Scalar>)
    {
        self.storage.addProduct(lhs.storage, rhs.storage)
    }
    mutating 
    func addProduct(_ lhs:Scalar, _ rhs:Vector3<Scalar>)
    {
        self.storage.addProduct(lhs, rhs.storage)
    }
    mutating 
    func addProduct(_ lhs:Vector3<Scalar>, _ rhs:Scalar)
    {
        self.storage.addProduct(lhs.storage, rhs)
    }

    func squareRoot() -> Vector3<Scalar>
    {
        return .init(self.storage.squareRoot())
    }

    func rounded(_ rule:FloatingPointRoundingRule) -> Vector3<Scalar>
    {
        return .init(self.storage.rounded(rule))
    }
    mutating 
    func round(_ rule:FloatingPointRoundingRule)
    {
        self.storage.round(rule)
    }
    
    static func lerp(_ a:Vector3<Scalar>, _ b:Vector3<Scalar>, _ t:Scalar) 
        -> Vector3<Scalar> 
    {
        return a.addingProduct(a, -t).addingProduct(b, t)
    } 
    
    
    var sum:Scalar 
    {
        return self.x + self.y + self.z
    }
    var volume:Scalar
    {
        return self.x * self.y * self.z
    }
    
    static func <> (lhs:Vector3<Scalar>, rhs:Vector3<Scalar>) -> Scalar
    {
        return (lhs * rhs).sum 
    }
    
    var length:Scalar 
    {
        return (self <> self).squareRoot()
    }
    
    mutating 
    func normalize() 
    {
        self /= self.length
    }
    func normalized() -> Vector3<Scalar> 
    {
        return self / self.length
    }

    static func <  (v:Vector3<Scalar>, r:Scalar) -> Bool
    {
        return v <> v <  r 
    }
    static func <= (v:Vector3<Scalar>, r:Scalar) -> Bool
    {
        return v <> v <= r 
    }
    static func ~~ (v:Vector3<Scalar>, r:Scalar) -> Bool
    {
        return v <> v == r 
    }
    static func !~ (v:Vector3<Scalar>, r:Scalar) -> Bool
    {
        return v <> v != r 
    }
    static func >= (v:Vector3<Scalar>, r:Scalar) -> Bool
    {
        return v <> v >= r 
    }
    static func >  (v:Vector3<Scalar>, r:Scalar) -> Bool
    {
        return v <> v >  r 
    }
}

func wrappingAbs<Scalar>(_ v:Vector3<Scalar>) -> Vector3<Scalar> where Scalar:FixedWidthInteger
{
    return .init(v.storage.replacing(with: 0 &- v.storage, where: v.storage .< 0))
}
func         abs<Scalar>(_ v:Vector3<Scalar>) -> Vector3<Scalar> where Scalar:FloatingPoint
{
    return .init(v.storage.replacing(with:     -v.storage, where: v.storage .< 0))
}

extension Vector3:Mathematical where Scalar:Mathematical 
{
    enum Math:MathImplementations 
    {
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 432)
        @inline(__always)
        static 
        func sin(_ v:Vector3<Scalar>) -> Vector3<Scalar>  
        {
            return .init(SIMD3<Scalar>.Math.sin(v.storage))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 432)
        @inline(__always)
        static 
        func cos(_ v:Vector3<Scalar>) -> Vector3<Scalar>  
        {
            return .init(SIMD3<Scalar>.Math.cos(v.storage))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 432)
        @inline(__always)
        static 
        func tan(_ v:Vector3<Scalar>) -> Vector3<Scalar>  
        {
            return .init(SIMD3<Scalar>.Math.tan(v.storage))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 432)
        @inline(__always)
        static 
        func asin(_ v:Vector3<Scalar>) -> Vector3<Scalar>  
        {
            return .init(SIMD3<Scalar>.Math.asin(v.storage))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 432)
        @inline(__always)
        static 
        func acos(_ v:Vector3<Scalar>) -> Vector3<Scalar>  
        {
            return .init(SIMD3<Scalar>.Math.acos(v.storage))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 432)
        @inline(__always)
        static 
        func atan(_ v:Vector3<Scalar>) -> Vector3<Scalar>  
        {
            return .init(SIMD3<Scalar>.Math.atan(v.storage))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 439)
        
        @inline(__always)
        static
        func atan2(y:Vector3<Scalar>, x:Vector3<Scalar>) -> Vector3<Scalar>
        {
            return .init(SIMD3<Scalar>.Math.atan2(y: y.storage, x: x.storage))
        }
    }
}
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 92)
extension SIMD4:Mathematical where Scalar:Mathematical
{
    enum Math:MathImplementations
    {
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 97)
        @inline(__always)
        static 
        func sin(_ v:SIMD4<Scalar>) -> SIMD4<Scalar> 
        {
            return .init(Scalar.Math.sin(v.x), Scalar.Math.sin(v.y), Scalar.Math.sin(v.z), Scalar.Math.sin(v.w))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 97)
        @inline(__always)
        static 
        func cos(_ v:SIMD4<Scalar>) -> SIMD4<Scalar> 
        {
            return .init(Scalar.Math.cos(v.x), Scalar.Math.cos(v.y), Scalar.Math.cos(v.z), Scalar.Math.cos(v.w))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 97)
        @inline(__always)
        static 
        func tan(_ v:SIMD4<Scalar>) -> SIMD4<Scalar> 
        {
            return .init(Scalar.Math.tan(v.x), Scalar.Math.tan(v.y), Scalar.Math.tan(v.z), Scalar.Math.tan(v.w))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 97)
        @inline(__always)
        static 
        func asin(_ v:SIMD4<Scalar>) -> SIMD4<Scalar> 
        {
            return .init(Scalar.Math.asin(v.x), Scalar.Math.asin(v.y), Scalar.Math.asin(v.z), Scalar.Math.asin(v.w))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 97)
        @inline(__always)
        static 
        func acos(_ v:SIMD4<Scalar>) -> SIMD4<Scalar> 
        {
            return .init(Scalar.Math.acos(v.x), Scalar.Math.acos(v.y), Scalar.Math.acos(v.z), Scalar.Math.acos(v.w))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 97)
        @inline(__always)
        static 
        func atan(_ v:SIMD4<Scalar>) -> SIMD4<Scalar> 
        {
            return .init(Scalar.Math.atan(v.x), Scalar.Math.atan(v.y), Scalar.Math.atan(v.z), Scalar.Math.atan(v.w))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 104)
        
        @inline(__always)
        static
        func atan2(y:SIMD4<Scalar>, x:SIMD4<Scalar>) -> SIMD4<Scalar>
        {
            return .init(Scalar.Math.atan2(y: y.x, x: x.x), Scalar.Math.atan2(y: y.y, x: x.y), Scalar.Math.atan2(y: y.z, x: x.z), Scalar.Math.atan2(y: y.w, x: x.w))
        }
    }
}

struct Vector4<Scalar>:Hashable, Codable where Scalar:SIMDScalar 
{
    var storage:SIMD4<Scalar>
    
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 119)
    var x:Scalar 
    {
        get 
        {
            return self.storage.x
        }
        set(x)
        {
            self.storage.x = x
        }
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 119)
    var y:Scalar 
    {
        get 
        {
            return self.storage.y
        }
        set(y)
        {
            self.storage.y = y
        }
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 119)
    var z:Scalar 
    {
        get 
        {
            return self.storage.z
        }
        set(z)
        {
            self.storage.z = z
        }
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 119)
    var w:Scalar 
    {
        get 
        {
            return self.storage.w
        }
        set(w)
        {
            self.storage.w = w
        }
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 131)
    
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 133)
    var xyz:Vector3<Scalar> 
    {
        return .init(self.x, self.y, self.z)
    }
    
    static 
    func extend(_ body:Vector3<Scalar>, _ tail:Scalar) 
        -> Vector4<Scalar> 
    {
        return .init(body.x, body.y, body.z, tail)
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 145)
    
    subscript(index:Int) -> Scalar 
    {
        return self.storage[index]
    }
    
    init(repeating repeatedValue:Scalar)
    {
        self.init(.init(repeatedValue, repeatedValue, repeatedValue, repeatedValue))
    }
    
    init(_ x:Scalar, _ y:Scalar, _ z:Scalar, _ w:Scalar)
    {
        self.init(.init(x, y, z, w))
    }
    
    init(_ storage:SIMD4<Scalar>) 
    {
        self.storage = storage 
    }
    
    func map<Result>(_ transform:(Scalar) throws -> Result) rethrows -> Vector4<Result>
        where Result:SIMDScalar 
    {
        return .init(try transform(self.x), try transform(self.y), try transform(self.z), try transform(self.w))
    }
}

extension Vector4 where Scalar:BinaryInteger 
{
    static 
    func cast<T>(_ v:Vector4<T>) -> Vector4<Scalar> where T:BinaryFloatingPoint 
    {
        return v.map(Scalar.init(_:))
    }
    static 
    func cast<T>(_ v:Vector4<T>) -> Vector4<Scalar> where T:BinaryInteger 
    {
        return v.map(Scalar.init(_:))
    }
}
extension Vector4 where Scalar:FloatingPoint 
{
    static 
    func cast<Source>(_ v:Vector4<Source>) -> Vector4<Scalar> where Source:BinaryInteger 
    {
        return v.map(Scalar.init(_:))
    }
}
extension Vector4 where Scalar:BinaryFloatingPoint 
{
    static 
    func cast<Source>(_ v:Vector4<Source>) -> Vector4<Scalar> where Source:BinaryFloatingPoint 
    {
        return v.map(Scalar.init(_:))
    }
}

extension Vector4 where Scalar:FixedWidthInteger
{
    static 
    var zero:Vector4<Scalar> 
    {
        return .init(.zero) 
    }
    
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 212)
    static 
    func &<< (lhs:Vector4<Scalar>, rhs:Vector4<Scalar>) 
        -> Vector4<Scalar>
    {
        return .init(lhs.storage &<< rhs.storage)
    }
    static 
    func &<< (lhs:Vector4<Scalar>, rhs:Scalar) 
        -> Vector4<Scalar>
    {
        return .init(lhs.storage &<< rhs)
    }
    static 
    func &<< (lhs:Scalar, rhs:Vector4<Scalar>) 
        -> Vector4<Scalar>
    {
        return .init(lhs &<< rhs.storage)
    }
    
    static 
    func &<<= (lhs:inout Vector4<Scalar>, rhs:Vector4<Scalar>)
    {
        lhs.storage &<<= rhs.storage
    }
    static 
    func &<<= (lhs:inout Vector4<Scalar>, rhs:Scalar)
    {
        lhs.storage &<<= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 212)
    static 
    func &>> (lhs:Vector4<Scalar>, rhs:Vector4<Scalar>) 
        -> Vector4<Scalar>
    {
        return .init(lhs.storage &>> rhs.storage)
    }
    static 
    func &>> (lhs:Vector4<Scalar>, rhs:Scalar) 
        -> Vector4<Scalar>
    {
        return .init(lhs.storage &>> rhs)
    }
    static 
    func &>> (lhs:Scalar, rhs:Vector4<Scalar>) 
        -> Vector4<Scalar>
    {
        return .init(lhs &>> rhs.storage)
    }
    
    static 
    func &>>= (lhs:inout Vector4<Scalar>, rhs:Vector4<Scalar>)
    {
        lhs.storage &>>= rhs.storage
    }
    static 
    func &>>= (lhs:inout Vector4<Scalar>, rhs:Scalar)
    {
        lhs.storage &>>= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 212)
    static 
    func &+ (lhs:Vector4<Scalar>, rhs:Vector4<Scalar>) 
        -> Vector4<Scalar>
    {
        return .init(lhs.storage &+ rhs.storage)
    }
    static 
    func &+ (lhs:Vector4<Scalar>, rhs:Scalar) 
        -> Vector4<Scalar>
    {
        return .init(lhs.storage &+ rhs)
    }
    static 
    func &+ (lhs:Scalar, rhs:Vector4<Scalar>) 
        -> Vector4<Scalar>
    {
        return .init(lhs &+ rhs.storage)
    }
    
    static 
    func &+= (lhs:inout Vector4<Scalar>, rhs:Vector4<Scalar>)
    {
        lhs.storage &+= rhs.storage
    }
    static 
    func &+= (lhs:inout Vector4<Scalar>, rhs:Scalar)
    {
        lhs.storage &+= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 212)
    static 
    func &- (lhs:Vector4<Scalar>, rhs:Vector4<Scalar>) 
        -> Vector4<Scalar>
    {
        return .init(lhs.storage &- rhs.storage)
    }
    static 
    func &- (lhs:Vector4<Scalar>, rhs:Scalar) 
        -> Vector4<Scalar>
    {
        return .init(lhs.storage &- rhs)
    }
    static 
    func &- (lhs:Scalar, rhs:Vector4<Scalar>) 
        -> Vector4<Scalar>
    {
        return .init(lhs &- rhs.storage)
    }
    
    static 
    func &-= (lhs:inout Vector4<Scalar>, rhs:Vector4<Scalar>)
    {
        lhs.storage &-= rhs.storage
    }
    static 
    func &-= (lhs:inout Vector4<Scalar>, rhs:Scalar)
    {
        lhs.storage &-= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 212)
    static 
    func &* (lhs:Vector4<Scalar>, rhs:Vector4<Scalar>) 
        -> Vector4<Scalar>
    {
        return .init(lhs.storage &* rhs.storage)
    }
    static 
    func &* (lhs:Vector4<Scalar>, rhs:Scalar) 
        -> Vector4<Scalar>
    {
        return .init(lhs.storage &* rhs)
    }
    static 
    func &* (lhs:Scalar, rhs:Vector4<Scalar>) 
        -> Vector4<Scalar>
    {
        return .init(lhs &* rhs.storage)
    }
    
    static 
    func &*= (lhs:inout Vector4<Scalar>, rhs:Vector4<Scalar>)
    {
        lhs.storage &*= rhs.storage
    }
    static 
    func &*= (lhs:inout Vector4<Scalar>, rhs:Scalar)
    {
        lhs.storage &*= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 212)
    static 
    func / (lhs:Vector4<Scalar>, rhs:Vector4<Scalar>) 
        -> Vector4<Scalar>
    {
        return .init(lhs.storage / rhs.storage)
    }
    static 
    func / (lhs:Vector4<Scalar>, rhs:Scalar) 
        -> Vector4<Scalar>
    {
        return .init(lhs.storage / rhs)
    }
    static 
    func / (lhs:Scalar, rhs:Vector4<Scalar>) 
        -> Vector4<Scalar>
    {
        return .init(lhs / rhs.storage)
    }
    
    static 
    func /= (lhs:inout Vector4<Scalar>, rhs:Vector4<Scalar>)
    {
        lhs.storage /= rhs.storage
    }
    static 
    func /= (lhs:inout Vector4<Scalar>, rhs:Scalar)
    {
        lhs.storage /= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 212)
    static 
    func % (lhs:Vector4<Scalar>, rhs:Vector4<Scalar>) 
        -> Vector4<Scalar>
    {
        return .init(lhs.storage % rhs.storage)
    }
    static 
    func % (lhs:Vector4<Scalar>, rhs:Scalar) 
        -> Vector4<Scalar>
    {
        return .init(lhs.storage % rhs)
    }
    static 
    func % (lhs:Scalar, rhs:Vector4<Scalar>) 
        -> Vector4<Scalar>
    {
        return .init(lhs % rhs.storage)
    }
    
    static 
    func %= (lhs:inout Vector4<Scalar>, rhs:Vector4<Scalar>)
    {
        lhs.storage %= rhs.storage
    }
    static 
    func %= (lhs:inout Vector4<Scalar>, rhs:Scalar)
    {
        lhs.storage %= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 242)
    
    func roundedUp(exponent:Int) -> Vector4<Scalar>
    { 
        let mask:Scalar                 = .max &<< exponent 
        let truncated:SIMD4<Scalar>  = self.storage & mask
        let carry:SIMD4<Scalar> = 
            SIMD4<Scalar>.zero.replacing(with: 1 &<< exponent, where: self.storage & ~mask .!= 0)
        return .init(truncated &+ carry)
    } 
    
    var wrappingSum:Scalar 
    {
        return self.x &+ self.y &+ self.z &+ self.w
    }
    var wrappingVolume:Scalar
    {
        return self.x &* self.y &* self.z &* self.w
    }
    
    static func &<> (lhs:Vector4<Scalar>, rhs:Vector4<Scalar>) -> Scalar
    {
        return (lhs &* rhs).wrappingSum
    }
}

extension Vector4 where Scalar:FloatingPoint 
{
    static 
    var zero:Vector4<Scalar> 
    {
        return .init(.zero) 
    }
    
    prefix static 
    func - (operand:Vector4<Scalar>) -> Vector4<Scalar>
    {
        return .init(-operand.storage)
    }
    
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 282)
    static 
    func + (lhs:Vector4<Scalar>, rhs:Vector4<Scalar>) 
        -> Vector4<Scalar>
    {
        return .init(lhs.storage + rhs.storage)
    }
    static 
    func + (lhs:Vector4<Scalar>, rhs:Scalar) 
        -> Vector4<Scalar>
    {
        return .init(lhs.storage + rhs)
    }
    static 
    func + (lhs:Scalar, rhs:Vector4<Scalar>) 
        -> Vector4<Scalar>
    {
        return .init(lhs + rhs.storage)
    }
    
    static 
    func += (lhs:inout Vector4<Scalar>, rhs:Vector4<Scalar>)
    {
        lhs.storage += rhs.storage
    }
    static 
    func += (lhs:inout Vector4<Scalar>, rhs:Scalar)
    {
        lhs.storage += rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 282)
    static 
    func - (lhs:Vector4<Scalar>, rhs:Vector4<Scalar>) 
        -> Vector4<Scalar>
    {
        return .init(lhs.storage - rhs.storage)
    }
    static 
    func - (lhs:Vector4<Scalar>, rhs:Scalar) 
        -> Vector4<Scalar>
    {
        return .init(lhs.storage - rhs)
    }
    static 
    func - (lhs:Scalar, rhs:Vector4<Scalar>) 
        -> Vector4<Scalar>
    {
        return .init(lhs - rhs.storage)
    }
    
    static 
    func -= (lhs:inout Vector4<Scalar>, rhs:Vector4<Scalar>)
    {
        lhs.storage -= rhs.storage
    }
    static 
    func -= (lhs:inout Vector4<Scalar>, rhs:Scalar)
    {
        lhs.storage -= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 282)
    static 
    func * (lhs:Vector4<Scalar>, rhs:Vector4<Scalar>) 
        -> Vector4<Scalar>
    {
        return .init(lhs.storage * rhs.storage)
    }
    static 
    func * (lhs:Vector4<Scalar>, rhs:Scalar) 
        -> Vector4<Scalar>
    {
        return .init(lhs.storage * rhs)
    }
    static 
    func * (lhs:Scalar, rhs:Vector4<Scalar>) 
        -> Vector4<Scalar>
    {
        return .init(lhs * rhs.storage)
    }
    
    static 
    func *= (lhs:inout Vector4<Scalar>, rhs:Vector4<Scalar>)
    {
        lhs.storage *= rhs.storage
    }
    static 
    func *= (lhs:inout Vector4<Scalar>, rhs:Scalar)
    {
        lhs.storage *= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 282)
    static 
    func / (lhs:Vector4<Scalar>, rhs:Vector4<Scalar>) 
        -> Vector4<Scalar>
    {
        return .init(lhs.storage / rhs.storage)
    }
    static 
    func / (lhs:Vector4<Scalar>, rhs:Scalar) 
        -> Vector4<Scalar>
    {
        return .init(lhs.storage / rhs)
    }
    static 
    func / (lhs:Scalar, rhs:Vector4<Scalar>) 
        -> Vector4<Scalar>
    {
        return .init(lhs / rhs.storage)
    }
    
    static 
    func /= (lhs:inout Vector4<Scalar>, rhs:Vector4<Scalar>)
    {
        lhs.storage /= rhs.storage
    }
    static 
    func /= (lhs:inout Vector4<Scalar>, rhs:Scalar)
    {
        lhs.storage /= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 312)
    
    func addingProduct(_ lhs:Vector4<Scalar>, _ rhs:Vector4<Scalar>) -> Vector4<Scalar>
    {
        return .init(self.storage.addingProduct(lhs.storage, rhs.storage))
    }
    func addingProduct(_ lhs:Scalar, _ rhs:Vector4<Scalar>) -> Vector4<Scalar>
    {
        return .init(self.storage.addingProduct(lhs, rhs.storage))
    }
    func addingProduct(_ lhs:Vector4<Scalar>, _ rhs:Scalar) -> Vector4<Scalar>
    {
        return .init(self.storage.addingProduct(lhs.storage, rhs))
    }
    mutating 
    func addProduct(_ lhs:Vector4<Scalar>, _ rhs:Vector4<Scalar>)
    {
        self.storage.addProduct(lhs.storage, rhs.storage)
    }
    mutating 
    func addProduct(_ lhs:Scalar, _ rhs:Vector4<Scalar>)
    {
        self.storage.addProduct(lhs, rhs.storage)
    }
    mutating 
    func addProduct(_ lhs:Vector4<Scalar>, _ rhs:Scalar)
    {
        self.storage.addProduct(lhs.storage, rhs)
    }

    func squareRoot() -> Vector4<Scalar>
    {
        return .init(self.storage.squareRoot())
    }

    func rounded(_ rule:FloatingPointRoundingRule) -> Vector4<Scalar>
    {
        return .init(self.storage.rounded(rule))
    }
    mutating 
    func round(_ rule:FloatingPointRoundingRule)
    {
        self.storage.round(rule)
    }
    
    static func lerp(_ a:Vector4<Scalar>, _ b:Vector4<Scalar>, _ t:Scalar) 
        -> Vector4<Scalar> 
    {
        return a.addingProduct(a, -t).addingProduct(b, t)
    } 
    
    
    var sum:Scalar 
    {
        return self.x + self.y + self.z + self.w
    }
    var volume:Scalar
    {
        return self.x * self.y * self.z * self.w
    }
    
    static func <> (lhs:Vector4<Scalar>, rhs:Vector4<Scalar>) -> Scalar
    {
        return (lhs * rhs).sum 
    }
    
    var length:Scalar 
    {
        return (self <> self).squareRoot()
    }
    
    mutating 
    func normalize() 
    {
        self /= self.length
    }
    func normalized() -> Vector4<Scalar> 
    {
        return self / self.length
    }

    static func <  (v:Vector4<Scalar>, r:Scalar) -> Bool
    {
        return v <> v <  r 
    }
    static func <= (v:Vector4<Scalar>, r:Scalar) -> Bool
    {
        return v <> v <= r 
    }
    static func ~~ (v:Vector4<Scalar>, r:Scalar) -> Bool
    {
        return v <> v == r 
    }
    static func !~ (v:Vector4<Scalar>, r:Scalar) -> Bool
    {
        return v <> v != r 
    }
    static func >= (v:Vector4<Scalar>, r:Scalar) -> Bool
    {
        return v <> v >= r 
    }
    static func >  (v:Vector4<Scalar>, r:Scalar) -> Bool
    {
        return v <> v >  r 
    }
}

func wrappingAbs<Scalar>(_ v:Vector4<Scalar>) -> Vector4<Scalar> where Scalar:FixedWidthInteger
{
    return .init(v.storage.replacing(with: 0 &- v.storage, where: v.storage .< 0))
}
func         abs<Scalar>(_ v:Vector4<Scalar>) -> Vector4<Scalar> where Scalar:FloatingPoint
{
    return .init(v.storage.replacing(with:     -v.storage, where: v.storage .< 0))
}

extension Vector4:Mathematical where Scalar:Mathematical 
{
    enum Math:MathImplementations 
    {
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 432)
        @inline(__always)
        static 
        func sin(_ v:Vector4<Scalar>) -> Vector4<Scalar>  
        {
            return .init(SIMD4<Scalar>.Math.sin(v.storage))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 432)
        @inline(__always)
        static 
        func cos(_ v:Vector4<Scalar>) -> Vector4<Scalar>  
        {
            return .init(SIMD4<Scalar>.Math.cos(v.storage))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 432)
        @inline(__always)
        static 
        func tan(_ v:Vector4<Scalar>) -> Vector4<Scalar>  
        {
            return .init(SIMD4<Scalar>.Math.tan(v.storage))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 432)
        @inline(__always)
        static 
        func asin(_ v:Vector4<Scalar>) -> Vector4<Scalar>  
        {
            return .init(SIMD4<Scalar>.Math.asin(v.storage))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 432)
        @inline(__always)
        static 
        func acos(_ v:Vector4<Scalar>) -> Vector4<Scalar>  
        {
            return .init(SIMD4<Scalar>.Math.acos(v.storage))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 432)
        @inline(__always)
        static 
        func atan(_ v:Vector4<Scalar>) -> Vector4<Scalar>  
        {
            return .init(SIMD4<Scalar>.Math.atan(v.storage))
        }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 439)
        
        @inline(__always)
        static
        func atan2(y:Vector4<Scalar>, x:Vector4<Scalar>) -> Vector4<Scalar>
        {
            return .init(SIMD4<Scalar>.Math.atan2(y: y.storage, x: x.storage))
        }
    }
}
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 449)

extension Vector2 where Scalar:FixedWidthInteger 
{
    static 
    func &>< (lhs:Vector2<Scalar>, rhs:Vector2<Scalar>) -> Scalar
    {
        return lhs.x &* rhs.y &- rhs.x &* lhs.y
    }
}
extension Vector2 where Scalar:FloatingPoint 
{
    static 
    func >< (lhs:Vector2<Scalar>, rhs:Vector2<Scalar>) -> Scalar 
    {
        return lhs.x * rhs.y - rhs.x * lhs.y
    }
}
extension Vector3 where Scalar:FixedWidthInteger 
{
    static 
    func &>< (lhs:Vector3<Scalar>, rhs:Vector3<Scalar>) -> Vector3<Scalar> 
    {
        return  .init(lhs.y, lhs.z, lhs.x) &* .init(rhs.z, rhs.x, rhs.y) &- 
                .init(rhs.y, rhs.z, rhs.x) &* .init(lhs.z, lhs.x, lhs.y)
    }
}
extension Vector3 where Scalar:FloatingPoint 
{
    static 
    func >< (lhs:Vector3<Scalar>, rhs:Vector3<Scalar>) -> Vector3<Scalar> 
    {
        return  .init(lhs.y, lhs.z, lhs.x) * .init(rhs.z, rhs.x, rhs.y) - 
                .init(rhs.y, rhs.z, rhs.x) * .init(lhs.z, lhs.x, lhs.y)
    }
}

extension Spherical2 where Scalar:FloatingPoint
{
    init(cartesian:Vector3<Scalar>)
    {
        let colatitude:Scalar = Scalar.Math.acos(cartesian.z / cartesian.length)
        let longitude:Scalar  = Scalar.Math.atan2(y: cartesian.y, x: cartesian.x)
        self.init(colatitude, longitude)
    }
    
    init(normalized cartesian:Vector3<Scalar>)
    {
        let colatitude:Scalar = Scalar.Math.acos(cartesian.z)
        let longitude:Scalar  = Scalar.Math.atan2(y: cartesian.y, x: cartesian.x)
        self.init(colatitude, longitude)
    }
}
extension Vector3 where Scalar:FloatingPoint & Mathematical 
{
    init(spherical:Spherical2<Scalar>)
    {
        let ll:Vector2<Scalar>  = .init(spherical.storage)
        let sin:Vector2<Scalar> = Vector2.Math.sin(ll), 
            cos:Vector2<Scalar> = Vector2.Math.cos(ll)
        self = .extend(.init(cos.y, sin.y) * sin.x, cos.x)
    }
}

struct Spherical2<Scalar> where Scalar:SIMDScalar & Mathematical
{
    var storage:SIMD2<Scalar>
    
    var colatitude:Scalar
    {
        get 
        { 
            return self.storage.x
        }
        set(x)
        {
            self.storage.x = x
        }
    }
    var longitude:Scalar 
    {
        get 
        { 
            return self.storage.y
        }
        set(y)
        {
            self.storage.y = y
        }
    }
    
    init(_ colatitude:Scalar, _ longitude:Scalar)
    {
        self.init(.init(colatitude, longitude))
    }
    
    init(_ storage:SIMD2<Scalar>) 
    {
        self.storage = storage 
    }
    
    func map<Result>(_ transform:(Scalar) throws -> Result) rethrows -> Spherical2<Result>
        where Result:SIMDScalar 
    {
        return .init(try transform(self.colatitude), try transform(self.longitude))
    }
}
extension Spherical2 where Scalar:FloatingPoint
{
    static 
    var zero:Spherical2<Scalar> 
    {
        return .init(.zero) 
    }
    
    prefix 
    static func - (operand:Spherical2<Scalar>) -> Spherical2<Scalar>
    {
        return .init(-operand.storage)
    }
    
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 570)
    static 
    func + (lhs:Spherical2<Scalar>, rhs:Spherical2<Scalar>) 
        -> Spherical2<Scalar>
    {
        return .init(lhs.storage + rhs.storage)
    }
    static 
    func + (lhs:Spherical2<Scalar>, rhs:Scalar) 
        -> Spherical2<Scalar>
    {
        return .init(lhs.storage + rhs)
    }
    static 
    func + (lhs:Scalar, rhs:Spherical2<Scalar>) 
        -> Spherical2<Scalar>
    {
        return .init(lhs + rhs.storage)
    }
    
    static 
    func += (lhs:inout Spherical2<Scalar>, rhs:Spherical2<Scalar>)
    {
        lhs.storage += rhs.storage
    }
    static 
    func += (lhs:inout Spherical2<Scalar>, rhs:Scalar)
    {
        lhs.storage += rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 570)
    static 
    func - (lhs:Spherical2<Scalar>, rhs:Spherical2<Scalar>) 
        -> Spherical2<Scalar>
    {
        return .init(lhs.storage - rhs.storage)
    }
    static 
    func - (lhs:Spherical2<Scalar>, rhs:Scalar) 
        -> Spherical2<Scalar>
    {
        return .init(lhs.storage - rhs)
    }
    static 
    func - (lhs:Scalar, rhs:Spherical2<Scalar>) 
        -> Spherical2<Scalar>
    {
        return .init(lhs - rhs.storage)
    }
    
    static 
    func -= (lhs:inout Spherical2<Scalar>, rhs:Spherical2<Scalar>)
    {
        lhs.storage -= rhs.storage
    }
    static 
    func -= (lhs:inout Spherical2<Scalar>, rhs:Scalar)
    {
        lhs.storage -= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 570)
    static 
    func * (lhs:Spherical2<Scalar>, rhs:Spherical2<Scalar>) 
        -> Spherical2<Scalar>
    {
        return .init(lhs.storage * rhs.storage)
    }
    static 
    func * (lhs:Spherical2<Scalar>, rhs:Scalar) 
        -> Spherical2<Scalar>
    {
        return .init(lhs.storage * rhs)
    }
    static 
    func * (lhs:Scalar, rhs:Spherical2<Scalar>) 
        -> Spherical2<Scalar>
    {
        return .init(lhs * rhs.storage)
    }
    
    static 
    func *= (lhs:inout Spherical2<Scalar>, rhs:Spherical2<Scalar>)
    {
        lhs.storage *= rhs.storage
    }
    static 
    func *= (lhs:inout Spherical2<Scalar>, rhs:Scalar)
    {
        lhs.storage *= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 570)
    static 
    func / (lhs:Spherical2<Scalar>, rhs:Spherical2<Scalar>) 
        -> Spherical2<Scalar>
    {
        return .init(lhs.storage / rhs.storage)
    }
    static 
    func / (lhs:Spherical2<Scalar>, rhs:Scalar) 
        -> Spherical2<Scalar>
    {
        return .init(lhs.storage / rhs)
    }
    static 
    func / (lhs:Scalar, rhs:Spherical2<Scalar>) 
        -> Spherical2<Scalar>
    {
        return .init(lhs / rhs.storage)
    }
    
    static 
    func /= (lhs:inout Spherical2<Scalar>, rhs:Spherical2<Scalar>)
    {
        lhs.storage /= rhs.storage
    }
    static 
    func /= (lhs:inout Spherical2<Scalar>, rhs:Scalar)
    {
        lhs.storage /= rhs
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 600)
    
    func addingProduct(_ lhs:Spherical2<Scalar>, _ rhs:Spherical2<Scalar>) -> Spherical2<Scalar>
    {
        return .init(self.storage.addingProduct(lhs.storage, rhs.storage))
    }
    func addingProduct(_ lhs:Scalar, _ rhs:Spherical2<Scalar>) -> Spherical2<Scalar>
    {
        return .init(self.storage.addingProduct(lhs, rhs.storage))
    }
    func addingProduct(_ lhs:Spherical2<Scalar>, _ rhs:Scalar) -> Spherical2<Scalar>
    {
        return .init(self.storage.addingProduct(lhs.storage, rhs))
    }
    mutating 
    func addProduct(_ lhs:Spherical2<Scalar>, _ rhs:Spherical2<Scalar>)
    {
        self.storage.addProduct(lhs.storage, rhs.storage)
    }
    mutating 
    func addProduct(_ lhs:Scalar, _ rhs:Spherical2<Scalar>)
    {
        self.storage.addProduct(lhs, rhs.storage)
    }
    mutating 
    func addProduct(_ lhs:Spherical2<Scalar>, _ rhs:Scalar)
    {
        self.storage.addProduct(lhs.storage, rhs)
    }

    func squareRoot() -> Spherical2<Scalar>
    {
        return .init(self.storage.squareRoot())
    }

    func rounded(_ rule:FloatingPointRoundingRule) -> Spherical2<Scalar>
    {
        return .init(self.storage.rounded(rule))
    }
    mutating 
    func round(_ rule:FloatingPointRoundingRule)
    {
        self.storage.round(rule)
    }
}

// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 646)
struct Matrix2<T> where T:SIMDScalar 
{
    private 
    var columns:(Vector2<T>, Vector2<T>)
    
    var transposed:Matrix2<T> 
    {
        return .init(
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 655)
            .init(self.columns.0.x, self.columns.1.x),
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 655)
            .init(self.columns.0.y, self.columns.1.y)
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 657)
            )
    }
    
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 666)
    
    @inline(__always)
    subscript(column:Int) -> Vector2<T> 
    {
        get 
        {
            switch column 
            {
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 675)
            case 0:
                return self.columns.0
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 675)
            case 1:
                return self.columns.1
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 678)
            default:
                fatalError("Matrix column index out of range")
            }
        }
        set(value) 
        {
            switch column 
            {
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 687)
            case 0:
                self.columns.0 = value 
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 687)
            case 1:
                self.columns.1 = value 
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 690)
            default:
                fatalError("Matrix column index out of range")
            }
        }
    }
    
    init(_ v0:Vector2<T>, _ v1:Vector2<T>)
    {
        self.columns = (v0, v1)
    }
}

extension Matrix2 where T:Numeric  
{
    static 
    var identity:Matrix2<T> 
    {
        return .init(
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 709)
            .init(1, 0),
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 709)
            .init(0, 1)
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 711)
        )
    }
}
extension Matrix2 where T:FixedWidthInteger
{
    static 
    func &>< (A:Matrix2<T>, v:Vector2<T>) -> Vector2<T>
    {
        return A.columns.0 &* v.x &+ A.columns.1 &* v.y
    }
    
    static 
    func &>< (A:Matrix2<T>, B:Matrix2<T>) -> Matrix2<T>
    {
        return .init(A &>< B.columns.0, A &>< B.columns.1)
    }
}
extension Matrix2 where T:FloatingPoint
{
    static 
    func >< (A:Matrix2<T>, v:Vector2<T>) -> Vector2<T>
    {
        return (A.columns.0 * v.x).addingProduct(A.columns.1, v.y)
    }
    
    static 
    func >< (A:Matrix2<T>, B:Matrix2<T>) -> Matrix2<T>
    {
        return .init(A >< B.columns.0, A >< B.columns.1)
    }
}
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 646)
struct Matrix3<T> where T:SIMDScalar 
{
    private 
    var columns:(Vector3<T>, Vector3<T>, Vector3<T>)
    
    var transposed:Matrix3<T> 
    {
        return .init(
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 655)
            .init(self.columns.0.x, self.columns.1.x, self.columns.2.x),
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 655)
            .init(self.columns.0.y, self.columns.1.y, self.columns.2.y),
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 655)
            .init(self.columns.0.z, self.columns.1.z, self.columns.2.z)
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 657)
            )
    }
    
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 661)
    var matrix2:Matrix2<T> 
    {
        return .init(self.columns.0.xy, self.columns.1.xy)
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 666)
    
    @inline(__always)
    subscript(column:Int) -> Vector3<T> 
    {
        get 
        {
            switch column 
            {
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 675)
            case 0:
                return self.columns.0
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 675)
            case 1:
                return self.columns.1
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 675)
            case 2:
                return self.columns.2
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 678)
            default:
                fatalError("Matrix column index out of range")
            }
        }
        set(value) 
        {
            switch column 
            {
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 687)
            case 0:
                self.columns.0 = value 
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 687)
            case 1:
                self.columns.1 = value 
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 687)
            case 2:
                self.columns.2 = value 
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 690)
            default:
                fatalError("Matrix column index out of range")
            }
        }
    }
    
    init(_ v0:Vector3<T>, _ v1:Vector3<T>, _ v2:Vector3<T>)
    {
        self.columns = (v0, v1, v2)
    }
}

extension Matrix3 where T:Numeric  
{
    static 
    var identity:Matrix3<T> 
    {
        return .init(
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 709)
            .init(1, 0, 0),
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 709)
            .init(0, 1, 0),
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 709)
            .init(0, 0, 1)
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 711)
        )
    }
}
extension Matrix3 where T:FixedWidthInteger
{
    static 
    func &>< (A:Matrix3<T>, v:Vector3<T>) -> Vector3<T>
    {
        return A.columns.0 &* v.x &+ A.columns.1 &* v.y &+ A.columns.2 &* v.z
    }
    
    static 
    func &>< (A:Matrix3<T>, B:Matrix3<T>) -> Matrix3<T>
    {
        return .init(A &>< B.columns.0, A &>< B.columns.1, A &>< B.columns.2)
    }
}
extension Matrix3 where T:FloatingPoint
{
    static 
    func >< (A:Matrix3<T>, v:Vector3<T>) -> Vector3<T>
    {
        return (A.columns.0 * v.x).addingProduct(A.columns.1, v.y).addingProduct(A.columns.2, v.z)
    }
    
    static 
    func >< (A:Matrix3<T>, B:Matrix3<T>) -> Matrix3<T>
    {
        return .init(A >< B.columns.0, A >< B.columns.1, A >< B.columns.2)
    }
}
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 646)
struct Matrix4<T> where T:SIMDScalar 
{
    private 
    var columns:(Vector4<T>, Vector4<T>, Vector4<T>, Vector4<T>)
    
    var transposed:Matrix4<T> 
    {
        return .init(
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 655)
            .init(self.columns.0.x, self.columns.1.x, self.columns.2.x, self.columns.3.x),
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 655)
            .init(self.columns.0.y, self.columns.1.y, self.columns.2.y, self.columns.3.y),
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 655)
            .init(self.columns.0.z, self.columns.1.z, self.columns.2.z, self.columns.3.z),
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 655)
            .init(self.columns.0.w, self.columns.1.w, self.columns.2.w, self.columns.3.w)
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 657)
            )
    }
    
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 661)
    var matrix3:Matrix3<T> 
    {
        return .init(self.columns.0.xyz, self.columns.1.xyz, self.columns.2.xyz)
    }
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 666)
    
    @inline(__always)
    subscript(column:Int) -> Vector4<T> 
    {
        get 
        {
            switch column 
            {
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 675)
            case 0:
                return self.columns.0
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 675)
            case 1:
                return self.columns.1
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 675)
            case 2:
                return self.columns.2
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 675)
            case 3:
                return self.columns.3
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 678)
            default:
                fatalError("Matrix column index out of range")
            }
        }
        set(value) 
        {
            switch column 
            {
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 687)
            case 0:
                self.columns.0 = value 
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 687)
            case 1:
                self.columns.1 = value 
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 687)
            case 2:
                self.columns.2 = value 
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 687)
            case 3:
                self.columns.3 = value 
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 690)
            default:
                fatalError("Matrix column index out of range")
            }
        }
    }
    
    init(_ v0:Vector4<T>, _ v1:Vector4<T>, _ v2:Vector4<T>, _ v3:Vector4<T>)
    {
        self.columns = (v0, v1, v2, v3)
    }
}

extension Matrix4 where T:Numeric  
{
    static 
    var identity:Matrix4<T> 
    {
        return .init(
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 709)
            .init(1, 0, 0, 0),
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 709)
            .init(0, 1, 0, 0),
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 709)
            .init(0, 0, 1, 0),
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 709)
            .init(0, 0, 0, 1)
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 711)
        )
    }
}
extension Matrix4 where T:FixedWidthInteger
{
    static 
    func &>< (A:Matrix4<T>, v:Vector4<T>) -> Vector4<T>
    {
        return A.columns.0 &* v.x &+ A.columns.1 &* v.y &+ A.columns.2 &* v.z &+ A.columns.3 &* v.w
    }
    
    static 
    func &>< (A:Matrix4<T>, B:Matrix4<T>) -> Matrix4<T>
    {
        return .init(A &>< B.columns.0, A &>< B.columns.1, A &>< B.columns.2, A &>< B.columns.3)
    }
}
extension Matrix4 where T:FloatingPoint
{
    static 
    func >< (A:Matrix4<T>, v:Vector4<T>) -> Vector4<T>
    {
        return (A.columns.0 * v.x).addingProduct(A.columns.1, v.y).addingProduct(A.columns.2, v.z).addingProduct(A.columns.3, v.w)
    }
    
    static 
    func >< (A:Matrix4<T>, B:Matrix4<T>) -> Matrix4<T>
    {
        return .init(A >< B.columns.0, A >< B.columns.1, A >< B.columns.2, A >< B.columns.3)
    }
}
// ###sourceLocation(file: "/home/klossy/dev/diannamy-engine/sources/polysphere/library/vector.swift.gyb", line: 743)


struct Rectangle<T> where T:SIMDScalar
{
    var storage:SIMD4<T> 
    
    var a:Vector2<T> 
    {
        get 
        {
            return .init(self.storage.x, self.storage.y)
        }
        set(a)
        {
            self.storage.x = a.x
            self.storage.y = a.y
        }
    }
    var b:Vector2<T> 
    {
        get 
        {
            return .init(self.storage.z, self.storage.w)
        }
        set(b)
        {
            self.storage.z = b.x
            self.storage.w = b.y
        }
    }
    
    init(_ a:Vector2<T>, _ b:Vector2<T>) 
    {
        self.init(.init(a.x, a.y, b.x, b.y))
    }
    
    init(_ storage:SIMD4<T>) 
    {
        self.storage = storage 
    }
    
    func map<Result>(_ transform:(T) throws -> Result) rethrows -> Rectangle<Result>
        where Result:SIMDScalar 
    {
        return  .init(.init(try transform(self.storage.x), 
                            try transform(self.storage.y), 
                            try transform(self.storage.z), 
                            try transform(self.storage.w)))
    }
}
extension Rectangle where T:FixedWidthInteger 
{
    static 
    var zero:Rectangle<T> 
    {
        return .init(.zero)
    }
    var size:Vector2<T> 
    {
        return self.b &- self.a
    }
}
extension Rectangle where T:FloatingPoint 
{
    static 
    var zero:Rectangle<T> 
    {
        return .init(.zero)
    }
    var size:Vector2<T> 
    {
        return self.b - self.a
    }
}
extension Rectangle where T:FloatingPoint & ExpressibleByFloatLiteral 
{
    var midpoint:Vector2<T> 
    {
        return 0.5 * (self.a + self.b)
    }
}
