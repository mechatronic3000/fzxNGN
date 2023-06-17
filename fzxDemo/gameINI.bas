'$include:'..\fzxNGN_BASE_v2\fzxNGN_ini.bas'

$IF GAMEINCLUDE = UNDEFINED THEN
  $LET GAMEINCLUDE = TRUE

  TYPE tCHAIN
    id AS STRING * 64
    axis AS _BYTE ' 0 - for horizontal, 1 - vertical
    primitive AS _BYTE ' 0 - rectangle, 1 - circle
    chainLinkCount AS LONG
    endPointBody1 AS LONG
    endPointBody2 AS LONG
    softness AS DOUBLE
    biasFactor AS DOUBLE
    maxBias AS DOUBLE ' Sets the breaking point
    segmentSize AS tFZX_VECTOR2d
    segmentSpacing AS DOUBLE ' Space between segments
    massMultiplier AS DOUBLE ' Set mass multiplier for each segment
    startPosition AS tFZX_VECTOR2d
    segmentTexture AS LONG ' Texture of each segment
  END TYPE

  TYPE tGAME
    player AS LONG
    wheel1 AS LONG
    wheel2 AS LONG
    head AS LONG

    loopramp1 AS LONG
    loopramp2 AS LONG
  END TYPE

  DIM SHARED AS tGAME game

  CONST cLOOP_CENTER_X = 20000
  CONST cLOOP_CENTER_Y = -230
  CONST cLOOP_RAMPHEIGHT = 750
  CONST cLOOP_RAMPWIDTH = 20
  CONST cLOOP_RAMPTHICKNESS = 100
  CONST cLOOP_RADIUS = 900
  CONST cSCENE_NUMBEROFLOOPSEGMENTS = 20



  DIM SHARED AS tCHAIN bridge
  bridge.id = "bridgeSegment"
  bridge.startPosition.x = 7400
  bridge.startPosition.y = -945
  bridge.chainLinkCount = 50 '25
  bridge.segmentSize.x = 50
  bridge.segmentSize.y = 25
  bridge.segmentSpacing = 60
  bridge.segmentTexture = 4
  bridge.softness = .00009
  bridge.biasFactor = 3000
  bridge.maxBias = 300 ' 350
  bridge.primitive = 0
  bridge.axis = 0
  bridge.massMultiplier = .00005


  CONST cVEHICLE_WHEEL_TORQUE = 6000

$END IF
