'$include:'fzxNGN_ini.bas'
'$include:'fzxNGN_IMPULSEMATH.bas'
$IF FZXSCALARMATHINCLUDE = UNDEFINED THEN
  $LET FZXSCALARMATHINCLUDE = TRUE
  '**********************************************************************************************
  '   Scalar helper functions
  '**********************************************************************************************
  SUB _______________SCALAR_HELPER_FUNCTIONS (): END SUB

  FUNCTION fzxScalarMin# (a AS DOUBLE, b AS DOUBLE)
    IF a < b THEN
      fzxScalarMin = a
    ELSE
      fzxScalarMin = b
    END IF
  END FUNCTION

  FUNCTION fzxScalarMax# (a AS DOUBLE, b AS DOUBLE)
    IF a > b THEN
      fzxScalarMax = a
    ELSE
      fzxScalarMax = b
    END IF
  END FUNCTION

  FUNCTION fzxScalarMap# (x AS DOUBLE, in_min AS DOUBLE, in_max AS DOUBLE, out_min AS DOUBLE, out_max AS DOUBLE)
    fzxScalarMap = (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
  END FUNCTION

  FUNCTION fzxScalarLERP# (current AS DOUBLE, target AS DOUBLE, t AS DOUBLE)
    t = fzxImpulseClamp(0, 1, t)
    fzxScalarLERP = current + (target - current) * t
  END FUNCTION

  FUNCTION fzxScalarLERPSmooth# (current AS DOUBLE, target AS DOUBLE, t AS DOUBLE)
    t = fzxImpulseClamp(0, 1, t)
    fzxScalarLERPSmooth = fzxScalarLERP#(current, target, t * t * (3.0 - 2.0 * t))
  END FUNCTION

  FUNCTION fzxScalarLERPSmoother# (current AS DOUBLE, target AS DOUBLE, t AS DOUBLE)
    t = fzxImpulseClamp(0, 1, t)
    fzxScalarLERPSmoother = fzxScalarLERP(current, target, t * t * t * (t * (t * 6.0 - 15.0) + 10.0))
  END FUNCTION

  FUNCTION fzxScalarLERPProgress# (startTime AS DOUBLE, endTime AS DOUBLE)
    fzxScalarLERPProgress = fzxImpulseClamp(0, 1, (TIMER(.001) - startTime) / (endTime - startTime))
  END FUNCTION

  FUNCTION fzxScalarRoughEqual (a AS DOUBLE, b AS DOUBLE, tolerance AS DOUBLE)
    fzxScalarRoughEqual = ABS(a - b) <= tolerance
  END FUNCTION

$END IF
