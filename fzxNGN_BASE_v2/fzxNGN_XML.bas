'$include:'fzxNGN_ini.bas'

$IF FZXXMLINCLUDE = UNDEFINED THEN
  $LET FZXXMLINCLUDE = TRUE

  SUB _____XML_HANDLING (): END SUB

  SUB XMLparse (file AS STRING, con() AS tFZX_STRINGTUPLE)
    DIM AS STRING xml(0), x, element_name, stack(0), context
    DIM AS LONG index
    DIM AS LONG element_start, element_ending
    DIM AS LONG element_first_space, element_pop
    DIM AS LONG element_end_of_family, element_no_family
    DIM AS LONG header_start, header_finish
    DIM AS LONG element_name_start, element_name_end
    DIM AS LONG comment_start, comment_end, comment_multiline_start, comment_multiline_end
    DIM AS LONG mute, j

    ' clear out context
    REDIM con(0) AS tFZX_STRINGTUPLE

    loadFilebyLine trim$(file), xml()

    mute = 0

    FOR index = 0 TO UBOUND(xml) - 1
      x = RTRIM$(LTRIM$(xml(index)))
      header_start = INSTR(x, "<?")
      header_finish = INSTR(x, "?>")
      comment_start = INSTR(x, "<!")
      comment_end = INSTR(x, "!>")
      comment_multiline_start = INSTR(x, "<!--")
      comment_multiline_end = INSTR(x, "-->")
      IF comment_start OR comment_multiline_start THEN mute = 1
      IF comment_end OR comment_multiline_end THEN mute = 0

      IF header_start = 0 AND mute = 0 THEN
        element_start = INSTR(x, "<")
        element_end_of_family = INSTR(x, "</")
        element_first_space = INSTR(element_start, x, " ")
        element_pop = INSTR(x, "/")
        element_ending = INSTR(x, ">")
        element_no_family = INSTR(x, "/>")
        element_name = ""
        IF element_start THEN
          'Get Element Name
          'Starting character
          IF element_end_of_family THEN
            element_name_start = element_end_of_family + 2 'start after '</'
          ELSE
            element_name_start = element_start + 1 'start after '<'
          END IF
          'Ending character
          IF element_first_space THEN ' check for a space after the element name
            element_name_end = element_first_space
          ELSE
            IF element_no_family THEN ' check for no family
              element_name_end = element_no_family
            ELSE
              IF element_ending THEN ' check for family name
                element_name_end = element_ending
              ELSE
                PRINT "XML malformed. "; x
                END
              END IF
            END IF
          END IF
          element_name = MID$(x, element_name_start, element_name_end - element_name_start)
          ' Determine level
          IF element_end_of_family = 0 THEN
            pushStackString stack(), element_name
            ' Compile context tree
            context = ""
            FOR j = 0 TO UBOUND(stack) - 1 'push_pop
              context = context + stack(j)
              IF j < UBOUND(stack) - 1 THEN
                context = context + " "
              END IF
            NEXT
          END IF
          IF element_pop THEN popStackString stack()
        END IF
        ' push onto Context tuple
        IF element_end_of_family = 0 THEN pushStackContextArg con(), context, x
      END IF
    NEXT
  END SUB

  FUNCTION getXMLArgValue# (i AS STRING, s AS STRING)
    DIM AS LONG sp, space
    DIM AS STRING m
    sp = INSTR(i, s)
    IF sp THEN
      sp = sp + LEN(s) + 1 ' add one for the quotes
      space = INSTR(sp + 1, i, CHR$(34)) - sp
      m = MID$(i, sp, space)
      getXMLArgValue# = VAL(m)
    END IF
  END FUNCTION

  FUNCTION getXMLArgString$ (i AS STRING, s AS STRING)
    DIM AS LONG sp, space
    DIM AS STRING m
    sp = INSTR(i, s)
    IF sp THEN
      sp = sp + LEN(s) + 1 ' add one for the quotes
      space = INSTR(sp + 1, i, CHR$(34)) - sp
      m = MID$(i, sp, space)
      getXMLArgString$ = RTRIM$(LTRIM$(m))
    END IF
  END FUNCTION

  '**********************************************************************************************
  '   Stack Functions/Subs
  '**********************************************************************************************
  SUB _______________STACK_HANDLING (): END SUB

  FUNCTION topStackString$ (stack() AS STRING)
    IF UBOUND(stack) > 0 THEN
      topStackString$ = stack(UBOUND(stack) - 1)
    ELSE
      topStackString$ = stack(UBOUND(stack))
    END IF
  END FUNCTION

  SUB pushStackString (stack() AS STRING, element AS STRING)
    stack(UBOUND(stack)) = element
    REDIM _PRESERVE stack(UBOUND(stack) + 1) AS STRING
  END SUB

  SUB popStackString (stack() AS STRING)
    IF UBOUND(stack) > 0 THEN REDIM _PRESERVE stack(UBOUND(stack) - 1) AS STRING
  END SUB

  SUB pushStackContextArg (stack() AS tFZX_STRINGTUPLE, element_name AS STRING, element AS STRING)
    stack(UBOUND(stack)).contextName = element_name
    stack(UBOUND(stack)).arg = element
    REDIM _PRESERVE stack(UBOUND(stack) + 1) AS tFZX_STRINGTUPLE
  END SUB

  SUB pushStackContext (stack() AS tFZX_STRINGTUPLE, element AS tFZX_STRINGTUPLE)
    stack(UBOUND(stack)) = element
    REDIM _PRESERVE stack(UBOUND(stack) + 1) AS tFZX_STRINGTUPLE
  END SUB

  SUB popStackContext (stack() AS tFZX_STRINGTUPLE)
    IF UBOUND(stack) > 0 THEN REDIM _PRESERVE stack(UBOUND(stack) - 1) AS tFZX_STRINGTUPLE
  END SUB

  SUB pushStackVector (stack() AS tFZX_VECTOR2d, element AS tFZX_VECTOR2d)
    stack(UBOUND(stack)) = element
    REDIM _PRESERVE stack(UBOUND(stack) + 1) AS tFZX_VECTOR2d
  END SUB

  SUB popStackVector (stack() AS tFZX_VECTOR2d)
    IF UBOUND(stack) > 0 THEN REDIM _PRESERVE stack(UBOUND(stack) - 1) AS tFZX_VECTOR2d
  END SUB

  SUB topStackVector (o AS tFZX_VECTOR2d, stack() AS tFZX_VECTOR2d)
    IF UBOUND(stack) > 0 THEN
      o = stack(UBOUND(stack) - 1)
    ELSE
      o = stack(UBOUND(stack))
    END IF
  END SUB

  SUB loadFilebyLine (fl AS STRING, filetext() AS STRING)
    fl = LTRIM$(RTRIM$(fl)) 'clean the filename
    DIM AS LONG file_num
    IF _FILEEXISTS(fl) THEN
      file_num = FREEFILE
      OPEN fl FOR INPUT AS #file_num
      DO UNTIL EOF(file_num)
        LINE INPUT #file_num, filetext(UBOUND(filetext))
        REDIM _PRESERVE filetext(UBOUND(filetext) + 1) AS STRING
      LOOP
      CLOSE file_num
    ELSE
      PRINT "File not found :"; fl
      END
    END IF
  END SUB
  '-------------------------------------------------------
  ' Misc Utility Functions
  '-------------------------------------------------------

  SUB _____MISC (): END SUB

  FUNCTION trim$ (s AS STRING)
    trim$ = RTRIM$(LTRIM$(s))
  END FUNCTION

  FUNCTION isAlpha (c AS STRING)
    isAlpha = (ASC(c) >= 65 AND ASC(c) <= 90) OR ((ASC(c) >= 97) AND (ASC(c) <= 122))
  END FUNCTION

  FUNCTION isDigit (c AS STRING)
    isDigit = (ASC(c) >= 48 AND ASC(c) <= 57)
  END FUNCTION

  FUNCTION isSymbol (c AS STRING)
    isSymbol = NOT (isAlpha(c) OR isDigit(c))
  END FUNCTION

$END IF
