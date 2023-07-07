'$include:'fzxNGN_ini.bas'
'$include:'fzxNGN_MEM.bas'
'$include:'fzxNGN_VECMATH.bas'
'$include:'fzxNGN_MATRIXMATH.bas'
'$include:'fzxNGN_IMPULSEMATH.bas'
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
    NEXT
  END SUB

  FUNCTION fzxPointInTriangle (a AS tFZX_VECTOR2d, b AS tFZX_VECTOR2d, c AS tFZX_VECTOR2d, p AS tFZX_VECTOR2d)
    DIM AS DOUBLE det, factor_alpha, factor_beta, alpha, beta, gamma
    det = (b.y - c.y) * (a.x - c.x) + (c.x - b.x) * (a.y - c.y)
    IF det = 0 THEN EXIT FUNCTION
    factor_alpha = (b.y - c.y) * (p.x - c.x) + (c.x - b.x) * (p.y - c.y)
    factor_beta = (c.y - a.y) * (p.x - c.x) + (a.x - c.x) * (p.y - c.y)
    alpha = factor_alpha / det
    beta = factor_beta / det
    gamma = 1.0 - alpha - beta

    fzxPointInTriangle = fzxVector2DEqual(p, a, 0) OR _
                         fzxVector2DEqual(p, b, 0) OR _
                         fzxVector2DEqual(p, c, 0) OR _
                         (fzxImpulseWithin(alpha, 0, 1) AND _
                          fzxImpulseWithin(beta, 0, 1) AND _
                          fzxImpulseWithin(gamma, 0, 1))
  END FUNCTION

$END IF
