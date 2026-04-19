package search

import      "core:os"
import      "core:fmt"
import str  "core:strings"
import      "core:math/bits"
import win  "core:sys/windows"
import util ".."


total_files  : i32 = 0
total_dirs   : i32 = 0
offset       : i32 = 0
subdir_depth : i32 = 0
// SUBDIR_DEPTH_MAX := 1 << 32 
SUBDIR_DEPTH_MAX : i32 = bits.I32_MAX

FILES_MAX := 1 << 32  // max files shown in subdirs

MAX_LINE_WIDTH := 50  // with of line without the size

ONLY_SHOW_DIRS := false 

// LINE_INACT :: "┆"
LINE_INACT :: "┊" 
// LINE_INACT :: "╏"
// LINE_INACT :: "╎"
LINE_ACT   := "│"

// DIR_ENTER  :: "╰"
// DIR_ENTER  :: "├"
// DIR_ENTER  :: "┡"
// DIR_ENTER  :: "━"
DIR_ENTER  :: "└"

FILE_NAME_MATCH  :: "├"

DIR_ICON  := ""
FILE_ICON := "󰈙"

CONFIG_ICON :: ""

has_path_arg := false
path_arg_idx := 1

found_matches := 0

main :: proc()
{  
  when ODIN_OS == .Windows
  {
    // @NOTE: enable utf output to console, windows specific
    win.SetConsoleOutputCP( win.CODEPAGE(win.CP_UTF8) )
  }

  for arg, i in os.args[1:]
  {
    if arg[0] == '-' 
    {
      if arg[1] == 'h' { print_help() }
    }
    else 
    {
      has_path_arg = true
      path_arg_idx = i + 1
    }
  }

  if !has_path_arg || len(os.args) < 2
  {
    fmt.println( "[ERROR] no args given" )
    print_help()
    return
  }

  // path := str.concatenate( { os.get_current_directory(), "\\", os.args[path_arg_idx] } )
  // fmt.println( "path: ", os.get_current_directory() )

  path, err := os.get_working_directory( context.temp_allocator )
  if err != os.ERROR_NONE { fmt.eprintln( "[ERROR] couldnt open executable directory" ); return } 
  fmt.println( DIR_ICON /* CONFIG_ICON */, path )

  search_directory( path )

  fmt.println( "└", found_matches, "matches found for:", os.args[path_arg_idx] )
  fmt.println()
}

print_help :: proc()
{
  fmt.println( "[HELP]" )
  fmt.println( " >search <arg>" )
  fmt.println( " >search -h" )
}

// calls the recursive function
search_directory :: proc( name: string )
{
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
  defer os.file_info_slice_delete( fis, context.temp_allocator ) // fis is a slice, we need to remember to free it

  fis, err = os.read_dir(f, -1, context.temp_allocator ) // -1 reads all file infos
  if err != os.ERROR_NONE 
  {
    fmt.eprintln( "[ERROR] could not read directory: ", name )
    os.exit(2)
  }


  file_count := 0

  for fi, i in fis 
  {
    total_files += 1
    file_count  += 1

    if fi.type == os.File_Type.Directory { continue }
    extension := str.split( fi.name, "." )
    // fmt.println( extension )
    defer delete( extension )
    if len(extension) > 1 && ( extension[1] == "lib" || extension[1] == "obj" || extension[1] == "exe" || extension[1] == "a" || extension[1] == "pdb" || 
                               extension[1] == "png" || extension[1] == "jpg"|| extension[1] == "jpeg" || extension[1] == "mp4" || 
                               extension[1] == "blend" || extension[1] == "fbx" || extension[1] == "glb" || extension[1] == "gltf" )
    { 
      fmt.println( LINE_INACT, "!!! skipped", fi.name )
      continue
    }
    
    if !search_file( fi, os.args[path_arg_idx] )
    {
      continue
    }

    if subdir_depth > 1 && file_count > FILES_MAX
    {
      tmp := LINE_ACT
      LINE_ACT = "└"
      tmp_dir_icon := FILE_ICON
      FILE_ICON = "..."
      print_file_name( fi, true, true, true, "..." )
      // fmt.println( "1", fi.name )
      FILE_ICON = tmp_dir_icon
      LINE_ACT = tmp

      break
    }
    if i == len(fis) -1
    {
      tmp := LINE_ACT
      LINE_ACT = "└"
      print_file_name( fi )
      // fmt.println( "2", fi.name )
      LINE_ACT = tmp
    }
    else 
    { 
      print_file_name( fi ) 
      // fmt.println( "3", fi.name )
    }

    if fi.type == os.File_Type.Directory && subdir_depth < i32(SUBDIR_DEPTH_MAX)
    {
      total_files -= 1
      total_dirs  += 1

      subdir_depth += 1
      offset += 2
      search_directory_recursive( fi.fullpath )
      subdir_depth -= 1
      offset -= 2
    }
    else if !ONLY_SHOW_DIRS && fi.type == os.File_Type.Directory && subdir_depth > 1 &&
            subdir_depth >= i32(SUBDIR_DEPTH_MAX)
    {
      tmp := LINE_ACT
      LINE_ACT = "└"
      tmp_dir_icon := DIR_ICON
      DIR_ICON = "..."
      offset += 2
      print_file_name( fi, true, true, true, "..." )
      // fmt.print( "file-name" )
      // fmt.println( "4", fi.name )
      offset -= 2
      DIR_ICON = tmp_dir_icon
      LINE_ACT = tmp
    }

    fmt.println( LINE_ACT ) 
  }

}

print_file_name :: proc( fi: os.File_Info, hide_size: bool = false, hide_icon: bool = false, name_override: bool = false, new_name: string = "" )
{
  if ONLY_SHOW_DIRS && fi.type != os.File_Type.Directory { return }

  char_count := 0


  if offset < 2
  {
    if !hide_icon
    {
      if fi.type == os.File_Type.Directory { fmt.printf( "%s %s ", DIR_ENTER, DIR_ICON ); char_count += 3 }
      else         { fmt.printf( "%s %s ",  LINE_ACT,  FILE_ICON ); char_count += 3 }
      // else         { fmt.printf( "%s %s",  LINE_ACT,  FILE_ICON); char_count += 3 }
    }
    else
    {
      if fi.type == os.File_Type.Directory { fmt.printf( "%s ", DIR_ENTER ); char_count += 1 }
      else         { fmt.printf( "%s ", LINE_ACT  ); char_count += 1 }
    }
  }
  else { fmt.printf( LINE_INACT ); char_count += 1 }

  start := offset < 2 ? 0 : offset -1
  for i in 0 ..< offset
  {
    if i == start
    { 
      // if fi.type == os.File_Type.Directory { fmt.printf( "%s %s ", DIR_ENTER, hide_icon ? "" : DIR_ICON ); char_count += 3 }
      // else         { fmt.printf( "%s %s",  LINE_ACT,  hide_icon ? "" : FILE_ICON ); char_count += 3 }
      if !hide_icon
      {
        if fi.type == os.File_Type.Directory { fmt.printf( "%s %s ", DIR_ENTER, DIR_ICON ); char_count += 3 }
        else         { fmt.printf( "%s %s ",  LINE_ACT,  FILE_ICON); char_count += 3 }
        // else         { fmt.printf( "%s %s",  LINE_ACT,  FILE_ICON); char_count += 3 }
      }
      else
      {
        if fi.type == os.File_Type.Directory { fmt.printf( "%s ", DIR_ENTER ); char_count += 1 }
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

    if fi.type == os.File_Type.Directory { fmt.printf( "\\" ); char_count += 1 }
  }

  // fmt.printf( " % *d", 30 - char_count, fi.size ) 
  
  max_chars = MAX_LINE_WIDTH - char_count
  assert( max_chars >= 0 )

  if fi.type != os.File_Type.Directory && !hide_size
  {
    // if      max_chars >= 3 { fmt.printf( "  " ); char_count += 2 }
    // else                   { fmt.printf( "XX" ); char_count += 1 }
    fmt.printf( "  " ); char_count += 2 

    // fmt.printf("\033[%d;%d;%dm", 2, 30, 40) // mode, fg, bg
    // fmt.printf( "\033[%d;%dm", PF_DIM, PF_WHITE )
    util.pf_style( util.PF_Mode.DIM, util.PF_Fg.WHITE )
    for i in 0 ..< max_chars
    {
      fmt.printf( "." )
    }
    // fmt.printf( "%2d", max_chars )
    // fmt.printf("\033[%d;%d;%dm", 0, 37, 40) // mode, fg, bg
    // fmt.printf( "\033[%d;%dm", PF_NORMAL, PF_WHITE )
    util.pf_style_reset()

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

search_file :: proc( fi: os.File_Info, match: string ) -> ( found_text: bool )
{
	data, err := os.read_entire_file( fi.fullpath, context.allocator )
	if err != os.ERROR_NONE
  {
    fmt.eprintln( "[ERROR] could not open file for reading:", fi.name, err )
		return
	}
	defer delete( data, context.allocator )

  // check file name if match
  if str.contains( fi.name, match )
  {
    // print_file_name( fi )
    fmt.printf( "%s %s", FILE_NAME_MATCH, FILE_ICON )
    print_highlited_match( fi.name, match )
  }

  found_text = false
  current_matches := 0
  line_nr := 0
	it := string( data )
	for line in str.split_lines_iterator( &it ) 
  {
    line_nr += 1
		// process line
    if str.contains( line, match )
    {
      // if found_matches <= 0
      if current_matches <= 0 
      {
        // cwd, err2 := os.get_working_directory( context.temp_allocator )
        // if err2 != os.ERROR_NONE { fmt.eprintln( "[ERROR] getting current working dir", err2 ); return }
        // fmt.println( DIR_ICON /* CONFIG_ICON */, cwd )
        // -- ─│─│┌┐┘└           -> window corners
        fmt.print( "├─────┐\n" )
      }

      found_text = true
      found_matches += 1
      current_matches += 1
      // fmt.printfln( "%s %03d %s %v", LINE_ACT, line_nr, LINE_ACT, line )
      fmt.printf( "%s %03d %s", LINE_ACT, line_nr, LINE_ACT)
      // sb := str.builder_make()
      // for i in 0..<len(line)
      print_highlited_match( line, match )
    }
	}
  return found_text
}

print_highlited_match :: proc( txt, match: string )
{
  for i := 0; i < len(txt); i += 1
  {
    if i + len(match) < len(txt) - i && 
       txt[i:i+len(match)] == match
    {
      fmt.print( util.pf_mode_str( util.PF_Mode.NORMAL, util.PF_Fg.BLACK, util.PF_Bg.WHITE ))
      fmt.print( match )
      fmt.print( util.pf_style_reset_str() )
      i += len(match) -1
    }
    else { fmt.printf( "%c", txt[i] ) }
  }
  fmt.println()
}
