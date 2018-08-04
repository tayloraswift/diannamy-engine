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

uniform int selected;
uniform int preselected;
uniform int snapped;
uniform int deleted;

out Vertex
{
    bool facing;
    vec3 color;
} vertex;

void main()
{
    if (index == selected)
    {
        if (index == preselected)
        {
            vertex.color = vec3(1, 0, 0.5);
        }
        else 
        {
            vertex.color = vec3(1, 0, 0);
        }
    } 
    else if (index == deleted)
    {
        vertex.color = vec3(1, 0.5, 0);
    }
    else if (index == snapped)
    {
        vertex.color = vec3(0, 0.5, 1);
    }
    else if (index == preselected)
    {
        vertex.color = vec3(1, 0, 1);
    }
    else 
    {
        vertex.color = vec3(1, 1, 1); 
    }
    
    vec3 normal   = position; // only because these are sphere points
    vertex.facing = dot(camera.position - position, normal) < 0 ? false : true;
    
    gl_Position   = camera.U * vec4(position, 1);
}
