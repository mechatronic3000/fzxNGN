'$include:'fzxNGN_ini.bas'
'$include:'fzxNGN_HASH.bas'
'$include:'fzxNGN_JOINT_MANAGEMENT.bas'
'$include:'fzxNGN_VECMATH.bas'

$IF FZXBODYMGMTINCLUDE = UNDEFINED THEN
  $LET FZXBODYMGMTINCLUDE = TRUE

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
    REDIM _PRESERVE __fzxBody(0 TO ub + 10) AS tFZX_BODY
    ub = UBOUND(__fzxBody)
    ' mark these to be overwritten
    iter = tempUb: DO WHILE iter <= ub
      __fzxBody(iter).overwrite = 1
    iter = iter + 1: LOOP

    __fzxBody(tempUb).overwrite = 0
    fzxBodyManagerAdd = tempUb
  END FUNCTION


  SUB fzxBodyClear
    DIM AS LONG iter
    iter = 0: DO WHILE iter <= UBOUND(__fzxBody)
      fzxBodyDelete iter, 0
    iter = iter + 1: LOOP
  END SUB

  SUB fzxBodyClearPerm
    DIM AS LONG iter
    iter = 0: DO WHILE iter <= UBOUND(__fzxBody)
      fzxBodyDelete iter, 1
    iter = iter + 1: LOOP
    ERASE __fzxBody
    REDIM AS tFZX_BODY __fzxBody(0 TO cSTARTINGNUMBEROFOBJECTS)
    ' Mark the  bodies for overwrite
    iter = 0: DO WHILE iter <= UBOUND(__fzxBody)
      __fzxBody(iter).overwrite = 1
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
        __fzxBody(index).entityID = 0
      ELSE
        'remove the bodys attached to it
        iter = index: DO
          __fzxBody(iter) = __fzxBody(iter + 1)
        iter = iter + 1: LOOP WHILE iter < UBOUND(__fzxBody)
        REDIM _PRESERVE __fzxBody(0 TO UBOUND(__fzxBody) - 1) AS tFZX_BODY

        'fix all the joints bodies after the index since then all the bodies are shifted toward zero index
        iter = 0: DO
          IF __fzxJoints(iter).body1 >= index THEN __fzxJoints(iter).body1 = __fzxJoints(iter).body1 - 1
          IF __fzxJoints(iter).body2 >= index THEN __fzxJoints(iter).body2 = __fzxJoints(iter).body2 - 1
        iter = iter + 1: LOOP WHILE iter <= UBOUND(__fzxJoints)
      END IF
    END IF
  END SUB


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

  SUB fzxCopyBodies (body() AS tFZX_BODY, newBody() AS tFZX_BODY)
    DIM AS LONG index
    FOR index = 0 TO UBOUND(body)
      newBody(index) = body(index)
    NEXT
  END SUB

$END IF
