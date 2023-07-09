'**********************************************************************************************
'   fzxMechanical
'**********************************************************************************************
$LET CIRCLEVISUAL = FALSE
'$DYNAMIC
OPTION _EXPLICIT
_TITLE "fzxNGN Gears"

' Initialize FZXNGN types, globals and constants
'$include:'..\fzxNGN_BASE_v2\fzxNGN_ini.bas'

SCREEN _NEWIMAGE(1024, 768, 32)

DIM AS LONG iterations: iterations = 10
DIM SHARED AS DOUBLE dt: dt = 1 / 120

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
  DIM AS DOUBLE angV
  DIM AS tFZX_VECTOR2d xy, sxy

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
    fzxSetBody cFZX_PARAMETER_STATICFRICTION, temp, .1, 0
    fzxSetBody cFZX_PARAMETER_DYNAMICFRICTION, temp, .85, 0
    ' Bodies wont live forever
    fzxSetBody cFZX_PARAMETER_LIFETIME, temp, RND * 20 + 60, 0
  END IF

  temp = fzxBodyManagerID("first_gear") ' Find body named "first_gear"
  fzxSetBody cFZX_PARAMETER_TORQUE, temp, 10, 0 ' Set the torque to 10. 10 what? You ask, its what ever you want. Units are arbitrary
  angV = fzxGetBodyD(cFZX_PARAMETER_ANGULARVELOCITY, temp, 0) ' Get the velocity
  fzxSetBody cFZX_PARAMETER_ANGULARVELOCITY, temp, fzxImpulseClamp(-1.5, 1.5, angV), 0 ' Clamp the velocity to 1.5. 1.5 what? You ask.

  ' Find the center of the gear
  fzxVector2DSet xy, fzxGetBodyD(cFZX_PARAMETER_POSITION, temp, cFZX_ARGUMENT_X), fzxGetBodyD(cFZX_PARAMETER_POSITION, temp, cFZX_ARGUMENT_Y)
  ' Convert that to screen coordinates
  fzxWorldToCameraEx xy, sxy
  ' Print the Id
  _PRINTSTRING (sxy.x - 30, sxy.y + 20), "1st gear"
  ' Print out the velocity
  LOCATE 3: PRINT USING "1st gear velocity:##.###  Drive gear."; angV

  ' Find the name of the body
  temp = fzxBodyManagerID("second_gear")
  ' Get the velocity
  angV = fzxGetBodyD(cFZX_PARAMETER_ANGULARVELOCITY, temp, 0)
  ' Find the center of the gear
  fzxVector2DSet xy, fzxGetBodyD(cFZX_PARAMETER_POSITION, temp, cFZX_ARGUMENT_X), fzxGetBodyD(cFZX_PARAMETER_POSITION, temp, cFZX_ARGUMENT_Y)
  ' Convert that to screen coordinates
  fzxWorldToCameraEx xy, sxy
  ' Print the Id
  _PRINTSTRING (sxy.x - 30, sxy.y + 20), "2nd gear"
  ' Print out the velocity
  LOCATE 4: PRINT USING "2nd gear velocity:##.###"; angV

  'Basically the same pattern for the third gear
  temp = fzxBodyManagerID("third_gear")
  angV = fzxGetBodyD(cFZX_PARAMETER_ANGULARVELOCITY, temp, 0)
  fzxVector2DSet xy, fzxGetBodyD(cFZX_PARAMETER_POSITION, temp, cFZX_ARGUMENT_X), fzxGetBodyD(cFZX_PARAMETER_POSITION, temp, cFZX_ARGUMENT_Y)
  fzxWorldToCameraEx xy, sxy
  _PRINTSTRING (sxy.x - 30, sxy.y + 20), "3rd gear"
  LOCATE 5: PRINT USING "3rd gear velocity:##.###"; angV

END SUB

'********************************************************
'   Build you world here
'********************************************************

SUB buildScene

  'Initialize camera
  __fzxCamera.zoom = 2.5
  fzxCalculateFOV

  '********************************************************
  '   Setup World
  '********************************************************

  fzxVector2DSet __fzxWorld.minusLimit, -20000, -20000
  fzxVector2DSet __fzxWorld.plusLimit, 20000, 20000
  fzxVector2DSet __fzxWorld.spawn, 0, 0
  fzxVector2DSet __fzxWorld.gravity, 0.0, 10.0

  ' Set camera position
  fzxVector2DSet __fzxCamera.position, __fzxWorld.spawn.x, __fzxWorld.spawn.y

  ' Some math used on the impulse side
  ' Todo: move this elsewhere
  DIM o AS tFZX_VECTOR2d
  fzxVector2DMultiplyScalarND o, __fzxWorld.gravity, dt
  __fzxWorld.resting = fzxVector2DLengthSq(o) + cFZX_EPSILON

  '********************************************************
  '   Build Level
  '********************************************************

  createGear "first", __fzxWorld.spawn.x + 48, __fzxWorld.spawn.y - 83, 15, 4
  createGear "second", __fzxWorld.spawn.x, __fzxWorld.spawn.y - 83, 25, 4
  createGear "third", __fzxWorld.spawn.x, __fzxWorld.spawn.y, 50, 4

END SUB


SUB createGear (idgear AS STRING, xo AS DOUBLE, yo AS DOUBLE, dia AS DOUBLE, toothSize AS LONG)
  DIM AS LONG gear1, pivot1, temp, tempj
  DIM AS DOUBLE theta, toothIncr
  DIM AS STRING id

  ' Pivot is the static part of the gear that keeps it planted
  pivot1 = fzxCreateCircleBodyEx(idgear + "_pivot", 5)
  fzxSetBody cFZX_PARAMETER_POSITION, pivot1, xo, yo
  fzxSetBody cFZX_PARAMETER_STATIC, pivot1, 0, 0
  ' Collision mask keeps the gear from colliding with the pivot
  fzxSetBody cFZX_PARAMETER_COLLISIONMASK, pivot1, 0, 0

  ' Build the actual gear wheel
  gear1 = fzxCreateCircleBodyEx(idgear + "_gear", dia)
  fzxSetBody cFZX_PARAMETER_POSITION, gear1, xo, yo

  ' Connect the pivot and gearwheel together
  tempj = fzxJointCreate(pivot1, gear1, xo, yo)
  __fzxJoints(tempj).softness = .000002
  __fzxJoints(tempj).biasFactor = 4000
  '__fzxJoints(tempj).render = 1

  ' Calculate tooth spacing aroud the gear
  toothIncr = 360 / (INT((_PI * dia) / toothSize))

  FOR theta = 0 TO 359 STEP toothIncr
    ' Name the tooth
    id = idgear + "_tooth_" + _TRIM$(STR$(theta))
    ' Create a triangle for a tooth
    temp = fzxCreatePolyBodyEx(id, toothSize, toothSize, 3)
    ' Plant the tooth around the perimeter
    fzxSetBody cFZX_PARAMETER_POSITION, temp, xo + (dia + toothSize * .5) * COS(_D2R(theta)), yo + (dia + toothSize * .5) * SIN(_D2R(theta))
    ' Adjust the angle of tooth so it points outward
    fzxSetBody cFZX_PARAMETER_ORIENT, temp, _D2R(theta), 0
    ' Attach tooth to gear wheel
    tempj = fzxJointCreate(temp, gear1, xo + (dia - 5) * COS(_D2R(theta)), yo + (dia - 5) * SIN(_D2R(theta)))
    __fzxJoints(tempj).softness = 0.0000002
    __fzxJoints(tempj).biasFactor = 4000
    ' __fzxJoints(tempj).render = 1
  NEXT

END SUB

SUB renderBodies STATIC
  DIM i AS LONG

  DIM AS LONG ub: ub = UBOUND(__fzxBody)
  DIM AS LONG uJ: uJ = UBOUND(__fzxJoints)

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

  ' Render Joint connections
  i = 0: DO WHILE i <= uJ
    IF __fzxJoints(i).render = 1 THEN renderJoints i
  i = i + 1: LOOP

END SUB

SUB renderWireFrameCircle (index AS LONG, c AS LONG)
  DIM AS tFZX_VECTOR2d o1
  fzxWorldToCameraEx __fzxBody(index).fzx.position, o1
  CIRCLE (o1.x, o1.y), __fzxBody(index).shape.radius * __fzxCamera.zoom, c
  $IF CIRCLEVISUAL = TRUE THEN
    DIM AS tFZX_VECTOR2d o2
    o2.x = o1.x + (__fzxBody(index).shape.radius * __fzxCamera.zoom) * COS(__fzxBody(index).fzx.orient)
    o2.y = o1.y + (__fzxBody(index).shape.radius * __fzxCamera.zoom) * SIN(__fzxBody(index).fzx.orient)
    LINE (o1.x, o1.y)-(o2.x, o2.y), c
  $END IF
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

SUB renderJoints (index AS LONG)
  IF __fzxJoints(index).overwrite = 1 THEN EXIT SUB
  DIM AS tFZX_VECTOR2d o1, o2
  fzxVector2DSet o1, 0, 0
  fzxVector2DSet o2, 0, 0
  fzxWorldToCameraEx __fzxBody(__fzxJoints(index).body1).fzx.position, o1
  fzxWorldToCameraEx __fzxBody(__fzxJoints(index).body2).fzx.position, o2
  LINE (o1.x, o1.y)-(o2.x, o2.y), __fzxJoints(index).wireframe_color
END SUB




