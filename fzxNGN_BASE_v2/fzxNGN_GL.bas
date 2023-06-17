'$include:'fzxNGN_ini.bas'
'$include:'fzxNGN_VECMATH.bas'
$IF FZXGLINCLUDE = UNDEFINED THEN
  $LET FZXGLINCLUDE = TRUE
'**********************************************************************************************
'   GL Drawing Subs
'**********************************************************************************************
SUB _______________GL_DRAWING (): END SUB

SUB glDrawCircle (cx AS SINGLE, cy AS SINGLE, r AS SINGLE, numOfSegments AS LONG)
  DIM AS LONG ii
  DIM AS SINGLE x, y, rads
  rads = 2.0 * _PI / numOfSegments
  _GLENABLE _GL_TEXTURE_2D
  _GLBEGIN _GL_LINE_LOOP
  DO WHILE ii <= numOfSegments
    x = r * COS(rads * ii)
    y = r * SIN(rads * ii)
    _GLVERTEX3F x + cx, y + cy, .5
    ii = ii + 1
  LOOP
  _GLEND
  _GLFLUSH
  _GLDISABLE _GL_TEXTURE_2D
END SUB

SUB glDrawRectText (tex AS LONG, x AS SINGLE, y AS SINGLE, x1 AS SINGLE, y1 AS SINGLE)
  GLSelectTexture tex
  _GLENABLE _GL_TEXTURE_2D
  _GLTEXPARAMETERI _GL_TEXTURE_2D, _GL_TEXTURE_MAG_FILTER, _GL_NEAREST
  _GLTEXPARAMETERI _GL_TEXTURE_2D, _GL_TEXTURE_MIN_FILTER, _GL_NEAREST
  _GLBEGIN _GL_QUADS
  _GLTEXCOORD2F 1, 1: _GLVERTEX2F x, y1
  _GLTEXCOORD2F 0, 1: _GLVERTEX2F x1, y1
  _GLTEXCOORD2F 0, 0: _GLVERTEX2F x1, y
  _GLTEXCOORD2F 1, 0: _GLVERTEX2F x, y
  _GLEND
  _GLDISABLE _GL_TEXTURE_2D
END SUB

SUB glDrawTexturedQuad (tex AS LONG, a AS tFZX_VECTOR2d, b AS tFZX_VECTOR2d, c AS tFZX_VECTOR2d, d AS tFZX_VECTOR2d)
  GLSelectTexture tex
  _GLENABLE _GL_TEXTURE_2D
  _GLTEXPARAMETERI _GL_TEXTURE_2D, _GL_TEXTURE_MAG_FILTER, _GL_NEAREST
  _GLTEXPARAMETERI _GL_TEXTURE_2D, _GL_TEXTURE_MIN_FILTER, _GL_NEAREST
  _GLBEGIN _GL_QUADS
  _GLTEXCOORD2F 1, 1: _GLVERTEX2F a.x, a.y
  _GLTEXCOORD2F 0, 1: _GLVERTEX2F b.x, b.y
  _GLTEXCOORD2F 0, 0: _GLVERTEX2F c.x, c.y
  _GLTEXCOORD2F 1, 0: _GLVERTEX2F d.x, d.y
  _GLEND
  _GLDISABLE _GL_TEXTURE_2D
END SUB

SUB glDrawLine (a AS tFZX_VECTOR2d, b AS tFZX_VECTOR2d, c AS LONG, w AS INTEGER)
  _GLLINEWIDTH w
  _GLCOLOR3UB _RED(c), _GREEN(c), _BLUE(c)
  _GLBEGIN _GL_LINES
  _GLVERTEX2F a.x, a.y
  _GLVERTEX2F b.x, b.y
  _GLEND
END SUB


$endif
