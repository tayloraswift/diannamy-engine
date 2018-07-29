#version 330 core

in Vertex
{
    vec3 color;
    vec2 uv;
} vertex;

out vec4 color;

void main()
{
    float eusq = dot(vertex.uv, vertex.uv);
    if (eusq > 1)
    {
        discard;
    }
    
    float alpha = min(smoothstep(1, 0, (eusq - 0.8) * 5), smoothstep(0, 1, (eusq - 0.4) * 5));
    color = vec4(vertex.color, alpha);
}
