#version 330 core

in Vertex
{
    vec4 color;
    vec2 t;
} vertex;

out vec4 color;

uniform float radius;

void main()
{
    float d = sqrt(dot(vertex.t, vertex.t));
    color   = vec4(vertex.color.rgb, vertex.color.a * smoothstep(-0.5, 0.5, radius - d));
}
