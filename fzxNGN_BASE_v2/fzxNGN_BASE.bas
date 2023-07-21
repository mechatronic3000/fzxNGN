OPTION _EXPLICIT
'$include:'fzxNGN_ini.bas'
'$include:'fzxNGN_MEM.bas'
'$include:'fzxNGN_VECMATH.bas'
'$include:'fzxNGN_MATRIXMATH.bas'
'$include:'fzxNGN_IMPULSEMATH.bas'
'$include:'fzxNGN_SCALARMATH.bas'
'$include:'fzxNGN_LINESEG.bas'
'$include:'fzxNGN_POLYGON.bas'
'$include:'fzxNGN_AABB.bas'
'$include:'fzxNGN_PERLIN.bas'
'$include:'fzxNGN_INPUT.bas'
'$include:'fzxNGN_CAMERA.bas'
'$include:'fzxNGN_XML.bas'

'**********************************************************************************************
'   Physics code ported from RandyGaul's Impulse Engine
'   https://github.com/RandyGaul/ImpulseEngine
'
'**********************************************************************************************
'    Copyright (c) 2013 Randy Gaul

'    This software is provided 'as-is', without any express or implied
'    warranty. In no event will the authors be held liable for any damages
'    arising from the use of this software.
'    Permission is granted to anyone to use this software for any purpose,
'    including commercial applications, and to alter it and redistribute it
'    freely, subject to the following restrictions:
'      1. The origin of this software must not be misrepresented; you must not
'         claim that you wrote the original software. If you use this software
'         in a product, an acknowledgment in the product documentation would be
'         appreciated but is not required.
'      2. Altered source versions must be plainly marked as such, and must not be
'         misrepresented as being the original software.
'      3. This notice may not be removed or altered from any source distribution.
'


'**********************************************************************************************
'   Body Initilization
'**********************************************************************************************
SUB _______________BODY_INIT_FUNCTIONS: END SUB

SUB fzxCircleInitialize (index AS LONG)
  fzxCircleComputeMass index, cFZX_MASS_DENSITY
END SUB

SUB fzxCircleComputeMass (index AS LONG, density AS DOUBLE)
  __fzxBody(index).fzx.mass = _PI * __fzxBody(index).shape.radius * __fzxBody(index).shape.radius * density
  IF __fzxBody(index).fzx.mass <> 0 THEN
    __fzxBody(index).fzx.invMass = 1.0 / __fzxBody(index).fzx.mass
  ELSE
    __fzxBody(index).fzx.invMass = 0.0
  END IF

  __fzxBody(index).fzx.inertia = __fzxBody(index).fzx.mass * __fzxBody(index).shape.radius * __fzxBody(index).shape.radius

  IF __fzxBody(index).fzx.inertia <> 0 THEN
    __fzxBody(index).fzx.invInertia = 1.0 / __fzxBody(index).fzx.inertia
  ELSE
    __fzxBody(index).fzx.invInertia = 0.0
  END IF
END SUB

SUB fzxPolygonInitialize (index AS LONG)
  fzxPolygonComputeMass index, cFZX_MASS_DENSITY
END SUB

SUB fzxPolygonComputeMass (index AS LONG, density AS DOUBLE)
  DIM c AS tFZX_VECTOR2d ' centroid
  DIM p1 AS tFZX_VECTOR2d
  DIM p2 AS tFZX_VECTOR2d
  DIM AS tFZX_VECTOR2d tempV
  DIM area AS DOUBLE
  DIM I AS DOUBLE
  DIM k_inv3 AS DOUBLE
  DIM D AS DOUBLE
  DIM triangleArea AS DOUBLE
  DIM weight AS DOUBLE
  DIM intx2 AS DOUBLE
  DIM inty2 AS DOUBLE
  DIM ii AS LONG

  k_inv3 = 1.0 / 3.0

  FOR ii = 0 TO __fzxBody(index).pa.count
    fzxGetBodyVert index, ii, p1
    fzxGetBodyVert index, fzxArrayNextIndex(ii, __fzxBody(index).pa.count), p2
    D = fzxVector2DCross(p1, p2)
    triangleArea = .5 * D
    area = area + triangleArea
    weight = triangleArea * k_inv3
    fzxVector2DAddVectorScalar c, p1, weight
    fzxVector2DAddVectorScalar c, p2, weight
    intx2 = p1.x * p1.x + p2.x * p1.x + p2.x * p2.x
    inty2 = p1.y * p1.y + p2.y * p1.y + p2.y * p2.y
    I = I + (0.25 * k_inv3 * D) * (intx2 + inty2)
  NEXT ii

  fzxVector2DMultiplyScalar c, 1.0 / area
  FOR ii = 0 TO __fzxBody(index).pa.count
    fzxGetBodyVert index, ii, tempV
    fzxVector2DSubVector tempV, c
    fzxSetBodyVert index, ii, tempV
  NEXT

  __fzxBody(index).fzx.mass = density * area
  IF __fzxBody(index).fzx.mass <> 0.0 THEN
    __fzxBody(index).fzx.invMass = 1.0 / __fzxBody(index).fzx.mass
  ELSE
    __fzxBody(index).fzx.invMass = 0.0
  END IF

  __fzxBody(index).fzx.inertia = I * density
  IF __fzxBody(index).fzx.inertia <> 0 THEN
    __fzxBody(index).fzx.invInertia = 1.0 / __fzxBody(index).fzx.inertia
  ELSE
    __fzxBody(index).fzx.invInertia = 0.0
  END IF
END SUB

'**********************************************************************************************
'   Body Creation
'**********************************************************************************************

SUB _______________BODY_CREATION_FUNCTIONS: END SUB

FUNCTION fzxCreateCircleBody (index AS LONG, radius AS DOUBLE)
  DIM shape AS tFZX_SHAPE
  fzxShapeCreate shape, cFZX_SHAPE_CIRCLE, radius
  shape.maxDimension.x = radius * cFZX_AABB_TOLERANCE * 2
  shape.maxDimension.y = radius * cFZX_AABB_TOLERANCE * 2
  fzxBodyCreate index, shape
  'no vertices have to created for circles
  fzxCircleInitialize index
  __fzxBody(index).c = _RGB32(255, 255, 255)
  fzxCreateCircleBody = index
END FUNCTION

FUNCTION fzxCreateCircleBodyEx (objName AS STRING, radius AS DOUBLE)
  DIM shape AS tFZX_SHAPE
  DIM index AS LONG
  fzxShapeCreate shape, cFZX_SHAPE_CIRCLE, radius
  shape.maxDimension.x = radius * cFZX_AABB_TOLERANCE * 2
  shape.maxDimension.y = radius * cFZX_AABB_TOLERANCE * 2
  fzxBodyCreateEx objName, shape, index
  'no vertices have to created for circles
  fzxCircleInitialize index
  __fzxBody(index).c = _RGB32(255, 255, 255)
  fzxCreateCircleBodyEx = index
END FUNCTION


FUNCTION fzxCreateBoxBody (index AS LONG, xs AS DOUBLE, ys AS DOUBLE)
  DIM shape AS tFZX_SHAPE
  fzxShapeCreate shape, cFZX_SHAPE_POLYGON, 0
  fzxBodyCreate index, shape
  fzxBoxCreate index, xs, ys
  fzxPolygonInitialize index
  __fzxBody(index).c = _RGB32(255, 255, 255)
  fzxCreateBoxBody = index
END FUNCTION

FUNCTION fzxCreateBoxBodyEx (objName AS STRING, xs AS DOUBLE, ys AS DOUBLE)
  DIM shape AS tFZX_SHAPE
  DIM index AS LONG
  fzxShapeCreate shape, cFZX_SHAPE_POLYGON, 0
  fzxBodyCreateEx objName, shape, index
  fzxBoxCreate index, xs, ys
  fzxPolygonInitialize index
  __fzxBody(index).c = _RGB32(255, 255, 255)
  fzxCreateBoxBodyEx = index
END FUNCTION

SUB fzxCreateTrapBody (index AS LONG, xs AS DOUBLE, ys AS DOUBLE, yoff1 AS DOUBLE, yoff2 AS DOUBLE)
  DIM shape AS tFZX_SHAPE
  fzxShapeCreate shape, cFZX_SHAPE_POLYGON, 0
  fzxBodyCreate index, shape
  fzxTrapCreate index, xs, ys, yoff1, yoff2
  fzxPolygonInitialize index
  __fzxBody(index).c = _RGB32(255, 255, 255)
END SUB

FUNCTION fzxCreateTrapBodyEx (objName AS STRING, xs AS DOUBLE, ys AS DOUBLE, yoff1 AS DOUBLE, yoff2 AS DOUBLE)
  DIM shape AS tFZX_SHAPE
  DIM index AS LONG
  fzxShapeCreate shape, cFZX_SHAPE_POLYGON, 0
  fzxBodyCreateEx objName, shape, index
  fzxTrapCreate index, xs, ys, yoff1, yoff2
  fzxPolygonInitialize index
  __fzxBody(index).c = _RGB32(255, 255, 255)
  fzxCreateTrapBodyEx = index
END FUNCTION

SUB fzxCreatePolyBody (index AS LONG, xs AS DOUBLE, ys AS DOUBLE, sides AS LONG)
  DIM shape AS tFZX_SHAPE
  fzxShapeCreate shape, cFZX_SHAPE_POLYGON, 0
  fzxBodyCreate index, shape
  fzxPolyCreate index, xs, ys, sides
  fzxPolygonInitialize index
  __fzxBody(index).c = _RGB32(255, 255, 255)
END SUB


FUNCTION fzxCreatePolyBodyEx (objName AS STRING, xs AS DOUBLE, ys AS DOUBLE, sides AS LONG)
  DIM shape AS tFZX_SHAPE
  DIM index AS LONG
  fzxShapeCreate shape, cFZX_SHAPE_POLYGON, 0
  fzxBodyCreateEx objName, shape, index
  fzxPolyCreate index, xs, ys, sides
  fzxPolygonInitialize index
  __fzxBody(index).c = _RGB32(255, 255, 255)
  fzxCreatePolyBodyEx = index
END FUNCTION


FUNCTION fzxCreatePolyBodyTest (objName AS STRING, xs AS DOUBLE, ys AS DOUBLE, sides AS LONG) ' experimental
  DIM shape AS tFZX_SHAPE
  DIM index AS LONG
  fzxShapeCreate shape, cFZX_SHAPE_POLYGON, 0
  fzxBodyCreateEx objName, shape, index
  fzxPolyCreateTest index, xs, ys, sides
  fzxPolygonInitialize index
  __fzxBody(index).c = _RGB32(255, 255, 255)
  fzxCreatePolyBodyTest = index
END FUNCTION



SUB fzxPolyCreate (index AS LONG, sizex AS DOUBLE, sizey AS DOUBLE, sides AS LONG)
  IF sides < 2 THEN sides = 2
  IF sides > cMAXVERTSPERBODY THEN sides = cMAXVERTSPERBODY

  DIM vertlength AS LONG: vertlength = sides
  DIM AS DOUBLE theta
  DIM verts(vertlength) AS tFZX_VECTOR2d
  DIM AS LONG vertCount: vertCount = 0

  __fzxBody(index).shape.maxDimension.x = fzxScalarMax(sizex, sizey) * cFZX_AABB_TOLERANCE
  __fzxBody(index).shape.maxDimension.y = fzxScalarMax(sizex, sizey) * cFZX_AABB_TOLERANCE

  FOR theta = 0 TO 359 STEP (360 / sides)
    fzxVector2DSet verts(vertCount), sizex * COS(_D2R(theta)), sizey * SIN(_D2R(theta))
    vertCount = vertCount + 1
  NEXT
  fzxVertexSet index, verts()
END SUB

SUB fzxPolyCreateTest (index AS LONG, sizex AS DOUBLE, sizey AS DOUBLE, sides AS LONG)
  IF sides < 2 THEN sides = 2
  IF sides > cMAXVERTSPERBODY THEN sides = cMAXVERTSPERBODY

  DIM vertlength AS LONG: vertlength = sides
  DIM AS DOUBLE theta
  DIM verts(vertlength) AS tFZX_VECTOR2d
  DIM AS LONG vertCount: vertCount = 0
  DIM AS LONG odd

  __fzxBody(index).shape.maxDimension.x = fzxScalarMax(sizex, sizey) * cFZX_AABB_TOLERANCE
  __fzxBody(index).shape.maxDimension.y = fzxScalarMax(sizex, sizey) * cFZX_AABB_TOLERANCE

  FOR theta = 0 TO 359 STEP (360 / sides)
    odd = (vertCount MOD 2) * 20
    fzxVector2DSet verts(vertCount), sizex * COS(_D2R(theta)), sizey * SIN(_D2R(theta))
    vertCount = vertCount + 1
  NEXT
  fzxVertexSetTest index, verts()
END SUB

SUB fzxBodyCreate (index AS LONG, shape AS tFZX_SHAPE)
  fzxVector2DSet __fzxBody(index).fzx.position, 0, 0
  fzxVector2DSet __fzxBody(index).fzx.velocity, 0, 0
  __fzxBody(index).fzx.angularVelocity = 0.0
  __fzxBody(index).fzx.torque = 0.0
  __fzxBody(index).fzx.orient = 0.0

  fzxVector2DSet __fzxBody(index).fzx.force, 0, 0
  __fzxBody(index).fzx.staticFriction = 0.5
  __fzxBody(index).fzx.dynamicFriction = 0.3
  __fzxBody(index).fzx.restitution = 0.2
  __fzxBody(index).shape = shape
  __fzxBody(index).shape.vert = _MEMNEW(cMAXVERTSPERBODY * 16) ' x and y for a total of 16 bytes
  __fzxBody(index).shape.norm = _MEMNEW(cMAXVERTSPERBODY * 16)
  __fzxBody(index).shape.repeatTexture.x = 1
  __fzxBody(index).shape.repeatTexture.y = 1

  __fzxBody(index).collisionMask = 255
  __fzxBody(index).enable = 1
  __fzxBody(index).noPhysics = 0
  __fzxBody(index).lifetime.start = TIMER(.001)
  __fzxBody(index).lifetime.duration = 0
  __fzxBody(index).zPosition = 0.01
END SUB

SUB fzxBodyCreateEx (objname AS STRING, shape AS tFZX_SHAPE, index AS LONG)
  index = fzxBodyManagerAdd
  __fzxBody(index).objectName = objname
  __fzxBody(index).objectHash = fzxComputeHash&&(objname)
  fzxBodyCreate index, shape
END SUB

SUB fzxBoxCreate (index AS LONG, sizex AS DOUBLE, sizey AS DOUBLE)
  DIM vertlength AS LONG: vertlength = 3
  DIM verts(vertlength) AS tFZX_VECTOR2d

  __fzxBody(index).shape.maxDimension.x = fzxScalarMax(sizex, sizey) * cFZX_AABB_TOLERANCE
  __fzxBody(index).shape.maxDimension.y = fzxScalarMax(sizex, sizey) * cFZX_AABB_TOLERANCE

  fzxVector2DSet verts(0), -sizex, -sizey
  fzxVector2DSet verts(1), sizex, -sizey
  fzxVector2DSet verts(2), sizex, sizey
  fzxVector2DSet verts(3), -sizex, sizey

  fzxVertexSet index, verts()
END SUB

SUB fzxTrapCreate (index AS LONG, sizex AS DOUBLE, sizey AS DOUBLE, yOff1 AS DOUBLE, yOff2 AS DOUBLE)
  DIM vertlength AS LONG: vertlength = 3
  DIM maxYSide AS DOUBLE
  DIM verts(vertlength) AS tFZX_VECTOR2d
  maxYSide = fzxScalarMax(yOff1, yOff2) + sizey
  __fzxBody(index).shape.maxDimension.x = fzxScalarMax(sizex, maxYSide) * cFZX_AABB_TOLERANCE
  __fzxBody(index).shape.maxDimension.y = fzxScalarMax(sizex, maxYSide) * cFZX_AABB_TOLERANCE

  fzxVector2DSet verts(0), -sizex, -sizey - yOff2
  fzxVector2DSet verts(1), sizex, -sizey - yOff1
  fzxVector2DSet verts(2), sizex, sizey
  fzxVector2DSet verts(3), -sizex, sizey

  fzxVertexSet index, verts()
END SUB

SUB fzxCreateTerrainBody (index AS LONG, slices AS LONG, sliceWidth AS DOUBLE, nominalHeight AS DOUBLE)
  DIM shape AS tFZX_SHAPE
  DIM elevation(slices) AS DOUBLE
  DIM AS LONG i, j

  FOR j = 0 TO slices
    elevation(j) = RND * 500
  NEXT

  fzxShapeCreate shape, cFZX_SHAPE_POLYGON, 0

  FOR i = 0 TO slices - 1
    fzxBodyCreate index + i, shape
    fzxTerrainCreate index + i, elevation(i), elevation(i + 1), sliceWidth, nominalHeight
    fzxPolygonInitialize index + i
    __fzxBody(index + i).c = _RGB32(255, 255, 255)
    fzxBodySetStatic index + i, 1
  NEXT i
END SUB

SUB fzxCreateTerrainBodyEx (objName AS STRING, elevation() AS DOUBLE, slices AS LONG, sliceWidth AS DOUBLE, nominalHeight AS DOUBLE)
  DIM shape AS tFZX_SHAPE
  DIM AS LONG i, index

  fzxShapeCreate shape, cFZX_SHAPE_POLYGON, 0

  FOR i = 0 TO slices - 1
    fzxBodyCreateEx objName + "_" + LTRIM$(STR$(i)), shape, index
    fzxTerrainCreate index, elevation(i), elevation(i + 1), sliceWidth, nominalHeight
    fzxPolygonInitialize index
    __fzxBody(index).c = _RGB32(255, 255, 255)
    fzxBodySetStatic index, 1
  NEXT i

  DIM AS DOUBLE p1, p2
  DIM start AS _INTEGER64

  FOR i = 0 TO slices - 1
    start = fzxBodyManagerID(objName + "_" + LTRIM$(STR$(i)))
    p1 = (sliceWidth / 2) - fzxGetBodyVertX(start, 0)
    p2 = nominalHeight - fzxGetBodyVertY(start, 1)
    fzxSetBody cFZX_PARAMETER_POSITION, start, __fzxWorld.terrainPosition.x + p1 + (sliceWidth * i), __fzxWorld.terrainPosition.y + p2
  NEXT
END SUB

SUB fzxTerrainCreate (index AS LONG, ele1 AS DOUBLE, ele2 AS DOUBLE, sliceWidth AS DOUBLE, nominalHeight AS DOUBLE)
  DIM AS LONG vertLength
  vertLength = 3 ' numOfslices + 1
  DIM verts(vertLength) AS tFZX_VECTOR2d
  DIM AS DOUBLE maxElev: maxElev = fzxScalarMax(ele1, ele2) + nominalHeight


  fzxVector2DSet verts(0), -sliceWidth / 2, nominalHeight
  fzxVector2DSet verts(1), -sliceWidth / 2, -nominalHeight - ele1
  fzxVector2DSet verts(2), sliceWidth / 2, -nominalHeight - ele2
  fzxVector2DSet verts(3), sliceWidth / 2, nominalHeight
  fzxVertexSet index, verts()

  __fzxBody(index).shape.maxDimension.x = sliceWidth * cFZX_AABB_TOLERANCE
  __fzxBody(index).shape.maxDimension.y = maxElev * cFZX_AABB_TOLERANCE
END SUB

' this is a test shape and should only be used in testing concave objects
SUB fzxVShapeCreate (index AS LONG, sizex AS DOUBLE, sizey AS DOUBLE)
  DIM vertlength AS LONG: vertlength = 7
  DIM verts(vertlength) AS tFZX_VECTOR2d

  fzxVector2DSet verts(0), -sizex, -sizey
  fzxVector2DSet verts(1), sizex, -sizey
  fzxVector2DSet verts(2), sizex, sizey
  fzxVector2DSet verts(3), -sizex, sizey
  fzxVector2DSet verts(4), -sizex, sizey / 2
  fzxVector2DSet verts(5), sizex / 2, sizey / 2
  fzxVector2DSet verts(6), sizex / 2, -sizey / 2
  fzxVector2DSet verts(7), -sizex, sizey / 2

  fzxVertexSet index, verts()
END SUB

'**********************************************************************************************
' Vertex set function
' This function verifies proper rotation to calculate Normals used in Collisions
' This function also removes Concave surfaces for collisions
'**********************************************************************************************

SUB _______________VERTEX_SET_FUNCTION: END SUB
SUB fzxVertexSet (index AS LONG, verts() AS tFZX_VECTOR2d)
  DIM AS LONG i, vertLength, rightMost

  vertLength = UBOUND(verts)
  rightMost = fzxFindRightMostVert(verts())

  DIM hull(vertLength) AS LONG
  DIM outCount AS LONG: outCount = 0
  DIM indexHull AS LONG: indexHull = rightMost
  DIM nextHullIndex AS LONG
  DIM e1 AS tFZX_VECTOR2d
  DIM e2 AS tFZX_VECTOR2d
  DIM cross AS DOUBLE
  DO
    hull(outCount) = indexHull ' indexHull starts out as the right most vertex
    nextHullIndex = 0
    FOR i = 1 TO vertLength
      IF nextHullIndex = indexHull THEN
        nextHullIndex = i
        _CONTINUE
      END IF
      fzxVector2DSubVectorND e1, verts(nextHullIndex), verts(hull(outCount))
      fzxVector2DSubVectorND e2, verts(i), verts(hull(outCount))
      cross = fzxVector2DCross(e1, e2)
      ' checks for a concave area in the sides of a body
      IF cross < 0.0 OR (cross = 0.0 AND (fzxVector2DLengthSq(e2) > fzxVector2DLengthSq(e1))) THEN nextHullIndex = i
    NEXT
    outCount = outCount + 1
    indexHull = nextHullIndex
    IF nextHullIndex = rightMost THEN
      __fzxBody(index).pa.count = outCount - 1
      EXIT DO
    END IF
  LOOP

  FOR i = 0 TO vertLength
    fzxSetBodyVert index, i, verts(hull(i))
  NEXT
  ' set the normals for the poly
  DIM AS tFZX_VECTOR2d face, vert1, vert2, tempV
  FOR i = 0 TO vertLength
    fzxGetBodyVert index, fzxArrayNextIndex(i, __fzxBody(index).pa.count), vert1
    fzxGetBodyVert index, i, vert2
    fzxVector2DSubVectorND face, vert1, vert2
    fzxSetBodyNormXY index, i, face.y, -face.x
    fzxGetBodyNorm index, i, tempV
    fzxVector2DNormalize tempV
    fzxSetBodyNorm index, i, tempV
  NEXT
END SUB

' This an experimental. It does not correct any of the vertex issues. (Use at your own risk!)
SUB fzxVertexSetTest (index AS LONG, verts() AS tFZX_VECTOR2d)

  DIM AS LONG i, vertLength

  vertLength = UBOUND(verts)

  __fzxBody(index).pa.count = vertLength - 1

  FOR i = 0 TO vertLength
    fzxSetBodyVert index, i, verts(i)
  NEXT
  fzxSetBodyVert index, vertLength, verts(0)

  ' set the normals for the poly
  DIM AS tFZX_VECTOR2d face, vert1, vert2, tempV
  FOR i = 0 TO vertLength
    fzxGetBodyVert index, fzxArrayNextIndex(i, __fzxBody(index).pa.count), vert1
    fzxGetBodyVert index, i, vert2
    fzxVector2DSubVectorND face, vert1, vert2
    fzxSetBodyNormXY index, i, face.y, -face.x
    fzxGetBodyNorm index, i, tempV
    fzxVector2DNormalize tempV
    fzxSetBodyNorm index, i, tempV
  NEXT

END SUB

SUB fzxBodyClear
  DIM AS LONG iter
  iter = 0: DO WHILE iter <= UBOUND(__fzxBody)
    fzxBodyDelete iter, 0
  iter = iter + 1: LOOP
END SUB

SUB fzxBodyDelete (index AS LONG, perm AS _BYTE)
  DIM AS LONG iter
  IF index >= 0 AND index <= UBOUND(__fzxBody) THEN

    IF _MEMEXISTS(__fzxBody(index).shape.vert) THEN _MEMFREE __fzxBody(index).shape.vert
    IF _MEMEXISTS(__fzxBody(index).shape.norm) THEN _MEMFREE __fzxBody(index).shape.norm

    'remove any joints that are attached to it
    iter = 0: DO
      IF __fzxJoints(iter).body1 = index OR __fzxJoints(iter).body2 = index THEN
        fzxJointDelete iter
      END IF
    iter = iter + 1: LOOP WHILE iter <= UBOUND(__fzxJoints)

    IF NOT perm THEN
      __fzxBody(index).enable = 0
      __fzxBody(index).overwrite = 1
      __fzxBody(index).objectName = ""
      __fzxBody(index).objectHash = 0
    ELSE
      'remove the bodys attached to it
      iter = index: DO
        __fzxBody(iter) = __fzxBody(iter + 1)
      iter = iter + 1: LOOP WHILE iter < UBOUND(__fzxBody)
      REDIM _PRESERVE __fzxBody(UBOUND(__fzxBody) - 1) AS tFZX_BODY

      'fix all the joints bodies after the index since then all the bodies are shifted toward zero index
      iter = 0: DO
        IF __fzxJoints(iter).body1 >= index THEN __fzxJoints(iter).body1 = __fzxJoints(iter).body1 - 1
        IF __fzxJoints(iter).body2 >= index THEN __fzxJoints(iter).body2 = __fzxJoints(iter).body2 - 1
      iter = iter + 1: LOOP WHILE iter <= UBOUND(__fzxJoints)
    END IF
  END IF
END SUB

FUNCTION fzxFindRightMostVert (verts() AS tFZX_VECTOR2d)
  DIM AS DOUBLE x, rightmost, highestXCoord
  DIM AS LONG vertCount, i
  highestXCoord = verts(0).x
  vertCount = UBOUND(verts)
  FOR i = 0 TO vertCount - 1
    x = verts(i).x
    IF x > highestXCoord THEN
      highestXCoord = x
      rightmost = i
    ELSE
      IF x = highestXCoord THEN
        IF verts(i).y < verts(rightmost).y THEN
          rightmost = i
        END IF
      END IF
    END IF
  NEXT
  fzxFindRightMostVert = rightmost
END FUNCTION

SUB fzxVector2DGetSupport (index AS LONG, dir AS tFZX_VECTOR2d, bestVertex AS tFZX_VECTOR2d)
  DIM bestProjection AS DOUBLE
  DIM v AS tFZX_VECTOR2d
  DIM projection AS DOUBLE
  DIM i AS LONG
  bestVertex.x = -9999999
  bestVertex.y = -9999999
  bestProjection = -9999999

  FOR i = 0 TO __fzxBody(index).pa.count
    fzxGetBodyVert index, i, v
    projection = fzxVector2DDot(v, dir)
    IF projection > bestProjection THEN
      bestVertex = v
      bestProjection = projection
    END IF
  NEXT
END SUB

'**********************************************************************************************
'   Shape Function
'**********************************************************************************************
SUB _______________SHAPE_INIT_FUNCTION: END SUB
SUB fzxShapeCreate (sh AS tFZX_SHAPE, ty AS LONG, radius AS DOUBLE)
  DIM u AS tFZX_MATRIX2D
  fzxMatrix2x2SetScalar u, 1, 0, 0, 1
  sh.ty = ty
  sh.radius = radius
  sh.u = u
  sh.scaleTexture.x = 1.0
  sh.scaleTexture.y = 1.0
  sh.renderOrder = 1 ' 0 - will be the front most rendering
  fzxVector2DSet sh.uv0, 1, 1
  fzxVector2DSet sh.uv1, 0, 1
  fzxVector2DSet sh.uv2, 0, 0
  fzxVector2DSet sh.uv3, 1, 0
END SUB

'**********************************************************************************************
'   Body Tools
'**********************************************************************************************

SUB _______________BODY_PARAMETER_FUNCTIONS: END SUB

SUB fzxSetBody (Parameter AS LONG, Index AS LONG, arg1 AS DOUBLE, arg2 AS DOUBLE)
  IF Index < 0 OR Index > UBOUND(__fzxBody) THEN EXIT SUB
  SELECT CASE Parameter
    CASE cFZX_PARAMETER_POSITION:
      fzxVector2DSet __fzxBody(Index).fzx.position, arg1, arg2
    CASE cFZX_PARAMETER_VELOCITY:
      fzxVector2DSet __fzxBody(Index).fzx.velocity, arg1, arg2
    CASE cFZX_PARAMETER_FORCE:
      fzxVector2DSet __fzxBody(Index).fzx.force, arg1, arg2
    CASE cFZX_PARAMETER_ANGULARVELOCITY:
      __fzxBody(Index).fzx.angularVelocity = arg1
    CASE cFZX_PARAMETER_TORQUE:
      __fzxBody(Index).fzx.torque = arg1
    CASE cFZX_PARAMETER_ORIENT:
      __fzxBody(Index).fzx.orient = arg1
      fzxMatrix2x2SetRadians __fzxBody(Index).shape.u, __fzxBody(Index).fzx.orient
    CASE cFZX_PARAMETER_STATICFRICTION:
      __fzxBody(Index).fzx.staticFriction = arg1
    CASE cFZX_PARAMETER_DYNAMICFRICTION:
      __fzxBody(Index).fzx.dynamicFriction = arg1
    CASE cFZX_PARAMETER_RESTITUTION:
      __fzxBody(Index).fzx.restitution = arg1
    CASE cFZX_PARAMETER_COLOR:
      __fzxBody(Index).c = arg1
    CASE cFZX_PARAMETER_ENABLE:
      __fzxBody(Index).enable = arg1
    CASE cFZX_PARAMETER_STATIC:
      fzxBodySetStatic Index, arg1
    CASE cFZX_PARAMETER_TEXTURE:
      __fzxBody(Index).shape.texture = arg1
    CASE cFZX_PARAMETER_FLIPTEXTURE: 'does the texture flip directions when moving left or right
      __fzxBody(Index).shape.flipTexture = arg1
    CASE cFZX_PARAMETER_SCALETEXTURE:
      __fzxBody(Index).shape.scaleTexture.x = arg1
      __fzxBody(Index).shape.scaleTexture.y = arg2
    CASE cFZX_PARAMETER_OFFSETTEXTURE:
      __fzxBody(Index).shape.offsetTexture.x = arg1
      __fzxBody(Index).shape.offsetTexture.y = arg2
    CASE cFZX_PARAMETER_COLLISIONMASK:
      __fzxBody(Index).collisionMask = arg1
    CASE cFZX_PARAMETER_INVERTNORMALS:
      IF arg1 THEN fzxPolygonInvertNormals Index
    CASE cFZX_PARAMETER_NOPHYSICS:
      __fzxBody(Index).noPhysics = arg1
    CASE cFZX_PARAMETER_SPECIALFUNCTION:
      __fzxBody(Index).specFunc.func = arg1
      __fzxBody(Index).specFunc.arg = arg2
    CASE cFZX_PARAMETER_RENDERORDER:
      __fzxBody(Index).shape.renderOrder = arg1
    CASE cFZX_PARAMETER_ENTITYID:
      __fzxBody(Index).entityID = arg1
    CASE cFZX_PARAMETER_LIFETIME:
      __fzxBody(Index).lifetime.start = TIMER(.001)
      __fzxBody(Index).lifetime.duration = arg1
    CASE cFZX_PARAMETER_REPEATTEXTURE
      IF __fzxBody(Index).shape.uv0.x <> 0 THEN __fzxBody(Index).shape.uv0.x = arg1
      IF __fzxBody(Index).shape.uv0.y <> 0 THEN __fzxBody(Index).shape.uv0.y = arg2
      IF __fzxBody(Index).shape.uv1.x <> 0 THEN __fzxBody(Index).shape.uv1.x = arg1
      IF __fzxBody(Index).shape.uv1.y <> 0 THEN __fzxBody(Index).shape.uv1.y = arg2
      IF __fzxBody(Index).shape.uv2.x <> 0 THEN __fzxBody(Index).shape.uv2.x = arg1
      IF __fzxBody(Index).shape.uv2.y <> 0 THEN __fzxBody(Index).shape.uv2.y = arg2
      IF __fzxBody(Index).shape.uv3.x <> 0 THEN __fzxBody(Index).shape.uv3.x = arg1
      IF __fzxBody(Index).shape.uv3.y <> 0 THEN __fzxBody(Index).shape.uv3.y = arg2
    CASE cFZX_PARAMETER_ZPOSITION
      __fzxBody(Index).zPosition = arg1
    CASE cFZX_PARAMETER_UV0
      fzxVector2DSet __fzxBody(Index).shape.uv0, arg1, arg2
    CASE cFZX_PARAMETER_UV1
      fzxVector2DSet __fzxBody(Index).shape.uv1, arg1, arg2
    CASE cFZX_PARAMETER_UV2
      fzxVector2DSet __fzxBody(Index).shape.uv2, arg1, arg2
    CASE cFZX_PARAMETER_UV3
      fzxVector2DSet __fzxBody(Index).shape.uv3, arg1, arg2

  END SELECT
END SUB

SUB fzxSetBodyEx (parameter AS LONG, objName AS STRING, arg1 AS DOUBLE, arg2 AS DOUBLE)
  DIM index AS LONG
  index = fzxBodyManagerID(objName)
  IF index > -1 THEN
    fzxSetBody parameter, index, arg1, arg2
  END IF
END SUB


FUNCTION fzxGetBodyD# (Parameter AS LONG, Index AS LONG, arg AS _BYTE)
  'CONST cFZX_ARGUMENT_X = 1
  'CONST cFZX_ARGUMENT_Y = 2
  IF Index < 0 OR Index > UBOUND(__fzxBody) THEN EXIT FUNCTION
  SELECT CASE Parameter
    CASE cFZX_PARAMETER_POSITION:
      IF arg = cFZX_ARGUMENT_X THEN
        fzxGetBodyD = __fzxBody(Index).fzx.position.x
      ELSE
        fzxGetBodyD = __fzxBody(Index).fzx.position.y
      END IF
    CASE cFZX_PARAMETER_VELOCITY:
      IF arg = cFZX_ARGUMENT_X THEN
        fzxGetBodyD = __fzxBody(Index).fzx.velocity.x
      ELSE
        fzxGetBodyD = __fzxBody(Index).fzx.velocity.y
      END IF
    CASE cFZX_PARAMETER_FORCE:
      IF arg = cFZX_ARGUMENT_X THEN
        fzxGetBodyD = __fzxBody(Index).fzx.force.x
      ELSE
        fzxGetBodyD = __fzxBody(Index).fzx.force.y
      END IF
    CASE cFZX_PARAMETER_ANGULARVELOCITY:
      fzxGetBodyD = __fzxBody(Index).fzx.angularVelocity
    CASE cFZX_PARAMETER_TORQUE:
      fzxGetBodyD = __fzxBody(Index).fzx.torque
    CASE cFZX_PARAMETER_ORIENT:
      fzxGetBodyD = __fzxBody(Index).fzx.orient
    CASE cFZX_PARAMETER_STATICFRICTION:
      fzxGetBodyD = __fzxBody(Index).fzx.staticFriction
    CASE cFZX_PARAMETER_DYNAMICFRICTION:
      fzxGetBodyD = __fzxBody(Index).fzx.dynamicFriction
    CASE cFZX_PARAMETER_RESTITUTION:
      fzxGetBodyD = __fzxBody(Index).fzx.restitution
    CASE cFZX_PARAMETER_COLOR:
      '__fzxBody(Index).c = arg1
    CASE cFZX_PARAMETER_ENABLE:
      '__fzxBody(Index).enable = arg1
    CASE cFZX_PARAMETER_STATIC:
      'fzxBodySetStatic Index, arg1
    CASE cFZX_PARAMETER_TEXTURE:
      '__fzxBody(Index).shape.texture = arg1
    CASE cFZX_PARAMETER_FLIPTEXTURE: 'does the texture flip directions when moving left or right
      '__fzxBody(Index).shape.flipTexture = arg1
    CASE cFZX_PARAMETER_SCALETEXTURE:
      '__fzxBody(Index).shape.scaleTexture.x = arg1
      '__fzxBody(Index).shape.scaleTexture.y = arg2
    CASE cFZX_PARAMETER_OFFSETTEXTURE:
      '__fzxBody(Index).shape.offsetTexture.x = arg1
      '__fzxBody(Index).shape.offsetTexture.y = arg2
    CASE cFZX_PARAMETER_COLLISIONMASK:
      '__fzxBody(Index).collisionMask = arg1
    CASE cFZX_PARAMETER_INVERTNORMALS:
      'IF arg1 THEN fzxPolygonInvertNormals Index
    CASE cFZX_PARAMETER_NOPHYSICS:
      '__fzxBody(Index).noPhysics = arg1
    CASE cFZX_PARAMETER_SPECIALFUNCTION:
      '__fzxBody(Index).specFunc.func = arg1
      '__fzxBody(Index).specFunc.arg = arg2
    CASE cFZX_PARAMETER_RENDERORDER:
      '__fzxBody(Index).shape.renderOrder = arg1
    CASE cFZX_PARAMETER_ENTITYID:
      '__fzxBody(Index).entityID = arg1
    CASE cFZX_PARAMETER_LIFETIME:
      '__fzxBody(Index).lifetime.start = TIMER(.001)
      '__fzxBody(Index).lifetime.duration = arg1
    CASE cFZX_PARAMETER_REPEATTEXTURE
      'IF __fzxBody(Index).shape.uv0.x <> 0 THEN __fzxBody(Index).shape.uv0.x = arg1
      'IF __fzxBody(Index).shape.uv0.y <> 0 THEN __fzxBody(Index).shape.uv0.y = arg2
      'IF __fzxBody(Index).shape.uv1.x <> 0 THEN __fzxBody(Index).shape.uv1.x = arg1
      'IF __fzxBody(Index).shape.uv1.y <> 0 THEN __fzxBody(Index).shape.uv1.y = arg2
      'IF __fzxBody(Index).shape.uv2.x <> 0 THEN __fzxBody(Index).shape.uv2.x = arg1
      'IF __fzxBody(Index).shape.uv2.y <> 0 THEN __fzxBody(Index).shape.uv2.y = arg2
      'IF __fzxBody(Index).shape.uv3.x <> 0 THEN __fzxBody(Index).shape.uv3.x = arg1
      'IF __fzxBody(Index).shape.uv3.y <> 0 THEN __fzxBody(Index).shape.uv3.y = arg2
    CASE cFZX_PARAMETER_ZPOSITION
      '__fzxBody(Index).zPosition = arg1
    CASE cFZX_PARAMETER_UV0
      'fzxVector2DSet __fzxBody(Index).shape.uv0, arg1, arg2
    CASE cFZX_PARAMETER_UV1
      'fzxVector2DSet __fzxBody(Index).shape.uv1, arg1, arg2
    CASE cFZX_PARAMETER_UV2
      'fzxVector2DSet __fzxBody(Index).shape.uv2, arg1, arg2
    CASE cFZX_PARAMETER_UV3
      'fzxVector2DSet __fzxBody(Index).shape.uv3, arg1, arg2
    CASE CFZX_PARAMETER_POLYCOUNT
      fzxGetBodyD = __fzxBody(Index).pa.count
  END SELECT

END FUNCTION

SUB fzxBodyStop (index AS LONG)
  fzxVector2DSet __fzxBody(index).fzx.velocity, 0, 0
  __fzxBody(index).fzx.angularVelocity = 0
  fzxVector2DSet __fzxBody(index).fzx.force, 0, 0
  __fzxBody(index).fzx.torque = 0
END SUB

SUB fzxBodyOffset (index AS LONG, vec AS tFZX_VECTOR2d)
  DIM i AS LONG
  FOR i = 0 TO __fzxBody(index).pa.count
    fzxSetBodyVertXY index, i, fzxGetBodyVertX(index, i) + vec.x, fzxGetBodyVertY(index, i) + vec.y
  NEXT
END SUB

SUB fzxBodySetStatic (index AS LONG, arg AS LONG)
  __fzxBody(index).fzx.isStatic = arg
  __fzxBody(index).fzx.inertia = 0.0
  __fzxBody(index).fzx.invInertia = 0.0
  __fzxBody(index).fzx.mass = 0.0
  __fzxBody(index).fzx.invMass = 0.0
END SUB

FUNCTION fzxBodyAtRest (index AS LONG, minVel AS DOUBLE)
  fzxBodyAtRest = (__fzxBody(index).fzx.velocity.x < minVel AND __fzxBody(index).fzx.velocity.x > -minVel AND __fzxBody(index).fzx.velocity.y < minVel AND __fzxBody(index).fzx.velocity.y > -minVel)
END FUNCTION

SUB fzxCopyBodies (body() AS tFZX_BODY, newBody() AS tFZX_BODY)
  DIM AS LONG index
  FOR index = 0 TO UBOUND(body)
    newBody(index) = body(index)
  NEXT
END SUB

'**********************************************************************************************
'   Misc
'**********************************************************************************************

SUB _______________MORE_MISC_FUNCTIONS: END SUB

FUNCTION fzxArrayNextIndex (i AS LONG, count AS LONG)
  fzxArrayNextIndex = ((i + 1) MOD (count + 1))
END FUNCTION
'**********************************************************************************************
'   Physics Collision Calculations
'**********************************************************************************************
SUB _______________COLLISION_FUNCTIONS: END SUB

SUB fzxCollisionCCHandle (m AS tFZX_MANIFOLD, contacts() AS tFZX_VECTOR2d, A AS LONG, B AS LONG)
  DIM normal AS tFZX_VECTOR2d
  DIM dist_sqr AS DOUBLE
  DIM radius AS DOUBLE
  DIM distance AS DOUBLE

  fzxVector2DSubVectorND normal, __fzxBody(B).fzx.position, __fzxBody(A).fzx.position ' Subtract two vectors position A and position
  dist_sqr = fzxVector2DLengthSq(normal) ' Calculate the distance between the balls or circles
  radius = __fzxBody(A).shape.radius + __fzxBody(B).shape.radius ' Add both circle A and circle B radius

  IF (dist_sqr >= radius * radius) THEN
    m.contactCount = 0
  ELSE
    distance = SQR(dist_sqr)
    m.contactCount = 1
    IF distance = 0 THEN
      m.penetration = __fzxBody(A).shape.radius
      fzxVector2DSet m.normal, 1.0, 0.0
      fzxVector2dSetVector contacts(0), __fzxBody(A).fzx.position
    ELSE
      m.penetration = radius - distance
      fzxVector2DDivideScalarND m.normal, normal, distance
      fzxVector2DMultiplyScalarND contacts(0), m.normal, __fzxBody(A).shape.radius
      fzxVector2DAddVector contacts(0), __fzxBody(A).fzx.position
    END IF
  END IF
END SUB

SUB fzxCollisionPCHandle (m AS tFZX_MANIFOLD, contacts() AS tFZX_VECTOR2d, A AS LONG, B AS LONG)
  fzxCollisionCPHandle m, contacts(), B, A
  IF m.contactCount > 0 THEN
    fzxVector2dNeg m.normal
  END IF
END SUB

SUB fzxCollisionCPHandle (m AS tFZX_MANIFOLD, contacts() AS tFZX_VECTOR2d, A AS LONG, B AS LONG)
  'A is the Circle
  'B is the POLY
  m.contactCount = 0
  DIM center AS tFZX_VECTOR2d
  DIM tm AS tFZX_MATRIX2D
  DIM tv AS tFZX_VECTOR2d
  DIM ARadius AS DOUBLE: ARadius = __fzxBody(A).shape.radius
  DIM AS tFZX_VECTOR2d tempV, tempN

  fzxVector2DSubVectorND center, __fzxBody(A).fzx.position, __fzxBody(B).fzx.position
  fzxMatrix2x2Transpose __fzxBody(B).shape.u, tm
  fzxMatrix2x2MultiplyVector tm, center, center

  DIM separation AS DOUBLE: separation = -9999999
  DIM faceNormal AS LONG: faceNormal = 0
  DIM i AS LONG
  DIM s AS DOUBLE
  FOR i = 0 TO __fzxBody(B).pa.count
    fzxGetBodyVert B, i, tempV
    fzxVector2DSubVectorND tv, center, tempV
    fzxGetBodyNorm B, i, tempN
    s = fzxVector2DDot(tempN, tv)
    IF s > ARadius THEN EXIT SUB
    IF s > separation THEN
      separation = s
      faceNormal = i
    END IF
  NEXT
  DIM v1 AS tFZX_VECTOR2d
  fzxGetBodyVert B, faceNormal, v1
  DIM v2 AS tFZX_VECTOR2d
  fzxGetBodyVert B, fzxArrayNextIndex(faceNormal, __fzxBody(B).pa.count), v2


  IF separation < cFZX_EPSILON THEN
    m.contactCount = 1
    fzxGetBodyNorm B, faceNormal, tempN
    fzxMatrix2x2MultiplyVector __fzxBody(B).shape.u, tempN, m.normal
    fzxVector2dNeg m.normal
    fzxVector2DMultiplyScalarND contacts(0), m.normal, ARadius
    fzxVector2DAddVector contacts(0), __fzxBody(A).fzx.position
    m.penetration = ARadius
    EXIT SUB
  END IF

  DIM dot1 AS DOUBLE
  DIM dot2 AS DOUBLE

  DIM tv1 AS tFZX_VECTOR2d
  DIM tv2 AS tFZX_VECTOR2d
  DIM n AS tFZX_VECTOR2d
  fzxVector2DSubVectorND tv1, center, v1
  fzxVector2DSubVectorND tv2, v2, v1
  dot1 = fzxVector2DDot(tv1, tv2)
  fzxVector2DSubVectorND tv1, center, v2
  fzxVector2DSubVectorND tv2, v1, v2
  dot2 = fzxVector2DDot(tv1, tv2)
  m.penetration = ARadius - separation
  IF dot1 <= 0.0 THEN
    IF fzxVector2DSqDist(center, v1) > ARadius * ARadius THEN EXIT SUB
    m.contactCount = 1
    fzxVector2DSubVectorND n, v1, center
    fzxMatrix2x2MultiplyVector __fzxBody(B).shape.u, n, n
    fzxVector2DNormalize n
    m.normal = n
    fzxMatrix2x2MultiplyVector __fzxBody(B).shape.u, v1, v1
    fzxVector2DAddVectorND v1, v1, __fzxBody(B).fzx.position
    contacts(0) = v1
  ELSE
    IF dot2 <= 0.0 THEN
      IF fzxVector2DSqDist(center, v2) > ARadius * ARadius THEN EXIT SUB
      m.contactCount = 1
      fzxVector2DSubVectorND n, v2, center
      fzxMatrix2x2MultiplyVector __fzxBody(B).shape.u, v2, v2
      fzxVector2DAddVectorND v2, v2, __fzxBody(B).fzx.position
      contacts(0) = v2
      fzxMatrix2x2MultiplyVector __fzxBody(B).shape.u, n, n
      fzxVector2DNormalize n
      m.normal = n
    ELSE
      fzxGetBodyNorm B, faceNormal, n
      fzxVector2DSubVectorND tv1, center, v1
      IF fzxVector2DDot(tv1, n) > ARadius THEN EXIT SUB
      m.contactCount = 1
      fzxMatrix2x2MultiplyVector __fzxBody(B).shape.u, n, n
      fzxVector2dNeg n
      m.normal = n
      fzxVector2DMultiplyScalarND contacts(0), m.normal, ARadius
      fzxVector2DAddVector contacts(0), __fzxBody(A).fzx.position
    END IF
  END IF
END SUB

FUNCTION fzxCollisionPPClip (n AS tFZX_VECTOR2d, c AS DOUBLE, face() AS tFZX_VECTOR2d)
  DIM sp AS LONG: sp = 0
  DIM o(10) AS tFZX_VECTOR2d

  o(0) = face(0)
  o(1) = face(1)

  DIM d1 AS DOUBLE: d1 = fzxVector2DDot(n, face(0)) - c
  DIM d2 AS DOUBLE: d2 = fzxVector2DDot(n, face(1)) - c

  IF d1 <= 0.0 THEN
    o(sp) = face(0)
    sp = sp + 1
  END IF

  IF d2 <= 0.0 THEN
    o(sp) = face(1)
    sp = sp + 1
  END IF

  IF d1 * d2 < 0.0 THEN
    DIM alpha AS DOUBLE: alpha = d1 / (d1 - d2)
    DIM tempv AS tFZX_VECTOR2d
    fzxVector2DSubVectorND tempv, face(1), face(0)
    fzxVector2DMultiplyScalar tempv, alpha
    fzxVector2DAddVectorND o(sp), tempv, face(0)
    sp = sp + 1
  END IF
  face(0) = o(0)
  face(1) = o(1)
  fzxCollisionPPClip = sp
END FUNCTION

SUB fzxCollisionPPFindIncidentFace (v() AS tFZX_VECTOR2d, RefPoly AS LONG, IncPoly AS LONG, referenceIndex AS LONG)
  DIM referenceNormal AS tFZX_VECTOR2d
  DIM uRef AS tFZX_MATRIX2D: uRef = __fzxBody(RefPoly).shape.u
  DIM uInc AS tFZX_MATRIX2D: uInc = __fzxBody(IncPoly).shape.u
  DIM uTemp AS tFZX_MATRIX2D
  DIM i AS LONG

  fzxGetBodyNorm RefPoly, referenceIndex, referenceNormal

  ' Calculate normal in incident's frame of reference
  ' To world space
  fzxMatrix2x2MultiplyVector uRef, referenceNormal, referenceNormal
  ' To incident's model space
  fzxMatrix2x2Transpose uInc, uTemp
  fzxMatrix2x2MultiplyVector uTemp, referenceNormal, referenceNormal

  DIM incidentFace AS LONG: incidentFace = 0
  DIM minDot AS DOUBLE: minDot = 9999999
  DIM dot AS DOUBLE
  DIM AS tFZX_VECTOR2d tempN, tempV
  FOR i = 0 TO __fzxBody(IncPoly).pa.count
    fzxGetBodyNorm IncPoly, i, tempN
    dot = fzxVector2DDot(referenceNormal, tempN)
    IF (dot < minDot) THEN
      minDot = dot
      incidentFace = i
    END IF
  NEXT

  '// Assign face vertices for incidentFace
  fzxGetBodyVert IncPoly, incidentFace, tempV
  fzxMatrix2x2MultiplyVector uInc, tempV, v(0)
  fzxVector2DAddVector v(0), __fzxBody(IncPoly).fzx.position

  incidentFace = fzxArrayNextIndex(incidentFace, __fzxBody(IncPoly).pa.count)

  fzxGetBodyVert IncPoly, incidentFace, tempV
  fzxMatrix2x2MultiplyVector uInc, tempV, v(1)
  fzxVector2DAddVector v(1), __fzxBody(IncPoly).fzx.position
END SUB

SUB fzxCollisionPPHandle (m AS tFZX_MANIFOLD, contacts() AS tFZX_VECTOR2d, A AS LONG, B AS LONG)
  m.contactCount = 0
  DIM faceA(100) AS LONG

  DIM penetrationA AS DOUBLE
  penetrationA = fzxCollisionPPFindAxisLeastPenetration(faceA(), A, B)
  IF penetrationA >= 0.0 THEN EXIT SUB

  DIM faceB(100) AS LONG

  DIM penetrationB AS DOUBLE
  penetrationB = fzxCollisionPPFindAxisLeastPenetration(faceB(), B, A)
  IF penetrationB >= 0.0 THEN EXIT SUB


  DIM referenceIndex AS LONG
  DIM flip AS LONG

  DIM RefPoly AS LONG
  DIM IncPoly AS LONG

  IF fzxImpulseGT(penetrationA, penetrationB) THEN
    RefPoly = A
    IncPoly = B
    referenceIndex = faceA(0)
    flip = 0
  ELSE
    RefPoly = B
    IncPoly = A
    referenceIndex = faceB(0)
    flip = 1
  END IF

  DIM incidentFace(2) AS tFZX_VECTOR2d

  fzxCollisionPPFindIncidentFace incidentFace(), RefPoly, IncPoly, referenceIndex
  DIM v1 AS tFZX_VECTOR2d
  DIM v2 AS tFZX_VECTOR2d
  DIM v1t AS tFZX_VECTOR2d
  DIM v2t AS tFZX_VECTOR2d

  fzxGetBodyVert RefPoly, referenceIndex, v1
  referenceIndex = fzxArrayNextIndex(referenceIndex, __fzxBody(RefPoly).pa.count)

  fzxGetBodyVert RefPoly, referenceIndex, v2
  ' Transform vertices to world space
  fzxMatrix2x2MultiplyVector __fzxBody(RefPoly).shape.u, v1, v1t
  fzxVector2DAddVectorND v1, v1t, __fzxBody(RefPoly).fzx.position
  fzxMatrix2x2MultiplyVector __fzxBody(RefPoly).shape.u, v2, v2t
  fzxVector2DAddVectorND v2, v2t, __fzxBody(RefPoly).fzx.position

  ' Calculate reference face side normal in world space
  DIM sidePlaneNormal AS tFZX_VECTOR2d
  fzxVector2DSubVectorND sidePlaneNormal, v2, v1
  fzxVector2DNormalize sidePlaneNormal

  ' Orthogonalize

  DIM refFaceNormal AS tFZX_VECTOR2d
  fzxVector2DSet refFaceNormal, sidePlaneNormal.y, -sidePlaneNormal.x

  ' ax + by = c
  ' c is distance from origin
  DIM refC AS DOUBLE: refC = fzxVector2DDot(refFaceNormal, v1)
  DIM negSide AS DOUBLE: negSide = -fzxVector2DDot(sidePlaneNormal, v1)
  DIM posSide AS DOUBLE: posSide = fzxVector2DDot(sidePlaneNormal, v2)


  ' Clip incident face to reference face side planes

  DIM negSidePlaneNormal AS tFZX_VECTOR2d
  fzxVector2DNegND negSidePlaneNormal, sidePlaneNormal

  IF fzxCollisionPPClip(negSidePlaneNormal, negSide, incidentFace()) < 2 THEN EXIT SUB
  IF fzxCollisionPPClip(sidePlaneNormal, posSide, incidentFace()) < 2 THEN EXIT SUB

  fzxVector2DSet m.normal, refFaceNormal.x, refFaceNormal.y
  IF flip THEN fzxVector2dNeg m.normal

  ' Keep points behind reference face
  DIM cp AS LONG: cp = 0 ' clipped points behind reference face
  DIM separation AS DOUBLE
  separation = fzxVector2DDot(refFaceNormal, incidentFace(0)) - refC
  IF separation <= 0.0 THEN
    contacts(cp) = incidentFace(0)
    m.penetration = -separation
    cp = cp + 1
  ELSE
    m.penetration = 0
  END IF

  separation = fzxVector2DDot(refFaceNormal, incidentFace(1)) - refC
  IF separation <= 0.0 THEN
    contacts(cp) = incidentFace(1)
    m.penetration = m.penetration + -separation
    cp = cp + 1
    m.penetration = m.penetration / cp
  END IF
  m.contactCount = cp
END SUB

FUNCTION fzxCollisionPPFindAxisLeastPenetration (faceIndex() AS LONG, A AS LONG, B AS LONG)
  DIM bestDistance AS DOUBLE: bestDistance = -9999999
  DIM bestIndex AS LONG: bestIndex = 0

  DIM n AS tFZX_VECTOR2d
  DIM nw AS tFZX_VECTOR2d
  DIM buT AS tFZX_MATRIX2D
  DIM s AS tFZX_VECTOR2d
  DIM nn AS tFZX_VECTOR2d
  DIM v AS tFZX_VECTOR2d
  DIM tv AS tFZX_VECTOR2d
  DIM d AS DOUBLE
  DIM i AS LONG

  i = 0: DO WHILE i <= __fzxBody(A).pa.count

    ' Retrieve a face normal from A

    fzxGetBodyNorm A, i, n
    fzxMatrix2x2MultiplyVector __fzxBody(A).shape.u, n, nw

    ' Transform face normal into B's model space
    fzxMatrix2x2Transpose __fzxBody(B).shape.u, buT
    fzxMatrix2x2MultiplyVector buT, nw, n

    ' Retrieve support point from B along -n

    fzxVector2DNegND nn, n
    fzxVector2DGetSupport B, nn, s

    ' Retrieve vertex on face from A, transform into
    ' B's model space

    fzxGetBodyVert A, i, v
    fzxMatrix2x2MultiplyVector __fzxBody(A).shape.u, v, tv
    fzxVector2DAddVectorND v, tv, __fzxBody(A).fzx.position

    fzxVector2DSubVector v, __fzxBody(B).fzx.position
    fzxMatrix2x2MultiplyVector buT, v, tv

    fzxVector2DSubVector s, tv
    d = fzxVector2DDot(n, s)

    IF d > bestDistance THEN
      bestDistance = d
      bestIndex = i
    END IF

  i = i + 1: LOOP

  faceIndex(0) = bestIndex

  fzxCollisionPPFindAxisLeastPenetration = bestDistance
END FUNCTION

'**********************************************************************************************
'   Physics Impulse Calculations
'**********************************************************************************************
SUB _______________PHYSICS_IMPULSE_MATH: END SUB

SUB fzxImpulseIntegrateForces (index AS LONG, dt AS DOUBLE)
  IF __fzxBody(index).fzx.invMass = 0.0 THEN EXIT SUB
  DIM dts AS DOUBLE
  dts = dt * .5
  fzxVector2DAddVectorScalar __fzxBody(index).fzx.velocity, __fzxBody(index).fzx.force, __fzxBody(index).fzx.invMass * dts
  fzxVector2DAddVectorScalar __fzxBody(index).fzx.velocity, __fzxWorld.gravity, dts
  __fzxBody(index).fzx.angularVelocity = __fzxBody(index).fzx.angularVelocity + (__fzxBody(index).fzx.torque * __fzxBody(index).fzx.invInertia * dts)
END SUB

SUB fzxImpulseIntegrateVelocity (index AS LONG, dt AS DOUBLE)
  IF __fzxBody(index).fzx.invMass = 0.0 THEN EXIT SUB
  fzxVector2DAddVectorScalar __fzxBody(index).fzx.position, __fzxBody(index).fzx.velocity, dt
  __fzxBody(index).fzx.orient = __fzxBody(index).fzx.orient + (__fzxBody(index).fzx.angularVelocity * dt)
  fzxMatrix2x2SetRadians __fzxBody(index).shape.u, __fzxBody(index).fzx.orient
  fzxImpulseIntegrateForces index, dt
END SUB

SUB fzxImpulseStep (dt AS DOUBLE, iterations AS LONG)
  DIM AS LONG uB: uB = UBOUND(__fzxBody)
  DIM AS LONG uJ: uJ = UBOUND(__fzxJoints)
  DIM AS LONG uH: uH = UBOUND(__fzxHits)
  DIM A AS tFZX_BODY
  DIM B AS tFZX_BODY
  DIM contacts(uB) AS tFZX_VECTOR2d
  DIM m AS tFZX_MANIFOLD
  DIM manifolds(uB * uB) AS tFZX_MANIFOLD
  DIM collisions(uB * uB, uB) AS tFZX_VECTOR2d
  DIM AS tFZX_VECTOR2d tv, tv1
  DIM AS DOUBLE d
  DIM AS LONG mval
  DIM manifoldCount AS LONG: manifoldCount = 0
  '    // Generate new collision info
  DIM AS LONG i, j, k, index
  DIM hitCount AS LONG: hitCount = 0

  i = 0: DO WHILE i <= uH
    __fzxHits(i).A = -1
    __fzxHits(i).B = -1
  i = i + 1: LOOP

  hitCount = 0

  i = 0: DO WHILE i < uB
    A = __fzxBody(i)
    IF A.enable THEN
      j = i + 1: DO WHILE j < uB
        B = __fzxBody(j)
        ' B enabled ?
        IF B.enable THEN
          ' Can they Collide?
          IF (A.collisionMask AND B.collisionMask) THEN
            ' Static Objects ?
            IF NOT (A.fzx.invMass = 0.0 AND B.fzx.invMass = 0.0) THEN
              'Mainfold solve - handle collisions
              IF fzxAABBOverlapObjects(i, j) THEN
                IF A.shape.ty = cFZX_SHAPE_CIRCLE AND B.shape.ty = cFZX_SHAPE_CIRCLE THEN
                  fzxCollisionCCHandle m, contacts(), i, j
                ELSE
                  IF A.shape.ty = cFZX_SHAPE_POLYGON AND B.shape.ty = cFZX_SHAPE_POLYGON THEN
                    fzxCollisionPPHandle m, contacts(), i, j
                  ELSE
                    IF A.shape.ty = cFZX_SHAPE_CIRCLE AND B.shape.ty = cFZX_SHAPE_POLYGON THEN
                      fzxCollisionCPHandle m, contacts(), i, j
                    ELSE
                      IF B.shape.ty = cFZX_SHAPE_CIRCLE AND A.shape.ty = cFZX_SHAPE_POLYGON THEN
                        fzxCollisionPCHandle m, contacts(), i, j
                      END IF
                    END IF
                  END IF
                END IF
                IF m.contactCount > 0 THEN
                  m.A = i
                  m.B = j
                  manifolds(manifoldCount) = m
                  k = 0: DO WHILE k <= m.contactCount
                    __fzxHits(hitCount).A = i
                    __fzxHits(hitCount).B = j
                    __fzxHits(hitCount).position = contacts(k)
                    collisions(manifoldCount, k) = contacts(k)
                    hitCount = hitCount + 1
                    IF hitCount > UBOUND(__fzxHits) THEN REDIM _PRESERVE __fzxHits(hitCount * 1.5) AS tFZX_HIT
                  k = k + 1: LOOP
                  manifoldCount = manifoldCount + 1
                  IF manifoldCount > UBOUND(manifolds) THEN REDIM _PRESERVE manifolds(manifoldCount * 1.5) AS tFZX_MANIFOLD
                END IF
              END IF
            END IF
          END IF
        END IF
      j = j + 1: LOOP
    END IF
  i = i + 1: LOOP


  '    Integrate forces
  i = 0: DO WHILE i <= uB
    IF __fzxBody(i).enable AND __fzxBody(i).noPhysics = 0 THEN fzxImpulseIntegrateForces i, dt
  i = i + 1: LOOP
  '    Initialize collision
  i = 0: DO WHILE i < manifoldCount
    k = 0: DO WHILE k < manifolds(i).contactCount
      contacts(k) = collisions(i, k)
    k = k + 1: LOOP
    fzxManifoldInit manifolds(i), contacts()
  i = i + 1: LOOP

  ' joint pre Steps
  i = 0: DO WHILE i <= uJ
    IF __fzxJoints(i).overwrite = 0 THEN fzxJointPrestep i, dt
  i = i + 1: LOOP

  ' Solve collisions
  j = 0: DO WHILE j < iterations:
    i = 0: DO WHILE i < manifoldCount
      k = 0: DO WHILE k < manifolds(i).contactCount
        contacts(k) = collisions(i, k)
      k = k + 1: LOOP
      fzxManifoldApplyImpulse manifolds(i), contacts()
      'store the hit speed for later
      k = 0: DO WHILE k < hitCount
        IF manifolds(i).A = __fzxHits(k).A AND manifolds(i).B = __fzxHits(k).B THEN
          __fzxHits(k).cv = manifolds(i).cv
        END IF
      k = k + 1: LOOP
    i = i + 1: LOOP


    i = 0: DO WHILE i <= uJ
      IF __fzxJoints(i).overwrite = 0 THEN fzxJointApplyImpulse i
    i = i + 1: LOOP

    ' It appears that the joint bias is analgous to the stress the
    ' joint has on it.
    ' Lets give those wireframe joints some color.
    ' If that stress is greater than the max then break the joint

    index = 0: DO
      IF __fzxJoints(index).overwrite = 0 THEN
        IF __fzxJoints(index).max_bias > 0 THEN
          fzxVector2dSetVector tv, __fzxJoints(index).bias
          fzxVector2DSet tv1, 0, 0
          d = fzxVector2DDistance(tv, tv1)
          mval = fzxScalarMap(d, 0, __fzxJoints(index).max_bias * .7, 0, 255)
          __fzxJoints(index).wireframe_color = _RGB32(mval, 255 - mval, 0)
          IF d > __fzxJoints(index).max_bias THEN
            fzxJointDelete index
            uJ = UBOUND(__fzxJoints)
          END IF
        END IF
      END IF
      index = index + 1
    LOOP UNTIL index > uJ
  j = j + 1: LOOP

  '// Integrate velocities
  i = 0: DO WHILE i < uB
    IF __fzxBody(i).enable AND NOT __fzxBody(i).noPhysics THEN fzxImpulseIntegrateVelocity i, dt
  i = i + 1: LOOP
  '// Correct positions
  i = 0: DO WHILE i < manifoldCount
    fzxManifoldPositionalCorrection manifolds(i)
  i = i + 1: LOOP
  '// Clear all forces
  i = 0: DO WHILE i <= uB
    fzxVector2DSet __fzxBody(i).fzx.force, 0, 0
    __fzxBody(i).fzx.torque = 0
  i = i + 1: LOOP

  i = 0: DO WHILE i <= uB
    IF __fzxBody(i).enable THEN
      IF __fzxBody(i).fzx.position.x < __fzxWorld.minusLimit.x OR _
         __fzxBody(i).fzx.position.x > __fzxWorld.plusLimit.x OR _
         __fzxBody(i).fzx.position.y < __fzxWorld.minusLimit.y OR _
         __fzxBody(i).fzx.position.y > __fzxWorld.plusLimit.y THEN
        fzxBodyDelete i, 0
      END IF
      IF __fzxBody(i).lifetime.duration <> 0 THEN
        IF TIMER(.001) > __fzxBody(i).lifetime.duration + __fzxBody(i).lifetime.start THEN
          fzxBodyDelete i, 0
        END IF
      END IF
    END IF
  i = i + 1: LOOP

  fzxHandleFPSMain
END SUB

SUB fzxBodyApplyImpulse (index AS LONG, fzxImpulse AS tFZX_VECTOR2d, contactVector AS tFZX_VECTOR2d)
  fzxVector2DAddVectorScalar __fzxBody(index).fzx.velocity, fzxImpulse, __fzxBody(index).fzx.invMass
  __fzxBody(index).fzx.angularVelocity = __fzxBody(index).fzx.angularVelocity + __fzxBody(index).fzx.invInertia * fzxVector2DCross(contactVector, fzxImpulse)
END SUB

SUB _______________MANIFOLD_MATH_FUNCTIONS: END SUB

SUB fzxManifoldInit (m AS tFZX_MANIFOLD, contacts() AS tFZX_VECTOR2d)
  DIM ra AS tFZX_VECTOR2d
  DIM rb AS tFZX_VECTOR2d
  DIM rv AS tFZX_VECTOR2d
  DIM tv1 AS tFZX_VECTOR2d 'temporary Vectors
  DIM tv2 AS tFZX_VECTOR2d
  m.e = fzxScalarMin(__fzxBody(m.A).fzx.restitution, __fzxBody(m.B).fzx.restitution)
  m.sf = SQR(__fzxBody(m.A).fzx.staticFriction * __fzxBody(m.A).fzx.staticFriction)
  m.df = SQR(__fzxBody(m.A).fzx.dynamicFriction * __fzxBody(m.A).fzx.dynamicFriction)

  DIM i AS LONG
  FOR i = 0 TO m.contactCount - 1
    fzxVector2DSubVectorND contacts(i), __fzxBody(m.A).fzx.position, ra
    fzxVector2DSubVectorND contacts(i), __fzxBody(m.B).fzx.position, rb

    fzxVector2DCrossScalar tv1, rb, __fzxBody(m.B).fzx.angularVelocity
    fzxVector2DCrossScalar tv2, ra, __fzxBody(m.A).fzx.angularVelocity
    fzxVector2DAddVector tv1, __fzxBody(m.B).fzx.velocity
    fzxVector2DSubVectorND tv2, __fzxBody(m.A).fzx.velocity, tv2
    fzxVector2DSubVectorND rv, tv1, tv2

    IF fzxVector2DLengthSq(rv) < __fzxWorld.resting THEN
      m.e = 0.0
    END IF
  NEXT
END SUB

SUB fzxManifoldApplyImpulse (m AS tFZX_MANIFOLD, contacts() AS tFZX_VECTOR2d)
  DIM ra AS tFZX_VECTOR2d
  DIM rb AS tFZX_VECTOR2d
  DIM rv AS tFZX_VECTOR2d
  DIM tv1 AS tFZX_VECTOR2d 'temporary Vectors
  DIM tv2 AS tFZX_VECTOR2d
  DIM contactVel AS DOUBLE

  DIM raCrossN AS DOUBLE
  DIM rbCrossN AS DOUBLE
  DIM invMassSum AS DOUBLE
  DIM i AS LONG
  DIM j AS DOUBLE
  DIM fzxImpulse AS tFZX_VECTOR2d

  DIM t AS tFZX_VECTOR2d
  DIM jt AS DOUBLE
  DIM tangentImpulse AS tFZX_VECTOR2d

  IF fzxImpulseEqual(__fzxBody(m.A).fzx.invMass + __fzxBody(m.B).fzx.invMass, 0.0) THEN
    fzxManifoldInfiniteMassCorrection m.A, m.B
    EXIT SUB
  END IF

  IF (__fzxBody(m.A).noPhysics OR __fzxBody(m.B).noPhysics) THEN
    EXIT SUB
  END IF

  i = 0: DO WHILE i < m.contactCount
    '// Calculate radii from COM to contact
    fzxVector2DSubVectorND ra, contacts(i), __fzxBody(m.A).fzx.position
    fzxVector2DSubVectorND rb, contacts(i), __fzxBody(m.B).fzx.position

    '// Relative velocity

    fzxVector2DCrossScalar tv1, rb, __fzxBody(m.B).fzx.angularVelocity
    fzxVector2DCrossScalar tv2, ra, __fzxBody(m.A).fzx.angularVelocity
    fzxVector2DAddVectorND rv, tv1, __fzxBody(m.B).fzx.velocity
    fzxVector2DSubVector rv, __fzxBody(m.A).fzx.velocity
    fzxVector2DSubVector rv, tv2

    '// Relative velocity along the normal
    contactVel = fzxVector2DDot(rv, m.normal)

    '// Do not resolve if velocities are separating
    IF contactVel > 0 THEN EXIT SUB
    m.cv = contactVel

    raCrossN = fzxVector2DCross(ra, m.normal)
    rbCrossN = fzxVector2DCross(rb, m.normal)
    invMassSum = __fzxBody(m.A).fzx.invMass + __fzxBody(m.B).fzx.invMass + (raCrossN * raCrossN) * __fzxBody(m.A).fzx.invInertia + (rbCrossN * rbCrossN) * __fzxBody(m.B).fzx.invInertia


    '// Calculate Impulse Scalar
    j = -(1.0 + m.e) * contactVel
    j = j / invMassSum
    j = j / m.contactCount

    '// Apply Impulse
    fzxVector2DMultiplyScalarND fzxImpulse, m.normal, j
    fzxVector2DNegND tv1, fzxImpulse
    fzxBodyApplyImpulse m.A, tv1, ra
    fzxBodyApplyImpulse m.B, fzxImpulse, rb

    '// Friction fzxImpulse
    fzxVector2DCrossScalar tv1, rb, __fzxBody(m.B).fzx.angularVelocity
    fzxVector2DCrossScalar tv2, ra, __fzxBody(m.A).fzx.angularVelocity
    fzxVector2DAddVectorND rv, tv1, __fzxBody(m.B).fzx.velocity
    fzxVector2DSubVector rv, __fzxBody(m.A).fzx.velocity
    fzxVector2DSubVector rv, tv2

    fzxVector2DMultiplyScalarND t, m.normal, fzxVector2DDot(rv, m.normal)
    fzxVector2DSubVectorND t, rv, t
    fzxVector2DNormalize t

    '// j tangent magnitude
    jt = -fzxVector2DDot(rv, t)
    jt = jt / invMassSum
    jt = jt / m.contactCount

    '// Don't apply tiny friction fzxImpulses
    IF fzxImpulseEqual(jt, 0.0) THEN EXIT SUB

    '// Coulumb's law
    IF ABS(jt) < j * m.sf THEN
      fzxVector2DMultiplyScalarND tangentImpulse, t, jt
    ELSE
      fzxVector2DMultiplyScalarND tangentImpulse, t, -j * m.df
    END IF

    '// Apply friction fzxImpulse
    fzxVector2DNegND tv1, tangentImpulse
    fzxBodyApplyImpulse m.A, tv1, ra
    fzxBodyApplyImpulse m.B, tangentImpulse, rb
  i = i + 1: LOOP

END SUB

SUB fzxManifoldPositionalCorrection (m AS tFZX_MANIFOLD)
  IF __fzxBody(m.A).noPhysics OR __fzxBody(m.B).noPhysics THEN EXIT SUB
  DIM correction AS DOUBLE
  correction = fzxScalarMax(m.penetration - cFZX_PENETRATION_ALLOWANCE, 0.0) / (__fzxBody(m.A).fzx.invMass + __fzxBody(m.B).fzx.invMass) * cFZX_PENETRATION_CORRECTION
  fzxVector2DAddVectorScalar __fzxBody(m.A).fzx.position, m.normal, -__fzxBody(m.A).fzx.invMass * correction
  fzxVector2DAddVectorScalar __fzxBody(m.B).fzx.position, m.normal, __fzxBody(m.B).fzx.invMass * correction
END SUB

SUB fzxManifoldInfiniteMassCorrection (A AS LONG, B AS LONG)
  fzxVector2DSet __fzxBody(A).fzx.velocity, 0, 0
  fzxVector2DSet __fzxBody(B).fzx.velocity, 0, 0
END SUB

'**********************************************************************************************
'   Joint Creation
'**********************************************************************************************
SUB _______________JOINT_CREATION_FUNCTIONS: END SUB

FUNCTION fzxJointAllocate
  DIM AS LONG iter, uB, uBTemp
  ' Set uB to -1 to signal if the following code is unsuccessful at find
  ' an available joint to overwrite then allocate more space
  uB = -1

  iter = 0: DO WHILE iter <= UBOUND(__fzxJoints)
    IF __fzxJoints(iter).overwrite = 1 THEN
      fzxJointAllocate = iter
      EXIT FUNCTION
    END IF
  iter = iter + 1: LOOP

  ' If uB is still -1 then we need to allocate more array space
  ' If uB >= 0 then it found an element to overwrite and returns this value.
  IF uB < 0 THEN
    ' uBTemp should be the next element in the newly allocated array
    uBTemp = UBOUND(__fzxJoints) + 1
    ' Add 10 more elements to the __fzxJoints array, while preserving the contents
    REDIM _PRESERVE __fzxJoints(UBOUND(__fzxJoints) + 10) AS tFZX_JOINT
    ' uB is the size of the newly expanded array
    uB = UBOUND(__fzxJoints)
    ' Mark all of the newly created elements to be overwritten
    iter = uBTemp: DO WHILE iter <= uB
      __fzxJoints(iter).overwrite = 1
    iter = iter + 1: LOOP
    ' Set uB to then first element available in the newly expanded array.
    uB = uBTemp
  END IF
  fzxJointAllocate = uB
END FUNCTION

FUNCTION fzxJointCreate (b1 AS LONG, b2 AS LONG, x AS DOUBLE, y AS DOUBLE)
  IF b1 < 0 OR b1 > UBOUND(__fzxBody) OR b2 < 0 OR b2 > UBOUND(__fzxBody) THEN EXIT FUNCTION
  DIM AS LONG tempJ: tempJ = fzxJointAllocate

  fzxJointSet tempJ, b1, b2, x, y
  'Joint name will default to a combination of the two objects that is connects.
  'If you change it you must also recompute the hash.
  __fzxJoints(tempJ).jointName = _TRIM$(__fzxBody(b1).objectName) + "_" + _TRIM$(__fzxBody(b2).objectName)
  __fzxJoints(tempJ).jointHash = fzxComputeHash&&(__fzxJoints(tempJ).jointName)
  __fzxJoints(tempJ).wireframe_color = _RGB32(255, 227, 127)
  fzxJointCreate = tempJ
END FUNCTION

FUNCTION fzxJointCreateEx (b1 AS LONG, b2 AS LONG, anchor1 AS tFZX_VECTOR2d, anchor2 AS tFZX_VECTOR2d)
  IF b1 < 0 OR b1 > UBOUND(__fzxBody) OR b2 < 0 OR b2 > UBOUND(__fzxBody) THEN EXIT FUNCTION
  DIM AS LONG tempJ: tempJ = fzxJointAllocate

  fzxJointSetEx tempJ, b1, b2, anchor1, anchor2
  'Joint name will default to a combination of the two objects that is connects.
  'If you change it you must also recompute the hash.
  __fzxJoints(tempJ).jointName = _TRIM$(__fzxBody(b1).objectName) + "_" + _TRIM$(__fzxBody(b2).objectName)
  __fzxJoints(tempJ).jointHash = fzxComputeHash&&(__fzxJoints(tempJ).jointName)
  __fzxJoints(tempJ).wireframe_color = _RGB32(255, 227, 127)
  fzxJointCreateEx = tempJ
END FUNCTION

SUB fzxJointClear
  DIM AS LONG iter
  iter = 0: DO WHILE iter <= UBOUND(__fzxJoints)
    fzxJointDelete iter
  iter = iter + 1: LOOP
END SUB

SUB fzxJointDelete (d AS LONG)
  IF d >= 0 AND d <= UBOUND(__fzxJoints) THEN
    __fzxJoints(d).overwrite = 1
    __fzxJoints(d).jointName = ""
    __fzxJoints(d).jointHash = 0
  END IF
END SUB

SUB fzxJointSet (index AS LONG, b1 AS LONG, b2 AS LONG, x AS DOUBLE, y AS DOUBLE)
  IF b1 < 0 OR b1 > UBOUND(__fzxBody) OR b2 < 0 OR b2 > UBOUND(__fzxBody) THEN EXIT SUB
  DIM anchor AS tFZX_VECTOR2d
  fzxVector2DSet anchor, x, y
  DIM Rot1 AS tFZX_MATRIX2D: Rot1 = __fzxBody(b1).shape.u
  DIM Rot2 AS tFZX_MATRIX2D: Rot2 = __fzxBody(b2).shape.u
  DIM Rot1T AS tFZX_MATRIX2D: fzxMatrix2x2Transpose Rot1, Rot1T
  DIM Rot2T AS tFZX_MATRIX2D: fzxMatrix2x2Transpose Rot2, Rot2T
  DIM tv AS tFZX_VECTOR2d

  __fzxJoints(index).body1 = b1
  __fzxJoints(index).body2 = b2

  fzxVector2DSubVectorND tv, anchor, __fzxBody(b1).fzx.position
  fzxMatrix2x2MultiplyVector Rot1T, tv, __fzxJoints(index).localAnchor1

  fzxVector2DSubVectorND tv, anchor, __fzxBody(b2).fzx.position
  fzxMatrix2x2MultiplyVector Rot2T, tv, __fzxJoints(index).localAnchor2

  fzxVector2DSet __fzxJoints(index).P, 0, 0
  ' Some default Settings
  __fzxJoints(index).softness = 0.001
  __fzxJoints(index).biasFactor = 1000
  __fzxJoints(index).max_bias = -1
  __fzxJoints(index).overwrite = 0
END SUB

SUB fzxJointSetEx (index AS LONG, b1 AS LONG, b2 AS LONG, anchor1 AS tFZX_VECTOR2d, anchor2 AS tFZX_VECTOR2d)
  IF b1 < 0 OR b1 > UBOUND(__fzxBody) OR b2 < 0 OR b2 > UBOUND(__fzxBody) THEN EXIT SUB
  DIM Rot1 AS tFZX_MATRIX2D: Rot1 = __fzxBody(b1).shape.u
  DIM Rot2 AS tFZX_MATRIX2D: Rot2 = __fzxBody(b2).shape.u
  DIM Rot1T AS tFZX_MATRIX2D: fzxMatrix2x2Transpose Rot1, Rot1T
  DIM Rot2T AS tFZX_MATRIX2D: fzxMatrix2x2Transpose Rot2, Rot2T
  DIM tv AS tFZX_VECTOR2d

  __fzxJoints(index).body1 = b1
  __fzxJoints(index).body2 = b2

  fzxVector2DSubVectorND tv, anchor1, __fzxBody(b1).fzx.position
  fzxMatrix2x2MultiplyVector Rot1T, tv, __fzxJoints(index).localAnchor1

  fzxVector2DSubVectorND tv, anchor2, __fzxBody(b2).fzx.position
  fzxMatrix2x2MultiplyVector Rot2T, tv, __fzxJoints(index).localAnchor2

  fzxVector2DSet __fzxJoints(index).P, 0, 0
  ' Some default Settings
  __fzxJoints(index).softness = 0.0001
  __fzxJoints(index).biasFactor = 1000
  __fzxJoints(index).max_bias = -1
  __fzxJoints(index).overwrite = 0
END SUB


'**********************************************************************************************
'   Joint Calculations
'**********************************************************************************************

SUB _______________JOINT_MATH_FUNCTIONS: END SUB

SUB fzxJointPrestep (index AS LONG, inv_dt AS DOUBLE)
  IF __fzxJoints(index).overwrite THEN EXIT SUB
  DIM Rot1 AS tFZX_MATRIX2D: Rot1 = __fzxBody(__fzxJoints(index).body1).shape.u
  DIM Rot2 AS tFZX_MATRIX2D: Rot2 = __fzxBody(__fzxJoints(index).body2).shape.u
  DIM b1invMass AS DOUBLE
  DIM b2invMass AS DOUBLE

  DIM b1invInertia AS DOUBLE
  DIM b2invInertia AS DOUBLE

  fzxMatrix2x2MultiplyVector Rot1, __fzxJoints(index).localAnchor1, __fzxJoints(index).r1
  fzxMatrix2x2MultiplyVector Rot2, __fzxJoints(index).localAnchor2, __fzxJoints(index).r2

  b1invMass = __fzxBody(__fzxJoints(index).body1).fzx.invMass
  b2invMass = __fzxBody(__fzxJoints(index).body2).fzx.invMass

  b1invInertia = __fzxBody(__fzxJoints(index).body1).fzx.invInertia
  b2invInertia = __fzxBody(__fzxJoints(index).body2).fzx.invInertia

  DIM K1 AS tFZX_MATRIX2D
  fzxMatrix2x2SetScalar K1, b1invMass + b2invMass, 0, 0, b1invMass + b2invMass
  DIM K2 AS tFZX_MATRIX2D
     fzxMatrix2x2SetScalar K2, b1invInertia * __fzxjoints(index).r1.y * __fzxjoints(index).r1.y, -b1invInertia * __fzxjoints(index).r1.x * __fzxjoints(index).r1.y,_
                            -b1invInertia * __fzxjoints(index).r1.x * __fzxjoints(index).r1.y,  b1invInertia * __fzxjoints(index).r1.x * __fzxjoints(index).r1.x

  DIM K3 AS tFZX_MATRIX2D
     fzxMatrix2x2SetScalar K3,  b2invInertia * __fzxjoints(index).r2.y * __fzxjoints(index).r2.y, - b2invInertia * __fzxjoints(index).r2.x * __fzxjoints(index).r2.y,_
                             -b2invInertia * __fzxjoints(index).r2.x * __fzxjoints(index).r2.y,   b2invInertia * __fzxjoints(index).r2.x * __fzxjoints(index).r2.x

  DIM K AS tFZX_MATRIX2D
  fzxMatrix2x2AddMatrix K1, K2, K
  fzxMatrix2x2AddMatrix K3, K, K
  K.m00 = K.m00 + __fzxJoints(index).softness
  K.m11 = K.m11 + __fzxJoints(index).softness
  fzxMatrix2x2Invert K, __fzxJoints(index).M

  DIM p1 AS tFZX_VECTOR2d: fzxVector2DAddVectorND p1, __fzxBody(__fzxJoints(index).body1).fzx.position, __fzxJoints(index).r1
  DIM p2 AS tFZX_VECTOR2d: fzxVector2DAddVectorND p2, __fzxBody(__fzxJoints(index).body2).fzx.position, __fzxJoints(index).r2
  DIM dp AS tFZX_VECTOR2d: fzxVector2DSubVectorND dp, p2, p1

  fzxVector2DMultiplyScalarND __fzxJoints(index).bias, dp, -__fzxJoints(index).biasFactor * inv_dt
  ' vectorSet j.bias, 0, 0
  fzxVector2DSet __fzxJoints(index).P, 0, 0
END SUB

SUB fzxJointApplyImpulse (index AS LONG)
  IF __fzxJoints(index).overwrite THEN EXIT SUB
  DIM dv AS tFZX_VECTOR2d
  DIM fzxImpulse AS tFZX_VECTOR2d
  DIM cross1 AS tFZX_VECTOR2d
  DIM cross2 AS tFZX_VECTOR2d
  DIM tv AS tFZX_VECTOR2d

  'Vec2 dv = body2->velocity + Cross(body2->angularVelocity, r2) - body1->velocity - Cross(body1->angularVelocity, r1);
  fzxVector2DCrossScalar cross2, __fzxJoints(index).r2, __fzxBody(__fzxJoints(index).body2).fzx.angularVelocity
  fzxVector2DCrossScalar cross1, __fzxJoints(index).r1, __fzxBody(__fzxJoints(index).body1).fzx.angularVelocity
  fzxVector2DAddVectorND dv, __fzxBody(__fzxJoints(index).body2).fzx.velocity, cross2
  fzxVector2DSubVectorND dv, dv, __fzxBody(__fzxJoints(index).body1).fzx.velocity
  fzxVector2DSubVectorND dv, dv, cross1

  ' fzxImpulse = M * (bias - dv - softness * P);
  fzxVector2DMultiplyScalarND tv, __fzxJoints(index).P, __fzxJoints(index).softness
  fzxVector2DSubVectorND fzxImpulse, __fzxJoints(index).bias, dv
  fzxVector2DSubVectorND fzxImpulse, fzxImpulse, tv
  fzxMatrix2x2MultiplyVector __fzxJoints(index).M, fzxImpulse, fzxImpulse

  ' body1->velocity -= body1->invMass * fzxImpulse;

  fzxVector2DMultiplyScalarND tv, fzxImpulse, __fzxBody(__fzxJoints(index).body1).fzx.invMass
  fzxVector2DSubVectorND __fzxBody(__fzxJoints(index).body1).fzx.velocity, __fzxBody(__fzxJoints(index).body1).fzx.velocity, tv

  ' body1->angularVelocity -= body1->invI * Cross(r1, fzxImpulse);
  DIM crossScalar AS DOUBLE
  crossScalar = fzxVector2DCross(__fzxJoints(index).r1, fzxImpulse)
  __fzxBody(__fzxJoints(index).body1).fzx.angularVelocity = __fzxBody(__fzxJoints(index).body1).fzx.angularVelocity - __fzxBody(__fzxJoints(index).body1).fzx.invInertia * crossScalar

  fzxVector2DMultiplyScalarND tv, fzxImpulse, __fzxBody(__fzxJoints(index).body2).fzx.invMass
  fzxVector2DAddVectorND __fzxBody(__fzxJoints(index).body2).fzx.velocity, __fzxBody(__fzxJoints(index).body2).fzx.velocity, tv

  crossScalar = fzxVector2DCross(__fzxJoints(index).r2, fzxImpulse)
  __fzxBody(__fzxJoints(index).body2).fzx.angularVelocity = __fzxBody(__fzxJoints(index).body2).fzx.angularVelocity + __fzxBody(__fzxJoints(index).body2).fzx.invInertia * crossScalar

  fzxVector2DAddVectorND __fzxJoints(index).P, __fzxJoints(index).P, fzxImpulse
END SUB

'**********************************************************************************************
'   Collision Tools
'**********************************************************************************************
SUB _______________COLLISION_QUERY_TOOLS: END SUB
FUNCTION fzxIsBodyTouchingBody (A AS LONG, B AS LONG)
  DIM hitcount AS LONG: hitcount = 0
  DIM AS LONG uH: uH = UBOUND(__fzxHits)
  fzxIsBodyTouchingBody = -1
  DO WHILE hitcount <= uH '    FOR hitcount = 0 TO UBOUND(hits)
    IF __fzxHits(hitcount).A = A AND __fzxHits(hitcount).B = B THEN
      fzxIsBodyTouchingBody = hitcount
      EXIT FUNCTION
    END IF
  hitcount = hitcount + 1: LOOP
END FUNCTION

FUNCTION fzxIsBodyTouchingStatic (A AS LONG)
  DIM hitcount AS LONG: hitcount = 0
  DIM AS LONG uH: uH = UBOUND(__fzxHits)
  fzxIsBodyTouchingStatic = 0
  hitcount = 0: DO WHILE hitcount <= uH
    IF __fzxHits(hitcount).A = A THEN
      IF __fzxBody(__fzxHits(hitcount).B).fzx.mass = 0 THEN
        fzxIsBodyTouchingStatic = hitcount
        EXIT FUNCTION
      END IF
    ELSE
      IF __fzxHits(hitcount).B = A THEN
        IF __fzxBody(__fzxHits(hitcount).A).fzx.mass = 0 THEN
          fzxIsBodyTouchingStatic = hitcount
          EXIT FUNCTION
        END IF
      END IF
    END IF
  hitcount = hitcount + 1: LOOP
END FUNCTION

FUNCTION fzxIsBodyTouching (A AS LONG)
  DIM hitcount AS LONG: hitcount = 0
  DIM AS LONG uH: uH = UBOUND(__fzxHits)
  fzxIsBodyTouching = -1
  hitcount = 0: DO WHILE hitcount <= uH
    IF __fzxHits(hitcount).A = A THEN
      fzxIsBodyTouching = __fzxHits(hitcount).B
      EXIT FUNCTION
    END IF
    IF __fzxHits(hitcount).B = A THEN
      fzxIsBodyTouching = __fzxHits(hitcount).A
      EXIT FUNCTION
    END IF
  hitcount = hitcount + 1: LOOP
END FUNCTION

FUNCTION fzxHighestCollisionVelocity (hits() AS tFZX_HIT, A AS LONG) ' this function is a bit dubious and may not do as you think
  DIM hitcount AS LONG: hitcount = 0
  DIM hiCv AS DOUBLE: hiCv = 0
  DIM AS LONG uH: uH = UBOUND(hits)
  fzxHighestCollisionVelocity = 0
  hitcount = 0: DO WHILE hitcount <= uH
    IF hits(hitcount).A = A AND ABS(hits(hitcount).cv) > hiCv AND hits(hitcount).cv < 0 THEN
      hiCv = ABS(hits(hitcount).cv)
    END IF
  hitcount = hitcount + 1: LOOP
  fzxHighestCollisionVelocity = hiCv
END FUNCTION

'**********************************************************************************************
'   Body Managment Tools
'**********************************************************************************************
SUB _______________BODY_MANAGEMENT: END SUB

FUNCTION fzxBodyManagerAdd ()
  DIM AS LONG ub, iter, tempUb
  ub = UBOUND(__fzxBody)
  ' Check for any available bodies to be overwritten
  iter = 0: DO WHILE iter <= ub
    IF __fzxBody(iter).overwrite THEN
      fzxBodyManagerAdd = iter
      __fzxBody(iter).overwrite = 0
      EXIT FUNCTION
    END IF
  iter = iter + 1: LOOP


  ' Prepare the the newly added elements in the array for overwrite
  tempUb = ub + 1
  ' Add more bodies
  REDIM _PRESERVE __fzxBody(ub + 10) AS tFZX_BODY
  ub = UBOUND(__fzxBody)
  ' mark these to be overwritten
  iter = tempUb: DO WHILE iter <= ub
    __fzxBody(iter).overwrite = 1
  iter = iter + 1: LOOP

  __fzxBody(tempUb).overwrite = 0
  fzxBodyManagerAdd = tempUb
END FUNCTION

FUNCTION fzxBodyWithHash (hash AS _INTEGER64)
  DIM AS LONG i
  fzxBodyWithHash = -1
  FOR i = 0 TO UBOUND(__fzxBody)
    IF __fzxBody(i).objectHash = hash THEN
      fzxBodyWithHash = i
      EXIT FUNCTION
    END IF
  NEXT
END FUNCTION

FUNCTION fzxBodyWithHashMask (hash AS _INTEGER64, mask AS LONG)
  DIM AS LONG i
  fzxBodyWithHashMask = -1
  FOR i = 0 TO UBOUND(__fzxBody)
    IF (__fzxBody(i).objectHash AND mask) = (hash AND mask) THEN
      fzxBodyWithHashMask = i
      EXIT FUNCTION
    END IF
  NEXT
END FUNCTION

FUNCTION fzxBodyManagerID (objName AS STRING)
  DIM i AS LONG
  DIM uID AS _INTEGER64
  uID = fzxComputeHash(_TRIM$(objName))
  fzxBodyManagerID = -1

  FOR i = 0 TO UBOUND(__fzxBody)
    IF __fzxBody(i).objectHash = uID THEN
      fzxBodyManagerID = i
      EXIT FUNCTION
    END IF
  NEXT
END FUNCTION

FUNCTION fzxBodyContainsString (start AS LONG, s AS STRING)
  fzxBodyContainsString = -1
  DIM AS LONG j
  FOR j = start TO UBOUND(__fzxBody)
    IF INSTR(__fzxBody(j).objectName, s) THEN
      fzxBodyContainsString = j
      EXIT FUNCTION
    END IF
  NEXT
END FUNCTION

'**********************************************************************************************
'   String Hash
'**********************************************************************************************
SUB _______________GENERAL_STRING_HASH: END SUB
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
'**********************************************************************************************
'   Network Related Tools
'**********************************************************************************************

SUB _______________NETWORK_FUNCTIONALITY: END SUB
SUB fzxHandleNetwork (net AS tFZX_NETWORK)
  IF net.SorC = cFZX_NET_SERVER THEN
    IF net.HCHandle = 0 THEN
      fzxNetworkStartHost net
    END IF
    fzxNetworkTransmit net
  END IF

  IF net.SorC = cFZX_NET_CLIENT THEN
    fzxNetworkReceiveFromHost net
  END IF
END SUB

SUB fzxNetworkStartHost (net AS tFZX_NETWORK)
  DIM connection AS STRING
  connection = RTRIM$(net.protocol) + ":" + LTRIM$(STR$(net.port))
  net.HCHandle = _OPENHOST(connection)
END SUB

SUB fzxNetworkReceiveFromHost (net AS tFZX_NETWORK)
  DIM connection AS STRING
  DIM AS LONG timeout
  connection = RTRIM$(net.protocol) + ":" + LTRIM$(STR$(net.port)) + ":" + RTRIM$(net.address)
  net.HCHandle = _OPENCLIENT(connection)
  timeout = TIMER
  IF net.HCHandle THEN
    DO
      GET #net.HCHandle, , __fzxBody()
      IF TIMER - timeout > 5 THEN EXIT DO ' 5 sec time out
    LOOP UNTIL EOF(net.HCHandle) = 0
    fzxNetworkClose net
  END IF
END SUB

SUB fzxNetworkTransmit (net AS tFZX_NETWORK)
  IF net.HCHandle <> 0 THEN
    net.connectionHandle = _OPENCONNECTION(net.HCHandle)
    IF net.connectionHandle <> 0 THEN
      PUT #net.connectionHandle, , __fzxBody()
      CLOSE net.connectionHandle
    END IF
  END IF
END SUB

SUB fzxNetworkClose (net AS tFZX_NETWORK)
  IF net.HCHandle <> 0 THEN
    CLOSE net.HCHandle
    net.HCHandle = 0
  END IF
END SUB

'**********************************************************************************************
'   FSM Handling
'**********************************************************************************************
SUB _______________FSM_HANDLING: END SUB

SUB fzxFSMChangeState (fsm AS tFZX_FSM, newState AS LONG)
  fsm.previousState = fsm.currentState
  fsm.currentState = newState
  fsm.timerState.start = TIMER(.001)
END SUB

SUB fzxFSMChangeStateEx (fsm AS tFZX_FSM, newState AS LONG, arg1 AS tFZX_VECTOR2d, arg2 AS tFZX_VECTOR2d, arg3 AS LONG)
  fsm.previousState = fsm.currentState
  fsm.currentState = newState
  fsm.arg1 = arg1
  fsm.arg2 = arg2
  fsm.arg3 = arg3
END SUB

SUB fzxFSMChangeStateOnTimer (fsm AS tFZX_FSM, newstate AS LONG)
  IF TIMER(.001) > fsm.timerState.start + fsm.timerState.duration THEN
    fzxFSMChangeState fsm, newstate
  END IF
END SUB

'**********************************************************************************************
'   String Array Functions
'**********************************************************************************************
SUB _______________STRING_ARRAY_FUNCTIONS: END SUB
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

'**********************************************************************************************
'   FPS Management
'**********************************************************************************************
SUB _______________FPS_MANAGEMENT: END SUB
SUB fzxInitFPS
  DIM timerOne AS LONG
  timerOne = _FREETIMER
  ON TIMER(timerOne, 1) fzxFPS
  TIMER(timerOne) ON

  timerOne = _FREETIMER
  ON TIMER(timerOne, 1) fzxFPSMain
  TIMER(timerOne) ON

  timerOne = _FREETIMER
  ON TIMER(timerOne, .001) fzxFPSdt
  TIMER(timerOne) ON
END SUB

SUB fzxFPS
  DIM fpss AS STRING
  fpss = "   MAIN LOOP FPS:" + STR$(__fzxFPSCount.fpsLast) + "  OPENGL FPS:" + STR$(__fzxFPSCount.fpsLast1) + "   "
  _PRINTSTRING ((_WIDTH / 2) - (_PRINTWIDTH(fpss) / 2), 0), fpss

  __fzxFPSCount.fpsLast = __fzxFPSCount.fpsCount
  __fzxFPSCount.fpsCount = 0
END SUB

SUB fzxFPSMain
  __fzxFPSCount.fpsLast1 = __fzxFPSCount.fpsCount1
  __fzxFPSCount.fpsCount1 = 0
END SUB

SUB fzxFPSdt
  IF __fzxFPSCount.fpsLastFine > 0 THEN
    __fzxFPSCount.dt = 1 / (__fzxFPSCount.fpsLastFine * 100)
  ELSE
    __fzxFPSCount.dt = 1 / 100000
  END IF

  __fzxFPSCount.fpsLastFine = __fzxFPSCount.fpsCountFine
  __fzxFPSCount.fpsCountFine = 0
END SUB


SUB fzxHandleFPSMain
  __fzxFPSCount.fpsCount = __fzxFPSCount.fpsCount + 1
  __fzxFPSCount.fpsCountFine = __fzxFPSCount.fpsCountFine + 1
END SUB

SUB fzxHandleFPSGL
  __fzxFPSCount.fpsCount1 = __fzxFPSCount.fpsCount1 + 1
END SUB




