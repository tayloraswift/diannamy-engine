//import GLFW

struct Location 
{
    let coordinates:Math<Float>.V3
    
    init(vector:Math<Float>.V3)
    {
        self.coordinates = Math.normalize(vector)
    }
    
    static 
    func distance(_ a:Location, _ b:Location) -> Float 
    {
        return Float.acos(Math.clamp(Math.dot(a.coordinates, b.coordinates), to: -1 ... 1))
    }
}

class BuildingType 
{
    let name:String, 
        tier:Int
    
    init(name:String, tier:Int)
    {
        self.name = name 
        self.tier = tier
    }
}

struct Building 
{
    let location:Location
    var type:BuildingType
}

struct Deposit 
{
    let location:Location
    var amount:Int
}

enum Resource:Int 
{
    case food, ore, coal, oil
}

struct World 
{
    var food:[Deposit]       = []
    
    var buildings:[Building] = []
    
    init() 
    {
    }
    
    mutating 
    func add(deposit:Deposit) -> Int
    {
        if let existing:Int = 
            Algorithm.nearest(of: self.food.map{ $0.location }, to: deposit.location, within: 0.1)
        {
            self.food[existing].amount += deposit.amount
            return existing
        }
        else 
        {
            self.food.append(deposit)
            return self.food.count - 1
        }
    }
    
    func find(_ location:Location) -> Int?
    {
        return Algorithm.nearest(of: self.food.map{ $0.location }, to: location, within: 0.1)
    }
}

enum Algorithm 
{
    static 
    func nearest(of points:[Location], to query:Location, within range:Float) -> Int?
    {
        //let _t0:Double = glfwGetTime()
        
        var radius:Float = Float.infinity, 
            index:Int?    = nil
        for (i, point):(Int, Location) in points.enumerated() 
        {
            let distance:Float = Location.distance(point, query)
            guard distance < range 
            else 
            {
                continue 
            }
            
            if distance < radius 
            {
                radius = distance 
                index  = i
            }
        }
        
        //print(1000 * (glfwGetTime() - _t0))
        
        return index
    }
}
