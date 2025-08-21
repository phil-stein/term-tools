package gitsync

import     "core:fmt"
import     "core:os"
import     "core:c/libc"
import win "core:sys/windows"

// @TODO: do this in a config file 
paths := [?]string{  
  "%appdata%\\..\\local\\nvim",
  "C:\\workspace\\markdown",
  "C:\\workspace\\c\\fisch",
  "c:\\workspace\\c\\esp8266_udp_server",
  "C:\\workspace\\c\\game_gen",
  "C:\\workspace\\c\\term_docs",
  "C:\\workspace\\c\\text_editor",
  "C:\\workspace\\odin\\01_tests",
  "C:\\workspace\\odin\\oloc",
  "C:\\workspace\\odin\\term-tools",
  "C:\\workspace\\odin\\03_game\\xcom",
}

main :: proc()
{ 
  var_str : cstring16 = "%AppData%"
  buf : [128]u16
  ret := win.ExpandEnvironmentStringsW( var_str, raw_data(&buf), 128 )
  if ret <= 0 { fmt.println( "[ERROR] win.ExpandEnvironmentStringsW failed with:", var_str ) }

  fmt.println( 
` M -> modified
?? -> untracked
idk` )
  for path in paths
  {
    err := os.set_current_directory( path )
    if err != os.ERROR_NONE { fmt.println( "[ERROR]", err, ", for path:", path ); continue } 
    fmt.println( "", path )
    // @TODO: how to get the output of this operation as string, for proper formatting
    libc.system( "git status --porcelain" ) // --porcelain
    // fmt.print( "\n" )
  }
}
