#version 330 core

layout(points) in;
layout(triangle_strip, max_vertices = 12) out; // 12 vertices = 3 digits

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

uniform vec4 monoFontMetrics;

in Vertex
{
    bool facing;
    vec3 color;
    int  index;
} vertex[1];

out Vertex
{
    noperspective vec3 color;
    noperspective vec2 uv;
} geometry;

vec2 screen(vec4 clip)
{
    return vec2(0.5 * clip.xy / clip.w * vec2(camera.h, camera.k));
}
vec4 clip(vec2 screen)
{
    return vec4(2 * screen / vec2(camera.h, camera.k), 1, 1);
}

void main()
{
    vec2 center = screen(gl_in[0].gl_Position);
    int n       = vertex[0].index;
    float digits[3];
    digits[2] = n % 10;
    n /= 10;
    digits[1] = n % 10;
    n /= 10;
    digits[0] = n % 10;
    
    for (int i = 0; i < 3; ++i)
    {
        vec2 origin = center + vec2(8 + i * monoFontMetrics.w, 8);
        float glyph = ('0' + digits[i]) * monoFontMetrics.z;
        
        gl_Position    = clip(origin + vec2(0, monoFontMetrics.x));
        geometry.color = vertex[0].color;
        geometry.uv    = vec2(glyph, 0);
        EmitVertex();
        
        gl_Position    = clip(origin + vec2(0, monoFontMetrics.y));
        geometry.color = vertex[0].color;
        geometry.uv    = vec2(glyph, 1);
        EmitVertex();

        gl_Position    = clip(origin + monoFontMetrics.wx);
        geometry.color = vertex[0].color;
        geometry.uv    = vec2(glyph + monoFontMetrics.z, 0);
        EmitVertex();
        
        gl_Position    = clip(origin + monoFontMetrics.wy);
        geometry.color = vertex[0].color;
        geometry.uv    = vec2(glyph + monoFontMetrics.z, 1);
        EmitVertex();
    }
    EndPrimitive();
}
