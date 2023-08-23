'$include:'fzxNGN_ini.bas'

$IF FZXHASHINCLUDE = UNDEFINED THEN
  $LET FZXHASHINCLUDE = TRUE

  FUNCTION fzxComputeHash&& (s AS STRING)
    DIM p, i AS LONG: p = 31
    DIM m AS _INTEGER64: m = 1E9 + 9
    DIM AS _INTEGER64 hash_value, p_pow
    p_pow = 1
    FOR i = 1 TO LEN(s)
      hash_value = (hash_value + (ASC(MID$(s, i)) - 97 + 1) * p_pow)
      p_pow = (p_pow * p) MOD m
    NEXT
    fzxComputeHash = hash_value
  END FUNCTION
$END IF
