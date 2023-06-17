'**********************************************************************************************
'   fzxDemo
'**********************************************************************************************

'$DYNAMIC
OPTION _EXPLICIT
_TITLE "fzxNGNDemo"

' Initialize FZXNGN types, globals and constants
'$include:'..\fzxNGN_BASE_v2\fzxNGN_ini.bas'

' Setup OPENGL related stuff
'$include:'GLINI.bas'

' Put game specific stuff here
'$include:'gameINI.bas'

'**********************************************************************************************
'   Setup Globals Variables
'**********************************************************************************************

$LET MRENDERJOINTS = TRUE
$LET MRENDERCOLLISIONS = FALSE
$LET MRENDERFZXAABB = FALSE
$LET MRENDERWIREFRAME = FALSE
$LET GLLIGHTS = FALSE
$LET MBRIDGE = TRUE
$LET MLOOP = TRUE

DIM SHARED AS LONG bm(0) ' array textures


SCREEN _NEWIMAGE(1024, 768, 32)

fzxInitFPS
fzxFSMChangeState glMode, cFSM_GLMODE_IDLE

DIM AS LONG iterations: iterations = 2
DIM SHARED AS DOUBLE dt: dt = 1 / 60

'**********************************************************************************************
' This is the main loop (Fast Loop)
'**********************************************************************************************
DO
  IF glMode.currentState = cFSM_GLMODE_RUN THEN animateScene game
  fzxImpulseStep dt, iterations
  fzxHandleInputDevice
LOOP UNTIL INKEY$ = CHR$(27)

SYSTEM

' This provides access to all of the fzxNGN functionality
'$include:'..\fzxNGN_BASE_v2\fzxNGN_BASE.bas'

'**********************************************************************************************
'    This is where you interact with the world.
'**********************************************************************************************

' This loop is continous
SUB animateScene (game AS tGAME)
  LOCATE 2, 40: PRINT "Use arrow keys to drive.  'r' to restart at beginning."

  ' Basic player controls
  IF _KEYDOWN(65) OR _KEYDOWN(97) OR _KEYDOWN(19200) THEN
    fzxSetBody cFZX_PARAMETER_TORQUE, game.wheel1, -cVEHICLE_WHEEL_TORQUE, 0
    fzxSetBody cFZX_PARAMETER_TORQUE, game.wheel2, -cVEHICLE_WHEEL_TORQUE, 0
  END IF

  IF _KEYDOWN(68) OR _KEYDOWN(100) OR _KEYDOWN(19712) THEN
    fzxSetBody cFZX_PARAMETER_TORQUE, game.wheel1, cVEHICLE_WHEEL_TORQUE, 0
    fzxSetBody cFZX_PARAMETER_TORQUE, game.wheel2, cVEHICLE_WHEEL_TORQUE, 0
  END IF
  IF _KEYDOWN(32) OR _KEYDOWN(87) OR _KEYDOWN(119) OR _KEYDOWN(18432) THEN
    fzxVector2DSet __fzxBody(game.player).fzx.force, 0, -1000
  END IF
  IF _KEYDOWN(20480) THEN
    fzxVector2DSet __fzxBody(game.player).fzx.force, 0, 10000
  END IF

  ' Keep the head following the orientation of the car
  fzxSetBody cFZX_PARAMETER_ORIENT, game.head, __fzxBody(game.player).fzx.orient, 0

  ' Camera is following the car
  __fzxCamera.position = __fzxBody(game.head).fzx.position

  ' If the player falls send them back to the spawn point
  IF __fzxBody(game.player).fzx.position.y > 1100 OR __fzxBody(game.player).fzx.position.x > 30000 OR _KEYDOWN(114) OR _KEYDOWN(82) THEN
    fzxSetBody cFZX_PARAMETER_POSITION, game.player, __fzxWorld.spawn.x, __fzxWorld.spawn.y
    fzxSetBody cFZX_PARAMETER_POSITION, game.wheel1, __fzxBody(game.player).fzx.position.x + 75, __fzxBody(game.player).fzx.position.y + 65
    fzxSetBody cFZX_PARAMETER_POSITION, game.wheel2, __fzxBody(game.player).fzx.position.x - 75, __fzxBody(game.player).fzx.position.y + 6
    fzxSetBody cFZX_PARAMETER_POSITION, game.head, __fzxBody(game.player).fzx.position.x - 25, __fzxBody(game.player).fzx.position.y - 125
    fzxSetBody cFZX_PARAMETER_ORIENT, game.player, 0, 0
    fzxSetBody cFZX_PARAMETER_ORIENT, game.wheel1, 0, 0
    fzxSetBody cFZX_PARAMETER_ORIENT, game.wheel2, 0, 0
    fzxSetBody cFZX_PARAMETER_ORIENT, game.head, 0, 0

    fzxBodyStop game.player
    fzxBodyStop game.wheel1
    fzxBodyStop game.wheel2
    fzxBodyStop game.head

    'In case you broke the bridge
    $IF MBRIDGE = TRUE THEN
      setBridge bridge
    $END IF
  END IF


  $IF MLOOP = TRUE THEN
    'Disable collisions on second ramp so you can get out
    IF __fzxBody(game.player).fzx.position.x > cLOOP_CENTER_X + cLOOP_RAMPWIDTH + 100 THEN
      IF __fzxBody(game.player).fzx.position.y < cLOOP_CENTER_Y - 1000 THEN
        fzxSetBody cFZX_PARAMETER_COLLISIONMASK, game.loopramp2, 0, 0
        fzxSetBody cFZX_PARAMETER_COLLISIONMASK, game.loopramp1, 255, 0
      END IF
    END IF

    'Renable for the next pass through
    IF __fzxBody(game.player).fzx.position.x < cLOOP_CENTER_X - cLOOP_RAMPWIDTH - 1000 THEN
      fzxSetBody cFZX_PARAMETER_COLLISIONMASK, game.loopramp2, 255, 0
      fzxSetBody cFZX_PARAMETER_COLLISIONMASK, game.loopramp1, 0, 0
    END IF
  $END IF
END SUB

'********************************************************
'   Build you world here
'********************************************************

SUB buildScene (game AS tGAME)
  DIM AS LONG temp
  loadSprites bm()

  'Initialize camera
  __fzxCamera.zoom = 0.35
  fzxCalculateFOV

  '********************************************************
  '   Setup World
  '********************************************************

  fzxVector2DSet __fzxWorld.minusLimit, -200000, -200000
  fzxVector2DSet __fzxWorld.plusLimit, 200000, 200000
  fzxVector2DSet __fzxWorld.spawn, 5000, -500
  fzxVector2DSet __fzxWorld.gravity, 0.0, 100.0
  fzxVector2DSet __fzxWorld.terrainPosition, -7000.0, 1000.0

  DIM o AS tFZX_VECTOR2d
  fzxVector2DMultiplyScalarND o, __fzxWorld.gravity, dt
  __fzxWorld.resting = fzxVector2DLengthSq(o) + cFZX_EPSILON

  '********************************************************
  '   Build Level
  '********************************************************
  DIM AS DOUBLE sf, df, rs
  sf = .1
  df = .1
  rs = 0.85

  __fzxCamera.bkImg = 11 ' background image loaded into texture array

  '********************************************************
  '   Build Vehicle
  '********************************************************

  ' Build Body
  game.player = fzxCreateBoxBodyEx("player", 150, 80)
  fzxPolygonComputeMass game.player, .0001
  fzxSetBody cFZX_PARAMETER_POSITION, game.player, __fzxWorld.spawn.x, __fzxWorld.spawn.y
  fzxSetBody cFZX_PARAMETER_VELOCITY, game.player, 0, 0
  fzxSetBody cFZX_PARAMETER_TEXTURE, game.player, 5, 0
  fzxSetBody cFZX_PARAMETER_COLLISIONMASK, game.player, 1, 0

  'Build Wheel 1
  game.wheel1 = fzxCreateCircleBodyEx("wheel1", 55)
  fzxSetBody cFZX_PARAMETER_TEXTURE, game.wheel1, 6, 0
  fzxSetBody cFZX_PARAMETER_POSITION, game.wheel1, __fzxBody(game.player).fzx.position.x + 85, __fzxBody(game.player).fzx.position.y + 65
  fzxSetBody cFZX_PARAMETER_STATICFRICTION, game.wheel1, 0.9, 0
  fzxSetBody cFZX_PARAMETER_DYNAMICFRICTION, game.wheel1, 0.7, 0
  fzxSetBody cFZX_PARAMETER_RESTITUTION, game.wheel1, .10, 0
  fzxSetBody cFZX_PARAMETER_COLLISIONMASK, game.wheel1, 2, 0
  fzxSetBody cFZX_PARAMETER_ZPOSITION, game.wheel1, .1, 0

  'Build Wheel 2
  game.wheel2 = fzxCreateCircleBodyEx("wheel2", 55)
  fzxSetBody cFZX_PARAMETER_TEXTURE, game.wheel2, 6, 0
  fzxSetBody cFZX_PARAMETER_POSITION, game.wheel2, __fzxBody(game.player).fzx.position.x - 85, __fzxBody(game.player).fzx.position.y + 65
  fzxSetBody cFZX_PARAMETER_STATICFRICTION, game.wheel2, 0.9, 0
  fzxSetBody cFZX_PARAMETER_DYNAMICFRICTION, game.wheel2, 0.7, 0
  fzxSetBody cFZX_PARAMETER_RESTITUTION, game.wheel2, .10, 0
  fzxSetBody cFZX_PARAMETER_COLLISIONMASK, game.wheel2, 2, 0
  fzxSetBody cFZX_PARAMETER_ZPOSITION, game.wheel2, .1, 0


  'Attach Wheel1 to Body
  temp = fzxJointCreate(game.player, game.wheel1, __fzxBody(game.wheel1).fzx.position.x, __fzxBody(game.wheel1).fzx.position.y)
  __fzxJoints(temp).softness = 0.00007
  __fzxJoints(temp).biasFactor = 500



  'Attach Wheel2 to Body
  temp = fzxJointCreate(game.player, game.wheel2, __fzxBody(game.wheel2).fzx.position.x, __fzxBody(game.wheel2).fzx.position.y)

  __fzxJoints(temp).softness = 0.00007
  __fzxJoints(temp).biasFactor = 500


  'Build and attach Drivers Head
  game.head = fzxCreateCircleBodyEx("head", 50)

  fzxSetBody cFZX_PARAMETER_TEXTURE, game.head, 7, 0
  fzxSetBody cFZX_PARAMETER_POSITION, game.head, __fzxBody(game.player).fzx.position.x - 25, __fzxBody(game.player).fzx.position.y - 125
  fzxSetBody cFZX_PARAMETER_COLLISIONMASK, game.head, 4, 0
  fzxSetBody cFZX_PARAMETER_ZPOSITION, game.head, .1, 0


  temp = fzxJointCreate(game.player, game.head, __fzxBody(game.head).fzx.position.x, __fzxBody(game.head).fzx.position.y)
  __fzxJoints(temp).softness = 0.09
  __fzxJoints(temp).biasFactor = 50


  '********************************************************
  '   Build Terrain
  '********************************************************

  ' Build a terrain to drive on

  DIM numberOfTerrainSegments AS INTEGER: numberOfTerrainSegments = 70
  DIM AS DOUBLE terrainSliceWidth, terrainNominalHeight, terrainRandomHeight

  terrainSliceWidth = 1500
  terrainNominalHeight = 1000
  terrainRandomHeight = 150

  ' Create some rolling Hills
  DIM ele(numberOfTerrainSegments) AS DOUBLE
  DIM AS LONG j
  FOR j = 0 TO numberOfTerrainSegments
    ele(j) = 200 + RND * terrainRandomHeight
  NEXT
  fzxCreateTerrainBodyEx "TERRAIN", ele(), numberOfTerrainSegments, terrainSliceWidth, terrainNominalHeight

  ' Set the texture to the terrain
  j = -1: DO
    j = fzxBodyContainsString(j + 1, "TERRAIN")
    IF j > -1 THEN
      fzxSetBodyEx cFZX_PARAMETER_TEXTURE, __fzxBody(j).objectName, 3, 0
      fzxSetBodyEx cFZX_PARAMETER_ZPOSITION, __fzxBody(j).objectName, .9, 0
      ' Remove the terrain below the bridge
      $IF MBRIDGE = TRUE THEN
        IF j > 13 AND j < 18 THEN fzxSetBodyEx cFZX_PARAMETER_ENABLE, __fzxBody(j).objectName, 0, 0
      $END IF
    END IF
  LOOP UNTIL j <= 0

  ' end stop to keep player from falling off the back edge
  temp = fzxCreateBoxBodyEx("endstop", 100, 1000)
  fzxSetBody cFZX_PARAMETER_POSITION, temp, __fzxWorld.terrainPosition.x, __fzxWorld.terrainPosition.y - 500 - terrainNominalHeight
  fzxSetBody cFZX_PARAMETER_VELOCITY, temp, 0, 0
  fzxSetBody cFZX_PARAMETER_TEXTURE, temp, 4, 0
  fzxSetBody cFZX_PARAMETER_STATIC, temp, 0, 0
  fzxSetBody cFZX_PARAMETER_REPEATTEXTURE, temp, 1, 10

  '********************************************************
  '   Build Bridge Ramps
  '********************************************************

  $IF MBRIDGE = TRUE THEN

    'build bridge ramps
    bridge.endPointBody1 = fzxCreateTrapBodyEx("BRIDGERAMP1", 1000, 200, 1200, 400)
    fzxSetBody cFZX_PARAMETER_POSITION, bridge.endPointBody1, 6600, 0
    fzxSetBody cFZX_PARAMETER_TEXTURE, bridge.endPointBody1, 4, 0
    fzxSetBody cFZX_PARAMETER_STATIC, bridge.endPointBody1, 0, 0
    fzxSetBody cFZX_PARAMETER_REPEATTEXTURE, bridge.endPointBody1, 20, 20

    bridge.endPointBody2 = fzxCreateTrapBodyEx("BRIDGERAMP2", 1000, 200, 400, 1200)
    fzxSetBody cFZX_PARAMETER_POSITION, bridge.endPointBody2, 10800 + (bridge.chainLinkCount + 1) * bridge.segmentSpacing, 0
    fzxSetBody cFZX_PARAMETER_TEXTURE, bridge.endPointBody2, 4, 0
    fzxSetBody cFZX_PARAMETER_STATIC, bridge.endPointBody2, 0, 0
    fzxSetBody cFZX_PARAMETER_REPEATTEXTURE, bridge.endPointBody2, 20, 20

    ' build actual bridge
    setBridge bridge
  $END IF


  $IF MLOOP = TRUE THEN
    '********************************************************
    '   Build loop
    '********************************************************

    'Ramp 1
    game.loopramp1 = fzxCreateBoxBodyEx("cSCENE_LOOPRAMP_1", cLOOP_RAMPWIDTH, cLOOP_RAMPHEIGHT)

    fzxSetBodyEx cFZX_PARAMETER_POSITION, "cSCENE_LOOPRAMP_1", cLOOP_CENTER_X + 250, cLOOP_CENTER_Y - 200
    fzxSetBodyEx cFZX_PARAMETER_TEXTURE, "cSCENE_LOOPRAMP_1", 4, 0
    fzxSetBodyEx cFZX_PARAMETER_STATIC, "cSCENE_LOOPRAMP_1", 0, 0
    fzxSetBodyEx cFZX_PARAMETER_COLLISIONMASK, "cSCENE_LOOPRAMP_1", 0, 0
    fzxSetBodyEx cFZX_PARAMETER_REPEATTEXTURE, "cSCENE_LOOPRAMP_1", 1, 20
    fzxSetBodyEx cFZX_PARAMETER_ZPOSITION, "cSCENE_LOOPRAMP_1", .003, 0
    fzxSetBodyEx cFZX_PARAMETER_ORIENT, "cSCENE_LOOPRAMP_1", _D2R(-70), 0

    'Ramp 2
    game.loopramp2 = fzxCreateBoxBodyEx("cSCENE_LOOPRAMP_2", cLOOP_RAMPWIDTH, cLOOP_RAMPHEIGHT)

    fzxSetBodyEx cFZX_PARAMETER_POSITION, "cSCENE_LOOPRAMP_2", cLOOP_CENTER_X + cLOOP_RAMPWIDTH + 250, cLOOP_CENTER_Y - 200
    fzxSetBodyEx cFZX_PARAMETER_TEXTURE, "cSCENE_LOOPRAMP_2", 4, 0
    fzxSetBodyEx cFZX_PARAMETER_STATIC, "cSCENE_LOOPRAMP_2", 0, 0
    fzxSetBodyEx cFZX_PARAMETER_REPEATTEXTURE, "cSCENE_LOOPRAMP_2", 1, 20
    fzxSetBodyEx cFZX_PARAMETER_ORIENT, "cSCENE_LOOPRAMP_2", _D2R(70), 0


    DIM AS LONG i
    FOR i = 0 TO cSCENE_NUMBEROFLOOPSEGMENTS - 1
      temp = fzxCreateBoxBodyEx("cSCENE_LOOPSEGMENTS" + LTRIM$(STR$(i)), 25, 110)
      fzxSetBody cFZX_PARAMETER_TEXTURE, temp, 4, 0
    NEXT
    DIM AS DOUBLE xp, yp, theta, rotOff
    rotOff = 10.5
    theta = (cFZX_PI / (cSCENE_NUMBEROFLOOPSEGMENTS / 2) * .75)
    FOR i = 0 TO cSCENE_NUMBEROFLOOPSEGMENTS - 1
      xp = cLOOP_CENTER_X - cLOOP_RADIUS * COS((i + rotOff) * theta) + 250
      yp = cLOOP_CENTER_Y + cLOOP_RADIUS * SIN((i + rotOff) * theta) - 1075
      fzxSetBodyEx cFZX_PARAMETER_POSITION, "cSCENE_LOOPSEGMENTS" + LTRIM$(STR$(i)), xp, yp
      fzxSetBodyEx cFZX_PARAMETER_ORIENT, "cSCENE_LOOPSEGMENTS" + LTRIM$(STR$(i)), -(i + rotOff) * theta, 0
      fzxSetBodyEx cFZX_PARAMETER_STATIC, "cSCENE_LOOPSEGMENTS" + LTRIM$(STR$(i)), 0, 0
      fzxSetBodyEx cFZX_PARAMETER_ZPOSITION, "cSCENE_LOOPSEGMENTS" + LTRIM$(STR$(i)), .001, 0
      fzxSetBodyEx cFZX_PARAMETER_REPEATTEXTURE, "cSCENE_LOOPSEGMENTS" + LTRIM$(STR$(i)), 1, 5
    NEXT
  $END IF

  ' Starting arrow
  temp = fzxCreateBoxBodyEx("start", 100, 100)
  fzxSetBody cFZX_PARAMETER_POSITION, temp, __fzxWorld.spawn.x + 300, __fzxWorld.spawn.y + 100
  fzxSetBody cFZX_PARAMETER_VELOCITY, temp, 0, 0
  fzxSetBody cFZX_PARAMETER_TEXTURE, temp, 13, 0
  fzxSetBody cFZX_PARAMETER_STATIC, temp, 0, 0
  fzxSetBody cFZX_PARAMETER_COLLISIONMASK, temp, 0, 0

  ' Finish sign
  temp = fzxCreateBoxBodyEx("finish", 100, 100)
  fzxSetBody cFZX_PARAMETER_POSITION, temp, __fzxWorld.spawn.x + 23000, __fzxWorld.spawn.y + 150
  fzxSetBody cFZX_PARAMETER_VELOCITY, temp, 0, 0
  fzxSetBody cFZX_PARAMETER_TEXTURE, temp, 14, 0
  fzxSetBody cFZX_PARAMETER_STATIC, temp, 0, 0
  fzxSetBody cFZX_PARAMETER_COLLISIONMASK, temp, 0, 0


END SUB

'********************************************************
'   Build Bridge
'********************************************************

SUB setBridge (segmentChain AS tCHAIN)
  DIM AS LONG i, temp, lastTemp, jTemp
  ' Delete the bridge joinst if they exist
  i = 0: DO
    IF INSTR(__fzxJoints(i).jointName, "Segment") THEN
      fzxJointDelete i
    ELSE
      i = i + 1
    END IF
  LOOP UNTIL i > UBOUND(__fzxJoints)
  ' Delete bridge segments if they exist
  DO
    temp = fzxBodyContainsString(0, "Segment")
    fzxBodyDelete temp, 0
  LOOP UNTIL temp < 0

  ' Build new chain
  FOR i = 1 TO segmentChain.chainLinkCount

    temp = fzxCreateBoxBodyEx(_TRIM$(segmentChain.id) + LTRIM$(STR$(i)), segmentChain.segmentSize.x, segmentChain.segmentSize.y)
    fzxPolygonComputeMass temp, segmentChain.massMultiplier
    fzxSetBody cFZX_PARAMETER_POSITION, temp, segmentChain.startPosition.x + (i * (segmentChain.segmentSize.x + segmentChain.segmentSpacing)), segmentChain.startPosition.y
    fzxSetBody cFZX_PARAMETER_ORIENT, temp, 0, 0
    fzxSetBody cFZX_PARAMETER_VELOCITY, temp, 0, 0
    fzxSetBody cFZX_PARAMETER_ANGULARVELOCITY, temp, 0, 0
    fzxSetBody cFZX_PARAMETER_TEXTURE, temp, segmentChain.segmentTexture, 0

    ' Set the the ends of the chain to static, so they dont move.
    IF i = 1 OR i = segmentChain.chainLinkCount THEN
      fzxSetBody cFZX_PARAMETER_STATIC, temp, 0, 0
    END IF
    ' Make the Joints
    IF i > 1 THEN ' We have built the second segment so link the previous and current segment together
      jTemp = fzxJointCreate(temp, lastTemp, __fzxBody(temp).fzx.position.x - (segmentChain.segmentSize.x / 2), __fzxBody(temp).fzx.position.y)
      __fzxJoints(jTemp).softness = segmentChain.softness
      __fzxJoints(jTemp).biasFactor = segmentChain.biasFactor
      __fzxJoints(jTemp).max_bias = segmentChain.maxBias
      __fzxJoints(jTemp).render = 1 ' so we can see the strain on the joints
    END IF
    lastTemp = temp ' keep track of the last segment
  NEXT i

END SUB



'**********************************************************************************************
'   OPENGL LOOP (~60 cycles per second)
'**********************************************************************************************

SUB _______________OPENGL_LOOP: END SUB
SUB _GL STATIC
  SELECT CASE glMode.currentState
    CASE cFSM_GLMODE_IDLE:
      fzxFSMChangeState glMode, cFSM_GLMODE_INIT
    CASE cFSM_GLMODE_INIT:
      buildScene game
      fzxFSMChangeState glMode, cFSM_GLMODE_RUN
    CASE cFSM_GLMODE_RUN:
      glStuff
      renderBodies textures()
  END SELECT
  fzxHandleFPSGL
END SUB

SUB renderBodies (textures() AS tGL_TEXTURE) STATIC
  DIM i AS INTEGER
  DIM AS tFZX_VECTOR2d scSize, scMid, scUpperLeft, camUpperLeft, aabbUpperLeft, aabbSize, aabbHalfSize
  DIM AS LONG ub: ub = UBOUND(__fzxBody)
  DIM AS LONG uJ: uJ = UBOUND(__fzxJoints)

  ' Todo : move this to camera functions
  fzxVector2DSet aabbSize, 40000, 40000
  fzxVector2DSet aabbHalfSize, aabbSize.x / 2, aabbSize.y / 2

  fzxVector2DSet scUpperLeft, 0, 0
  fzxVector2DSet scSize, _WIDTH, _HEIGHT

  fzxVector2DDivideScalarND scMid, scSize, 2
  fzxVector2DSubVectorND camUpperLeft, __fzxCamera.position, scMid

  $IF MRENDERWIREFRAME = FALSE THEN
    IF __fzxCamera.bkImg <> 0 THEN
      glDrawRectText textures(__fzxCamera.bkImg).glText, 0, 0, _WIDTH(textures(__fzxCamera.bkImg).img), _HEIGHT(textures(__fzxCamera.bkImg).img)
    END IF
  $END IF

  i = 0: DO WHILE i < ub
    IF __fzxBody(i).enable THEN
      'fzxAABB to cut down on rendering objects out of camera view
      fzxVector2DSubVectorND aabbUpperLeft, __fzxBody(i).fzx.position, aabbHalfSize
      IF fzxAABBOverlap(camUpperLeft.x, camUpperLeft.y, scSize.x, scSize.y, aabbUpperLeft.x, aabbUpperLeft.y, aabbSize.x, aabbSize.y) THEN
        IF __fzxBody(i).shape.ty = cFZX_SHAPE_CIRCLE THEN
          $IF MRENDERWIREFRAME = FALSE THEN
            renderTexturedCircle3d i
          $ELSE
              renderWireFrameCircle i, _RGB32(0, 255, 0)
          $END IF
        ELSE IF __fzxBody(i).shape.ty = cFZX_SHAPE_POLYGON THEN
            $IF MRENDERWIREFRAME = FALSE THEN
              renderTexturedBox3d i
            $ELSE
                renderWireFramePoly i
            $END IF
          END IF
        END IF
      END IF
    END IF
    i = i + 1
  LOOP
  $IF MRENDERJOINTS = TRUE THEN
    i = 0: DO WHILE i <= uJ
      IF __fzxJoints(i).render = 1 THEN renderJoints i
    i = i + 1: LOOP
  $END IF
  $IF MRENDERCOLLISIONS = TRUE THEN
      DIM AS tFZX_VECTOR2d tv
      DIM hitcount AS LONG
      hitcount = 0: DO WHILE hitcount <= UBOUND(__fzxHits)
      tv.x = 0: tv.y = 0
      fzxWorldToCameraEx __fzxHits(hitcount).position, tv
      glDrawCircle tv.x, tv.y, 4, _RGB(255, 0, 0), 8
      hitcount = hitcount + 1: LOOP
  $END IF


END SUB

SUB renderJoints (index AS LONG)
  IF __fzxJoints(index).overwrite = 1 THEN EXIT SUB
  DIM AS tFZX_VECTOR2d o1, o2
  fzxVector2DSet o1, 0, 0
  fzxVector2DSet o2, 0, 0
  fzxWorldToCameraEx __fzxBody(__fzxJoints(index).body1).fzx.position, o1
  fzxWorldToCameraEx __fzxBody(__fzxJoints(index).body2).fzx.position, o2

  glDrawLine o1, o2, __fzxJoints(index).wireframe_color, 5
END SUB

SUB renderWireFrameCircle (index AS LONG, c AS LONG)
  DIM AS tFZX_VECTOR2d o1, o2

  fzxWorldToCameraEx __fzxBody(index).fzx.position, o1
  glDrawCircle o1.x, o1.y, __fzxBody(index).shape.radius * __fzxCamera.zoom, c, 12
  o2.x = o1.x + (__fzxBody(index).shape.radius * __fzxCamera.zoom) * COS(__fzxBody(index).fzx.orient)
  o2.y = o1.y + (__fzxBody(index).shape.radius * __fzxCamera.zoom) * SIN(__fzxBody(index).fzx.orient)
  glDrawLine o1, o2, c, 1

END SUB

SUB renderWireFramePoly (index AS LONG)
  DIM vert(3) AS tFZX_VECTOR2d

  fzxGetBodyVert index, 0, vert(0)
  fzxVector2DAddVector vert(0), __fzxBody(index).shape.offsetTexture
  fzxVector2DMultiplyVector vert(0), __fzxBody(index).shape.scaleTexture
  fzxWorldToCamera index, vert(0)

  fzxGetBodyVert index, 1, vert(1)
  fzxVector2DAddVector vert(1), __fzxBody(index).shape.offsetTexture
  fzxVector2DMultiplyVector vert(1), __fzxBody(index).shape.scaleTexture
  fzxWorldToCamera index, vert(1)

  fzxGetBodyVert index, 2, vert(2)
  fzxVector2DAddVector vert(2), __fzxBody(index).shape.offsetTexture
  fzxVector2DMultiplyVector vert(2), __fzxBody(index).shape.scaleTexture
  fzxWorldToCamera index, vert(2)

  fzxGetBodyVert index, 3, vert(3)
  fzxVector2DAddVector vert(3), __fzxBody(index).shape.offsetTexture
  fzxVector2DMultiplyVector vert(3), __fzxBody(index).shape.scaleTexture
  fzxWorldToCamera index, vert(3)

  glDrawLine vert(0), vert(1), _RGB(0, 255, 0), 2
  glDrawLine vert(1), vert(2), _RGB(0, 255, 0), 2
  glDrawLine vert(2), vert(3), _RGB(0, 255, 0), 2
  glDrawLine vert(3), vert(0), _RGB(0, 255, 0), 2

END SUB

SUB renderTexturedCircle (index AS INTEGER)
  DIM vert(3) AS tFZX_VECTOR2d
  fzxVector2DSet vert(0), -__fzxBody(index).shape.radius, __fzxBody(index).shape.radius
  fzxVector2DSet vert(1), -__fzxBody(index).shape.radius, -__fzxBody(index).shape.radius
  fzxVector2DSet vert(2), __fzxBody(index).shape.radius, -__fzxBody(index).shape.radius
  fzxVector2DSet vert(3), __fzxBody(index).shape.radius, __fzxBody(index).shape.radius
  fzxWorldToCamera index, vert(0)
  fzxWorldToCamera index, vert(1)
  fzxWorldToCamera index, vert(2)
  fzxWorldToCamera index, vert(3)

  glDrawTexturedQuad __fzxBody(index).shape, vert(3), vert(0), vert(1), vert(2)
END SUB

SUB renderTexturedCircle3d (index AS INTEGER)
  DIM vert(3) AS tFZX_VECTOR2d
  fzxVector2DSet vert(0), -__fzxBody(index).shape.radius, __fzxBody(index).shape.radius
  fzxVector2DSet vert(1), -__fzxBody(index).shape.radius, -__fzxBody(index).shape.radius
  fzxVector2DSet vert(2), __fzxBody(index).shape.radius, -__fzxBody(index).shape.radius
  fzxVector2DSet vert(3), __fzxBody(index).shape.radius, __fzxBody(index).shape.radius
  fzxWorldToCamera index, vert(0)
  fzxWorldToCamera index, vert(1)
  fzxWorldToCamera index, vert(2)
  fzxWorldToCamera index, vert(3)
  glDrawTexturedQuad3d __fzxBody(index).shape, vert(3), vert(0), vert(1), vert(2), __fzxBody(index).zPosition
END SUB


SUB renderTexturedBox (index AS INTEGER)
  DIM vert(3) AS tFZX_VECTOR2d

  fzxGetBodyVert index, 0, vert(0)
  fzxVector2DAddVector vert(0), __fzxBody(index).shape.offsetTexture
  fzxVector2DMultiplyVector vert(0), __fzxBody(index).shape.scaleTexture
  fzxWorldToCamera index, vert(0)

  fzxGetBodyVert index, 1, vert(1)
  fzxVector2DAddVector vert(1), __fzxBody(index).shape.offsetTexture
  fzxVector2DMultiplyVector vert(1), __fzxBody(index).shape.scaleTexture
  fzxWorldToCamera index, vert(1)

  fzxGetBodyVert index, 2, vert(2)
  fzxVector2DAddVector vert(2), __fzxBody(index).shape.offsetTexture
  fzxVector2DMultiplyVector vert(2), __fzxBody(index).shape.scaleTexture
  fzxWorldToCamera index, vert(2)

  fzxGetBodyVert index, 3, vert(3)
  fzxVector2DAddVector vert(3), __fzxBody(index).shape.offsetTexture
  fzxVector2DMultiplyVector vert(3), __fzxBody(index).shape.scaleTexture
  fzxWorldToCamera index, vert(3)

  'glDrawTexturedQuad textures(__fzxBody(index).shape.texture).glText, vert(1), vert(2), vert(3), vert(0)
  glDrawTexturedQuad __fzxBody(index).shape, vert(1), vert(2), vert(3), vert(0)
END SUB

SUB renderTexturedBox3d (index AS INTEGER)
  DIM vert(3) AS tFZX_VECTOR2d

  fzxGetBodyVert index, 0, vert(0)
  fzxVector2DAddVector vert(0), __fzxBody(index).shape.offsetTexture
  fzxVector2DMultiplyVector vert(0), __fzxBody(index).shape.scaleTexture
  fzxWorldToCamera index, vert(0)

  fzxGetBodyVert index, 1, vert(1)
  fzxVector2DAddVector vert(1), __fzxBody(index).shape.offsetTexture
  fzxVector2DMultiplyVector vert(1), __fzxBody(index).shape.scaleTexture
  fzxWorldToCamera index, vert(1)

  fzxGetBodyVert index, 2, vert(2)
  fzxVector2DAddVector vert(2), __fzxBody(index).shape.offsetTexture
  fzxVector2DMultiplyVector vert(2), __fzxBody(index).shape.scaleTexture
  fzxWorldToCamera index, vert(2)

  fzxGetBodyVert index, 3, vert(3)
  fzxVector2DAddVector vert(3), __fzxBody(index).shape.offsetTexture
  fzxVector2DMultiplyVector vert(3), __fzxBody(index).shape.scaleTexture
  fzxWorldToCamera index, vert(3)

  glDrawTexturedQuad3d __fzxBody(index).shape, vert(1), vert(2), vert(3), vert(0), __fzxBody(index).zPosition
END SUB


SUB glStuff
  _GLMATRIXMODE _GL_PROJECTION 'Select The Projection Matrix
  _GLENABLE _GL_DEPTH_TEST 'use the zbuffer
  _GLLOADIDENTITY 'Reset The Projection Matrix
  _GLORTHO 0, _WIDTH(0), _HEIGHT(0), 0, -1, 1

  _GLCLEARCOLOR .01, .24, .01, .5

  _GLMATRIXMODE _GL_MODELVIEW 'Select The Modelview Matrix
  _GLLOADIDENTITY 'Reset The Modelview Matrix
  _GLCLEAR _GL_DEPTH_BUFFER_BIT OR _GL_COLOR_BUFFER_BIT

  _GLENABLE _GL_BLEND
  _GLBLENDFUNC _GL_SRC_ALPHA, _GL_ONE_MINUS_SRC_ALPHA 'how alpha values are interpretted
  _GLDEPTHMASK _GL_TRUE
  _GLALPHAFUNC _GL_GREATER, 0.5 'dont do anything if alpha isn't greater than 0.5 (or 128)
  _GLENABLE _GL_ALPHA_TEST

  _GLHINT _GL_LINE_SMOOTH_HINT, _GL_NICEST
  _GLHINT _GL_POLYGON_SMOOTH_HINT, _GL_NICEST
  _GLDISABLE _GL_LINE_SMOOTH
  _GLDISABLE _GL_POLYGON_SMOOTH
  _GLENABLE _GL_MULTISAMPLE
END SUB

SUB GLSelectTexture (texture AS LONG)
  _GLBINDTEXTURE _GL_TEXTURE_2D, texture
END SUB

FUNCTION GLImageToTexture (texture() AS tGL_TEXTURE, img AS LONG)
  IF img > -1 THEN ERROR 100: EXIT FUNCTION
  DIM AS LONG textureArrayIndex
  DIM AS _MEM mIMG
  mIMG = _MEMIMAGE(img)
  textureArrayIndex = UBOUND(texture)
  _GLGENTEXTURES 1, _OFFSET(texture(textureArrayIndex).glText)
  _GLBINDTEXTURE _GL_TEXTURE_2D, texture(textureArrayIndex).glText
  _GLTEXIMAGE2D _GL_TEXTURE_2D, 0, _GL_RGBA, _WIDTH(img), _HEIGHT(img), 0, &H80E1&&, _GL_UNSIGNED_BYTE, mIMG.OFFSET
  GLImageToTexture = textureArrayIndex
  REDIM _PRESERVE texture(textureArrayIndex + 1) AS tGL_TEXTURE
  _MEMFREE mIMG
  _FREEIMAGE img
END FUNCTION

'**********************************************************************************************
'   GL Drawing Subs
'**********************************************************************************************
SUB _______________GL_DRAWING: END SUB
SUB glRGBColor (ptr AS _MEM, rgba AS LONG)
  DIM AS SINGLE r, g, b, a
  IF ptr.SIZE = 16 THEN
    r = fzxScalarMap(_RED(rgba), 0, 255, 0, 1)
    g = fzxScalarMap(_GREEN(rgba), 0, 255, 0, 1)
    b = fzxScalarMap(_BLUE(rgba), 0, 255, 0, 1)
    a = fzxScalarMap(_ALPHA(rgba), 0, 255, 0, 1)
    _MEMPUT ptr, ptr.OFFSET + 0, r AS SINGLE
    _MEMPUT ptr, ptr.OFFSET + 4, g AS SINGLE
    _MEMPUT ptr, ptr.OFFSET + 8, b AS SINGLE
    _MEMPUT ptr, ptr.OFFSET + 12, a AS SINGLE
  END IF
END SUB

SUB glFloat4 (ptr AS _MEM, x AS SINGLE, y AS SINGLE, z AS SINGLE, w AS SINGLE)
  IF ptr.SIZE = 16 THEN
    _MEMPUT ptr, ptr.OFFSET + 0, x AS SINGLE
    _MEMPUT ptr, ptr.OFFSET + 4, y AS SINGLE
    _MEMPUT ptr, ptr.OFFSET + 8, z AS SINGLE
    _MEMPUT ptr, ptr.OFFSET + 12, w AS SINGLE
  END IF
END SUB

SUB glDrawCircle (cx AS DOUBLE, cy AS DOUBLE, r AS DOUBLE, c AS LONG, numOfSegments AS LONG)

  DIM AS LONG ii
  DIM AS DOUBLE x, y, rads

  rads = 2.0 * _PI / numOfSegments

  _GLCOLOR3UB _RED(c), _GREEN(c), _BLUE(c)
  _GLBEGIN _GL_LINE_LOOP
  DO WHILE ii <= numOfSegments
    x = r * COS(rads * ii)
    y = r * SIN(rads * ii)
    _GLVERTEX3F x + cx, y + cy, .5
    ii = ii + 1
  LOOP
  _GLEND
  _GLFLUSH

END SUB

SUB glDrawRectText (tex AS LONG, x AS DOUBLE, y AS DOUBLE, x1 AS DOUBLE, y1 AS DOUBLE)
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

SUB glDrawRect3DText (shape AS tFZX_SHAPE, x AS DOUBLE, y AS DOUBLE, x1 AS DOUBLE, y1 AS DOUBLE, z AS DOUBLE)
  GLSelectTexture textures(shape.texture).glText
  _GLENABLE _GL_TEXTURE_2D
  _GLTEXPARAMETERI _GL_TEXTURE_2D, _GL_TEXTURE_MAG_FILTER, _GL_NEAREST
  _GLTEXPARAMETERI _GL_TEXTURE_2D, _GL_TEXTURE_MIN_FILTER, _GL_NEAREST

  _GLBEGIN _GL_QUADS
  _GLTEXCOORD2F 1, 1: _GLVERTEX3F x, y1, z
  _GLTEXCOORD2F 0, 1: _GLVERTEX3F x1, y1, z
  _GLTEXCOORD2F 0, 0: _GLVERTEX3F x1, y, z
  _GLTEXCOORD2F 1, 0: _GLVERTEX3F x, y, z
  _GLEND
  _GLDISABLE _GL_TEXTURE_2D
END SUB


SUB glDrawTexturedQuad (shape AS tFZX_SHAPE, a AS tFZX_VECTOR2d, b AS tFZX_VECTOR2d, c AS tFZX_VECTOR2d, d AS tFZX_VECTOR2d)
  GLSelectTexture textures(shape.texture).glText
  _GLENABLE _GL_TEXTURE_2D
  _GLTEXPARAMETERI _GL_TEXTURE_2D, _GL_TEXTURE_MAG_FILTER, _GL_NEAREST
  _GLTEXPARAMETERI _GL_TEXTURE_2D, _GL_TEXTURE_MIN_FILTER, _GL_NEAREST
  _GLBEGIN _GL_QUADS
  _GLTEXCOORD2F shape.uv0.x, shape.uv0.y: _GLVERTEX2F a.x, a.y
  _GLTEXCOORD2F shape.uv1.x, shape.uv1.y: _GLVERTEX2F b.x, b.y
  _GLTEXCOORD2F shape.uv2.x, shape.uv2.y: _GLVERTEX2F c.x, c.y
  _GLTEXCOORD2F shape.uv3.x, shape.uv3.y: _GLVERTEX2F d.x, d.y
  _GLEND
  _GLDISABLE _GL_TEXTURE_2D
END SUB

SUB glDrawTexturedQuad3d (shape AS tFZX_SHAPE, a AS tFZX_VECTOR2d, b AS tFZX_VECTOR2d, c AS tFZX_VECTOR2d, d AS tFZX_VECTOR2d, z AS DOUBLE)
  GLSelectTexture textures(shape.texture).glText
  _GLENABLE _GL_TEXTURE_2D
  _GLTEXPARAMETERI _GL_TEXTURE_2D, _GL_TEXTURE_MAG_FILTER, _GL_NEAREST
  _GLTEXPARAMETERI _GL_TEXTURE_2D, _GL_TEXTURE_MIN_FILTER, _GL_NEAREST
  _GLTEXPARAMETERI _GL_TEXTURE_2D, _GL_TEXTURE_WRAP_S, _GL_REPEAT
  _GLTEXPARAMETERI _GL_TEXTURE_2D, _GL_TEXTURE_WRAP_T, _GL_REPEAT

  _GLBEGIN _GL_QUADS
  _GLTEXCOORD2F shape.uv0.x, shape.uv0.y: _GLVERTEX3F a.x, a.y, z
  _GLTEXCOORD2F shape.uv1.x, shape.uv1.y: _GLVERTEX3F b.x, b.y, z
  _GLTEXCOORD2F shape.uv2.x, shape.uv2.y: _GLVERTEX3F c.x, c.y, z
  _GLTEXCOORD2F shape.uv3.x, shape.uv3.y: _GLVERTEX3F d.x, d.y, z
  _GLEND
  _GLDISABLE _GL_TEXTURE_2D
END SUB


SUB glDrawLine (a AS tFZX_VECTOR2d, b AS tFZX_VECTOR2d, c AS LONG, w AS INTEGER)
  _GLLINEWIDTH w
  _GLCOLOR3UB _RED(c), _GREEN(c), _BLUE(c)
  _GLBEGIN _GL_LINES
  _GLVERTEX3F a.x, a.y, .9
  _GLVERTEX3F b.x, b.y, .9
  _GLEND
END SUB


'**********************************************************************************************
'   Generate Bitmap
'**********************************************************************************************

SUB loadSprites (bm() AS LONG)
  'Body  - License CC0 - GameArt2D.com
  DIM AS LONG b, temp
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/truck/Body.png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/truck/Wheel (1).png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/truck/Head.png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Graveyard/png/Tiles/Tile (2).png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Graveyard/png/Objects/Crate.png")

  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/orc/Body.png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/orc/Wheel (1).png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/orc/Head.png")

  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/girl/Body.png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/girl/Wheel (1).png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/girl/Head.png")

  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Graveyard/png/BG.png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Desert/png/Objects/Cactus (2).png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Graveyard/png/Objects/ArrowSign.png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Graveyard/png/Objects/Sign.png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Graveyard/png/Objects/Bush (1).png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Graveyard/png/Objects/Bush (2).png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Graveyard/png/Objects/DeadBush.png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Graveyard/png/Objects/Skeleton.png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Graveyard/png/Objects/TombStone (1).png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Graveyard/png/Objects/TombStone (2).png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Graveyard/png/Objects/Tree.png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Graveyard/png/Tiles/Bones (1).png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Graveyard/png/Tiles/Bones (2).png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Graveyard/png/Tiles/Bones (3).png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Graveyard/png/Tiles/Bones (4).png")

  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Graveyard/png/Tiles/Tile (1).png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Graveyard/png/Tiles/Tile (3).png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Graveyard/png/Tiles/Tile (4).png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Graveyard/png/Tiles/Tile (5).png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Graveyard/png/Tiles/Tile (6).png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Graveyard/png/Tiles/Tile (7).png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Graveyard/png/Tiles/Tile (8).png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Graveyard/png/Tiles/Tile (9).png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Graveyard/png/Tiles/Tile (10).png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Graveyard/png/Tiles/Tile (11).png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Graveyard/png/Tiles/Tile (12).png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Graveyard/png/Tiles/Tile (13).png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Graveyard/png/Tiles/Tile (14).png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Graveyard/png/Tiles/Tile (15).png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Graveyard/png/Tiles/Tile (16).png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Scifi/png/Tiles/Acid (1).png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Scifi/png/Tiles/Acid (2).png")
  pushStackLong bm(), _LOADIMAGE(_CWD$ + "/Assets/Scifi/png/Tiles/Spike.png")

  FOR b = 0 TO UBOUND(bm) - 1
    IF bm(b) THEN temp = GLImageToTexture(textures(), bm(b))
  NEXT
END SUB

SUB pushStackLong (st() AS LONG, ele AS LONG)
  'IF ele = -1 THEN ERROR 101
  st(UBOUND(st)) = ele
  REDIM _PRESERVE st(UBOUND(st) + 1) AS LONG
END SUB



