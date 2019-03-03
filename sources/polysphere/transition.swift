protocol Interpolable 
{
    static 
    func interpolate<F>(_:Self, _:Self, by:F) -> Self where F:FloatingPoint 
}

struct Transition<State> where State:Interpolable
{
    private 
    var base:State, 
        head:(next:State, remaining:Int, time:Int)?
    
    private 
    var mutated:Bool  
    
    var dirty:Bool 
    {
        return self.mutated 
    }
    
    var current:State 
    {
        if let head:(next:State, remaining:Int, time:Int) = self.head 
        {
            let phase:Double = .init(head.remaining) / .init(head.time)
            return State.interpolate(head.next, self.base, by: phase) 
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
        self.mutated    = true 
    }
    
    mutating 
    func charge(_ next:State, time:Int) 
    {
        if time > 0 
        {
            self.head = (next, time, time)
        }
        else 
        {
            self.base       = next 
            self.head       = nil 
            self.mutated    = true 
        }
    }
    
    mutating 
    func process(_ delta:Int) -> Bool // time in ms 
    {
        if let remaining:Int = self.head?.remaining, delta > 0
        {
            if delta < remaining 
            {
                self.head?.remaining -= delta 
            }
            else 
            {
                self.head = nil 
            }
            
            self.mutated = true 
        }
        
        return self.mutated 
    }

    mutating 
    func pop() -> State? 
    {
        if self.mutated 
        {
            self.mutated = false 
            return self.current 
        }
        else 
        {
            return nil 
        }
    }
}
