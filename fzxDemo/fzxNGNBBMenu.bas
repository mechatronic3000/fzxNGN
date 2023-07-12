'**********************************************************************************************
'   fzxBareBones with Menu
'**********************************************************************************************

'$DYNAMIC
OPTION _EXPLICIT
_TITLE "fzxNGN Bare Bones with Menu"

' Initialize FZXNGN types, globals and constants
'$include:'..\fzxNGN_BASE_v2\fzxNGN_ini.bas'

CONST cFSM_GAMEMODE_IDLE = 0
CONST cFSM_GAMEMODE_SPLASH_DRAW = 1
CONST cFSM_GAMEMODE_SPLASH_DONE = 2
CONST cFSM_GAMEMODE_MAIN_MENU_LOOP = 4
CONST cFSM_GAMEMODE_MAIN_OPTIONS_LOOP = 6
CONST cFSM_GAMEMODE_GAMEPLAY_INITIALIZE = 7
CONST cFSM_GAMEMODE_GAMEPLAY_LOOP = 8
CONST cFSM_GAMEMODE_DELTA_LOOP = 9
CONST cFSM_GAMEMODE_ITERATIONS_LOOP = 10


DIM SHARED AS tFZX_FSM mainMenu
fzxFSMChangeState mainMenu, cFSM_GAMEMODE_IDLE


SCREEN _NEWIMAGE(1024, 768, 32)

DIM SHARED AS LONG iterations: iterations = 100
DIM SHARED AS LONG dtDivisor: dtDivisor = 240
DIM SHARED AS DOUBLE dt: dt = 1 / dtDivisor


'**********************************************************************************************
' This is the main loop
'**********************************************************************************************

DO
  fzxHandleInputDevice
  SELECT CASE mainMenu.currentState
    CASE cFSM_GAMEMODE_IDLE
      fzxFSMChangeState mainMenu, cFSM_GAMEMODE_SPLASH_DRAW
    CASE cFSM_GAMEMODE_SPLASH_DRAW
      CLS
      LOCATE 20, 50: PRINT "BARE BONES with Menu"
      mainMenu.timerState.duration = 3
      buildSplash
      fzxFSMChangeState mainMenu, cFSM_GAMEMODE_SPLASH_DONE
    CASE cFSM_GAMEMODE_SPLASH_DONE
      fzxFSMChangeStateOnTimer mainMenu, cFSM_GAMEMODE_MAIN_MENU_LOOP
    CASE cFSM_GAMEMODE_MAIN_MENU_LOOP
      CLS
      LOCATE 20, 100: PRINT "   BARE BONES"
      LOCATE 22, 100: PRINT "1. Start"
      LOCATE 23, 100: PRINT "2. Options"
      LOCATE 24, 100: PRINT "3. Quit"
      LOCATE 26, 100: PRINT "Selection: ";

      SELECT CASE __fzxInputDevice.keyboard.keyHit
        CASE 49
          fzxFSMChangeState mainMenu, cFSM_GAMEMODE_GAMEPLAY_INITIALIZE
        CASE 50
          fzxFSMChangeState mainMenu, cFSM_GAMEMODE_MAIN_OPTIONS_LOOP
        CASE 51, 27
          SYSTEM
      END SELECT
      animateSplash
    CASE cFSM_GAMEMODE_MAIN_OPTIONS_LOOP
      CLS
      LOCATE 20, 100: PRINT "   Options"
      LOCATE 22, 100: PRINT "1. Delta Time"
      LOCATE 23, 100: PRINT "2. Interations"
      LOCATE 24, 100: PRINT "3. Back"
      LOCATE 26, 100: PRINT "Selection: ";

      SELECT CASE __fzxInputDevice.keyboard.keyHit
        CASE 49
          fzxFSMChangeState mainMenu, cFSM_GAMEMODE_DELTA_LOOP
        CASE 50
          fzxFSMChangeState mainMenu, cFSM_GAMEMODE_ITERATIONS_LOOP
        CASE 51, 27
          fzxFSMChangeState mainMenu, cFSM_GAMEMODE_MAIN_MENU_LOOP
      END SELECT
      animateSplash
    CASE cFSM_GAMEMODE_DELTA_LOOP
      CLS
      LOCATE 20, 50: PRINT "         Delta Time"
      LOCATE 22, 50: PRINT "Use arrow ("; CHR$(24); CHR$(25); ") keys to adjust the time"
      LOCATE 23, 50: PRINT "(ESC) key to go back to options menu"
      LOCATE 24, 50: PRINT USING "       ###"; dtDivisor

      SELECT CASE __fzxInputDevice.keyboard.keyHit
        CASE 18432 ' Up
          dtDivisor = dtDivisor + 1
        CASE 20480 ' Down
          dtDivisor = dtDivisor - 1
        CASE 27
          fzxFSMChangeState mainMenu, cFSM_GAMEMODE_MAIN_OPTIONS_LOOP
      END SELECT
      dtDivisor = fzxImpulseClamp(10, 240, dtDivisor)
      dt = 1 / dtDivisor
      animateSplash
    CASE cFSM_GAMEMODE_ITERATIONS_LOOP
      CLS
      LOCATE 20, 50: PRINT "         Iterations"
      LOCATE 22, 50: PRINT "Use arrow ("; CHR$(24); CHR$(25); ") keys to adjust"
      LOCATE 23, 50: PRINT "(ESC) key to go back to options menu"
      LOCATE 24, 50: PRINT USING "       #####"; iterations

      SELECT CASE __fzxInputDevice.keyboard.keyHit
        CASE 18432 ' Up
          iterations = iterations + 1
        CASE 20480 ' Down
          iterations = iterations - 1
        CASE 27
          fzxFSMChangeState mainMenu, cFSM_GAMEMODE_MAIN_OPTIONS_LOOP
      END SELECT
      iterations = fzxImpulseClamp(1, 10000, iterations)
      animateSplash
    CASE cFSM_GAMEMODE_GAMEPLAY_INITIALIZE
      '********************************
      ' Build the playfield
      '********************************
      clearScene
      buildScene
      fzxFSMChangeState mainMenu, cFSM_GAMEMODE_GAMEPLAY_LOOP
    CASE cFSM_GAMEMODE_GAMEPLAY_LOOP
      animatescene
      fzxImpulseStep dt, iterations
      CLS: LOCATE 1: PRINT "Click the mouse on the playfield to spawn an object"
      renderBodies
      IF __fzxInputDevice.keyboard.keyHit = 27 THEN
        fzxFSMChangeState mainMenu, cFSM_GAMEMODE_MAIN_MENU_LOOP
      END IF
  END SELECT
  _DISPLAY

LOOP

SYSTEM

' This provides access to all of the fzxNGN functionality
'$include:'..\fzxNGN_BASE_v2\fzxNGN_BASE.bas'

'**********************************************************************************************
'    This is where you interact with the world.
'**********************************************************************************************

SUB animatescene
  DIM AS LONG temp

  ' Create a object on mouse click
  IF __fzxInputDevice.mouse.b1.NegEdge THEN
    ' Drop a ball or a box, flip a coin
    IF RND > .5 THEN
      temp = fzxCreateCircleBodyEx("b" + _TRIM$(STR$(RND * 1000000000)), 10)
    ELSE
      temp = fzxCreatePolyBodyEx("b" + _TRIM$(STR$(RND * 1000000000)), 10, 10, 3 + INT(RND * 5))
    END IF
    ' Set the bodies parameters
    ' Put the body where the mouse is on the screen
    fzxSetBody cFZX_PARAMETER_POSITION, temp, __fzxInputDevice.mouse.worldPosition.x, __fzxInputDevice.mouse.worldPosition.y
    ' Give it the mouse's velocity, so you can throw it
    fzxSetBody cFZX_PARAMETER_VELOCITY, temp, __fzxInputDevice.mouse.velocity.x * 10, __fzxInputDevice.mouse.velocity.y * 10
    ' Change its orientation or angle
    fzxSetBody cFZX_PARAMETER_ORIENT, temp, _D2R(RND * 360), 0
    ' Set the bouncyness
    fzxSetBody cFZX_PARAMETER_RESTITUTION, temp, .5, 0 ' Bounce
    ' Set the friction values of the body
    fzxSetBody cFZX_PARAMETER_STATICFRICTION, temp, .9, 0
    fzxSetBody cFZX_PARAMETER_DYNAMICFRICTION, temp, .25, 0
    ' Bodies wont live forever
    fzxSetBody cFZX_PARAMETER_LIFETIME, temp, RND * 20 + 10, 0
  END IF

END SUB

'********************************************************
'   Build you world here
'********************************************************

SUB buildScene
  DIM AS LONG temp

  'Initialize camera
  __fzxCamera.zoom = 1
  fzxCalculateFOV

  '********************************************************
  '   Setup World
  '********************************************************

  fzxVector2DSet __fzxWorld.minusLimit, -200000, -200000
  fzxVector2DSet __fzxWorld.plusLimit, 200000, 200000
  fzxVector2DSet __fzxWorld.spawn, 0, 0
  fzxVector2DSet __fzxWorld.gravity, 0.0, 100.0

  ' Set camera position
  fzxVector2DSet __fzxCamera.position, __fzxWorld.spawn.x, __fzxWorld.spawn.y - 300

  ' Some math used on the impulse side
  ' Todo: move this elsewhere
  DIM o AS tFZX_VECTOR2d
  fzxVector2DMultiplyScalarND o, __fzxWorld.gravity, dt
  __fzxWorld.resting = fzxVector2DLengthSq(o) + cFZX_EPSILON

  '********************************************************
  '   Build Level
  '********************************************************

  temp = fzxCreateBoxBodyEx("floor", 800, 10)
  fzxSetBody cFZX_PARAMETER_POSITION, temp, __fzxWorld.spawn.x, __fzxWorld.spawn.y
  fzxSetBody cFZX_PARAMETER_STATIC, temp, 0, 0


END SUB

SUB renderBodies STATIC
  DIM i AS LONG

  DIM AS LONG ub: ub = UBOUND(__fzxBody)

  'Draw all of the bodies that are visible
  i = 0: DO WHILE i < ub
    IF __fzxBody(i).enable AND __fzxBody(i).objectHash <> 0 THEN
      IF __fzxBody(i).shape.ty = cFZX_SHAPE_CIRCLE THEN
        renderWireFrameCircle i, _RGB32(0, 255, 0)
      ELSE IF __fzxBody(i).shape.ty = cFZX_SHAPE_POLYGON THEN
          renderWireFramePoly i
        END IF
      END IF
    END IF
    i = i + 1
  LOOP

END SUB

SUB renderWireFrameCircle (index AS LONG, c AS LONG)
  DIM AS tFZX_VECTOR2d o1, o2
  fzxWorldToCameraEx __fzxBody(index).fzx.position, o1
  CIRCLE (o1.x, o1.y), __fzxBody(index).shape.radius * __fzxCamera.zoom, c
  'o2.x = o1.x + (__fzxBody(index).shape.radius * __fzxCamera.zoom) * COS(__fzxBody(index).fzx.orient)
  'o2.y = o1.y + (__fzxBody(index).shape.radius * __fzxCamera.zoom) * SIN(__fzxBody(index).fzx.orient)
  'LINE (o1.x, o1.y)-(o2.x, o2.y), c
END SUB

SUB renderWireFramePoly (index AS LONG) STATIC
  DIM AS LONG polyCount, i
  polyCount = fzxGetBodyD(CFZX_PARAMETER_POLYCOUNT, index, 0)
  DIM AS tFZX_VECTOR2d vert1, vert2
  i = 0: DO WHILE i <= polyCount
    fzxGetBodyVert index, i, vert1
    fzxGetBodyVert index, fzxArrayNextIndex(i, polyCount), vert2

    fzxWorldToCamera index, vert1
    fzxWorldToCamera index, vert2
    LINE (vert1.x, vert1.y)-(vert2.x, vert2.y), _RGB(0, 255, 0)
  i = i + 1: LOOP
END SUB

SUB buildSplash
  DIM AS LONG temp

  'Initialize camera
  __fzxCamera.zoom = 1
  fzxCalculateFOV

  '********************************************************
  '   Setup World
  '********************************************************

  fzxVector2DSet __fzxWorld.minusLimit, -2000, -2000
  fzxVector2DSet __fzxWorld.plusLimit, 2000, 2000
  fzxVector2DSet __fzxWorld.spawn, 0, 0
  fzxVector2DSet __fzxWorld.gravity, 0.0, 100.0

  ' Set camera position
  fzxVector2DSet __fzxCamera.position, __fzxWorld.spawn.x, __fzxWorld.spawn.y - 300

  ' Some math used on the impulse side
  ' Todo: move this elsewhere
  DIM o AS tFZX_VECTOR2d
  fzxVector2DMultiplyScalarND o, __fzxWorld.gravity, dt
  __fzxWorld.resting = fzxVector2DLengthSq(o) + cFZX_EPSILON

  '********************************************************
  '   Build Level
  '********************************************************

  objectArray "s", 24, 36, 20, __fzxWorld.spawn.x, __fzxWorld.spawn.y - 500, 540

END SUB

SUB animateSplash
  DIM AS LONG temp
  IF RND > .995 THEN
    IF RND > .5 THEN
      temp = fzxCreateCircleBodyEx("b" + _TRIM$(STR$(RND * 1000000000)), 20)
    ELSE
      temp = fzxCreatePolyBodyEx("b" + _TRIM$(STR$(RND * 1000000000)), 20, 20, 3 + INT(RND * 5))
    END IF
    ' Set the bodies parameters
    ' Put the body on the screen
    fzxSetBody cFZX_PARAMETER_POSITION, temp, __fzxWorld.spawn.x + (RND * 500) - 250, __fzxWorld.spawn.y - 900
    ' Change its orientation or angle
    fzxSetBody cFZX_PARAMETER_ORIENT, temp, _D2R(RND * 360), 0
    ' Set the bouncyness
    fzxSetBody cFZX_PARAMETER_RESTITUTION, temp, .5, 0 ' Bounce
    ' Set the friction values of the body
    fzxSetBody cFZX_PARAMETER_STATICFRICTION, temp, .9, 0
    fzxSetBody cFZX_PARAMETER_DYNAMICFRICTION, temp, .9, 0
    ' Bodies wont live forever
    fzxSetBody cFZX_PARAMETER_LIFETIME, temp, 20, 0
  END IF
  fzxImpulseStep dt, iterations
  renderBodies
END SUB

SUB objectArray (id AS STRING, Count AS LONG, Radius AS DOUBLE, airgap AS DOUBLE, xp AS DOUBLE, yp AS DOUBLE, maxwidth AS LONG)
  DIM AS LONG temp, iter
  DIM AS DOUBLE xc, yc
  DIM AS DOUBLE PerRow, Diameter, rowCount, columnCount, oddRow
  Diameter = (Radius + airgap) * 2
  PerRow = INT(maxwidth / (Diameter + airgap))
  iter = 0: DO WHILE iter < Count
    IF RND > .5 THEN
      temp = fzxCreateCircleBodyEx(id + _TRIM$(STR$(iter)), Radius)
    ELSE
      temp = fzxCreatePolyBodyEx(id + _TRIM$(STR$(iter)), Radius, Radius, 3 + INT(RND * 5))
    END IF
    ' Set the bodies parameters
    columnCount = (iter MOD PerRow)
    rowCount = INT(iter / PerRow)
    oddRow = rowCount MOD 2
    xc = columnCount * (Diameter + airgap) + xp - (maxwidth * .5) + ((Radius + airgap) * oddRow * 1.4)
    yc = rowCount * ((Diameter + airgap) * .707) + yp
    fzxSetBody cFZX_PARAMETER_POSITION, temp, xc, yc
    fzxSetBody cFZX_PARAMETER_VELOCITY, temp, 0, 100
    ' Set the bouncyness
    fzxSetBody cFZX_PARAMETER_RESTITUTION, temp, .5, 0 ' Bounce
    ' Set the friction values of the body
    fzxSetBody cFZX_PARAMETER_STATICFRICTION, temp, .9, 0
    fzxSetBody cFZX_PARAMETER_DYNAMICFRICTION, temp, .9, 0
    fzxSetBody cFZX_PARAMETER_STATIC, temp, 0, 0
    fzxSetBody cFZX_PARAMETER_ORIENT, temp, _D2R(RND * 360), 0
  iter = iter + 1: LOOP
END SUB

SUB clearScene
  DIM AS LONG iter
  iter = 0: DO WHILE iter <= UBOUND(__fzxBody)
    fzxBodyDelete iter, 0
  iter = iter + 1: LOOP
END SUB


