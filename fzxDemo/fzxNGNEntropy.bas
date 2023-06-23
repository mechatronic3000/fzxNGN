'**********************************************************************************************
'   fzxEntropy
' This is not meant to be run in realtime, The is to run 2 cycles. First cycle
' is to determine where each ball lands in the pile at the bottom. The second cycle is to
' use that information to draw a picture of colored balls at the bottom.
' I've decided to abandon this project due to be way too slow.
'**********************************************************************************************

'$DYNAMIC
OPTION _EXPLICIT
_TITLE "fzxNGN Entropy"

' Initialize FZXNGN types, globals and constants
'$include:'..\fzxNGN_BASE_v2\fzxNGN_ini.bas'

SCREEN _NEWIMAGE(800, 1000, 32)

DIM AS LONG iterations: iterations = 100
DIM SHARED AS DOUBLE dt: dt = 1 / 120


'**********************************************************************************************
' Build the playfield
'**********************************************************************************************

DIM SHARED AS LONG ballCount
DIM SHARED AS LONG img, mixer

img = _NEWIMAGE(15, 46, 32)
buildImg (img)


buildScene

'**********************************************************************************************
' This is the main loop
'**********************************************************************************************

DO

  fzxHandleInputDevice
  animateScene
  fzxImpulseStep dt, iterations
  renderBodies
  'LOCATE 1: PRINT USING "MX:#####.# MY:#####.#"; __fzxInputDevice.mouse.worldPosition.x; __fzxInputDevice.mouse.worldPosition.y

  _DISPLAY
LOOP UNTIL INKEY$ = CHR$(27)

SYSTEM

' This provides access to all of the fzxNGN functionality
'$include:'..\fzxNGN_BASE_v2\fzxNGN_BASE.bas'

'**********************************************************************************************
'    This is where you interact with the world.
'**********************************************************************************************

SUB animateScene STATIC
  DIM AS LONG iter, ticTock, releaseCount, released, doneCount, done
  ' prime the clock
  IF ticTock = 0 THEN ticTock = TIMER(.001)

  doneCount = 0
  iter = 0: DO WHILE iter <= UBOUND(__fzxBody)
    IF __fzxBody(iter).objectHash <> 0 THEN
      IF fzxBodyAtRest(iter, 5.0) THEN
        IF __fzxBody(iter).specFunc.arg = 0 THEN
          fzxSetBody cFZX_PARAMETER_SPECIALFUNCTION, iter, 0, TIMER(.001)
        ELSE
          IF TIMER(.001) - __fzxBody(iter).specFunc.arg > (30 + (releaseCount * 20)) THEN
            fzxSetBody cFZX_PARAMETER_STATIC, iter, 0, 0
            fzxSetBody cFZX_PARAMETER_COLOR, iter, _RGB32(255, 0, 0), 0
          END IF
        END IF
      ELSE
        fzxSetBody cFZX_PARAMETER_SPECIALFUNCTION, iter, 0, 0
      END IF

      IF LEFT$(__fzxBody(iter).objectName, 1) = "b" AND __fzxBody(iter).fzx.mass = 0 THEN
        doneCount = doneCount + 1
        IF (doneCount / ballCount) * 100 > 99.5 THEN done = 1
      END IF
    END IF
  iter = iter + 1: LOOP


  IF releaseCount = 0 OR (TIMER(.001) - ticTock > 45) THEN
    ticTock = TIMER(.001)
    IF releaseCount < 7 THEN

      released = 0
      iter = UBOUND(__fzxBody): DO

        IF released < 100 THEN
          IF LEFT$(__fzxBody(iter).objectName, 1) = "b" THEN
            IF __fzxBody(iter).noPhysics = 1 THEN
              fzxSetBody cFZX_PARAMETER_NOPHYSICS, iter, 0, 0
              fzxSetBody cFZX_PARAMETER_COLOR, iter, _RGB32(0, 255, 255), 0
              released = released + 1
            END IF
          END IF
        END IF
      iter = iter - 1: LOOP UNTIL iter < 0

    END IF
    releaseCount = releaseCount + 1
  END IF
  IF done THEN LOCATE 20, 60: PRINT "Done!"


  fzxSetBody cFZX_PARAMETER_POSITION, mixer, __fzxWorld.spawn.x, __fzxWorld.spawn.y - 5000
  fzxSetBody cFZX_PARAMETER_TORQUE, mixer, 10000, 0
  fzxSetBody cFZX_PARAMETER_ANGULARVELOCITY, mixer, fzxImpulseClamp(0, 1, __fzxBody(mixer).fzx.angularVelocity), 0

END SUB

'********************************************************
'   Build you world here
'********************************************************

SUB buildScene
  DIM AS LONG temp, pegCount

  'Initialize camera
  __fzxCamera.zoom = .125
  fzxCalculateFOV

  '********************************************************
  '   Setup World
  '********************************************************

  fzxVector2DSet __fzxWorld.minusLimit, -200000, -200000
  fzxVector2DSet __fzxWorld.plusLimit, 200000, 200000
  fzxVector2DSet __fzxWorld.spawn, 0, 0
  fzxVector2DSet __fzxWorld.gravity, 0.0, 100.0

  ' Set camera position
  fzxVector2DSet __fzxCamera.position, __fzxWorld.spawn.x, __fzxWorld.spawn.y - 3000

  ' Some math used on the impulse side
  ' Todo: move this elsewhere
  DIM o AS tFZX_VECTOR2d
  fzxVector2DMultiplyScalarND o, __fzxWorld.gravity, dt
  __fzxWorld.resting = fzxVector2DLengthSq(o) + cFZX_EPSILON

  '********************************************************
  '   Build Level
  '********************************************************

  temp = fzxCreateBoxBodyEx("floor", 400, 100)
  fzxSetBody cFZX_PARAMETER_POSITION, temp, __fzxWorld.spawn.x, __fzxWorld.spawn.y
  fzxSetBody cFZX_PARAMETER_STATIC, temp, 0, 0

  temp = fzxCreateBoxBodyEx("wall1", 100, 3000)
  fzxSetBody cFZX_PARAMETER_POSITION, temp, __fzxWorld.spawn.x - 400, __fzxWorld.spawn.y - 3000
  fzxSetBody cFZX_PARAMETER_STATIC, temp, 0, 0

  temp = fzxCreateBoxBodyEx("wall2", 100, 3000)
  fzxSetBody cFZX_PARAMETER_POSITION, temp, __fzxWorld.spawn.x + 400, __fzxWorld.spawn.y - 3000
  fzxSetBody cFZX_PARAMETER_STATIC, temp, 0, 0

  temp = fzxCreateTrapBodyEx("funnel1", 300, 100, 0, 180)
  fzxSetBody cFZX_PARAMETER_POSITION, temp, __fzxWorld.spawn.x + 360, __fzxWorld.spawn.y - 2200
  fzxSetBody cFZX_PARAMETER_STATIC, temp, 0, 0
  fzxSetBody cFZX_PARAMETER_ORIENT, temp, _D2R(-90), 0

  temp = fzxCreateTrapBodyEx("funnel2", 300, 100, 180, 0)
  fzxSetBody cFZX_PARAMETER_POSITION, temp, __fzxWorld.spawn.x - 360, __fzxWorld.spawn.y - 2200
  fzxSetBody cFZX_PARAMETER_STATIC, temp, 0, 0
  fzxSetBody cFZX_PARAMETER_ORIENT, temp, _D2R(90), 0

  temp = fzxCreateTrapBodyEx("funnel3", 300, 100, 0, 180)
  fzxSetBody cFZX_PARAMETER_POSITION, temp, __fzxWorld.spawn.x + 360, __fzxWorld.spawn.y - 3600
  fzxSetBody cFZX_PARAMETER_STATIC, temp, 0, 0
  fzxSetBody cFZX_PARAMETER_ORIENT, temp, _D2R(-90), 0

  temp = fzxCreateTrapBodyEx("funnel4", 300, 100, 180, 0)
  fzxSetBody cFZX_PARAMETER_POSITION, temp, __fzxWorld.spawn.x - 360, __fzxWorld.spawn.y - 3600
  fzxSetBody cFZX_PARAMETER_STATIC, temp, 0, 0
  fzxSetBody cFZX_PARAMETER_ORIENT, temp, _D2R(90), 0

  mixer = fzxCreateBoxBodyEx("mixer", 20, 250)


  ' Make Pegs

  pegCount = 24

  ballArray "s", pegCount, 12, 20, __fzxWorld.spawn.x + 20, __fzxWorld.spawn.y - 3000, 540
  temp = 0: DO WHILE temp < pegCount
    fzxSetBodyEx cFZX_PARAMETER_STATIC, "s" + _TRIM$(STR$(temp)), 0, 0
    fzxSetBodyEx cFZX_PARAMETER_COLOR, "s" + _TRIM$(STR$(temp)), _RGB32(0, 255, 0), 0
    fzxSetBodyEx cFZX_PARAMETER_RESTITUTION, "s" + _TRIM$(STR$(temp)), .20, 0 ' Bounce
  temp = temp + 1: LOOP

  ballArray "sm", pegCount, 12, 20, __fzxWorld.spawn.x + 20, __fzxWorld.spawn.y - 4500, 540
  temp = 0: DO WHILE temp < pegCount
    fzxSetBodyEx cFZX_PARAMETER_STATIC, "sm" + _TRIM$(STR$(temp)), 0, 0
    fzxSetBodyEx cFZX_PARAMETER_COLOR, "sm" + _TRIM$(STR$(temp)), _RGB32(0, 255, 0), 0
    fzxSetBodyEx cFZX_PARAMETER_RESTITUTION, "sm" + _TRIM$(STR$(temp)), .20, 0 ' Bounce
  temp = temp + 1: LOOP


  ballCount = 700

  ballArray "b", ballCount, 20, 5, __fzxWorld.spawn.x, __fzxWorld.spawn.y - 8500, 500
  temp = 0: DO WHILE temp < ballCount
    fzxSetBodyEx cFZX_PARAMETER_NOPHYSICS, "b" + _TRIM$(STR$(temp)), 1, 0
    ' fzxSetBodyEx cFZX_PARAMETER_COLOR, "b" + _TRIM$(STR$(temp)), _RGB32(0, 255, 0), 0
  temp = temp + 1: LOOP


END SUB

SUB ballArray (id AS STRING, ballCount AS LONG, ballRadius AS DOUBLE, airgap AS DOUBLE, xp AS DOUBLE, yp AS DOUBLE, maxwidth AS LONG)
  DIM AS LONG temp, iter
  DIM AS DOUBLE xc, yc
  DIM AS DOUBLE ballsPerRow, ballDiameter, rowCount, columnCount, oddRow
  ballDiameter = (ballRadius + airgap) * 2
  ballsPerRow = INT(maxwidth / (ballDiameter + airgap))
  iter = 0: DO WHILE iter < ballCount
    temp = fzxCreateCircleBodyEx(id + _TRIM$(STR$(iter)), ballRadius)
    ' Set the bodies parameters
    columnCount = (iter MOD ballsPerRow)
    rowCount = INT(iter / ballsPerRow)
    oddRow = rowCount MOD 2
    xc = columnCount * (ballDiameter + airgap) + xp - (maxwidth * .5) + ((ballRadius + airgap) * oddRow * 1.4)
    yc = rowCount * ((ballDiameter + airgap) * .707) + yp
    fzxSetBody cFZX_PARAMETER_POSITION, temp, xc, yc
    fzxSetBody cFZX_PARAMETER_VELOCITY, temp, 0, 100
    ' Set the bouncyness
    fzxSetBody cFZX_PARAMETER_RESTITUTION, temp, .5, 0 ' Bounce
    ' Set the friction values of the body
    fzxSetBody cFZX_PARAMETER_STATICFRICTION, temp, .8, 0
    fzxSetBody cFZX_PARAMETER_DYNAMICFRICTION, temp, .25, 0
  iter = iter + 1: LOOP

END SUB

SUB buildImg (img AS LONG)
  _PRINTMODE _KEEPBACKGROUND
  _DEST img
  LINE (0, 0)-(14, 45), _RGB32(17, 0, 128), BF
  COLOR _RGB32(233, 227, 0), _RGB32(17, 0, 128)
  _PRINTSTRING (4, 6), "Q"
  _PRINTSTRING (4, 22), "B"
  LINE (0, 0)-(14, 45), _RGB32(255, 249, 39), B
  _DEST 0
END SUB


SUB renderBodies STATIC
  DIM skipCount AS LONG
  DIM i AS LONG

  DIM AS LONG ub: ub = UBOUND(__fzxBody)

  skipCount = skipCount + 1
  IF skipCount MOD 2 = 0 THEN ' Dont render every frame
    CLS
    'Draw all of the bodies that are visible
    i = 0: DO WHILE i < ub
      IF __fzxBody(i).enable THEN
        IF __fzxBody(i).shape.ty = cFZX_SHAPE_CIRCLE THEN
          renderWireFrameCircle i, __fzxBody(i).c
        ELSE IF __fzxBody(i).shape.ty = cFZX_SHAPE_POLYGON THEN
            renderWireFramePoly i, __fzxBody(i).c
          END IF
        END IF
      END IF
      i = i + 1
    LOOP
  END IF

  ' _PUTIMAGE (0, 0)-(15, 46), img, 0
END SUB

SUB renderWireFrameCircle (index AS LONG, c AS LONG)
  DIM AS tFZX_VECTOR2d o1, o2
  fzxWorldToCameraEx __fzxBody(index).fzx.position, o1
  CIRCLE (o1.x, o1.y), __fzxBody(index).shape.radius * __fzxCamera.zoom, c
  o2.x = o1.x + (__fzxBody(index).shape.radius * __fzxCamera.zoom) * COS(__fzxBody(index).fzx.orient)
  o2.y = o1.y + (__fzxBody(index).shape.radius * __fzxCamera.zoom) * SIN(__fzxBody(index).fzx.orient)
  LINE (o1.x, o1.y)-(o2.x, o2.y), c
END SUB

SUB renderWireFramePoly (index AS LONG, c AS LONG)
  DIM vert(3) AS tFZX_VECTOR2d

  fzxGetBodyVert index, 0, vert(0)
  fzxWorldToCamera index, vert(0)

  fzxGetBodyVert index, 1, vert(1)
  fzxWorldToCamera index, vert(1)

  fzxGetBodyVert index, 2, vert(2)
  fzxWorldToCamera index, vert(2)

  fzxGetBodyVert index, 3, vert(3)
  fzxWorldToCamera index, vert(3)

  LINE (vert(0).x, vert(0).y)-(vert(1).x, vert(1).y), c
  LINE (vert(1).x, vert(1).y)-(vert(2).x, vert(2).y), c
  LINE (vert(2).x, vert(2).y)-(vert(3).x, vert(3).y), c
  LINE (vert(3).x, vert(3).y)-(vert(0).x, vert(0).y), c
END SUB



