struct UI 
{
    enum Event 
    {
        enum Direction 
        {
            case up, down
        }
        
        enum CardinalDirection
        {
            case up, down, left, right
        }
        
        enum Key:Int32
        {
            struct Modifiers 
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

            init(_ keycode:Int32)
            {
                self = .init(rawValue: keycode) ?? .unknown
            }
        }
        
        enum Pass:Comparable 
        {
            case priority 
            case preferred 
            case general
            
            static 
            func < (lhs:Self, rhs:Self) -> Bool 
            {
                switch (lhs, rhs) 
                {
                    case    (.priority, .preferred), 
                            (.priority, .general):
                        return true 
                    case    (.preferred, .general):
                        return true
                    default:
                        return false 
                }
            }
        }
        
        enum Confirmation 
        {
            case primary(Transition)
            case secondary(Transition)
            case key(Key, Key.Modifiers)
            
            static 
            func ~= (confirmation:Self, event:Event) -> Bool 
            {
                switch (confirmation, event) 
                {
                case    (.primary(  let transition1), .primary(  let transition2, let _)), 
                        (.secondary(let transition1), .secondary(let transition2, let _)):
                    return transition1 == transition2 
                
                case    (.key(let key1, let modifiers1), .key(let key2, let modifiers2)):
                    return key1 == key2 && modifiers1 == modifiers2
                default:
                    return false
                }
            }
        }
        
        // buttons 
        case primary(Direction, Vector2<Float>)
        case secondary(Direction, Vector2<Float>)
        
        // cursor 
        case enter(Vector2<Float>) // formerly known as "move"
        case leave 
        
        case scroll(CardinalDirection, Vector2<Float>) 
        
        // key events 
        case key(Key, Key.Modifiers)
        case character(Character)
    }

    

    
    enum Action:UInt8 
    {
        case primary = 1, secondary, tertiary
        
        struct BitVector 
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
        }
    }
}
