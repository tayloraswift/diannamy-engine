import PNG

enum Programs
{
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
