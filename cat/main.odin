package cat

import      "core:fmt"
import      "core:os"
import str  "core:strings"
import util ".."

main :: proc()
{
  if len( os.args ) <= 1
  {
    print_help()
  }
  else
  {
    fmt.printfln( " %v", os.args[1] )

    txt, ok := os.read_entire_file_from_filename( os.args[1] )

    if !ok { fmt.println( "[ERROR] could not find file:", os.args[1] ) }
    else
    {
      defer delete( txt )
      len := len(os.args[1])
      if len > 3 &&
         os.args[1][len -1] == 'd' &&
         os.args[1][len -2] == 'm' &&
         os.args[1][len -3] == '.'
      {
        fmt.println( "is .md" )
        txt_str := string(txt)
        cat_md( &txt_str )
      }
      else
      {
        fmt.print( string(txt) )
      }
    }

  }

}
print_help :: proc()
{
  fmt.println( "usage:" )
  fmt.println( "  > cat file.ext" )
}

cat_md :: proc( txt: ^string )
{
  sb := str.builder_make()

  line_nr := 1
	for line in str.split_lines_iterator(txt) 
  {
    len := len(line)
    str.write_string( &sb, fmt.tprintf( "%3d | ", line_nr ) )

    // for i in 0..<len
    for i := 0; i < len; i += 1
    {
      // --- headers ---
      i_offs := 0
      found_header := false
      for i + i_offs < len
      {
        if str.is_space( rune(line[i + i_offs]) )
        {
          i_offs += 1
          continue
        }
        else if line[i + i_offs] == '#'
        {
          count := 1
          for line[i + i_offs + count] == '#'
          {
            count  += 1
            i_offs += 1
          }
          found_header = true
          i_offs += 1
          str.write_string( &sb, util.pf_mode_str( util.PF_Mode.UNDERLINE, util.PF_Fg.WHITE, util.PF_Bg.RED ) )
          str.write_string( &sb, fmt.tprintf( "%v", count ) )
          break
        }
        else { break }
        i_offs += 1
      }
      if found_header 
      { 
        i += i_offs 
        for i < len { str.write_byte( &sb, line[i] ); i += 1 }
        str.write_string( &sb, util.pf_style_reset_str() )
        str.write_byte( &sb, '\n' )
        continue
      }

      // --- checklists ---
      if i < len +4 &&
         line[i +0] == '-' &&
         line[i +1] == ' ' &&
         line[i +2] == '[' &&
         line[i +3] == ' ' &&
         line[i +4] == ']'
      {
        str.write_string( &sb, "□" ) 
        i += 4
      }
      else if i < len +4 &&
              line[i +0] == '-' &&
              line[i +1] == ' ' &&
              line[i +2] == '[' &&
              line[i +3] == 'X' &&
              line[i +4] == ']'
      {
        str.write_string( &sb, "☑" ) 
        i += 4 
        str.write_string( &sb, util.pf_style_str( util.PF_Mode.STRIKETHROUGH, util.PF_Fg.WHITE ) )
      }
      else if i < len +1 &&
              line[i +0] == '-' &&
              line[i +1] == ' '
      {
        str.write_string( &sb, "○" ) 
        // i += 1
      }
      else if i < len +1 &&       // --- links ---
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
          link_symbol := "󰌹"
          if i > 0 && line[i -1] == '!' { link_symbol = "󰥶" }
          str.write_string( &sb, util.pf_style_str( util.PF_Mode.UNDERLINE, util.PF_Fg.BLUE ) )
          str.write_string( &sb, fmt.tprintf( "%v %v", link_symbol, line[name_start:name_end +1] ) )
          i += i_offs
        }

        // i += 1
      }
      else
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
        }
        else { str.write_byte( &sb, line[i] ) }
      }
    }
    str.write_byte( &sb, '\n' )

    str.write_string( &sb, util.pf_style_reset_str() )
    fmt.print( str.to_string( sb ) )
    str.builder_reset( &sb )
    // util.pf_style_reset()

    line_nr += 1
	}
}
