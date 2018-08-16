struct Assets
{
    enum Libraries 
    {
        static 
        let freetype:FreeType = 
        {
            guard let library:FreeType = FreeType.init() 
            else 
            {
                Log.fatal("failed to initialize freetype library")
            }
            
            return library
        }()
    }
    
    // a basic, grid-based monospace font. good for debug displays, but will probably 
    // not display accents or complex typography well, and some glyphs may be clipped
    struct BasicMonospaceFont 
    {
        struct Metrics 
        {
            let bounds:Math<Int>.V2, 
                advance:Int
        }
        
        let metrics:Metrics, 
            atlas:Array2D<UInt8>
    }
}
