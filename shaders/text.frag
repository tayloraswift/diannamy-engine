#version 330 core

in Vertex
{
    noperspective vec2 uv;
    vec4 color;
} vertex;

uniform sampler2D fontatlas;

out vec4 color;

void main()
{
    color = vec4(vertex.color.rgb, vertex.color.a * texture(fontatlas, vertex.uv).r);
}
