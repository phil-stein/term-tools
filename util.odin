package util

import "core:fmt"

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
