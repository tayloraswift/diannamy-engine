struct UI 
{
    enum Event 
    {
        enum Direction 
        {
            enum D1 
            {
                case up, down
            }
            
            enum D2 
            {
                case up, down, left, right
                
                init(_ d1:D1) 
                {
                    switch d1 
                    {
                    case .up: 
                        self = .up 
                    case .down: 
                        self = .down 
                    }
                }
            }
        }
        
        enum Key:Int32
        {
            struct Modifiers:Equatable
            {
                private 
                let bitfield:UInt8 
                
                init<T>(_ bitfield:T) where T:BinaryInteger 
                {
                    self.bitfield = .init(truncatingIfNeeded: bitfield)
                }
                
                init(shift:Bool = false, control:Bool = false, alt:Bool = false, multi:Bool = false)
                {
                    self.bitfield   = (shift   ? 1 : 0)
                                    | (control ? 1 : 0) << 1
                                    | (alt     ? 1 : 0) << 2
                                    | (multi   ? 1 : 0) << 3
                }
                
                static 
                var none:Self 
                {
                    .init(0)
                }
                
                var shift:Bool 
                {
                    self.bitfield & 1 != 0
                }
                var control:Bool 
                {
                    self.bitfield & 2 != 0
                }
                var alt:Bool 
                {
                    self.bitfield & 4 != 0
                }
                var multi:Bool 
                {
                    self.bitfield & 8 != 0
                }
                
                static 
                func | (lhs:Self, rhs:Self) -> Self 
                {
                    .init(lhs.bitfield | rhs.bitfield)
                }
                
                static 
                func & (lhs:Self, rhs:Self) -> Self 
                {
                    .init(lhs.bitfield & rhs.bitfield)
                }
            }
            
            case esc     = 256,
                 enter,
                 tab,
                 backspace,
                 insert,
                 delete,
                 right,
                 left,
                 down,
                 up
                 
            case grave = 96
                 
            case zero = 48, one, two, three, four, five, six, seven, eight, nine
                 
            case A = 65, 
                 B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z

            case f1 = 290, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12

            case space   = 32
            case period  = 46
            case unknown = -1
            
            var repeatable:Bool 
            {
                switch self 
                {
                case .right, .left, .down, .up:
                    return true 
                default:
                    return false 
                }
            }

            init(_ keycode:Int32)
            {
                self = Self.init(rawValue: keycode) ?? .unknown
            }
        }
        
        // buttons 
        case primary(Direction.D1, Vector2<Float>, doubled:Bool)
        case secondary(Direction.D1, Vector2<Float>, doubled:Bool)
        
        // cursor 
        case cursor(Vector2<Float>)
        
        case scroll(Direction.D2, Vector2<Float>) 
        
        // key events 
        case key(Key, Key.Modifiers)
        case character(Character)
        
        /* case cut 
        case copy 
        case paste(String)
        
        case leave */
        
        /* struct Response  
        {
            var cursor:Cursor       = .arrow
            var clipboard:String?   = nil 
        } */
        
        enum Action 
        {
            case primary(Vector2<Float>, doubled:Bool) 
            case secondary(Vector2<Float>, doubled:Bool)
            case drag(Vector2<Float>)
            case complete(Vector2<Float>)
            case hover(Vector2<Float>)
            
            case scroll(Direction.D2)
            
            case key(Key, Key.Modifiers)
            case character(Character)
            
            case defocus, deactivate, dehover
            
            
            func reflect(vertical h:Float) -> Self 
            {
                switch self 
                {
                case .primary(let s, let doubled):
                    return .primary(.init(s.x, h - s.y), doubled: doubled)
                case .secondary(let s, let doubled):
                    return .secondary(.init(s.x, h - s.y), doubled: doubled)
                case .drag(let s):
                    return .drag(.init(s.x, h - s.y))
                case .complete(let s):
                    return .complete(.init(s.x, h - s.y))
                case .hover(let s):
                    return .hover(.init(s.x, h - s.y))
                
                default:
                    return self
                }
            }
        }
    }
    
    enum Cursor:Hashable
    {
        case arrow 
        case beam
        case crosshair
        case hand 
        case resizeHorizontal
        case resizeVertical
    }
    
    struct State 
    {
        let cursor:Cursor 
    }

    /* struct BitVector 
    {
        private 
        var bitvector:UInt8 
        
        var any:Bool 
        {
            return self.bitvector == 0
        }
        
        init() 
        {
            self.bitvector = 0
        }
        
        subscript(action:Action) -> Bool 
        {
            get 
            {
                return self.bitvector & 1 << (action.rawValue - 1) == 0 
            }
            set(v) 
            {
                if v 
                {
                    self.bitvector |=   1 << (action.rawValue - 1)
                }
                else 
                {
                    self.bitvector &= ~(1 << (action.rawValue - 1))
                }
            }
        }
    } */
}
