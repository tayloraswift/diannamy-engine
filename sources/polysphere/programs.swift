import PNG

enum Programs
{
    static 
    let monofont:(metrics:Math<Float>.V4, texture:GL.Texture<UInt8>) = 
    {
        let font:BasicFontAtlas = .init("assets/fonts/SourceCodePro-Medium.otf", size: 16) 
        
        let texture:GL.Texture<UInt8> = .generate()
        texture.bind(to: .texture2d)
        {
            $0.data(font.atlas, layout: .r8, storage: .r8)
            $0.setMagnificationFilter(.nearest)
            $0.setMinificationFilter(.nearest, mipmap: nil)
        }
        
        let fraction:Float = Float(font.metrics.advance) / Float(font.atlas.shape.x), 
            bounds:Math<Float>.V2 = Math.cast(font.metrics.bounds, as: Float.self)
        return ((bounds.x, bounds.y, fraction, Float(font.metrics.advance)), texture)
    }()
    
    
    static
    let sphere:GL.Program = .create(
        shaders:
        [
            (.vertex  , "shaders/sphere.vert"),
            (.fragment, "shaders/sphere.frag")
        ],
        uniforms:
        [
            .block("Camera", binding: 0), 
            .float4("sphere"), 
            .texture("globetex", binding: 1)
        ]
    )!
    static
    let borders:GL.Program = .create(
        shaders:
        [
            (.vertex  , "shaders/border.vert"),
            (.geometry, "shaders/border.geom"),
            (.fragment, "shaders/border.frag")
        ],
        uniforms:
        [
            .block("Camera", binding: 0), 
            .int("indicator"), 
            .int("preselection")
        ]
    )!
    static
    let borderLabels:GL.Program = .create(
        shaders:
        [
            (.vertex  , "shaders/border.vert"),
            (.geometry, "shaders/borderlabel.geom"),
            (.fragment, "shaders/borderlabel.frag")
        ],
        uniforms:
        [
            .block("Camera", binding: 0), 
            .int("indicator"), 
            .int("preselection"), 
            
            .float4("monoFontMetrics"), 
            .texture("monoFontAtlas", binding: 0)
        ]
    )!
    static
    let borderPolyline:GL.Program = .create(
        shaders:
        [
            (.vertex  , "shaders/border-to-polyline.vert"),
            (.geometry, "shaders/polyline.geom"),
            (.fragment, "shaders/polyline.frag")
        ],
        uniforms:
        [
            .block("Camera", binding: 0), 
            .float("thickness"), 
            .float4("frontColor"), 
            .float4("backColor")
        ]
    )!
}
