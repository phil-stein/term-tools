package notizn

import     "core:fmt"
import     "core:os"
import     "core:log"
import     "core:time"
// import     "core:encoding/ansi"
import     "core:terminal/ansi"
import str "core:strings"
import win "core:sys/windows"



@(private="file")
Default_Console_Logger_Opts :: log.Options {
	.Level,
	.Terminal_Color,
	.Short_File_Path,
	.Line,
	.Procedure,
} 
@(private="file")
create_console_logger :: proc(lowest := log.Level.Debug, opt := Default_Console_Logger_Opts, ident := "") -> log.Logger 
{
	data := new(log.File_Console_Logger_Data)
	data.file_handle = os.INVALID_HANDLE
	data.ident = ident
	return log.Logger{file_console_logger_proc, data, lowest, opt}
}

@(private="file")
destroy_console_logger :: proc(log: log.Logger) 
{
	free(log.data)
}

level_headers := [?]string{
	 0..<10 = "[DEBUG] ",
	10..<20 = "[INFO ] ",
	20..<30 = "[WARN ] ",
	30..<40 = "[ERROR] ",
	40..<50 = "[FATAL] ",
}
RESET     :: ansi.CSI + ansi.RESET           + ansi.SGR
RED       :: ansi.CSI + ansi.FG_RED          + ansi.SGR
YELLOW    :: ansi.CSI + ansi.FG_YELLOW       + ansi.SGR
DARK_GREY :: ansi.CSI + ansi.FG_BRIGHT_BLACK + ansi.SGR
CYAN      :: ansi.CSI + ansi.FG_CYAN         + ansi.SGR

@(private="file")
file_console_logger_proc :: proc(logger_data: rawptr, level: log.Level, text: string, options: log.Options, location := #caller_location) {
	data := cast(^log.File_Console_Logger_Data)logger_data
	h: os.Handle = os.stdout if level <= log.Level.Error else os.stderr
	if data.file_handle != os.INVALID_HANDLE 
  {
		h = data.file_handle
	}
	backing: [1024]byte //NOTE(Hoej): 1024 might be too much for a header backing, unless somebody has really long paths.
	buf := str.builder_from_bytes(backing[:])


	do_level_header( options, &buf, level )
	do_location_header( options, &buf, location )
  do_progress_header( options, &buf )
	
  fmt.sbprint(&buf, "| ")

	// when time.IS_SUPPORTED {
	// 	do_time_header(options, &buf, time.now())
	// }


	if .Thread_Id in options {
		// NOTE(Oskar): not using context.thread_id here since that could be
		// incorrect when replacing context for a thread.
		fmt.sbprintf(&buf, "[{}] ", os.current_thread_id())
	}

	if data.ident != "" {
		fmt.sbprintf(&buf, "[%s] ", data.ident)
	}
	//TODO(Hoej): When we have better atomics and such, make this thread-safe
	fmt.fprintf(h, "%s%s\n", str.to_string(buf), text)

}

@(private="file")
do_level_header :: proc(opts: log.Options, str: ^str.Builder, level: log.Level) 
{
	col := RESET
	switch level 
  {
	  case log.Level.Debug:         col = DARK_GREY
	  case log.Level.Info:          col = CYAN // RESET
	  case log.Level.Warning:       col = YELLOW
	  case log.Level.Error, .Fatal: col = RED
	}

	if log.Options.Level in opts 
  {
		if log.Options.Terminal_Color in opts 
    {
			fmt.sbprint(str, col)
		}
		fmt.sbprint(str, level_headers[level])
		if log.Options.Terminal_Color in opts 
    {
			fmt.sbprint(str, RESET)
		}
	}
}

@(private="file")
do_time_header :: proc(opts: log.Options, buf: ^str.Builder, t: time.Time) {
	when time.IS_SUPPORTED {
		if log.Full_Timestamp_Opts & opts != nil {
			fmt.sbprint(buf, "[")
			y, m, d := time.date(t)
			h, min, s := time.clock(t)
			if .Date in opts {
				fmt.sbprintf(buf, "%d-%02d-%02d", y, m, d)
				if .Time in opts {
					fmt.sbprint(buf, " ")
				}
			}
			if .Time in opts { fmt.sbprintf(buf, "%02d:%02d:%02d", h, min, s) }
			fmt.sbprint(buf, "] ")
		}
	}
}
@(private="file")
log_progress    := [?]rune{ '|', '/', '-', '\\' } 
@(private="file")
log_process_idx : int
@(private="file")
do_progress_header :: proc(opts: log.Options, buf: ^str.Builder ) 
{
	if log.Options.Terminal_Color in opts 
  {
		fmt.sbprint(buf, DARK_GREY)
	}

	fmt.sbprintf(buf, "[%v]", log_progress[log_process_idx] )

  log_process_idx = log_process_idx +1 if log_process_idx+1 < len(log_progress) else 0

	if log.Options.Terminal_Color in opts 
  {
		fmt.sbprint(buf, RESET)
	}
}

@(private="file")
do_location_header :: proc(opts: log.Options, buf: ^str.Builder, location := #caller_location) 
{
	if log.Location_Header_Opts & opts == nil 
  {
		return
	}

	if log.Options.Terminal_Color in opts 
  {
		fmt.sbprint(buf, DARK_GREY)
	}

	fmt.sbprint(buf, "[")

	file := location.file_path
	if .Short_File_Path in opts 
  {
		last := 0
		for r, i in location.file_path 
    {
			if r == '/' {
				last = i+1
			}
		}
		file = location.file_path[last:]
	}

	if log.Location_File_Opts & opts != nil 
  {
		fmt.sbprint(buf, file)
	}
	if .Line in opts 
  {
		if log.Location_File_Opts & opts != nil 
    {
			fmt.sbprint(buf, ":")
		}
		fmt.sbprint(buf, location.line)
	}

	if .Procedure in opts 
  {
		if (log.Location_File_Opts | {.Line}) & opts != nil 
    {
			fmt.sbprint(buf, ":")
		}
		fmt.sbprintf(buf, "%s()", location.procedure)
	}

	fmt.sbprint(buf, "] ")

	if log.Options.Terminal_Color in opts 
  {
		fmt.sbprint(buf, RESET)
	}
}

//
// :start | :main | :begin
//


// :types | typedefs | :definitions

Message_Type :: enum 
{
  NOTE,
  TODO,
  TMP,
  BUG,
  UNKNOWN,
}

// :variables | :constants

total_files  : i32 = 0
total_dirs   : i32 = 0
offset       : i32 = 0
subdir_depth : i32 = 1
SUBDIR_DEPTH_MAX := 0 


main :: proc()
{
  // setup log
  // context.logger = log.create_console_logger()
  context.logger = create_console_logger()
  when ODIN_DEBUG // no need to as windows does it automatically
  { defer destroy_console_logger( context.logger ) }

  // @NOTE: enable utf output to console, windows specific
  win.SetConsoleOutputCP( win.CODEPAGE(win.CP_UTF8) )

  // for arg, i in os.args[1:]
  // {
  // }

  // specified directory 
  if len(os.args) > 1 
  { 
    path := str.concatenate( { os.get_current_directory(), "\\", os.args[1] } )
    fmt.println( "path: ", path )
    search_directory_recursive( path )
  }
  else // current directory
  {
    // search_directory( "C:\\Workspace\\odin\\term-tools" )
    cwd := os.get_current_directory()
    fmt.println( "cwd: ", cwd )
    search_directory_recursive( cwd )
  }
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

  fis, err = os.read_dir( f, -1 ) // -1 reads all file infos
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

    // if subdir_depth > 1 && file_count > FILES_MAX
    // {
    //   tmp := LINE_ACT
    //   LINE_ACT = "└"
    //   tmp_dir_icon := FILE_ICON
    //   FILE_ICON = "..."
    //   print_file_name( fi, true, true, true, "..." )
    //   FILE_ICON = tmp_dir_icon
    //   LINE_ACT = tmp
    //
    //   break
    // }
    // if i == len(fis) -1
    // {
    //   tmp := LINE_ACT
    //   LINE_ACT = "└"
    //   print_file_name( fi )
    //   LINE_ACT = tmp
    // }
    // else { print_file_name( fi ) }

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
    // else if fi.is_dir && subdir_depth > 1 &&
    //         subdir_depth >= i32(SUBDIR_DEPTH_MAX)
    // {
    //   // tmp := LINE_ACT
    //   // LINE_ACT = "└"
    //   // tmp_dir_icon := DIR_ICON
    //   // DIR_ICON = "..."
    //   // offset += 2
    //   // print_file_name( fi, true, true, true, "..." )
    //   // offset -= 2
    //   // DIR_ICON = tmp_dir_icon
    //   // LINE_ACT = tmp

    // }
    
    if !fi.is_dir { search_file( fi ) }
  }
}

search_file :: proc( fi: os.File_Info )
{
  txt, err := os.read_entire_file_from_filename_or_err( fi.fullpath, context.allocator )
  if err != os.ERROR_NONE { log.error( "file not found: ", err ) }
  defer delete( txt, context.allocator )

  printed_file_name := false
  // fmt.println( "[FILE] ", fi.name )

	it := string( txt )
  line_nr := 0
	for line in str.split_lines_iterator( &it )
  {
    line_nr += 1
    // match_str := "@(TODO=\""
    match_str_arr := [?]string{ "@(NOTE=\"", "@(TODO=\"", "@(TMP=\"", "@(BUG=\"", "@(UNKNOWN=\"" } 
    for match_str, i in match_str_arr
    {
      ok: bool
      printed_file_name, ok = search_file_match_str( fi.name, line, match_str, Message_Type(i), line_nr, printed_file_name )
    }
	}
}
search_file_match_str :: proc( fi_name, line, match_str: string, match_str_type: Message_Type, line_nr: int, _printed_file_name: bool ) -> ( printed_file_name, ok: bool )
{
  printed_file_name = _printed_file_name
    
  idx := -1 
  idx = str.index( line, match_str )
  if idx >= 0   // if str.contains( line, "@(TODO=\"" ) 
  {
    idx += len(match_str)
    end := 0
    for end = idx + len(match_str); end < len(line) && line[end] != '"'; end += 1 
    { /* fmt.print( rune(line[end]) ) */ }
    // fmt.print( "\n" )

    // str is idx -> end
    msg := str.cut( line, idx, end - idx)
    log.info( "msg: ", msg )

    if !printed_file_name { print_file_name( fi_name ); printed_file_name = true }

    print_message( msg, match_str_type )

    return printed_file_name, true
  }
  return printed_file_name, false
}

print_file_name :: proc( name: string )
{
  fmt.println( "", name )
}
print_message :: proc( msg: string, type: Message_Type )
{
  fmt.print( "└ " )
  // fmt.print( "- " )

	fmt.print( DARK_GREY )
  switch type
  {
    case Message_Type.NOTE:
    {
      fmt.printf( "[   %v@NOTE%v] ", YELLOW, DARK_GREY )
    }
    case Message_Type.TODO:
    {
      fmt.printf( "[   %v@TODO%v] ", YELLOW, DARK_GREY )
    }
    case Message_Type.TMP:
    {
      fmt.printf( "[    %v@TMP%v] ", DARK_GREY, DARK_GREY )
    }
    case Message_Type.BUG:
    {
      fmt.printf( "[    %v@BUG%v] ", RED, DARK_GREY )
    }
    case Message_Type.UNKNOWN:
    {
      fmt.printf( "[%v@UNKNOWN%v] ", CYAN, DARK_GREY )
    }
  }
	fmt.print( RESET )

  fmt.println( msg )
}


