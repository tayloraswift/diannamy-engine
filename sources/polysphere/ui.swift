struct UI 
{
    struct Ray 
    {
        let source:Math<Float>.V3, 
            vector:Math<Float>.V3
    }
    
    enum Action 
    {
        case double, primary, secondary, tertiary
    }
    
    enum Mode 
    {
        case geo, units, global
    }
    
    enum Layer 
    {
        case floating, deep, plane
    }
    
    enum Hit 
    {
        case gate(Mode), local(Int)
    }

    struct Geo 
    {
        struct Anchor 
        {
            let base:Math<Float>.V2, 
                layer:Layer
            
            init(_ base:Math<Float>.V2, layer:Layer)
            {
                self.base  = base 
                self.layer = layer
            }
        }
        
        private 
        var points:[Math<Float>.V3], 
            active:Int, 
            anchor:Anchor?
        
        private 
        var controlplane:ControlPlane
        
        private 
        func probe() -> Hit?
        {
            return .local(0)
        }
        
        private 
        func intersectsFloating(_:Math<Float>.V2) -> Bool 
        {
            return false 
        }
        
        mutating 
        func down(_ position:Math<Float>.V2, action:Action) -> Mode?
        {
            if self.intersectsFloating(position)
            {
                self.layer = .floating
            }
            else 
            {
                let ray:Ray = self.controlplane.ray(position)
                switch action 
                {
                    case .primary, .double:
                        if let anchor:Anchor = self.anchor 
                        {
                            assert(anchor.action == .secondary)
                            // a left-click action applies any move operation if present
                            self.sphere.move(identifier, to: _)
                            break
                        }
                        
                        guard let hit:Hit = self.probe(ray)
                        else 
                        {
                            self.layer = .plane
                            self.controlplane.down(position, .pan)
                        }
                        
                        switch hit 
                        {
                            case .gate(let mode):
                                return mode 
                            
                            case .local(let identifier):
                                self.layer = .deep
                                
                                if action == .double 
                                {
                                    self.active = self.sphere.duplicate(identifier)
                                }
                                else 
                                {
                                    self.active = identifier
                                }
                        }
                    
                    case .secondary:
                        if let anchor:Anchor = self.anchor 
                        {
                            assert(anchor.action == .secondary)
                            // a second right-click clears the move action
                            break
                        }
                        
                        guard let hit:Hit = self.probe(ray)
                        else 
                        {
                            break 
                        } 
                        
                        switch hit 
                        {
                            case .gate(let mode):
                                return mode 
                            
                            case .local(let identifier):
                                if self.layer == .plane
                                {
                                    
                                }
                                self.layer  = .deep
                                self.active = identifier 
                                
                                self.anchor = .init(position, action: .secondary)
                                return nil
                        }
                    
                    case .tertiary:
                        self.layer = .plane
                        self.controlplane.down(position, .pan)
                }
            }
            
            let ray:Ray = self.controlplane.ray(position)
            
            if let anchor:Anchor = self.anchor 
            {
                switch (anchor.layer, action) 
                {
                    case (.plane, .tertiary):
                        
                        
                }
            }
            else 
            {
                
            }
            
            switch action
            {
                case .tertiary:
                    if let  anchor:Anchor = self.anchor, 
                            anchor.layer == .plane 
                    {
                        self.anchor = nil
                        break
                    }
                    
                    self.controlplane.down(position, .pan)
                
                case .primary, .double:
                    if self.intersectsFloating(position)
                    {
                        break
                    }
                    
                    if let  anchor:Anchor = self.anchor, 
                            anchor.layer == .deep
                    {
                        // a left-click action applies any move operation if present
                        self.sphere.move(self.active, to: _)
                        self.anchor = nil
                        break
                    }
                    
                    guard let hit:Hit = self.probe(ray)
                    else 
                    {
                        self.anchor = .init(position, layer: .plane)
                        self.controlplane.down(position, .pan)
                    }
            }
            
            return nil
        }
        
        mutating 
        func up(_ position:Math<Float>.V2, action:Action) 
        {
            switch action
            {
                case .tertiary:
                    self.controlplane.up(position, .pan)
            }
        }
    }
}
