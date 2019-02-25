#version 330 core

layout(lines) in;
layout(triangle_strip, max_vertices = 4) out;

in Vertex
{
    vec2 anchor;
    vec2 offset;
    vec4 color;
} line[2];

layout(std140) uniform Display 
{
    vec2 frame_a;
    vec2 frame_b;
    vec2 viewport;
} display;

layout(std140) uniform Camera
{
    mat4 U;         // P × V
    mat4 V;         // V
    mat3 F;         // F[0 ..< 3]
    vec3 position;  // F[3]
} camera;

out Vertex
{
    noperspective vec2 anchor;
    vec4 color;
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
    vec2 trace = round(screen(camera.U * gl_in[0].gl_Position));
    
    gl_Position     = clip(trace + line[0].offset);
    geometry.anchor = line[0].anchor;
    geometry.color  = line[0].color;
    EmitVertex();
    
    gl_Position     = clip(trace + vec2(line[0].offset.x, line[1].offset.y)); 
    geometry.anchor = vec2(line[0].anchor.x, line[1].anchor.y);
    geometry.color  = line[0].color;
    EmitVertex();
    
    gl_Position     = clip(trace + vec2(line[1].offset.x, line[0].offset.y)); 
    geometry.anchor = vec2(line[1].anchor.x, line[0].anchor.y);
    geometry.color  = line[1].color;
    EmitVertex();

    gl_Position     = clip(trace + line[1].offset);
    geometry.anchor = line[1].anchor;
    geometry.color  = line[1].color;
    EmitVertex();
    
    EndPrimitive();
}
