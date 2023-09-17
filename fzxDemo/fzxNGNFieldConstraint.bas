'**********************************************************************************************
'   fzx Field Constraint
'**********************************************************************************************



_TITLE "fzxNGN Field Constraint"

' Initialize FZXNGN types, globals and constants
'$include:'..\fzxNGN_BASE_v2\fzxNGN_ini.bas'
fzxInitFPS
SCREEN _NEWIMAGE(1024, 768, 32)


TYPE vectorField
  v AS tFZX_VECTOR2d 'force vector
  f AS DOUBLE 'friction
END TYPE
TYPE vectorFieldParams
  scale AS tFZX_VECTOR2d ' Vector field scale over playfield
  offset AS tFZX_VECTOR2d ' Vector offsets over playfield
  str AS DOUBLE ' strength of the vectors. Can be negative
END TYPE

DIM SHARED AS STRING constraintFile
DIM SHARED AS LONG img
DIM SHARED AS vectorField vf(0, 0)
DIM SHARED AS vectorFieldParams vp
DIM SHARED AS _BYTE displayMode




'**********************************************************************************************
' Build the playfield
'**********************************************************************************************

buildScene

'**********************************************************************************************
' This is the main loop
'**********************************************************************************************

DO

  fzxHandleInputDevice
  animatescene
  applyVectorField
  fzxImpulseStep
  renderBodies
  fzxHandleFPSMain
  _LIMIT 60
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
      temp = fzxCreateCircleBodyEx("b" + _TRIM$(STR$(RND * 1000000000)), 10 + RND * 10)
    ELSE
      temp = fzxCreatePolyBodyEx("b" + _TRIM$(STR$(RND * 1000000000)), 10 + RND * 10, 10 + RND * 10, 3 + INT(RND * 5))
    END IF
    ' Set the bodies parameters
    ' Put the body where the mouse is on the screen
    fzxSetBody cFZX_PARAMETER_POSITION, temp, __fzxInputDevice.mouse.worldPosition.x, __fzxInputDevice.mouse.worldPosition.y
    ' Give it the mouse's velocity, so you can throw it
    fzxSetBody cFZX_PARAMETER_VELOCITY, temp, __fzxInputDevice.mouse.velocity.x * 10, __fzxInputDevice.mouse.velocity.y * 10
    ' Change its orientation or angle
    fzxSetBody cFZX_PARAMETER_ORIENT, temp, _D2R(RND * 360), 0
    ' Set the bouncyness
    fzxSetBody cFZX_PARAMETER_RESTITUTION, temp, .3, 0 ' Bounce
    ' Set the friction values of the body
    fzxSetBody cFZX_PARAMETER_STATICFRICTION, temp, .9, 0
    fzxSetBody cFZX_PARAMETER_DYNAMICFRICTION, temp, .25, 0
    ' Bodies wont live forever
    ' fzxSetBody cFZX_PARAMETER_LIFETIME, temp, RND * 20 + 10, 0
    ' Set the color
    fzxSetBody cFZX_PARAMETER_COLOR, temp, _RGB32(RND * 200, RND * 200, RND * 200), 0

  END IF
  IF __fzxInputDevice.mouse.b2.NegEdge THEN
    displayMode = displayMode + 1
    IF displayMode > 2 THEN displayMode = 0
  END IF

END SUB

'********************************************************
'   Build you world here
'********************************************************

SUB buildScene

  'constraintFile = _OPENFILEDIALOG$("Open Constraint Image", _CWD$, "*.png|*.bmp|*.jpg", "Image Files", 0)
  constraintFile = _CWD$ + "/Assets/constraint8.png"
  IF _FILEEXISTS(constraintFile) THEN
    img = _LOADIMAGE(constraintFile)
  ELSE
    END
  END IF

  buildVectorField vf(), img
  vp.scale.x = _WIDTH(0) / _WIDTH(img)
  vp.scale.y = _HEIGHT(0) / _HEIGHT(img)
  vp.offset.x = -(_WIDTH(0)) / 2
  vp.offset.y = -(_HEIGHT(0)) / 2 - 300
  vp.str = 1000

  'Initialize camera
  __fzxCamera.zoom = 1
  fzxCalculateFOV

  '********************************************************
  '   Setup World
  '********************************************************
  fzxVector2DSet __fzxWorld.gravity, 0.0, 9.8

  ' Some math used on the impulse side
  ' Todo: move this elsewhere
  DIM o AS tFZX_VECTOR2d
  fzxVector2DMultiplyScalarND o, __fzxWorld.gravity, __fzxWorld.deltaTime
  __fzxWorld.resting = fzxVector2DLengthSq(o) + cFZX_EPSILON


  ' Set camera position
  fzxVector2DSet __fzxCamera.position, __fzxWorld.spawn.x, __fzxWorld.spawn.y - 300


  '********************************************************
  '   Build Level
  '********************************************************


END SUB

SUB renderBodies STATIC
  DIM i AS LONG
  DIM AS tFZX_VECTOR2d ov
  DIM AS DOUBLE fric
  DIM AS LONG ub: ub = UBOUND(__fzxBody)
  CLS
  ' _PUTIMAGE (vp.offset.x, vp.offset.y)-(_WIDTH(img), _HEIGHT(img)), img, 0,

  IF displayMode = 0 THEN
    _PUTIMAGE , img, 0, ' display vector field source image
  ELSE IF displayMode = 1 THEN
      renderVectorField vf(), vp ' diplay vector field
    END IF
  END IF

  LOCATE 1, 10: PRINT "Click the mouse on the playfield to spawn an object"
  LOCATE 1, 1: PRINT USING "FPS:###"; __fzxStats.fps
  LOCATE 2, 10: PRINT "Throw objects by moving the mouse and releasing the left mose button"
  LOCATE 3, 10: PRINT "Right click to switch vector viewing mode."
  LOCATE 4, 10: PRINT USING "Number of objects:####"; __fzxStats.numberOfBodies

  playField2VectorField vf(), vp, __fzxInputDevice.mouse.worldPosition, ov, fric


  'LINE (__fzxInputDevice.mouse.position.x, __fzxInputDevice.mouse.position.y)-(__fzxInputDevice.mouse.position.x + ov.x, __fzxInputDevice.mouse.position.y + ov.y), _RGB32(0, 255, 0)
  'Draw all of the bodies that are visible
  i = 0: DO WHILE i < ub
    IF __fzxBody(i).enable AND __fzxBody(i).objectHash <> 0 THEN
      IF __fzxBody(i).shape.ty = cFZX_SHAPE_CIRCLE THEN
        renderWireFrameCircle i
      ELSE IF __fzxBody(i).shape.ty = cFZX_SHAPE_POLYGON THEN
          renderWireFramePoly i
        END IF
      END IF
    END IF
    i = i + 1
  LOOP
END SUB

SUB renderWireFrameCircle (index AS LONG)
  DIM AS tFZX_VECTOR2d o1, o2
  fzxWorldToCameraEx __fzxBody(index).fzx.position, o1
  CIRCLE (o1.x, o1.y), __fzxBody(index).shape.radius * __fzxCamera.zoom, __fzxBody(index).c
  o2.x = o1.x + (__fzxBody(index).shape.radius * __fzxCamera.zoom) * COS(__fzxBody(index).fzx.orient)
  o2.y = o1.y + (__fzxBody(index).shape.radius * __fzxCamera.zoom) * SIN(__fzxBody(index).fzx.orient)
  LINE (o1.x, o1.y)-(o2.x, o2.y), __fzxBody(index).c
END SUB

SUB renderWireFramePoly (index AS LONG)
  DIM AS LONG polyCount, i
  polyCount = fzxGetBodyD(CFZX_PARAMETER_POLYCOUNT, index, 0)
  DIM AS tFZX_VECTOR2d vert1, vert2
  i = 0: DO WHILE i <= polyCount
    fzxGetBodyVert index, i, vert1
    fzxGetBodyVert index, fzxArrayNextIndex(i, polyCount), vert2

    fzxWorldToCamera index, vert1
    fzxWorldToCamera index, vert2
    LINE (vert1.x, vert1.y)-(vert2.x, vert2.y), __fzxBody(index).c
  i = i + 1: LOOP
END SUB
'***********************************************************************************************
' Vectorfield
'***********************************************************************************************
SUB applyVectorField

  DIM i AS LONG

  DIM AS LONG ub: ub = UBOUND(__fzxBody)
  DIM AS tFZX_VECTOR2d vo
  DIM AS DOUBLE fric

  i = 0: DO WHILE i < ub
    IF __fzxBody(i).enable AND __fzxBody(i).objectHash <> 0 THEN
      playField2VectorField vf(), vp, __fzxBody(i).fzx.position, vo, fric
      __fzxBody(i).fzx.force.x = __fzxBody(i).fzx.force.x + (vo.x * __fzxWorld.deltaTime)
      __fzxBody(i).fzx.force.y = __fzxBody(i).fzx.force.y + (vo.y * __fzxWorld.deltaTime)
      __fzxBody(i).fzx.velocity.x = __fzxBody(i).fzx.velocity.x * (1 - fric * __fzxWorld.deltaTime)
      __fzxBody(i).fzx.velocity.y = __fzxBody(i).fzx.velocity.y * (1 - fric * __fzxWorld.deltaTime)
      __fzxBody(i).fzx.angularVelocity = __fzxBody(i).fzx.angularVelocity * (1 - fric * __fzxWorld.deltaTime)
    END IF
    i = i + 1
  LOOP
END SUB


SUB buildVectorField (vf() AS vectorField, img AS LONG)
  DIM AS LONG i, j, ii, jj, pixel1, pixel2, pixDif

  _SOURCE img
  REDIM vf(_WIDTH(img), _HEIGHT(img)) AS vectorField
  FOR j = 1 TO _HEIGHT(img) - 1
    FOR i = 1 TO _WIDTH(img) - 1
      pixel1 = _RED(POINT(i, j))
      FOR jj = -1 TO 1
        FOR ii = -1 TO 1
          pixel2 = _RED(POINT(i + ii, j + jj))
          pixDif = pixel1 - pixel2
          vf(i, j).v.x = vf(i, j).v.x + (pixDif * ii)
          vf(i, j).v.y = vf(i, j).v.y + (pixDif * jj)
        NEXT
      NEXT
      normalize vf(i, j).v.x, vf(i, j).v.y, vf(i, j).v.x, vf(i, j).v.y
      vf(i, j).f = _BLUE(POINT(i, j)) / 255 'friction
    NEXT
  NEXT
  _SOURCE 0
END SUB

SUB playField2VectorField (vf() AS vectorField, vp AS vectorFieldParams, in AS tFZX_VECTOR2d, vo AS tFZX_VECTOR2d, vf AS DOUBLE)
  DIM AS tFZX_VECTOR2d vfp
  vfp.x = INT((in.x - vp.offset.x) / vp.scale.x)
  vfp.y = INT((in.y - vp.offset.y) / vp.scale.y)
  IF vfp.x >= 0 AND vfp.x <= UBOUND(vf, 1) AND vfp.y >= 0 AND vfp.y <= UBOUND(vf, 2) THEN
    vo.x = vf(vfp.x, vfp.y).v.x * vp.str
    vo.y = vf(vfp.x, vfp.y).v.y * vp.str
    vf = vf(vfp.x, vfp.y).f
  ELSE
    vo.x = 0
    vo.y = 0
  END IF
END SUB

SUB renderVectorField (vf() AS vectorField, vp AS vectorFieldParams)
  DIM AS tFZX_VECTOR2d v1, v2, o1, o2
  DIM AS LONG i, j
  FOR j = 0 TO _HEIGHT(img)
    FOR i = 0 TO _WIDTH(img)
      IF vf(i, j).v.x <> 0 OR vf(i, j).v.y <> 0 THEN
        v1.x = i * vp.scale.x + vp.offset.x
        v1.y = j * vp.scale.y + vp.offset.y
        fzxWorldToCameraEx v1, o1
        v2.x = v1.x + (vf(i, j).v.x * vp.scale.x)
        v2.y = v1.y + (vf(i, j).v.y * vp.scale.y)
        fzxWorldToCameraEx v2, o2
        LINE (o1.x, o1.y)-(o2.x, o2.y)
        PSET (o2.x, o2.y), _RGB32(0, 255, 0)
      END IF
    NEXT
  NEXT
END SUB

FUNCTION magnitude# (x AS DOUBLE, y AS DOUBLE)
  magnitude = SQR(x * x + y * y)
END FUNCTION

SUB normalize (x AS DOUBLE, y AS DOUBLE, xn AS DOUBLE, yn AS DOUBLE)
  DIM AS DOUBLE m: m = magnitude(x, y)
  IF m <> 0 THEN
    xn = x / m
    yn = y / m
  ELSE
    xn = 0
    yn = 0
  END IF
END SUB



