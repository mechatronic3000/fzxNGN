'$include:'fzxNGN_ini.bas'
'
$IF FZXVECMATHINCLUDE = UNDEFINED THEN
  $LET FZXVECMATHINCLUDE = TRUE
  '**********************************************************************************************
  '   Vector Math Functions
  '**********************************************************************************************
  SUB _______________VECTOR_FUNCTIONS (): END SUB

  SUB fzxVector2DSet (v AS tFZX_VECTOR2d, x AS DOUBLE, y AS DOUBLE)
    v.x = x
    v.y = y
  END SUB

  SUB fzxVector2dSetVector (o AS tFZX_VECTOR2d, v AS tFZX_VECTOR2d)
    o.x = v.x
    o.y = v.y
  END SUB

  SUB fzxVector2dNeg (v AS tFZX_VECTOR2d)
    v.x = -v.x
    v.y = -v.y
  END SUB

  SUB fzxVector2DNegND (o AS tFZX_VECTOR2d, v AS tFZX_VECTOR2d)
    o.x = -v.x
    o.y = -v.y
  END SUB

  SUB fzxVector2DMultiplyScalar (v AS tFZX_VECTOR2d, s AS DOUBLE)
    v.x = v.x * s
    v.y = v.y * s
  END SUB

  SUB fzxVector2DMultiplyScalarND (o AS tFZX_VECTOR2d, v AS tFZX_VECTOR2d, s AS DOUBLE)
    o.x = v.x * s
    o.y = v.y * s
  END SUB

  SUB fzxVector2DDivideScalar (v AS tFZX_VECTOR2d, s AS DOUBLE)
    v.x = v.x / s
    v.y = v.y / s
  END SUB

  SUB fzxVector2DDivideScalarND (o AS tFZX_VECTOR2d, v AS tFZX_VECTOR2d, s AS DOUBLE)
    o.x = v.x / s
    o.y = v.y / s
  END SUB

  SUB fzxVector2DAddScalar (v AS tFZX_VECTOR2d, s AS DOUBLE)
    v.x = v.x + s
    v.y = v.y + s
  END SUB

  SUB fzxVector2DAddScalarND (o AS tFZX_VECTOR2d, v AS tFZX_VECTOR2d, s AS DOUBLE)
    o.x = v.x + s
    o.y = v.y + s
  END SUB

  SUB fzxVector2DMultiplyVector (v AS tFZX_VECTOR2d, m AS tFZX_VECTOR2d)
    v.x = v.x * m.x
    v.y = v.y * m.y
  END SUB

  SUB fzxVector2DMultiplyVectorND (o AS tFZX_VECTOR2d, v AS tFZX_VECTOR2d, m AS tFZX_VECTOR2d)
    o.x = v.x * m.x
    o.y = v.y * m.y
  END SUB

  SUB fzxVector2DDivideVector (v AS tFZX_VECTOR2d, m AS tFZX_VECTOR2d)
    v.x = v.x / m.x
    v.y = v.y / m.y
  END SUB

  SUB fzxVector2DDivideVectorND (o AS tFZX_VECTOR2d, v AS tFZX_VECTOR2d, m AS tFZX_VECTOR2d)
    o.x = v.x / m.x
    o.y = v.y / m.y
  END SUB

  SUB fzxVector2DAddVector (v AS tFZX_VECTOR2d, m AS tFZX_VECTOR2d)
    v.x = v.x + m.x
    v.y = v.y + m.y
  END SUB

  SUB fzxVector2DAddVectorND (o AS tFZX_VECTOR2d, v AS tFZX_VECTOR2d, m AS tFZX_VECTOR2d)
    o.x = v.x + m.x
    o.y = v.y + m.y
  END SUB

  SUB fzxVector2DAddVectorScalar (v AS tFZX_VECTOR2d, m AS tFZX_VECTOR2d, s AS DOUBLE)
    v.x = v.x + m.x * s
    v.y = v.y + m.y * s
  END SUB

  SUB fzxVector2DAddVectorScalarND (o AS tFZX_VECTOR2d, v AS tFZX_VECTOR2d, m AS tFZX_VECTOR2d, s AS DOUBLE)
    o.x = v.x + m.x * s
    o.y = v.y + m.y * s
  END SUB

  SUB fzxVector2DSubVector (v AS tFZX_VECTOR2d, m AS tFZX_VECTOR2d)
    v.x = v.x - m.x
    v.y = v.y - m.y
  END SUB

  SUB fzxVector2DSubVectorND (o AS tFZX_VECTOR2d, v AS tFZX_VECTOR2d, m AS tFZX_VECTOR2d)
    o.x = v.x - m.x
    o.y = v.y - m.y
  END SUB

  SUB fzxVector2DSwap (v1 AS tFZX_VECTOR2d, v2 AS tFZX_VECTOR2d)
    SWAP v1, v2
  END SUB

  FUNCTION fzxVector2DLengthSq# (v AS tFZX_VECTOR2d)
    fzxVector2DLengthSq = v.x * v.x + v.y * v.y
  END FUNCTION

  FUNCTION fzxVector2DLength# (v AS tFZX_VECTOR2d)
    fzxVector2DLength = SQR(fzxVector2DLengthSq(v))
  END FUNCTION

  SUB fzxVector2DRotate (v AS tFZX_VECTOR2d, radians AS DOUBLE)
    DIM c, s, xp, yp AS DOUBLE
    c = COS(radians)
    s = SIN(radians)
    xp = v.x * c - v.y * s
    yp = v.x * s + v.y * c
    v.x = xp
    v.y = yp
  END SUB

  SUB fzxVector2DNormalize (v AS tFZX_VECTOR2d)
    DIM lenSQ, invLen AS DOUBLE
    lenSQ = fzxVector2DLengthSq(v)
    IF lenSQ > cFZX_EPSILON_SQ THEN
      invLen = 1.0 / SQR(lenSQ)
      v.x = v.x * invLen
      v.y = v.y * invLen
    END IF
  END SUB

  SUB fzxVector2DMin (a AS tFZX_VECTOR2d, b AS tFZX_VECTOR2d, o AS tFZX_VECTOR2d)
    o.x = fzxScalarMin(a.x, b.x)
    o.y = fzxScalarMin(a.y, b.y)
  END SUB

  SUB fzxVector2DMax (a AS tFZX_VECTOR2d, b AS tFZX_VECTOR2d, o AS tFZX_VECTOR2d)
    o.x = fzxScalarMax(a.x, b.x)
    o.y = fzxScalarMax(a.y, b.y)
  END SUB

  FUNCTION fzxVector2DDot# (a AS tFZX_VECTOR2d, b AS tFZX_VECTOR2d)
    fzxVector2DDot = a.x * b.x + a.y * b.y
  END FUNCTION

  FUNCTION fzxVector2DSqDist# (a AS tFZX_VECTOR2d, b AS tFZX_VECTOR2d)
    DIM dx, dy AS DOUBLE
    dx = b.x - a.x
    dy = b.y - a.y
    fzxVector2DSqDist = dx * dx + dy * dy
  END FUNCTION

  FUNCTION fzxVector2DDistance# (a AS tFZX_VECTOR2d, b AS tFZX_VECTOR2d)
    fzxVector2DDistance = SQR(fzxVector2DSqDist(a, b))
  END FUNCTION

  FUNCTION fzxVector2DCross# (a AS tFZX_VECTOR2d, b AS tFZX_VECTOR2d)
    fzxVector2DCross = a.x * b.y - a.y * b.x
  END FUNCTION

  SUB fzxVector2DCrossScalar (o AS tFZX_VECTOR2d, v AS tFZX_VECTOR2d, a AS DOUBLE)
    o.x = v.y * -a
    o.y = v.x * a
  END SUB

  FUNCTION fzxVector2DArea# (a AS tFZX_VECTOR2d, b AS tFZX_VECTOR2d, c AS tFZX_VECTOR2d)
    fzxVector2DArea = (((b.x - a.x) * (c.y - a.y)) - ((c.x - a.x) * (b.y - a.y)))
  END FUNCTION

  FUNCTION fzxVector2DLeft# (a AS tFZX_VECTOR2d, b AS tFZX_VECTOR2d, c AS tFZX_VECTOR2d)
    fzxVector2DLeft = fzxVector2DArea(a, b, c) > 0
  END FUNCTION

  FUNCTION fzxVector2DLeftOn# (a AS tFZX_VECTOR2d, b AS tFZX_VECTOR2d, c AS tFZX_VECTOR2d)
    fzxVector2DLeftOn = fzxVector2DArea(a, b, c) >= 0
  END FUNCTION

  FUNCTION fzxVector2DRight# (a AS tFZX_VECTOR2d, b AS tFZX_VECTOR2d, c AS tFZX_VECTOR2d)
    fzxVector2DRight = fzxVector2DArea(a, b, c) < 0
  END FUNCTION

  FUNCTION fzxVector2DRightOn# (a AS tFZX_VECTOR2d, b AS tFZX_VECTOR2d, c AS tFZX_VECTOR2d)
    fzxVector2DRightOn = fzxVector2DArea(a, b, c) <= 0
  END FUNCTION

  FUNCTION fzxVector2DCollinear# (a AS tFZX_VECTOR2d, b AS tFZX_VECTOR2d, c AS tFZX_VECTOR2d, thresholdAngle AS DOUBLE)
    IF (thresholdAngle = 0) THEN
      fzxVector2DCollinear = (fzxVector2DArea(a, b, c) = 0)
    ELSE
      DIM ab AS tFZX_VECTOR2d
      DIM bc AS tFZX_VECTOR2d
      DIM dot AS DOUBLE
      DIM magA AS DOUBLE
      DIM magB AS DOUBLE
      DIM angle AS DOUBLE

      ab.x = b.x - a.x
      ab.y = b.y - a.y
      bc.x = c.x - b.x
      bc.y = c.y - b.y

      dot = ab.x * bc.x + ab.y * bc.y
      magA = SQR(ab.x * ab.x + ab.y * ab.y)
      magB = SQR(bc.x * bc.x + bc.y * bc.y)
      angle = _ACOS(dot / (magA * magB))
      fzxVector2DCollinear = angle < thresholdAngle
    END IF
  END FUNCTION


  SUB fzxVector2DLERP (curr AS tFZX_VECTOR2d, start AS tFZX_VECTOR2d, target AS tFZX_VECTOR2d, inc AS DOUBLE)
    curr.x = fzxScalarLERP(start.x, target.x, inc)
    curr.y = fzxScalarLERP(start.y, target.y, inc)
  END SUB

  SUB fzxVector2DLERPSmooth (curr AS tFZX_VECTOR2d, start AS tFZX_VECTOR2d, target AS tFZX_VECTOR2d, inc AS DOUBLE)
    curr.x = fzxScalarLERPSmooth(start.x, target.x, inc)
    curr.y = fzxScalarLERPSmooth(start.y, target.y, inc)
  END SUB

  SUB fzxVector2DLERPSmoother (curr AS tFZX_VECTOR2d, start AS tFZX_VECTOR2d, target AS tFZX_VECTOR2d, inc AS DOUBLE)
    curr.x = fzxScalarLERPSmoother(start.x, target.x, inc)
    curr.y = fzxScalarLERPSmoother(start.y, target.y, inc)
  END SUB

  SUB fzxVector2DOrbitVector (o AS tFZX_VECTOR2d, position AS tFZX_VECTOR2d, dist AS DOUBLE, angle AS DOUBLE)
    o.x = COS(angle) * dist + position.x
    o.y = SIN(angle) * dist + position.y
  END SUB

  FUNCTION fzxVector2DEqual (a AS tFZX_VECTOR2d, b AS tFZX_VECTOR2d, tolerance AS DOUBLE)
    fzxVector2DEqual = fzxScalarRoughEqual(a.x, b.x, tolerance) AND fzxScalarRoughEqual(a.y, b.y, tolerance)
  END FUNCTION

  SUB fzxVector2DMid (o AS tFZX_VECTOR2d, v1 AS tFZX_VECTOR2d, v2 AS tFZX_VECTOR2d)
    o.x = (v1.x + v2.x) / 2
    o.y = (v1.y + v2.y) / 2
  END SUB

  FUNCTION fzxGetAngleVector2d# (p1 AS tFZX_VECTOR2d, p2 AS tFZX_VECTOR2d)
    fzxGetAngleVector2d = fzxGetAngle(p1.x, p1.y, p2.x, p2.y)
  END FUNCTION

  ' Function written bu Galleon (modified for using radians)
  FUNCTION fzxGetAngle# (x1 AS DOUBLE, y1 AS DOUBLE, x2 AS DOUBLE, y2 AS DOUBLE) 'returns 0-359.99...
    IF y2 = y1 THEN
      IF x1 = x2 THEN EXIT FUNCTION
      IF x2 > x1 THEN fzxGetAngle# = _PI * .5 ELSE fzxGetAngle# = _PI * 1.5
      EXIT FUNCTION
    END IF
    IF x2 = x1 THEN
      IF y2 > y1 THEN fzxGetAngle# = _PI
      EXIT FUNCTION
    END IF
    IF y2 < y1 THEN
      IF x2 > x1 THEN
        fzxGetAngle# = -ATN((x2 - x1) / (y2 - y1))
      ELSE
        fzxGetAngle# = -ATN((x2 - x1) / (y2 - y1)) + (2 * _PI)
      END IF
    ELSE
      fzxGetAngle# = -ATN((x2 - x1) / (y2 - y1)) + _PI
    END IF
  END FUNCTION

$END IF
