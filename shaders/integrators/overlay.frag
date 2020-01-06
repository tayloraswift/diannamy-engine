#version 330 core

uniform sampler2D   background;
uniform sampler2DMS foreground;
uniform int         samples;

layout(std140) uniform Display 
{
    vec2 viewport;
} display;

out vec4 color;

vec4 textureMS(sampler2DMS sampler, ivec2 s)
{
    vec4 color = vec4(0.0);
    for (int i = 0; i < samples; ++i)
    {
        color += texelFetch(sampler, s, i);
    }
    color /= float(samples);
    return color;
}

void main()
{
    ivec2 s = ivec2(gl_FragCoord.xy);
    vec2  t = gl_FragCoord.xy / display.viewport;
    vec3 bg = texture(background, t).rgb;
    vec4 fg = textureMS(foreground, s);
    color = vec4(bg * (1 - fg.a) + fg.rgb, 1.0);
}
