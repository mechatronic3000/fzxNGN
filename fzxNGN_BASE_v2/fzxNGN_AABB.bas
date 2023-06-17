'$include:'fzxNGN_ini.bas'
'$include:'fzxNGN_VECMATH.bas'
$IF FZXFZXAABBINCLUDE = UNDEFINED THEN
  $LET FZXFZXAABBINCLUDE = TRUE
  '**********************************************************************************************
  '   fzxAABB helper functions
  '**********************************************************************************************
  SUB _______________fzxAABB_HELPER_FUNCTIONS (): END SUB

  FUNCTION fzxAABBOverlap (Ax AS DOUBLE, Ay AS DOUBLE, Aw AS DOUBLE, Ah AS DOUBLE, Bx AS DOUBLE, By AS DOUBLE, Bw AS DOUBLE, Bh AS DOUBLE)
    fzxAABBOverlap = Ax < Bx + Bw AND Ax + Aw > Bx AND Ay < By + Bh AND Ay + Ah > By
  END FUNCTION

  FUNCTION fzxAABBOverlapVector (A AS tFZX_VECTOR2d, Aw AS DOUBLE, Ah AS DOUBLE, B AS tFZX_VECTOR2d, Bw AS DOUBLE, Bh AS DOUBLE)
    fzxAABBOverlapVector = fzxAABBOverlap(A.x, A.y, Aw, Ah, B.x, B.y, Bw, Bh)
  END FUNCTION

  FUNCTION fzxAABBOverlapObjects (a AS LONG, b AS LONG)
    DIM AS tFZX_VECTOR2d am, bm, mam, mbm
    fzxVector2DSubVectorND am, __fzxBody(a).fzx.position, __fzxBody(a).shape.maxDimension
    fzxVector2DSubVectorND bm, __fzxBody(b).fzx.position, __fzxBody(b).shape.maxDimension
    mam = __fzxBody(a).shape.maxDimension
    mbm = __fzxBody(b).shape.maxDimension
    fzxAABBOverlapObjects = fzxAABBOverlap(am.x, am.y, (mam.x * 2), (mam.y * 2), bm.x, bm.y, (mbm.x * 2), (mbm.y * 2))
  END FUNCTION

  'FUNCTION fzxAABBOverlapObjectCamera (body() AS tFZX_BODY, cam AS tFZX_CAMERA, a AS LONG)
  '  DIM AS tFZX_VECTOR2d winUpLeft
  '  fzxVector2DNegND winUpLeft, cam.fov

  'END FUNCTION
$END IF
