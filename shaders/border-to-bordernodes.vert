#version 330 core

layout(location = 0) in vec3 position;
layout(location = 1) in int index;

layout(std140) uniform Camera
{
    mat4 U;         // P × V
    mat4 V;         // V
    mat3 F;         // F[0 ..< 3]
    vec3 position;  // F[3]
} camera;

uniform int indicator;
uniform int preselection;

out Vertex
{
    bool facing;
    vec3 color;
    int  index;
} vertex;

void main()
{
    if (index == -1) 
    {
        // new
        vertex.color = vec3(0.3, 0.2, 1);
        vertex.index = -1;
    }
    else if (index == indicator >> 1)
    {
        int flags = indicator & 0x1;
        switch (flags)
        {
            case 0:
                // selected
                vertex.color = vec3(1, 0, 0);
                break;

            default:
                // moving 
                vertex.color = vec3(1, 0.6, 0);
                break;
        }
        
        vertex.index = index;
    }
    else if (index == preselection)
    {
        vertex.color = vec3(1, 0, 1);
        vertex.index = index;
    }
    else 
    {
        vertex.color = vec3(0.5, 0.5, 0.5); 
        vertex.index = index;
    }
    
    vec3 normal   = position; // only because these are sphere points
    vertex.facing = dot(camera.position - position, normal) < 0 ? false : true;
    vertex.color  = vertex.facing ? vertex.color : vec3(0.2, 0.2, 0.2);
    
    gl_Position   = camera.U * vec4(position, 1);
}
