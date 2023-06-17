'$include:'fzxNGN_ini.bas'

$IF FZXMATRIXMATHINCLUDE = UNDEFINED THEN
  $LET FZXMATRIXMATHINCLUDE = TRUE
  '**********************************************************************************************
  '   Matrix Math Functions
  '**********************************************************************************************

  SUB _______________MATRIX_FUNCTIONS (): END SUB
  SUB fzxMatrix2x2SetRadians (m AS tFZX_MATRIX2D, radians AS DOUBLE)
    DIM c AS DOUBLE
    DIM s AS DOUBLE
    c = COS(radians)
    s = SIN(radians)
    m.m00 = c
    m.m01 = -s
    m.m10 = s
    m.m11 = c
  END SUB

  SUB fzxMatrix2x2SetScalar (m AS tFZX_MATRIX2D, a AS DOUBLE, b AS DOUBLE, c AS DOUBLE, d AS DOUBLE)
    m.m00 = a
    m.m01 = b
    m.m10 = c
    m.m11 = d
  END SUB

  SUB fzxMatrix2x2Abs (m AS tFZX_MATRIX2D, o AS tFZX_MATRIX2D)
    o.m00 = ABS(m.m00)
    o.m01 = ABS(m.m01)
    o.m10 = ABS(m.m10)
    o.m11 = ABS(m.m11)
  END SUB

  SUB fzxMatrix2x2GetAxisX (m AS tFZX_MATRIX2D, o AS tFZX_VECTOR2d)
    o.x = m.m00
    o.y = m.m10
  END SUB

  SUB fzxMatrix2x2GetAxisY (m AS tFZX_MATRIX2D, o AS tFZX_VECTOR2d)
    o.x = m.m01
    o.y = m.m11
  END SUB

  SUB fzxMatrix2x2TransposeI (m AS tFZX_MATRIX2D)
    SWAP m.m01, m.m10
  END SUB

  SUB fzxMatrix2x2Transpose (m AS tFZX_MATRIX2D, o AS tFZX_MATRIX2D)
    DIM tm AS tFZX_MATRIX2D
    tm.m00 = m.m00
    tm.m01 = m.m10
    tm.m10 = m.m01
    tm.m11 = m.m11
    o = tm
  END SUB

  SUB fzxMatrix2x2Invert (m AS tFZX_MATRIX2D, o AS tFZX_MATRIX2D)
    DIM a, b, c, d, det AS DOUBLE
    DIM tm AS tFZX_MATRIX2D

    a = m.m00: b = m.m01: c = m.m10: d = m.m11
    det = a * d - b * c
    IF det = 0 THEN EXIT SUB

    det = 1 / det
    tm.m00 = det * d: tm.m01 = -det * b
    tm.m10 = -det * c: tm.m11 = det * a
    o = tm
  END SUB

  SUB fzxMatrix2x2MultiplyVector (m AS tFZX_MATRIX2D, v AS tFZX_VECTOR2d, o AS tFZX_VECTOR2d)
    DIM t AS tFZX_VECTOR2d
    t.x = m.m00 * v.x + m.m01 * v.y
    t.y = m.m10 * v.x + m.m11 * v.y
    o = t
  END SUB

  SUB fzxMatrix2x2AddMatrix (m AS tFZX_MATRIX2D, x AS tFZX_MATRIX2D, o AS tFZX_MATRIX2D)
    o.m00 = m.m00 + x.m00
    o.m01 = m.m01 + x.m01
    o.m10 = m.m10 + x.m10
    o.m11 = m.m11 + x.m11
  END SUB

  SUB fzxMatrix2x2MultiplyMatrix (m AS tFZX_MATRIX2D, x AS tFZX_MATRIX2D, o AS tFZX_MATRIX2D)
    o.m00 = m.m00 * x.m00 + m.m01 * x.m10
    o.m01 = m.m00 * x.m01 + m.m01 * x.m11
    o.m10 = m.m10 * x.m00 + m.m11 * x.m10
    o.m11 = m.m10 * x.m01 + m.m11 * x.m11
  END SUB

$END IF
