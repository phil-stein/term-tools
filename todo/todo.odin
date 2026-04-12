package todo

import      "core:fmt"
import      "core:os"
import      "core:c"
import      "core:c/libc"
import str  "core:strings"
import win  "core:sys/windows"
import util ".."


parsed_value_t :: union 
{
	bool,
	int,
	f32,
}
Note_Type :: enum
{
  REGULAR_LINE,
  UNCHECKED,
  CHECKED,
  WORK_IN_PROGRESS,
  // @TODO:
  // UNSURE,
  // TMP,   // have like wipe all tmp notes funtion
  // IMPORTANT,
}
note_t :: struct
{
  str     : string,
  type    : Note_Type,
  line_nr : int,
}
config_t :: struct
{
  available    : bool, // if .config actually defines this preset
  
  utf8         : bool,
  ansi_color   : bool,
  line_nr      : bool,

  // notes        : [dynamic]string,
  // note_types   : [dynamic]Note_Type,
  notes : [dynamic]note_t,
}
config : config_t

path_to_exec : string

main :: proc()
{
  when ODIN_OS == .Windows
  {
    // @NOTE: enable utf output to console, windows specific
    win.SetConsoleOutputCP( win.CODEPAGE(win.CP_UTF8) )
  }

  // fmt.println( "current_dir:", os.get_current_directory() )
  // path to executable
  buf : [256]c.wchar_t
  path_to_exec_len := win.GetModuleFileNameW( nil, &buf[0], 256 )
  if path_to_exec_len <= 0 { fmt.eprintln( "win.GetModuleFileNameW() failed:", path_to_exec_len ) }
  sb := str.builder_make()
  for i in 0 ..< path_to_exec_len - 12 // -7 to remove '\ls.exe'
  { str.write_byte( &sb, u8(buf[i]) ) }
  path_to_exec = str.to_string( sb )
  // fmt.println( "GetModuleFileName():", path_to_exec )
 
  config_path := str.concatenate( []string{ path_to_exec, "\\config\\todo.note" }, context.temp_allocator )
  // fmt.println( "config_path:", config_path )
  // cmd := fmt.ctprint( "cd ", config_path, " & cat todo.note" )
  // fmt.println( "cmd:", cmd )
  // libc.system( cmd )
  config_file_txt := config_read( config_path, &config )
  defer delete( config_file_txt )
  
  changed_config_file := false

  if len( os.args ) <= 1
  {
  }
  else
  {
    fmt.printfln( "%v", os.args[1] )

    // @TODO: 
    //        -rm:

    // if os.args[1] == "-add"
    if len(os.args[1]) > 4  &&
       os.args[1][0] == '-' && 
       os.args[1][1] == 'a' && 
       os.args[1][2] == 'd' && 
       os.args[1][3] == 'd' 
    {
      if len(os.args) <= 2
      { fmt.println( "[ERROR] -add requires argument" ); return }

      str := str.join( os.args[2:], " " )

      if len(os.args[1]) > 5 && os.args[1][4] == ':'
      {
        type_str := os.args[1][4+1:]
        type     := type_str[0] == '-' ? Note_Type.REGULAR_LINE : 
                    type_str[0] == '*' ? Note_Type.REGULAR_LINE : 
                    type_str[0] == '.' ? Note_Type.UNCHECKED : 
                    type_str[0] == '+' ? Note_Type.UNCHECKED : 
                    type_str[0] == 'x' ? Note_Type.CHECKED : 
                    type_str[0] == 'X' ? Note_Type.CHECKED : 
                    type_str[0] == '%' ? Note_Type.WORK_IN_PROGRESS : Note_Type.REGULAR_LINE 
        fmt.println( "add type: '%v', %v", type_str, type )
        add_line( config_file_txt, config_path, str, type )
        changed_config_file = true
      }
      else
      {
        add_line( config_file_txt, config_path, str, Note_Type.REGULAR_LINE )
        changed_config_file = true
      }
    }
    else if len(os.args[1]) > 3  &&
            os.args[1][0] == '-' && 
            os.args[1][1] == 'r' && 
            os.args[1][2] == 'm'
    {
      if len(os.args) > 2
      { fmt.println( "[ERROR] -rm doeasnt take argument" ); return }

      str := str.join( os.args[2:], " " )

      if len(os.args[1]) > 4 && os.args[1][3] == ':'
      {
        val, ok := parse_value( os.args[1][4:] )
        if !ok { fmt.printfln( "[ERROR] -rm:%v failed to parse, expecting integer number", os.args[1][4:] ); return }
        num : int
        num, ok = val.(int)
        if !ok { fmt.printfln( "[ERROR] -rm:%v failed to parse, expecting integer number", os.args[1][4:] ); return }
        fmt.println( "num:", num )
        remove_line( &config_file_txt, config_path, num )
      }
      else
      {
        fmt.println( "[ERROR] -rm:XX requires argument" ) 
      }
    }
    else 
    {
      fmt.println( "[ERROR] invalid argument" )
    }
  }

  if changed_config_file
  {
    for n in config.notes { delete( n.str ) }
    delete( config.notes )
    // delete( config.note_types )
    // delete( config_file_txt )
    config = {}
    config_read( config_path, &config )
  }

  for i in 0..<len(config.notes)
  {
    // fmt.println( "note:", config.notes[i], ", type:", config.note_types[i] )
    fmt.printf( "%3d %v %3d %v  %v ", i +1, config.utf8 ? "│" : "|", config.notes[i].line_nr, config.utf8 ? "│" : "|",
                config.notes[i].type == Note_Type.REGULAR_LINE     ? ( config.utf8 ? "○" : "*" ) :  
                config.notes[i].type == Note_Type.UNCHECKED        ? ( config.utf8 ? "□" : "o" ) :  
                config.notes[i].type == Note_Type.CHECKED          ? ( config.utf8 ? "☑" : "x" ) :
                config.notes[i].type == Note_Type.WORK_IN_PROGRESS ? ( config.utf8 ? "󰔚" : "~" ) : "?" // 🕝 🚧 🏗️  󱑁 󰔚 󱦟 󰦕 󰲽 
    )
    // fmt.println( config.utf8 ? "│" : "|", config.notes[i].str )
    fmt.println( config.notes[i].str )
  }

  // assert( 1 == 0 )
}

add_line :: proc( src, path, newline: string, type: Note_Type )
{
  // fmt.println( "path:", path )
  new_src := str.join( { src,
                         type == Note_Type.REGULAR_LINE     ? "[-]" :  
                         type == Note_Type.UNCHECKED        ? "[ ]" :  
                         type == Note_Type.CHECKED          ? "[X]" :
                         type == Note_Type.WORK_IN_PROGRESS ? "[%]" : "[ERROR]",
                         newline, "\n" }, " " )
  os.write_entire_file( path, transmute([]u8)new_src )
}
remove_line :: proc( src: ^string, path: string, line_nr: int )
{
  // @TODO: this first part is useless
  idx := -1
  for note, i in config.notes
  {
    if i == line_nr -1 // line_nr is 1 indexed, array is 0 indexed
    {
      idx = note.line_nr
      fmt.println( "line_nr:", note.line_nr, ", notes[", i, "]:", note.str, "|", note.type )
    }
  }
  if idx < 0 { fmt.println( "[ERROR] line_nr given doesnt exist:", line_nr ); return }

  i := 0
  sb := str.builder_make()
  for line in str.split_lines_iterator( src )
  {
    if i == idx
    {
      continue
    }
    str.write_string( &sb, line )
    str.write_rune( &sb, '\n' )
    i += 1
  }

  new_src := str.to_string( sb )
  os.write_entire_file( path, transmute([]u8)new_src )
}

config_read :: proc( path: string, config: ^config_t ) -> ( config_file_txt: string )
{
  // set default values for presets
  config.available  = false
  config.utf8       = true
  config.ansi_color = true

  // read config file
  
  src_bytes, ok := os.read_entire_file( path, context.allocator )
  if !ok || len( src_bytes ) <= 0
  { fmt.eprintln( "[ERROR] could not read config file: ", path ); return }
  // defer delete( src_bytes, context.allocator )
  config.available = true
  src     := string( src_bytes )
  src_len := len( src )

  // fmt.println( " -------------------" )
  // fmt.println( src )
  // fmt.println( " -------------------" )
 
  // @TODO: count lines, put in note_t and then use that do determine which line needs to go in rm, also make rm alias del
  cur_line := 0
  for i := 0; i < src_len; i += 1
  {
    // skip comments
    if i +1 < src_len   &&
       src[i   ] == '/' &&
       src[i +1] == '/'  
    {
      for i < src_len && src[i] != '\n' 
      { i += 1 }
      // continue
      // cur_line += 1
      if src[i] == '\n' { cur_line += 1 }
    } // arguments
    else if src[i] == '['
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
      { 
        // if src[i] == '\n' { cur_line += 1 }
        i += 1 
      }
      
      // read value
      name_start = i
      for i < src_len && src[i] != '\n' // !str.is_space( rune(src[i]) ) 
      { i += 1 }
      if src[i] == '\n' { cur_line += 1 }
      // cur_line += 1
      value := src[name_start:i-1]
      // fmt.printf( "value: #%v#\n", value )
      // fmt.printf( "%v\n", value )

      handle_value( name, value, cur_line, config )
    }
    else if src[i] == '\n' { cur_line += 1 }
  }
  return src
}

handle_value :: proc( name, value: string, cur_line: int, conf: ^config_t )
{
  // strings
  if name == "-"
  {
    // append( &conf.notes, str.clone( value ) )
    // append( &conf.note_types, Note_Type.REGULAR_LINE )
    note := note_t{ str=str.clone( value ), type=Note_Type.REGULAR_LINE, line_nr=cur_line }
    append( &conf.notes, note )
    return
  }
  else if name == " "
  {
    // append( &conf.notes, str.clone( value ) )
    // append( &conf.note_types, Note_Type.UNCHECKED )
    note := note_t{ str=str.clone( value ), type=Note_Type.UNCHECKED, line_nr=cur_line }
    append( &conf.notes, note )
    return
  }
  else if name == "x" || name == "X"
  {
    // append( &conf.notes, str.clone( value ) )
    // append( &conf.note_types, Note_Type.CHECKED )
    note := note_t{ str=str.clone( value ), type=Note_Type.CHECKED, line_nr=cur_line }
    append( &conf.notes, note )
    return
  }
  else if name == "%"
  {
    // append( &conf.notes, str.clone( value ) )
    // append( &conf.note_types, Note_Type.WORK_IN_PROGRESS )
    note := note_t{ str=str.clone( value ), type=Note_Type.WORK_IN_PROGRESS, line_nr=cur_line }
    append( &conf.notes, note )
    return
  }

  // for normal values
  v, succsess := parse_value( value )
  if ( v == nil || !succsess ) && !str.contains( value, "{" )  
  { fmt.eprintfln( "[ERROR] value given for [%v] failed to parse: \"%s\"", name, value ); return }
  
  if name == "utf8"
  {
    val, ok := v.(bool)
    if !ok 
    { fmt.eprintfln( "[ERROR] utf8 value given not boolean: \"%s\"", value ); return }
    conf.utf8 = val  
    // fmt.println( "conf.utf8:", conf.utf8 )
  }
  else if name == "color"
  {
    val, ok := v.(bool)
    if !ok 
    { fmt.eprintfln( "[ERROR] color value given not boolean: \"%s\"", value ); return }
    conf.ansi_color = val  
    // fmt.println( "conf.ansi_color:", conf.ansi_color )
  }
  else if name == "line_nr"
  {
    val, ok := v.(bool)
    if !ok 
    { fmt.eprintfln( "[ERROR] line_nr value given not boolean: \"%s\"", value ); return }
    conf.line_nr = val  
  }
  else { fmt.printfln( "[ERROR] config argument with unknown name: [%v]", name ) }
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
