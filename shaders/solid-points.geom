#version 330 core

layout(points) in;
layout(triangle_strip, max_vertices = 4) out;

in Vertex
{
    vec4 color;
    bool _facing;
} vertex[1];

out Vertex
{
    noperspective vec4 color;
    noperspective vec2 t;
} geometry;

uniform float radius;

layout(std140) uniform Display 
{
    vec2 viewport;
} display;

vec3 screen(vec4 clip)
{
    return vec3(0.5 * clip.xy / clip.w * display.viewport, clip.z / clip.w);
}
vec4 clip(vec3 screen)
{
    return vec4(2 * screen.xy / display.viewport, screen.z, 1);
}

void main()
{
    if (!vertex[0]._facing) 
    {
        return;
    }
    
    float r = radius + 1;
    vec3 center    = screen(gl_in[0].gl_Position);
    geometry.color = vertex[0].color;
    geometry.t     = vec2(-r, -r); 
    gl_Position    = clip(center + vec3(-r, -r, 0));
    EmitVertex();
    geometry.color = vertex[0].color;
    geometry.t     = vec2( r, -r); 
    gl_Position    = clip(center + vec3( r, -r, 0));
    EmitVertex();
    geometry.color = vertex[0].color;
    geometry.t     = vec2(-r,  r); 
    gl_Position    = clip(center + vec3(-r,  r, 0));
    EmitVertex();
    geometry.color = vertex[0].color;
    geometry.t     = vec2( r,  r); 
    gl_Position    = clip(center + vec3( r,  r, 0));
    EmitVertex();
    
    EndPrimitive();
}
