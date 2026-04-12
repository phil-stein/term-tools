package gitsync

import      "core:fmt"
import      "core:os"
import      "core:c"
import str  "core:strings"
import      "core:strconv"
import      "core:c/libc"
import win  "core:sys/windows"
import util ".."

// // @TODO: do this in a config file 
// paths := [?]string{  
//   "%appdata%\\..\\local\\nvim",
//   "C:\\workspace\\markdown",
//   "C:\\workspace\\c\\fisch",
//   "c:\\workspace\\c\\esp8266_udp_server",
//   "C:\\workspace\\c\\game_gen",
//   "C:\\workspace\\c\\term_docs",
//   "C:\\workspace\\c\\text_editor",
//   "C:\\workspace\\odin\\01_tests",
//   "C:\\workspace\\odin\\oloc",
//   "C:\\workspace\\odin\\term-tools",
//   "C:\\workspace\\odin\\03_game\\xcom",
// }

parsed_value_t :: union 
{
	bool,
	int,
	f32,
}
config_t :: struct
{
  available : bool, // if gitsync.config actually defines this preset
  
  paths    : [dynamic]string,
  concise  : bool,
  utf8     : bool,
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
 
  config_path := str.concatenate( []string{ path_to_exec, "\\..\\config\\gitsync.config" }, context.temp_allocator )
  // fmt.println( "config_path:", config_path )
  config_read( config_path, &config )


  @TODO :
  std : os.Handle = os.get_std_handle()

  // check for args
  //    -h    -> help
  //    -push:"commit message" -> push all repos in gitsync.config
  for arg, i in os.args[1:]
  {
    // fmt.println( "arg[", i, "]: ", arg )
    if arg[0] == '-'
    {
      // -push:"X"
      if len(arg) >= 4 &&
         arg[1] == 'p' && 
         arg[2] == 'u' && 
         arg[3] == 's' && 
         arg[4] == 'h' && 
         arg[5] == ':'
      {
        commit_msg := arg[6:]
        fmt.println( "commit_msg:", commit_msg )
        call_git_push( commit_msg )
        os.exit(0)
      }
      else 
      {
        fmt.printf( "[ERROR] unknow argument: \"%s\"\n", arg )
        fmt.println( " >gitsync                 <- for status" )
        fmt.println( " >gitsync -push:\"msg\"   <- for pushing" )
        os.exit( 0 )
      }
    }
  }

  // no args given 

  call_git_status()
}

call_git_status :: proc()
{
  fmt.println( 
`│ M -> modified
│?? -> untracked
│` )
  // fmt.println( "config.paths len:", len(config.paths) )
  for path in config.paths
  {
    // fmt.println( "config.path:", path )

    p := expand_environment_variable( path )
    // fmt.println( "p:", p )
    err_1    := os.set_current_directory( p )
    if err_1 != os.ERROR_NONE { fmt.println( "[ERROR]", err_1, ", for path:", path ); continue } 

    if config.utf8
    {
      util.pf_color( util.PF_Fg.WHITE ) 
      fmt.print( "" )
    }
    util.pf_mode( util.PF_Mode.BOLD, util.PF_Fg.BLACK, util.PF_Bg.WHITE ) 
    fmt.print( config.utf8 ? "" : "#", path )
    if config.utf8
    {
      util.pf_style_reset()
      util.pf_color( util.PF_Fg.WHITE ) 
      fmt.print( "\n" )
      util.pf_style_reset()
    } 
    else 
    { 
      util.pf_style_reset()
      fmt.print( "\n" ) 
    }
    util.pf_style_reset()

    // @TODO: how to get the output of this operation as string, for proper formatting
    if config.concise
    { libc.system( "git status --porcelain" ) }
    else
    { libc.system( "git status" ) }
  }
}
call_git_push :: proc( commit_message: string, remote := "origin", branch := "main" )
{
  for path in config.paths
  {
    p := expand_environment_variable( path )
    // fmt.println( "p:", p )
    err_1    := os.set_current_directory( p )
    if err_1 != os.ERROR_NONE { fmt.println( "[ERROR]", err_1, ", for path:", path ); continue } 

    if config.utf8
    {
      util.pf_color( util.PF_Fg.WHITE ) 
      fmt.print( "" )
    }
    util.pf_mode( util.PF_Mode.UNDERLINE, util.PF_Fg.BLACK, util.PF_Bg.WHITE ) 
    fmt.print( config.utf8 ? "" : "#", path )
    util.pf_style_reset()
    if config.utf8
    {
      util.pf_color( util.PF_Fg.WHITE ) 
      fmt.print( "\n" )
      util.pf_style_reset()
    } 
    else 
    { 
      fmt.print( "\n" ) 
      util.pf_style_reset()
    }
    util.pf_style_reset()

    libc.system( "del .git\\index.lock" )
    libc.system( "git add ." )
    libc.system( fmt.ctprintf( "git commit -m \"%v\"", commit_message) )
    libc.system( fmt.ctprintf( "git push %v %v", remote, branch) )
  }
}

EXP_ENV_VAR_BUF_MAX :: 256
// expand_environment_variable :: proc( var_str: [^]u16 )
expand_environment_variable :: proc( var_str_in: string ) -> ( string )
{
  var_str : [EXP_ENV_VAR_BUF_MAX]u16
  buf     : [EXP_ENV_VAR_BUF_MAX]u16
  for c, i in var_str_in
  {
    var_str[i] = u16(c)
  }
  // win.LPCWSTR
  // win.LPWSTR
  ret := win.ExpandEnvironmentStringsW( raw_data(&var_str), raw_data(&buf), EXP_ENV_VAR_BUF_MAX )
  if ret <= 0 { fmt.println( "[ERROR] win.ExpandEnvironmentStringsW failed with:", var_str ) }
  // fmt.println( "ret:", ret )
  buf_str_sb := str.builder_make( context.temp_allocator )
  for i in 0..<ret
  {  
    // fmt.print( rune(buf[i]), "(", buf[i], ")," )
    str.write_byte( &buf_str_sb, byte(buf[i]) ) 
  } 
  buf_str : string = str.to_string( buf_str_sb )
  // fmt.println( var_str_in, "->", buf_str )

  return buf_str
}

config_read :: proc( path: string, config: ^config_t )
{
  // set default values for presets
  config.available = false
  config.concise   = true
  config.utf8      = true

  // read config file
  
  src_bytes, ok := os.read_entire_file( path, context.allocator )
  if !ok || len( src_bytes ) <= 0
  { fmt.eprintln( "[ERROR] could not read config file: ", path ); return }
  defer delete( src_bytes, context.allocator )
  config.available = true
  src     := string( src_bytes )
  src_len := len( src )
  
  for i := 0; i < src_len; i += 1
  {
    // skip comments
    if i +1 < src_len   &&
       src[i   ] == '/' &&
       src[i +1] == '/'  
    {
      for i < src_len && src[i] != '\n' 
      { i += 1 }
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
      { i += 1 }
      
      // read value
      name_start = i
      for i < src_len && !str.is_space( rune(src[i]) ) 
      { i += 1 }
      value := src[name_start:i]
      // fmt.println( "value: ", value )

      handle_value( name, value, config )
    }
  }
}

handle_value :: proc( name: string, value: string, conf: ^config_t )
{
  if name == "path" 
  {
    // put path in the config paths array
    append( &config.paths, str.clone( value ) )
    return
  }

  // for normal values
  v, succsess := parse_value( value )
  if ( v == nil || !succsess ) && !str.contains( value, "{" )  
  { fmt.eprintfln( "[ERROR] value given for [%v] failed to parse: \"%s\"", name, value ); return }
  
  if name == "concise"
  {
    val, ok := v.(bool)
    if !ok 
    { fmt.eprintfln( "[ERROR] concise value given not boolean: \"%s\"", value ); return }
    conf.concise = val  
    // fmt.println( "conf.concise:", conf.concise )
  }
  else if name == "utf8"
  {
    val, ok := v.(bool)
    if !ok 
    { fmt.eprintfln( "[ERROR] utf8 value given not boolean: \"%s\"", value ); return }
    conf.utf8 = val  
    // fmt.println( "conf.utf8:", conf.utf8 )
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
