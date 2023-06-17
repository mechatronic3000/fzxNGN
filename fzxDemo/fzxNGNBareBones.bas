'**********************************************************************************************
'   fzxBareBones
'**********************************************************************************************

'$DYNAMIC
OPTION _EXPLICIT
_TITLE "fzxNGN Bare Bones"

' Initialize FZXNGN types, globals and constants
'$include:'..\fzxNGN_BASE_v2\fzxNGN_ini.bas'

SCREEN _NEWIMAGE(1024, 768, 32)

DIM AS LONG iterations: iterations = 2
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
      temp = fzxCreateBoxBodyEx("b" + _TRIM$(STR$(RND * 1000000000)), 10, 10)
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
    fzxSetBody cFZX_PARAMETER_STATICFRICTION, temp, .1, 0
    fzxSetBody cFZX_PARAMETER_DYNAMICFRICTION, temp, .85, 0
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
  ' Set camera position
  fzxVector2DSet __fzxCamera.position, __fzxWorld.spawn.x, __fzxWorld.spawn.y - 300

  '********************************************************
  '   Setup World
  '********************************************************

  fzxVector2DSet __fzxWorld.minusLimit, -200000, -200000
  fzxVector2DSet __fzxWorld.plusLimit, 200000, 200000
  fzxVector2DSet __fzxWorld.spawn, 0, 0
  fzxVector2DSet __fzxWorld.gravity, 0.0, 10.0

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
  DIM AS tFZX_VECTOR2d scSize, scMid, scUpperLeft, camUpperLeft, aabbUpperLeft, aabbSize, aabbHalfSize
  DIM AS LONG ub: ub = UBOUND(__fzxBody)

  ' Todo : move this to camera functions
  fzxVector2DSet aabbSize, 40000, 40000
  fzxVector2DSet aabbHalfSize, aabbSize.x / 2, aabbSize.y / 2

  fzxVector2DSet scUpperLeft, 0, 0
  fzxVector2DSet scSize, _WIDTH, _HEIGHT

  fzxVector2DDivideScalarND scMid, scSize, 2
  fzxVector2DSubVectorND camUpperLeft, __fzxCamera.position, scMid

  'Draw all of the bodies that are visible
  i = 0: DO WHILE i < ub
    IF __fzxBody(i).enable THEN
      'fzxAABB to cut down on rendering objects out of camera view
      fzxVector2DSubVectorND aabbUpperLeft, __fzxBody(i).fzx.position, aabbHalfSize
      IF fzxAABBOverlap(camUpperLeft.x, camUpperLeft.y, scSize.x, scSize.y, aabbUpperLeft.x, aabbUpperLeft.y, aabbSize.x, aabbSize.y) THEN
        IF __fzxBody(i).shape.ty = cFZX_SHAPE_CIRCLE THEN
          renderWireFrameCircle i, _RGB32(0, 255, 0)
        ELSE IF __fzxBody(i).shape.ty = cFZX_SHAPE_POLYGON THEN
            renderWireFramePoly i
          END IF
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

SUB renderWireFramePoly (index AS LONG)
  DIM vert(3) AS tFZX_VECTOR2d

  fzxGetBodyVert index, 0, vert(0)
  fzxWorldToCamera index, vert(0)

  fzxGetBodyVert index, 1, vert(1)
  fzxWorldToCamera index, vert(1)

  fzxGetBodyVert index, 2, vert(2)
  fzxWorldToCamera index, vert(2)

  fzxGetBodyVert index, 3, vert(3)
  fzxWorldToCamera index, vert(3)

  LINE (vert(0).x, vert(0).y)-(vert(1).x, vert(1).y), _RGB(0, 255, 0)
  LINE (vert(1).x, vert(1).y)-(vert(2).x, vert(2).y), _RGB(0, 255, 0)
  LINE (vert(2).x, vert(2).y)-(vert(3).x, vert(3).y), _RGB(0, 255, 0)
  LINE (vert(3).x, vert(3).y)-(vert(0).x, vert(0).y), _RGB(0, 255, 0)
END SUB


