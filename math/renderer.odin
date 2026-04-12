package term_tools_math

import        "core:log"
import        "core:math"
import linalg "core:math/linalg/glsl"
import gl     "vendor:OpenGL"
// import        "core:prof/spall"


exposure  :: 1.25


renderer_init :: proc( loc := #caller_location )
{
  // spall.SCOPED_EVENT( &spall_ctx, &spall_buffer, #procedure )
  // log.debug( loc )
  gl.BindFramebuffer( gl.FRAMEBUFFER, 0 )
  gl.Viewport( 0, 0, i32(data.window_width), i32(data.window_height) )
  gl.Enable( gl.DEPTH_TEST )
  // gl.FrontFace( gl.CCW )
  gl.Enable( gl.CULL_FACE )
  gl.CullFace( gl.FRONT )
  
  // opengl state
  // Texture blending options.
  // gl.Disable( gl.BLEND ) // enable blending of transparent texture
  gl.Enable( gl.BLEND )
  gl.BlendFunc( gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA )

  gl.ClearColor( 0.0, 0.0, 0.0, 1.0 )

}

// renderer_update :: proc()
// {
//   // spall.SCOPED_EVENT( &spall_ctx, &spall_buffer, #procedure )
//
//   gl.Clear(gl.COLOR_BUFFER_BIT);
//   gl.Disable(gl.DEPTH_TEST);
//   gl.Disable( gl.CULL_FACE )
//   // gl.Enable(gl.DEPTH_TEST);
//   // gl.Enable( gl.CULL_FACE )
// }

renderer_draw_quad :: proc( pos, scl: linalg.vec2, texture_handle: u32, tint := linalg.vec3{ 1, 1, 1 } )
{
  gl.Disable( gl.CULL_FACE )
  gl.Disable( gl.DEPTH_TEST)

  // -- draw triangle --
  // gl.UseProgram( data.quad_shader )
  shader_use( data.quad_shader )
  gl.BindVertexArray( data.quad_vao )
  // gl.Uniform2f( gl.GetUniformLocation(data.quad_shader, "pos"), pos.x, pos.y )
  // gl.Uniform2f( gl.GetUniformLocation(data.quad_shader, "scl"), scl.x, scl.y )
  shader_act_set_vec2( "pos", pos )
  shader_act_set_vec2( "scl", scl )
  shader_act_set_vec3( "tint", tint )
  
  gl.ActiveTexture( gl.TEXTURE0 )
  gl.BindTexture( gl.TEXTURE_2D, texture_handle )
  // gl.Uniform1i( gl.GetUniformLocation(data.quad_shader, "tex"), 0 )
  shader_act_set_i32( "tex", 0 )

  gl.DrawArrays( gl.TRIANGLES,    // Draw triangles.
                 0,               // Begin drawing at index 0.
                 6 )              // Use 3 indices.

  gl.Enable( gl.CULL_FACE )
  gl.Enable( gl.DEPTH_TEST)
}

