enum Shader
{
    typealias Programs = 
    (
        text:           GPU.Program,
        xo:             GPU.Program,
        
        implicitSphere: GPU.Program, 
        
        colorPoints:    GPU.Program,
        colorLines:     GPU.Program,
        colorTriangles: GPU.Program, 
        
        integrator:
        (
            overlay:GPU.Program,
            highlight:GPU.Program
        )
    )
    
    private static 
    func supervise(_ body:() throws -> GPU.Program) -> GPU.Program
    {
        do 
        {
            return try body()
        }
        catch 
        {
            Log.trace(error: error)
            Log.fatal("failed to compile one or more shader programs")
        }
    }
    
    static 
    func programs() -> Programs
    {
        let programs:Programs 
        programs.text = supervise
        {
            return try .init(
                [
                    (.vertex,   "shaders/text.vert"),
                    (.geometry, "shaders/text.geom"),
                    (.fragment, "shaders/text.frag"),
                ], 
                debugName: "diannamy://engine/shaders/text*")
        }
        programs.xo = supervise
        {
            return try .init(
                [
                    (.vertex,   "shaders/colorD2.vert"),
                    (.fragment, "shaders/colorD2.frag"),
                ], 
                debugName: "diannamy://engine/shaders/colorD2*")
        }
        
        programs.implicitSphere = supervise 
        {
            return try .init(
                [
                    (.vertex,   "shaders/sphere.vert"),
                    (.fragment, "shaders/sphere.vert.frag"),
                ], 
                debugName: "diannamy://engine/shaders/sphere*")
        }
        programs.colorPoints = supervise 
        {
            return try .init(
                [
                    (.vertex,   "shaders/color-vertex.vert"),
                    (.geometry, "shaders/color-vertex.vert.points.geom"),
                    (.fragment, "shaders/color-vertex.vert.points.geom.frag"),
                ], 
                debugName: "diannamy://engine/shaders/color-vertex.points*")
        }
        programs.colorLines = supervise 
        {
            return try .init(
                [
                    (.vertex,   "shaders/color-vertex.vert"),
                    (.geometry, "shaders/color-vertex.vert.polyline.geom"),
                    (.fragment, "shaders/color-vertex.vert.polyline.geom.frag"),
                ], 
                debugName: "diannamy://engine/shaders/color-vertex.polyline*")
        }
        programs.colorTriangles = supervise 
        {
            return try .init(
                [
                    (.vertex,   "shaders/color-vertex.vert"),
                    (.fragment, "shaders/color-vertex.vert.triangles.frag"),
                ], 
                debugName: "diannamy://engine/shaders/color-vertex.triangles*")
        }
        
        
        programs.integrator.overlay = supervise 
        {
            return try .init(
                [
                    (.vertex,   "shaders/integrators/identity.vert"),
                    (.fragment, "shaders/integrators/overlay.frag"),
                ], 
                debugName: "diannamy://engine/shaders/integrators/overlay*")
        }
        programs.integrator.highlight = supervise 
        {
            return try .init(
                [
                    (.vertex,   "shaders/integrators/identity.vert"),
                    (.fragment, "shaders/integrators/highlight.frag"),
                ], 
                debugName: "diannamy://engine/shaders/integrators/highlight*")
        }
        return programs
    }
}
