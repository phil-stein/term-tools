package util

import      "base:runtime"
import      "core:os"
import      "core:fmt"
import      "core:log"
import      "core:time"
import str  "core:strings"
import      "core:debug/trace"
import      "core:terminal/ansi"

PF_Mode :: enum
{
  NORMAL                 = 0,
  BOLD                   = 1,    // bright
  DIM                    = 2,
  ITALIC                 = 3,
  UNDERLINE              = 4,
  REVERSE                = 5, // same as .BLINK_SLOW
  BLINK_SLOW             = 5, // same as .REVERSE
  BLINK_RAPID            = 6, 
  NEGATIVE_IMAGE         = 7,
  HIDDEN                 = 8, 
  STRIKETHROUGH          = 9,
  DOUBLE_UNDERLINE       = 21,

  BLACK_TEXT             = 30,
  RED_TEXT               = 31,
  GREEN_TEXT             = 32,
  YELLOW_TEXT            = 33,
  BLUE_TEXT              = 34,
  PURPLE_TEXT            = 35,
  CYAN_TEXT              = 36,
  WHITE_TEXT             = 37,
  DEFAULT_TEXT_COLOUR    = 39,

  BLACK_BACKGROUND       = 40,
  RED_BACKGROUND         = 41,
  GREEN_BACKGROUND       = 42,
  YELLOW_BACKGROUND      = 43,
  BLUE_BACKGROUND        = 44,
  MAGENTA_BACKGROUND     = 45,
  CYAN_BACKGROUND        = 46,
  WHITE_BACKGROUND       = 47,
}
// @DOC: used for setting terminal output to a specific text color, using PF_MODE(), PF_STYLE, etc.
PF_Fg :: enum
{
  BLACK    = 30,
  RED      = 31,
  GREEN    = 32,
  YELLOW   = 33,
  BLUE     = 34,
  PURPLE   = 35,
  CYAN     = 36,
  WHITE    = 37,
  DEFAULT  = 39,
}
// @DOC: used for setting terminal output to a specific background color, using PF_MODE(), PF_STYLE, etc.
PF_Bg :: enum
{
  BLACK    = 40,
  RED      = 41,
  GREEN    = 42,
  YELLOW   = 43,
  BLUE     = 44,
  PURPLE   = 45,
  CYAN     = 46,
  WHITE    = 47, 
}
// @DOC: setting terminal output to a specific mode, text and background color
pf_mode :: #force_inline proc(style: PF_Mode, fg: PF_Fg, bg: PF_Bg) { fmt.printf("\033[%d;%d;%dm", style, fg, bg) }
// @DOC: setting terminal output to a specific mode and text color
pf_style  :: #force_inline proc(style: PF_Mode, color: PF_Fg)       { fmt.printf("\033[%d;%dm", style, color) }
// @DOC: setting terminal output to a specific text color
pf_color :: #force_inline proc(color: PF_Fg)                        { pf_style(PF_Mode.NORMAL, color) }
// @DOC: setting terminal output to default mode, text and background color
@(deprecated="doesnt work properly, idk why, use pf_reset_style() instead")
pf_mode_reset :: #force_inline proc()                               { pf_mode(PF_Mode.NORMAL, PF_Fg.WHITE, PF_Bg.BLACK) }
// @DOC: setting terminal output to default mode and text
pf_style_reset :: #force_inline proc()                              { pf_style(PF_Mode.NORMAL, PF_Fg.WHITE) }

// @DOC: setting terminal output to a specific mode, text and background color
pf_mode_str :: #force_inline proc(style: PF_Mode, fg: PF_Fg, bg: PF_Bg) -> string { return fmt.tprintf("\033[%d;%d;%dm", style, fg, bg) }
// @DOC: setting terminal output to a specific mode and text color
pf_style_str  :: #force_inline proc(style: PF_Mode, color: PF_Fg) -> string       { return fmt.tprintf("\033[%d;%dm", style, color) }
// @DOC: setting terminal output to a specific text color
pf_color_str :: #force_inline proc(color: PF_Fg) -> string                        { return pf_style_str(PF_Mode.NORMAL, color) }
// @DOC: setting terminal output to default mode and text
pf_style_reset_str :: #force_inline proc() -> string                              { return pf_style_str(PF_Mode.NORMAL, PF_Fg.WHITE) }

default_mode := PF_Mode.NORMAL
default_fg   := PF_Fg.WHITE
default_bg   := PF_Bg.BLACK
// @TODO: docs
pf_set_default   :: #force_inline proc(style: PF_Mode, fg: PF_Fg, bg: PF_Bg) { default_mode = style; default_fg = fg; default_bg = bg }
pf_reset_default :: #force_inline proc()                                     { default_mode = PF_Mode.NORMAL; default_fg = PF_Fg.WHITE; default_bg = PF_Bg.BLACK }
pf_default       :: #force_inline proc()                                     { pf_mode( default_mode, default_fg, default_bg ) }
pf_default_str   :: #force_inline proc() -> string                           { return pf_mode_str( default_mode, default_fg, default_bg ) }




// setup debug/trace
global_trace_ctx: trace.Context
debug_trace_assertion_failure_proc :: proc(prefix, message: string, loc := #caller_location) -> ! 
{
	runtime.print_caller_location( loc )
	runtime.print_string( " " )
	runtime.print_string( prefix )
	if len(message) > 0 
  {
		runtime.print_string( ": " )
		runtime.print_string( message )
	}
	runtime.print_byte( '\n' )

	// ctx := &trace_ctx
	ctx := &global_trace_ctx
	if !trace.in_resolve( ctx ) 
  {
		buf: [64]trace.Frame
		runtime.print_string( "Debug Trace:\n" )
		frames := trace.frames( ctx, 1, buf[:] )
		for f, i in frames 
    {
			fl := trace.resolve( ctx, f, context.temp_allocator )
			if fl.loc.file_path == "" && fl.loc.line == 0 
      {
				continue
			}
			runtime.print_caller_location( fl.loc )
			runtime.print_string( " - frame " )
			runtime.print_int( i )
			runtime.print_byte( '\n' )
		}
	}
	runtime.trap()
}

Default_Console_Logger_Opts :: log.Options {
	.Level,
	.Terminal_Color,
	.Short_File_Path,
	.Line,
	.Procedure,
} 
create_console_logger :: proc(lowest := log.Level.Debug, opt := Default_Console_Logger_Opts, ident := "") -> log.Logger 
{
	data := new(log.File_Console_Logger_Data)
	data.file_handle = nil
	data.ident = ident
	return log.Logger{file_console_logger_proc, data, lowest, opt}
}

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
file_console_logger_proc :: proc(logger_data: rawptr, level: log.Level, text: string, options: log.Options, location := #caller_location) {
	data := cast(^log.File_Console_Logger_Data)logger_data
	h: ^os.File = os.stdout if level <= log.Level.Error else os.stderr
	// if data.file_handle != os.INVALID_HANDLE 
	if data.file_handle != nil
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
		fmt.sbprintf(&buf, "[{}] ", os.get_current_thread_id())
	}

	if data.ident != "" {
		fmt.sbprintf(&buf, "[%s] ", data.ident)
	}
	//TODO(Hoej): When we have better atomics and such, make this thread-safe
	fmt.fprintf(h, "%s%s\n", str.to_string(buf), text)

}

do_level_header :: proc(opts: log.Options, str: ^str.Builder, level: log.Level) 
{
	RESET     :: ansi.CSI + ansi.RESET           + ansi.SGR
	RED       :: ansi.CSI + ansi.FG_RED          + ansi.SGR
	YELLOW    :: ansi.CSI + ansi.FG_YELLOW       + ansi.SGR
	DARK_GREY :: ansi.CSI + ansi.FG_BRIGHT_BLACK + ansi.SGR
	CYAN      :: ansi.CSI + ansi.FG_CYAN         + ansi.SGR

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
log_progress    := [?]rune{ '|', '/', '-', '\\' } 
log_process_idx : int
do_progress_header :: proc(opts: log.Options, buf: ^str.Builder ) 
{
	RESET     :: ansi.CSI + ansi.RESET           + ansi.SGR
	DARK_GREY :: ansi.CSI + ansi.FG_BRIGHT_BLACK + ansi.SGR

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
do_location_header :: proc(opts: log.Options, buf: ^str.Builder, location := #caller_location) 
{
	RESET     :: ansi.CSI + ansi.RESET           + ansi.SGR
	DARK_GREY :: ansi.CSI + ansi.FG_BRIGHT_BLACK + ansi.SGR

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

// // :spall automatic profiling of every procedure:
// @(instrumentation_enter)
// spall_enter :: proc "contextless" (proc_address, call_site_return_address: rawptr, loc: runtime.Source_Code_Location) {
// 	spall._buffer_begin(&spall_ctx, &spall_buffer, "", "", loc)
// }
// @(instrumentation_exit)
// spall_exit :: proc "contextless" (proc_address, call_site_return_address: rawptr, loc: runtime.Source_Code_Location) {
// 	spall._buffer_end(&spall_ctx, &spall_buffer)
// }

// @TODO: 
// // :tracy automatic profiling of every procedure:
// tracy_ctx_arr : [dynamic]tracy.ZoneCtx
// @(instrumentation_enter)
// __tracy_instrumentation_enter :: #force_inline proc "contextless" (proc_address, call_site_return_address: rawptr, loc: runtime.Source_Code_Location) {
//   {
//   context = runtime.default_context()
//   append( &tracy_ctx_arr, tracy.ZoneBegin( active=true, depth=tracy.TRACY_CALLSTACK, loc=loc ) )
//   }
//   // libc.printf( "cock enter\n" )
// }
// @(instrumentation_exit)
// __tracy_instrumentation_exit :: #force_inline proc "contextless" (proc_address, call_site_return_address: rawptr, loc: runtime.Source_Code_Location) {
// 	// spall._buffer_end(&spall_ctx, &spall_buffer)
//   // {
//   //   context = runtime.default_context()
//   //   ctx := pop( &tracy_ctx_arr, loc=loc )
//   //   tracy.ZoneEnd( ctx )
//   // }
//   // libc.printf( "cock exit\n" )
// }

