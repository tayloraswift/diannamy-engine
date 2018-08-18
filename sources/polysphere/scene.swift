extension UI 
{
    struct View 
    {
        enum Programs
        {
            static 
            let monofont:(metrics:Math<Float>.V4, texture:GL.Texture<UInt8>) = 
            {
                let font:Assets.BasicMonospaceFont = Assets.Libraries.freetype
                    .renderBasicMonospaceFont("assets/fonts/SourceCodePro-Medium.otf", size: 16) 
                
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
            let debug:GL.Program = .create(
                shaders:
                [
                    (.vertex  , "shaders/debug.vert"),
                    (.fragment, "shaders/debug.frag")
                ],
                uniforms:
                [
                    .block("Camera", binding: 0)
                ]
            )!
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
                    .float4("sphere")
                ]
            )!
            static
            let point:GL.Program = .create(
                shaders:
                [
                    (.vertex  , "shaders/point.vert"),
                    (.geometry, "shaders/point.geom"),
                    (.fragment, "shaders/point.frag")
                ],
                uniforms:
                [
                    .block("Camera", binding: 0), 
                    .int("preselected")
                ]
            )!
            static
            let borders:GL.Program = .create(
                shaders:
                [
                    (.vertex  , "shaders/border.vert"),
                    (.geometry, "shaders/point.geom"),
                    (.fragment, "shaders/point.frag")
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
        
        struct Geo 
        {
            struct Borders
            {
                typealias Index = UInt16 
                
                @_fixed_layout
                @usableFromInline 
                struct Vertex 
                {
                    let position:Math<Float>.V3, 
                        id:Int32
                    
                    init(_ position:Math<Float>.V3, id:Int)
                    {
                        self.position = position 
                        self.id       = Int32(truncatingIfNeeded: id)
                    }
                }
                
                private 
                let vao:GL.VertexArray
                private 
                var vvo:GL.Vector<Vertex>, 
                    evo:GL.Vector<Index>
                    
                private 
                var indexSegments:Indices.Segments = .init(fixed: 0 ..< 0, interpolated: 0 ..< 0)
                
                private 
                var indicator:Int32    = -1, 
                    preselection:Int32 = -1
                
                init()
                {
                    self.evo = .generate()
                    self.vvo = .generate()
                    self.vao = .generate()
                    
                    self.vvo.buffer.bind(to: .array)
                    {
                        self.vao.bind().setVertexLayout(.float(from: .float3), .int(from: .int))
                        self.evo.buffer.bind(to: .elementArray)
                        {
                            self.vao.unbind()
                        }
                    }
                }
                
                struct Indices
                {
                    struct Segments 
                    {
                        let fixed:Range<Int>, 
                            interpolated:Range<Int>
                    }
                    
                    let indices:[Index]
                    
                    private 
                    let partition:Int 
                    
                    var segments:Segments
                    {
                        let fixed:Range<Int>        = 0              ..< self.partition, 
                            interpolated:Range<Int> = self.partition ..< indices.count
                        return .init(fixed: fixed, interpolated: interpolated)
                    }
                    
                    init(fixed:[Index], interpolated:[Index]) 
                    {
                        self.partition = fixed.count 
                        self.indices   = fixed + interpolated
                    }
                }
                                
                private static 
                func subdivide(_ loops:[[Math<Float>.V3]], resolution:Float = 0.1) 
                    -> (vertices:[Vertex], indices:Indices)
                {
                    var vertices:[Vertex] = [], 
                        indices:(fixed:[Index], interpolated:[Index]) = ([], []) 
                    for loop:[Math<Float>.V3] in loops
                    {
                        let base:Index = Index(vertices.count) 
                        for j:Int in loop.indices
                        {
                            let i:Int = loop.index(before: j == loop.startIndex ? loop.endIndex : j)
                            // get two vertices and angle between
                            let edge:Math<Math<Float>.V3>.V2 = (loop[i], loop[j])
                            let d:Float     = Math.dot(edge.0, edge.1), 
                                φ:Float     = .acos(d), 
                                scale:Float = 1 / (1 - d * d).squareRoot()
                            // determine subdivisions 
                            let subdivisions:Int = Int(φ / resolution) + 1
                            
                            // push the fixed vertex 
                            indices.fixed.append(Index(vertices.count))
                            vertices.append(.init(edge.0, id: i))
                            // push the interpolated vertices 
                            for s:Int in 1 ..< subdivisions
                            {
                                let t:Float = Float(s) / Float(subdivisions)
                                
                                // slerp!
                                let sines:Math<Float>.V2   = (.sin(φ - φ * t), .sin(φ * t)), 
                                    factors:Math<Float>.V2 = Math.scale(sines, by: scale)
                                
                                let components:Math<Math<Float>.V3>.V2 
                                components.0 = Math.scale(edge.0, by: factors.0) 
                                components.1 = Math.scale(edge.1, by: factors.1) 
                                
                                let interpolated:Math<Float>.V3 = Math.add(components.0, components.1)
                                
                                vertices.append(.init(interpolated, id: i))
                            }
                        }
                        
                        // compute lines-adjacency indices
                        let totalDivisions:Index = Index(vertices.count) - base
                        for primitive:Index in 0 ..< totalDivisions
                        {
                            indices.interpolated.append(base +  primitive    )
                            indices.interpolated.append(base + (primitive + 1) % totalDivisions)
                            indices.interpolated.append(base + (primitive + 2) % totalDivisions)
                            indices.interpolated.append(base + (primitive + 3) % totalDivisions)
                        }
                    }
                    
                    return (vertices, .init(fixed: indices.fixed, interpolated: indices.interpolated))
                }
                
                mutating 
                func rebuild(from scene:inout Controller.Geo.Scene) 
                {
                    if let vertices = scene.vertices.pop()
                    {
                        let (vertices, indices):([Vertex], Indices) = Borders.subdivide([vertices])
                        self.vvo.assign(data: vertices,        in: .array,        usage: .dynamic)
                        self.evo.assign(data: indices.indices, in: .elementArray, usage: .dynamic)
                        
                        self.indexSegments = indices.segments
                    }
                    
                    self.indicator    = Borders.encode(indicator:    scene.indicator)
                    self.preselection = Borders.encode(preselection: scene.preselection)
                }
                
                private static 
                func encode(indicator:(Int, Controller.Geo.Scene.Indicator)?) -> Int32 
                {
                    // lowest 3 bits encode type information 
                    //  3       2       1       0
                    //  [      case     ][ snapped ]
                    //  
                    //  0 0 0 = unconfirmed, not snapped 
                    //  0 0 1 = unconfirmed, snapped 
                    //  0 1 0 = selected, not snapped 
                    //  0 1 1 = selected, snapped 
                    //  1 0 0 = deleted 
                    //  1 0 1 = deleted 
                    //  1 1 0 = deleted 
                    //  1 1 1 = deleted
                    //
                    // roughly, bit 0 = snapping, bit 1 = confirmation, bit 2 = deletion
                    guard let (index, type):(Int, Controller.Geo.Scene.Indicator) = indicator 
                    else 
                    {
                        return -1
                    }
                    
                    let code:Int32
                    switch type 
                    {
                        case .unconfirmed(let snapping):
                            code = 0b00 << 1 | (snapping ? 1 : 0) 
                        
                        case .selected(let snapping):
                            code = 0b01 << 1 | (snapping ? 1 : 0) 
                        
                        case .deleted:
                            code = 0b10 << 1
                    }
                    
                    return Int32(index) << 3 | code
                }
                private static 
                func encode(preselection:Int?) -> Int32 
                {
                    return Int32(preselection ?? -1)
                }
                
                func draw() 
                {
                    Programs.borderPolyline.bind 
                    {
                        $0.set(float:  "thickness", 2)
                        $0.set(float4: "frontColor", (1, 1, 1, 1))
                        $0.set(float4: "backColor",  (1, 1, 1, 0))
                        self.vao.drawElements(self.indexSegments.interpolated, as: .linesAdjacency, indexType: Index.self)
                    }
                    
                    Programs.borders.bind 
                    {
                        $0.set(int: "indicator",    self.indicator)
                        $0.set(int: "preselection", self.preselection)
                        self.vao.drawElements(self.indexSegments.fixed, as: .points, indexType: Index.self)
                    }
                    
                    Programs.borderLabels.bind 
                    {
                        $0.set(int: "indicator",    self.indicator)
                        $0.set(int: "preselection", self.preselection)
                        
                        $0.set(float4: "monoFontMetrics", Programs.monofont.metrics)
                        Programs.monofont.texture.bind(to: .texture2d, index: 0)
                        {
                            self.vao.drawElements(self.indexSegments.fixed, as: .points, indexType: Index.self)
                        }
                    }
                }
            }
            
            struct Globe
            {
                private 
                let vao:GL.VertexArray, 
                    vbo:GL.Buffer<Math<Float>.V3>,
                    ebo:GL.Buffer<Math<UInt8>.V3>

                init()
                {
                    self.ebo = .generate()
                    self.vbo = .generate()
                    self.vao = .generate()

                    let cube:[Math<Float>.V3] =
                    [
                         (-1, -1, -1),
                         ( 1, -1, -1),
                         ( 1,  1, -1),
                         (-1,  1, -1),

                         (-1, -1,  1),
                         ( 1, -1,  1),
                         ( 1,  1,  1),
                         (-1,  1,  1)
                    ]

                    let indices:[Math<UInt8>.V3] =
                    [
                        (0, 2, 1),
                        (0, 3, 2),

                        (0, 1, 5),
                        (0, 5, 4),

                        (1, 2, 6),
                        (1, 6, 5),

                        (2, 3, 7),
                        (2, 7, 6),

                        (3, 0, 4),
                        (3, 4, 7),

                        (4, 5, 6),
                        (4, 6, 7)
                    ]

                    self.vbo.bind(to: .array)
                    {
                        $0.data(cube, usage: .static)

                        self.vao.bind().setVertexLayout(.float(from: .float3))

                        self.ebo.bind(to: .elementArray)
                        {
                            $0.data(indices, usage: .static)
                            self.vao.unbind()
                        }
                    }
                }
                
                func draw()
                {
                    Programs.sphere.bind
                    {
                        $0.set(float4: "sphere", (0, 0, 0, 1))
                        self.vao.drawElements(0 ..< 36, as: .triangles, indexType: UInt8.self)
                    }
                }
            }
            
            private 
            var borders:Borders
            private
            let globe:Globe 
            
            init()
            {
                self.borders = .init()
                self.globe   = .init()
            }
            
            mutating 
            func rebuild(from scene:inout Controller.Geo.Scene) 
            {
                self.borders.rebuild(from: &scene)
            }
            
            func draw()
            {
                GL.enable(.culling)
                
                GL.disable(.multisampling)
                
                GL.enable(.blending)
                GL.blend(.mix)
                self.globe.draw()
                GL.enable(.multisampling)
                GL.blend(.add)
                self.borders.draw()
            }
        }
    }
}
