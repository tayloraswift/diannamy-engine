#version 330 core

layout(location = 0) in vec2    s;
layout(location = 1) in vec2    hb;
layout(location = 2) in vec3    r;
layout(location = 3) in float   hr;

layout(location = 4) in vec4    color_outer_h;
layout(location = 5) in vec4    color_outer_v;
layout(location = 6) in vec4    color_inner;
layout(location = 7) in vec2    i;

layout(std140) uniform Display 
{
    vec2 viewport;
} display;

out Vertex
{
    vec2    hb;
    float   hr;
    vec2    i;
    vec4    color_outer_h;
    vec4    color_outer_v;
    vec4    color_inner;
} vertex;

void main()
{
    gl_Position = vec4(vec2(1, -1) * (2 * s - display.viewport) / display.viewport, 1, 1);
    vertex.hb            = hb;
    vertex.hr            = hr;
    vertex.i             = i;
    vertex.color_outer_h = color_outer_h;
    vertex.color_outer_v = color_outer_v;
    vertex.color_inner   = color_inner;
}
