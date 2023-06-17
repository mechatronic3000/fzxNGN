'$include:'fzxNGN_ini.bas'
'$include:'fzxNGN_MEM.bas'
'$include:'fzxNGN_VECMATH.bas'
'$include:'fzxNGN_MATRIXMATH.bas'
$IF FZXPOLYGONINCLUDE = UNDEFINED THEN
  $LET FZXPOLYGONINCLUDE = TRUE
  '**********************************************************************************************
  '   Polygon Helper
  '**********************************************************************************************

  SUB _______________POLYGON_HELPER_FUNCTIONS (): END SUB

  SUB fzxPolygonMakeCCW (obj AS tFZX_TRIANGLE)
    IF fzxVector2DLeft(obj.a, obj.b, obj.c) = 0 THEN
      SWAP obj.a, obj.c
    END IF
  END SUB

  FUNCTION fzxPolygonIsReflex (t AS tFZX_TRIANGLE)
    fzxPolygonIsReflex = fzxVector2DRight(t.a, t.b, t.c)
  END FUNCTION

  SUB fzxPolygonSetOrient (index AS LONG, radians AS DOUBLE)
    fzxMatrix2x2SetRadians __fzxBody(index).shape.u, radians
  END SUB

  SUB fzxPolygonInvertNormals (index AS LONG)
    DIM AS LONG i
    DIM AS tFZX_VECTOR2d v
    FOR i = 0 TO __fzxBody(index).pa.count
      fzxGetBodyNorm index, i, v
      fzxVector2dNeg v
      fzxSetBodyNorm index, i, v

      'fzxVector2dNeg __fzxPoly(__fzxBody(index).pa.start + i).norm

    NEXT
  END SUB
$END IF
