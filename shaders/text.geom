#version 330 core

layout(lines) in;
layout(triangle_strip, max_vertices = 4) out;

in Vertex
{
    vec2 anchor;
    vec4 color;
} line[2];

out Vertex
{
    noperspective vec2 anchor;
    vec4 color;
} geometry;

void main()
{    
    gl_Position     = gl_in[0].gl_Position;
    geometry.anchor = line[0].anchor;
    geometry.color  = line[0].color;
    EmitVertex();
    
    gl_Position     = vec4(gl_in[0].gl_Position.x, gl_in[1].gl_Position.y, gl_in[0].gl_Position.z, gl_in[0].gl_Position.w);
    geometry.anchor = vec2(line[0].anchor.x, line[1].anchor.y);
    geometry.color  = line[0].color;
    EmitVertex();
    
    gl_Position     = vec4(gl_in[1].gl_Position.x, gl_in[0].gl_Position.y, gl_in[1].gl_Position.z, gl_in[1].gl_Position.w);
    geometry.anchor = vec2(line[1].anchor.x, line[0].anchor.y);
    geometry.color  = line[1].color;
    EmitVertex();

    gl_Position     = gl_in[1].gl_Position;
    geometry.anchor = line[1].anchor;
    geometry.color  = line[1].color;
    EmitVertex();
    
    EndPrimitive();
}
