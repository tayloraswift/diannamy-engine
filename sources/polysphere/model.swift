//import GLFW    

struct Borders 
{
    struct Marker 
    {
        enum Selector 
        {
            case exterior(Int), interior(Int)
        }
        
        var location:Location, 
            owners:Set<Regions.Index>
    }
    
    struct Regions:Collection 
    {
        struct Index:Hashable, Comparable
        {
            let value:Int
            init(_ value:Int) 
            {
                self.value = value
            }
            
            static 
            func < (lhs:Index, rhs:Index) -> Bool
            {
                return lhs.value < rhs.value
            }
        }
        
        private 
        var regions:[[Int]]
        
        // Collection conformance
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
        
        var startIndex:Index 
        {
            return .init(0)
        }
        var endIndex:Index 
        {
            return .init(self.regions.count)
        }
        
        func index(after current:Index) -> Index 
        {
            return .init(current.value + 1)
        }
    }
    
    private 
    var markers:[Marker], 
        regions:Regions
    
    // returns indices of markers that belong exclusively to the given set of regions
    func exclusive(to unfrozen:Set<Regions.Index>) -> [Int]
    {
        var indices:[Int] = []
        for r:Regions.Index in unfrozen 
        {
            for m:Int in self.regions[r]
            {
                guard unfrozen.isSuperset(of: self.markers[m].owners)
                else 
                {
                    continue 
                }
                
                indices.append(m)
            }
        }
        
        indices.sort()
        return indices
    }
    
    // returns indices of markers that do not belong exclusively to the given set 
    // of regions. this is not just the complement of `exclusive(to:)`, it includes 
    // points that are not owned by any member of the given set at all 
    func external(to regions:Regions.Index...) -> [Int]
    {
        // find all interior points to remove (points owned solely by the replaced regions)
        let unfrozen:Set<Regions.Index> = .init(regions), 
            removals:[Int]              = self.exclusive(to: unfrozen)
        
        // remove the points
        var iterator:IndexingIterator<[Int]> = removals.makeIterator()
        var remove:Int? = iterator.next()
        
        guard remove != nil 
        else  
        {
            return .init(self.markers.indices)
        }
        
        let count:Int = self.markers.count - removals.count
        var filtered:[Int] = []
            filtered.reserveCapacity(count)
        for m:Int in self.markers.indices
        {
            if m == remove 
            {
                remove = iterator.next()
            }
            else 
            {
                filtered.append(m)
            }
        }
        
        return filtered
    }
    
    mutating 
    func replace(_ replacements:(Regions.Index, [Marker.Selector])..., interiorMarkers:[Marker])
    {
        // find all interior points to remove (points owned solely by the replaced regions)
        let unfrozen:Set<Regions.Index> = .init(replacements.lazy.map{ $0.0 }), 
            removals:[Int]              = self.exclusive(to: unfrozen)
        
        // remove the points
        var iterator:IndexingIterator<[Int]> = removals.makeIterator()
        var remove:Int? = iterator.next()
        
        let count:Int = self.markers.count - removals.count
        var filtered:[Marker] = []
            filtered.reserveCapacity(count + interiorMarkers.count)
        var indices:[Int]     = []
            indices.reserveCapacity(self.markers.count)
        
        for (m, marker):(Int, Marker) in self.markers.enumerated()
        {
            if m == remove 
            {
                indices.append(-1) 
                remove = iterator.next()
            }
            else 
            {
                indices.append(filtered.count) 
                filtered.append(marker)
            }
        }
        
        filtered.append(contentsOf: interiorMarkers)
        self.markers = filtered
        
        // replace region indices
        var index:Regions.Index = self.regions.startIndex 
        while index != self.regions.endIndex 
        {
            if !unfrozen.contains(index)
            {
                self.regions[index] = self.regions[index].map
                { 
                    let new:Int = indices[$0] 
                    assert(new != -1)
                    return new
                }
            }
            
            index = self.regions.index(after: index)
        }
        // replace replaced regions 
        for (r, selectors):(Regions.Index, [Marker.Selector]) in replacements 
        {
            self.regions[r] = selectors.map 
            {
                switch $0 
                {
                    case .interior(let i):
                        return count + i
                    
                    case .exterior(let m):
                        let new:Int = indices[m] 
                        assert(new != -1)
                        return new
                }
            }
        }
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
