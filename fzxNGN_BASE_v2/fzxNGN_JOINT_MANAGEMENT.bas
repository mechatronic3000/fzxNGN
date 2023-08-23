'$include:'fzxNGN_ini.bas'
'$include:'fzxNGN_HASH.bas'
'$include:'fzxNGN_VECMATH.bas'
'$include:'fzxNGN_MATRIXMATH.bas'

$IF FZXJOINTMGMTINCLUDE = UNDEFINED THEN
  $LET FZXJOINTMGMTINCLUDE = TRUE
  FUNCTION fzxJointAllocate
    DIM AS LONG iter, uB, uBTemp
    ' Set uB to -1 to signal if the following code is unsuccessful at find
    ' an available joint to overwrite then allocate more space
    uB = -1

    iter = 0: DO WHILE iter <= UBOUND(__fzxJoints)
      IF __fzxJoints(iter).overwrite = 1 THEN
        fzxJointAllocate = iter
        EXIT FUNCTION
      END IF
    iter = iter + 1: LOOP

    ' If uB is still -1 then we need to allocate more array space
    ' If uB >= 0 then it found an element to overwrite and returns this value.
    IF uB < 0 THEN
      ' uBTemp should be the next element in the newly allocated array
      uBTemp = UBOUND(__fzxJoints) + 1
      ' Add 10 more elements to the __fzxJoints array, while preserving the contents
      REDIM _PRESERVE __fzxJoints(0 TO UBOUND(__fzxJoints) + 10) AS tFZX_JOINT
      ' uB is the size of the newly expanded array
      uB = UBOUND(__fzxJoints)
      ' Mark all of the newly created elements to be overwritten
      iter = uBTemp: DO WHILE iter <= uB
        __fzxJoints(iter).overwrite = 1
      iter = iter + 1: LOOP
      ' Set uB to then first element available in the newly expanded array.
      uB = uBTemp
    END IF
    fzxJointAllocate = uB
  END FUNCTION

  FUNCTION fzxJointCreate (b1 AS LONG, b2 AS LONG, x AS DOUBLE, y AS DOUBLE)
    IF b1 < 0 OR b1 > UBOUND(__fzxBody) OR b2 < 0 OR b2 > UBOUND(__fzxBody) THEN EXIT FUNCTION
    DIM AS LONG tempJ: tempJ = fzxJointAllocate

    fzxJointSet tempJ, b1, b2, x, y
    'Joint name will default to a combination of the two objects that is connects.
    'If you change it you must also recompute the hash.
    __fzxJoints(tempJ).jointName = _TRIM$(__fzxBody(b1).objectName) + "_" + _TRIM$(__fzxBody(b2).objectName)
    __fzxJoints(tempJ).jointHash = fzxComputeHash&&(__fzxJoints(tempJ).jointName)
    __fzxJoints(tempJ).wireframe_color = _RGB32(255, 227, 127)
    fzxJointCreate = tempJ
  END FUNCTION

  FUNCTION fzxJointCreateEx (b1 AS LONG, b2 AS LONG, anchor1 AS tFZX_VECTOR2d, anchor2 AS tFZX_VECTOR2d)
    IF b1 < 0 OR b1 > UBOUND(__fzxBody) OR b2 < 0 OR b2 > UBOUND(__fzxBody) THEN EXIT FUNCTION
    DIM AS LONG tempJ: tempJ = fzxJointAllocate

    fzxJointSetEx tempJ, b1, b2, anchor1, anchor2
    'Joint name will default to a combination of the two objects that is connects.
    'If you change it you must also recompute the hash.
    __fzxJoints(tempJ).jointName = _TRIM$(__fzxBody(b1).objectName) + "_" + _TRIM$(__fzxBody(b2).objectName)
    __fzxJoints(tempJ).jointHash = fzxComputeHash&&(__fzxJoints(tempJ).jointName)
    __fzxJoints(tempJ).wireframe_color = _RGB32(255, 227, 127)
    fzxJointCreateEx = tempJ
  END FUNCTION

  SUB fzxJointClear
    DIM AS LONG iter
    iter = 0: DO WHILE iter <= UBOUND(__fzxJoints)
      fzxJointDelete iter
    iter = iter + 1: LOOP
  END SUB

  SUB fzxJointDelete (d AS LONG)
    IF d >= 0 AND d <= UBOUND(__fzxJoints) THEN
      __fzxJoints(d).overwrite = 1
      __fzxJoints(d).jointName = ""
      __fzxJoints(d).jointHash = 0
    END IF
  END SUB

  SUB fzxJointSet (index AS LONG, b1 AS LONG, b2 AS LONG, x AS DOUBLE, y AS DOUBLE)
    IF b1 < 0 OR b1 > UBOUND(__fzxBody) OR b2 < 0 OR b2 > UBOUND(__fzxBody) THEN EXIT SUB
    DIM anchor AS tFZX_VECTOR2d
    fzxVector2DSet anchor, x, y
    DIM Rot1 AS tFZX_MATRIX2D: Rot1 = __fzxBody(b1).shape.u
    DIM Rot2 AS tFZX_MATRIX2D: Rot2 = __fzxBody(b2).shape.u
    DIM Rot1T AS tFZX_MATRIX2D: fzxMatrix2x2Transpose Rot1, Rot1T
    DIM Rot2T AS tFZX_MATRIX2D: fzxMatrix2x2Transpose Rot2, Rot2T
    DIM tv AS tFZX_VECTOR2d

    __fzxJoints(index).body1 = b1
    __fzxJoints(index).body2 = b2

    fzxVector2DSubVectorND tv, anchor, __fzxBody(b1).fzx.position
    fzxMatrix2x2MultiplyVector Rot1T, tv, __fzxJoints(index).localAnchor1

    fzxVector2DSubVectorND tv, anchor, __fzxBody(b2).fzx.position
    fzxMatrix2x2MultiplyVector Rot2T, tv, __fzxJoints(index).localAnchor2

    fzxVector2DSet __fzxJoints(index).P, 0, 0
    ' Some default Settings
    __fzxJoints(index).softness = 0.001
    __fzxJoints(index).biasFactor = 1000
    __fzxJoints(index).max_bias = -1
    __fzxJoints(index).overwrite = 0
  END SUB

  SUB fzxJointSetEx (index AS LONG, b1 AS LONG, b2 AS LONG, anchor1 AS tFZX_VECTOR2d, anchor2 AS tFZX_VECTOR2d)
    IF b1 < 0 OR b1 > UBOUND(__fzxBody) OR b2 < 0 OR b2 > UBOUND(__fzxBody) THEN EXIT SUB
    DIM Rot1 AS tFZX_MATRIX2D: Rot1 = __fzxBody(b1).shape.u
    DIM Rot2 AS tFZX_MATRIX2D: Rot2 = __fzxBody(b2).shape.u
    DIM Rot1T AS tFZX_MATRIX2D: fzxMatrix2x2Transpose Rot1, Rot1T
    DIM Rot2T AS tFZX_MATRIX2D: fzxMatrix2x2Transpose Rot2, Rot2T
    DIM tv AS tFZX_VECTOR2d

    __fzxJoints(index).body1 = b1
    __fzxJoints(index).body2 = b2

    fzxVector2DSubVectorND tv, anchor1, __fzxBody(b1).fzx.position
    fzxMatrix2x2MultiplyVector Rot1T, tv, __fzxJoints(index).localAnchor1

    fzxVector2DSubVectorND tv, anchor2, __fzxBody(b2).fzx.position
    fzxMatrix2x2MultiplyVector Rot2T, tv, __fzxJoints(index).localAnchor2

    fzxVector2DSet __fzxJoints(index).P, 0, 0
    ' Some default Settings
    __fzxJoints(index).softness = 0.0001
    __fzxJoints(index).biasFactor = 1000
    __fzxJoints(index).max_bias = -1
    __fzxJoints(index).overwrite = 0
  END SUB

$END IF
