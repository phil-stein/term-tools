package term_tools_math

import        "base:runtime"
import        "core:os"
import        "core:fmt"
import        "core:log"
import        "core:math"
import linalg "core:math/linalg/glsl"
import gl     "vendor:OpenGL"
import tt     "vendor:stb/truetype"


// // ascii chars from 32 to 126
// ATLAS_CHARS := [126 - 32]rune
// ascii chars from 0 to 126
ATLAS_CHARS : [126 +1]rune

glyph_t :: struct
{
  width  : f32,
  height : f32,
  x_offs : f32,
  y_offs : f32,

  bbox_x  : f32,
  bbox_y  : f32,
  advance : f32,
}
glyph_info : [len(ATLAS_CHARS)]glyph_t

// text_init :: proc()
text_init :: proc( path: string )
{
  // dpi_w, dpi_h := window_get_monitor_dpi()
  // font_size := i32( dpi_h / 4.0 )

  // scale based on physical size of monitor being used
  cm_w, cm_h := window_get_monitor_size_cm()
  // font_size := i32( 700 / cm_h )  // 700 is abitrary could be higher or lower
  font_size := i32( 900 / cm_h )  // 700 is abitrary could be higher or lower
  log.debug( "monitor cm_width:", cm_h, ", font_size:", font_size )
  atlas_handle, atlas_w, atlas_h := text_make_atlas( path, font_size )
  // atlas_handle, atlas_w, atlas_h := text_make_atlas( font_size )
}
text_make_atlas :: proc( font_name: string, glyph_size: i32, loc := #caller_location ) -> ( handle: u32, atlas_w, atlas_h: i32 )
{
  // log.debug( loc )

  // @TMP:
  // font_name := "../assets/fonts/JetBrainsMonoNL-Regular.ttf"

  data.text.glyph_size = glyph_size
  data.text.font_name = font_name 

  // set atlas_chars to ascii values
  ascii := 0 
  for &c in ATLAS_CHARS
  {
    c = rune(ascii)
    ascii += 1
  }

  //-------------------------------------------------------------
  //Set up a rectangle to have the character texture drawn on it.
  //-------------------------------------------------------------

  h, w : f32
  h    = f32(glyph_size * 2) 
  w    = f32(glyph_size * 2)
  
  rect_verts : [6 * 4]f32 
  rect_verts = { // rect coords : vec2, texture coords : vec2
    0, h,    0, 0,
    0, 0,    0, 1,
    w, 0,    1, 1,
    0, h,    0, 0,
    w, 0,    1, 1,
    w, h,    1, 0,
  }

  gl.GenVertexArrays(1, &data.text.mesh.vao)
  gl.BindVertexArray(data.text.mesh.vao)

  vbo : u32 
  gl.GenBuffers(1, &vbo)
  gl.BindBuffer(gl.ARRAY_BUFFER, vbo)

  Glyph_texture : u32 
  gl.GenTextures(1, &Glyph_texture)
  gl.BindTexture(gl.TEXTURE_2D, Glyph_texture)
  
  // Describe GPU buffer.
  gl.BufferData(gl.ARRAY_BUFFER, size_of(rect_verts), &rect_verts, gl.STATIC_DRAW)
  log.debug( "size_of(rect_verts):", size_of(rect_verts), ", len(rect_verts):", len(rect_verts) )

  // Position and color attributes. Don't forget to enable!
  gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 0 * size_of(f32))
  gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 2 * size_of(f32))
  
  gl.EnableVertexAttribArray(0)
  gl.EnableVertexAttribArray(1)


  // atlas_w : i32 = glyph_size * len(ATLAS_CHARS) 
  // atlas_h : i32 = glyph_size
  // atlas_w : i32 = glyph_size
  // atlas_h : i32 = glyph_size * len(ATLAS_CHARS) 
  atlas_w = glyph_size
  atlas_h = glyph_size * len(ATLAS_CHARS) 

  pixel_data := make( []byte, atlas_w * atlas_h )
  defer delete( pixel_data )
  for &b in pixel_data { b = 128 }
  log.debug( "atlas sizeof: ", len(pixel_data), "b, ", f32(len(pixel_data)) / 1000, "kb, ", f32(len(pixel_data)) / 1000000, "mb" )

  // Load .ttf file into buffer.
  ttf_buffer :: [1<<23] u8 // Assumes a .ttf file of under 8MB.
  fontdata, succ := os.read_entire_file_from_filename( font_name, context.temp_allocator ) // @TODO: @OPTIMIZATION: use context.temp_allocator, kept crashing on laptop, figure out why, also use this in all funtions where capable
  if !succ 
  {
    log.error("ERROR: Couldn't load font at: ", font_name )
    os.exit(1)
  }
  // fontdata := #load( "../_assets/fonts/JetBrainsMonoNL-Regular.ttf" )
  // defer delete( fontdata ) // allocated in temp_alloc
  font_ptr : [^]u8 = &fontdata[0]

  // Initialize font.
  font : tt.fontinfo
  tt.InitFont(info = &font, data = font_ptr, offset = 0)

  // @OPTIMIZATION: @UNSURE: going over the first 32 ascii chars which arent visible
  pixel_data_pos := 0
  for i in 0 ..< len(ATLAS_CHARS)
  {
    // Find glyph of character to render.
    char_index := tt.FindGlyphIndex(&font, ATLAS_CHARS[i] )

    char_scale : f32 = tt.ScaleForPixelHeight(&font, f32(glyph_size) )

    // Create Bitmap of glyph, and loading width and height.
    bitmap_w, bitmap_h, xo, yo : i32
    glyph_bitmap := tt.GetGlyphBitmap(
        info    = &font,
        scale_x = 0,
        scale_y = char_scale,
        glyph   = char_index,
        width   = &bitmap_w,
        height  = &bitmap_h,
        xoff    = &xo,
        yoff    = &yo,
    )
    // Get bbox values.
    box1, box2, box3, box4 : i32
    tt.GetGlyphBox(&font, char_index, &box1, &box2, &box3, &box4)

    // Get advance and l_bearing.
    raw_advance, raw_l_bearing : i32
    tt.GetGlyphHMetrics(&font, char_index, &raw_advance, &raw_l_bearing)

    // Scale to font size.
    glyph_info[i].bbox_x  = char_scale * f32(box1)
    glyph_info[i].bbox_y  = char_scale * f32(box2)
    glyph_info[i].advance = char_scale * f32(raw_advance)
    // l_bearing       := char_scale * f32(raw_l_bearing)
    // fmt.println( "glyph_info[i].bbox_x:  ", glyph_info[i].bbox_x  ) 
    // fmt.println( "glyph_info[i].bbox_y:  ", glyph_info[i].bbox_y  )
    // fmt.println( "glyph_info[i].advance: ", glyph_info[i].advance, "raw_advance: ", raw_advance )


    // fmt.println( "xo: ", xo )
    // fmt.println( "yo: ", yo )
    glyph_info[i].x_offs = f32(xo)  // f32(glyph_size) // f32(bitmap_w)
    glyph_info[i].y_offs = f32(yo) // f32(glyph_size) // f32(bitmap_h)
    glyph_info[i].width  = f32(bitmap_w)
    glyph_info[i].height = f32(bitmap_h)
    // fmt.println( rune(i), ": x_offs:     ", glyph_info[i].x_offs )
    // fmt.println( rune(i), ": y_offs:     ", glyph_info[i].y_offs )
    // fmt.println( rune(i), ": width:      ", glyph_info[i].width )
    // fmt.println( rune(i), ": height:     ", glyph_info[i].height )
    // fmt.println( rune(i), ": advance:    ", glyph_info[i].advance )
    // fmt.println( rune(i), ": char_scale: ", char_scale )

    // GLYPH_BITMAP_SIZE := int(bitmap_w * bitmap_h)
    // GLYPH_SIZEOF      := glyph_size * glyph_size
    // // OFFS              := i * int(GLYPH_SIZEOF)
    // fmt.println( "bitmap: ", bitmap_w, ", ", bitmap_h, ", GLYPH_BITMAP_SIZE: ", GLYPH_BITMAP_SIZE )
    // fmt.println( "glyph_size: ", glyph_size, ", GLYPH_SIZEOF: ", GLYPH_SIZEOF, ", GLYPH_SIZEOF * len(ATLAS_CHARS): ", GLYPH_SIZEOF * len(ATLAS_CHARS) )
    // fmt.println( "pixel_data_len: ", atlas_w * atlas_h )

    // copy glyph_bitmap into pixel_data
    for rows in 0 ..< bitmap_h
    {
      for px in 0 ..< bitmap_w
      {
        // pixel_data[pixel_data_pos] = 255; 
        pixel_data[pixel_data_pos] = glyph_bitmap[px + (rows * bitmap_w)] 
        pixel_data_pos += 1
      }
      for blank in 0..< glyph_size - bitmap_w
      {
        pixel_data[pixel_data_pos] = 0; pixel_data_pos += 1
      }
    }
    for blank in 0 ..< glyph_size - bitmap_h
    {
      for px in 0 ..< glyph_size
      {
        pixel_data[pixel_data_pos] = 0; pixel_data_pos += 1
      }
    }

  }

  gl.GenTextures( 1, &handle )
  gl.BindTexture( gl.TEXTURE_2D, handle )

  gl.PixelStorei(gl.UNPACK_ALIGNMENT, 1)

  gl.TexImage2D(
      gl.TEXTURE_2D,    // texture type
      0,                // level of detail number (default = 0)
      gl.RED,           // texture format
      atlas_w,          // width
      atlas_h,          // height
      0,                // border, must be 0
      gl.RED,           // pixel data format
      gl.UNSIGNED_BYTE, // data type of pixel data
      &pixel_data[0],   // image data
  )

  // Texture wrapping options.
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
  
  // Texture filtering options.
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

  data.text.atlas_tex_handle = handle
  return
}

text_load_glyph :: proc( font_name: string, char: rune, scale: f32 )
{
  //-------------------------------------------------------------
  //Use stb to load a .ttf font and create a bitmap from it.
  //-------------------------------------------------------------

  // Load .ttf file into buffer.
  ttf_buffer :: [1<<23] u8 // Assumes a .ttf file of under 8MB.
  fontdata, succ := os.read_entire_file(font_name)
  if !succ 
  {
    log.panic("ERROR: Couldn't load font at: ", font_name )
  }
  font_ptr : [^] u8 = &fontdata[0]

  // Initialize font.
  font : tt.fontinfo
  tt.InitFont(info = &font, data = font_ptr, offset = 0)

  // Find glyph of character to render.
  char_index := tt.FindGlyphIndex(&font, char )

  // Create Bitmap of glyph, and loading width and height.
  bitmap_w, bitmap_h, xo, yo : i32
  glyph_bitmap := tt.GetGlyphBitmap(
      info    = &font,
      scale_x = 0,
      scale_y = tt.ScaleForPixelHeight(&font, scale ),
      glyph   = char_index,
      width   = &bitmap_w,
      height  = &bitmap_h,
      xoff    = &xo,
      yoff    = &yo,
  )
  // Memory Leak: the above should be freed with tt.FreeBitmap

  //f.println("bitmap width, height of", CHARACTER, ":", bitmap_w, bitmap_h) // Debug

  //-------------------------------------------------------------
  //Tell the GPU about the data, especially the font texture.
  //-------------------------------------------------------------

  gl.PixelStorei(gl.UNPACK_ALIGNMENT, 1)

  gl.TexImage2D(
      gl.TEXTURE_2D,    // texture type
      0,                // level of detail number (default = 0)
      gl.RED,           // texture format
      bitmap_w,         // width
      bitmap_h,         // height
      0,                // border, must be 0
      gl.RED,           // pixel data format
      gl.UNSIGNED_BYTE, // data type of pixel data
      glyph_bitmap,     // image data
  )

  // Texture wrapping options.
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
  
  // Texture filtering options.
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

}

text_draw_glyph :: proc( pos: linalg.vec2, char: i32 ) 
{
  // Calculate projection matrix.
  render_rect_w , render_rect_h : f32
  render_rect_w = f32(data.window_width) 
  render_rect_h = f32(data.window_height)

  proj_mat := [4] f32 {
      1/render_rect_w, 0,
      0, 1/render_rect_h,
  }
  
  proj_mat_ptr : [^] f32 = &proj_mat[0]

  // // Calculate translation matrix.
  // raw_duration := time.stopwatch_duration(watch)
  // secs := f32(time.duration_seconds(raw_duration))
  // theta := f32(m.PI * secs )
  // radius := f32(0.5)

  // fmt.println( "glyph_info[char].y_offs: ", glyph_info[char].y_offs )
  // pos.y += glyph_info[char].y_offs
  // y_pos_offs := glyph_info[char].y_offs * -0.5
  // y_pos_offs := glyph_info[char].y_offs * -1.0
  // idk why *6
  x_pos_offs :=  2 * ( glyph_info[char].x_offs / f32(data.window_width ) )
  y_pos_offs := -2 * ( glyph_info[char].y_offs / f32(data.window_height) )
  // fmt.println( "x_pos_offs: ", x_pos_offs )
  // fmt.println( "y_pos_offs: ", y_pos_offs )

  translation_mat := [16] f32 {
      1, 0, 0, pos.x + x_pos_offs, // radius * m.cos(theta),
      0, 1, 0, pos.y + y_pos_offs, // radius * m.sin(theta),
      0, 0, 1, 0,
      0, 0, 0, 1,
  }

  trans_mat_ptr : [^] f32 = &translation_mat[0]

  gl.Disable( gl.DEPTH_TEST )

  shader_use( data.text.shader )
  
  // Send matrices to the shader.
  shader_act_set_mat2_transpose( "projection",  proj_mat_ptr )
  shader_act_set_mat4_transpose( "translation", trans_mat_ptr )
  // shader_act_set_i32( "tile_idx", char )
  shader_act_set_f32( "ratio",  f32(1) / f32(len(ATLAS_CHARS)) )
  y_offs := (f32(1) / f32(len(ATLAS_CHARS)) ) * f32(char)
  // y_offs += ( glyph_info[char].y_offs ) * (f32(1) / f32(len(ATLAS_CHARS)) )
  // shader_act_set_vec2_f( "offs",  glyph_info[char].x_offs, y_offs )
  shader_act_set_f32( "offs", y_offs )
  shader_act_set_vec3_f( "color", 1, 1, 1 )
  // fmt.println( "ratio: ", f32(1) / f32(len(ATLAS_CHARS)) )
  shader_act_set_bool( "solid", data.text.draw_solid )
  // log.debug( "data.text.draw_solid:", data.text.draw_solid )

  shader_act_bind_texture( "glyph_texture", data.text.atlas_tex_handle )
  
  gl.BindVertexArray( data.text.mesh.vao )
  // defer gl.BindVertexArray(0)
  gl.DrawArrays( gl.TRIANGLES, 0, 6 )

  gl.Enable( gl.DEPTH_TEST )

  data.text.draw_calls += 1
}

text_draw_string :: proc( str: string, pos: linalg.vec2 ) -> ( str_width: f32 )
{
  _pos := pos
  c_idx : i32 = 0 

  for char in str
  {
    c_idx += 1
    text_draw_glyph( _pos, i32(char) )
    
    _pos.x    += ( glyph_info[c_idx].advance / f32(data.window_width) ) * 2 
    str_width += ( glyph_info[c_idx].advance / f32(data.window_width) ) * 2 

    // fmt.println( "_pos.x: ", _pos.x, ", added: ", glyph_info[c_idx].width / f32(data.window_width) * 6 )
  }

  return str_width
}

text_bake_string :: proc( str: string, _pos: linalg.vec2 ) -> ( text_mesh: mesh_t )
{
  mesh  : mesh_t
  verts : [dynamic]f32
  pos   := _pos
  
  // Calculate projection matrix.
  render_rect_w , render_rect_h : f32
  render_rect_w = f32(data.window_width) 
  render_rect_h = f32(data.window_height)
  
  // proj_mat := mat2{
  proj_mat := [4]f32{
      1/render_rect_w, 0,
      0, 1/render_rect_h,
  }

  // translation_mat := mat4{
  translation_mat := [16]f32 {
      1, 0, 0, pos.x, 
      0, 1, 0, pos.y, 
      0, 0, 1, 0,
      0, 0, 0, 1,
  }

  for char, i in str
  {
    x_pos_offs :=  2 * ( glyph_info[char].x_offs / f32(data.window_width ) )
    y_pos_offs := -2 * ( glyph_info[char].y_offs / f32(data.window_height) )

    x_pos    := pos.x + x_pos_offs
    y_pos    := pos.y + y_pos_offs
    rect_pos := vec2{ x_pos_offs, y_pos_offs } // vec2{ pos.x + x_pos_offs, pos.y + y_pos_offs }

    // @TODO: 
    h := f32(data.text.glyph_size * 2) // f32(1.0)  
    w := f32(data.text.glyph_size * 2) // f32(1.0) 
    // h := f32(1.0)  
    // w := f32(1.0) 
    log.debug( "h:", h, "w:", w )

    // rect_pos  := util_mat4_mul_v( translation_mat, vec4{ x_pos, y_pos, 0, 1 } )
    
    // move to right spot in atlas
    ratio  :=  f32(1) / f32(len(ATLAS_CHARS))
    y_offs := (f32(1) / f32(len(ATLAS_CHARS)) ) * f32(char)
     
    log.debug( "rect_pos: ", rect_pos )
    rect_verts : [6 * 4]f32 
    rect_verts = { // rect coords : vec2, texture coords : vec2
      // pos.x   pos.y             uv.x        uv.y
      // 0,              h + rect_pos.y,   0,          0,
      // 0,              0,                0,          1 * ratio + y_offs,
      // w + rect_pos.x, 0,                1 + y_offs, 1 * ratio + y_offs,
      // 0,              h + rect_pos.y,   0,          0,
      // w + rect_pos.x, 0,                1 + y_offs, 1 * ratio + y_offs,
      // w + rect_pos.x, h + rect_pos.y,   1 + y_offs, 0,

      0, h,   0, 0,
      0, 0,   0, 1,
      w, 0,   1, 1,
      0, h,   0, 0,
      w, 0,   1, 1,
      w, h,   1, 0,
    }

    append_elems( &verts, ..rect_verts[:] )

    pos.x += ( glyph_info[i].advance / f32(data.window_width) ) * 2 
  }

  // gl.GenVertexArrays( 1, &mesh.vao )
  // gl.GenBuffers( 1, &mesh.vbo )
  // gl.BindVertexArray( mesh.vao)
  // defer gl.BindVertexArray( 0 )
  // gl.BindBuffer( gl.ARRAY_BUFFER, mesh.vbo )
	// gl.BufferData( gl.ARRAY_BUFFER, size_of(verts), &verts, gl.STATIC_DRAW); // quad_verts is 24 long
	// gl.EnableVertexAttribArray(0);
	// gl.VertexAttribPointer( 0, 2, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 0 )
	// gl.EnableVertexAttribArray( 1 )
	// gl.VertexAttribPointer( 1, 2, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 2 * size_of(f32) )

  gl.GenVertexArrays(1, &mesh.vao)
  gl.BindVertexArray(mesh.vao)
  vbo : u32 
  gl.GenBuffers(1, &vbo)
  gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
  // Describe GPU buffer.
  gl.BufferData(gl.ARRAY_BUFFER, len(verts) * size_of(f32) /* size_of(verts) */, &verts, gl.STATIC_DRAW)
  // Position and color attributes. Don't forget to enable!
  gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 0 * size_of(f32))
  gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 2 * size_of(f32))
  gl.EnableVertexAttribArray(0)
  gl.EnableVertexAttribArray(1)

  proj_mat_ptr  : [^]f32 = &proj_mat[0]
  trans_mat_ptr : [^]f32 = &translation_mat[0]

  shader_use( data.text.baked_shader )
  // gl.BindVertexArray( data.text.mesh.vao )
  
  // shader_act_set_vec2_f( "pos", 0, 0 )
  // shader_act_set_vec2_f( "scl", 1, 1 )
  // shader_act_set_mat2_transpose( "projection",  ([^]f32)(&proj_mat[0]) )
  // shader_act_set_mat4_transpose( "translation", ([^]f32)(&translation_mat[0]) )
  shader_act_set_mat2_transpose( "projection",  proj_mat_ptr )
  shader_act_set_mat4_transpose( "translation", trans_mat_ptr )
  
  shader_act_set_vec3_f( "color", 1, 1, 1 )
  shader_act_set_bool( "solid", true ) // data.text.draw_solid )
  shader_act_bind_texture( "glyph_texture", data.text.atlas_tex_handle )
  
  gl.DrawArrays( gl.TRIANGLES, 0, i32(len(verts) / 4) )
  data.text.draw_calls += 1

  log.debug( "len(verts):", len(verts), ", len(verts) / 4:", len(verts) / 4, ", size_of(verts):", size_of(verts), ", len(verts) * size_of(f32):", len(verts) * size_of(f32) )

  delete( verts )

  return mesh 
}

// text_draw_glyph :: proc() 
// {
//   // Calculate projection matrix.
//   render_rect_w , render_rect_h : f32
//   render_rect_w = f32(data.window_width) 
//   render_rect_h = f32(data.window_height)
// 
//   proj_mat := [4] f32 {
//       1/render_rect_w, 0,
//       0, 1/render_rect_h,
//   }
//   
//   proj_mat_ptr : [^] f32 = &proj_mat[0]
// 
//   // // Calculate translation matrix.
//   // raw_duration := time.stopwatch_duration(watch)
//   // secs := f32(time.duration_seconds(raw_duration))
//   // theta := f32(m.PI * secs )
//   // radius := f32(0.5)
// 
//   translation_mat := [16] f32 {
//       1, 0, 0, 0, // radius * m.cos(theta),
//       0, 1, 0, 0, // radius * m.sin(theta),
//       0, 0, 1, 0,
//       0, 0, 0, 1,
//   }
// 
//   trans_mat_ptr : [^] f32 = &translation_mat[0]
// 
//   shader_use( data.text_shader )
//   gl.BindVertexArray( data.text_vao )
//   // defer gl.BindVertexArray(0)
//   
//   // Send matrices to the shader.
//   shader_act_set_mat2_transpose( "projection",  proj_mat_ptr )
//   shader_act_set_mat4_transpose( "translation", trans_mat_ptr )
//   
//   gl.DrawArrays(gl.TRIANGLES, 0, 6)
