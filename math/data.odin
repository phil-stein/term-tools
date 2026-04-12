package term_tools_math

import linalg "core:math/linalg/glsl"
import str    "core:strings"
import        "core:fmt"
import        "vendor:glfw"
import gl     "vendor:OpenGL"
// import        "core:prof/spall"
// import tracy  "../external/odin-tracy"

// "typedefs" for linalg/glsl package
vec2 :: linalg.vec2
vec3 :: linalg.vec3
vec4 :: linalg.vec4
mat3 :: linalg.mat3
mat4 :: linalg.mat4

Window_Type :: enum { MINIMIZED, MAXIMIZED, FULLSCREEN };

texture_t :: struct
{
  handle   : u32,
  width    : int,
  height   : int,
  channels : int,

  name   : string,  // @TODO: only needed in debug mode
}

// material_t :: struct
// {
//   albedo_idx       : int,
//   roughness_idx    : int,
//   metallic_idx     : int,
//   normal_idx       : int,
//   emissive_idx     : int,
//
//   uv_tile          : linalg.vec2,
//   uv_offs          : linalg.vec2,
//
//   tint             : linalg.vec3,
//   roughness_f      : f32,
//   metallic_f       : f32,
//   emissive_f       : f32,
//
//   name             : string,  // @TODO: only needed in debug mode
// }

F32_PER_VERT :: ( 3 + 2 + 3 + 3 )  // pos, uvs, normals, tangents
mesh_t :: struct
{
  vao          : u32,
  vbo          : u32,
  vertices_len : int, 
  indices_len  : int, 

  name         : string  // @TODO: only needed in debug mode
}

// cubemap_t :: struct
// {
//   loaded : bool,
//   // name   : string,
//
//   environment : u32,
//   irradiance  : u32,
//   prefilter   : u32,
//   intensity   : f32,
// }

data_t :: struct
{
  delta_t_real      : f32,
  delta_t           : f32,
  total_t           : f32,
  cur_fps           : f32,
  time_scale        : f32,

  window                 : glfw.WindowHandle,
  window_type            : Window_Type,
  window_width           : int,
  window_height          : int,
  monitor                : glfw.MonitorHandle,
  monitor_width          : int,
  monitor_height         : int,
  monitor_size_cm_width  : f32,
  monitor_size_cm_height : f32,
  monitor_dpi_width      : f32,
  monitor_dpi_height     : f32,
  monitor_ppi_width      : f32,
  monitor_ppi_height     : f32,
  vsync_enabled          : bool,

  quad_vao : u32,
  quad_vbo : u32,

  line_mesh : mesh_t,

  basic_shader          : u32,
  quad_shader           : u32,
  mouse_pick_shader     : u32,

  wireframe_mode_enabled : bool,
  
  cam : struct
  {
    pos       : linalg.vec3,
    target    : linalg.vec3,
    pitch_rad : f32, 
    yaw_rad   : f32, 
    view_mat  : linalg.mat4,
    pers_mat  : linalg.mat4,
  },

  text : struct
  {
    atlas_tex_handle  : u32,
    glyph_size        : i32,
    last_draw_calls   : i32,
    draw_calls        : i32,
    font_name         : string,
    draw_solid        : bool,

    shader            : u32,
    baked_shader      : u32,

    mesh              : mesh_t,
  },
  
  // assetm
  texture_arr  : [dynamic]texture_t,

  texture_idxs : struct
  {
    blank               : int,
  },

}
// global struct holding most data about the game, except input
data : data_t =
{
  delta_t_real      = 0.0,
  delta_t           = 0.0,
  total_t           = 0.0,
  cur_fps           = 0.0,
  time_scale        = 1.0,
  
  wireframe_mode_enabled = false,

  cam = 
  {
    // pos       = { 0, 5, -6 },
    pos       = { 0,11.5, -12 },
    target    = {  0, 0, 0 },
    // pitch_rad = -0.4,
    // yaw_rad   = 14.2,
    pitch_rad = -0.78397244,
    yaw_rad   = 14.130187,
  },
}

data_init :: proc()
{
  // spall.SCOPED_EVENT( &spall_ctx, &spall_buffer, #procedure )


  // screen quad 
	quad_verts := [?]f32{ 
	  // pos       // uv 
	  -1.0,  1.0,  0.0, 1.0,
	  -1.0, -1.0,  0.0, 0.0,
	   1.0, -1.0,  1.0, 0.0,

	  -1.0,  1.0,  0.0, 1.0,
	   1.0, -1.0,  1.0, 0.0,
	   1.0,  1.0,  1.0, 1.0
	}

	// screen quad VAO
	gl.GenVertexArrays( 1, &data.quad_vao )
	gl.GenBuffers( 1, &data.quad_vbo )
	gl.BindVertexArray( data.quad_vao )
	gl.BindBuffer( gl.ARRAY_BUFFER, data.quad_vbo);
	gl.BufferData( gl.ARRAY_BUFFER, size_of(quad_verts), &quad_verts, gl.STATIC_DRAW); // quad_verts is 24 long
	gl.EnableVertexAttribArray(0);
	gl.VertexAttribPointer( 0, 2, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 0 )
	gl.EnableVertexAttribArray( 1 )
	gl.VertexAttribPointer( 1, 2, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 2 * size_of(f32) )


  // line mesh ------------------------------------------------------------------------------------

  line_verts := [?]f32 {
    // // pos    uvs  
    // 0, 0, 0,  0, 0, 
    // 0, 1, 0,  0, 0, 

    // pos    uvs    normals   tangents
    0, 0, 0,  0, 0,  0, 0, 0,  0, 0, 0, 
    0, 1, 0,  0, 0,  0, 0, 0,  0, 0, 0, 
  }
  // // const int verts_01_len = 2 * FLOATS_PER_VERT;
  // // mesh_make((f32*)verts_01, (int)verts_01_len, &core_data->line_mesh);
  gl.GenVertexArrays( 1, &data.line_mesh.vao )
  gl.GenBuffers( 1, &data.line_mesh.vbo )
  gl.BindVertexArray( data.line_mesh.vao )
  gl.BindBuffer( gl.ARRAY_BUFFER, data.line_mesh.vbo )
	gl.BufferData( gl.ARRAY_BUFFER, size_of(line_verts), &line_verts, gl.STATIC_DRAW )

  gl.EnableVertexAttribArray( 0 ) // pos
	gl.VertexAttribPointer( 0, 3, gl.FLOAT, gl.FALSE, F32_PER_VERT * size_of(f32), 0 )
	gl.EnableVertexAttribArray( 1 ) // uv
	gl.VertexAttribPointer( 1, 2, gl.FLOAT, gl.FALSE, F32_PER_VERT * size_of(f32), 3 * size_of(f32) )
	gl.EnableVertexAttribArray( 2 ) // normals 
	gl.VertexAttribPointer( 2, 3, gl.FLOAT, gl.FALSE, F32_PER_VERT * size_of(f32), 5 * size_of(f32) )
	gl.EnableVertexAttribArray( 3 ) // tangents 
	gl.VertexAttribPointer( 3, 3, gl.FLOAT, gl.FALSE, F32_PER_VERT * size_of(f32), 8 * size_of(f32) )

  // ----------------------------------------------------------------------------------------------


  data.basic_shader          = shader_make( #load( "../_assets/shaders/basic.vert", string ), 
                                            #load( "../_assets/shaders/basic.frag", string ), "basic_shader" )

  data.quad_shader           = shader_make( #load( "../_assets/shaders/quad.vert", string ), 
                                            #load( "../_assets/shaders/quad.frag", string ), "quad_shader" )

  data.text.shader       = shader_make( #load( "../_assets/shaders/text.vert", string ),
                                        #load( "../_assets/shaders/text.frag", string ), "text_shader" )

  data.text.baked_shader = shader_make( #load( "../_assets/shaders/text_baked.vert", string ),
                                        #load( "../_assets/shaders/text.frag",       string ), "text_baked_shader" )
  
  
}

data_pre_updated :: proc()
{
  @(static) first_frame := true
  // ---- time ----
	data.delta_t_real = f32(glfw.GetTime()) - data.total_t
	data.total_t      = f32(glfw.GetTime())
  data.cur_fps      = 1 / data.delta_t_real
  if ( first_frame ) 
  { data.delta_t_real = 0.016; first_frame = false; } // otherwise dt first frame is like 5 seconds
  data.delta_t = data.delta_t_real * data.time_scale
  
  window_set_title( 
    str.clone_to_cstring( 
      fmt.tprint( "amazing title | fps: ", data.cur_fps, ", vsync: ", data.vsync_enabled ), 
      context.temp_allocator ) 
  )
  
  data.text.last_draw_calls = data.text.draw_calls
  data.text.draw_calls = 0
}

// @NOTE: only gets called in debug mode bc. of the tracking alloc
data_cleanup :: proc()
{
}


