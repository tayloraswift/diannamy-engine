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

protocol Mathable
{
    associatedtype Math:MathImplementations where Math.Value == Self
}
protocol MathImplementations 
{
    associatedtype Value
    static func sin(_:Value) -> Value
    static func cos(_:Value) -> Value
    static func tan(_:Value) -> Value
    static func asin(_:Value) -> Value
    static func acos(_:Value) -> Value
    static func atan(_:Value) -> Value
    static func atan2(y:Value, x:Value) -> Value
}
extension Float:Mathable
{
    enum Math:MathImplementations
    {
        @inline(__always)
        static 
        func sin(_ x:Float) -> Float 
        {
            return _sin(x)
        }
        @inline(__always)
        static 
        func cos(_ x:Float) -> Float 
        {
            return _cos(x)
        }
        @inline(__always)
        static 
        func tan(_ x:Float) -> Float 
        {
            return Glibc.tan(x)
        }
        
        @inline(__always)
        static
        func asin(_ t:Float) -> Float
        {
            return Glibc.asin(t)
        }
        @inline(__always)
        static
        func acos(_ t:Float) -> Float
        {
            return Glibc.acos(t)
        }
        @inline(__always)
        static
        func atan(_ t:Float) -> Float
        {
            return Glibc.atan(t)
        }
        @inline(__always)
        static
        func atan2(y:Float, x:Float) -> Float
        {
            return Glibc.atan2(y, x)
        }
    }
}
extension Double:Mathable
{
    enum Math:MathImplementations
    {
        @inline(__always)
        static 
        func sin(_ x:Double) -> Double 
        {
            return _sin(x)
        }
        @inline(__always)
        static 
        func cos(_ x:Double) -> Double 
        {
            return _cos(x)
        }
        @inline(__always)
        static 
        func tan(_ x:Double) -> Double 
        {
            return Glibc.tan(x)
        }
        
        @inline(__always)
        static
        func asin(_ t:Double) -> Double
        {
            return Glibc.asin(t)
        }
        @inline(__always)
        static
        func acos(_ t:Double) -> Double
        {
            return Glibc.acos(t)
        }
        @inline(__always)
        static
        func atan(_ t:Double) -> Double
        {
            return Glibc.atan(t)
        }
        @inline(__always)
        static
        func atan2(y:Double, x:Double) -> Double
        {
            return Glibc.atan2(y, x)
        }
    }
}
extension SIMD2:Mathable where Scalar:Mathable
{
    enum Math:MathImplementations
    {
        @inline(__always)
        static 
        func sin(_ v:SIMD2<Scalar>) -> SIMD2<Scalar> 
        {
            return .init(Scalar.Math.sin(v.x), Scalar.Math.sin(v.y))
        }
        @inline(__always)
        static 
        func cos(_ v:SIMD2<Scalar>) -> SIMD2<Scalar> 
        {
            return .init(Scalar.Math.cos(v.x), Scalar.Math.cos(v.y))
        }
        @inline(__always)
        static 
        func tan(_ v:SIMD2<Scalar>) -> SIMD2<Scalar> 
        {
            return .init(Scalar.Math.tan(v.x), Scalar.Math.tan(v.y))
        }
        
        @inline(__always)
        static
        func asin(_ v:SIMD2<Scalar>) -> SIMD2<Scalar>
        {
            return .init(Scalar.Math.asin(v.x), Scalar.Math.asin(v.y))
        }
        @inline(__always)
        static
        func acos(_ v:SIMD2<Scalar>) -> SIMD2<Scalar>
        {
            return .init(Scalar.Math.acos(v.x), Scalar.Math.acos(v.y))
        }
        @inline(__always)
        static
        func atan(_ v:SIMD2<Scalar>) -> SIMD2<Scalar>
        {
            return .init(Scalar.Math.atan(v.x), Scalar.Math.atan(v.y))
        }
        @inline(__always)
        static
        func atan2(y:SIMD2<Scalar>, x:SIMD2<Scalar>) -> SIMD2<Scalar>
        {
            return .init(Scalar.Math.atan2(y: y.x, x: x.x), Scalar.Math.atan2(y: y.y, x: x.y))
        }
    }
}

protocol Vector:Hashable, Codable 
{
    associatedtype Storage:SIMD
    var storage:Storage { get set }
    
    init(_ storage:Storage) 
}

protocol WrapReducibleVector:Vector 
{
    var wrappingSum:Storage.Scalar 
    {
        get
    }
    var wrappingVolume:Storage.Scalar
    {
        get
    }
}

protocol ReducibleVector:Vector 
{
    var sum:Storage.Scalar 
    {
        get
    }
    var volume:Storage.Scalar
    {
        get
    }
}

struct Spherical2<Coordinate>:Vector where Coordinate:SIMDScalar & Mathable
{
    typealias Storage = SIMD2<Coordinate>
    
    var storage:Storage
    
    var colatitude:Storage.Scalar
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
    var azimuth:Storage.Scalar 
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
    
    init(_ colatitude:Storage.Scalar, _ azimuth:Storage.Scalar)
    {
        self.init(.init(colatitude, azimuth))
    }
    
    init(_ storage:Storage) 
    {
        self.storage = storage 
    }
    
    func map<Result>(_ transform:(Storage.Scalar) throws -> Result) rethrows -> Vector2<Result>
        where Result:SIMDScalar 
    {
        return .init(try transform(self.colatitude), try transform(self.azimuth))
    }
}
struct Vector2<Scalar>:Vector where Scalar:SIMDScalar 
{
    typealias Storage = SIMD2<Scalar>
    
    var storage:Storage
    
    var x:Storage.Scalar 
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
    var y:Storage.Scalar 
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
    
    init(_ x:Storage.Scalar, _ y:Storage.Scalar)
    {
        self.init(.init(x, y))
    }
    
    init(_ storage:Storage) 
    {
        self.storage = storage 
    }
    
    func map<Result>(_ transform:(Storage.Scalar) throws -> Result) rethrows -> Vector2<Result>
        where Result:SIMDScalar 
    {
        return .init(try transform(self.x), try transform(self.y))
    }
}
struct Vector3<Scalar>:Vector where Scalar:SIMDScalar 
{
    typealias Storage = SIMD3<Scalar> 
    
    var storage:Storage
    
    var x:Storage.Scalar 
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
    var y:Storage.Scalar 
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
    var z:Storage.Scalar 
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
    
    var xy:Vector2<Storage.Scalar> 
    {
        return .init(self.x, self.y)
    }
    
    static 
    func extend(_ v2:Vector2<Storage.Scalar>, _ z:Storage.Scalar) -> Vector3<Storage.Scalar> 
    {
        return .init(v2.x, v2.y, z)
    }
    
    init(_ x:Storage.Scalar, _ y:Storage.Scalar, _ z:Storage.Scalar)
    {
        self.init(.init(x, y, z))
    }
    
    init(_ storage:Storage) 
    {
        self.storage = storage 
    }
    
    func map<Result>(_ transform:(Storage.Scalar) throws -> Result) rethrows -> Vector3<Result>
        where Result:SIMDScalar 
    {
        return .init(try transform(self.x), try transform(self.y), try transform(self.z))
    }
}
struct Vector4<Scalar>:Vector where Scalar:SIMDScalar 
{
    typealias Storage = SIMD4<Scalar> 
    
    var storage:Storage
    
    var x:Storage.Scalar 
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
    var y:Storage.Scalar 
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
    var z:Storage.Scalar 
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
    var w:Storage.Scalar 
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
    
    var xyz:Vector3<Storage.Scalar> 
    {
        return .init(self.x, self.y, self.z)
    }
    
    static 
    func extend(_ v3:Vector3<Storage.Scalar>, _ w:Storage.Scalar) -> Vector4<Storage.Scalar> 
    {
        return .init(v3.x, v3.y, v3.z, w)
    }
    
    init(_ x:Storage.Scalar, _ y:Storage.Scalar, _ z:Storage.Scalar, _ w:Storage.Scalar)
    {
        self.init(.init(x, y, z, w))
    }
    
    init(_ storage:Storage) 
    {
        self.storage = storage 
    }
    
    func map<Result>(_ transform:(Storage.Scalar) throws -> Result) rethrows -> Vector4<Result>
        where Result:SIMDScalar 
    {
        return .init(try transform(self.x), try transform(self.y), try transform(self.z), try transform(self.w))
    }
}

extension Vector 
{
    subscript(index:Int) -> Storage.Scalar 
    {
        return self.storage[index]
    }
}
extension Vector where Storage.Scalar:FixedWidthInteger
{
    static 
    var zero:Self 
    {
        return .init(Storage.zero) 
    }
    
    static func &<<(lhs:Self, rhs:Self) -> Self
    {
        return .init(lhs.storage &<< rhs.storage)
    }
    static func &>>(lhs:Self, rhs:Self) -> Self
    {
        return .init(lhs.storage &>> rhs.storage)
    }
    static func &+(lhs:Self, rhs:Self) -> Self
    {
        return .init(lhs.storage &+ rhs.storage)
    }
    static func &-(lhs:Self, rhs:Self) -> Self
    {
        return .init(lhs.storage &- rhs.storage)
    }
    static func &*(lhs:Self, rhs:Self) -> Self
    {
        return .init(lhs.storage &* rhs.storage)
    }
    static func /(lhs:Self, rhs:Self) -> Self
    {
        return .init(lhs.storage / rhs.storage)
    }
    static func %(lhs:Self, rhs:Self) -> Self 
    {
        return .init(lhs.storage % rhs.storage)
    }
    
    static func &<< (lhs:Self, rhs:Storage.Scalar) -> Self
    {
        return .init(lhs.storage &<< rhs)
    }
    static func &>> (lhs:Self, rhs:Storage.Scalar) -> Self
    {
        return .init(lhs.storage &>> rhs)
    }
    static func &+  (lhs:Self, rhs:Storage.Scalar) -> Self 
    {
        return .init(lhs.storage &+ rhs)
    }
    static func &-  (lhs:Self, rhs:Storage.Scalar) -> Self 
    {
        return .init(lhs.storage &- rhs)
    }
    static func &*  (lhs:Self, rhs:Storage.Scalar) -> Self 
    {
        return .init(lhs.storage &* rhs)
    }
    static func /   (lhs:Self, rhs:Storage.Scalar) -> Self
    {
        return .init(lhs.storage / rhs)
    }
    static func %   (lhs:Self, rhs:Storage.Scalar) -> Self
    {
        return .init(lhs.storage % rhs)
    }
    
    static func &+  (lhs:Storage.Scalar, rhs:Self) -> Self 
    {
        return .init(lhs &+ rhs.storage)
    }
    static func &-  (lhs:Storage.Scalar, rhs:Self) -> Self 
    {
        return .init(lhs &- rhs.storage)
    }
    static func &*  (lhs:Storage.Scalar, rhs:Self) -> Self 
    {
        return .init(lhs &* rhs.storage)
    }
    
    static func &<<=(lhs:inout Self, rhs:Self)
    {
        lhs.storage &<<= rhs.storage
    }
    static func &>>=(lhs:inout Self, rhs:Self)
    {
        lhs.storage &>>= rhs.storage
    }
    static func &+= (lhs:inout Self, rhs:Self) 
    {
        lhs.storage &+= rhs.storage
    }
    static func &-= (lhs:inout Self, rhs:Self) 
    {
        lhs.storage &-= rhs.storage
    }
    static func &*= (lhs:inout Self, rhs:Self) 
    {
        lhs.storage &*= rhs.storage
    }
    static func /=  (lhs:inout Self, rhs:Self)
    {
        lhs.storage /= rhs.storage
    }
    static func %=  (lhs:inout Self, rhs:Self)
    {
        lhs.storage %= rhs.storage
    }
    
    static func &<<=(lhs:inout Self, rhs:Storage.Scalar)
    {
        lhs.storage &<<= rhs
    }
    static func &>>=(lhs:inout Self, rhs:Storage.Scalar)
    {
        lhs.storage &>>= rhs
    }
    static func &+= (lhs:inout Self, rhs:Storage.Scalar) 
    {
        lhs.storage &+= rhs
    }
    static func &-= (lhs:inout Self, rhs:Storage.Scalar) 
    {
        lhs.storage &-= rhs
    }
    static func &*= (lhs:inout Self, rhs:Storage.Scalar) 
    {
        lhs.storage &*= rhs
    }
    static func /=  (lhs:inout Self, rhs:Storage.Scalar)
    {
        lhs.storage /= rhs
    }
    static func %=  (lhs:inout Self, rhs:Storage.Scalar)
    {
        lhs.storage %= rhs
    }
    
    
    func roundedUp(exponent:Int) -> Self  
    { 
        let mask:Storage.Scalar = .max &<< exponent 
        let truncated:Storage   = self.storage & mask, 
            carry:Storage       = Storage.zero.replacing(with: 1 &<< exponent, where: self.storage & ~mask .!= 0)
        return .init(truncated &+ carry)
    } 
}
extension WrapReducibleVector where Storage.Scalar:FixedWidthInteger 
{    
    static func &<> (lhs:Self, rhs:Self) -> Storage.Scalar
    {
        return (lhs &* rhs).wrappingSum 
    }
}
extension Vector2:WrapReducibleVector where Storage.Scalar:FixedWidthInteger 
{
    var wrappingSum:Storage.Scalar 
    {
        return self.x &+ self.y
    }
    var wrappingVolume:Storage.Scalar
    {
        return self.x &* self.y
    }
    
    static func &>< (lhs:Vector2<Storage.Scalar>, rhs:Vector2<Storage.Scalar>) -> Storage.Scalar
    {
        return  lhs.x &* rhs.y &- rhs.x &* lhs.y
    }
}
extension Vector3:WrapReducibleVector where Storage.Scalar:FixedWidthInteger 
{
    var wrappingSum:Storage.Scalar 
    {
        return self.x &+ self.y &+ self.z
    }
    var wrappingVolume:Storage.Scalar
    {
        return self.x &* self.y &* self.z
    }
    
    static func &>< (lhs:Vector3<Storage.Scalar>, rhs:Vector3<Storage.Scalar>) -> Vector3<Storage.Scalar> 
    {
        return  .init(lhs.y, lhs.z, lhs.x) &* .init(rhs.z, rhs.x, rhs.y) &- 
                .init(rhs.y, rhs.z, rhs.x) &* .init(lhs.z, lhs.x, lhs.y)
    }
}
extension Vector4:WrapReducibleVector where Storage.Scalar:FixedWidthInteger 
{
    var wrappingSum:Storage.Scalar 
    {
        return self.x &+ self.y &+ self.z &+ self.w
    }
    var wrappingVolume:Storage.Scalar
    {
        return self.x &* self.y &* self.z &* self.w
    }
}

extension FloatingPoint 
{
    static func lerp(_ a:Self, _ b:Self, _ t:Self) -> Self 
    {
        return a.addingProduct(a, -t).addingProduct(b, t)
    } 
}
extension Vector where Storage.Scalar:FloatingPoint 
{
    static 
    var zero:Self 
    {
        return .init(Storage.zero) 
    }
    
    prefix 
    static func - (operand:Self) -> Self
    {
        return .init(-operand.storage)
    }
    
    static func + (lhs:Self, rhs:Self) -> Self
    {
        return .init(lhs.storage + rhs.storage) 
    }
    static func - (lhs:Self, rhs:Self) -> Self
    {
        return .init(lhs.storage - rhs.storage) 
    }
    static func * (lhs:Self, rhs:Self) -> Self
    {
        return .init(lhs.storage * rhs.storage) 
    }
    static func / (lhs:Self, rhs:Self) -> Self
    {
        return .init(lhs.storage / rhs.storage) 
    }

    static func + (lhs:Storage.Scalar, rhs:Self) -> Self
    {
        return .init(lhs + rhs.storage) 
    }
    static func * (lhs:Storage.Scalar, rhs:Self) -> Self
    {
        return .init(lhs * rhs.storage) 
    }

    static func + (lhs:Self, rhs:Storage.Scalar) -> Self
    {
        return .init(lhs.storage + rhs) 
    }
    static func - (lhs:Self, rhs:Storage.Scalar) -> Self
    {
        return .init(lhs.storage - rhs) 
    }
    static func * (lhs:Self, rhs:Storage.Scalar) -> Self
    {
        return .init(lhs.storage * rhs) 
    }
    static func / (lhs:Self, rhs:Storage.Scalar) -> Self
    {
        return .init(lhs.storage / rhs) 
    }

    static func += (lhs:inout Self, rhs:Self)
    {
        lhs.storage += rhs.storage 
    }
    static func -= (lhs:inout Self, rhs:Self)
    {
        lhs.storage -= rhs.storage 
    }
    static func *= (lhs:inout Self, rhs:Self)
    {
        lhs.storage *= rhs.storage 
    }
    static func /= (lhs:inout Self, rhs:Self)
    {
        lhs.storage /= rhs.storage 
    }

    static func += (lhs:inout Self, rhs:Storage.Scalar)
    {
        lhs.storage += rhs 
    }
    static func -= (lhs:inout Self, rhs:Storage.Scalar)
    {
        lhs.storage -= rhs 
    }
    static func *= (lhs:inout Self, rhs:Storage.Scalar)
    {
        lhs.storage *= rhs 
    }
    static func /= (lhs:inout Self, rhs:Storage.Scalar)
    {
        lhs.storage /= rhs 
    }

    func addingProduct(_ lhs:Self, _ rhs:Self) -> Self
    {
        return .init(self.storage.addingProduct(lhs.storage, rhs.storage))
    }
    func addingProduct(_ lhs:Storage.Scalar, _ rhs:Self) -> Self
    {
        return .init(self.storage.addingProduct(lhs, rhs.storage))
    }
    func addingProduct(_ lhs:Self, _ rhs:Storage.Scalar) -> Self
    {
        return .init(self.storage.addingProduct(lhs.storage, rhs))
    }
    mutating 
    func addProduct(_ lhs:Self, _ rhs:Self)
    {
        self.storage.addProduct(lhs.storage, rhs.storage)
    }
    mutating 
    func addProduct(_ lhs:Storage.Scalar, _ rhs:Self)
    {
        self.storage.addProduct(lhs, rhs.storage)
    }
    mutating 
    func addProduct(_ lhs:Self, _ rhs:Storage.Scalar)
    {
        self.storage.addProduct(lhs.storage, rhs)
    }

    func squareRoot() -> Self
    {
        return .init(self.storage.squareRoot())
    }

    func rounded(_ rule:FloatingPointRoundingRule) -> Self
    {
        return .init(self.storage.rounded(rule))
    }
    mutating 
    func round(_ rule:FloatingPointRoundingRule)
    {
        self.storage.round(rule)
    }
    
    static func lerp(_ a:Self, _ b:Self, _ t:Storage.Scalar) -> Self 
    {
        return a.addingProduct(a, -t).addingProduct(b, t)
    } 

    var reciprocal:Self 
    {
        return .init(1 / self.storage)
    }
}
extension ReducibleVector where Storage.Scalar:FloatingPoint
{
    static func <> (lhs:Self, rhs:Self) -> Storage.Scalar
    {
        return (lhs * rhs).sum 
    }
    
    var length:Storage.Scalar 
    {
        return (self <> self).squareRoot()
    }
    
    mutating 
    func normalize() 
    {
        self /= self.length
    }
    func normalized() -> Self 
    {
        return self / self.length
    }

    static func <  (v:Self, r:Storage.Scalar) -> Bool
    {
        return v <> v <  r 
    }
    static func <= (v:Self, r:Storage.Scalar) -> Bool
    {
        return v <> v <= r 
    }
    static func ~~ (v:Self, r:Storage.Scalar) -> Bool
    {
        return v <> v == r 
    }
    static func !~ (v:Self, r:Storage.Scalar) -> Bool
    {
        return v <> v != r 
    }
    static func >= (v:Self, r:Storage.Scalar) -> Bool
    {
        return v <> v >= r 
    }
    static func >  (v:Self, r:Storage.Scalar) -> Bool
    {
        return v <> v >  r 
    }
}
extension Vector2:ReducibleVector where Storage.Scalar:FloatingPoint 
{    
    var sum:Storage.Scalar 
    {
        return self.x + self.y
    }
    var volume:Storage.Scalar
    {
        return self.x * self.y
    }
    
    static func >< (lhs:Vector2<Storage.Scalar>, rhs:Vector2<Storage.Scalar>) -> Storage.Scalar 
    {
        return  lhs.x * rhs.y - rhs.x * lhs.y
    }
}
extension Vector3:ReducibleVector where Storage.Scalar:FloatingPoint 
{    
    var sum:Storage.Scalar 
    {
        return self.x + self.y + self.z
    }
    var volume:Storage.Scalar
    {
        return self.x * self.y * self.z
    }
    
    static func >< (lhs:Vector3<Storage.Scalar>, rhs:Vector3<Storage.Scalar>) -> Vector3<Storage.Scalar> 
    {
        return  .init(lhs.y, lhs.z, lhs.x) * .init(rhs.z, rhs.x, rhs.y) - 
                .init(rhs.y, rhs.z, rhs.x) * .init(lhs.z, lhs.x, lhs.y)
    }
}
extension Vector4:ReducibleVector where Storage.Scalar:FloatingPoint 
{    
    var sum:Storage.Scalar 
    {
        return self.x + self.y + self.z + self.w
    }
    var volume:Storage.Scalar
    {
        return self.x * self.y * self.z * self.w
    }
}

func wrappingAbs<V>(_ vector:V) -> V where V:Vector, V.Storage.Scalar:FixedWidthInteger
{
    return .init(vector.storage.replacing(with: 0 &- vector.storage, where: vector.storage .< 0))
}
func abs<V>(_ vector:V) -> V where V:Vector, V.Storage.Scalar:FloatingPoint
{
    return .init(vector.storage.replacing(with: -vector.storage, where: vector.storage .< 0))
}

extension Spherical2 where Storage.Scalar:FloatingPoint
{
    var cartesian:Vector3<Storage.Scalar> 
    {
        let sin:Vector2<Storage.Scalar> = .init(Storage.Math.sin(self.storage)), 
            cos:Vector2<Storage.Scalar> = .init(Storage.Math.cos(self.storage))
        return .extend(.init(cos.y, sin.y) * sin.x, cos.x)
    }
}
extension Vector3 where Storage.Scalar:FloatingPoint & Mathable 
{
    var spherical:Spherical2<Storage.Scalar> 
    {
        return    .init(Storage.Scalar.Math.acos(self.z / self.length), 
                        Storage.Scalar.Math.atan2(y: self.y, x: self.x))
    }
    var sphericalAssumingNormalized:Spherical2<Storage.Scalar> 
    {
        return    .init(Storage.Scalar.Math.acos(self.z), 
                        Storage.Scalar.Math.atan2(y: self.y, x: self.x))
    }
}

struct Matrix2<T> where T:SIMDScalar
{
    var columns:(Vector2<T>, Vector2<T>)
    
    var transposed:Matrix2<T> 
    {
        return .init(
            .init(self.columns.0.x, self.columns.1.x), 
            .init(self.columns.0.y, self.columns.1.y))
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
        return .init(.init(1, 0), .init(0, 1))
    }
}
extension Matrix2 where T:FixedWidthInteger
{
    static 
    func &>< (A:Matrix2<T>, v:Vector2<T>) -> Vector2<T>
    {
        return  A.columns.0 &* v.x &+
                A.columns.1 &* v.y
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
        return            (A.columns.0 * v.x)
            .addingProduct(A.columns.1,  v.y)
    }
    
    static 
    func >< (A:Matrix2<T>, B:Matrix2<T>) -> Matrix2<T>
    {
        return .init(A >< B.columns.0, A >< B.columns.1)
    }
}

struct Matrix3<T> where T:SIMDScalar
{
    var columns:(Vector3<T>, Vector3<T>, Vector3<T>)
    
    var matrix2:Matrix2<T> 
    {
        return .init(self.columns.0.xy, self.columns.1.xy)
    }
    
    var transposed:Matrix3<T> 
    {
        return .init(
            .init(self.columns.0.x, self.columns.1.x, self.columns.2.x), 
            .init(self.columns.0.y, self.columns.1.y, self.columns.2.y),
            .init(self.columns.0.z, self.columns.1.z, self.columns.2.z))
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
        return .init(.init(1, 0, 0), .init(0, 1, 0), .init(0, 0, 1))
    }
}
extension Matrix3 where T:FixedWidthInteger
{
    static 
    func &>< (A:Matrix3<T>, v:Vector3<T>) -> Vector3<T>
    {
        return  A.columns.0 &* v.x &+
                A.columns.1 &* v.y &+
                A.columns.2 &* v.z
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
        return            (A.columns.0 * v.x)
            .addingProduct(A.columns.1,  v.y)
            .addingProduct(A.columns.2,  v.z)
    }
    
    static 
    func >< (A:Matrix3<T>, B:Matrix3<T>) -> Matrix3<T>
    {
        return .init(A >< B.columns.0, A >< B.columns.1, A >< B.columns.2)
    }
}

struct Matrix4<T> where T:SIMDScalar
{
    var columns:(Vector4<T>, Vector4<T>, Vector4<T>, Vector4<T>)
    
    var matrix3:Matrix3<T> 
    {
        return .init(self.columns.0.xyz, self.columns.1.xyz, self.columns.2.xyz)
    }
    
    var transposed:Matrix4<T> 
    {
        return .init(
            .init(self.columns.0.x, self.columns.1.x, self.columns.2.x, self.columns.3.x), 
            .init(self.columns.0.y, self.columns.1.y, self.columns.2.y, self.columns.3.y),
            .init(self.columns.0.z, self.columns.1.z, self.columns.2.z, self.columns.3.z),
            .init(self.columns.0.w, self.columns.1.w, self.columns.2.w, self.columns.3.w))
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
        return .init(.init(1, 0, 0, 0), .init(0, 1, 0, 0), .init(0, 0, 1, 0), .init(0, 0, 0, 1))
    }
}
extension Matrix4 where T:FixedWidthInteger
{
    static 
    func &>< (A:Matrix4<T>, v:Vector4<T>) -> Vector4<T>
    {
        return  A.columns.0 &* v.x as Vector4<T> &+
                A.columns.1 &* v.y as Vector4<T> &+
                A.columns.2 &* v.z as Vector4<T> &+
                A.columns.3 &* v.w as Vector4<T>
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
        return            (A.columns.0 * v.x)
            .addingProduct(A.columns.1,  v.y)
            .addingProduct(A.columns.2,  v.z)
            .addingProduct(A.columns.3,  v.w)
    }
    
    static 
    func >< (A:Matrix4<T>, B:Matrix4<T>) -> Matrix4<T>
    {
        return .init(A >< B.columns.0, A >< B.columns.1, A >< B.columns.2, A >< B.columns.3)
    }
}


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
    var size:Vector2<T> 
    {
        return self.b &- self.a
    }
}
extension Rectangle where T:FloatingPoint 
{
    var size:Vector2<T> 
    {
        return self.b - self.a
    }
}
extension Rectangle where T:BinaryFloatingPoint 
{
    var midpoint:Vector2<T> 
    {
        return 0.5 * (self.a + self.b)
    }
}


extension Vector2 
{
    static 
    func _struct(_ tuple:Math<Storage.Scalar>.V2) -> Vector2<Storage.Scalar> 
    {
        return .init(tuple.x, tuple.y)
    }
    
    var _tuple:Math<Storage.Scalar>.V2 
    {
        return (self.x, self.y)
    }
}
extension Vector3
{
    static 
    func _struct(_ tuple:Math<Storage.Scalar>.V3) -> Vector3<Storage.Scalar> 
    {
        return .init(tuple.x, tuple.y, tuple.z)
    }
    
    var _tuple:Math<Storage.Scalar>.V3 
    {
        return (self.x, self.y, self.z)
    }
}
extension Rectangle
{
    static 
    func _struct(_ tuple:Math<T>.Rectangle) -> Rectangle<T> 
    {
        return .init(._struct(tuple.a), ._struct(tuple.b))
    }
    
    var _tuple:Math<T>.Rectangle
    {
        return (self.a._tuple, self.b._tuple)
    }
}
