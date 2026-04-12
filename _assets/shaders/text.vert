#version 330 core

layout (location = 0) in vec2 xyPos;
layout (location = 1) in vec2 aUV;

out vec2 inUV;

uniform mat2  projection;
uniform mat4  translation;
// uniform int   tile_idx;
uniform float ratio;
uniform float offs;
// uniform vec2 offs;

void main() 
{
  gl_Position = translation * vec4(projection * xyPos, 0, 1);
  // TexCoords = aUV;
  float uv_y = aUV.y * ratio;
	// inUV = vec2( aUV.x, ( uv_y * ( tile_idx ) ) ); 
	inUV = vec2( aUV.x, uv_y + offs ); 
}
