struct Location 
{
    let coordinates:Math<Float>.V3
    
    static 
    func distance(_ a:Location, _ b:Location) -> Float 
    {
        return Float.acos(Math.dot(a.coordinates, b.coordinates))
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
    func add(deposit:Deposit)
    {
        if let existing:Int = 
            Algorithm.nearest(of: self.food.map{ $0.location }, to: deposit.location, within: 0.1)
        {
            self.food[existing].amount += 1
        }
        else 
        {
            self.food.append(deposit)
        }
    }
}

enum Algorithm 
{
    static 
    func nearest(of points:[Location], to query:Location, within range:Float) -> Int?
    {
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
        
        return index
    }
}
