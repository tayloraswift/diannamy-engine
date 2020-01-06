typealias SwiftFloatingPoint = BinaryFloatingPoint & ExpressibleByFloatLiteral & ElementaryFunctions & SIMDScalar

extension BinaryFloatingPoint 
{
    static 
    var phi:Self 
    {
        (1 + (5 as Self).squareRoot()) / 2
    }
}
