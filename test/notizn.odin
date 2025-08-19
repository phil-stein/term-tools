
package core 

DISABLE_DOCKING :: #config(DISABLE_DOCKING, false )

import im     "../external/odin-imgui"
import        "../external/odin-imgui/imgui_impl_glfw"
import        "../external/odin-imgui/imgui_impl_opengl3"

import        "vendor:glfw"
import gl     "vendor:OpenGL"

import        "core:os"
import        "core:log"
import        "core:fmt"
import        "core:strconv"
import str    "core:strings"
import linalg "core:math/linalg/glsl"
import        "core:reflect"

font     : ^im.Font
font_big : ^im.Font


log_arr : [dynamic]string


ui_init :: proc()
{
	im.CHECKVERSION()
	im.CreateContext()
	io := im.GetIO()
	io.ConfigFlags += {.NavEnableKeyboard, .NavEnableGamepad}
	when !DISABLE_DOCKING 
  {
		io.ConfigFlags += {.DockingEnable}
		io.ConfigFlags += {.ViewportsEnable}
	}


	// im.StyleColorsDark()
  // ui_set_style_dark_default()
  ui_set_style_dark_light()

	imgui_impl_glfw.InitForOpenGL(data.window, true)
	imgui_impl_opengl3.Init("#version 150")

  font     = im.FontAtlas_AddFontFromFileTTF( io.Fonts, "assets/fonts/JetBrainsMonoNL-Regular.ttf", 20 )
  font_big = im.FontAtlas_AddFontFromFileTTF( io.Fonts, "assets/fonts/JetBrainsMonoNL-Regular.ttf", 24 )
  im.FontAtlas_Build( io.Fonts )
  // im.PushFont( font )

}

// @TODO: this dont work too good
win_flags : im.WindowFlags = { im.WindowFlag.NoTitleBar }
// p_open := true
ui_update :: proc()
{
	imgui_impl_opengl3.NewFrame()
	imgui_impl_glfw.NewFrame()
	im.NewFrame()

	if data.editor_ui.show_demo { im.ShowDemoWindow() }

  im.DockSpaceOverViewport( 0, im.GetMainViewport(), { im.DockNodeFlag.PassthruCentralNode } )

  // log.debug( im.IsAnyItemFocused() )
  // log.debug( im.IsMouse() )
  // im.IsMouseHoveringAnyWindow()

  if data.editor_ui.show_main { ui_main_win() }

  ui_tool_win()

  ui_cmd_log_win()
  ui_cmd_win()

	im.Render()
	display_w, display_h := glfw.GetFramebufferSize(data.window)
	// gl.Viewport(0, 0, display_w, display_h)
	// gl.ClearColor(0, 0, 0, 1)
	// gl.Clear(gl.COLOR_BUFFER_BIT)
	imgui_impl_opengl3.RenderDrawData(im.GetDrawData())

	when !DISABLE_DOCKING {
		backup_current_window := glfw.GetCurrentContext()
		im.UpdatePlatformWindows()
		im.RenderPlatformWindowsDefault()
		glfw.MakeContextCurrent(backup_current_window)
	}
}

ui_cleanup :: proc()
{
	imgui_impl_glfw.Shutdown()
	imgui_impl_opengl3.Shutdown()
	im.DestroyContext()
}

ui_display_texture :: proc( name: cstring, w, h, hover_w, hover_h: f32, handle: u32, no_name := false )
{
  if !no_name { im.Text( name ) }
  im.Image( im.TextureID(uintptr(handle)), im.Vec2{ w, h }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
  if im.BeginItemTooltip( )
  {
    im.Image( im.TextureID(uintptr(handle)), im.Vec2{ hover_w, hover_h }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
    im.EndTooltip()
  }
}
@(BUG="cock")
ui_display_2_texture :: proc( name_00: cstring, w_00, h_00, hover_w_00, hover_h_00: f32, handle_00: u32,
                              name_01: cstring, w_01, h_01, hover_w_01, hover_h_01: f32, handle_01: u32, no_name := false )
{
  if !no_name 
  { 
    im.Text( name_00 ) 
    im.SameLine()
    im.Text( name_01 ) 
  }
  im.Image( im.TextureID(uintptr(handle_00)), im.Vec2{ w_00, h_00 }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )


  if im.BeginItemTooltip( )
  {
    im.Image( im.TextureID(uintptr(handle_00)), im.Vec2{ hover_w_00, hover_h_00 }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
    im.EndTooltip()
  }
  im.SameLine()

  im.Image( im.TextureID(uintptr(handle_01)), im.Vec2{ w_01, h_01 }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
  if im.BeginItemTooltip( )
  {
    im.Image( im.TextureID(uintptr(handle_01)), im.Vec2{ hover_w_01, hover_h_01 }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
    im.EndTooltip()
  }
}

@(NOTE="hey there")

@(TODO="hello, world! :)")
ui_cmd_log_win :: #force_inline proc()
{
// @(TMP="aka. temp")
  if im.Begin( "log" )
  {
    for entry in log_arr
    {
      c_str, err := str.clone_to_cstring( entry, context.temp_allocator )
      im.Text( c_str )
    }
    im.End()
  }
}
ui_cmd_win :: #force_inline proc()
{
  quad_size :: linalg.vec2{ 0.25, -0.25 }
  renderer_draw_quad( linalg.vec2{ -0.00, -0.15 }, linalg.vec2{ 0.50, 0.20 }, data.texture_arr[data.texture_idxs.blank].handle, linalg.vec3{ 0, 0, 0 } )
  text_draw_string( fmt.tprintf( "cock cock" ), vec2{ -0.00, -0.15 } )
}

ui_tool_win :: #force_inline proc()
{
  if im.Begin( "tools" )
  {
    input.mouse_over_ui = im.IsWindowHovered()  

    im.Text( "cock" )
    
    if im.Button( "reset" )
    {
      data.player_chars_current = -1

      for &char in data.player_chars
      {
        for &p in char.paths_arr
        { clear( &p ) }
        // { delete( p ) }
        clear( &char.paths_arr )
        // delete( char.paths_arr )
      }
    }

    if im.BeginCombo( "style", fmt.ctprint( "style: ", data.editor_ui.style ) )
    {
      // @UNSURE: ayo these enums are unnanmed wtf do i call them when i cant implicitly use them ???
      if im.Selectable( fmt.ctprint( "dark default" ), data.editor_ui.style != .DARK_DEFAULT )
      {
        data.editor_ui.style = .DARK_DEFAULT
        ui_set_style_dark_default()
      }
      if im.Selectable( fmt.ctprint( "dark light" ), data.editor_ui.style != .DARK_LIGHT )
      {
        data.editor_ui.style = .DARK_LIGHT
        ui_set_style_dark_light()
      }

      im.EndCombo()
    }

    im.End()
  }
}

ui_main_win :: #force_inline proc()
{
  if im.Begin( "window", nil,  win_flags ) 
  {
    input.mouse_over_ui = im.IsWindowHovered() // @UNSURE: flag should prob. be in data ???  

    map_tab, entities_tab, player_chars_tab, framebuffers_tab, assetm_tab, data_tab : bool
    if im.BeginTabBar( "tabs" )
    {
      if im.BeginTabItem( "map" )
      {
        map_tab = true
        im.EndTabItem()
      }
      if im.BeginTabItem( "entities" )
      {
        entities_tab = true
        im.EndTabItem()
      }
      if im.BeginTabItem( "player_chars" )
      {
        player_chars_tab = true
        im.EndTabItem()
      }
      if im.BeginTabItem( "assetm" )
      {
        assetm_tab = true
        im.EndTabItem()
      }
      if im.BeginTabItem( "data" )
      {
        data_tab = true
        im.EndTabItem()
      }
      im.EndTabBar()
    }
    im.SameLine()
    if im.Button( "undock" )
    {
      if im.WindowFlag.NoTitleBar in win_flags
      {
        /* win_flags = win_flags | { im.WindowFlag.NoDocking } */
        win_flags = win_flags - { im.WindowFlag.NoTitleBar }
      }
      else 
      {
        win_flags = win_flags + { im.WindowFlag.NoTitleBar }
      }

      fmt.println( "win_flags: ", win_flags )
      im.SetWindowPos( im.Vec2{ 0, 0 } )
    }
    // im.SameLine()
    // is_collapsed := im.IsWindowCollapsed()
    // if im.Button( is_collapsed ? "V" : "X" )
    // {
    //   im.SetWindowCollapsed( !is_collapsed ) 
    // }

    im.Separator()

    if      map_tab          { ui_map_tab()          }
    else if entities_tab     { ui_entity_tab()       }
    else if player_chars_tab { ui_player_chars_tab() }
    else if assetm_tab       { ui_assetm_tab()       }
    else if data_tab         { ui_data_tab()         }
    // else if framebuffers_tab { ui_framebuffer_tab()  }
	}
	im.End()
}

ui_entity_tab :: proc()
{
  im.SeparatorText( "reflected" )
  ui_display_any( data.entity_arr, "data.entity_arr" )
  im.SeparatorText( "" )

  // // if im.TreeNode("data.entity_arr" )
  // if im.CollapsingHeader( "data.entity_arr" )
  // {
  for &e, i in data.entity_arr
  {
    if i == 0
    {
      im.Text( " | data.entity_arr[0] is invalid |" )
      im.Text( " |  -> this is hacky fix this    |" )
      continue
    }

    // tree_id_string := fmt.tprintf( "entity-tree: %d", i )
    // tree_id_string_cstr := str.clone_to_cstring( tree_id_string, context.temp_allocator )
    // if im.TreeNodeStr(tree_id_string_cstr, "data.entity_arr[%d]", i )
    tree_id_string := fmt.tprintf( "data.entity_arr[%d]", i )
    tree_id_string_cstr := str.clone_to_cstring( tree_id_string, context.temp_allocator )
    if im.CollapsingHeader( tree_id_string_cstr )
    {
      debug_draw_sphere( e.pos, linalg.vec3{ 0.2, 0.2, 0.2 }, linalg.vec3{ 1, 1, 1 } )

      im.Text( "entity_idx:      %d", i )

      im.SeparatorText( "transform" )

      // im.SliderFloat3( "pos", (^[3]f32)(&e.pos), -100, 100 )
      // im.InputFloat3(  "pos", (^[3]f32)(&e.pos) )
      im.DragFloat3(  "pos", (^[3]f32)(&e.pos) )
      // im.SliderFloat3( "rot", (^[3]f32)(&e.rot), -360, 360 )
      // im.InputFloat3(  "rot", (^[3]f32)(&e.rot) )
      im.DragFloat3( "rot", (^[3]f32)(&e.rot) )
      // im.SliderFloat3( "scl", (^[3]f32)(&e.scl), -100, 100 )
      // im.InputFloat3(  "scl", (^[3]f32)(&e.scl) )
      im.DragFloat3(  "scl", (^[3]f32)(&e.scl), 0.5 )

      im.Separator()

      // im.TreePop()
    }
  }
  // }
}
ui_player_chars_tab :: proc()
{
  im.SeparatorText( "reflected" )
  ui_display_any( data.player_chars, "data.player_chars" )
  ui_display_any( data.player_chars, "data.enemy_chars" )
  im.SeparatorText( "" )

  im.Text( "data.player_chars_current: %d", data.player_chars_current )
  // // if im.TreeNode( "data.player_chars" )
  // if im.CollapsingHeader( "data.player_chars" )
  // {
  for char, i in data.player_chars
  {
    if char.entity_idx > 0
    {
      // tree_id_string      := fmt.tprintf( "player-chars-tree: %d", i )
      // tree_id_string_cstr := str.clone_to_cstring( tree_id_string, context.temp_allocator )
      // if im.TreeNodeExStr( tree_id_string_cstr, { im.TreeNodeFlag. } "data.player_chars[%d]", i )

      tree_id_string      := fmt.tprintf( "data.player_chars[%d]", i )
      tree_id_string_cstr := str.clone_to_cstring( tree_id_string, context.temp_allocator )
      if im.CollapsingHeader( tree_id_string_cstr )
      {
        im.Text( "entity_idx:      %d", char.entity_idx )
        im.Text( "halo_entity_idx: %d", char.halo_entity_idx )
        // im.Text( "has_path:        %d", char.has_path )
        im.Text( "path_len:        %d", len(char.paths_arr) )

        // im.TreePop()
      }
    }
  }
  // }

}

level_combo_selected_idx := 0
ui_map_tab :: proc()
{
  im.SeparatorText( "reflected" )
  ui_display_any( data.tile_str_arr, "data.tile_str_arr" )
  ui_display_any( data.tile_type_arr, "data.tile_type_arr" )
  ui_display_any( data.tile_entity_id_arr, "data.tile_entity_id_arr" )
  im.SeparatorText( "" )

  tile_strs   := [?]cstring{ "empty", "blocked", "tile", "ramp_forward", "ramp_backward", "ramp_left", "ramp_right", "spring", "box" }
  id_strs     := [?]cstring{ " ", "-", "X", "^", "v", "<", ">", "O", "#" }
  id_strs_idx := 0
  selected    := false

  level := level_combo_selected_idx

  if im.BeginCombo( "level", fmt.ctprint( "level: ", level ))
  {
    for idx in 0 ..< TILE_LEVELS_MAX
    {
      is_selected := level == idx

      if im.Selectable( fmt.ctprint(idx), is_selected )
      { 
        level_combo_selected_idx = idx
        level = idx 
      }

      // Set the initial focus when opening the combo (scrolling + keyboard navigation focus)
      if is_selected 
      { im.SetItemDefaultFocus() }
    }
    im.EndCombo()
  }
  for z := TILE_ARR_Z_MAX -1; z >= 0; z -= 1
  {
    for x := TILE_ARR_X_MAX -1; x >= 0; x -= 1
    {
      if x != TILE_ARR_X_MAX -1 { im.SameLine() }
      
      im.PushID( str.clone_to_cstring( fmt.tprint( z * TILE_ARR_X_MAX + x ), context.temp_allocator ) )
      
      switch data.tile_type_arr[level][x][z]
      {
        case Tile_Nav_Type.EMPTY:
        {
          id_strs_idx = 0
          selected = false
        }
        case Tile_Nav_Type.BLOCKED:
        {
          id_strs_idx = 1
          selected = false
        }
        case Tile_Nav_Type.TRAVERSABLE:
        {
          id_strs_idx = 2 
          selected = true 
        }
        case Tile_Nav_Type.RAMP_FORWARD:
        {
          id_strs_idx = 3 
          selected = true 
        }
        case Tile_Nav_Type.RAMP_BACKWARD:
        {
          id_strs_idx = 4 
          selected = true 
        }
        case Tile_Nav_Type.RAMP_LEFT:
        {
          id_strs_idx = 5 
          selected = true 
        }
        case Tile_Nav_Type.RAMP_RIGHT:
        {
          id_strs_idx = 6 
          selected = true 
        }
        case Tile_Nav_Type.SPRING:
        {
          id_strs_idx = 7
          selected = false
        }
        case Tile_Nav_Type.BOX:
        {
          id_strs_idx = 8
          selected = false
        }
      }
      im.PushStyleVarImVec2( im.StyleVar.SelectableTextAlign, im.Vec2{ 0.5, 0.5 } )
      im.PushFont( font_big )
      // if im.Selectable( str.clone_to_cstring( fmt.tprint( x, z ) ), selected, {}, im.Vec2{ 35, 35 } )
      if im.Selectable( id_strs[id_strs_idx], selected, {}, im.Vec2{ 35, 35 } )
      {
        im.OpenPopup( "tile_type_popup" )
      }
      im.PopStyleVar()
      im.PopFont()
      if im.IsItemHovered()
      {
        // debug_draw_sphere( util_tile_to_pos( waypoint_t{ level_idx=level, x=x, z=z } ), 
        //                    linalg.vec3{ 0.2, 0.2, 0.2 }, 
        //                    linalg.vec3{ 1, 1, 1 } )
        
        pos := util_tile_to_pos( waypoint_t{ level_idx=level, x=x, z=z } )
        min := pos + linalg.vec3{ -1, -1, -1 }
        max := pos + linalg.vec3{  1,  1,  1 }
        debug_draw_aabb( min, max, linalg.vec3{ 1, 1, 1 }, 15 )
      }
      if im.BeginPopup( "tile_type_popup" )
      {
        im.Text( fmt.ctprintf( "%v %v %v", level, x, z ) )
        im.SeparatorText( tile_strs[id_strs_idx] )
        if data.tile_type_arr[level][x][z] != Tile_Nav_Type.EMPTY && im.Button( "empty" ) 
        { 
          if data.tile_type_arr[level][x][z] == Tile_Nav_Type.TRAVERSABLE ||
             data.tile_type_arr[level][x][z] == Tile_Nav_Type.BLOCKED
          {
            data_entity_remove( data.tile_entity_id_arr[level][x][z] )
          }
          data.tile_type_arr[level][x][z] = Tile_Nav_Type.EMPTY
        }
        if data.tile_type_arr[level][x][z] == Tile_Nav_Type.EMPTY && im.Button( "tile" )  
        {
          data_entity_add( 
                  entity_t{ pos = util_tile_to_pos( waypoint_t{ level, x, z, Combo_Type.NONE } ), 
                            rot = { 0, 0, 0 }, scl = { 1, 1, 1 },
                            mesh_idx = data.mesh_idxs.dirt_cube, 
                            mat_idx  = level == 1 ? data.material_idxs.dirt_cube_02 : 
                                                    data.material_idxs.dirt_cube_01
                          } )
          data.tile_type_arr[level][x][z] = Tile_Nav_Type.TRAVERSABLE
          if level +1 < TILE_LEVELS_MAX && data.tile_type_arr[level +1][x][z] == Tile_Nav_Type.TRAVERSABLE
          { data.tile_type_arr[level][x][z] = Tile_Nav_Type.BLOCKED } 
        }
        if data.tile_type_arr[level][x][z] == Tile_Nav_Type.BLOCKED && im.Button( "remove blocking tile" )
        {
          data_entity_remove( data.tile_entity_id_arr[level +1][x][z] )
        }
        im.EndPopup()
      }
      im.PopID()

      // x += 1
    }
    // z += 1
  }
}
ui_assetm_tab :: proc()
{

  // im.Text( "blank" )
  // im.Image( im.TextureID(uintptr(data.texture_arr[data.texture_idxs.blank].handle)), im.Vec2{ w, h }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
  //
  // im.Text( "brick-albedo" )
  // im.Image( im.TextureID(uintptr(data.texture_arr[data.texture_idxs.brick_albedo].handle)), im.Vec2{ w, h }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
  // im.Text( "brick-normal" )
  // im.Image( im.TextureID(uintptr(data.texture_arr[data.texture_idxs.brick_normal].handle)), im.Vec2{ w, h }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
  
  if im.BeginTabBar( "assetm-tab-tabs" )
  {
    if im.BeginTabItem( "materials" )
    {
      im.SeparatorText( "reflected" )
      ui_display_any( data.material_arr, "data.material_arr" )
      im.SeparatorText( "" )

      for &m, i in data.material_arr
      {
        if im.CollapsingHeader( str.clone_to_cstring( m.name, context.temp_allocator )  )
        {
          // im.Text( str.clone_to_cstring( m.name, context.temp_allocator ) )
          
          im.SeparatorText( "tint" )

          w := (im.GetContentRegionAvail().x - im.GetStyle().ItemSpacing.y) * 0.40
          im.SetNextItemWidth( w )
          im.PushID( str.clone_to_cstring( fmt.tprint( "color-picker3_00", i ), context.temp_allocator ) )
          im.ColorPicker3("##MyColor##5", (^[3]f32)(&m.tint), { im.ColorEditFlags.PickerHueBar, im.ColorEditFlags.NoSidePreview, im.ColorEditFlags.NoInputs, im.ColorEditFlags.NoAlpha });
          im.PopID()
          
          im.SameLine()
          im.SetNextItemWidth(w);
          im.PushID( str.clone_to_cstring( fmt.tprint( "color-picker3_01", i ), context.temp_allocator ) )
          im.ColorPicker3("##MyColor##6", (^[3]f32)(&m.tint), { im.ColorEditFlags.PickerHueWheel, im.ColorEditFlags.NoSidePreview, im.ColorEditFlags.NoInputs, im.ColorEditFlags.NoAlpha } )
          im.PopID()

          im.PushID( str.clone_to_cstring( fmt.tprint( "color-dragfloat3", i ), context.temp_allocator ) )
          im.DragFloat3( "", (^[3]f32)(&m.tint), 0.1, 0, 1)
          im.PopID()
          color_int := [3]i32{ i32(m.tint[0] * 255.0), i32(m.tint[1] * 255.0), i32(m.tint[2] * 255.0) }
          im.PushID( str.clone_to_cstring( fmt.tprint( "color-dragint3", i ), context.temp_allocator ) )
          im.DragInt3( "", &color_int, 0.1, 0, 255)
          im.PopID()
          m.tint[0] = f32(color_int[0]) / 255.0
          m.tint[1] = f32(color_int[1]) / 255.0
          m.tint[2] = f32(color_int[2]) / 255.0
          
          im.SeparatorText( "properties" )

          im.DragFloat( fmt.ctprintf( "roughness_f : f32" ), &m.roughness_f, 0.05, 0.0, 1.0  )
          im.DragFloat( fmt.ctprintf( "metallic_f : f32" ), &m.metallic_f,   0.05, 0.0, 1.0 )
          im.DragFloat2( fmt.ctprintf( "uv_tile: linalg.vec2" ), &m.uv_tile, 0.05 )
          im.DragFloat2( fmt.ctprintf( "uv_offs: linalg.vec2" ), &m.uv_offs, 0.05 )

          im.SeparatorText( "textures" )

          t_albedo    := assetm_get_texture( m.albedo_idx )
          t_roughness := assetm_get_texture( m.roughness_idx )
          t_metallic  := assetm_get_texture( m.metallic_idx )
          t_normal    := assetm_get_texture( m.normal_idx )
 
          SCALE :: 225
          
          t_00   := t_albedo
          t_w_00 : f32 = SCALE
          t_h_00 : f32 = SCALE * ( f32(t_00.height) / f32(t_00.width) )
          t_01   := t_roughness
          t_w_01 : f32 = SCALE
          t_h_01 : f32 = SCALE * ( f32(t_01.height) / f32(t_01.width) )
          ui_display_2_texture( fmt.ctprintf( "albedo: %s",    t_albedo.name ),    t_w_00, t_h_00, t_w_00*4, t_h_00*4, t_albedo.handle,
                                fmt.ctprintf( "roughness: %s", t_roughness.name ), t_w_01, t_h_01, t_w_01*4, t_h_01*4, t_roughness.handle )

          t_00   = t_metallic
          t_w_00 = SCALE
          t_h_00 = SCALE * ( f32(t_00.height) / f32(t_00.width) )
          t_01   = t_normal
          t_w_01 = SCALE
          t_h_01 = SCALE * ( f32(t_01.height) / f32(t_01.width) )
          ui_display_2_texture( fmt.ctprintf( "metallic: %s", t_metallic.name ), t_w_00, t_h_00, t_w_00*4, t_h_00*4, t_metallic.handle,
                                fmt.ctprintf( "normal: %s",   t_normal.name ),   t_w_01, t_h_01, t_w_01*4, t_h_01*4, t_normal.handle )
        }
      }
      im.EndTabItem()
    }
    if im.BeginTabItem( "textures" )
    {
      im.SeparatorText( "reflected" )
      ui_display_any( data.texture_arr, "data.texture_arr" )
      im.SeparatorText( "" )

      for t, i in data.texture_arr
      {
        name_cstr := str.clone_to_cstring( t.name, context.temp_allocator )
        if im.CollapsingHeader( name_cstr )
        {
          SCALE :: 350
          w : f32 = SCALE
          h : f32 = SCALE * ( f32(t.height) / f32(t.width) )
          ui_display_texture( name_cstr, w, h, w*2, h*2, t.handle, no_name=true )

          im.Text( str.clone_to_cstring( fmt.tprint( "width:    ", t.width ),    context.temp_allocator ) )
          im.Text( str.clone_to_cstring( fmt.tprint( "height:   ", t.height ),   context.temp_allocator ) )
          im.Text( str.clone_to_cstring( fmt.tprint( "channels: ", t.channels ), context.temp_allocator ) )
        }
      }
      im.EndTabItem()
    }
    if im.BeginTabItem( "meshes" )
    {
      im.SeparatorText( "reflected" )
      ui_display_any( data.mesh_arr, "data.mesh_arr" )
      im.SeparatorText( "" )

      im.Text( "F32_PER_VERT: %d", F32_PER_VERT )
      for m, i in data.mesh_arr
      {
        if im.CollapsingHeader( str.clone_to_cstring( m.name, context.temp_allocator )  )
        {
          im.Text( str.clone_to_cstring( fmt.tprintf( "vao:          %d", m.vao ),          context.temp_allocator ) )
          im.Text( str.clone_to_cstring( fmt.tprintf( "vbo:          %d", m.vbo ),          context.temp_allocator ) )
          im.Text( str.clone_to_cstring( fmt.tprintf( "vertices_len: %d", m.vertices_len / F32_PER_VERT ), context.temp_allocator ) )
          im.Text( str.clone_to_cstring( fmt.tprintf( "indices_len:  %d", m.indices_len ),  context.temp_allocator ) )
        }
      }
      im.EndTabItem()
    }
    im.EndTabBar()
  }
}
ui_data_tab :: proc()
{
  if im.BeginTabBar( "data-tab-tabs" )
  {
    if im.BeginTabItem( "data" )
    {
      im.SeparatorText( "reflected" )
      ui_display_struct_members( data, "data" )
      im.SeparatorText( "" )

      im.NewLine()
      im.Text( "delta_t_real:            %f", data.delta_t_real )
      im.Text( "delta_t:                 %f", data.delta_t )
      im.Text( "total_t:                 %f", data.total_t )
      im.Text( "cur_fps:                 %f", data.cur_fps )
      im.Text( "time_scale:              %f", data.time_scale )
      im.DragFloat( "time_scale", &data.time_scale, 0.1 )
      
      im.NewLine()
      im.Text( "window_width:            %d", data.window_width )
      im.Text( "window_height:           %d", data.window_height )
      im.Text( "monitor_width:           %d", data.monitor_width )
      im.Text( "monitor_height:          %d", data.monitor_height )
      im.Text( "vsync_enabled:           %s", data.vsync_enabled ? "true" : "false" )
      vsync := data.vsync_enabled
      im.Checkbox( "vsync_enabled", &vsync )
      if vsync != data.vsync_enabled
      { window_set_vsync( vsync ) }

      im.NewLine()
      im.Text( "wireframe_mode_enabled:  %s", data.wireframe_mode_enabled ? "true" : "false" )
      im.Checkbox( "wireframe_mode_enabled", &data.wireframe_mode_enabled )
  
      SCALE :: 225
      t_w : f32 = SCALE
      t_h : f32 = SCALE 
      ui_display_texture( "brdf_lut", t_w, t_h, t_w*2, t_h*2, data.brdf_lut )

      im.NewLine()
      im.Text( "cam.pos:                 %f, %f, %f", data.cam.pos.x, data.cam.pos.y, data.cam.pos.z )
      im.DragFloat3( "cam.pos", (^[3]f32)(&data.cam.pos) )
      im.Text( "cam.target:              %f, %f, %f", data.cam.target.x, data.cam.target.y, data.cam.target.z )
      // im.DragFloat3( "cam.target", (^[3]f32)(&data.cam.target) )
      im.Text( "cam.pitch_rad:           %f", data.cam.pitch_rad )
      im.DragFloat( "cam.pitch_rad", &data.cam.pitch_rad, 0.1 )
      im.Text( "cam.yaw_rad:             %f", data.cam.yaw_rad )
      im.DragFloat( "cam.yaw_rad",   &data.cam.yaw_rad, 0.1 )

      im.NewLine()
      im.Text( "editor_ui.active:        %s", data.editor_ui.active ? "true" : "false" )

      im.NewLine()
      im.Text( "TILE_ARR_X_MAX:          %d", TILE_ARR_X_MAX )
      im.Text( "TILE_ARR_Z_MAX:          %d", TILE_ARR_Z_MAX )
      im.Text( "TILE_LEVELS_MAX:         %d", TILE_LEVELS_MAX )

      im.EndTabItem()
    }
    if im.BeginTabItem( "framebuffers" )
    {
      SCALE :: 0.35
      w := f32(data.window_width)  * SCALE
      h := f32(data.window_height) * SCALE

      // im.Text( "color" )
      // im.Image( im.TextureID(uintptr(data.fb_deferred.buffer01)), im.Vec2{ w, h }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
      // im.Text( "material" )
      // im.Image( im.TextureID(uintptr(data.fb_deferred.buffer02)), im.Vec2{ w, h }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
      // im.Text( "normal" )
      // im.Image( im.TextureID(uintptr(data.fb_deferred.buffer03)), im.Vec2{ w, h }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
      // im.Text( "position" )
      // im.Image( im.TextureID(uintptr(data.fb_deferred.buffer04)), im.Vec2{ w, h }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
      // im.Text( "lighting" )
      // im.Image( im.TextureID(uintptr(data.fb_lighting.buffer01)), im.Vec2{ w, h }, im.Vec2{ 1, 1 }, im.Vec2{ 0, 0 } )
      ui_display_texture( "color",    w, h, w*2, h*2, data.fb_deferred.buffer01 )
      ui_display_texture( "material", w, h, w*2, h*2, data.fb_deferred.buffer02 )
      ui_display_texture( "normal",   w, h, w*2, h*2, data.fb_deferred.buffer03 )
      ui_display_texture( "position", w, h, w*2, h*2, data.fb_deferred.buffer04 )
      ui_display_texture( "lighting", w, h, w*2, h*2, data.fb_lighting.buffer01 )
      ui_display_texture( "outline", w, h, w*2, h*2, data.fb_outline.buffer01 )
      ui_display_texture( "mouse_pick", w, h, w*2, h*2, data.fb_mouse_pick.buffer01 )


      im.EndTabItem()
    }
    if im.BeginTabItem( "timers" )
    {
      im.SeparatorText( "reflected" )
      ui_display_any( timer_static_arr, "timer_static_arr" )
      ui_display_any( timer_stopped_arr, "timer_stopped_arr" )
      im.SeparatorText( "" )

      if im.CollapsingHeader( fmt.ctprintf( "static timer[%d]", len(timer_static_arr) ) )
      {
        for &t, i in timer_static_arr
        {
          ui_display_timer( &t )
        }
      }
      if im.CollapsingHeader( fmt.ctprintf( "timer[%d]", len(timer_stopped_arr[timer_stopped_arr_idx == 0 ? 1 : 0]) ) )
      {
        for &t, i in timer_stopped_arr[timer_stopped_arr_idx == 0 ? 1 : 0]
        {
          ui_display_timer( &t )
        }
      }
      im.EndTabItem()
    }
  }
  im.EndTabBar()
} 
ui_display_timer :: #force_inline proc( t: ^timer_t )
{
  indent_w : f32 = 15.0 * f32(t.parent_idx)
  if t.parent_idx != 0
  {
    im.Indent( indent_w ) 
  }
  header_str := fmt.ctprintf( "%s -> %.2fms %s():%d", 
                t.name, f32(t.stopwatch._accumulation) / 1000000.0, 
                t.loc_start.procedure, t.loc_start.line )
  im.PushID( header_str )
  if im.TreeNode( header_str )
  {
    im.Text( fmt.ctprintf( "time: %.2fms | %d", f32( t.stopwatch._accumulation) / ( 1000000.0 ), t.stopwatch._accumulation ) ) 
    im.Text( fmt.ctprintf( "idx: %d, parent_idx: %d", t.idx, t.parent_idx ) ) 

    im.SeparatorText( "started" )
    im.Text( fmt.ctprint( "proc:", t.loc_start.procedure, ", line:", t.loc_start.line, ", col: ", t.loc_start.column ) )
    im.Text( fmt.ctprint( "file:", t.loc_start.file_path ) )

    im.SeparatorText( "stopped" )
    im.Text( fmt.ctprint( "proc:", t.loc_stop.procedure, ", line:", t.loc_stop.line, ", col: ", t.loc_stop.column ) )
    im.Text( fmt.ctprint( "file:", t.loc_stop.file_path ) )


    im.TreePop()
  }
  im.PopID()
  if t.parent_idx != 0
  {
    im.Unindent( indent_w )
  }
}

ui_display_any :: #force_inline proc( v: any, name: string, indent_idx := 0 )
{
  ui_display_type_info( type_info_of( v.id ), v, name, indent_idx )
}
ui_display_type_info :: proc( type: ^reflect.Type_Info, v: any, name: string, indent_idx := 0 )
{
  // indent_w : f32 = 15.0 * f32(indent_idx)
  // if indent_idx != 0
  // {
  //   im.Indent( indent_w ) 
  // }
  for i in 0 ..< indent_idx
  {
    im.Text( "| " )
    im.SameLine()
  }

  switch
  {
    case v.id == typeid_of( string ) || v.id == typeid_of( cstring ):
    { im.Text( fmt.ctprintf( "%s : %s = \"%s\"", name, v.id, v ) ) }
    case ( reflect.is_integer( type ) && !reflect.is_unsigned( type ) ):
    { im.DragInt( fmt.ctprintf( "%s : %s", name, v.id ), (^i32)(v.data) ) }
    case ( reflect.is_integer( type ) && reflect.is_unsigned( type ) ):
    { im.DragInt( fmt.ctprintf( "%s : %s", name, v.id ), (^i32)(v.data), 1.0, 0.0 ) }
    case reflect.is_float( type ):
    { im.DragFloat( fmt.ctprintf( "%s : %s", name, v.id ), (^f32)(v.data), 0.05 ) }
    case v.id == typeid_of( bool ):
    { im.Checkbox( fmt.ctprintf( "%s : %s", name, v.id ), (^bool)(v.data) ) }
    case v.id == typeid_of( [2]f32 ) || v.id == typeid_of( linalg.vec2 ): 
    { im.DragFloat2( fmt.ctprintf( "%s : %s", name, v.id ), (^[2]f32)(v.data), 0.05 ) }
    case v.id == typeid_of( [3]f32 ) || v.id == typeid_of( linalg.vec3 ): 
    { im.DragFloat3( fmt.ctprintf( "%s : %s", name, v.id ), (^[3]f32)(v.data), 0.05 ) }
    case v.id == typeid_of( [4]f32 ) || v.id == typeid_of( linalg.vec4 ): 
    { im.DragFloat4( fmt.ctprintf( "%s : %s", name, v.id ), (^[4]f32)(v.data), 0.05 ) }
    case reflect.is_array( type ) || reflect.is_dynamic_array( type ):
    {
      if im.CollapsingHeader( fmt.ctprintf( "%s[%d] : %s", name, reflect.length(v), v.id ) )
      {
        for idx := 0; idx < reflect.length( v ); idx += 1
        { 
          val : any
          ok  : bool
          _idx := idx
          val, _idx, ok = reflect.iterate_array( v, &_idx )
          if !ok { break }
          // im.Text( fmt.ctprintf( "%s[%d] : %s = %v", name, idx, val.id, val ) ) 
          ui_display_any( val, fmt.tprintf( "%s[%d]", name, idx ), indent_idx +1 )
        }
      }
    }
    case reflect.is_struct( type ):
    {
      ui_display_struct_members( v, name, indent_idx +1 )
    }
    case: 
    { im.Text( fmt.ctprintf( "%s : %s = %v", name, type, v ) ) }
  }
  
  // if indent_ix != 0
  // {
  //   im.Unindent( indent_w )
  // }
}
ui_display_struct_members :: proc( value: any, name: string, indent_idx := 1 )
{
  if im.CollapsingHeader( fmt.ctprintf( "%s : %s", name, value.id  ) ) 
  {
    types_arr  := reflect.struct_field_types( value.id )
    names_arr  := reflect.struct_field_names( value.id )
    for type, i in types_arr
    {
      v := reflect.struct_field_value_by_name( value, names_arr[i] )
      ui_display_type_info( type, v, names_arr[i], indent_idx )
    }
  }
}

ui_set_style_dark_default :: proc()
{
	im.StyleColorsDark()
	style := im.GetStyle()
	style.WindowRounding    = 10.0
  style.TabRounding       = 10.0
  style.GrabRounding      = 10.0
  style.PopupRounding     = 10.0
  style.FrameRounding     = 10.0
  style.ScrollbarRounding = 10.0
  style.AntiAliasedLines  = true  // Enable anti-aliased lines
  style.AntiAliasedFill   = true  // Enable anti-aliased fill

	// style.Colors[im.Col.WindowBg].w = 1
  style.Colors[im.Col.WindowBg]            = im.Vec4{ 0.2,  0.2,  0.2,  1.0 }

  style.Colors[im.Col.Header]              = im.Vec4{ 0.15, 0.15, 0.15, 1.0 }
  style.Colors[im.Col.HeaderHovered]       = im.Vec4{ 0.1,  0.1,  0.1,  1.0 }
  style.Colors[im.Col.HeaderActive]        = im.Vec4{ 0.1,  0.1,  0.1,  1.0 }

  style.Colors[im.Col.Tab]                 = im.Vec4{ 0.2,  0.2,  0.2,  1.0 }
  style.Colors[im.Col.TabHovered]          = im.Vec4{ 0.35, 0.35, 0.35,  1.0 }
  style.Colors[im.Col.TabSelected]         = im.Vec4{ 0.30, 0.30, 0.30, 1.0 }
  style.Colors[im.Col.TabDimmed]           = im.Vec4{ 0.20, 0.20, 0.20, 1.0 }
  style.Colors[im.Col.TabDimmedSelected]   = im.Vec4{ 0.25, 0.25, 0.25, 1.0 }
  style.Colors[im.Col.TabSelectedOverline] = im.Vec4{ 0.9,  0.9,  0.9,  1.0 }

  style.Colors[im.Col.Button]              = im.Vec4{ 0.15, 0.15, 0.15, 1.0 }
  style.Colors[im.Col.ButtonActive]        = im.Vec4{ 0.05, 0.05, 0.05, 1.0 }
  style.Colors[im.Col.ButtonHovered]       = im.Vec4{ 0.1,  0.1,  0.1,  1.0 }

  style.Colors[im.Col.TitleBg]             = im.Vec4{ 0.15, 0.15, 0.15, 1.0 }
  style.Colors[im.Col.TitleBgActive]       = im.Vec4{ 0.1,  0.1,  0.1,  1.0 }
  style.Colors[im.Col.TitleBgCollapsed]    = im.Vec4{ 0.1,  0.1,  0.1,  1.0 }

  style.Colors[im.Col.FrameBg]             = im.Vec4{ 0.15, 0.15, 0.15, 1.0 }
  style.Colors[im.Col.FrameBgActive]       = im.Vec4{ 0.15, 0.15, 0.15, 1.0 }
  style.Colors[im.Col.FrameBgHovered]      = im.Vec4{ 0.15, 0.15, 0.15, 1.0 }

  style.Colors[im.Col.CheckMark]           = im.Vec4{ 0.9,  0.9,  0.9,  1.0 }
  style.Colors[im.Col.SliderGrab]          = im.Vec4{ 0.9,  0.9,  0.9,  1.0 }
  style.Colors[im.Col.SliderGrabActive]    = im.Vec4{ 1.0,  1.0,  1.0,  1.0 }

  style.Colors[im.Col.Separator]           = im.Vec4{ 0.1,  0.1,  0.1,  1.0 }
  style.Colors[im.Col.SeparatorActive]     = im.Vec4{ 0.1,  0.1,  0.1,  1.0 }
  style.Colors[im.Col.SeparatorHovered]    = im.Vec4{ 0.1,  0.1,  0.1,  1.0 }

  style.Colors[im.Col.ResizeGrip]          = im.Vec4{ 0.5,  0.5,  0.5,  1.0 }
  style.Colors[im.Col.ResizeGripHovered]   = im.Vec4{ 0.6,  0.6,  0.6,  1.0 }
  style.Colors[im.Col.ResizeGripActive]    = im.Vec4{ 0.7,  0.7,  0.7,  1.0 }
  
  style.Colors[im.Col.DockingPreview]      = im.Vec4{ 0.9,  0.9,  0.9,  1.0 }

  data.editor_ui.style = .DARK_DEFAULT
}

ui_set_style_dark_light :: proc()
{
  style := im.GetStyle()

  // Base colors for a pleasant and modern dark theme with dark accents
  style.Colors[im.Col.Text]                   = { 0.92, 0.93, 0.94, 1.00 }  // Light grey text for readability
  style.Colors[im.Col.TextDisabled]           = { 0.50, 0.52, 0.54, 1.00 }  // Subtle grey for disabled text
  style.Colors[im.Col.WindowBg]               = { 0.14, 0.14, 0.16, 1.00 }  // Dark background with a hint of blue
  style.Colors[im.Col.ChildBg]                = { 0.16, 0.16, 0.18, 1.00 }  // Slightly lighter for child elements
  style.Colors[im.Col.PopupBg]                = { 0.18, 0.18, 0.20, 1.00 }  // Popup background
  style.Colors[im.Col.Border]                 = { 0.28, 0.29, 0.30, 0.60 }  // Soft border color
  style.Colors[im.Col.BorderShadow]           = { 0.00, 0.00, 0.00, 0.00 }  // No border shadow
  style.Colors[im.Col.FrameBg]                = { 0.20, 0.22, 0.24, 1.00 }  // Frame background
  style.Colors[im.Col.FrameBgHovered]         = { 0.22, 0.24, 0.26, 1.00 }  // Frame hover effect
  style.Colors[im.Col.FrameBgActive]          = { 0.24, 0.26, 0.28, 1.00 }  // Active frame background
  style.Colors[im.Col.TitleBg]                = { 0.14, 0.14, 0.16, 1.00 }  // Title background
  style.Colors[im.Col.TitleBgActive]          = { 0.16, 0.16, 0.18, 1.00 }  // Active title background
  style.Colors[im.Col.TitleBgCollapsed]       = { 0.14, 0.14, 0.16, 1.00 }  // Collapsed title background
  style.Colors[im.Col.MenuBarBg]              = { 0.20, 0.20, 0.22, 1.00 }  // Menu bar background
  style.Colors[im.Col.ScrollbarBg]            = { 0.16, 0.16, 0.18, 1.00 }  // Scrollbar background
  style.Colors[im.Col.ScrollbarGrab]          = { 0.24, 0.26, 0.28, 1.00 }  // Dark accent for scrollbar grab
  style.Colors[im.Col.ScrollbarGrabHovered]   = { 0.28, 0.30, 0.32, 1.00 }  // Scrollbar grab hover
  style.Colors[im.Col.ScrollbarGrabActive]    = { 0.32, 0.34, 0.36, 1.00 }  // Scrollbar grab active
  style.Colors[im.Col.CheckMark]              = { 0.46, 0.56, 0.66, 1.00 }  // Dark blue checkmark
  style.Colors[im.Col.SliderGrab]             = { 0.36, 0.46, 0.56, 1.00 }  // Dark blue slider grab
  style.Colors[im.Col.SliderGrabActive]       = { 0.40, 0.50, 0.60, 1.00 }  // Active slider grab
  style.Colors[im.Col.Button]                 = { 0.24, 0.34, 0.44, 1.00 }  // Dark blue button
  style.Colors[im.Col.ButtonHovered]          = { 0.28, 0.38, 0.48, 1.00 }  // Button hover effect
  style.Colors[im.Col.ButtonActive]           = { 0.32, 0.42, 0.52, 1.00 }  // Active button
  style.Colors[im.Col.Header]                 = { 0.24, 0.34, 0.44, 1.00 }  // Header color similar to button
  style.Colors[im.Col.HeaderHovered]          = { 0.28, 0.38, 0.48, 1.00 }  // Header hover effect
  style.Colors[im.Col.HeaderActive]           = { 0.32, 0.42, 0.52, 1.00 }  // Active header
  style.Colors[im.Col.Separator]              = { 0.28, 0.29, 0.30, 1.00 }  // Separator color
  style.Colors[im.Col.SeparatorHovered]       = { 0.46, 0.56, 0.66, 1.00 }  // Hover effect for separator
  style.Colors[im.Col.SeparatorActive]        = { 0.46, 0.56, 0.66, 1.00 }  // Active separator
  style.Colors[im.Col.ResizeGrip]             = { 0.36, 0.46, 0.56, 1.00 }  // Resize grip
  style.Colors[im.Col.ResizeGripHovered]      = { 0.40, 0.50, 0.60, 1.00 }  // Hover effect for resize grip
  style.Colors[im.Col.ResizeGripActive]       = { 0.44, 0.54, 0.64, 1.00 }  // Active resize grip
  style.Colors[im.Col.Tab]                    = { 0.20, 0.22, 0.24, 1.00 }  // Inactive tab
  style.Colors[im.Col.TabHovered]             = { 0.28, 0.38, 0.48, 1.00 }  // Hover effect for tab
  style.Colors[im.Col.TabSelected]            = { 0.24, 0.34, 0.44, 1.00 }  // Active tab color (TabActive)
  style.Colors[im.Col.TabDimmed]              = { 0.20, 0.22, 0.24, 1.00 }  // Unfocused tab (TabUnfocused)
  style.Colors[im.Col.TabDimmedSelected]      = { 0.24, 0.34, 0.44, 1.00 }  // Active but unfocused tab (TabUnfocusedActive)
  style.Colors[im.Col.DockingPreview]         = { 0.24, 0.34, 0.44, 0.70 }  // Docking preview
  style.Colors[im.Col.DockingEmptyBg]         = { 0.14, 0.14, 0.16, 1.00 }  // Empty docking background
  style.Colors[im.Col.PlotLines]              = { 0.46, 0.56, 0.66, 1.00 }  // Plot lines
  style.Colors[im.Col.PlotLinesHovered]       = { 0.46, 0.56, 0.66, 1.00 }  // Hover effect for plot lines
  style.Colors[im.Col.PlotHistogram]          = { 0.36, 0.46, 0.56, 1.00 }  // Histogram color
  style.Colors[im.Col.PlotHistogramHovered]   = { 0.40, 0.50, 0.60, 1.00 }  // Hover effect for histogram
  style.Colors[im.Col.TableHeaderBg]          = { 0.20, 0.22, 0.24, 1.00 }  // Table header background
  style.Colors[im.Col.TableBorderStrong]      = { 0.28, 0.29, 0.30, 1.00 }  // Strong border for tables
  style.Colors[im.Col.TableBorderLight]       = { 0.24, 0.25, 0.26, 1.00 }  // Light border for tables
  style.Colors[im.Col.TableRowBg]             = { 0.20, 0.22, 0.24, 1.00 }  // Table row background
  style.Colors[im.Col.TableRowBgAlt]          = { 0.22, 0.24, 0.26, 1.00 }  // Alternate row background
  style.Colors[im.Col.TextSelectedBg]         = { 0.24, 0.34, 0.44, 0.35 }  // Selected text background
  style.Colors[im.Col.DragDropTarget]         = { 0.46, 0.56, 0.66, 0.90 }  // Drag and drop target
  style.Colors[im.Col.NavHighlight]           = { 0.46, 0.56, 0.66, 1.00 }  // Navigation highlight (NavHighlight)
  style.Colors[im.Col.NavWindowingHighlight]  = { 1.00, 1.00, 1.00, 0.70 }  // Windowing highlight
  style.Colors[im.Col.NavWindowingDimBg]      = { 0.80, 0.80, 0.80, 0.20 }  // Dim background for windowing
  style.Colors[im.Col.ModalWindowDimBg]       = { 0.80, 0.80, 0.80, 0.35 }  // Dim background for modal windows

	style.WindowRounding    = 10.0
  style.TabRounding       = 10.0
  style.GrabRounding      = 10.0
  style.PopupRounding     = 10.0
  style.FrameRounding     = 10.0
  style.ScrollbarRounding = 10.0

  // Style adjustments
  style.WindowRounding     = 8.0  // Softer rounded corners for windows
  style.FrameRounding     = 4.0  // Rounded corners for frames
  style.ScrollbarRounding = 6.0  // Rounded corners for scrollbars
  style.GrabRounding      = 4.0  // Rounded corners for grab elements
  style.ChildRounding     = 4.0  // Rounded corners for child windows

  style.WindowTitleAlign = {0.50, 0.50}  // Centered window title
  style.WindowPadding     = {10.0, 10.0}  // Comfortable padding
  style.FramePadding      = {6.0, 4.0}    // Frame padding
  style.ItemSpacing       = {8.0, 8.0}    // Item spacing
  style.ItemInnerSpacing = {8.0, 6.0}    // Inner item spacing
  style.IndentSpacing     = 22.0          // Indentation spacing

  style.ScrollbarSize = 16.0  // Scrollbar size
  style.GrabMinSize  = 10.0  // Minimum grab size

  style.AntiAliasedLines = true  // Enable anti-aliased lines
  style.AntiAliasedFill  = true  // Enable anti-aliased fill

  data.editor_ui.style = .DARK_LIGHT
}
