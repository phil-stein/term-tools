package cat

import "core:fmt"
import "core:os"

main :: proc()
{
  if len( os.args ) <= 1
  {
    print_help()
  }
  else
  {
    fmt.println( os.args[1] )

    txt, ok := os.read_entire_file_from_filename( os.args[1] )

    if !ok { fmt.println( "[ERROR] could not find file:", os.args[1] ) }
    else
    {
      defer delete( txt )
      fmt.print( string(txt) )
    }

  }

}
print_help :: proc()
{
  fmt.println( "usage:" )
  fmt.println( "  > cat file.ext" )
}
