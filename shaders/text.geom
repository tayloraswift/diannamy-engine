#version 330 core

layout(lines) in;
layout(triangle_strip, max_vertices = 4) out;

in Vertex
{
    vec2 texture;
    vec4 color;
} line[2];

out Vertex
{
    noperspective vec2 texture;
    vec4 color;
} geometry;

void main()
{    
    gl_Position      = gl_in[0].gl_Position;
    geometry.texture = line[0].texture;
    geometry.color   = line[0].color;
    EmitVertex();
    
    gl_Position      = vec4(gl_in[0].gl_Position.x, gl_in[1].gl_Position.y, gl_in[0].gl_Position.z, gl_in[0].gl_Position.w);
    geometry.texture = vec2(line[0].texture.x, line[1].texture.y);
    geometry.color   = line[0].color;
    EmitVertex();
    
    gl_Position      = vec4(gl_in[1].gl_Position.x, gl_in[0].gl_Position.y, gl_in[1].gl_Position.z, gl_in[1].gl_Position.w);
    geometry.texture = vec2(line[1].texture.x, line[0].texture.y);
    geometry.color   = line[1].color;
    EmitVertex();

    gl_Position      = gl_in[1].gl_Position;
    geometry.texture = line[1].texture;
    geometry.color   = line[1].color;
    EmitVertex();
    
    EndPrimitive();
}
