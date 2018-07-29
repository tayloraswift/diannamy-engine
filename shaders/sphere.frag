#version 330 core

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

uniform vec4 sphere;

out vec4 color;


const float pi = 3.1415926538;

void main()
{
    vec3 ray = normalize(camera.F * vec3(gl_FragCoord.xy, 1));
    vec3  c  = sphere.xyz - camera.position;
    float l  = dot(c, ray);
    
    float discriminant = sphere.w * sphere.w + l * l - dot(c, c);
    if (discriminant < 0)
    {
        discard;
    }
    
    vec3 normal = normalize(camera.position + ray * (l - sqrt(discriminant)) - sphere.xyz);
    color = vec4(0.5 * vec3(max(0, dot(normal, normalize(vec3(1, 1, 1))))), 1);
}
