'**********************************************************************************************
'   fzxBareBones
'**********************************************************************************************

'$DYNAMIC
OPTION _EXPLICIT
_TITLE "fzxNGN Cloth"

' Initialize FZXNGN types, globals and constants
'$include:'..\fzxNGN_BASE_v2\fzxNGN_ini.bas'

SCREEN _NEWIMAGE(1024, 768, 32)

DIM AS LONG iterations: iterations = 100
DIM SHARED AS DOUBLE dt: dt = 1 / 60


DIM SHARED AS LONG flagX, flagY
DIM SHARED AS LONG nodeCB, nodeXB, nodeYB, nodeXYB
DIM SHARED AS LONG flagSizeX, flagSizeY, flagSpacing
DIM SHARED AS DOUBLE sf, bias

flagSizeX = 5
flagSizeY = 3
flagSpacing = 40

sf = 0.00007
bias = 2000


'**********************************************************************************************
' Build the playfield
'**********************************************************************************************

buildScene

'**********************************************************************************************
' This is the main loop
'**********************************************************************************************

DO
  CLS , _RGB32(64, 64, 64): LOCATE 1: PRINT "Move mouse around to distort the cloth"
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
  DIM AS LONG temp, iter

  FOR iter = 0 TO flagSizeY
    temp = fzxBodyManagerID("node_" + _TRIM$(STR$(0)) + "_" + _TRIM$(STR$(iter)))
    fzxSetBody cFZX_PARAMETER_POSITION, temp, __fzxInputDevice.mouse.worldPosition.x, __fzxInputDevice.mouse.worldPosition.y + (iter * flagSpacing)
  NEXT

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
  fzxVector2DSet __fzxWorld.spawn, 10000, 10000
  fzxVector2DSet __fzxWorld.gravity, 0.0, 0.0
  DIM o AS tFZX_VECTOR2d
  fzxVector2DMultiplyScalarND o, __fzxWorld.gravity, dt
  __fzxWorld.resting = fzxVector2DLengthSq(o) + cFZX_EPSILON


  ' Set camera position
  fzxVector2DSet __fzxCamera.position, __fzxWorld.spawn.x + 50, __fzxWorld.spawn.y + 200


  '********************************************************
  '   Build Level
  '********************************************************


  FOR flagY = 0 TO flagSizeY
    FOR flagX = 0 TO flagSizeX
      temp = fzxCreateCircleBodyEx("node_" + _TRIM$(STR$(flagX)) + "_" + _TRIM$(STR$(flagY)), 5)
      fzxSetBody cFZX_PARAMETER_POSITION, temp, __fzxWorld.spawn.x + (flagX * flagSpacing), __fzxWorld.spawn.y + (flagY * flagSpacing)
      fzxSetBody cFZX_PARAMETER_COLLISIONMASK, temp, 0, 0
      IF flagX = 0 THEN fzxSetBody cFZX_PARAMETER_STATIC, temp, 0, 0
    NEXT
  NEXT

  FOR flagY = 0 TO flagSizeY
    FOR flagX = 0 TO flagSizeX
      nodeCB = fzxBodyManagerID("node_" + _TRIM$(STR$(flagX)) + "_" + _TRIM$(STR$(flagY)))
      IF flagX < flagSizeX THEN nodeXB = fzxBodyManagerID("node_" + _TRIM$(STR$(flagX + 1)) + "_" + _TRIM$(STR$(flagY)))
      IF flagY < flagSizeY THEN nodeYB = fzxBodyManagerID("node_" + _TRIM$(STR$(flagX)) + "_" + _TRIM$(STR$(flagY + 1)))
      IF flagX < flagSizeX AND flagY < flagSizeY THEN nodeXYB = fzxBodyManagerID("node_" + _TRIM$(STR$(flagX + 1)) + "_" + _TRIM$(STR$(flagY + 1)))

      IF flagX < flagSizeX THEN
        temp = fzxJointCreate(nodeCB, nodeXB, fzxGetBodyD(cFZX_PARAMETER_POSITION, nodeCB, cFZX_ARGUMENT_X), fzxGetBodyD(cFZX_PARAMETER_POSITION, nodeCB, cFZX_ARGUMENT_Y))
        __fzxJoints(temp).softness = sf
        __fzxJoints(temp).biasFactor = bias / 5
        __fzxJoints(temp).render = 1
      END IF

      IF flagY < flagSizeY THEN
        temp = fzxJointCreate(nodeCB, nodeYB, fzxGetBodyD(cFZX_PARAMETER_POSITION, nodeCB, cFZX_ARGUMENT_X), fzxGetBodyD(cFZX_PARAMETER_POSITION, nodeCB, cFZX_ARGUMENT_Y))
        __fzxJoints(temp).softness = sf
        __fzxJoints(temp).biasFactor = bias
        __fzxJoints(temp).render = 1
      END IF

      IF flagX < flagSizeX AND flagY < flagSizeY THEN
        temp = fzxJointCreate(nodeCB, nodeXYB, fzxGetBodyD(cFZX_PARAMETER_POSITION, nodeCB, cFZX_ARGUMENT_X), fzxGetBodyD(cFZX_PARAMETER_POSITION, nodeCB, cFZX_ARGUMENT_Y))
        __fzxJoints(temp).softness = sf
        __fzxJoints(temp).biasFactor = bias / 10
        __fzxJoints(temp).render = 1
      END IF

      IF flagX < flagSizeX AND flagY < flagSizeY THEN
        temp = fzxJointCreate(nodeXB, nodeYB, fzxGetBodyD(cFZX_PARAMETER_POSITION, nodeXB, cFZX_ARGUMENT_X), fzxGetBodyD(cFZX_PARAMETER_POSITION, nodeXB, cFZX_ARGUMENT_Y))
        __fzxJoints(temp).softness = sf
        __fzxJoints(temp).biasFactor = bias / 10
        __fzxJoints(temp).render = 1
      END IF

    NEXT
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
  i = 0: DO WHILE i <= uJ
    IF __fzxJoints(i).render = 1 THEN renderJoints i
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


FUNCTION createImg (w AS LONG, h AS LONG)
  DIM AS LONG sc
  sc = _NEWIMAGE(w, h, 32)
  _DEST sc
  CLS , _RGB32(0, 0, 192)
  PSET (w / 2, h / 2), _RGB32(255, 216, 0)




  _DEST 0
END FUNCTION



