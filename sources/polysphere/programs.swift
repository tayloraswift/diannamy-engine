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
        
        let fraction:Float = Float(font.metrics.advance) / Float(font.atlas.size.x), 
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
            .block("Camera", binding: 1), 
            .float4("sphere"), 
            .texture("globetex", binding: 1)
        ]
    )!
    
    static
    let borderNodes:GL.Program = .create(
        shaders:
        [
            (.vertex  , "shaders/border-to-bordernodes.vert"),
            (.geometry, "shaders/bordernodes.geom"),
            (.fragment, "shaders/bordernodes.frag")
        ],
        uniforms:
        [
            .block("Display", binding: 0), 
            .block("Camera", binding: 1), 
            .int("indicator"), 
            .int("preselection")
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
            .block("Display", binding: 0), 
            .block("Camera", binding: 1), 
            .float("thickness"), 
            .float4("frontColor"), 
            .float4("backColor")
        ]
    )!
    
    static
    let text:GL.Program = .create(
        shaders:
        [
            (.vertex  , "shaders/text.vert"),
            (.geometry, "shaders/text.geom"),
            (.fragment, "shaders/text.frag")
        ],
        uniforms:
        [
            .block("Display", binding: 0), 
            .texture("fontatlas", binding: 2)
        ]
    )!
    
    static
    let tracingText:GL.Program = .create(
        shaders:
        [
            (.vertex  , "shaders/tracingtext.vert"),
            (.geometry, "shaders/tracingtext.geom"),
            (.fragment, "shaders/text.frag")
        ],
        uniforms:
        [
            .block("Display", binding: 0), 
            .block("Camera", binding: 1), 
            .texture("fontatlas", binding: 2)
        ]
    )!
}
