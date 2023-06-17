'$include:'fzxNGN_ini.bas'
'$include:'fzxNGN_VECMATH.bas'
$IF FZXMEMINCLUDE = UNDEFINED THEN
  $LET FZXMEMINCLUDE = TRUE

  '**********************************************************************************************
  '   MEM Array Functions
  '**********************************************************************************************
  SUB _______________MEM_ARRAY_FUNCTIONS: END SUB

  SUB fzxSetBodyVertXY (indexBody AS LONG, indexVert AS LONG, x AS DOUBLE, y AS DOUBLE)
    'IF indexVert > __fzxBody(indexBody).shape.vert.SIZE THEN EXIT SUB
    _MEMPUT __fzxBody(indexBody).shape.vert, __fzxBody(indexBody).shape.vert.OFFSET + (indexVert * 16), x AS DOUBLE
    _MEMPUT __fzxBody(indexBody).shape.vert, __fzxBody(indexBody).shape.vert.OFFSET + (indexVert * 16) + 8, y AS DOUBLE
    'PRINT #1, "fzxSetBodyVertXY "; x; " "; y; "  "; fzxGetBodyVertX#(indexBody, indexVert); ", "; fzxGetBodyVertY#(indexBody, indexVert); "  "; __fzxBody(indexBody).objectName
  END SUB

  SUB fzxSetBodyVert (indexBody AS LONG, indexVert AS LONG, v AS tFZX_VECTOR2d)
    'IF indexVert > __fzxBody(indexBody).shape.vert.SIZE THEN EXIT SUB
    _MEMPUT __fzxBody(indexBody).shape.vert, __fzxBody(indexBody).shape.vert.OFFSET + (indexVert * 16), v.x AS DOUBLE
    _MEMPUT __fzxBody(indexBody).shape.vert, __fzxBody(indexBody).shape.vert.OFFSET + (indexVert * 16) + 8, v.y AS DOUBLE
    'PRINT #1, "fzxSetBodyVert "; v.x; " "; v.y; "  "; fzxGetBodyVertX#(indexBody, indexVert); ", "; fzxGetBodyVertY#(indexBody, indexVert); "  "; __fzxBody(indexBody).objectName
  END SUB

  FUNCTION fzxGetBodyVertX# (indexBody AS LONG, indexVert AS LONG)
    'IF indexVert > __fzxBody(indexBody).shape.vert.SIZE THEN EXIT FUNCTION
    fzxGetBodyVertX = _MEMGET(__fzxBody(indexBody).shape.vert, __fzxBody(indexBody).shape.vert.OFFSET + (indexVert * 16), DOUBLE)
  END FUNCTION

  FUNCTION fzxGetBodyVertY# (indexBody AS LONG, indexVert AS LONG)
    'IF indexVert > __fzxBody(indexBody).shape.vert.SIZE THEN EXIT FUNCTION
    fzxGetBodyVertY = _MEMGET(__fzxBody(indexBody).shape.vert, __fzxBody(indexBody).shape.vert.OFFSET + (indexVert * 16) + 8, DOUBLE)
  END FUNCTION

  SUB fzxGetBodyVert (indexBody AS LONG, indexVert AS LONG, vert AS tFZX_VECTOR2d)
    fzxVector2DSet vert, fzxGetBodyVertX#(indexBody, indexVert), fzxGetBodyVertY#(indexBody, indexVert)
  END SUB

  '**********************************************************************************************

  SUB fzxSetBodyNormXY (indexBody AS LONG, indexNorm AS LONG, x AS DOUBLE, y AS DOUBLE)
    'IF indexNorm > __fzxBody(indexBody).shape.norm.SIZE THEN EXIT SUB
    _MEMPUT __fzxBody(indexBody).shape.norm, __fzxBody(indexBody).shape.norm.OFFSET + (indexNorm * 16), x AS DOUBLE
    _MEMPUT __fzxBody(indexBody).shape.norm, __fzxBody(indexBody).shape.norm.OFFSET + (indexNorm * 16) + 8, y AS DOUBLE
    'PRINT #1, "fzxSetBodyNormXY "; x; " "; y; "  "; fzxGetBodyNormX#(indexBody, indexNorm); ", "; fzxGetBodyNormY#(indexBody, indexNorm); "  "; __fzxBody(indexBody).objectName
  END SUB

  SUB fzxSetBodyNorm (indexBody AS LONG, indexNorm AS LONG, v AS tFZX_VECTOR2d)
    'IF indexNorm > __fzxBody(indexBody).shape.norm.SIZE THEN EXIT SUB
    _MEMPUT __fzxBody(indexBody).shape.norm, __fzxBody(indexBody).shape.norm.OFFSET + (indexNorm * 16), v.x AS DOUBLE
    _MEMPUT __fzxBody(indexBody).shape.norm, __fzxBody(indexBody).shape.norm.OFFSET + (indexNorm * 16) + 8, v.y AS DOUBLE
    'PRINT #1, "fzxSetBodyNormXY "; v.x; " "; v.y; "  "; fzxGetBodyNormX#(indexBody, indexNorm); ", "; fzxGetBodyNormY#(indexBody, indexNorm); "  "; __fzxBody(indexBody).objectName
  END SUB


  FUNCTION fzxGetBodyNormX# (indexBody AS LONG, indexNorm AS LONG)
    'IF indexNorm > __fzxBody(indexBody).shape.norm.SIZE THEN EXIT FUNCTION
    fzxGetBodyNormX = _MEMGET(__fzxBody(indexBody).shape.norm, __fzxBody(indexBody).shape.norm.OFFSET + (indexNorm * 16), DOUBLE)
  END FUNCTION

  FUNCTION fzxGetBodyNormY# (indexBody AS LONG, indexNorm AS LONG)
    'IF indexNorm > __fzxBody(indexBody).shape.norm.SIZE THEN EXIT FUNCTION
    fzxGetBodyNormY = _MEMGET(__fzxBody(indexBody).shape.norm, __fzxBody(indexBody).shape.norm.OFFSET + (indexNorm * 16) + 8, DOUBLE)
  END FUNCTION

  SUB fzxGetBodyNorm (indexBody AS LONG, indexNorm AS LONG, norm AS tFZX_VECTOR2d)
    fzxVector2DSet norm, fzxGetBodyNormX#(indexBody, indexNorm), fzxGetBodyNormY#(indexBody, indexNorm)
  END SUB

$END IF
