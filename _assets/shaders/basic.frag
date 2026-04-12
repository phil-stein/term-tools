#version 460 core

out vec4 FragColor;

//passed from vertex-shader
in VS_OUT
{
  vec2 uv_coords;
  vec3 frag_pos;
  vec3 normal;
  mat3 TBN;
} _in;

uniform vec3      tint;
uniform sampler2D tex;
// uniform vec3      light_pos;

void main()
{
  // vec3 obj_color   = texture(tex, _in.uv_coords.xy).rgb; // * vec4(tint.rgb, 1.0);
  // // vec3 obj_color   = vec3( 1.0 ); 
  // vec3 light_color = vec3( 1.0, 1.0, 1.0 );
  //
  // // blinn-phong lighting: Learn OpenGL, page: 119
  // vec3 ambient   = 0.1 * light_color;
  // vec3 normal    = normalize( _in.normal );
  // vec3 light_dir = normalize( light_pos - _in.frag_pos );
  // float diff     = max( dot( normal, light_dir ), 0.0 );
  // vec3 diffuse   = diff * light_color; 
  // // vec3 cell      = length( diffuse ) >= 0.95  ? vec3( 1.0  ) : vec3( 0.65 );
  // // cell           = length( diffuse ) >= 0.9   ? vec3( 0.75 ) : cell;
  // // cell           = length( diffuse ) <  0.5   ? vec3( 0.5  ) : cell;
  // // cell          -= length( diffuse ) <  0.25  ? vec3( 0.2  ) : vec3( 0.0 );
  // vec3 cell      = length( diffuse * 0.75 ) >= 0.9999999 ? vec3( 1.0  ) : 
  //                  length( diffuse * 0.75 ) >= 0.99 ? vec3( 0.85  ) : 
  //                  length( diffuse * 0.75 ) >= 0.75  ? vec3( 0.75 ) : 
  //                  length( diffuse * 0.75 ) >= 0.5   ? vec3( 0.5  ) : 
  //                  length( diffuse * 0.75 ) >= 0.25  ? vec3( 0.25 ) : vec3( 0.1 );
  //
  // vec3 result    = (ambient + diffuse) * obj_color;
  // // vec3 result    = cell * obj_color;
  // FragColor      = vec4( result, 1.0 );
  //
  // // FragColor      = vec4( diffuse, 1.0 );
  // // FragColor      = vec4( cell, 1.0 );


  FragColor = texture(tex, _in.uv_coords.xy) * vec4(tint.rgb, 1.0);
  // FragColor = vec4( _in.uv_coords.xy, 0.0, 1.0 );
  // FragColor = vec4( 1.0 );
  // FragColor = vec4( normalize(_in.normal), 1.0 );
}
