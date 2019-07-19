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
                
                var shift:Bool 
                {
                    return self.bitfield & 1 != 0
                }
                var control:Bool 
                {
                    return self.bitfield & 2 != 0
                }
                var alt:Bool 
                {
                    return self.bitfield & 4 != 0
                }
                var multi:Bool 
                {
                    return self.bitfield & 8 != 0
                }
                
                static 
                func | (lhs:Self, rhs:Self) -> Self 
                {
                    return .init(lhs.bitfield | rhs.bitfield)
                }
                
                static 
                func & (lhs:Self, rhs:Self) -> Self 
                {
                    return .init(lhs.bitfield & rhs.bitfield)
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
        
        enum Pass:Comparable 
        {
            // events will be captured by elements explicitly waiting on a confirmation. 
            // usually, there should not be more than one such element at a time, 
            // often, zero.
            case confirmation 
            
            // events will be captured by local elements (within an active “panel”)
            case local
            // events will be captured by anything else (allowing context switches)
            case global 
            
            static 
            func < (lhs:Self, rhs:Self) -> Bool 
            {
                switch (lhs, rhs) 
                {
                    case    (.confirmation, .local), 
                            (.confirmation, .global):
                        return true 
                    case    (.local, .global):
                        return true
                    default:
                        return false 
                }
            }
        }
        
        enum Confirmation 
        {
            case primary(Direction.D1)
            case secondary(Direction.D1)
            case key(Key, Key.Modifiers)
            
            static 
            func ~= (confirmation:Self, event:Event) -> Bool 
            {
                switch (confirmation, event) 
                {
                case    (.primary(  let transition1), .primary(  let transition2, _)), 
                        (.secondary(let transition1), .secondary(let transition2, _)):
                    return transition1 == transition2 
                
                case    (.key(let key1, let modifiers1), .key(let key2, let modifiers2)):
                    return key1 == key2 && modifiers1 == modifiers2
                default:
                    return false
                }
            }
        }
        
        // buttons 
        case double(Direction.D1, Vector2<Float>)
        case primary(Direction.D1, Vector2<Float>)
        case secondary(Direction.D1, Vector2<Float>)
        
        // cursor 
        case enter(Vector2<Float>) // formerly known as "move"
        case leave 
        
        case scroll(Direction.D2, Vector2<Float>) 
        
        // key events 
        case key(Key, Key.Modifiers)
        case character(Character)
        
        // instructs elements to provide clipboard responses
        case cut 
        case copy 
        case paste(String)
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
