#version 330 core

layout (location = 0) in vec2 aPos;
layout (location = 1) in vec2 aUV;

out vec2 inUV;

uniform mat2 projection;
uniform mat4 translation;


void main() 
{
  // gl_Position = translation * vec4(projection * xyPos, 0, 1);
  // gl_Position = translation * vec4(xyPos, 0, 1);
  // gl_Position = vec4( (aPos.x * scl.x) + pos.x, (aPos.y * scl.y) + pos.y, 0.0, 1.0 );     
  // gl_Position = vec4( aPos.x, aPos.y, 0.0, 1.0 );     
  gl_Position = translation * vec4(projection * aPos, 0, 1);
  // gl_Position = vec4(projection * aPos, 0, 1);

  //  // TexCoords = aUV;
  //  float uv_y = aUV.y * ratio;
	// // inUV = vec2( aUV.x, ( uv_y * ( tile_idx ) ) ); 
	// inUV = vec2( aUV.x, uv_y + offs ); 
  //
  inUV = aUV;
}
