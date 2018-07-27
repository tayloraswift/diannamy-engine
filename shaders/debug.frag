#version 330 core

in Vertex
{
    vec3 color;
} vertex;

layout(std140) uniform Camera
{
    mat4 U;
    mat4 V;
    mat4 F;
    
    // projection parameters 
    vec3 a;
    vec3 b;
    
    // view parameters
    vec3 position;
} camera;

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
    vec3 ray = normalize((camera.F * vec4(gl_FragCoord.xy, 1, 1)).xyz);
    color = vec4(ray, 1);
}
