#version 330 core

layout(location = 0) in vec3 position;
layout(location = 1) in vec4 color;

layout(std140) uniform Camera
{
    mat4 U;         // P × V
    mat4 V;         // V
    mat3 F;         // F[0 ..< 3]
    vec3 position;  // F[3]
} camera;

out Vertex
{
    vec4 color;
    float _facing;
} vertex;

void main()
{
    vertex.color  = color;
    gl_Position   = camera.U * vec4(position, 1);
    
    vec3 normal   = position; // only because these are sphere points
    vertex._facing = dot(normalize(camera.position - position), normal);
}
