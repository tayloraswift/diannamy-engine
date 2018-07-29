#version 330 core

layout(location = 0) in vec3 position;

layout(std140) uniform Camera
{
    mat4  U;
    mat4  V;
    mat3  F;
    vec3  position;
    
    vec3  a;
    float h;
    vec3  b;
    float k;
} camera;

out Vertex
{
    vec3 color;
} vertex;

void main()
{
    vertex.color = position; 
    gl_Position  = camera.U * vec4(position, 1);
}
