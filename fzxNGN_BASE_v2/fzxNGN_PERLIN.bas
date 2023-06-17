'$include:'fzxNGN_ini.bas'

$IF FZXPERLININCLUDE = UNDEFINED THEN
  $LET FZXPERLININCLUDE = TRUE

  '**********************************************************************************************
  '   Perlin Operations
  '**********************************************************************************************

  FUNCTION fzxPerlinScaleOffset (p AS DOUBLE)
    fzxPerlinScaleOffset = INT(p * 256 + 128)
  END FUNCTION

  '/* Function to linearly interpolate between a0 and a1
  ' * Weight w should be in the range [0.0, 1.0]
  FUNCTION fzxPerlinInterpolate# (a0 AS DOUBLE, a1 AS DOUBLE, w AS DOUBLE)
    ' /* // You may want clamping by inserting:
    '  * if (0.0 > w) return a0;
    IF 0.0 > w THEN fzxPerlinInterpolate# = a0: EXIT FUNCTION
    '  * if (1.0 < w) return a1;
    IF 1.0 < w THEN fzxPerlinInterpolate# = a1: EXIT FUNCTION
    ' fzxPerlinInterpolate = (a1 - a0) * w + a0
    ' /* // Use this cubic interpolation [[Smoothstep]] instead, for a smooth appearance:
    '  * return (a1 - a0) * (3.0 - w * 2.0) * w * w + a0;
    'fzxPerlinInterpolate = (a1 - a0) * (3.0 - w * 2.0) * w * w + a0
    '  * // Use [[Smootherstep]] for an even smoother result with a second derivative equal to zero on boundaries:
    '  * return (a1 - a0) * ((w * (w * 6.0 - 15.0) + 10.0) * w * w * w) + a0;
    fzxPerlinInterpolate# = (a1 - a0) * ((w * (w * 6.0 - 15.0) + 10.0) * w * w * w) + a0
  END FUNCTION

  '/* Create random direction vector
  SUB fzxPerlinRandomGradient (seed AS DOUBLE, ix AS INTEGER, iy AS INTEGER, o AS tFZX_VECTOR2d)
    '// Random float. No precomputed gradients mean this works for any number of grid coordinates
    DIM AS DOUBLE prandom
    prandom = seed * SIN(ix * 21942.0 + iy * 171324.0 + 8912.0) * COS(ix * 23157.0 * iy * 217832.0 + 9758.0)
    o.x = COS(prandom)
    o.y = SIN(prandom)
  END SUB

  '// Computes the dot product of the distance and gradient vectors.
  FUNCTION fzxPerlinDotGridGradient# (seed AS DOUBLE, ix AS INTEGER, iy AS INTEGER, x AS DOUBLE, y AS DOUBLE)
    DIM AS tFZX_VECTOR2d gradient
    DIM AS DOUBLE dx, dy
    '/ Get gradient from integer coordinates
    fzxPerlinRandomGradient seed, ix, iy, gradient
    '// Compute the distance vector
    dx = x - ix
    dy = y - iy
    '// Compute the dot-product
    fzxPerlinDotGridGradient# = dx * gradient.x + dy * gradient.y
  END FUNCTION

  '// Compute Perlin noise at coordinates x, y
  FUNCTION fzxPerlin# (x AS DOUBLE, y AS DOUBLE, seed AS DOUBLE)
    '// Determine grid cell coordinates
    DIM AS INTEGER x0, x1, y0, y1
    DIM AS DOUBLE sx, sy, n0, n1, ix0, ix1
    x0 = INT(x)
    x1 = x0 + 1
    y0 = INT(y)
    y1 = y0 + 1

    '// Determine interpolation weights
    '// Could also use higher order polynomial/s-curve here
    sx = x - x0
    sy = y - y0

    '// Interpolate between grid point gradients
    n0 = fzxPerlinDotGridGradient#(seed, x0, y0, x, y)
    n1 = fzxPerlinDotGridGradient#(seed, x1, y0, x, y)
    ix0 = fzxPerlinInterpolate#(n0, n1, sx)

    n0 = fzxPerlinDotGridGradient#(seed, x0, y1, x, y)
    n1 = fzxPerlinDotGridGradient#(seed, x1, y1, x, y)
    ix1 = fzxPerlinInterpolate#(n0, n1, sx)

    fzxPerlin# = fzxPerlinInterpolate#(ix0, ix1, sy)
  END FUNCTION
$END IF
