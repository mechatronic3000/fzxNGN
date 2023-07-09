'**********************************************************************************************
'   fzxOrbital Mechanics
'**********************************************************************************************

'$DYNAMIC
OPTION _EXPLICIT
_TITLE "fzxNGN Orbital Mechanics"

' Initialize FZXNGN types, globals and constants
'$include:'..\fzxNGN_BASE_v2\fzxNGN_ini.bas'

SCREEN _NEWIMAGE(1024, 768, 32)

DIM AS LONG iterations: iterations = 1000
DIM SHARED AS DOUBLE dt: dt = 1 / 120

TYPE tTRAIL
  xy AS tFZX_VECTOR2d
  t AS SINGLE
  c AS LONG
END TYPE

DIM SHARED trail(5000) AS tTRAIL

'**********************************************************************************************
' Build the playfield
'**********************************************************************************************

CONST cGRAVCONST = 100000000
' To little for our simulation
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

  ' Use the mouse wheel to set Camera Zoom
  __fzxCamera.zoom = fzxImpulseClamp(.001, 2, __fzxCamera.zoom - (__fzxInputDevice.mouse.wCount * .001))
  __fzxInputDevice.mouse.wCount = 0
  fzxCalculateFOV

  ' Move the Camera to where you right clicked
  IF __fzxInputDevice.mouse.b2.PosEdge THEN
    fzxVector2DSet __fzxCamera.position, __fzxInputDevice.mouse.worldPosition.x, __fzxInputDevice.mouse.worldPosition.y
  END IF

  ' Give on screen visual, for how hard you are drawing back the velocity
  IF __fzxInputDevice.mouse.b1.drag THEN
    CIRCLE (__fzxInputDevice.mouse.b1.anchorPosition.x, __fzxInputDevice.mouse.b1.anchorPosition.y), 3, _RGB32(255, 255, 0)
    LINE (__fzxInputDevice.mouse.b1.anchorPosition.x, __fzxInputDevice.mouse.b1.anchorPosition.y)-(__fzxInputDevice.mouse.position.x, __fzxInputDevice.mouse.position.y), _RGB32(0, 0, 127), , &B1110110111011011
    CIRCLE (__fzxInputDevice.mouse.position.x, __fzxInputDevice.mouse.position.y), 3, _RGB32(255, 0, 0)
  END IF

  ' Release the orbital body
  IF __fzxInputDevice.mouse.b1.NegEdge THEN
    vel = fzxVector2DDistance(__fzxInputDevice.mouse.b1.anchorPosition, __fzxInputDevice.mouse.position) * __fzxCamera.invZoom
    angle = fzxGetAngleVector2d#(__fzxInputDevice.mouse.b1.anchorPosition, __fzxInputDevice.mouse.position)
    sa = -SIN(angle) * vel
    ca = COS(angle) * vel

    temp = fzxCreateCircleBodyEx("b" + _TRIM$(STR$(RND * 1000000000)), 100)
    ' Set the bodies parameters
    ' Put the body where the mouse is on the screen
    fzxSetBody cFZX_PARAMETER_POSITION, temp, __fzxInputDevice.mouse.worldPosition.x, __fzxInputDevice.mouse.worldPosition.y
    ' Give it the mouse's velocity
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

  '********************************************************
  '   Build Level
  '********************************************************

  temp = fzxCreateCircleBodyEx("planetX", 800)
  fzxSetBody cFZX_PARAMETER_POSITION, temp, __fzxWorld.spawn.x, __fzxWorld.spawn.y

END SUB

SUB gravitizeEverthing
  DIM AS LONG i, j, touch
  DIM AS LONG ub: ub = UBOUND(__fzxBody)
  DIM AS DOUBLE gv, dist, newRAd
  DIM AS tFZX_VECTOR2d v1
  i = 0: DO WHILE i < ub
    j = 0: DO WHILE j < ub
      IF __fzxBody(i).enable AND __fzxBody(i).objectHash <> 0 AND __fzxBody(j).enable AND __fzxBody(j).objectHash <> 0 AND i <> j THEN

        dist = fzxVector2DDistance(__fzxBody(i).fzx.position, __fzxBody(j).fzx.position)
        gv = (cGRAVCONST * ((__fzxBody(i).fzx.mass * __fzxBody(j).fzx.mass) / (dist * dist)))

        fzxVector2DSubVectorND v1, __fzxBody(i).fzx.position, __fzxBody(j).fzx.position
        fzxVector2DNormalize v1

        __fzxBody(i).fzx.force.x = __fzxBody(i).fzx.force.x - (gv * v1.x)
        __fzxBody(i).fzx.force.y = __fzxBody(i).fzx.force.y - (gv * v1.y)
      END IF
      j = j + 1
    LOOP

    ' Bodies can absorb each other
    touch = fzxIsBodyTouching(i) ' Who's touching me?
    IF touch > 0 THEN
      IF __fzxBody(i).fzx.mass > __fzxBody(touch).fzx.mass THEN ' Who's bigger?
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
  DIM AS LONG i, j, skipCount
  DIM AS tFZX_VECTOR2d tempV
  DIM AS LONG ub: ub = UBOUND(__fzxBody)
  DIM AS SINGLE time, fade

  'Draw all of the bodies that are visible
  i = 0: DO WHILE i <= ub
    IF __fzxBody(i).enable AND __fzxBody(i).objectHash <> 0 THEN
      IF __fzxBody(i).shape.ty = cFZX_SHAPE_CIRCLE THEN
        renderWireFrameCircle i, _RGB32(0, 255, 0)
      ELSE IF __fzxBody(i).shape.ty = cFZX_SHAPE_POLYGON THEN
          renderWireFramePoly i
        END IF
      END IF
      'Draw trails
      IF skipCount MOD 10 = 0 THEN ' dont add trails every cycle
        ' add a trail to the buffer
        j = 0: DO WHILE j <= UBOUND(trail)
          IF trail(j).t = 0 THEN
            trail(j).t = TIMER + 5
            trail(j).xy = __fzxBody(i).fzx.position
            trail(j).c = _RGB32(205, 194, 50)
            EXIT DO
          END IF
        j = j + 1: LOOP

      END IF
      ' Draw trail dots
      j = 0: DO WHILE j <= UBOUND(trail)
        IF trail(j).t > 0 THEN
          fzxWorldToCameraEx trail(j).xy, tempV
          PSET (tempV.x, tempV.y), trail(j).c
          time = TIMER
          fade = fzxImpulseClamp(0, 1, (trail(j).t - time) / 3.00)
          trail(j).c = _RGB32(INT(_RED(trail(j).c) * fade), INT(_GREEN(trail(j).c) * fade), INT(_BLUE(trail(j).c) * fade))
          ' Eliminate expired trail dots
          IF TIMER > trail(j).t THEN trail(j).t = 0
        END IF
      j = j + 1: LOOP

    END IF


    i = i + 1
  LOOP
  skipCount = skipCount + 1
END SUB


SUB renderWireFrameCircle (index AS LONG, c AS LONG)
  DIM AS tFZX_VECTOR2d o1
  fzxWorldToCameraEx __fzxBody(index).fzx.position, o1
  CIRCLE (o1.x, o1.y), __fzxBody(index).shape.radius * __fzxCamera.zoom, c
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



