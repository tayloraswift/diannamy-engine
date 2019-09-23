#version 330 core

in Vertex
{
    vec4 color;
    bool _facing;
} vertex;

out vec4 color;

void main()
{
    color = vertex.color;
}
