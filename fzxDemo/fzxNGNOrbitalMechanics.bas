'**********************************************************************************************
'   fzxOrbital Mechanics
'**********************************************************************************************

'$DYNAMIC
OPTION _EXPLICIT
_TITLE "fzxNGN Orbital Mechanics"

' Initialize FZXNGN types, globals and constants
'$include:'..\fzxNGN_BASE_v2\fzxNGN_ini.bas'

SCREEN _NEWIMAGE(1024, 768, 32)

DIM AS LONG iterations: iterations = 10
DIM SHARED AS DOUBLE dt: dt = 1 / 60

'**********************************************************************************************
' Build the playfield
'**********************************************************************************************

CONST cGRAVCONST = 1
'CONST cGRAVCONST = 6.674E-11
buildScene

'**********************************************************************************************
' This is the main loop
'**********************************************************************************************

DO
  CLS
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
  DIM AS DOUBLE vel, angle, sa, ca

  ' Create a object on mouse click
  __fzxCamera.zoom = fzxImpulseClamp(.001, 2, __fzxCamera.zoom - (__fzxInputDevice.mouse.wCount * .001))
  __fzxInputDevice.mouse.wCount = 0
  fzxCalculateFOV
  IF __fzxInputDevice.mouse.b2.PosEdge THEN

    fzxVector2DSet __fzxCamera.position, __fzxInputDevice.mouse.worldPosition.x, __fzxInputDevice.mouse.worldPosition.y
  END IF


  IF __fzxInputDevice.mouse.b1.drag THEN
    CIRCLE (__fzxInputDevice.mouse.b1.anchorPosition.x, __fzxInputDevice.mouse.b1.anchorPosition.y), 3, _RGB32(255, 255, 0)
    LINE (__fzxInputDevice.mouse.b1.anchorPosition.x, __fzxInputDevice.mouse.b1.anchorPosition.y)-(__fzxInputDevice.mouse.position.x, __fzxInputDevice.mouse.position.y), _RGB32(0, 0, 127), , &B1110110111011011
    CIRCLE (__fzxInputDevice.mouse.position.x, __fzxInputDevice.mouse.position.y), 3, _RGB32(255, 0, 0)
  END IF
  IF __fzxInputDevice.mouse.b1.NegEdge THEN

    ' Drop a ball
    vel = fzxVector2DDistance(__fzxInputDevice.mouse.b1.anchorPosition, __fzxInputDevice.mouse.position) * __fzxCamera.invZoom

    angle = getangle(__fzxInputDevice.mouse.b1.anchorPosition.x, __fzxInputDevice.mouse.b1.anchorPosition.y, __fzxInputDevice.mouse.position.x, __fzxInputDevice.mouse.position.y)
    sa = -SIN(angle) * vel
    ca = COS(angle) * vel

    temp = fzxCreateCircleBodyEx("b" + _TRIM$(STR$(RND * 1000000000)), 100)
    ' Set the bodies parameters
    ' Put the body where the mouse is on the screen
    fzxSetBody cFZX_PARAMETER_POSITION, temp, __fzxInputDevice.mouse.worldPosition.x, __fzxInputDevice.mouse.worldPosition.y
    ' Give it the mouse's velocity, so you can throw it
    fzxSetBody cFZX_PARAMETER_VELOCITY, temp, sa, ca
    fzxSetBody cFZX_PARAMETER_STATICFRICTION, temp, 0.9, 0
    fzxSetBody cFZX_PARAMETER_DYNAMICFRICTION, temp, 0.7, 0
    fzxSetBody cFZX_PARAMETER_RESTITUTION, temp, .10, 0

  END IF


  gravitizeEverthing

  LOCATE 1
  PRINT "Simple Gravity Mechanics Simulator"
  PRINT "Click and drag left mouse button to add a object and give it velocity."
  PRINT "Right click to move the camera. Use mouse wheel to zoom."

  IF fzxBodyManagerID("planetX") >= 0 THEN LOCATE 45: PRINT USING "PlanetX mass:#######.#"; __fzxBody(fzxBodyManagerID("planetX")).fzx.mass
END SUB

'********************************************************
'   Build you world here
'********************************************************

SUB buildScene
  DIM AS LONG temp

  'Initialize camera
  __fzxCamera.zoom = .0625
  fzxCalculateFOV

  '********************************************************
  '   Setup World
  '********************************************************

  fzxVector2DSet __fzxWorld.minusLimit, -200000, -200000
  fzxVector2DSet __fzxWorld.plusLimit, 200000, 200000
  fzxVector2DSet __fzxWorld.spawn, 0, 0
  fzxVector2DSet __fzxWorld.gravity, 0.0, 0.0

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

  temp = fzxCreateCircleBodyEx("planetX", 800)
  fzxSetBody cFZX_PARAMETER_POSITION, temp, __fzxWorld.spawn.x, __fzxWorld.spawn.y
  fzxSetBody cFZX_PARAMETER_STATICFRICTION, temp, 0.9, 0
  fzxSetBody cFZX_PARAMETER_DYNAMICFRICTION, temp, 0.7, 0
  fzxSetBody cFZX_PARAMETER_RESTITUTION, temp, .10, 0

END SUB

SUB gravitizeEverthing
  DIM AS LONG i, j, touch
  DIM AS LONG ub: ub = UBOUND(__fzxBody)
  DIM AS DOUBLE angle, sa, ca, gv, dist, newRAd
  DIM AS tFZX_VECTOR2d v1, v2
  i = 0: DO WHILE i < ub
    j = 0: DO WHILE j < ub
      IF __fzxBody(i).enable AND __fzxBody(i).objectHash <> 0 AND __fzxBody(j).enable AND __fzxBody(j).objectHash <> 0 AND i <> j THEN

        dist = fzxVector2DDistance(__fzxBody(i).fzx.position, __fzxBody(j).fzx.position)
        gv = (cGRAVCONST * ((__fzxBody(i).fzx.mass * __fzxBody(j).fzx.mass) / (dist * dist)))

        ' Some math guru's can easily simplify this
        fzxVector2DSubVectorND v1, __fzxBody(i).fzx.position, __fzxBody(j).fzx.position '(o AS tFZX_VECTOR2d, v AS tFZX_VECTOR2d, m AS tFZX_VECTOR2d)
        fzxVector2DNormalize v1
        fzxVector2DMultiplyScalar v1, 100000000

        __fzxBody(i).fzx.force.x = __fzxBody(i).fzx.force.x - (gv * v1.x)
        __fzxBody(i).fzx.force.y = __fzxBody(i).fzx.force.y - (gv * v1.y)
      END IF
      j = j + 1
    LOOP

    touch = fzxIsBodyTouching(i)
    IF touch > 0 THEN
      IF __fzxBody(i).fzx.mass > __fzxBody(touch).fzx.mass THEN
        newRAd = addCircles(__fzxBody(i).shape.radius, __fzxBody(touch).shape.radius)
        __fzxBody(i).shape.radius = newRAd
        fzxCircleComputeMass i, cFZX_MASS_DENSITY
        fzxBodyDelete touch, 0
      ELSE
        newRAd = addCircles(__fzxBody(i).shape.radius, __fzxBody(touch).shape.radius)
        __fzxBody(touch).shape.radius = newRAd
        fzxCircleComputeMass touch, cFZX_MASS_DENSITY
        fzxBodyDelete i, 0
      END IF
    END IF

    i = i + 1
  LOOP

END SUB

FUNCTION addCircles# (r1 AS DOUBLE, r2 AS DOUBLE)
  DIM AS DOUBLE a1, a2
  a1 = _PI * r1 * r1
  a2 = _PI * r2 * r2
  addCircles = areaToRadius(a1 + a2)
END FUNCTION

FUNCTION areaToRadius# (area AS DOUBLE)
  areaToRadius = SQR(area / _PI)
END FUNCTION

SUB renderBodies STATIC
  DIM AS LONG i

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

' Function written bu Galleon (modified)
FUNCTION getangle# (x1 AS DOUBLE, y1 AS DOUBLE, x2 AS DOUBLE, y2 AS DOUBLE) 'returns 0-359.99...
  IF y2 = y1 THEN
    IF x1 = x2 THEN EXIT FUNCTION
    IF x2 > x1 THEN getangle# = _PI * .5 ELSE getangle# = _PI * 1.5
    EXIT FUNCTION
  END IF
  IF x2 = x1 THEN
    IF y2 > y1 THEN getangle# = _PI
    EXIT FUNCTION
  END IF
  IF y2 < y1 THEN
    IF x2 > x1 THEN
      getangle# = -ATN((x2 - x1) / (y2 - y1))
    ELSE
      getangle# = -ATN((x2 - x1) / (y2 - y1)) + (2 * _PI)
    END IF
  ELSE
    getangle# = -ATN((x2 - x1) / (y2 - y1)) + _PI
  END IF
END FUNCTION


SUB renderWireFrameCircle (index AS LONG, c AS LONG)
  DIM AS tFZX_VECTOR2d o1, o2
  fzxWorldToCameraEx __fzxBody(index).fzx.position, o1
  CIRCLE (o1.x, o1.y), __fzxBody(index).shape.radius * __fzxCamera.zoom, c
  'o2.x = o1.x + (__fzxBody(index).shape.radius * __fzxCamera.zoom) * COS(__fzxBody(index).fzx.orient)
  'o2.y = o1.y + (__fzxBody(index).shape.radius * __fzxCamera.zoom) * SIN(__fzxBody(index).fzx.orient)
  'LINE (o1.x, o1.y)-(o2.x, o2.y), c
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



