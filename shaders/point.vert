#version 330 core

layout(location = 0) in vec3 position;
layout(location = 1) in int weight;
layout(location = 2) in int index;

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

uniform int preselected;

out Vertex
{
    bool facing;
    vec3 color;
    int  index;
} vertex;

void main()
{
    if (index == preselected)
    {
        vertex.color = vec3(1, 0, 0);
    }
    else 
    {
        vertex.color = mix(vec3(1, 1, 1), vec3(0.2, 0.4, 1), weight * 0.1); 
    }
    
    vec3 normal   = position; // only because these are sphere points
    vertex.facing = dot(camera.position - position, normal) < 0 ? false : true;
    vertex.color  = vertex.facing ? vertex.color : vec3(0.2, 0.2, 0.2);
    vertex.index  = index;
    gl_Position   = camera.U * vec4(position, 1);
}
