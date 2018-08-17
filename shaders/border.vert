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

// lowest 3 bits encode type information 
//  3       2       1       0
//  [      case     ][ snapped ]
//  
//  0 0 0 = unconfirmed, not snapped 
//  0 0 1 = unconfirmed, snapped 
//  0 1 0 = selected, not snapped 
//  0 1 1 = selected, snapped 
//  1 0 0 = deleted 
//  1 0 1 = deleted 
//  1 1 0 = deleted 
//  1 1 1 = deleted
//
// roughly, bit 0 = snapping, bit 1 = confirmation, bit 2 = deletion
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
    if (index == indicator >> 3)
    {
        int flags = indicator & 0x7;
        switch (flags)
        {
            case 0:
                // unconfirmed, not snapped 
                vertex.color = vec3(0.3, 0.2, 1);
                vertex.index = index;
                break;
            case 1:
                // unconfirmed, snapped 
                vertex.color = vec3(0.5, 0, 1);
                vertex.index = -1;
                break; 
            case 2:
                // selected, not snapped 
                if (index == preselection)
                {
                    vertex.color = vec3(1, 0, 0.5);
                }
                else 
                {
                    vertex.color = vec3(1, 0, 0);
                }
                vertex.index = index;
                break;
            case 3:
                // selected, snapped 
                vertex.color = vec3(0, 0.5, 1);
                vertex.index = -1;
                break;
            
            default:
                // deleted 
                vertex.color = vec3(1, 0.5, 0);
                vertex.index = -2 - index;
        }
    }
    else if (index == preselection)
    {
        vertex.color = vec3(1, 0, 1);
        vertex.index = index;
    }
    else 
    {
        vertex.color = vec3(1, 1, 1); 
        vertex.index = index;
    }
    
    vec3 normal   = position; // only because these are sphere points
    vertex.facing = dot(camera.position - position, normal) < 0 ? false : true;
    vertex.color  = vertex.facing ? vertex.color : vec3(0.2, 0.2, 0.2);
    
    gl_Position   = camera.U * vec4(position, 1);
}
