public 
protocol RecursiveError:Swift.Error 
{
    var next:Swift.Error?
    {
        get
    }
    
    static 
    var namespace:String 
    {
        get 
    }
    
    var message:String 
    {
        get 
    }
}
