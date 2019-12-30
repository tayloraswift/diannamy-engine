protocol Interpolable
{
    associatedtype Parameter:FloatingPoint 
    
    static 
    func interpolate(_:Self, _:Self, by:Parameter) -> Self 
}
extension Vector2:Interpolable where Scalar:FloatingPoint 
{
    typealias Parameter = Scalar 
}
extension Vector3:Interpolable where Scalar:FloatingPoint 
{
    typealias Parameter = Scalar 
}
extension Vector4:Interpolable where Scalar:FloatingPoint 
{
    typealias Parameter = Scalar 
}

protocol InterpolationCurve 
{
    // x from 0 to 1
    static
    func parameter<Parameter>(_:Parameter) -> Parameter where Parameter:FloatingPoint
}

enum Curve 
{
    enum Linear:InterpolationCurve 
    {
        static
        func parameter<Parameter>(_ x:Parameter) -> Parameter where Parameter:FloatingPoint
        {
            return x
        }
    }
    enum Quadratic:InterpolationCurve 
    {
        static
        func parameter<Parameter>(_ x:Parameter) -> Parameter where Parameter:FloatingPoint
        {
            return x * x
        }
    }
}
struct Transition<State, Curve> where State:Interpolable, Curve:InterpolationCurve
{
    private 
    var base:State, 
        head:(next:State, remaining:Int, time:Int)?
    
    var current:State 
    {
        if let (next, remaining, time):(State, Int, Int) = self.head 
        {
            if remaining <= 0 
            {
                return next 
            }
            else 
            {
                let phase:State.Parameter = .init(remaining) / .init(time)
                return State.interpolate(next, self.base, by: Curve.parameter(phase)) 
            }
        }
        else 
        {
            return self.base 
        }
    } 
    
    init(initial:State) 
    {
        self.base       = initial
        self.head       = nil 
    }
    
    mutating 
    func stop()
    {
        self.base = self.current 
        self.head = (self.base, 0, 1) 
    }
    
    mutating 
    func charge(time:Int, _ next:State) 
    {
        self.base = self.current 
        self.head = (next, time, max(time, 1))
    }
    
    mutating 
    func charge(time:Int, transform:(inout State) throws -> ()) rethrows 
    {
        self.base       = self.current 
        var next:State  = self.base 
        try transform(&next)
        self.head       = (next, time, max(time, 1))
    }
    
    mutating 
    func process(_ delta:Int) -> Bool // time in ms 
    {
        if let (next, remaining, _):(State, Int, Int) = self.head, delta > 0
        {
            if delta < remaining 
            {
                self.head?.remaining -= delta 
            }
            else 
            {
                self.base = next 
                self.head = nil 
            }
            
            return true 
        }
        else 
        {
            return false 
        }
    }
}
