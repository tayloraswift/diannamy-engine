#version 330 core

in Vertex
{
    vec4 color;
    float facing;
} vertex;

out vec4 color;

void main()
{
    color = vertex.facing < 0 ? vec4(0, 0, 0, 0) : vertex.color;
}
