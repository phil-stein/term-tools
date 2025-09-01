package img

import     "core:os"
import     "core:fmt"
import win "core:sys/windows"

main :: proc()
{
  when ODIN_OS == .Windows
  {
    // @NOTE: enable utf output to console, windows specific
    win.SetConsoleOutputCP( win.CODEPAGE(win.CP_UTF8) )
  }

  if len( os.args ) <= 1
  {
    print_help()
  }
  else
  {
    fmt.printfln( " %v", os.args[1] )
  }

}
print_help :: proc()
{
  fmt.println( "usage:" )
  fmt.println( "  > img file.png" )
}
