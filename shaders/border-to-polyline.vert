#version 330 core

layout(location = 0) in vec3 position;
layout(location = 1) in int index;

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
    float facing;
} vertex;

void main()
{
    gl_Position   = camera.U * vec4(position, 1);
    
    vertex.facing = dot(position, position - camera.position);
}
