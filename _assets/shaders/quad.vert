
#version 460 core 
	layout (location = 0) in vec2 aPos; 
	layout (location = 1) in vec2 aUV;  

	out vec2 uv_coords;

  uniform vec2 pos;
  uniform vec2 scl;

	void main() 
	{     
		gl_Position = vec4( (aPos.x * scl.x) + pos.x, (aPos.y * scl.y) + pos.y, 0.0, 1.0 );     
		uv_coords = vec2( aUV.x, 1.0 - aUV.y );
	}
