#version 330 core

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

uniform vec4 sphere;

out vec4 color;

void main()
{
    vec3 ray = normalize((camera.F * vec4(gl_FragCoord.xy, 1, 1)).xyz - camera.position);
    vec3  c  = sphere.xyz - camera.position;
    float l  = dot(c, ray);
    
    float discriminant = sphere.w * sphere.w + l * l - dot(c, c);
    if (discriminant < 0)
    {
        discard;
    }
    
    vec3 near = ray * (l - sqrt(discriminant));
    color = vec4((camera.position + near) * 0.5 + 0.5, 1);
}