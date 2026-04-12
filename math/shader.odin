package term_tools_math

import        "core:fmt"
import str    "core:strings"
import gl     "vendor:OpenGL"
import linalg "core:math/linalg/glsl"

handle_act  : u32
tex_idx_act : u32 = 0


shader_make :: proc( vertex_src, fragment_src: string, name := "unnamed", loc := #caller_location ) -> ( handle: u32 )
{
  // Compile vertex shader and fragment shader.
  // Note how much easier this is in Odin than in C++!
  // vertex_shader   := string( #load( "../assets/basic.vert" ) )
  // fragment_shader := string( #load( "../assets/basic.frag" ) )
  // handle, program_ok = gl.load_shaders_source( vertex_shader, fragment_shader )

  // handle, program_ok = gl.load_shaders_source( vertex_src, fragment_src )
  // if ( !program_ok )
  // {
  //   fmt.println( "ERROR: Failed to load and compile shaders: ", name )
  //   panic( "shader comp failed" ) 
  // }

  // fmt.println( "shader loc:", loc )

  vertex_src_cstr := str.clone_to_cstring( vertex_src, context.temp_allocator )
  vert_shader := gl.CreateShader( gl.VERTEX_SHADER )
  gl.ShaderSource( vert_shader, 1, &vertex_src_cstr, nil )
  gl.CompileShader( vert_shader )

  ok : i32 = 0
  info_log : [512]u8
  info_log_len : i32 = 0
  gl.GetShaderiv( vert_shader, gl.COMPILE_STATUS, &ok )
  if ok <= 0
  {
    gl.GetShaderInfoLog( vert_shader, 512, &info_log_len, raw_data(info_log[:]) )
    fmt.println( "ERROR: Failed to load and compile vertex shader: ", name )
    fmt.printfln( "       %s", info_log )
    panic( "shader comp failed" ) 
  }

  fragment_src_cstr := str.clone_to_cstring( fragment_src, context.temp_allocator )
  frag_shader := gl.CreateShader( gl.FRAGMENT_SHADER )
  gl.ShaderSource( frag_shader, 1, &fragment_src_cstr, nil )
  gl.CompileShader( frag_shader )

  gl.GetShaderiv( frag_shader, gl.COMPILE_STATUS, &ok )
  if ok <= 0
  {
    gl.GetShaderInfoLog( frag_shader, 512, &info_log_len, raw_data(info_log[:]) )
    fmt.println( "ERROR: Failed to load and compile fragment shader: ", name )
    fmt.printfln( "       %s", info_log )
    panic( "shader comp failed" ) 
  }

	// link shaders
  shader_program := gl.CreateProgram()
	gl.AttachShader( shader_program, vert_shader )
	gl.AttachShader( shader_program, frag_shader )
	gl.LinkProgram( shader_program )

	// check for linking errors
	gl.GetProgramiv(shader_program, gl.LINK_STATUS, &ok);
  if ok <= 0
  {
		gl.GetProgramInfoLog( shader_program, 512, &info_log_len, raw_data(info_log[:]) )
    fmt.println( "ERROR: Failed to load and compile shader program: ", name )
    fmt.printfln( "       %s", info_log )
    panic( "shader comp failed" ) 
	}

	// free the shaders
	gl.DeleteShader( vert_shader )
	gl.DeleteShader( frag_shader )

  return shader_program
}


shader_use :: #force_inline proc( handle: u32 )
{
  gl.UseProgram( handle )
  handle_act  = handle
  tex_idx_act = 0
}
shader_delete :: #force_inline proc( handle: u32 )
{
	gl.DeleteProgram( handle )
  if handle == handle_act { handle_act = 0; tex_idx_act = 0 }
}
// resete tex_idx_act for the shader_act_... procs
shader_act_reset_tex_idx :: #force_inline proc( )
{
  tex_idx_act = 0
}

// shader set ---------------------------------------------------------------------------------

// shader_set_bool :: #force_inline proc( handle: u32, name: cstring, value: i32 )
shader_set_bool :: #force_inline proc( handle: u32, name: cstring, value: bool )
{
	gl.Uniform1i( gl.GetUniformLocation( handle, name ), i32(value) )
}
// set an integer in the shader
shader_set_i32:: #force_inline proc( handle: u32, name: cstring, value: i32 )
{
	gl.Uniform1i( gl.GetUniformLocation( handle, name ), value )
}
// set a float in the shader
shader_set_f32:: #force_inline proc( handle: u32, name: cstring, value: f32 )
{
	gl.Uniform1f( gl.GetUniformLocation( handle, name ), value )
}
// set a vec2 in the shader
shader_set_vec2_f :: #force_inline proc( handle: u32, name: cstring, x, y: f32 )
{
	gl.Uniform2f( gl.GetUniformLocation( handle, name ), x, y )
}
// set a vec2 in the shader
shader_set_vec2 :: #force_inline proc( handle: u32, name: cstring, v: linalg.vec2 )
{
	gl.Uniform2f( gl.GetUniformLocation( handle, name ), v.x, v.y )
}
// set a vec3 in the shader
shader_set_vec3_f :: #force_inline proc( handle: u32, name: cstring, x, y, z: f32 )
{
	gl.Uniform3f( gl.GetUniformLocation( handle, name ), x, y, z )
}
// set a vec3 in the shader
shader_set_vec3 :: #force_inline proc( handle: u32, name: cstring, v: linalg.vec3 )
{
	gl.Uniform3f( gl.GetUniformLocation( handle, name ), v.x, v.y, v.z )
}
// set a matrix 4x4 in the shader
// shader_set_mat4 :: #force_inline proc( handle: u32, name: cstring, value: linalg.mat4 )
shader_set_mat4 :: #force_inline proc( handle: u32, name: cstring, value: [^]f32 )
{
	// GLint transformLoc = gl.GetUniformLocation( handle, name )
	// gl.UniformMatrix4fv( transformLoc, 1, GL_FALSE, value[0] ) 
  gl.UniformMatrix4fv(gl.GetUniformLocation( handle, name ), 1, gl.FALSE, value )
}
shader_set_mat2_transpose :: #force_inline proc( handle: u32, name : cstring, value : [^] f32) 
{
    gl.UniformMatrix2fv(gl.GetUniformLocation( handle, name ), 1, gl.TRUE, value )
}
shader_set_mat4_transpose :: #force_inline proc( handle: u32, name : cstring, value : [^] f32) {
    gl.UniformMatrix4fv(gl.GetUniformLocation( handle, name ), 1, gl.TRUE, value )
}

shader_bind_texture :: #force_inline proc( handle: u32, name: cstring, tex_handle: u32, tex_idx: u32 )
{
  gl.ActiveTexture( gl.TEXTURE0 + tex_idx )
  gl.BindTexture( gl.TEXTURE_2D, tex_handle )
	gl.Uniform1i( gl.GetUniformLocation( handle, name ), i32(tex_idx) )
}
shader_bind_cube_map :: #force_inline proc( handle: u32, name: cstring, tex_handle: u32, tex_idx: u32 )
{
  gl.ActiveTexture( gl.TEXTURE0 + tex_idx )
  gl.BindTexture( gl.TEXTURE_CUBE_MAP, tex_handle )
	gl.Uniform1i( gl.GetUniformLocation( handle, name ), i32(tex_idx) )
}

// shader act ---------------------------------------------------------------------------------

// shader_act_set_bool :: #force_inline proc( name: cstring, value: i32 )
shader_act_set_bool :: #force_inline proc( name: cstring, value: bool )
{
	gl.Uniform1i( gl.GetUniformLocation( handle_act, name ), i32(value) )
}
// set an integer in the shader
shader_act_set_i32:: #force_inline proc( name: cstring, value: i32 )
{
	gl.Uniform1i( gl.GetUniformLocation( handle_act, name ), value )
}
// set a float in the shader
shader_act_set_f32:: #force_inline proc( name: cstring, value: f32 )
{
	gl.Uniform1f( gl.GetUniformLocation( handle_act, name ), value )
}
// set a vec2 in the shader
shader_act_set_vec2_f :: #force_inline proc( name: cstring, x, y: f32 )
{
	gl.Uniform2f( gl.GetUniformLocation( handle_act, name ), x, y )
}
// set a vec2 in the shader
shader_act_set_vec2 :: #force_inline proc( name: cstring, v: linalg.vec2 )
{
	gl.Uniform2f( gl.GetUniformLocation( handle_act, name ), v.x, v.y )
}
// set a vec3 in the shader
shader_act_set_vec3_f :: #force_inline proc( name: cstring, x, y, z: f32 )
{
	gl.Uniform3f( gl.GetUniformLocation( handle_act, name ), x, y, z )
}
// set a vec3 in the shader
shader_act_set_vec3 :: #force_inline proc( name: cstring, v: linalg.vec3 )
{
	gl.Uniform3f( gl.GetUniformLocation( handle_act, name ), v.x, v.y, v.z )
}
// set a matrix 4x4 in the shader
// shader_act_set_mat4 :: #force_inline proc( name: cstring, value: linalg.mat4 )
shader_act_set_mat4 :: #force_inline proc( name: cstring, value: [^]f32 )
{
	// GLint transformLoc = gl.GetUniformLocation( handle_act, name )
	// gl.UniformMatrix4fv( transformLoc, 1, GL_FALSE, value[0] ) 
  gl.UniformMatrix4fv(gl.GetUniformLocation( handle_act, name ), 1, gl.FALSE, value )
}
shader_act_set_mat2_transpose :: #force_inline proc( name : cstring, value : [^] f32) 
{
    gl.UniformMatrix2fv(gl.GetUniformLocation( handle_act, name ), 1, gl.TRUE, value )
}
shader_act_set_mat4_transpose :: #force_inline proc( name : cstring, value : [^] f32) {
    gl.UniformMatrix4fv(gl.GetUniformLocation( handle_act, name ), 1, gl.TRUE, value )
}

shader_act_bind_cube_map :: #force_inline proc( name: cstring, tex_handle: u32 )
{
  gl.ActiveTexture( gl.TEXTURE0 + tex_idx_act )
  gl.BindTexture( gl.TEXTURE_CUBE_MAP, tex_handle )
	gl.Uniform1i( gl.GetUniformLocation( handle_act, name ), i32(tex_idx_act) )
  tex_idx_act += 1
}
// shader_act_bind_texture :: #force_inline proc( name: cstring, tex_handle: u32, tex_idx: u32 )
shader_act_bind_texture :: #force_inline proc( name: cstring, tex_handle: u32, loc := #caller_location )
{
  gl.ActiveTexture( gl.TEXTURE0 + tex_idx_act )
  gl.BindTexture( gl.TEXTURE_2D, tex_handle )
	gl.Uniform1i( gl.GetUniformLocation( handle_act, name ), i32(tex_idx_act) )
  tex_idx_act += 1

  // fmt.println( #procedure, " called by: ", loc.procedure, " line: ", loc.line, " -> ", loc.file_path )
}
