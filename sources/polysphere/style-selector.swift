extension UI.Style 
{
    struct Selector:Hashable, CustomStringConvertible
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
        
        struct Pattern:CustomStringConvertible
        {
            private(set)
            var levels:[(vector:Bool, level:Level)]
            
            var description:String 
            {
                self.levels.map{ "\($0.vector ? "" : "> ")\($0.level)" }.joined(separator: " ")
            }
            
            var concrete:Selector? 
            {
                guard (self.levels.dropFirst().allSatisfy{ !$0.vector })
                else 
                {
                    return nil 
                }
                return .init(levels: self.levels.map{ $0.level })
            }
        }
        
        private 
        var levels:[Level] 
        
        init() 
        {
            self.levels = []
        }
        
        private 
        init(levels:[Level]) 
        {
            self.levels = levels
        }
        
        mutating 
        func append(_ element:UI.Element) 
        {
            let level:Level = .init(element: type(of: element), 
                classes: element.classes, identifier: element.identifier)
            self.levels.append(level)
        }
        
        static 
        func ~= (pattern:Pattern, selector:Self) -> Bool
        {
            var depth:Int = selector.levels.startIndex 
            outer:
            for (vector, pattern):(Bool, Level) in pattern.levels 
            {
                while depth < selector.levels.endIndex 
                {
                    defer 
                    {
                        depth += 1
                    }
                    
                    if pattern ~= selector.levels[depth] 
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
            
            return true  
        }
        
        var description:String 
        {
            return self.levels.map(String.init(describing:)).joined(separator: " > ")
        }
    }
}

extension UI.Style.Selector:ExpressibleByStringLiteral 
{
    init(stringLiteral:String) 
    {
        do 
        {
            guard let selector:UI.Style.Selector = 
                try UI.Style.Sheet.parse(selectorPattern: stringLiteral).concrete 
            else 
            {
                Log.fatal("selector literal contains descendant combinators")
            }
            
            self = selector 
        }
        catch 
        {
            Log.trace(error: error)
            Log.fatal("failed to parse selector literal")
        }
    }
}
extension UI.Style.Selector.Pattern:ExpressibleByStringLiteral 
{
    init(stringLiteral:String) 
    {
        do 
        {
            self = try UI.Style.Sheet.parse(selectorPattern: stringLiteral) 
        }
        catch 
        {
            Log.trace(error: error)
            Log.fatal("failed to parse selector pattern literal")
        }
    }
}
