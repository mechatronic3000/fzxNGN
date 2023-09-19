$IF CONSTANTS = UNDEFINED THEN
  $LET CONSTANTS = TRUE

  CONST FALSE = 0
  CONST TRUE = -1

  CONST cRENDER_JOINTS = 0
  CONST cRENDER_COLLISIONS = 0
  CONST cRENDER_AABB = 0
  CONST cRENDER_WIREFRAME = 0

  CONST cNET_NONE = 0
  CONST cNET_SERVER = 1
  CONST cNET_CLIENT = 2

  CONST cKEY_ESC = 27
  CONST cKEY_TAB = 9
  CONST cKEY_ARROW_UP = 18432
  CONST cKEY_ARROW_DOWN = 20480
  CONST cKEY_ARROW_LEFT = 19200
  CONST cKEY_ARROW_RIGHT = 19712
  CONST cKEY_SPACE = 32

  CONST cFSM_GAMEMODE_IDLE = 0
  CONST cFSM_GAMEMODE_SPLASH = 1
  CONST cFSM_GAMEMODE_START = 2
  CONST cFSM_GAMEMODE_GAMEPLAY = 3
  CONST cFSM_GAMEMODE_CREDITS_SETUP = 4
  CONST cFSM_GAMEMODE_CREDITS = 5
  CONST cFSM_GAMEMODE_INTRO_SETUP = 6
  CONST cFSM_GAMEMODE_INTRO = 7
  CONST cFSM_GAMEMODE_INSTRUCTION_SETUP = 8
  CONST cFSM_GAMEMODE_INSTRUCTION = 9
  CONST cFSM_GAMEMODE_INVENTORY_SETUP = 10
  CONST cFSM_GAMEMODE_INVENTORY = 11
  CONST cFSM_GAMEMODE_LOOTMENU_SETUP = 12
  CONST cFSM_GAMEMODE_LOOTMENU = 13
  CONST cFSM_GAMEMODE_COMBAT_SETUP = 14
  CONST cFSM_GAMEMODE_COMBAT_PLAYER_TURN = 15
  CONST cFSM_GAMEMODE_COMBAT_ENEMY_TURN = 16
  CONST cFSM_GAMEMODE_GAMEPLAY_SETUP = 17

  CONST cFSM_CAMERA_IDLE = 0
  CONST cFSM_CAMERA_START = 1
  CONST cFSM_CAMERA_MOVING = 2

  CONST cFSM_ENTITY_IDLE = 0
  CONST cFSM_ENTITY_MOVE_SETUP = 1
  CONST cFSM_ENTITY_MOVE = 2
  CONST cFSM_ENTITY_WAIT = 3

  CONST cFSM_MESSAGE_IDLE = 0
  CONST cFSM_MESSAGE_INIT = 1
  CONST cFSM_MESSAGE_FADEIN = 2
  CONST cFSM_MESSAGE_SHINE = 3
  CONST cFSM_MESSAGE_FADEOUT = 4
  CONST cFSM_MESSAGE_CLEANUP = 5

  CONST cFSM_SOUND_IDLE = 0
  CONST cFSM_SOUND_START = 1
  CONST cFSM_SOUND_LEADIN = 2
  CONST cFSM_SOUND_PLAY = 3
  CONST cFSM_SOUND_LEADOUT = 4
  CONST cFSM_SOUND_CLEANUP = 5


  CONST cENTITY_BEHAVIOR_NONE = 0
  CONST cENTITY_BEHAVIOR_WANDER = 1
  CONST cENTITY_BEHAVIOR_CONTAINER = 2

  CONST cFSM_GL_IDLE = 0
  CONST cFSM_GL_INIT = 1
  CONST cFSM_GL_DRAW = 2

  CONST cLIGHTING_MAX_DISTANCE = 12

  CONST cSCREENLAYERS = 7

  CONST cSCR_DISPLAY = 0
  CONST cSCR_LEVEL_SENSOR = 1
  CONST cSCR_GUI = 2
  CONST cSCR_GUI_SENSOR = 3
  CONST cSCR_LOG = 4
  CONST cSCR_LEVEL1 = 5
  CONST cSCR_LEVEL2 = 6
  CONST cSCR_LEVEL3 = 7

  CONST cGUI_LAYOUT_INVENTORY = 0
  CONST cGUI_LAYOUT_LOOT = 1
  CONST cGUI_LAYOUT_HUD = 2
  CONST cGUI_LAYOUT_HUD_LARGE_CONSOLE = 3


$END IF
