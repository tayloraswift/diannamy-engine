#version 330 core

layout(lines_adjacency) in;

in Vertex
{
    float facing;
} vertices[4];

layout(std140) uniform Display 
{
    vec2 frame_a;
    vec2 frame_b;
    vec2 viewport;
} display;

uniform float thickness;

layout(triangle_strip, max_vertices = 6) out;

out Vertex
{
    noperspective float facing;
} geometry;

vec2 screen(vec4 clip)
{
    return vec2(0.5 * clip.xy / clip.w * display.viewport);
}
vec4 clip(vec2 screen)
{
    return vec4(2 * screen / display.viewport, 1, 1);
}


void polyline(const vec2 nodes[4])
{
    float h = thickness * 0.5;
    //                   . nodes[i + 1]
    //  normals[i] ↖   ↗ vectors[i]
    //               ·
    //              nodes[i]

    const vec2 vectors[3] = vec2[]
    (
        normalize(nodes[1] - nodes[0]),
        normalize(nodes[2] - nodes[1]),
        normalize(nodes[3] - nodes[2])
    );

    const vec2 normals[3] = vec2[]
    (
        vec2(-vectors[0].y, vectors[0].x),
        vec2(-vectors[1].y, vectors[1].x),
        vec2(-vectors[2].y, vectors[2].x)
    );

    //             vector
    //               ↑
    //            2 ——— 3
    //            | \   |
    //   normal ← |  \  |
    //            |   \ |
    //            0 ——— ­1
    
    geometry.facing = vertices[1].facing;
    gl_Position = clip(nodes[1] + h * normals[1]);
    EmitVertex();
    gl_Position = clip(nodes[1] - h * normals[1]);
    EmitVertex();
    
    geometry.facing = vertices[2].facing;
    gl_Position = clip(nodes[2] + h * normals[1]);
    EmitVertex();
    gl_Position = clip(nodes[2] - h * normals[1]);
    EmitVertex();
    

    const vec2 miter = normalize(normals[1] + normals[2]);

    // project miter onto normal, then scale it up until the projection is the
    // same size as the normal, so we know how big the full size miter vector is

    const float p = dot(miter, normals[1]);

    if (p == 0)
    {
        EndPrimitive();
        return;
    }

    //           ↗
    // ——————→ ·
    if (dot(vectors[2], normals[1]) > 0)
    {
        gl_Position = clip(nodes[2] - h * normals[2]);
        EmitVertex();
        // only emit miter if it’s a reasonable length
        if (p > 0.75)
        {
            gl_Position = clip(nodes[2] - miter * h / p);
            EmitVertex();
        }
    }
    else
    {
        // only emit miter if it’s a reasonable length
        if (p > 0.75)
        {
            gl_Position = clip(nodes[2] + miter * h / p);
            EmitVertex();
        }
        gl_Position = clip(nodes[2] + h * normals[2]);
        EmitVertex();
    }

    EndPrimitive();
}

void main()
{
    vec2 nodes[4];
    nodes[0] = screen(gl_in[0].gl_Position);
    nodes[1] = screen(gl_in[1].gl_Position);
    nodes[2] = screen(gl_in[2].gl_Position);
    nodes[3] = screen(gl_in[3].gl_Position);

    polyline(nodes);
}
