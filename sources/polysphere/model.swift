//import GLFW    

struct Borders 
{
    struct Marker 
    {
        enum Unfrozen 
        {
            case exterior(Int), interior(Int)
        }
        
        var location:Location, 
            owners:Set<Regions.Index>
    }
    
    struct Regions 
    {
        struct Index:Hashable 
        {
            let value:Int
            init(_ value:Int) 
            {
                self.value = value
            }
        }
        
        private 
        var regions:[[Int]]
        
        subscript(index:Index) -> [Int]
        {
            get 
            {
                return self.regions[index.value]
            }
            set(v)
            {
                self.regions[index.value] = v
            }
        }
    }
    
    private 
    var markers:[Marker], 
        regions:Regions
    
    mutating 
    func replace(_ regions:(Regions.Index, [Marker.Unfrozen])..., interiorMarkers:[Marker])
    {
        // find all interior points to remove (points owned solely by the replaced regions)
        let unfrozen:Set<Regions.Index> = .init(regions.lazy.map{ $0.0 })
        var removals:[Int]              = []
        for (region, _):(Regions.Index, [Marker.Unfrozen]) in regions 
        {
            for marker:Int in self.regions[region]
            {
                assert(self.markers[marker].owners.isSuperset(of: unfrozen))
                
                guard !self.markers[marker].owners.isStrictSuperset(of: unfrozen)
                else 
                {
                    continue 
                }
                
                removals.append(marker)
            }
        }
        
        // sort removals in reversed order so that a sequence of pops gives 
        // indices in ascending order
        removals.sort(by: >)
        
        // remove the points
        let count:Int = self.markers.count - removals.count
        var filtered:[Marker] = []
            filtered.reserveCapacity(count)
        var indices:[Int]     = []
            indices.reserveCapacity(self.markers.count)
        
        for (oldIndex, marker):(Int, Marker) in self.markers.enumerated()
        {
            guard let remove:Int = removals.last 
            else 
            {
                break 
            }
            
            if oldIndex == remove 
            {
                indices.append(-1) 
                removals.removeLast()
            }
            else 
            {
                indices.append(filtered.count) 
                filtered.append(marker)
            }
        }
        
        // replace region indices
        
        self.markers = filtered
    }
}

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
