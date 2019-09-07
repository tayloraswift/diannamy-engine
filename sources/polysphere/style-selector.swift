extension UI.Style 
{
    struct Path:Hashable, CustomStringConvertible 
    {
        fileprivate 
        var levels:[Selector.Level] 
        
        init() 
        {
            self.levels = []
        }
        
        private 
        init(levels:[Selector.Level]) 
        {
            self.levels = levels
        }
        
        mutating 
        func append(_ element:UI.Element)  
        {
            let level:Selector.Level = .init(element: type(of: element), 
                classes: element.classes, identifier: element.identifier)
            self.levels.append(level)
        }
        func appended(_ element:UI.Element) -> Self 
        {
            var extended:Self = self 
            extended.append(element)
            return extended
        }
        
        var description:String 
        {
            return self.levels.map(String.init(describing:)).joined(separator: " > ")
        }
    }
    struct Selector:CustomStringConvertible
    {
        struct Level:Hashable, CustomStringConvertible
        {
            var element:Any.Type 
            var classes:Set<String>
            var identifier:String?
            
            static 
            let any:Self = .init(element: Any.self, classes: [], identifier: nil)
            
            var description:String 
            {
                let components:(element:String, classes:String, identifier:String)
                if let element:UI.Element.Type = self.element as? UI.Element.Type 
                {
                    components.element = "<\(String(reflecting: element).split(separator: ".").dropFirst().joined(separator: "."))>"
                }
                else
                {
                    components.element = self.classes.isEmpty && self.identifier == nil ? "*" : ""
                }
                
                components.classes = self.classes.map{ ".\($0)" }.joined(separator: "")
                components.identifier = self.identifier.map{ "#\($0)" } ?? ""
                return "\(components.element)\(components.classes)\(components.identifier)"
            }
            
            static 
            func ~= (pattern:Self, level:Self) -> Bool 
            {
                guard   pattern.element == Any.self ||
                        pattern.element == level.element 
                else 
                {
                    return false  
                }
                guard   pattern.classes.isSubset(of: level.classes)
                else 
                {
                    return false 
                }
                if  let expected:String = pattern.identifier
                {
                    guard (level.identifier.map{ $0 == expected }) ?? false 
                    else 
                    {
                        return false 
                    }
                }
                return true 
            }
            
            // Hashable conformance 
            static 
            func == (a:Self, b:Self) -> Bool 
            {
                return a.element == b.element &&
                    a.classes    == b.classes && 
                    a.identifier == b.identifier
            }
            
            func hash(into hasher:inout Hasher) 
            {
                hasher.combine(ObjectIdentifier.init(self.element))
                hasher.combine(self.classes)
                hasher.combine(self.identifier)
            }
        }
        
        private(set)
        var levels:[(vector:Bool, level:Level)]
        
        var description:String 
        {
            self.levels.map{ "\($0.vector ? "" : "> ")\($0.level)" }.joined(separator: " ")
        }
        
        static 
        func ~= (selector:Self, path:Path) -> Bool
        {
            var depth:Int = path.levels.startIndex 
            outer:
            for (vector, level):(Bool, Level) in selector.levels 
            {
                while depth < path.levels.endIndex 
                {
                    defer 
                    {
                        depth += 1
                    }
                    
                    if level ~= path.levels[depth] 
                    {
                        continue outer 
                    }
                    else if !vector
                    {
                        return false 
                    }
                }
                
                return false 
            }
            
            guard depth == path.levels.endIndex
            else 
            {
                if  selector.levels.last?.vector ?? false, 
                    let level:Level = selector.levels.last?.level, 
                    let leaf:Level  = path.levels.last, 
                    level ~= leaf 
                {
                    return true 
                }
                else 
                {
                    return false 
                }
            }
            return true  
        }
    }
}

extension UI.Style.Selector:ExpressibleByStringLiteral 
{
    init(stringLiteral:String) 
    {
        do 
        {
            self = try UI.Style.Sheet.parse(selector: stringLiteral) 
        }
        catch 
        {
            Log.trace(error: error)
            Log.fatal("failed to parse selector literal")
        }
    }
}
