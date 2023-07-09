'**********************************************************************************************
'   fzxBareBones
'**********************************************************************************************

'$DYNAMIC
OPTION _EXPLICIT
_TITLE "fzxNGN Bare Bones"

' Initialize FZXNGN types, globals and constants
'$include:'..\fzxNGN_BASE_v2\fzxNGN_ini.bas'

SCREEN _NEWIMAGE(1024, 768, 32)

DIM AS LONG iterations: iterations = 100
DIM SHARED AS DOUBLE dt: dt = 1 / 60

'**********************************************************************************************
' Build the playfield
'**********************************************************************************************

buildScene

'**********************************************************************************************
' This is the main loop
'**********************************************************************************************

DO
  CLS: LOCATE 1: PRINT "Click the mouse on the playfield to spawn an object"
  fzxHandleInputDevice
  animatescene
  fzxImpulseStep dt, iterations
  renderBodies
  _DISPLAY
LOOP UNTIL INKEY$ = CHR$(27)

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
    fzxSetBody cFZX_PARAMETER_VELOCITY, temp, __fzxInputDevice.mouse.velocity.x, __fzxInputDevice.mouse.velocity.y
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
  fzxVector2DSet __fzxWorld.gravity, 0.0, 10.0

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
  o2.x = o1.x + (__fzxBody(index).shape.radius * __fzxCamera.zoom) * COS(__fzxBody(index).fzx.orient)
  o2.y = o1.y + (__fzxBody(index).shape.radius * __fzxCamera.zoom) * SIN(__fzxBody(index).fzx.orient)
  LINE (o1.x, o1.y)-(o2.x, o2.y), c
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



