'**********************************************************************************************
'   fzxSoftBody
'**********************************************************************************************

'$DYNAMIC
OPTION _EXPLICIT
_TITLE "fzxNGN Softbody"

' Initialize FZXNGN types, globals and constants
'$include:'..\fzxNGN_BASE_v2\fzxNGN_ini.bas'

SCREEN _NEWIMAGE(1024, 768, 32)

'DIM AS LONG iterations: iterations = 100
'DIM SHARED AS DOUBLE dt: dt = 1 / 60


DIM SHARED AS LONG softbodyX, softbodyY
DIM SHARED AS LONG nodeSize, nodeCB, nodeXB, nodeYB, nodeXYB
DIM SHARED AS LONG softbodySizeX, softbodySizeY, softbodySpacing
DIM SHARED AS DOUBLE sf, bias, maxBias

nodeSize = 10
softbodySizeX = 5
softbodySizeY = 5
softbodySpacing = 40

sf = 0.007
bias = 100
maxBias = -1

'**********************************************************************************************
' Build the playfield
'**********************************************************************************************

buildScene

'**********************************************************************************************
' This is the main loop
'**********************************************************************************************

DO
  CLS , _RGB32(64, 64, 64)
  LOCATE 1: PRINT "Move the MASHER around with mouse to distort the Softbody."
  LOCATE 2: PRINT "Use UP and DOWN arrow keys to adjust the bias on Softbody."
  LOCATE 2, 80: PRINT "Bias:"; bias

  fzxHandleInputDevice
  animatescene
  fzxImpulseStep
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

  temp = fzxBodyManagerID("masher")
  fzxSetBody cFZX_PARAMETER_POSITION, temp, __fzxInputDevice.mouse.worldPosition.x, __fzxInputDevice.mouse.worldPosition.y

  IF _KEYDOWN(18432) THEN ' arrow up
    bias = bias + 10
    setAllJoinstBias bias
  END IF
  IF _KEYDOWN(20480) THEN ' arrow down
    bias = bias - 10
    setAllJoinstBias bias
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
  fzxVector2DSet __fzxWorld.spawn, 10000, 10000
  fzxVector2DSet __fzxWorld.gravity, 0.0, 1000.0
  DIM o AS tFZX_VECTOR2d
  fzxVector2DMultiplyScalarND o, __fzxWorld.gravity, __fzxWorld.deltaTime
  __fzxWorld.resting = fzxVector2DLengthSq(o) + cFZX_EPSILON

  ' Set camera position
  fzxVector2DSet __fzxCamera.position, __fzxWorld.spawn.x + 50, __fzxWorld.spawn.y + 200

  '********************************************************
  '   Build Level
  '********************************************************

  ' Create a grid of nodes. The nodes are simply circles that are used to attach the joints together.
  ' The collision mask is set to zero so that the circles will not collide with each other.
  ' The nodes on the left side are set to static.

  FOR softbodyY = 0 TO softbodySizeY
    FOR softbodyX = 0 TO softbodySizeX
      temp = fzxCreateCircleBodyEx("node_" + _TRIM$(STR$(softbodyX)) + "_" + _TRIM$(STR$(softbodyY)), nodeSize)
      fzxSetBody cFZX_PARAMETER_POSITION, temp, __fzxWorld.spawn.x + (softbodyX * softbodySpacing), __fzxWorld.spawn.y + (softbodyY * softbodySpacing)
    NEXT
  NEXT

  ' Build a mesh of joints between the nodes.
  ' The bodies are designated by Fig. 1
  '
  '   nodeCB  nodeXB
  '       O-----O
  '       |\   /|
  '       | \ / |
  '       |  X  |
  '       | / \ |
  '       |/   \|
  '       O-----O
  '   nodeYB  nodeXYB
  '       Fig. 1
  '
  ' The bias values were tweaked a bit depending on how they were oriented,
  ' you play with those values to get a desired effect

  FOR softbodyY = 0 TO softbodySizeY
    FOR softbodyX = 0 TO softbodySizeX
      nodeCB = nodeId(softbodyX, softbodyY)

      IF softbodyX < softbodySizeX THEN
        nodeXB = nodeId(softbodyX + 1, softbodyY)
        temp = fzxJointCreate(nodeCB, nodeXB, fzxGetBodyD(cFZX_PARAMETER_POSITION, nodeCB, cFZX_ARGUMENT_X), fzxGetBodyD(cFZX_PARAMETER_POSITION, nodeCB, cFZX_ARGUMENT_Y))
        __fzxJoints(temp).softness = sf
        __fzxJoints(temp).biasFactor = bias
        __fzxJoints(temp).max_bias = maxBias
        __fzxJoints(temp).render = 1
      END IF

      IF softbodyY < softbodySizeY THEN
        nodeYB = nodeId(softbodyX, softbodyY + 1)
        temp = fzxJointCreate(nodeCB, nodeYB, fzxGetBodyD(cFZX_PARAMETER_POSITION, nodeCB, cFZX_ARGUMENT_X), fzxGetBodyD(cFZX_PARAMETER_POSITION, nodeCB, cFZX_ARGUMENT_Y))
        __fzxJoints(temp).softness = sf
        __fzxJoints(temp).biasFactor = bias
        __fzxJoints(temp).max_bias = maxBias
        __fzxJoints(temp).render = 1
      END IF

      IF softbodyX < softbodySizeX AND softbodyY < softbodySizeY THEN
        nodeXYB = nodeId(softbodyX + 1, softbodyY + 1)
        temp = fzxJointCreate(nodeCB, nodeXYB, fzxGetBodyD(cFZX_PARAMETER_POSITION, nodeCB, cFZX_ARGUMENT_X), fzxGetBodyD(cFZX_PARAMETER_POSITION, nodeCB, cFZX_ARGUMENT_Y))
        __fzxJoints(temp).softness = sf
        __fzxJoints(temp).biasFactor = bias
        __fzxJoints(temp).max_bias = maxBias
        __fzxJoints(temp).render = 1

        temp = fzxJointCreate(nodeXB, nodeYB, fzxGetBodyD(cFZX_PARAMETER_POSITION, nodeXB, cFZX_ARGUMENT_X), fzxGetBodyD(cFZX_PARAMETER_POSITION, nodeXB, cFZX_ARGUMENT_Y))
        __fzxJoints(temp).softness = sf
        __fzxJoints(temp).biasFactor = bias
        __fzxJoints(temp).max_bias = maxBias
        __fzxJoints(temp).render = 1
      END IF

    NEXT
  NEXT

  temp = fzxCreateBoxBodyEx("floor", 800, 100)
  fzxSetBody cFZX_PARAMETER_POSITION, temp, __fzxWorld.spawn.x, __fzxWorld.spawn.y + 600
  fzxSetBody cFZX_PARAMETER_STATIC, temp, 0, 0

  temp = fzxCreateBoxBodyEx("wall1", 40, 300)
  fzxSetBody cFZX_PARAMETER_POSITION, temp, __fzxWorld.spawn.x + 400, __fzxWorld.spawn.y + 200
  fzxSetBody cFZX_PARAMETER_STATIC, temp, 0, 0

  temp = fzxCreateBoxBodyEx("wall2", 40, 300)
  fzxSetBody cFZX_PARAMETER_POSITION, temp, __fzxWorld.spawn.x - 400, __fzxWorld.spawn.y + 200
  fzxSetBody cFZX_PARAMETER_STATIC, temp, 0, 0


  temp = fzxCreateBoxBodyEx("masher", 150, 40)
  fzxSetBody cFZX_PARAMETER_POSITION, temp, __fzxWorld.spawn.x, __fzxWorld.spawn.y
  fzxSetBody cFZX_PARAMETER_STATIC, temp, 0, 0
END SUB

SUB setAllJoinstBias (bias AS DOUBLE)
  ' get really unstable outside these values
  ' negative numbers don't really make sense, but they have an interesting effect
  IF bias < -10 THEN bias = -10
  IF bias > 5000 THEN bias = 5000

  DIM AS LONG iter
  iter = 1: DO WHILE iter < UBOUND(__fzxJoints)
    __fzxJoints(iter).biasFactor = bias
  iter = iter + 1: LOOP
END SUB

FUNCTION nodeId& (x AS LONG, y AS LONG)
  nodeId = fzxBodyManagerID("node_" + _TRIM$(STR$(x)) + "_" + _TRIM$(STR$(y)))
END FUNCTION

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

