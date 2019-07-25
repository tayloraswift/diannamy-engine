#version 330 core

layout(location = 0) in vec2 screen;
layout(location = 1) in vec2 texture;
layout(location = 2) in vec3 tracer;
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
    gl_Position    = vec4(vec2(1, -1) * (2 * screen - display.viewport) / display.viewport, 1, 1);
    vertex.texture = texture;
    vertex.color   = color;
}
