package cat

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
config_t :: struct
{
  available    : bool, // if .config actually defines this preset
  
  utf8         : bool,
  ansi_color   : bool,
  line_nr      : bool,
  syntax_md    : bool,
  syntax_sheet : bool,

  code_block_min_width : int,
}
config : config_t

path_to_exec : string

main :: proc()
{
  // for i in 0..=65
  // {
  //   // fmt.printf( "\033[%d;%dm", i, util.PF_Fg.WHITE )
  //   fmt.printf( "\033[%dm", i )
  //   fmt.print( i, ": test Test TEST" )
  //   util.pf_style_reset()
  //   fmt.print( "\n" )
  // }
  // assert( 0 == 1 )
  
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
 
  config_path := str.concatenate( []string{ path_to_exec, "\\config\\cat.config" }, context.temp_allocator )
  // fmt.println( "config_path:", config_path )
  config_read( config_path, &config )

  if len( os.args ) <= 1
  {
    print_help()
  }
  else
  {
    fmt.printfln( " %v", os.args[1] )

    // txt, ok := os.read_entire_file_from_filename( os.args[1] )
    txt, err := os.read_entire_file_from_path( os.args[1], context.allocator )
    defer delete(txt)

    if err != os.ERROR_NONE { fmt.println( "[ERROR] could not find file:", os.args[1] ) }
    else
    {
      defer delete( txt )
      len := len(os.args[1])
      txt_str := string(txt)
      if len > 3 &&
         os.args[1][len -1] == 'd' &&
         os.args[1][len -2] == 'm' &&
         os.args[1][len -3] == '.'
      {
        // fmt.println( "is .md" )
        if config.syntax_md { cat_md( &txt_str ) }
        else { cat_txt( &txt_str ) }
      }
      else if len > 6 &&
         os.args[1][len -1] == 't' &&
         os.args[1][len -2] == 'e' &&
         os.args[1][len -3] == 'e' &&
         os.args[1][len -4] == 'h' &&
         os.args[1][len -5] == 's' &&
         os.args[1][len -6] == '.'
      {
        fmt.println( "is .sheet | config.syntax_sheet:", config.syntax_sheet )
        if config.syntax_sheet { cat_sheet( &txt_str ) }
        else { cat_txt( &txt_str ) }
      }
      else
      {
        cat_txt( &txt_str )
      }
    }

  }

}
print_help :: proc()
{
  fmt.println( "usage:" )
  fmt.println( "  > cat file.ext" )
}

cat_txt :: proc( txt: ^string )
{
  line_nr := 1
	for line in str.split_lines_iterator(txt) 
  {
    if config.line_nr { fmt.printf( "%3d %v ", line_nr, config.utf8 ? "│" : "|" ) }
    fmt.println( line )
    line_nr += 1
  }
}

cat_sheet :: proc( txt: ^string )
{
  // fmt.println( "is .sheet" )
  fmt.println( "[NOTE] .sheet syntax isnt done" )
  sb := str.builder_make()

  line_nr := 1
	for line in str.split_lines_iterator(txt) 
  {
    len := len(line)
    if config.line_nr { str.write_string( &sb, fmt.tprintf( "%3d %v ", line_nr, config.utf8 ? "│" : "|" ) ) }

    // str.write_string( &sb, line )
    for i := 0; i < len; i += 1
    {
      if i +1 < len         &&
         line[i +0] == '\\'
      {
        if line[i +1] == '\\' ||
           line[i +1] == '$' ||
           line[i +1] == '#'
        {
          str.write_byte( &sb, line[i +1] )
          i += 1
          continue
        }
      }
      if i +1 < len        &&
         line[i +0] == '$' &&
         line[i +1] == '$' &&
         ( i > 0 ? line[i -1] != '\\' : true )  // checking if escaped, i.e. \$
      {
        i += 1
        continue
      }
      else if i +2 < len        &&
              line[i +0] == '$'
      {
        found := false
        i_offs := 1
        for i + i_offs < len 
        {  
          if line[i + i_offs]    == '$' &&
             line[i + i_offs -1] != '\\' // checking if escaped, i.e. \$
          {
            start := i +1
            end   := i + i_offs
            // fmt.println( "start:", start, ", end:", end )
            cat_sheet_parse_command( &sb, line[start:end] )
            // cat_sheet_parse_command( &sb, line[i:i+i_offs] )
            found = true
            break
          }
          i_offs += 1
        }
        if found 
        {
          i += i_offs
          continue 
        } 
      }

      str.write_byte( &sb, line[i] )
    }
    str.write_byte( &sb, '\n' )

    str.write_string( &sb, util.pf_style_reset_str() )
    fmt.print( str.to_string( sb ) )
    str.builder_reset( &sb )

    line_nr += 1
	}
}
cat_sheet_parse_command :: proc( sb: ^str.Builder, cmd: string )
{
  fmt.println( "cmd:", cmd )
}

cat_md :: proc( txt: ^string )
{
  sb := str.builder_make()

  syntax_act := true
  in_code_block := false
  line_nr := 1
	for line in str.split_lines_iterator(txt) 
  {
    len := len(line)
    if config.line_nr { str.write_string( &sb, fmt.tprintf( "%3d %v ", line_nr, config.utf8 ? "│" : "|" ) ) }

    if in_code_block && config.ansi_color { str.write_string( &sb, util.pf_mode_str( util.PF_Mode.DIM, util.PF_Fg.WHITE, util.PF_Bg.BLACK ) ) }

    syntax_act = !in_code_block

    // for i in 0..<len
    for i := 0; i < len; i += 1
    {
      // --- headers ---
      i_offs := 0
      found_header    := false
      found_checklist := false
      for i + i_offs < len
      {
        if syntax_act && str.is_space( rune(line[i + i_offs]) )
        {
          i_offs += 1
          continue
        }
        else if syntax_act
        {
          if line[i + i_offs] == '#'
          {
            count := 1
            for line[i + i_offs + count] == '#'
            {
              count  += 1
              i_offs += 1
            }
            found_header = true
            i_offs += 1
            if config.ansi_color { str.write_string( &sb, util.pf_mode_str( util.PF_Mode.UNDERLINE, util.PF_Fg.WHITE, util.PF_Bg.RED ) ) }
            str.write_string( &sb, fmt.tprintf( "%v%v", count, config.utf8 ? "" : ">" ) )
            break
          }
          else if i + i_offs +4 < len   && // --- checklists ---
             line[i + i_offs +0] == '-' &&
             line[i + i_offs +1] == ' ' &&
             line[i + i_offs +2] == '[' &&
             line[i + i_offs +3] == ' ' &&
             line[i + i_offs +4] == ']'
          {
            for idx in 0..<i_offs { str.write_byte( &sb, line[i + idx] ) }
            str.write_string( &sb, config.utf8 ? "□ " : "o " ) 
            found_checklist = true
            i_offs += 4
          }
          else if i + i_offs +4 < len        &&
                  line[i + i_offs +0] == '-' &&
                  line[i + i_offs +1] == ' ' &&
                  line[i + i_offs +2] == '[' &&
                  line[i + i_offs +3] == 'X' &&
                  line[i + i_offs +4] == ']'
          {
            for idx in 0..<i_offs { str.write_byte( &sb, line[i + idx] ) }
            if config.ansi_color { str.write_string( &sb, util.pf_style_str( util.PF_Mode.NORMAL, util.PF_Fg.GREEN ) ) }
            str.write_string( &sb, config.utf8 ? "☑ " : "x " ) 
            if config.ansi_color { str.write_string( &sb, util.pf_style_str( util.PF_Mode.STRIKETHROUGH, util.PF_Fg.WHITE ) ) }
            found_checklist = true
            i_offs += 4 
          }
          else if i + i_offs +1 < len        &&
                  line[i + i_offs +0] == '-' &&
                  line[i + i_offs +1] == ' '
          {
            // @NOTE: this check should not be necessary, but it is somehow, idk
            if i + i_offs > 0 && !str.is_space( rune(line[i + i_offs -1]) ) { break }
            
            for idx in 0..<i_offs 
            { 
              // @NOTE: this check should not be necessary, but it is somehow, idk
              if !str.is_space( rune(line[i + idx]) ) { break }
              str.write_byte( &sb, line[i + idx] ) 
            }
            str.write_string( &sb, config.utf8 ? "○ " : "* " ) 
            found_checklist = true
            // i_offs += 1
          }
          else { break }
        }
        i_offs += 1
      }
      if found_header
      { 
        i += i_offs 
        for i < len { str.write_byte( &sb, line[i] ); i += 1 }
        if config.ansi_color { str.write_string( &sb, util.pf_style_reset_str() ) }
        // str.write_byte( &sb, '\n' )
        continue
      }
      else if found_checklist
      { 
        // str.write_byte( &sb, ' ' )
        i += i_offs 
        for i < len { str.write_byte( &sb, line[i] ); i += 1 }
        if config.ansi_color { str.write_string( &sb, util.pf_style_reset_str() ) }
        // str.write_byte( &sb, '\n' )
        continue
      }


      // --- links ---
      if syntax_act &&
         i < len +1 &&       
         line[i +0] == '[' 
      {
        name_start := i +1
        name_end   := i +1
        link_start := i +1
        link_end   := i +1
        found_link := 1   // 4 means found all four, i.e. [ ] ( )

        i_offs = 0
        for i + i_offs < len
        {
          if      line[i + i_offs]    == ']' { name_end   = i + i_offs -1; found_link += 1 }
          else if i + i_offs > 0 && line[i + i_offs -1] == '(' { link_start = i + i_offs;    found_link += 1 }
          else if line[i + i_offs]    == ')' { link_end   = i + i_offs -1; found_link += 1; break }
          i_offs += 1
        }
        assert( found_link <= 4 )
        if found_link == 4
        {
          // 🔗 󰌹 
          link_symbol := config.utf8 ? "󰌹 " : ""
          if i > 0 && line[i -1] == '!' { link_symbol = config.utf8 ? "󰥶 " : "" }
          if config.ansi_color { str.write_string( &sb, util.pf_style_str( util.PF_Mode.UNDERLINE, util.PF_Fg.BLUE ) ) }
          str.write_string( &sb, fmt.tprintf( "%v%v", link_symbol, line[name_start:name_end +1] ) )
          if config.ansi_color { str.write_string( &sb, util.pf_style_reset_str() ) }
          i += i_offs
        }

        continue
      }
      else if syntax_act
      { 
        // --- links ---
        if i < len +1 &&       
           line[i +0] == '!' && 
           line[i +1] == '[' &&
           str.contains_rune( line, ']' ) &&
           str.contains_rune( line, '(' ) &&
           str.contains_rune( line, ')' )
        {
          // just skipping the ! in ![name](link)
          continue
        }
      }
      // --- html tags ---
      if syntax_act &&
         i +1 < len &&       
         line[i +0] == '<' 
      {
        start := i +1
        // if i +1 < len && line[i +1] == '/' { ahhhhhhh and tag }
        end   := i +1
        found := false

        i_offs = 1
        for i + i_offs < len
        {
          if line[i + i_offs] == '>' { end = i + i_offs -1; found = true; break }
          i_offs += 1
        }
        if found
        {

          CODE_BLOCK_MODE :: util.PF_Mode.DIM
          CODE_BLOCK_FG   :: util.PF_Fg.BLACK

          HTML_TAG_NAME_MODE :: util.PF_Mode.DIM
          HTML_TAG_NAME_FG   :: util.PF_Fg.RED
          if config.ansi_color { str.write_string( &sb, util.pf_style_str( CODE_BLOCK_MODE, CODE_BLOCK_FG ) ) }
          // @TODO: highlight span / p / etc.
          // str.write_string( &sb, fmt.tprintf( "<%v>", line[start:end +1] ) )
          str.write_byte( &sb, '<' ) 
          
          if line[start] == '/' 
          { str.write_byte( &sb, '/' ); start += 1 }
          
          for idx := start; idx < end+1; idx += 1
          {
            if config.ansi_color &&
                    idx +3 < end +1   &&
                    line[idx +0] == 's' &&
                    line[idx +1] == 'p' &&
                    line[idx +2] == 'a' &&
                    line[idx +3] == 'n'
            { 
              str.write_string( &sb, util.pf_style_str( HTML_TAG_NAME_MODE, HTML_TAG_NAME_FG ) ) 
              str.write_string( &sb, "span" ) 
              str.write_string( &sb, util.pf_style_str( CODE_BLOCK_MODE, CODE_BLOCK_FG ) )
              idx += 3
            }
            else if config.ansi_color &&
               idx +2 < end +1        &&
               line[idx +0] == 'i'    &&
               line[idx +1] == 'm'    &&
               line[idx +2] == 'g'
            { 
              str.write_string( &sb, util.pf_style_str( HTML_TAG_NAME_MODE, HTML_TAG_NAME_FG ) ) 
              str.write_string( &sb, "img" ) 
              str.write_string( &sb, util.pf_style_str( CODE_BLOCK_MODE, CODE_BLOCK_FG ) )
              idx += 2 
            }
            else if config.ansi_color &&
               idx +2 < end +1        &&
               line[idx +0] == 'd'    &&
               line[idx +1] == 'i'    &&
               line[idx +2] == 'v'
            { 
              str.write_string( &sb, util.pf_style_str( HTML_TAG_NAME_MODE, HTML_TAG_NAME_FG ) ) 
              str.write_string( &sb, "div" ) 
              str.write_string( &sb, util.pf_style_str( CODE_BLOCK_MODE, CODE_BLOCK_FG ) )
              idx += 2
            }
            else if config.ansi_color &&
               idx +1 < end +1        &&
               line[idx +0] == 't'    &&
               line[idx +1] == 'r'
            { 
              str.write_string( &sb, util.pf_style_str( HTML_TAG_NAME_MODE, HTML_TAG_NAME_FG ) ) 
              str.write_string( &sb, "tr" ) 
              str.write_string( &sb, util.pf_style_str( CODE_BLOCK_MODE, CODE_BLOCK_FG ) )
              idx += 1
            }
            else if config.ansi_color &&
               idx +1 < end +1        &&
               line[idx +0] == 't'    &&
               line[idx +1] == 'h'
            { 
              str.write_string( &sb, util.pf_style_str( HTML_TAG_NAME_MODE, HTML_TAG_NAME_FG ) ) 
              str.write_string( &sb, "th" ) 
              str.write_string( &sb, util.pf_style_str( CODE_BLOCK_MODE, CODE_BLOCK_FG ) )
              idx += 1
            }
            else if config.ansi_color &&
               idx +1 < end +1        &&
               line[idx +0] == 't'    &&
               line[idx +1] == 'd'
            { 
              str.write_string( &sb, util.pf_style_str( HTML_TAG_NAME_MODE, HTML_TAG_NAME_FG ) ) 
              str.write_string( &sb, "td" ) 
              str.write_string( &sb, util.pf_style_str( CODE_BLOCK_MODE, CODE_BLOCK_FG ) )
              idx += 1
            }
            else if config.ansi_color &&
               idx +1 < end +1        &&
               line[idx +0] == 'b'    &&
               line[idx +1] == 'r'
            { 
              str.write_string( &sb, util.pf_style_str( HTML_TAG_NAME_MODE, HTML_TAG_NAME_FG ) ) 
              str.write_string( &sb, "br" ) 
              str.write_string( &sb, util.pf_style_str( CODE_BLOCK_MODE, CODE_BLOCK_FG ) )
              idx += 1
            }
            else if config.ansi_color &&
               idx +0 < end +1        &&
               line[idx +0] == 'p'      
            { 
              str.write_string( &sb, util.pf_style_str( HTML_TAG_NAME_MODE, HTML_TAG_NAME_FG ) ) 
              str.write_string( &sb, "p" ) 
              str.write_string( &sb, util.pf_style_str( CODE_BLOCK_MODE, CODE_BLOCK_FG ) )
              idx += 0
            }
            else 
            { str.write_byte( &sb, line[idx] ) }

          }
          str.write_byte( &sb, '>' ) 
          if config.ansi_color { str.write_string( &sb, util.pf_style_reset_str() ) }
          i += i_offs
          
          continue
        }
      }

      // --- code block ---
      if i +2 < len &&       
         line[i +0] == '`' &&
         line[i +1] == '`' &&
         line[i +2] == '`' 
      {
        in_code_block = !in_code_block
        if !in_code_block && config.ansi_color 
        { 
          str.write_string( &sb, util.pf_style_reset_str() ) 
          // util.pf_reset_default()
        }
        else if i +3 < len
        {
          // "", ""
          // str.write_string( &sb, str.concatenate( []string{ config.utf8 ? "" : "/", line[i +3:len], config.utf8 ? "" : "\\" }, context.temp_allocator ) )
          str.write_string( &sb, util.pf_style_str( util.PF_Mode.DIM, util.PF_Fg.BLACK ) )
          str.write_string( &sb, config.utf8 ? ""/* "" */ : "/" )
          str.write_string( &sb, util.pf_mode_str( util.PF_Mode.DIM, util.PF_Fg.WHITE, util.PF_Bg.BLACK ) )
          str.write_string( &sb, line[i +3:len] )
          str.write_string( &sb, util.pf_style_reset_str() )
          str.write_string( &sb, util.pf_style_str( util.PF_Mode.DIM, util.PF_Fg.BLACK ) )
          str.write_string( &sb, config.utf8 ? ""/* "" */ : "\\" )
          str.write_string( &sb, util.pf_style_reset_str() )
        }
        // { util.pf_set_default( util.PF_Mode.DIM, util.PF_Fg.WHITE, util.PF_Bg.BLACK ) }
        // i += 2
        i = len
        continue
        // start := i +1
        // end   := i +1
        // found := false
        //
        // i_offs = 1
        // for i + i_offs +2 < len
        // {
        //   if line[i + i_offs +0] == '`' &&
        //      line[i + i_offs +1] == '`' &&
        //      line[i + i_offs +2] == '`' 
        //   { 
        //     end = i + i_offs -1
        //     found = true
        //     break 
        //   }
        //   i_offs += 1
        // }
        // if found
        // {
        //   if config.ansi_color { str.write_string( &sb, util.pf_mode_str( util.PF_Mode.DIM, util.PF_Fg.WHITE, util.PF_Bg.BLACK ) ) }
        //   str.write_string( &sb, fmt.tprintf( "%v", line[start:end +1] ) )
        //   if config.ansi_color { str.write_string( &sb, util.pf_style_reset_str() ) }
        //   i += i_offs
        //   continue
        // }
      } 
      else if syntax_act &&
              i +1 < len && // --- inline code block ---
              line[i +0] == '`' 
      {
        start := i +1
        end   := i +1
        found := false

        i_offs = 1
        for i + i_offs < len
        {
          if line[i + i_offs] == '`' { end = i + i_offs -1; found = true; break }
          i_offs += 1
        }
        if found
        {
          if config.ansi_color { str.write_string( &sb, util.pf_mode_str( util.PF_Mode.DIM, util.PF_Fg.WHITE, util.PF_Bg.BLACK ) ) }
          str.write_string( &sb, fmt.tprintf( "%v", line[start:end +1] ) )
          if config.ansi_color { str.write_string( &sb, util.pf_style_reset_str() ) }
          i += i_offs
          continue
        }
      }
      
      str.write_byte( &sb, line[i] ) 
    }

    if in_code_block && config.ansi_color 
    {
      for _ in len..=config.code_block_min_width
      {
        str.write_byte( &sb, ' ' )
      }
    }
    str.write_string( &sb, util.pf_style_reset_str() )
    // str.write_string( &sb, util.pf_default_str() )
    str.write_byte( &sb, '\n' )

    fmt.print( str.to_string( sb ) )
    str.builder_reset( &sb )
    // util.pf_style_reset()

    line_nr += 1
	}
}

config_read :: proc( path: string, config: ^config_t )
{
  // set default values for presets
  config.available = false
  config.utf8      = true
  config.syntax_md = true
  config.code_block_min_width = 50

  // read config file
  
  src_bytes, err := os.read_entire_file_from_path( path, context.allocator )
  if err != os.ERROR_NONE || len( src_bytes ) <= 0
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
  // strings
  // ...
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
  else if name == "code-block-width"
  {
    val, ok := v.(int)
    if !ok 
    { fmt.eprintfln( "[ERROR] code-block-width value given not int: \"%s\"", value ); return }
    conf.code_block_min_width = val  
    fmt.println( "conf.code-block-width:", conf.code_block_min_width )
  }
  else if len(name) > 6  &&
          name[0] == 's' &&
          name[1] == 'y' &&
          name[2] == 'n' &&
          name[3] == 't' &&
          name[4] == 'a' &&
          name[5] == 'x' &&
          name[6] == ':' 
  {
    if len(name) > 8  &&
       name[7] == 'm' &&
       name[8] == 'd'
    {
      val, ok := v.(bool)
      if !ok 
      { fmt.eprintfln( "[ERROR] syntax:md value given not boolean: \"%s\"", value ); return }
      conf.syntax_md = val  
    }
    else if len(name) > 11  &&
       name[ 7] == 's' &&
       name[ 8] == 'h' &&
       name[ 9] == 'e' &&
       name[10] == 'e' &&
       name[11] == 't'
    {
      val, ok := v.(bool)
      if !ok 
      { fmt.eprintfln( "[ERROR] syntax:sheet value given not boolean: \"%s\"", value ); return }
      conf.syntax_sheet = val  
    }
    else { fmt.printfln( "[ERROR] config argument with unknown name: [%v]", name ) }
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
