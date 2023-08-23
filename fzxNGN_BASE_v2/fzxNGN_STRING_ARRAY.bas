'$include:'fzxNGN_ini.bas'

$IF FZXSTARRAYINCLUDE = UNDEFINED THEN
  $LET FZXSTARRAYINCLUDE = TRUE
  FUNCTION fzxReadArrayLong& (s AS STRING, p AS LONG)
    IF p > 0 AND p * 4 + 4 < LEN(s) THEN fzxReadArrayLong = CVL(MID$(s, p * 4, 4))
  END FUNCTION

  SUB fzxSetArrayLong (s AS STRING, p AS LONG, v AS LONG)
    IF p > 0 AND p * 4 + 4 < LEN(s) THEN MID$(s, p * 4) = MKL$(v)
  END SUB

  FUNCTION fzxReadArraySingle! (s AS STRING, p AS LONG)
    IF p > 0 AND p * 4 + 4 < LEN(s) THEN fzxReadArraySingle = CVS(MID$(s, p * 4, 4))
  END FUNCTION

  SUB fzxSetArraySingle (s AS STRING, p AS LONG, v AS SINGLE)
    IF p > 0 AND p * 4 + 4 < LEN(s) THEN MID$(s, p * 4) = MKS$(v)
  END SUB

  FUNCTION fzxReadArrayInteger% (s AS STRING, p AS LONG)
    IF p > 0 AND p * 2 + 2 < LEN(s) THEN fzxReadArrayInteger = CVI(MID$(s, p * 2, 2))
  END FUNCTION

  SUB fzxSetArrayInteger (s AS STRING, p AS LONG, v AS INTEGER)
    IF p > 0 AND p * 2 + 2 < LEN(s) THEN MID$(s, p * 2) = MKI$(v)
  END SUB

  FUNCTION fzxReadArrayDouble# (s AS STRING, p AS LONG)
    IF p > 0 AND p * 8 + 8 < LEN(s) THEN fzxReadArrayDouble = CVL(MID$(s, p * 8, 8))
  END FUNCTION

  SUB fzxSetArrayDouble (s AS STRING, p AS LONG, v AS DOUBLE)
    IF p > 0 AND p * 8 + 8 < LEN(s) THEN MID$(s, p * 8) = MKD$(v)
  END SUB
$END IF

