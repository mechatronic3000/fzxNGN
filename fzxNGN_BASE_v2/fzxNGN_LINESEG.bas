'$include:'fzxNGN_ini.bas'

$IF FZXLINESEGINCLUDE = UNDEFINED THEN
  $LET FZXLINESEGINCLUDE = TRUE
  SUB _______________LINE_SEG_HELPER_FUNCTIONS (): END SUB

  SUB fzxLineIntersection (l1 AS tFZX_LINE2d, l2 AS tFZX_LINE2d, o AS tFZX_VECTOR2d)
    DIM as double a1, b1, c1, a2, b2, c2, det 
    o.x = 0
    o.y = 0
    a1 = l1.b.y - l1.a.y
    b1 = l1.a.x - l1.b.x
    c1 = a1 * l1.a.x + b1 * l1.a.y
    a2 = l2.b.y - l2.a.y
    b2 = l2.a.x - l2.b.x
    c2 = a2 * l2.a.x + b2 * l2.a.y
    det = a1 * b2 - a2 * b1

    IF INT(det * cFZX_PRECISION) <> 0 THEN
      o.x = (b2 * c1 - b1 * c2) / det
      o.y = (a1 * c2 - a2 * c1) / det
    END IF
  END SUB

  FUNCTION fzxLineSegmentsIntersect (l1 AS tFZX_LINE2d, l2 AS tFZX_LINE2d)
    DIM dx, dy, da, db, s, t AS DOUBLE
    dx = l1.b.x - l1.a.x
    dy = l1.b.y - l1.a.y
    da = l2.b.x - l2.a.x
    db = l2.b.y - l2.a.y
    IF da * dy - db * dx = 0 THEN
      fzxLineSegmentsIntersect = 0
    ELSE
      s = (dx * (l2.a.y - l1.a.y) + dy * (l1.a.x - l2.a.x)) / (da * dy - db * dx)
      t = (da * (l1.a.y - l2.a.y) + db * (l2.a.x - l1.a.x)) / (db * dx - da * dy)
      fzxLineSegmentsIntersect = (s >= 0 AND s <= 1 AND t >= 0 AND t <= 1)
    END IF
  END FUNCTION

$END IF
