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

             zero = 48, one, two, three, four, five, six, seven, eight, nine,

             f1 = 290, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12,

             space   = 32,
             period  = 46,
             unknown = -1

        init(_ keycode:Int32)
        {
            self = Key.init(rawValue: Int(keycode)) ?? .unknown
        }
    }
    
    enum Action 
    {
        case double, primary, secondary, tertiary
    }
}
