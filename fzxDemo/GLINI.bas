'**************************************************
' OPEN GL related initialization
'**************************************************
'$include:'..\fzxNGN_BASE_v2\fzxNGN_ini.bas'


TYPE tGL_TEXTURE
  glText AS _INTEGER64
  img AS LONG
  hash AS _INTEGER64
  id AS STRING * 64
END TYPE


CONST cFSM_GLMODE_IDLE = 0
CONST cFSM_GLMODE_INIT = 1
CONST cFSM_GLMODE_RUN = 2

DIM SHARED AS tFZX_FSM glMode
DIM SHARED AS tGL_TEXTURE textures(0)

_GLRENDER _BEHIND
