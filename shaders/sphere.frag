#version 330 core

#define PI 3.1415926538
#define INV_PI (1.0 / 3.1415926538)
#define INV_2PI (0.5 / 3.1415926538)

layout(std140) uniform Camera
{
    mat4 U;         // P × V
    mat4 V;         // V
    mat3 F;         // F[0 ..< 3]
    vec3 position;  // F[3]
} camera;

uniform vec4 sphere;

uniform sampler2D globetex;

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
    
    vec2 equirectangular = vec2(atan(normal.y, normal.x) * INV_2PI, acos(normal.z) * INV_PI);
    vec3 albedo = texture(globetex, equirectangular).rgb;
    color = vec4(albedo * vec3(max(0, dot(normal, normalize(vec3(1, 1, 1)))) + 0.05), 1);
}
