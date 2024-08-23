package ls 

import     "core:fmt"
import     "core:os"
import str "core:strings"
import     "core:strconv"
import     "core:c/libc"
import     "core:log"
import win "core:sys/windows"
import c   "core:c"
import     "core:mem"


total_files  : i32 = 0
total_dirs   : i32 = 0
offset       : i32 = 0
subdir_depth : i32 = 1
SUBDIR_DEPTH_MAX := 2 

FILES_MAX := 1 << 32  // max files shown in subdirs

MAX_LINE_WIDTH := 50  // with of line without the size

ONLY_SHOW_DIRS := false 

// ─│─│╭╮╯╰           -> rounded window corners
// ─│─│┌┐┘└           -> window corners

// LINE_INACT :: "┆"
// LINE_INACT :: "┊" 
// LINE_INACT :: "╏"
LINE_INACT :: "╎"
LINE_ACT   := "│"

// DIR_ENTER  :: "╰"
// DIR_ENTER  :: "├"
// DIR_ENTER  :: "┡"
// DIR_ENTER  :: "━"
DIR_ENTER  :: "└"

DIR_ICON  := ""
FILE_ICON := "󰈙"

CONFIG_ICON :: ""


path_to_exec : string

active_preset := -1 // <0 means config_result.main

main :: proc()
{
  context.logger = log.create_console_logger()

  // @NOTE: enable utf output to console, windows specific
  win.SetConsoleOutputCP( win.CP_UTF8 )

  // fmt.println( "current_dir:", os.get_current_directory() )
  // path to executable
  buf : [256]c.wchar_t
  path_to_exec_len := win.GetModuleFileNameW( nil, &buf[0], 256 )
  if path_to_exec_len <= 0 { fmt.eprintln( "win.GetModuleFileNameW() failed:", path_to_exec_len ) }
  sb := str.builder_make()
  for i in 0 ..< path_to_exec_len -7 // -7 to remove '\ls.exe'
  { str.write_byte( &sb, u8(buf[i]) ) }
  path_to_exec = str.to_string( sb )
  // fmt.println( "GetModuleFileName():", path_to_exec )
 
  config_path := str.concatenate( []string{ path_to_exec, "\\..\\config\\ls.config" } )
  // config_path_slice := [?]string{ path_to_exec, "\\..\\config\\ls.config" }
  // config_path, err := str.concatenate( config_path_slice[:] )
  // if err != mem.Allocator_Error.None { fmt.eprintln( "[ERROR] alloc err" ); os.exit( 2 ) }
  // fmt.println( "config_path_slice:", config_path_slice, "len:", len(config_path_slice) )
  // fmt.println( "config_path:", config_path )
  // assert( config_path == "C:\\Workspace\\odin\\term-tools\\..\\config\\ls.config" )
  config_read( config_path )
  // config_read( "../config/ls.config" )

  // MAX_LINE_WIDTH   = config_result.main.width
  // ONLY_SHOW_DIRS   = config_result.main.dirs  
  // SUBDIR_DEPTH_MAX = config_result.main.depth 
  // FILES_MAX        = config_result.main.files 
  config_set_preset( &config_result.main )

  // assert( false ) // @TMP:

  has_path_arg := false
  path_arg     := -1

  // check for args
  //    -h    -> help
  //    -w:XX -> set max line width
  //    -d:XX -> set sub dir depth
  //    -f:XX -> set max files shown in subdirs, <=0 means no cap
  //    -dir  -> only show dirs 
  //    -X    -> preset number X
  for arg, i in os.args[1:]
  {
    // fmt.println( "arg[", i, "]: ", arg )
    if arg[0] == '-'
    {
      // -w:XX
      if arg[1] == 'w' && arg[2] == ':' && len(arg) >= 4
      {
        numstr  := arg[3:]
        num, ok := strconv.parse_int( numstr )

        if !ok
        { fmt.println( "> SET WIDTH: ", numstr, ", failed" ) }
        else 
        {
          if num < 24
          { 
            fmt.println( "! -w:", numstr, " min width is 24" ) 
            num = 24
          }
          MAX_LINE_WIDTH = num
          // fmt.println( "> SET WIDTH: ", numstr, ", MAX_LINE_WIDTH: ", MAX_LINE_WIDTH )
        }
      }
      else if arg[1] == 'd' && arg[2] == ':' && len(arg) >= 4 // -d:XX
      {
        numstr  := arg[3:]
        num, ok := strconv.parse_int( numstr )

        if !ok
        { fmt.println( "> SET DEPTH: ", numstr, ", failed" ) }
        else 
        {
          if num < 0
          { 
            fmt.println( "! -d:", numstr, " min subdirectory depth is 0" ) 
            num = 0
          }
          SUBDIR_DEPTH_MAX = num
          // fmt.println( "> SET DEPTH: ", numstr, ", : SUBDIR_DEPTH_MAX", SUBDIR_DEPTH_MAX)
        }
      } 
      else if arg[1] == 'f' && arg[2] == ':' && len(arg) >= 4 // -f:XX
      {
        numstr  := arg[3:]
        num, ok := strconv.parse_int( numstr )

        if !ok
        { fmt.println( "> SET MAX FILES: ", numstr, ", failed" ) }
        else 
        {
          if num < 1  // <1 means show all files
          { 
            // fmt.println( "! -f:", numstr, " <= 0 means all files are shown" ) 
            num = 1 << 32
          }
          FILES_MAX = num
          // fmt.println( "> SET MAX FILES: ", numstr, ", FILES_MAX: ", FILES_MAX )
        }
      }
      else if libc.isdigit( i32(arg[1]) ) > 0  // -X
      {
      // else if ( arg[1] == 'p' && arg[2] == ':' && len(arg) >= 4 ) ||  // -p:X
      //         ( libc.isdigit( i32(arg[1]) ) > 0 )                     // -X
        // numstr  := arg[2:]
        // num, ok := strconv.parse_int( numstr )
        num := int(arg[1]) - 48  // ascii code to 0-9 range

        if !config_result.presets[num].available
        { fmt.eprintln( "[ERROR] tried using preset that wasnt defined in ls.config" ); os.exit( 1 ) }
        else
        {
          if num < 0 || num > 9   // || !ok
          { fmt.println( "[ERROR] set preset: ", num, "|", rune(arg[1]), ", failed" ) }
          else 
          {
            config_set_preset( &config_result.presets[num] )
            active_preset = num
            // fmt.println( "> SET PRESET: ", num, " | ", rune(arg[1]) )
          }
        }
      }
      else if arg[1] == 'd' && arg[2] == 'i' && arg[3] == 'r' // -dir
      {
        ONLY_SHOW_DIRS = true
        // fmt.println( "> ONLY SHOW DIRS: true" )
      }
      else if arg[1] == 'h' || 
              ( arg[1] == '-' && arg[2] == 'h' ) // -h or --h
      {
        fmt.println( "  > ls        -> current path" )
        fmt.println( "  > ls <path> -> specified path" )
        fmt.println( "  > ls -dir   -> only show directories" )
        fmt.println( "  > ls -w:XX  -> specify width" )
        fmt.println( "  > ls -d:XX  -> specify subdir depth" )
        fmt.println( "  > ls -f:XX  -> specify max files shown" )
        fmt.println( "  example:" )
        fmt.println( "  > ls some/folder\\01 -dir -w:30 -d:4 -f:14" )
        os.exit( 0 )
      }
      else 
      {
        fmt.printf( "[ERROR] unknow argument: \"%s\"\n", arg )
        os.exit( 0 )
      }
    }
    else
    {
      has_path_arg = true
      path_arg     = i +1
    }
  }

  // specified directory 
  if has_path_arg && len(os.args) > 1 
  { 
    
    // path := os.get_current_directory()
    path := str.concatenate( { os.get_current_directory(), "\\", os.args[path_arg] } )
    // fmt.println( "path: ", path )
    search_directory( path )
    
  }
  else // current directory
  {
    // search_directory( "C:\\Workspace\\odin\\term-tools" )
    cwd := os.get_current_directory()
    // fmt.println( "cwd: ", cwd )
    search_directory( cwd )
  }
}

// calls the recursive function
search_directory :: proc( name: string )
{
  // name_short := str.cut( name, 0, 3 )
  fmt.println( DIR_ICON, name ) 
  fmt.print( LINE_ACT, CONFIG_ICON, " " ) 
  fmt.print( "width: ", MAX_LINE_WIDTH, ", subdir depth: ", SUBDIR_DEPTH_MAX )
  fmt.print( "\n" )
  fmt.print( LINE_ACT, CONFIG_ICON, " " ) 
  if FILES_MAX >= 1 << 31
  { fmt.print( "max files: all" ) }
  else 
  { fmt.print( "max files: ", FILES_MAX ) }
  fmt.print( ", dirs: ", ONLY_SHOW_DIRS )
  fmt.print( "\n" )
  if active_preset >= 0 // when using a preset
  {
    fmt.print( LINE_ACT, CONFIG_ICON, " preset: ", active_preset ) 
    fmt.print( "\n" )
  }
  fmt.println( LINE_ACT ) 

  search_directory_recursive( name )
}

search_directory_recursive :: proc( name: string )
{
  f, err := os.open( name )
  defer os.close(f)

  if err != os.ERROR_NONE 
  {
    // Print error to stderr and exit with errorcode
    fmt.eprintln( "[ERROR] could not open directory for reading: ", name )
    os.exit(1)
  }

  fis: []os.File_Info
  defer os.file_info_slice_delete( fis ) // fis is a slice, we need to remember to free it

  fis, err = os.read_dir(f, -1) // -1 reads all file infos
  if err != os.ERROR_NONE 
  {
    fmt.eprintln( "[ERROR] could not read directory: ", name )
    os.exit(2)
  }


  file_count := 0

  for fi, i in fis 
  {
    total_files += 1
    file_count += 1

    if subdir_depth > 1 && file_count > FILES_MAX
    {
      tmp := LINE_ACT
      LINE_ACT = "└"
      tmp_dir_icon := FILE_ICON
      FILE_ICON = "..."
      print_file_name( fi, true, true, true, "..." )
      FILE_ICON = tmp_dir_icon
      LINE_ACT = tmp

      break
    }
    if i == len(fis) -1
    {
      tmp := LINE_ACT
      LINE_ACT = "└"
      print_file_name( fi )
      LINE_ACT = tmp
    }
    else { print_file_name( fi ) }

    if fi.is_dir && subdir_depth < i32(SUBDIR_DEPTH_MAX)
    {
      total_files -= 1
      total_dirs  += 1

      subdir_depth += 1
      offset += 2
      search_directory_recursive( fi.fullpath )
      subdir_depth -= 1
      offset -= 2
    }
    else if !ONLY_SHOW_DIRS && fi.is_dir && subdir_depth >= i32(SUBDIR_DEPTH_MAX)
    {
      tmp := LINE_ACT
      LINE_ACT = "└"
      tmp_dir_icon := DIR_ICON
      DIR_ICON = "..."
      offset += 2
      print_file_name( fi, true, true, true, "..." )
      offset -= 2
      DIR_ICON = tmp_dir_icon
      LINE_ACT = tmp
    }
  }
}

print_file_name :: proc( fi: os.File_Info, hide_size: bool = false, hide_icon: bool = false, name_override: bool = false, new_name: string = "" )
{
  if ONLY_SHOW_DIRS && !fi.is_dir { return }

  char_count := 0


  if offset < 2
  {
    if !hide_icon
    {
      if fi.is_dir { fmt.printf( "%s %s ", DIR_ENTER, DIR_ICON ); char_count += 3 }
      else         { fmt.printf( "%s %s",  LINE_ACT,  FILE_ICON); char_count += 3 }
    }
    else
    {
      if fi.is_dir { fmt.printf( "%s ", DIR_ENTER ); char_count += 1 }
      else         { fmt.printf( "%s ", LINE_ACT  ); char_count += 1 }
    }
  }
  else           { fmt.printf( LINE_INACT ); char_count += 1 }

  start := offset < 2 ? 0 : offset -1
  for i in 0 ..< offset
  {
    if i == start
    { 
      // if fi.is_dir { fmt.printf( "%s %s ", DIR_ENTER, hide_icon ? "" : DIR_ICON ); char_count += 3 }
      // else         { fmt.printf( "%s %s",  LINE_ACT,  hide_icon ? "" : FILE_ICON ); char_count += 3 }
      if !hide_icon
      {
        if fi.is_dir { fmt.printf( "%s %s ", DIR_ENTER, DIR_ICON ); char_count += 3 }
        else         { fmt.printf( "%s %s",  LINE_ACT,  FILE_ICON); char_count += 3 }
      }
      else
      {
        if fi.is_dir { fmt.printf( "%s ", DIR_ENTER ); char_count += 1 }
        else         { fmt.printf( "%s ", LINE_ACT  ); char_count += 1 }
      }
    }
    else if i > start 
    { fmt.printf( "X" ); char_count += 1 }
    else 
    { 
      if  (i +1) % 2 == 0 { fmt.printf( LINE_INACT ); char_count += 1 }
      else                { fmt.printf( " " );        char_count += 1 }
    }
  }

  max_chars := MAX_LINE_WIDTH - char_count
  assert( max_chars >= 0 )

  if name_override { fmt.printf( new_name ); char_count += len(new_name) }
  else             
  { 
    if len(fi.name) >= max_chars
    {
      n := str.cut( fi.name, 0, max_chars -3 )
      fmt.printf( "%s...", n ); char_count += max_chars
    }
    else { fmt.printf( fi.name ); char_count += len(fi.name) }

    if fi.is_dir { fmt.printf( "\\" ); char_count += 1 }
  }

  // fmt.printf( " % *d", 30 - char_count, fi.size ) 
  
  max_chars = MAX_LINE_WIDTH - char_count
  assert( max_chars >= 0 )

  if !fi.is_dir && !hide_size
  {
    // if      max_chars >= 3 { fmt.printf( "  " ); char_count += 2 }
    // else                   { fmt.printf( "XX" ); char_count += 1 }
    fmt.printf( "  " ); char_count += 2 

    fmt.printf("\033[%d;%d;%dm", 2, 30, 40) // mode, fg, bg
    for i in 0 ..< max_chars
    {
      fmt.printf( "." )
    }
    // fmt.printf( "%2d", max_chars )
    fmt.printf("\033[%d;%d;%dm", 0, 37, 40) // mode, fg, bg

    // fmt.printf( "%dmb, % 4dkb, % 4db", fi.size / 1000000, fi.size / 1000, fi.size ) 

    if fi.size > 1000000000
    { fmt.printf( "%.2f gb", f32(fi.size) / 1000000000 ) }
    else if fi.size > 1000000
    { fmt.printf( "%.2f mb", f32(fi.size) / 1000000 ) }
    else if fi.size > 1000
    { fmt.printf( "%.2f kb", f32(fi.size) / 1000 ) }
    else
    { fmt.printf( "%d b",  fi.size) }

  }

  fmt.print( "\n" )

}

