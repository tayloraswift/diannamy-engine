#version 330 core

layout(location = 0) in vec2 anchor;
layout(location = 1) in vec2 offset;
layout(location = 2) in vec4 color;
layout(location = 3) in vec3 point;

out Vertex
{
    vec2 anchor;
    vec2 offset;
    vec4 color;
} vertex;

void main()
{
    gl_Position   = vec4(point, 1); 
    vertex.anchor = anchor;
    vertex.offset = vec2(offset.x, -offset.y);
    vertex.color  = color;
}
