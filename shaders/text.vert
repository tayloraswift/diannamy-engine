#version 330 core

layout(location = 0) in vec2 s;
layout(location = 1) in vec2 t;
layout(location = 2) in vec3 r;
layout(location = 3) in vec4 color;

layout(std140) uniform Display 
{
    vec2 viewport;
} display;

out Vertex
{
    vec2 texture;
    vec4 color;
} vertex;

void main()
{
    gl_Position    = vec4(vec2(1, -1) * (2 * s - display.viewport) / display.viewport, 1, 1);
    vertex.texture = t;
    vertex.color   = color;
}
