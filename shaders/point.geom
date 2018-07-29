#version 330 core

layout(points) in;
layout(triangle_strip, max_vertices = 4) out;

layout(std140) uniform Camera
{
    mat4  U;
    mat4  V;
    mat3  F;
    vec3  position;
    
    vec3  a;
    float h;
    vec3  b;
    float k;
} camera;

in Vertex
{
    bool facing;
    vec3 color;
} vertex[1];

out Vertex
{
    noperspective vec3 color;
    noperspective vec2 uv;
} geometry;

vec2 screen(vec4 clip)
{
    return vec2(0.5 * clip.xy / clip.w * vec2(camera.h, camera.k));
}
vec4 clip(vec2 screen)
{
    return vec4(2 * screen / vec2(camera.h, camera.k), 1, 1);
}

void main()
{
    vec3 color  = vertex[0].facing ? vertex[0].color : vec3(0.2, 0.2, 0.2);
    vec2 center = screen(gl_in[0].gl_Position);
    geometry.color = color;
    geometry.uv    = vec2(-1, -1); 
    gl_Position    = clip(center + vec2(-8, -8));
    EmitVertex();
    geometry.color = color;
    geometry.uv    = vec2( 1, -1); 
    gl_Position    = clip(center + vec2( 8, -8));
    EmitVertex();
    geometry.color = color;
    geometry.uv    = vec2(-1,  1); 
    gl_Position    = clip(center + vec2(-8,  8));
    EmitVertex();
    geometry.color = color;
    geometry.uv    = vec2( 1,  1); 
    gl_Position    = clip(center + vec2( 8,  8));
    EmitVertex();
    
    EndPrimitive();
}
