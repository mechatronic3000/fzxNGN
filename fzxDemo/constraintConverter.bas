TYPE vector2d
  x AS DOUBLE
  y AS DOUBLE
END TYPE

TYPE vectorField
  v AS vector2d
END TYPE


DIM AS STRING constraintFile
DIM AS LONG img

constraintFile = _OPENFILEDIALOG$("Open Constraint Image", _CWD$, "*.png|*.bmp|*.jpg", "Image Files", 0)
IF _FILEEXISTS(constraintFile) THEN
  img = _LOADIMAGE(constraintFile)
ELSE
  END
END IF

DIM AS vectorField vf(_WIDTH(img), _HEIGHT(img))
buildVectorField vf()


SCREEN img
CLS

SCREEN _NEWIMAGE(_WIDTH(img) * 3, _HEIGHT(img) * 3, 32)

FOR j = 1 TO _HEIGHT(img)
  FOR i = 1 TO _WIDTH(img)
    xn = vf(i, j).v.x
    yn = vf(i, j).v.y
    LINE (i * 3 + 1.5, j * 3 + 1.5)-((xn + i) * 3 + 1.5, (yn + j) * 3 + 1.5)
    PSET ((xn + i) * 3 + 1.5, (yn + j) * 3 + 1.5), _RGB32(255, 0, 0)
  NEXT
NEXT

FUNCTION magnitude# (x AS DOUBLE, y AS DOUBLE)
  magnitude = SQR(x * x + y * y)
END FUNCTION

SUB normalize (x AS DOUBLE, y AS DOUBLE, xn AS DOUBLE, yn AS DOUBLE)
  DIM AS DOUBLE m: m = magnitude(x, y)
  xn = x / m
  yn = y / m
END SUB

SUB buildVectorField (vf() AS vectorField)
  DIM AS LONG i, j, ii, jj, pixel1, pixel2, pixDif
  DIM AS DOUBLE xn, yn

  FOR j = 1 TO _HEIGHT - 1
    FOR i = 1 TO _WIDTH - 1
      pixel1 = POINT(i, j)
      FOR jj = -1 TO 1
        FOR ii = -1 TO 1
          pixel2 = POINT(i + ii, j + jj)
          pixDif = pixel1 - pixel2
          vf(i, j).v.x = vf(i, j).v.x + (pixDif * ii)
          vf(i, j).v.y = vf(i, j).v.y + (pixDif * jj)
        NEXT
      NEXT
      normalize vf(i, j).v.x, vf(i, j).v.y, vf(i, j).v.x, vf(i, j).v.y
    NEXT
  NEXT

END SUB


