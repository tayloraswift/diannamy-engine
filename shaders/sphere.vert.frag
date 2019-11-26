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

uniform vec3 origin;
uniform float scale;

uniform samplerCube globetex;

out vec4 color;


const float pi = 3.1415926538;

vec4 pixel(vec2 fragment) 
{
    vec3 ray = normalize(camera.F * vec3(fragment, 1));
    vec3  c  = origin - camera.position;
    float l  = dot(c, ray);
    
    float discriminant = scale * scale + l * l - dot(c, c);
    if (discriminant < 0)
    {
        return vec4(0); 
    }
    
    vec3 normal = normalize(camera.position + ray * (l - sqrt(discriminant)) - origin);
    
    //vec2 equirectangular = vec2(atan(normal.y, normal.x) * INV_2PI, acos(normal.z) * INV_PI);
    //vec3 albedo = texture(globetex, normal).rgb;
    vec3 albedo = texture(globetex, normal).a > 0.5 ? vec3(0.5, 0.7, 0.6) : vec3(0.5, 0.6, 0.8);
    return vec4(albedo * vec3(max(0, dot(normal, normalize(vec3(1, 1, 1)))) + 0.05), 1);
}
void main()
{
    vec2 fragments[5];
    fragments[0] = vec2(-0.25, -0.25);
    fragments[1] = vec2( 0.25, -0.25);
    fragments[2] = vec2(-0.25,  0.25);
    fragments[3] = vec2( 0.25,  0.25);
    fragments[4] = vec2( 0,     0);
    
    color = vec4(0, 0, 0, 0);
    for (uint i = 0u; i < 5u; ++i) 
    {
        color += pixel(gl_FragCoord.xy + fragments[i]);
    }
    if (color.a > 0) 
    {
        color.rgb = color.rgb / color.a;
        color.a  /= 5;
    }
}
