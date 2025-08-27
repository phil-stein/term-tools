package util

import "core:fmt"

PF_Mode :: enum
{
  NORMAL     = 0,
  BOLD       = 1,    // bright
  DIM        = 2,
  ITALIC     = 3,
  UNDERLINE  = 4,
  REVERSE    = 5,
  HIDDEN     = 6,
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
