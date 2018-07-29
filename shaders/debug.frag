#version 330 core

in Vertex
{
    vec3 color;
} vertex;

out vec4 color;

/*
vec3 debugColor(float x)
{
    if (abs(x) > 1)
    {
        return vec3(0, 0, 0.2 * abs(x)); 
    }
    
    if (x < 0)
    {
        return vec3(0, -x, 0); 
    }
    else 
    {
        return vec3(x, 0, 0); 
    }
}
*/

void main()
{
    color = vec4(vertex.color, 1);
}
