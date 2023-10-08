'**********************************************************************************************
'   Setup Engine Types and Variables
'**********************************************************************************************
'$include:'..\..\fzxNGN_BASE_v2\fzxNGN_ini.bas'

$IF TYPEDEFS = UNDEFINED THEN
  $LET TYPEDEFS = TRUE


  TYPE tSPECIALFUNCTION
    func AS LONG
    arg AS LONG
  END TYPE

  TYPE tTILEMAP
    file AS STRING * 256
    tsxFile AS STRING * 256
    mapWidth AS LONG ' gamemap width
    mapHeight AS LONG ' gamemap height
    tileWidth AS LONG 'tile width in pixels
    tileHeight AS LONG 'tile height in pixels
    tileImageX AS LONG 'size of tilemap image in tiles
    tileCount AS LONG 'number of tiles in the image
    tileMap AS LONG ' tilemap image
    tileSize AS LONG 'same as tilewidth * tileheight, if square
    tilePadding AS LONG ' distance between tiles
    numberOfTilesX AS LONG 'same as w
    numberOfTilesY AS LONG 'same as h
    numberOfTiles AS LONG 'w*h
    tilescale AS LONG 'Tile to physics world scale
  END TYPE

  TYPE tTILE
    t AS _UNSIGNED LONG ' base tile layer
    t0 AS _UNSIGNED LONG ' second tile layer
    collision AS LONG ' collision
    id AS LONG
    class AS STRING * 32
    aniNextFrame AS LONG
    aniTiming AS LONG
    lightColor AS LONG
    glTexture AS _INTEGER64
  END TYPE

  TYPE tGL_TEXTURE
    glText AS _INTEGER64
  END TYPE

  TYPE tARCHTYPE
    id AS LONG
    sprite AS LONG
    nameString AS STRING * 64
    itemType AS LONG ' i.e. 1 = sword, 2 = helmet, 3 = ...
    weight AS SINGLE
    level AS LONG
    attackType AS LONG ' 0 = none, 1 = melee, 2 = ranged, 3 = magic ...
    defenseType AS LONG ' 0 = none, 1 = head, 2 = chest, 3 = ....
    stackCount AS LONG 'maximum amount in a stack
    lAttributeCount AS LONG
    lAttributeType AS STRING * 64 ' effects of item
    sAttributeQty AS STRING * 64 ' the amount of the effect
  END TYPE

  TYPE tCONTAINER ' almost all thins will be a containers
    sprite AS LONG ' the container may have its own sprite such as a bag or corpse
    containerType AS LONG
    owner AS LONG ' which entity owns the container
    lItemCount AS LONG ' keep track of the last item in the list
    lItemId AS STRING * 2048
    lItemHash AS STRING * 2048
    lItemType AS STRING * 2048 ' these will use long types (512 unique items)
    lItemQty AS STRING * 2048 ' how many? must not exceed stack count
    lItemAttribute AS STRING * 2048 ' bitmask for item attributes (i.e. is it equipt?)
  END TYPE

  TYPE tENTITYSTATS
    nameString AS STRING * 32
    level AS LONG
    xp AS LONG
    hp AS LONG
    hpMax AS LONG
    ap AS LONG ' action points
    apMax AS LONG
    stamina AS LONG
    staminaMax AS LONG
    mana AS LONG
    manaMax AS LONG
    hunger AS SINGLE
    thirst AS SINGLE

    gold AS LONG
    ' Base stats
    '***********************
    ' Strength bonus add to encumbrance and melee attacks
    strength AS LONG
  END TYPE


  TYPE tENTITYPARAMETERS
    activated AS _BYTE
    target AS LONG ' catch all for interacting with different entities
    normalTile AS LONG
    activatedTile AS LONG
    scale AS _FLOAT
    behavior AS LONG
    maxForce AS tFZX_VECTOR2d
    movementSpeed AS _FLOAT ' time to traverse 1 square
    drunkiness AS _FLOAT ' 1-5 additional parameter for A-star
    metadata AS STRING * 8192
  END TYPE

  TYPE tENTITY
    objectID AS LONG
    objectType AS LONG
    objectHash AS _INTEGER64
    parameters AS tENTITYPARAMETERS
    pathString AS STRING * 1024 ' for A* Path 'U'-Up 'D'-Down 'L'-Left 'R'-Right
    fsmPrimary AS tFZX_FSM
    fsmSecondary AS tFZX_FSM
    stats AS tENTITYSTATS
    inventory AS tCONTAINER
  END TYPE

  TYPE tMESSAGE
    baseImage AS LONG
    fadeImage AS LONG
    fsm AS tFZX_FSM
    position AS tFZX_VECTOR2d
    scale AS _FLOAT
    bgColor AS LONG
  END TYPE

  TYPE tMAPPARAMETERS
    maxLightDistance AS LONG
  END TYPE

  TYPE tGUI_MAPS ' the tile based maps used for the GUI
    hud AS LONG ' current hud
    sensorMap AS LONG

    hudMap AS LONG
    hudMapFile AS STRING * 256
    hudImage AS LONG

    hudLrgConMap AS LONG
    hudLrgConMapFile AS STRING * 256
    hudLrgConImage AS LONG

    inventoryMap AS LONG
    inventoryMapFile AS STRING * 256
    inventoryImage AS LONG

    lootMap AS LONG
    lootMapFile AS STRING * 256
    lootMapImage AS LONG
  END TYPE

  TYPE tGUI_FIELDS
    Id AS STRING * 32
    menuType AS INTEGER ' used to designate which menu they are in
    position AS tFZX_VECTOR2d
    size AS tFZX_VECTOR2d
    text AS STRING * 256
    scale AS LONG
    fieldType AS LONG
    activatedTile AS LONG
    buttonName AS STRING * 128
    buttonType AS LONG
    buttonId AS LONG
    buttonState AS INTEGER ' 0 - off, 1 - hover, 2 - clicked, 3 -doubleclicked
  END TYPE

  TYPE tENGINE
    currentMap AS STRING * 256
    mapParameters AS tMAPPARAMETERS


    workingDirectory AS STRING * 512
    assetsDirectory AS STRING * 512
    saveDirectory AS STRING * 512

    resting AS _FLOAT

    gameMode AS tFZX_FSM

    logFileName AS STRING * 256
    logFileNumber AS LONG

    itemListFilename AS STRING * 128

    displayClearColor AS LONG
    overlayEnable AS _BYTE

    displayScr AS LONG
    hiddenScr AS LONG
    overlayScr AS LONG

    displayMask AS LONG

    gui AS tGUI_MAPS
    guiRefresh AS _BYTE ' Set to refresh gui
    ' Refactoring rendering pipeline goes below here
    renderPipeline AS _MEM ' array of images
  END TYPE

  TYPE tFPS
    fpsCount AS LONG
    fpsLast AS LONG
  END TYPE

  TYPE tTILEFONT
    t AS LONG
    c AS LONG
    id AS LONG
  END TYPE

  TYPE tPATH ' used for A star
    position AS tFZX_VECTOR2d
    parent AS tFZX_VECTOR2d
    g AS LONG
    h AS LONG
    f AS LONG
    status AS LONG
  END TYPE

  TYPE tSOUND
    fileName AS STRING * 64
    class AS STRING * 64
    fileHash AS _INTEGER64
    classHash AS _INTEGER64
    handle AS LONG
  END TYPE

  TYPE tPLAYLIST
    currentMusic AS LONG
    nextMusic AS LONG
    fsm AS tFZX_FSM
    vol AS _FLOAT
    bal AS _FLOAT
  END TYPE

  TYPE tCOLOR
    r AS _UNSIGNED _BYTE
    g AS _UNSIGNED _BYTE
    b AS _UNSIGNED _BYTE
    a AS _UNSIGNED _BYTE
  END TYPE

  TYPE tLIGHT
    position AS tFZX_VECTOR2d
    lightColor AS LONG
  END TYPE

  TYPE tLANDMARK
    position AS tFZX_VECTOR2d
    landmarkName AS STRING * 64
    landmarkHash AS _INTEGER64
  END TYPE

  TYPE tDOOR
    bodyId AS LONG
    map AS STRING * 64
    doorName AS STRING * 64
    doorHash AS _INTEGER64
    position AS tFZX_VECTOR2d
    size AS tFZX_VECTOR2d
    landmarkHash AS _INTEGER64
    status AS INTEGER
    tileOpen AS LONG
    tileClosed AS LONG
  END TYPE

  TYPE tGAMEOPTIONS
    musicVolume AS SINGLE
    soundVolume AS SINGLE
  END TYPE

  TYPE tCONSOLE
    img AS LONG
    sPos AS tFZX_VECTOR2d ' Screen Position
    sSize AS tFZX_VECTOR2d ' Screen Size
    txt AS STRING * 32768 ' Buffer
    yPos AS LONG ' last viewable position in log (normally at the end)
    xSize AS LONG ' width of the currently viewable window . (in characters not pixels)
    ySize AS LONG ' height of the currently viewable window. (in characters not pixels)
    tSize AS LONG ' height of the font
    lc AS LONG ' current line count
  END TYPE


$END IF
