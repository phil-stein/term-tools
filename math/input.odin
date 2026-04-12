package term_tools_math

import     "core:fmt"
import str "core:strings"
import     "vendor:glfw"
// import "core:prof/spall"

Key :: enum
{
  UNKNOWN = glfw.KEY_UNKNOWN, 

  SPACE         = glfw.KEY_SPACE,        
  APOSTROPHE    = glfw.KEY_APOSTROPHE,    /* ' */
  COMMA         = glfw.KEY_COMMA,         /* , */
  MINUS         = glfw.KEY_MINUS,         /* - */
  PERIOD        = glfw.KEY_PERIOD,        /* . */
  SLASH         = glfw.KEY_SLASH,         /* / */
  SEMICOLON     = glfw.KEY_SEMICOLON,     /* ; */
  EQUAL         = glfw.KEY_EQUAL,         /* :: */
  LEFT_BRACKET  = glfw.KEY_LEFT_BRACKET,  /* [ */
  BACKSLASH     = glfw.KEY_BACKSLASH,     /* \ */
  RIGHT_BRACKET = glfw.KEY_RIGHT_BRACKET, /* ] */
  GRAVE_ACCENT  = glfw.KEY_GRAVE_ACCENT,  /* ` */
  WORLD_1       = glfw.KEY_WORLD_1,       /* non-US #1 */
  WORLD_2       = glfw.KEY_WORLD_2,       /* non-US #2 */

  NUM_0 = glfw.KEY_0,
  NUM_1 = glfw.KEY_1,
  NUM_2 = glfw.KEY_2,
  NUM_3 = glfw.KEY_3,
  NUM_4 = glfw.KEY_4,
  NUM_5 = glfw.KEY_5,
  NUM_6 = glfw.KEY_6,
  NUM_7 = glfw.KEY_7,
  NUM_8 = glfw.KEY_8,
  NUM_9 = glfw.KEY_9,
    
  A = glfw.KEY_A,
  B = glfw.KEY_B,
  C = glfw.KEY_C,
  D = glfw.KEY_D,
  E = glfw.KEY_E,
  F = glfw.KEY_F,
  G = glfw.KEY_G,
  H = glfw.KEY_H,
  I = glfw.KEY_I,
  J = glfw.KEY_J,
  K = glfw.KEY_K,
  L = glfw.KEY_L,
  M = glfw.KEY_M,
  N = glfw.KEY_N,
  O = glfw.KEY_O,
  P = glfw.KEY_P,
  Q = glfw.KEY_Q,
  R = glfw.KEY_R,
  S = glfw.KEY_S,
  T = glfw.KEY_T,
  U = glfw.KEY_U,
  V = glfw.KEY_V,
  W = glfw.KEY_W,
  X = glfw.KEY_X,
  Y = glfw.KEY_Y,
  Z = glfw.KEY_Z,

  ESCAPE       = glfw.KEY_ESCAPE,      
  ENTER        = glfw.KEY_ENTER,       
  TAB          = glfw.KEY_TAB,         
  BACKSPACE    = glfw.KEY_BACKSPACE,   
  INSERT       = glfw.KEY_INSERT,      
  DELETE       = glfw.KEY_DELETE,      
  RIGHT        = glfw.KEY_RIGHT,       
  LEFT         = glfw.KEY_LEFT,        
  DOWN         = glfw.KEY_DOWN,        
  UP           = glfw.KEY_UP,          
  PAGE_UP      = glfw.KEY_PAGE_UP,     
  PAGE_DOWN    = glfw.KEY_PAGE_DOWN,   
  HOME         = glfw.KEY_HOME,        
  END          = glfw.KEY_END,         
  CAPS_LOCK    = glfw.KEY_CAPS_LOCK,   
  SCROLL_LOCK  = glfw.KEY_SCROLL_LOCK, 
  NUM_LOCK     = glfw.KEY_NUM_LOCK,    
  PRINT_SCREEN = glfw.KEY_PRINT_SCREEN,
  PAUSE        = glfw.KEY_PAUSE,       

  F1  = glfw.KEY_F1, 
  F2  = glfw.KEY_F2, 
  F3  = glfw.KEY_F3, 
  F4  = glfw.KEY_F4, 
  F5  = glfw.KEY_F5, 
  F6  = glfw.KEY_F6, 
  F7  = glfw.KEY_F7, 
  F8  = glfw.KEY_F8, 
  F9  = glfw.KEY_F9, 
  F10 = glfw.KEY_F10,
  F11 = glfw.KEY_F11,
  F12 = glfw.KEY_F12,
  F13 = glfw.KEY_F13,
  F14 = glfw.KEY_F14,
  F15 = glfw.KEY_F15,
  F16 = glfw.KEY_F16,
  F17 = glfw.KEY_F17,
  F18 = glfw.KEY_F18,
  F19 = glfw.KEY_F19,
  F20 = glfw.KEY_F20,
  F21 = glfw.KEY_F21,
  F22 = glfw.KEY_F22,
  F23 = glfw.KEY_F23,
  F24 = glfw.KEY_F24,
  F25 = glfw.KEY_F25,
  
  KEYPAD_0 = glfw.KEY_KP_0,
  KEYPAD_1 = glfw.KEY_KP_1,
  KEYPAD_2 = glfw.KEY_KP_2,
  KEYPAD_3 = glfw.KEY_KP_3,
  KEYPAD_4 = glfw.KEY_KP_4,
  KEYPAD_5 = glfw.KEY_KP_5,
  KEYPAD_6 = glfw.KEY_KP_6,
  KEYPAD_7 = glfw.KEY_KP_7,
  KEYPAD_8 = glfw.KEY_KP_8,
  KEYPAD_9 = glfw.KEY_KP_9,

  KEYPAD_DECIMAL  = glfw.KEY_KP_DECIMAL, 
  KEYPAD_DIVIDE   = glfw.KEY_KP_DIVIDE,  
  KEYPAD_MULTIPLY = glfw.KEY_KP_MULTIPLY,
  KEYPAD_SUBTRACT = glfw.KEY_KP_SUBTRACT,
  KEYPAD_ADD      = glfw.KEY_KP_ADD,     
  KEYPAD_ENTER    = glfw.KEY_KP_ENTER,   
  KEYPAD_EQUAL    = glfw.KEY_KP_EQUAL,   
  
  LEFT_SHIFT    = glfw.KEY_LEFT_SHIFT,   
  LEFT_CONTROL  = glfw.KEY_LEFT_CONTROL, 
  LEFT_ALT      = glfw.KEY_LEFT_ALT,     
  LEFT_SUPER    = glfw.KEY_LEFT_SUPER,   
  RIGHT_SHIFT   = glfw.KEY_RIGHT_SHIFT,  
  RIGHT_CONTROL = glfw.KEY_RIGHT_CONTROL,
  RIGHT_ALT     = glfw.KEY_RIGHT_ALT,    
  RIGHT_SUPER   = glfw.KEY_RIGHT_SUPER,  
  MENU          = glfw.KEY_MENU,         

  LAST = glfw.KEY_LAST 
}

Keymod :: enum
{
  MOD_NONE     = 0,

  MOD_SHIFT    = glfw.MOD_SHIFT,    
  MOD_CONTROL  = glfw.MOD_CONTROL,  
  MOD_ALT      = glfw.MOD_ALT,      
  MOD_SUPER    = glfw.MOD_SUPER,    
  MOD_CAPS_LOCK= glfw.MOD_CAPS_LOCK,
  MOD_NUM_LOCK = glfw.MOD_NUM_LOCK, 
}


// KEYSTATE :: enum
// {
//   RELEASE = glfw.RELEASE,
//   DOWN    = glfw.PRESS,
//   PRESSED = 2
// }
key_state_t :: struct
{
  down_last : bool, // down last frame
  down      : bool,
  pressed   : bool,
  mods      : Keymod, 
}


Mouse_Button :: enum
{
  LEFT   = glfw.MOUSE_BUTTON_1,
  RIGHT  = glfw.MOUSE_BUTTON_2,
  MIDDLE = glfw.MOUSE_BUTTON_3,
  BUTTON_4 = glfw.MOUSE_BUTTON_4,
  BUTTON_5 = glfw.MOUSE_BUTTON_5,
  BUTTON_6 = glfw.MOUSE_BUTTON_6,
  BUTTON_7 = glfw.MOUSE_BUTTON_7,
  BUTTON_8 = glfw.MOUSE_BUTTON_8,
}
mouse_button_state_t :: struct
{
  down_last : bool, // down last frame
  down      : bool,
  pressed   : bool,
}

input_t :: struct
{
  // @TODO: no idea what #sparse does,
  //        cant find docs on odin-lang.org 
  key_states : #sparse [Key]key_state_t,

  // @TODO: no idea what #sparse does,
  //        cant find docs on odin-lang.org 
  mouse_button_states : #sparse [Mouse_Button]mouse_button_state_t,

  mouse_x           : f32,
  mouse_y           : f32,  
  mouse_delta_x     : f32,
  mouse_delta_y     : f32, 
  mouse_over_ui     : bool,

  mouse_sensitivity : f32,
}
// global struct holding all input info
input : input_t = 
{
  mouse_x           = 0.0,
  mouse_y           = 0.0, 
  mouse_delta_x     = 0.0,
  mouse_delta_y     = 0.0, 

  mouse_sensitivity = 0.5,
}

input_init :: proc()
{
  // spall.SCOPED_EVENT( &spall_ctx, &spall_buffer, #procedure )

  glfw.SetKeyCallback( data.window, glfw.KeyProc(input_key_callback) )
  glfw.SetCharCallback( data.window, glfw.CharProc(input_char_callback) )
  
  glfw.SetMouseButtonCallback( data.window, glfw.MouseButtonProc(input_mouse_button_callback) )
  glfw.SetCursorPosCallback( data.window, glfw.CursorPosProc(input_mouse_pos_callback) )
}

input_update :: proc()
{
  // spall.SCOPED_EVENT( &spall_ctx, &spall_buffer, #procedure )

  for &key in input.key_states 
  {
    key.down_last = key.down
    key.pressed   = false
    key.mods      = .MOD_NONE
  }

  for &btn in input.mouse_button_states 
  {
    btn.down_last = btn.down
    btn.pressed   = false
  }

  input.mouse_delta_x = 0.0
  input.mouse_delta_y = 0.0
}

input_key_callback :: proc( window: glfw.WindowHandle, keycode: int, scancode: int, state: int, mods: int)
{
  assert( keycode >= 0 )
  assert( keycode <  len(input.key_states) )
  input.key_states[Key(keycode)].pressed = input.key_states[Key(keycode)].down_last ? false : true 
  input.key_states[Key(keycode)].down    = state == glfw.PRESS || state == glfw.REPEAT 
  input.key_states[Key(keycode)].mods    = Keymod(mods)
  // if ( keycode == glfw.KEY_W ) { fmt.println( "state: ", state ) }
}

input_char_callback :: proc( window: glfw.WindowHandle, char: rune )
{
  // fmt.println( char )
}

input_mouse_button_callback :: proc( window: glfw.WindowHandle, button, action, mods: int )
{
  input.mouse_button_states[Mouse_Button(button)].pressed = input.mouse_button_states[Mouse_Button(button)].down_last ? false : true 
  input.mouse_button_states[Mouse_Button(button)].down    = action == glfw.PRESS || action == glfw.REPEAT 
}

input_mouse_pos_callback :: proc( window: glfw.WindowHandle, xpos, ypos: f64 )
{
  input.mouse_delta_x = f32(xpos) - input.mouse_x
  input.mouse_delta_y = input.mouse_y - f32(ypos) // for some reason y is invers, prob because opengl is weird about coordinates
  input.mouse_x = f32(xpos)
  input.mouse_y = f32(ypos)
}

input_center_cursor :: proc()
{
  glfw.SetCursorPos( data.window, f64(data.window_width / 2), f64(data.window_height / 2) )
  input.mouse_x = f32(data.window_width / 2)
  input.mouse_y = f32(data.window_height / 2)
  input.mouse_delta_x = 0 
  input.mouse_delta_y = 0
}

input_set_cursor_visibile :: proc(visible: bool)
{
  glfw.SetInputMode( data.window, glfw.CURSOR, visible ? glfw.CURSOR_NORMAL : glfw.CURSOR_DISABLED )
}
