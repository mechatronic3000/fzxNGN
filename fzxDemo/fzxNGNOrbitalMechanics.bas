'**********************************************************************************************
'   fzxOrbital Mechanics
'**********************************************************************************************

'$DYNAMIC
OPTION _EXPLICIT
_TITLE "fzxNGN Orbital Mechanics"

' Initialize FZXNGN types, globals and constants
'$include:'..\fzxNGN_BASE_v2\fzxNGN_ini.bas'

SCREEN _NEWIMAGE(1024, 768, 32)

__fzxWorld.deltaTime = 1 / 120
__fzxWorld.iterations = 1000

TYPE tTRAIL
  xy AS tFZX_VECTOR2d
  t AS SINGLE
  c AS LONG
END TYPE

TYPE tTEMPBODY
  en AS _BYTE
  xy AS tFZX_VECTOR2d
  mass AS DOUBLE
  vel AS tFZX_VECTOR2d
  force AS tFZX_VECTOR2d
END TYPE

DIM SHARED AS tFZX_BODY tempBody(UBOUND(__fzxBody))
DIM SHARED trail(5000) AS tTRAIL
DIM SHARED AS _BYTE pause

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
  IF NOT pause THEN CLS
  fzxHandleInputDevice
  animatescene
  IF NOT pause THEN
    fzxImpulseStep
  END IF
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
  DIM AS LONG temp, iter, bix, i, j, ub
  DIM AS DOUBLE vel, angle, sa, ca, dist, gv
  DIM AS tFZX_VECTOR2d gravVec, v2
  'DIM AS tTEMPBODY b(UBOUND(__fzxBody))

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

  END IF

  IF NOT pause THEN
    gravitizeEverthing
  END IF

  LOCATE 1
  PRINT "Simple Gravity Mechanics Simulator"
  PRINT "Click and drag left mouse button to add a object and give it velocity."
  PRINT "Right click to move the camera. Use mouse wheel to zoom."
  PRINT "Press <SPACE> to pause and unpause simulation"
  IF pause THEN LOCATE 44: PRINT "--PAUSED--"

  IF fzxBodyManagerID("planetX") >= 0 THEN LOCATE 45: PRINT USING "PlanetX mass:#######.#"; __fzxBody(fzxBodyManagerID("planetX")).fzx.mass
  LOCATE 46: PRINT USING "Zoom :##.######  Scale: ######.##"; __fzxCamera.zoom; __fzxCamera.invZoom
  ' Pause Mode
  IF __fzxInputDevice.keyboard.keyHit = 32 THEN
    pause = NOT pause
  END IF

  'Not working correctly
  'IF pause THEN
  '  ub = UBOUND(__fzxBody)
  '  REDIM b(ub) AS tTEMPBODY
  '  bix = 0: DO WHILE bix <= ub
  '    b(bix).en = __fzxBody(bix).enable AND __fzxBody(bix).objectHash <> 0
  '    b(bix).xy = __fzxBody(bix).fzx.position
  '    b(bix).vel = __fzxBody(bix).fzx.velocity
  '    b(bix).mass = __fzxBody(bix).fzx.mass
  '  bix = bix + 1: LOOP

  '  iter = 0: DO WHILE iter < 2000
  '    i = 0: DO WHILE i <= ub
  '      IF b(i).en THEN
  '        j = 0: DO WHILE j <= ub
  '          IF b(j).en AND i <> j THEN
  '            dist = fzxVector2DDistance(b(i).xy, b(j).xy)
  '            gv = gravity(b(i).mass, b(j).mass, dist)
  '            fzxVector2DSubVectorND gravVec, b(i).xy, b(j).xy
  '            fzxVector2DNormalize gravVec
  '            fzxVector2DMultiplyScalar gravVec, -gv
  '            integrateGravity b(i), gravVec
  '          END IF
  '        j = j + 1: LOOP
  '        fzxWorldToCameraEx b(i).xy, v2
  '        PSET (v2.x, v2.y), _RGB32(244, 0, 127)
  '      END IF
  '    i = i + 1: LOOP
  '  iter = iter + 1: LOOP
  'END IF
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

FUNCTION gravity# (massA AS DOUBLE, massB AS DOUBLE, dist AS DOUBLE)
  gravity = (cGRAVCONST * ((massA * massB) / (dist * dist)))
END FUNCTION

SUB integrateGravity (b AS tTEMPBODY, gv AS tFZX_VECTOR2d)
  DIM dts AS DOUBLE
  dts = __fzxWorld.deltaTime * .5
  fzxVector2DAddVectorScalar b.xy, b.vel, __fzxWorld.deltaTime
  fzxVector2DAddVectorScalar b.vel, gv, (1 / b.mass) * dts
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
        gv = gravity(__fzxBody(i).fzx.mass, __fzxBody(j).fzx.mass, dist)

        fzxVector2DSubVectorND v1, __fzxBody(i).fzx.position, __fzxBody(j).fzx.position
        fzxVector2DNormalize v1
        fzxVector2DAddVectorScalar __fzxBody(i).fzx.force, v1, -gv
      END IF
    j = j + 1: LOOP

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
  i = i + 1: LOOP
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
      IF NOT pause THEN
        'Add trail dot to stack
        IF skipCount MOD 20 = 0 THEN ' dont add trails every cycle
          ' add a trail to the buffer
          j = 0: DO WHILE j <= UBOUND(trail)
            IF trail(j).t = 0 THEN
              trail(j).t = TIMER + 10
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
            IF TIMER > trail(j).t AND NOT pause THEN trail(j).t = 0
          END IF
        j = j + 1: LOOP

      END IF
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



