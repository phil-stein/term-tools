package ls 

import     "core:os"
import     "core:fmt"
import str "core:strings"
import     "core:c/libc"


// Value_Type :: enum
// {
//   INVALID,
//   BOOL,
//   INT,
//   F32,
// }
parsed_value_t :: union 
{
	bool,
	int,
	f32,
}
config_preset_t :: struct
{
  available : bool, // if ls.config actually defines this preset

  width : int,
  depth : int,
  files : int,
  dirs  : bool,
}
CONFIG_RESULT_T_PRESETS_MAX :: 10
config_result_t :: struct
{
  main    : config_preset_t,
  presets : [CONFIG_RESULT_T_PRESETS_MAX]config_preset_t,
}

config_result : config_result_t
current_config_preset : ^config_preset_t = &config_result.main

preset_idx := -1 // < 0 means config_result_t.main is active

config_set_preset :: #force_inline proc( preset: ^config_preset_t)
{
  MAX_LINE_WIDTH   = preset.width
  ONLY_SHOW_DIRS   = preset.dirs  
  SUBDIR_DEPTH_MAX = preset.depth 
  FILES_MAX        = preset.files 
}

config_read :: proc( path: string)
{
  // set default values for presets
  config_result.main.available = true 
  config_result.main.width     = MAX_LINE_WIDTH 
  config_result.main.dirs      = ONLY_SHOW_DIRS 
  config_result.main.depth     = SUBDIR_DEPTH_MAX
  config_result.main.files     = FILES_MAX
  for i in 0 ..< CONFIG_RESULT_T_PRESETS_MAX
  {
    config_result.presets[i].available = false 
    config_result.presets[i].width     = MAX_LINE_WIDTH 
    config_result.presets[i].dirs      = ONLY_SHOW_DIRS 
    config_result.presets[i].depth     = SUBDIR_DEPTH_MAX
    config_result.presets[i].files     = FILES_MAX
  }


  // read config file
  
  src_bytes, ok := os.read_entire_file( path, context.allocator )
  if !ok || len( src_bytes ) <= 0
  { fmt.eprintln( "[ERROR] could not read config file: ", path ); return }
  defer delete( src_bytes, context.allocator )
  src     := string( src_bytes )
  src_len := len( src )
  
  for i := 0; i < src_len; i += 1
  {
    if src[i] == '['
    {
      // read name
      i += 1  // skip [
      name_start := i
      for i < src_len && src[i] != ']'
      { i += 1 }
      name := src[name_start:i]
      i += 1  // skip ]
      // fmt.println( "name:", name )

      // skip whitespace
      for i < src_len && str.is_space( rune(src[i]) ) 
      { i += 1 }
      
      // read value
      name_start = i
      for i < src_len && !str.is_space( rune(src[i]) ) 
      { i += 1 }
      value := src[name_start:i]
      // fmt.println( "value: ", value )

      handle_value( name, value, current_config_preset /* &config_result.main */ )
    }
  }
}

handle_value :: proc( name: string, value: string, conf: ^config_preset_t )
{
  // checking for '}'
  if str.contains( name, "}" )
  {
    // reseting to main preset in reading '}'
    current_config_preset = &config_result.main
  }

  // for normal values
  v, succsess := parse_value( value )
  if ( v == nil || !succsess ) && !str.contains( value, "{" )  { return }

  if str.compare( name, "width" ) == 0
  {
    val, ok := v.(int)
    if !ok 
    { fmt.eprintfln( "[ERROR] width value given not integer: \"%s\"", value ); return }
    conf.width = val  
    // fmt.println( " > width: ", conf.width )
  }
  else if str.compare( name, "depth" ) == 0
  {
    val, ok := v.(int)
    if !ok 
    { fmt.eprintfln( "[ERROR] depth value given not integer: \"%s\"", value ); return }
    conf.depth = val  
    // fmt.println( " > depth: ", conf.depth )
  }
  else if str.compare( name, "files" ) == 0
  {
    val, ok := v.(int)
    if !ok 
    { fmt.eprintfln( "[ERROR] files value given not integer: \"%s\"", value ); return }

    if val < 1  // <1 means show all files
    { 
      val = 1 << 32
    }
    conf.files = val  
    // fmt.println( " > files: ", conf.files )
  }
  else if str.compare( name, "dirs" ) == 0
  {
    val, ok := v.(bool)
    if !ok 
    { fmt.eprintfln( "[ERROR] dirs value given not boolean: \"%s\"", value ); return }
    conf.dirs = val  
    // fmt.println( " > dirs: ", conf.dirs )
  }
  else if name[0] == 'p' &&
          name[1] == 'r' && 
          name[2] == 'e' && 
          name[3] == 's' && 
          name[4] == 'e' && 
          name[5] == 't' && 
          name[6] == ':'      // else if str.contains( name, "preset:" )
  {
    // fmt.println( "!!! preset" )
    // @TODO:
    // - parse preset number
    // - use appropriate ^config_preset_t
    if libc.isdigit( i32(name[7]) ) > 0
    {
      val := int(name[7]) - 48  // ascii code to 0-9 range
      current_config_preset = &config_result.presets[val]
      config_result.presets[val].available = true
      // fmt.println( " > preset:", val )

    }
    else { fmt.eprintln( "[ERROR] preset argument without number defined: ", name ) }
  }
  else { fmt.println( "[ERROR] argument with unknown name: ", name ) }
}
parse_value :: proc( value: string ) -> ( v: parsed_value_t, success: bool )
{
  if      str.compare( value, "true" )  == 0 { return true,  true }
  else if str.compare( value, "false" ) == 0 { return false, true }
  else if libc.isdigit( i32(value[0]) ) > 0
  {
    all_numeric := true
    for r in value { if libc.isdigit( i32(r) ) <= 0 { all_numeric = false; break } }
    if !all_numeric
    { fmt.eprintfln( "[ERROR] value contains both numeric and non numeric characters: \"%s\"", value ); return nil, false }

    value_cstr := str.clone_to_cstring( value )
    defer delete( value_cstr )
    val := libc.atoi( value_cstr )
    return int(val), true
    
  }
  else
  { return nil, false }
  
  return 
}
