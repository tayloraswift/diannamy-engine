#version 330 core

in Vertex
{
    vec3 color;
    vec2 uv;
} vertex;

uniform sampler2D monoFontAtlas;

out vec4 color;

void main()
{
    color = vec4(vertex.color, texture(monoFontAtlas, vertex.uv).r);
}
