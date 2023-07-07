'$include:'fzxNGN_ini.bas'

$IF FZXIMPULSEMATHINCLUDE = UNDEFINED THEN
  $LET FZXIMPULSEMATHINCLUDE = TRUE
  '**********************************************************************************************
  '   Impulse Math
  '**********************************************************************************************
  SUB _______________IMPULSE_MATH (): END SUB

  FUNCTION fzxImpulseEqual (a AS DOUBLE, b AS DOUBLE)
    fzxImpulseEqual = ABS(a - b) <= cFZX_EPSILON
  END FUNCTION

  FUNCTION fzxImpulseClamp# (min AS DOUBLE, max AS DOUBLE, a AS DOUBLE)
    IF a < min THEN
      fzxImpulseClamp = min
    ELSE IF a > max THEN
        fzxImpulseClamp = max
      ELSE
        fzxImpulseClamp = a
      END IF
    END IF
  END FUNCTION

  FUNCTION fzxImpulseRound# (a AS DOUBLE)
    fzxImpulseRound = INT(a + 0.5)
  END FUNCTION

  FUNCTION fzxImpulseRandomFloat## (min AS _FLOAT, max AS _FLOAT)
    fzxImpulseRandomFloat = ((max - min) * RND + min)
  END FUNCTION

  FUNCTION fzxImpulseRandomInteger% (min AS INTEGER, max AS INTEGER)
    fzxImpulseRandomInteger = INT((max - min) * RND + min)
  END FUNCTION

  FUNCTION fzxImpulseRandomdouble# (min AS DOUBLE, max AS DOUBLE)
    fzxImpulseRandomdouble = ((max - min) * RND + min)
  END FUNCTION

  FUNCTION fzxImpulseGT (a AS DOUBLE, b AS DOUBLE)
    fzxImpulseGT = (a >= b * cFZX_BIAS_RELATIVE + a * cFZX_BIAS_ABSOLUTE)
  END FUNCTION

  FUNCTION fzxImpulseWithin (v AS DOUBLE, low AS DOUBLE, high AS DOUBLE)
    fzxImpulseWithin = (low <= v) AND (v <= high)
  END FUNCTION

$END IF
