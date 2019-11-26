#version 330 core

in Vertex
{
    vec4 color;
    float _facing;
} vertex;

out vec4 color;

void main()
{
    color = vertex.color.r < 0.6315 ? vec4(0.4, 0.4, 0.8, 1.0) : vertex.color;
}
