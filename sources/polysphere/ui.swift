struct UI 
{
    enum Direction
    {
        case up, down, left, right
    }
    
    enum Key:Int
    {
        struct Modifiers 
        {
            private 
            let bitfield:UInt8 
            
            init<T>(_ bitfield:T) where T:BinaryInteger 
            {
                self.bitfield = .init(truncatingIfNeeded: bitfield)
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
             up,
             
             grave = 96, 
             
             zero = 48, one, two, three, four, five, six, seven, eight, nine,
             
             A = 65, 
             B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z, 

             f1 = 290, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12,

             space   = 32,
             period  = 46,
             unknown = -1

        init(_ keycode:Int32)
        {
            self = Key.init(rawValue: Int(keycode)) ?? .unknown
        }
        
        var isArrowKey:Bool 
        {
            switch self 
            {
            case .right, .left, .up, .down:
                return true 
            default:
                return false
            }
        }
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
