#version 330 core

in Vertex
{
    float facing;
} vertex;

uniform vec4 frontColor;
uniform vec4 backColor;

out vec4 color;

void main()
{
    color = vertex.facing < 0 ? frontColor : backColor;
}
