package term_tools_math

import      "core:os"
import      "core:fmt"
import      "core:mem"
import str  "core:strings"
import      "core:c/libc"
import      "core:debug/trace"
import      "vendor:glfw"
import gl   "vendor:OpenGL"
import util ".."


parsed_value_t :: union 
{
	bool,
	int,
	f32,
}

Token_Type :: enum
{
  NUMBER,

  ADDITION,
  SUBTRACT,
  MULTIPLY,
  DIVIDE,

  PAREN_OPEN,
  PAREN_CLOSE,
}
token_t :: struct
{
  type  : Token_Type,
  start : int,
  end   : int,
  val   : f64,
}


main :: proc()
{
  // ---- init odin stuff ----

  when ODIN_DEBUG 
  {
    // setup tracking allocator
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)
		defer 
    {
			if len(track.allocation_map) > 0 
      {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map 
        {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 
      {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array 
        {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}

    // init stack trace
	  trace.init(&util.global_trace_ctx)
	  defer trace.destroy(&util.global_trace_ctx)
	  context.assertion_failure_proc = util.debug_trace_assertion_failure_proc

    // // setup :spall
	  // spall_ctx = spall.context_create("trace.spall")
	  // defer spall.context_destroy(&spall_ctx)

	  // buffer_backing := make([]u8, spall.BUFFER_DEFAULT_SIZE)
	  // defer delete(buffer_backing)

	  // spall_buffer = spall.buffer_create(buffer_backing, u32(sync.current_thread_id()))
	  // defer spall.buffer_destroy(&spall_ctx, &spall_buffer)
	}
  // setup log
  // context.logger = log.create_console_logger()
  context.logger = util.create_console_logger()
  when ODIN_DEBUG // no need to as windows does it automatically
  { defer util.destroy_console_logger( context.logger ) }
  // { defer free( context.logger.data ) }


  if len(os.args) <= 1
  {
    fmt.println( "[ERROR] no argument given" )
    return
  }

  sb := str.builder_make()

  for i in 1..<len(os.args)
  {
    str.write_string( &sb, os.args[i] )
  }
  txt := str.to_string( sb )

  fmt.println( txt )

  // str.builder_destroy( &sb )
  str.builder_reset( &sb )

  tokens := make( [dynamic]token_t )

  // for i in 0..<len(txt)
  for i := 0; i < len(txt); i += 1
  {
    if libc.isdigit( i32(txt[i]) ) > 0
    {
      start := i
      offs  := 0
      for start + offs < len(txt) && 
          ( txt[start+offs] == '.' || 
            libc.isdigit( i32(txt[start+offs]) ) > 0 )
      {
        offs += 1
      }
      v, ok := parse_value( txt[start:start+offs] )
      if !ok { fmt.println( "[ERROR] parsing value:", txt[start:start+offs] ) }
      val : f32 = 0.0
      val, ok = v.(f32)
      if !ok 
      {
        ival, iok := v.(int)
        if !iok
        {
          fmt.println( "[ERROR] parsing value:", txt[start:start+offs], ", not f32 or int" ) 
        }
        else { val = f32(ival) }
      }
      append( &tokens, token_t{ type=Token_Type.NUMBER, start=start, end=start+offs, val=f64(val) } )
      i += offs -1
      continue
    }
    else if txt[i] == '+'
    {
      append( &tokens, token_t{ type=Token_Type.ADDITION, start=i, end=i+1 } )
      continue
    }
    else if txt[i] == '-'
    {
      append( &tokens, token_t{ type=Token_Type.SUBTRACT, start=i, end=i+1 } )
      continue
    }
    else if txt[i] == '*'
    {
      append( &tokens, token_t{ type=Token_Type.MULTIPLY, start=i, end=i+1 } )
      continue
    }
    else if txt[i] == '/'
    {
      append( &tokens, token_t{ type=Token_Type.DIVIDE, start=i, end=i+1 } )
      continue
    }
  }

  for t in tokens
  {
    fmt.printfln( "%v | %v, value: %v, start: %v, end: %v", t.type, txt[t.start:t.end], t.val, t.start, t.end )
  }

  run_visualization()
}

parse_value :: proc( value: string ) -> ( v: parsed_value_t, success: bool )
{
  if      str.compare( value, "true" )  == 0 { return true,  true }
  else if str.compare( value, "false" ) == 0 { return false, true }
  else if libc.isdigit( i32(value[0]) ) > 0
  {
    all_numeric := true
    for r in value { if libc.isdigit( i32(r) ) <= 0 && r != '.' { all_numeric = false; break } }
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

run_visualization :: #force_inline proc()
{
  if !window_create( 0.75, 0.75, 0.1, 0.1, "visualization", Window_Type.MINIMIZED, true )
  {
    fmt.eprintln( "[ERROR] creating window" )
    os.exit( 1 )
  }
  
  input_init()
  data_init()

  gl.Disable( gl.DEPTH_TEST )
  text_init( "../_assets/fonts/JetBrainsMonoNL-Regular.ttf" )
  renderer_init()

  for !window_should_close()
  {
    // fmt.println( "loop" )
    glfw.PollEvents();

    data_pre_updated()

    if input.key_states[Key.ESCAPE].pressed 
    { break }

    gl.ClearColor( 1, 0, 1, 1 )
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

    text_draw_string( fmt.tprintf( "fps: %.2f", data.cur_fps ), vec2{ 0.00, 0.00 } )

    glfw.SwapBuffers( data.window )

    input_update()
  }

  data_cleanup()
}

