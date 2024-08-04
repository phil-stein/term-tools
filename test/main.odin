package oloc

import     "core:fmt"
import     "core:os"
import str "core:strings"
import     "core:c/libc"
import     "core:log"


LINE_TYPE :: enum
{
  EMPTY,
  CODE,
  COMMENT,
}

total_lines   := 0
code_lines    := 0
comment_lines := 0
empty_lines   := 0

total_files   := 0
odin_files    := 0
failed_files  := 0
  
directory     := false

main :: proc()
{
  context.logger = log.create_console_logger()

 //  fmt.println( "hello" )
	// // os.args is a []string
	// fmt.println( os.args[0] )  // executable name
	// fmt.println( os.args[1:] ) // the rest of the arguments
	// fmt.println( len(os.args) ) // the rest of the arguments

  // no arg given
  if len( os.args ) <= 1
  {
    fmt.println( "[ERROR] no argument given\n",
                 "usage:\n",
                 " > oloc .\n",
                 " > oloc some_dir\n",
                 " > oloc file.odin\n",
                 " > oloc path/to/some/dir\n",
                 " > oloc path/to/file.odin" )
    os.exit( 0 )
  }
  
  
  // single file
  if len(os.args) > 1 && 
     str.contains( os.args[1], ".odin" ) 
  { 
    _total_lines, _code_lines, _comment_lines, _empty_lines, ok := count_lines_in_file( os.args[1] )
    if !ok { os.exit( 1 ) }
    total_lines   += _total_lines
    code_lines    += _code_lines
    comment_lines += _comment_lines
    empty_lines   += _empty_lines
  }
  else // directory
  {
    directory = true
    
    search_directory( os.args[1] )
  }

  print_result()

}

print_result :: proc ()
{
  // fmt.println( "total:" )
  // fmt.println( " total_lines:   ", total_lines )
  // fmt.println( " code_lines:    ", code_lines )
  // fmt.println( " comment_lines: ", comment_lines )
  // fmt.println( " empty_lines:   ", empty_lines )

  fmt.println(  " ----------------------" )
  if directory
  {
  fmt.printfln( "  total files:  % *d", 6, total_files )
  fmt.printfln( "  odin files:   % *d", 6, total_files )
  if failed_files > 0 { fmt.printfln( "  failed files: % *d", 6, failed_files ) }
  fmt.println(  " - - - - - - - - - - - " )
  }
  // // fmt.printf( "\033[4m" )
  // fmt.printfln( "  \033[4mempty:        % *d\033[0m", 6, empty_lines )
  // fmt.printfln( "  \033[4mcomment:      % *d\033[0m", 6, comment_lines )
  // fmt.printfln( "  \033[4mcode:         % *d\033[0m", 6, code_lines )
  // fmt.printfln( "  \033[4mtotal:        % *d\033[0m", 6, total_lines )
  // // fmt.printf( "\033[0m" )
  fmt.printfln( "  empty:        % *d", 6, empty_lines )
  fmt.printfln( "  comment:      % *d", 6, comment_lines )
  fmt.printfln( "  code:         % *d", 6, code_lines )
  fmt.printfln( "  total:        % *d", 6, total_lines )
  fmt.println(  " ----------------------" )
}

search_directory :: proc( name: string )
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
    defer os.file_info_slice_delete(fis) // fis is a slice, we need to remember to free it

    fis, err = os.read_dir(f, -1) // -1 reads all file infos
    if err != os.ERROR_NONE 
    {
        fmt.eprintln( "[ERROR] could not read directory: ", name )
        os.exit(2)
    }

    for fi in fis 
    {
      total_files += 1
      // log.debug( fi.name )
      // log.debug( fi.fullpath )
      if fi.is_dir
      {
        search_directory( fi.fullpath )
        total_files -= 1
      }
      else if str.contains( fi.name, ".odin" )
      {
        odin_files += 1
        _total_lines, _code_lines, _comment_lines, _empty_lines, ok := 
        count_lines_in_file( fi.fullpath )
        if !ok { failed_files += 1; continue }
        total_lines   += _total_lines
        code_lines    += _code_lines
        comment_lines += _comment_lines
        empty_lines   += _empty_lines
      }
    }
}

count_lines_in_file :: proc(path: string) -> ( total_lines, code_lines, comment_lines, empty_lines: int, ok: bool)
{
  src_bytes, _ok := os.read_entire_file( path, context.allocator )
  ok = _ok
  if !ok || len( src_bytes ) <= 0
  { fmt.eprintln( "[ERROR] could not read file: ", path ); return }
  defer delete( src_bytes, context.allocator )
  src     := string( src_bytes )
  src_len := len( src )


  in_block_comment  := false

  // go over all chars
  for i := 0; i < src_len; i += 1
  {
    line_type : LINE_TYPE = LINE_TYPE.EMPTY

    skip_to_next_line := false

    // go over all chars in one line of text
    for ; i < src_len && src[i] != '\n'; i += 1
    { 
      if in_block_comment
      {
        skip_to_next_line = true
        line_type = LINE_TYPE.COMMENT

        if src[i] == '*' && src[i +1] == '/' 
        { 
          in_block_comment = false 
          // skip_to_next_line = true
          line_type = LINE_TYPE.COMMENT
        }
      }
      else if !skip_to_next_line && src[i] == '/' && src[i +1] == '/' 
      { 
        comment_lines += 1
        skip_to_next_line = true
        line_type = LINE_TYPE.COMMENT
      }
      else if !skip_to_next_line && src[i] == '/' && src[i +1] == '*' 
      { 
        comment_lines += 1
        in_block_comment = true
        skip_to_next_line = true
        line_type = LINE_TYPE.COMMENT
      }
      else if !skip_to_next_line && !str.is_space( rune(src[i]) ) // bool(libc.isalnum( i32(src[i]) ))
      { 
        code_lines += 1
        skip_to_next_line = true
        line_type = LINE_TYPE.CODE
      }
    }

    if in_block_comment { comment_lines += 1 }
    if line_type == LINE_TYPE.EMPTY { empty_lines += 1 }

    total_lines += 1
    // fmt.println( total_lines, line_type )
  }

  // fmt.println( "total_lines:   ", total_lines )
  // fmt.println( "code_lines:    ", code_lines )
  // fmt.println( "comment_lines: ", comment_lines )
  // fmt.println( "empty_lines:   ", empty_lines )
  // fmt.println( "sum:           ", code_lines + comment_lines + empty_lines )
  assert( (code_lines + comment_lines + empty_lines) == total_lines )

  return
}
