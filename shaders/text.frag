#version 330 core

in Vertex
{
    noperspective vec2 texture;
    vec4 color;
} vertex;

layout(std140) uniform Display 
{
    vec2 viewport;
} display;

uniform sampler2D fontatlas;

out vec4 color;

void main()
{
    color = vec4(vertex.color.rgb, vertex.color.a * texture(fontatlas, vertex.texture).r);
}
