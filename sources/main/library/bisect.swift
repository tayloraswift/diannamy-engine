extension RandomAccessCollection 
{
    // returns an index such that predicate is false for self[..< index] and true 
    // for self[index...]
    func bisect(where predicate:(Element) -> Bool) -> Index 
    {
        var lowerBound:Index = self.startIndex, 
            upperBound:Index = self.endIndex
        
        while lowerBound < upperBound 
        {
            let median:Index = self.index(lowerBound, 
                                offsetBy: self.distance(from: lowerBound, to: upperBound) / 2)
            if predicate(self[median])
            {
                upperBound = median
            }
            else 
            {
                lowerBound = self.index(after: median)
            }
        }
        
        return lowerBound
    }
}
