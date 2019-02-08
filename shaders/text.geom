#version 330 core

layout(lines) in;
layout(triangle_strip, max_vertices = 4) out;

in Vertex
{
    vec2 uv;
    vec4 color;
} line[2];

out Vertex
{
    noperspective vec2 uv;
    vec4 color;
} geometry;

void main()
{    
    gl_Position = gl_in[0].gl_Position;
    geometry.uv = line[0].uv;
    geometry.color = line[0].color;
    EmitVertex();
    
    gl_Position = vec4(gl_in[0].gl_Position.x, gl_in[1].gl_Position.y, gl_in[0].gl_Position.z, gl_in[0].gl_Position.w);
    geometry.uv = vec2(line[0].uv.x, line[1].uv.y);
    geometry.color = line[0].color;
    EmitVertex();
    
    gl_Position = vec4(gl_in[1].gl_Position.x, gl_in[0].gl_Position.y, gl_in[1].gl_Position.z, gl_in[1].gl_Position.w);
    geometry.uv = vec2(line[1].uv.x, line[0].uv.y);
    geometry.color = line[1].color;
    EmitVertex();

    gl_Position = gl_in[1].gl_Position;
    geometry.uv = line[1].uv;
    geometry.color = line[1].color;
    EmitVertex();
    
    EndPrimitive();
}
