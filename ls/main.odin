package ls 

import     "core:fmt"
import     "core:os"
import str "core:strings"
import     "core:c/libc"
import     "core:log"
import win "core:sys/windows"


total_files  : i32 = 0
total_dirs   : i32 = 0
offset       : i32 = 0
subdir_depth : i32 = 0
SUBDIR_DEPTH_MAX :: 3

FILES_MAX :: 8 // @TODO:



// ─│─│╭╮╯╰           -> rounded window corners
// ─│─│┌┐┘└           -> window corners

// LINE_INACT :: "┆"
// LINE_INACT :: "┊" 
// LINE_INACT :: "╏"
LINE_INACT :: "╎"
LINE_ACT   :: "│"

// DIR_ENTER  :: "╰"
// DIR_ENTER  :: "├"
// DIR_ENTER  :: "┡"
// DIR_ENTER  :: "━"
DIR_ENTER  :: "└"

DIR_ICON  := ""
FILE_ICON := "󰈙"

main :: proc()
{
  context.logger = log.create_console_logger()

  // @NOTE: enable utf output to console, windows specific
  win.SetConsoleOutputCP( win.CP_UTF8 )

  // os.args is a []string
  // fmt.println( "os.args[0]: ", os.args[0] )  // executable name
  // fmt.println( os.args[1:] ) // the rest of the arguments
  // fmt.println( "len(os.args): ", len(os.args) ) // the rest of the arguments
  // for i in 0 ..< len(os.args)
  // { fmt.println( "os.args[", i, "]: ", os.args[i] ) }

  
  // specified directory 
  if len(os.args) > 1 
  { 
    log.error( "cant do arguments yet" )
  }
  else // current directory
  {
    // search_directory( "C:\\Workspace\\odin\\term-tools" )
    cwd := os.get_current_directory()
    // fmt.println( "cwd: ", cwd )
    search_directory( cwd )
  }

}

print_result :: proc ()
{
  // fmt.println(  " ----------------------" )
  // if directory
  // {
  // fmt.printfln( "  total files:  % *d", 6, total_files )
  // fmt.printfln( "  odin files:   % *d", 6, total_files )
  // if failed_files > 0 { fmt.printfln( "  failed files: % *d", 6, failed_files ) }
  // fmt.println(  " - - - - - - - - - - - " )
  // }
  // fmt.printfln( "  empty:        % *d", 6, empty_lines )
  // fmt.printfln( "  comment:      % *d", 6, comment_lines )
  // fmt.printfln( "  code:         % *d", 6, code_lines )
  // fmt.printfln( "  total:        % *d", 6, total_lines )
  // fmt.println(  " ----------------------" )
}

// calls the recursive function
search_directory :: proc( name: string )
{
  // name_short := str.cut( name, 0, 3 )
  fmt.println( "", name ) 
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

  for fi in fis 
  {
    total_files += 1
    file_count += 1

    if file_count > FILES_MAX
    {
      tmp_dir_icon := FILE_ICON
      FILE_ICON = "..."
      print_file_name( fi, true, "" )
      FILE_ICON = tmp_dir_icon

      break
    }
    print_file_name( fi )

    if fi.is_dir && subdir_depth < SUBDIR_DEPTH_MAX 
    {
      total_files -= 1
      total_dirs  += 1

      subdir_depth += 1
      offset += 2
      search_directory_recursive( fi.fullpath )
      subdir_depth -= 1
      offset -= 2
    }
    else if fi.is_dir && subdir_depth >= SUBDIR_DEPTH_MAX 
    {
      tmp_dir_icon := DIR_ICON
      DIR_ICON = "..."
      offset += 2
      print_file_name( fi, true, "" )
      offset -= 2
      DIR_ICON = tmp_dir_icon
    }
  }
}

print_file_name :: proc( fi: os.File_Info, name_override: bool = false, new_name: string = "" )
{
  if offset < 2
  {
    if fi.is_dir { fmt.print( DIR_ENTER, DIR_ICON) }
    else         { fmt.print( LINE_ACT, FILE_ICON) }
  }
  else           { fmt.print( LINE_INACT ) }

  start := offset < 2 ? 0 : offset -1
  for i in 0 ..< offset
  {
    if i == start
    { 
      if fi.is_dir { fmt.print( DIR_ENTER, DIR_ICON ) }
      else         { fmt.print( LINE_ACT, FILE_ICON ) }
    }
    else if i > start 
    { fmt.print( " " ) }
    else 
    { 
      if  (i +1) % 2 == 0 { fmt.print( LINE_INACT ) }
      else           { fmt.print( " " ) }
    }
  }

  if name_override { fmt.print( new_name ) }
  else             
  { 
    fmt.print( fi.name ) 
    if fi.is_dir { fmt.print( "\\" ) }
  }

  // fmt.print( " | ", fi.size ) 

  fmt.print( "\n" )

}

