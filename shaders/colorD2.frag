#version 330 core

in Vertex
{
    noperspective vec2    hb;
    noperspective float   hr;
    noperspective vec2    i;
    noperspective vec4    color_outer_h;
    noperspective vec4    color_outer_v;
    noperspective vec4    color_inner;
} vertex;

layout(std140) uniform Display 
{
    vec2 viewport;
} display;

out vec4 color;

float signed_distance_ellipse(const vec2 parameters, const vec2 i)
{
    vec2 ab;
    vec2 s;
    if      (i.x == 0) 
    {
        return i.y == 0 ? -0.5 : i.y - parameters.y;
    }
    else if (i.y == 0) 
    {
        return i.x == 0 ? -0.5 : i.x - parameters.x;
    }
    else if (i.y < i.x) 
    {
        s  = i.xy;
        ab = parameters.xy;
    }
    else 
    {
        s  = i.yx;
        ab = parameters.yx;
    }
    
    float m = abs(s.y / s.x);
    float x = ab[0] * ab[1] / length(ab * vec2(m, 1));
    return isnan(x) ? 0.5 : (1 - x / s.x) * length(s);
}

float signed_distance_line(const vec2 line, const vec2 i)
{
    vec2 m = normalize(vec2(-line.y, line.x));
    return dot(i, m);
}

void main()
{
    vec2 range      = max(vertex.hb, vertex.hr);
    vec2 i          = vertex.i * range;
    
    float mask_z    = smoothstep(-0.5, 0.5, signed_distance_line(vertex.hb, vec2(vertex.hr) - i));
    
    float r1        = signed_distance_ellipse(range - vertex.hb,    i);
    float r2        = signed_distance_ellipse(vec2(vertex.hr),      max(i - range + vertex.hr, 0));
    
    vec2 mask_r     = smoothstep(-0.5, 0.5, vec2(r1 == r2 ? -0.5 : r1, r2));
    color           =   mask_z  * ((1 - mask_r.x) * vertex.color_inner + mask_r.x * vertex.color_outer_v) + 
                   (1 - mask_z) * ((1 - mask_r.x) * vertex.color_inner + mask_r.x * vertex.color_outer_h);
    color.a        *= 1 - mask_r.y;
}
