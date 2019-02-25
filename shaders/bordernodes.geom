#version 330 core

layout(points) in;
layout(triangle_strip, max_vertices = 4) out;

layout(std140) uniform Display 
{
    vec2 frame_a;
    vec2 frame_b;
    vec2 viewport;
} display;

in Vertex
{
    bool facing;
    vec3 color;
    int  index;
} vertex[1];

out Vertex
{
    noperspective vec3 color;
    noperspective vec2 uv;
} geometry;

vec2 screen(vec4 clip)
{
    return vec2(0.5 * clip.xy / clip.w * display.viewport);
}
vec4 clip(vec2 screen)
{
    return vec4(2 * screen / display.viewport, 1, 1);
}

void main()
{
    vec2 center = screen(gl_in[0].gl_Position);
    geometry.color = vertex[0].color;
    geometry.uv    = vec2(-1, -1); 
    gl_Position    = clip(center + vec2(-8, -8));
    EmitVertex();
    geometry.color = vertex[0].color;
    geometry.uv    = vec2( 1, -1); 
    gl_Position    = clip(center + vec2( 8, -8));
    EmitVertex();
    geometry.color = vertex[0].color;
    geometry.uv    = vec2(-1,  1); 
    gl_Position    = clip(center + vec2(-8,  8));
    EmitVertex();
    geometry.color = vertex[0].color;
    geometry.uv    = vec2( 1,  1); 
    gl_Position    = clip(center + vec2( 8,  8));
    EmitVertex();
    
    EndPrimitive();
}
