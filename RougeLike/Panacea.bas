' Panacea v0.1

$RESIZE:OFF
OPTION _EXPLICIT
'$dynamic
'$include:'..\fzxNGN_BASE_v2\fzxNGN_ini.bas'
'$include:'libs\globals.bi'


'**********************************************************************************************
'   Panacea a Rougelike Adventure written by Paul Martin aka justsomeguy
'
'                    Graphics by Kenney  - www.kenney.nl
'                    Sound by Eric Matyas  - soundimage.org
'
'**********************************************************************************************

'**********************************************************************************************
'
'**********************************************************************************************
' 05-22-21 : Added Mouse PoseEdge and NegEdge, tidyied up the code
' 05-23-21 : Push Screen Init and FPS init to functions
' 05-23-21 : Auto Center FPS Counter
' 05-23-21 : Realized that you dont need to use  if you dont use () around the arguments
'            Purged 's from main program
' 05-26-21 : Purged 's from impulse.bas
' 05-27-21 : More purging of CALL's
' 01-07-22 : Refactor for Generic Use, Removed all CALL statements
' 01-12-22 : Integrate TMX and TSX files to make level building easier
' 01-13-22 : Optimize AABB for collision detection
' 01-17-22 : Reorganized code for easier navigation
' 01-23-22 : Refactor XML parsing (Still not happy with it.)
' 01-23-22 : Adding Waypoints to the map data
' 01-27-22 : Discovered and fixed a long term bug in the circle wireframe code
'            Added Mouse code that uses as hidden image to detect collisions with sensors
'            Laid ground work for A-star usage
' 01-31-22 : Tidy up code more. Pushed mainloop items out to the Subs and functions
'            Implemented camera movement FSM
'            Player is controllable with Mouse and A Star
' 02-01-22 : Rename objectmanager to bodyManager
'            Inserted some Perlin Noise Code
'            Reworked message handler and Added a Splash Screen
' 02-04-22 : Worked on Camera following and Character movement FSM
'            The FSM still needs work
'            Integrated Background Music for the menu
' 02-06-22 : Added in baked in lighting for the map.
'            Added FSM functionality for Music
'            Added Landmarks
' 02-11-22 : Now able traverse Levels.
' 02-14-22 : Added Rigid Body Functionality (SLOW!!!!)
' 04-19-22 : Added Game Options Right now only volume
' 04-20-22 : Added Windows path separator support
'          : Got the Volume control working
' 04-22-23 : Started messing with it again.
'          : Added a cat to main area
'          : Pushed Movement speed and drunkiness to the map editor
'          : Added more Cats!
' 04-23-23 : Refactored out physics code and moved it to fzxNGN_base
' 04-24-23 : Renamed game to Panacea
'          : Built a home/lab for you shenanngans
' 04-28-23 : Layed ground work for a UI
' 04-29-23 : Built a Loot and Inventory Menu Screen
'          : Currently non functional, but able to display and escape
' 07-12-23 : Refactored to use newest 2d physics engine
' 09-12-23 : Working on more bug fixes
'          : Found a bug where the XML parsing cannot handle a space as an argument so the
'          : text characters would not generate a space correctly. Further work is needed.
'          : Started to implement level saving so that the state of a level is
'          : preserved when you leave and return
' 09-14-23 : Fixed no map after level transition
'          : Working on no combat routing after level transition.
' 09-16-23 : Cleaned up the globals and started moving some of the code out to libraries
' 09-17-23 : Fixed some bugs with level loading and putting the player in correct location.
'          : Updated the Level_1 map to make it an mob spawn location
'          : Added some residents to the town, They just wander around and do nothing.
' 09-18-23 : fixed the loot and inventory menus so they don't have to be updated
'          : twice to display correct information.
'          : AP now updates during combat mode.
'
'    ------  Moved comments to the github ------
'
'**********************************************************************************************
'TODO:
' ûFix the loot and inventory menus so that they dont have to be updated twice
' Get UI working correctly and fill the gaps.
' Make player persistent through level changes.
' Get loot and inventory to work.
' Actual combat!
' Add the crafting component.
' Refactor graphics pipeline (its a mess)
'
'**********************************************************************************************
'   ENTRY POINT
'**********************************************************************************************
$LET DEBUG = TRUE
main


'$include:'..\fzxNGN_BASE_v2\fzxNGN_BASE.bas'
'$include:'libs\memArrays.bm'
'$include:'libs\strArrays.bm'
'$include:'libs\debug.bm'
'$include:'libs\rpgFunctions.bm'

'**********************************************************************************************
'   Main Loop
'**********************************************************************************************
SUB _______________MAIN_LOOP (): END SUB
SUB main

  '**********************************************************************************************
  '   Arrays
  '**********************************************************************************************

  STATIC message(0) AS tMESSAGE

  STATIC tileMap AS tTILEMAP
  STATIC tile(0) AS tTILE


  STATIC archtype(0) AS tARCHTYPE
  STATIC container(0) AS tCONTAINER

  _TITLE "Panacea"

  __gmEngine.workingDirectory = _CWD$ + OSPathJoin$
  __gmEngine.assetsDirectory = _CWD$ + OSPathJoin$ + "Assets" + OSPathJoin$

  __gmEngine.logFileName = _CWD$ + OSPathJoin$ + "logs" + OSPathJoin$ + "Logfile.txt"
  __gmEngine.logFileNumber = 1
  __logfile = __gmEngine.logFileNumber
  IF _FILEEXISTS(_TRIM$(__gmEngine.logFileName)) THEN KILL _TRIM$(__gmEngine.logFileName)
  OPEN _TRIM$(__gmEngine.logFileName) FOR OUTPUT AS __gmEngine.logFileNumber

  __gmEngine.currentMap = "Mona.tmx"
  __gmEngine.gui.hudMapFile = "hud.tmx"
  __gmEngine.gui.hudLrgConMapFile = "hudLrgCon.tmx"
  __gmEngine.gui.inventoryMapFile = "Inventory.tmx"
  __gmEngine.gui.lootMapFile = "Loot.tmx"
  __gmEngine.itemListFilename = "archetypes.xml"

  initScreen 1024, 768, 32
  fzxInitFPS
  buildScene archtype(),_
             container(),_
             tile(), _
             tileMap, _
             message()


  DO
    runScene archtype(),_
             container(),_
             tile(), _
             tileMap, _
             message()
    handleTimers
    handleMusic __gmPlayList, __gmSounds()
    handleCamera
    handleEntitys tile(), tileMap
    handleMessages tile(), message()
    handleInputDevice tileMap
    fzxImpulseStep

    _DISPLAY
  LOOP



END SUB
'**********************************************************************************************
'   Scene Build
'**********************************************************************************************
SUB _______________BUILD_SCENE (): END SUB

SUB buildScene (arch() AS tARCHTYPE, container() AS tCONTAINER, tile() AS tTILE, tilemap AS tTILEMAP, message() AS tMESSAGE)

  _MOUSEHIDE
  __gmOptions.musicVolume = .05
  REDIM message(0) AS tMESSAGE
  REDIM context(0) AS tFZX_STRINGTUPLE

  freeAllTiles tile()

  '********************************************************
  '   Setup World
  '********************************************************

  tilemap.tilescale = 1
  __gmEngine.displayClearColor = _RGB32(26, 26, 26) '_RGB32(39, 67, 55)

  '********************************************************
  '   Load Map
  '********************************************************
  XMLparse _TRIM$(__gmEngine.assetsDirectory) + _TRIM$(__gmEngine.currentMap), context()
  XMLapplyAttributes tile(), tilemap, context()

  '********************************************************
  '   Load GUI
  '********************************************************
  XMLparse _TRIM$(__gmEngine.assetsDirectory) + _TRIM$(__gmEngine.gui.inventoryMapFile), context()
  XMLGUI __gmEngine.gui.inventoryMapFile, __gmGuiLayout(cGUI_LAYOUT_INVENTORY), context(), 1

  XMLparse _TRIM$(__gmEngine.assetsDirectory) + _TRIM$(__gmEngine.gui.lootMapFile), context()
  XMLGUI __gmEngine.gui.lootMapFile, __gmGuiLayout(cGUI_LAYOUT_LOOT), context(), 0

  XMLparse _TRIM$(__gmEngine.assetsDirectory) + _TRIM$(__gmEngine.gui.hudMapFile), context()
  XMLGUI __gmEngine.gui.hudMapFile, __gmGuiLayout(cGUI_LAYOUT_HUD), context(), 0

  XMLparse _TRIM$(__gmEngine.assetsDirectory) + _TRIM$(__gmEngine.gui.hudLrgConMapFile), context()
  XMLGUI __gmEngine.gui.hudLrgConMapFile, __gmGuiLayout(cGUI_LAYOUT_HUD_LARGE_CONSOLE), context(), 0

  __gmEngine.gui.hud = cGUI_LAYOUT_HUD
  __gmConsole.img = _NEWIMAGE(1024, 1024, 32)

  '********************************************************
  '   Load Items
  '********************************************************
  XMLparse _TRIM$(__gmEngine.assetsDirectory) + _TRIM$(__gmEngine.itemListFilename), context()
  archTypeInitialize arch(), context()

  initInputDevice tile(idToTile(tile(), 516 + 1)).t

  DIM AS LONG playerId

  playerId = entityManagerID("PLAYER")
  IF playerId < 0 THEN
    PRINT "Player does not exist!": waitkey: END
  END IF

  fzxFSMChangeState __gmEngine.gameMode, cFSM_GAMEMODE_SPLASH
  __debugDumpBodies
END SUB

'**********************************************************************************************
'   Scene Handling
'**********************************************************************************************
SUB _______________RUN_SCENE (): END SUB
SUB runScene (arch() as tarchtype,_
              container as tcontainer,_
              tile() AS tTILE, _
              tilemap AS tTILEMAP, _
              message() AS tMESSAGE)



  DIM AS LONG backgroundMusic, music1, music2, music3
  DIM AS tFZX_VECTOR2d tempVec, tempVec2
  DIM AS tFZX_VECTOR2d position
  DIM AS LONG bkgndID, hudId, xs, ys

  DIM AS LONG indx, playerID, mouseID, targetID
  STATIC lastZoom AS SINGLE
  STATIC AS tFZX_VECTOR2d vecs(256) ' list of vectors for the overlay
  STATIC AS LONG vecCount

  STATIC m AS tMESSAGE

  backgroundMusic = soundManagerIDClass(__gmSounds(), "BACKGROUND")
  music1 = soundManagerIDClass(__gmSounds(), "MUSIC_1")
  music2 = soundManagerIDClass(__gmSounds(), "MUSIC_2")
  music3 = soundManagerIDClass(__gmSounds(), "MUSIC_3")
  hudId = fzxBodyManagerID(_TRIM$(__gmEngine.gui.hudMapFile))
  SELECT CASE __gmEngine.gameMode.currentState
    CASE cFSM_GAMEMODE_IDLE:
    CASE cFSM_GAMEMODE_SPLASH:

      fzxVector2DSet position, 100, 100
      addMessage tile(), tilemap, message(), "   ~00656 Panacea ~00656__  by Paul Martin _ aka  JUSTSOMEGUY", 4, position, 3.0
      playMusic __gmPlayList, __gmSounds(), "BACKGROUND"
      fzxFSMChangeState __gmEngine.gameMode, cFSM_GAMEMODE_START

    CASE cFSM_GAMEMODE_START:

      __gmEngine.gameMode.timerState.duration = 9
      clearScreen
      fzxFSMChangeStateOnTimer __gmEngine.gameMode, cFSM_GAMEMODE_INTRO_SETUP
      __fzxInputDevice.mouse.mouseMode = 0

    CASE cFSM_GAMEMODE_INTRO_SETUP:

      fzxVector2DSet position, 10, 100
      addMessage tile(), tilemap, message(), "             Panacea__" + _
                                             "Welcome to the small village of_" + _
                                             "Mona. You are the son of the_" + _
                                             "towns Doctor. You have to_" + _
                                             "assist your father with various_" +_
                                             "duties. You learn how to make_" +_
                                             "medicines for the village." _
                                             , 4, position, 2.0
      fzxFSMChangeState __gmEngine.gameMode, cFSM_GAMEMODE_INTRO

    CASE cFSM_GAMEMODE_INTRO:

      __gmEngine.gameMode.timerState.duration = 9
      clearScreen
      fzxFSMChangeStateOnTimer __gmEngine.gameMode, cFSM_GAMEMODE_GAMEPLAY_SETUP
      __fzxInputDevice.mouse.mouseMode = 0
      __gmEngine.overlayEnable = TRUE

      __gmEngine.guiRefresh = TRUE
      updateGUI cGUI_LAYOUT_HUD, tilemap

    CASE cFSM_GAMEMODE_GAMEPLAY_SETUP
      __gmEngine.guiRefresh = TRUE
      updateGUI __gmEngine.gui.hud, tilemap ' cGUI_LAYOUT_HUD
      playerID = entityManagerID("PLAYER")
      moveCamera __fzxBody(__gmEntity(playerID).objectID).fzx.position
      fzxFSMChangeState __gmEngine.gameMode, cFSM_GAMEMODE_GAMEPLAY
      __gmConsole.xSize = 58
      __gmConsole.ySize = 4
      __gmConsole.yPos = 0
      ' test wall of text
      consoleOut tile(), tilemap, "~01409 Welcome to Mona! ~01409"


    CASE cFSM_GAMEMODE_GAMEPLAY:

      handlePlayerInput tile(), tilemap, message()
      IF handleMapChange(tile(), tilemap, message()) THEN EXIT SUB ' we changed maps so lets start again
      handleMapSpecific tile(), tilemap, message()
      handleGUI tilemap
      renderBodies tilemap

    CASE cFSM_GAMEMODE_CREDITS_SETUP:

      clearScreen
      fzxVector2DSet position, 40, 100
      addMessage tile(), tilemap, message(), "      Panacea__" + _
                                             "by Paul Martin aka JUSTSOMEGUY_Written Using QB64___" + _
                                             "Graphics by Kenney_www.kenney.nl___" + _
                                             "Sound by Eric Matyas_soundimage.org" _
                                             , 4, position, 2.0
      fzxFSMChangeState __gmEngine.gameMode, cFSM_GAMEMODE_CREDITS

    CASE cFSM_GAMEMODE_CREDITS:

      __gmEngine.gameMode.timerState.duration = 9
      clearScreen
      fzxFSMChangeStateOnTimer __gmEngine.gameMode, cFSM_GAMEMODE_GAMEPLAY
      __fzxInputDevice.mouse.mouseMode = 0
      findLandmarkPosition __gmLandmark(), "lmNEVERMIND", tempVec
      fzxSetBody cFZX_PARAMETER_POSITION, __gmEntity(playerID).objectID, tempVec.x, tempVec.y

    CASE cFSM_GAMEMODE_INVENTORY_SETUP:

      clearScreen
      __gmEngine.guiRefresh = TRUE
      updateGUI cGUI_LAYOUT_INVENTORY, tilemap
      fzxFSMChangeState __gmEngine.gameMode, cFSM_GAMEMODE_INVENTORY

    CASE cFSM_GAMEMODE_INVENTORY:

      handleGUI tilemap
      IF __fzxInputDevice.keyboard.keyHitPosEdge = 27 THEN

        fzxFSMChangeState __gmEngine.gameMode, cFSM_GAMEMODE_GAMEPLAY
        clearScreen
        __gmEngine.guiRefresh = TRUE
        updateGUI cGUI_LAYOUT_HUD, tilemap
      END IF
      renderBodies tilemap

    CASE cFSM_GAMEMODE_LOOTMENU_SETUP:

      clearScreen
      __gmEngine.guiRefresh = TRUE
      updateGUI cGUI_LAYOUT_LOOT, tilemap

      fzxFSMChangeState __gmEngine.gameMode, cFSM_GAMEMODE_LOOTMENU

    CASE cFSM_GAMEMODE_LOOTMENU:

      handleGUI tilemap
      IF __fzxInputDevice.keyboard.keyHitPosEdge = 27 THEN
        clearScreen
        __gmEngine.guiRefresh = TRUE
        updateGUI cGUI_LAYOUT_HUD, tilemap
        fzxFSMChangeState __gmEngine.gameMode, cFSM_GAMEMODE_GAMEPLAY
        __gmEntity(targetID).parameters.activated = 0
      END IF
      renderBodies tilemap

    CASE cFSM_GAMEMODE_COMBAT_SETUP:
      '**************************************
      '   COMBAT
      '**************************************

      playerID = entityManagerID("PLAYER")
      IF playerID < 0 THEN
        PRINT "Object does not exist!": waitkey: END
      END IF

      fzxVector2DSet position, 100, 100
      'addMessage tile(), tilemap, message(), "PLAYER TURN", 1, position, 3.0
      consoleOut tile(), tilemap, "Isaac Turn"
      ' draw the paths available
      DIM AS STRING pathString
      vecCount = 0
      'PRINT #__logfile, USING "player id: #### name: & hash: ############ playerxy: ##### #####"; playerID; __fzxBody(playerID).objectName; __fzxBody(playerID).objectHash; __fzxBody(playerID).fzx.position.x; __fzxBody(playerID).fzx.position.y
      FOR xs = -6 TO 6
        FOR ys = -6 TO 6
          IF xs <> 0 OR ys <> 0 THEN
            fzxVector2DSet tempVec, xs, ys
            vector2dToGameMapXY tilemap, __fzxBody(playerID).fzx.position, tempVec2
            fzxVector2DAddVectorND tempVec, tempVec, tempVec2
            pathString = AStarSetPath$(__gmEntity(playerID), tempVec2, tempVec, tilemap)
            'PRINT #__logfile, "xpos:"; xs; " ypos:"; ys; " path:"; pathString
            IF LEN(pathString) <= __gmEntity(playerID).stats.ap AND LEN(pathString) > 0 THEN
              vecs(vecCount) = tempVec
              vecCount = vecCount + 1
            END IF
          END IF
        NEXT
      NEXT
      __gmEngine.guiRefresh = 1
      updateGUI cGUI_LAYOUT_HUD, tilemap
      fzxFSMChangeState __gmEngine.gameMode, cFSM_GAMEMODE_COMBAT_PLAYER_TURN

    CASE cFSM_GAMEMODE_COMBAT_PLAYER_TURN:

      handleGUI tilemap
      IF __fzxInputDevice.keyboard.keyHitPosEdge = 27 THEN
        'fzxVector2DSet position, 100, 100
        'addMessage tile(), tilemap, message(), "LEAVING COMBAT", 1, position, 3.0
        consoleOut tile(), tilemap, "Leaving Combat"
        fzxFSMChangeState __gmEngine.gameMode, cFSM_GAMEMODE_GAMEPLAY
      END IF

      IF __fzxInputDevice.mouse.b2.PosEdge THEN
        moveCamera __fzxBody(mouseID).fzx.position
      END IF

      renderBodies tilemap
      '_DEST __gmEngine.overlayScr
      FOR indx = 0 TO vecCount - 1
        gameMapXYToVector2d tilemap, vecs(indx), tempVec2
        fzxVector2DSet tempVec2, tempVec2.x + tilemap.tileWidth / 2, tempVec2.y + tilemap.tileHeight / 2
        IF __fzxInputDevice.mouse.gamePosition.x = vecs(indx).x AND __fzxInputDevice.mouse.gamePosition.y = vecs(indx).y THEN
          renderSolidCircleVector tempVec2, 2, _RGB32(233, 11, 50)
          IF __fzxInputDevice.mouse.b1.PosEdge THEN
            moveEntity __gmEntity(playerID), __fzxInputDevice.mouse.worldPosition, tilemap
          END IF
        ELSE
          renderSolidCircleVector tempVec2, 2, _RGB32(200, 150, 0)
        END IF
      NEXT
      '_DEST 0
      'updateGUI cGUI_LAYOUT_HUD
      IF __gmEntity(playerID).stats.ap <= 0 THEN
        __gmEntity(playerID).stats.ap = __gmEntity(playerID).stats.apMax
        fzxFSMChangeState __gmEngine.gameMode, cFSM_GAMEMODE_COMBAT_ENEMY_TURN
        consoleOut tile(), tilemap, "ENEMY TURN!"
      END IF

    CASE cFSM_GAMEMODE_COMBAT_ENEMY_TURN:

      __gmEngine.gameMode.timerState.duration = 6
      fzxFSMChangeStateOnTimer __gmEngine.gameMode, cFSM_GAMEMODE_COMBAT_SETUP
      renderBodies tilemap

    CASE ELSE
  END SELECT
END SUB


SUB handleGUI (tilemap AS tTILEMAP)
  DIM AS LONG playerId, targetID, guiBtnId, indx
  playerId = entityManagerID("PLAYER")
  targetID = __gmEntity(playerId).parameters.target

  guiBtnId = isOnGUISensor(__fzxInputDevice.mouse.position)

  IF guiBtnId > 0 THEN
    'clearScreen engine
    FOR indx = 0 TO UBOUND(__gmGuiFields)
      __gmGuiFields(indx).buttonState = cFZX_MOUSE_NONE
      IF guiBtnId = __gmGuiFields(indx).buttonId THEN
        IF __fzxInputDevice.mouse.b1.doubleClick THEN
          __gmGuiFields(indx).buttonState = cFZX_MOUSE_DOUBLECLICK ' Double Clicked -- This probably wont work unless button state 2 is ignored
        ELSE IF __fzxInputDevice.mouse.b1.button THEN
            __gmGuiFields(indx).buttonState = cFZX_MOUSE_CLICK ' Button Clicked
          ELSE
            __gmGuiFields(indx).buttonState = cFZX_MOUSE_HOVER ' Hover over Button
          END IF
        END IF
      END IF


      SELECT CASE __gmGuiFields(indx).menuType
        CASE cGUI_LAYOUT_HUD
          IF guiBtnId = 1 AND __gmGuiFields(indx).buttonState = cFZX_MOUSE_CLICK THEN
            moveEntity __gmEntity(playerId), __fzxInputDevice.mouse.worldPosition, tilemap
            fzxFSMChangeState __fzxCamera.fsm, cFSM_CAMERA_IDLE
          END IF

          IF __gmGuiFields(indx).buttonState = cFZX_MOUSE_CLICK THEN
            SELECT CASE guiBtnId
              CASE 61 '  scroll down
                __gmConsole.yPos = __gmConsole.yPos + tilemap.tileHeight: IF __gmConsole.yPos > _HEIGHT(__gmConsole.img) THEN __gmConsole.yPos = _HEIGHT(__gmConsole.img)
              CASE 62 ' scroll up
                __gmConsole.yPos = __gmConsole.yPos - tilemap.tileHeight: IF __gmConsole.yPos < 0 THEN __gmConsole.yPos = 0
              CASE 60 ' consoleswitch
                __gmEngine.gui.hud = cGUI_LAYOUT_HUD_LARGE_CONSOLE
                __gmEngine.guiRefresh = TRUE
                updateGUI __gmEngine.gui.hud, tilemap
                __gmConsole.yPos = fzxScalarMax(0, __gmConsole.lc - __gmConsole.ySize) * 16 'tilemap.tileHeight
            END SELECT
          END IF
        CASE cGUI_LAYOUT_HUD_LARGE_CONSOLE

          IF guiBtnId = 2 AND __gmGuiFields(indx).buttonState = cFZX_MOUSE_CLICK THEN
            moveEntity __gmEntity(playerId), __fzxInputDevice.mouse.worldPosition, tilemap
            fzxFSMChangeState __fzxCamera.fsm, cFSM_CAMERA_IDLE
          END IF

          IF __gmGuiFields(indx).buttonState = cFZX_MOUSE_CLICK THEN
            SELECT CASE guiBtnId
              CASE 71 '  scroll down
                __gmConsole.yPos = __gmConsole.yPos + tilemap.tileHeight: IF __gmConsole.yPos > _HEIGHT(__gmConsole.img) THEN __gmConsole.yPos = _HEIGHT(__gmConsole.img)
              CASE 70 ' scroll up
                __gmConsole.yPos = __gmConsole.yPos - tilemap.tileHeight: IF __gmConsole.yPos < 0 THEN __gmConsole.yPos = 0
              CASE 72 ' console switch
                __gmEngine.gui.hud = cGUI_LAYOUT_HUD
                __gmEngine.guiRefresh = TRUE
                updateGUI __gmEngine.gui.hud, tilemap
                __gmConsole.yPos = fzxScalarMax(0, __gmConsole.lc - __gmConsole.ySize) * 16 'tilemap.tileHeight
            END SELECT
          END IF

        CASE cGUI_LAYOUT_LOOT
          IF __gmGuiFields(indx).buttonState = cFZX_MOUSE_CLICK THEN
            SELECT CASE guiBtnId
              CASE 100 ' loot scroll up
              CASE 101 ' loot scroll down
              CASE 102 ' move inventory to loot
              CASE 103 ' move loot to inventory
              CASE 110 ' equip ring
              CASE 111 ' equip helm
              CASE 112 ' equip necklace
              CASE 113 ' equip right glove
              CASE 114 ' equip body armor
              CASE 115 ' equip left glove
              CASE 116 ' equip shield
              CASE 117 ' equip boots
              CASE 118 ' equip weapon

              CASE 255 ' exit
                clearScreen
                __gmEngine.guiRefresh = TRUE
                updateGUI cGUI_LAYOUT_HUD, tilemap
                fzxFSMChangeState __gmEngine.gameMode, cFSM_GAMEMODE_GAMEPLAY
                __gmEntity(targetID).parameters.activated = 0
            END SELECT
          END IF
      END SELECT
    NEXT
  END IF
END SUB

SUB handlePlayerInput (tile() AS tTILE, tilemap AS tTILEMAP, message() AS tMESSAGE)


  DIM AS LONG playerId, mouseId
  DIM AS tFZX_VECTOR2d tempVec, mpos, position
  playerId = entityManagerID("PLAYER")
  IF playerId < 0 THEN
    PRINT "Object does not exist!": waitkey: END
  END IF

  __fzxInputDevice.mouse.mouseMode = 1
  mouseId = fzxBodyManagerID("_mouse")

  ' Camera Zoom -- Mouse Scroll Wheel

  __fzxCamera.zoom = __fzxCamera.zoom - (__fzxInputDevice.mouse.wCount * .025)
  IF __fzxCamera.zoom < 0.5 THEN __fzxCamera.zoom = 0.5: __fzxInputDevice.mouse.wCount = 0
  IF __fzxCamera.zoom > 3.5 THEN __fzxCamera.zoom = 3.5: __fzxInputDevice.mouse.wCount = 0
  __fzxInputDevice.mouse.wCount = 0


  mpos = __fzxInputDevice.mouse.position

  IF __fzxInputDevice.keyboard.keyHitPosEdge = ASC("i") THEN
    fzxFSMChangeState __gmEngine.gameMode, cFSM_GAMEMODE_INVENTORY_SETUP
  END IF

  IF __fzxInputDevice.keyboard.keyHitPosEdge = ASC("l") THEN
    fzxFSMChangeState __gmEngine.gameMode, cFSM_GAMEMODE_LOOTMENU_SETUP
  END IF

  IF __fzxInputDevice.keyboard.keyHitPosEdge = ASC("p") THEN
    fzxFSMChangeState __gmEngine.gameMode, cFSM_GAMEMODE_COMBAT_SETUP
    consoleOut tile(), tilemap, "Combat!"
  END IF

  IF 0 THEN ' disabled for now
    IF _KEYDOWN(32) OR _KEYDOWN(87) OR _KEYDOWN(119) OR _KEYDOWN(18432) THEN
      __fzxBody(__gmEntity(playerId).objectID).fzx.force.y = -(__gmEntity(playerId).parameters.maxForce.y / 100)
    END IF

    IF _KEYDOWN(20480) THEN
      __fzxBody(__gmEntity(playerId).objectID).fzx.force.y = (__gmEntity(playerId).parameters.maxForce.y / 100)
    END IF

    IF _KEYDOWN(65) OR _KEYDOWN(97) OR _KEYDOWN(19200) THEN
      __fzxBody(__gmEntity(playerId).objectID).fzx.force.x = -(__gmEntity(playerId).parameters.maxForce.x)
    END IF

    IF _KEYDOWN(68) OR _KEYDOWN(100) OR _KEYDOWN(19712) THEN
      __fzxBody(__gmEntity(playerId).objectID).fzx.force.x = __gmEntity(playerId).parameters.maxForce.x
    END IF

    __fzxBody(__gmEntity(playerId).objectID).fzx.velocity.x = fzxImpulseClamp(-1000, 1000, __fzxBody(__gmEntity(playerId).objectID).fzx.velocity.x)
    __fzxBody(__gmEntity(playerId).objectID).fzx.velocity.y = fzxImpulseClamp(-1000, 1000, __fzxBody(__gmEntity(playerId).objectID).fzx.velocity.y)
  END IF

  IF __fzxInputDevice.mouse.b1.PosEdge THEN
    'isOnSensor returns the body ID of the sensor that the mouse is touching (as long it is under 256)
    DIM AS LONG volumeControlID
    volumeControlID = entityManagerID("enVOLCONTROL")
    SELECT CASE isOnSensor(mpos)
      CASE fzxBodyManagerID("senVolumeUp"):
        IF __gmOptions.musicVolume <= 1.0 THEN
          __gmOptions.musicVolume = __gmOptions.musicVolume + 0.1
          __fzxBody(__gmEntity(volumeControlID).objectID).fzx.position.x = __fzxBody(__gmEntity(volumeControlID).objectID).fzx.position.x + tilemap.tileWidth
        END IF
      CASE fzxBodyManagerID("senVolumeDown"):
        IF __gmOptions.musicVolume >= 0.0 THEN
          __gmOptions.musicVolume = __gmOptions.musicVolume - 0.1
          __fzxBody(__gmEntity(volumeControlID).objectID).fzx.position.x = __fzxBody(__gmEntity(volumeControlID).objectID).fzx.position.x - tilemap.tileWidth
        END IF
      CASE ELSE
    END SELECT
  END IF
  IF __fzxInputDevice.mouse.b2.PosEdge THEN ' Move camera
    moveCamera __fzxBody(mouseId).fzx.position
  END IF


  ' If player has stopped moving, and camera was sitting still then move the camera to the player
  IF __gmEntity(playerId).fsmPrimary.currentState = cFSM_ENTITY_IDLE AND __gmEntity(playerId).fsmPrimary.previousState = cFSM_ENTITY_MOVE AND __fzxCamera.fsm.previousState <> cFSM_CAMERA_MOVING THEN
    IF fzxIsBodyTouchingBody(__gmEntity(playerId).objectID, fzxBodyManagerID("senCENTER_CAMERA")) THEN
      moveCamera __fzxBody(__gmEntity(playerId).objectID).fzx.position
    ELSE
      findLandmarkPosition __gmLandmark(), "lmCAMERA_CENTER", tempVec
      moveCamera tempVec
    END IF
  END IF

END SUB


SUB handleMapSpecific (tile() AS tTILE, tilemap AS tTILEMAP, message() AS tMESSAGE)

  DIM AS LONG playerId
  DIM AS tFZX_VECTOR2d tempVec, mpos
  playerId = entityManagerID("PLAYER")
  IF playerId < 0 THEN
    PRINT "Object does not exist!": waitkey: END
  END IF
  mpos = __fzxInputDevice.mouse.position
  SELECT CASE _TRIM$(__gmEngine.currentMap)
    CASE "Main_Menu.tmx"
      IF NOT fzxIsBodyTouchingBody(__gmEntity(playerId).objectID, fzxBodyManagerID("senMUSIC_1")) THEN
        playMusic __gmPlayList, __gmSounds(), "MUSIC_1"
      END IF

      IF NOT fzxIsBodyTouchingBody(__gmEntity(playerId).objectID, fzxBodyManagerID("senMUSIC_2")) THEN
        playMusic __gmPlayList, __gmSounds(), "MUSIC_2"
      END IF

      IF NOT fzxIsBodyTouchingBody(__gmEntity(playerId).objectID, fzxBodyManagerID("senMUSIC_3")) THEN
        playMusic __gmPlayList, __gmSounds(), "BACKGROUND"
      END IF


      IF NOT fzxIsBodyTouchingBody(__gmEntity(playerId).objectID, fzxBodyManagerID("senQUIT_N")) THEN
        findLandmarkPosition __gmLandmark(), "lmNEVERMIND", tempVec
        fzxSetBody cFZX_PARAMETER_POSITION, __gmEntity(playerId).objectID, tempVec.x, tempVec.y
        moveCamera __fzxBody(__gmEntity(playerId).objectID).fzx.position
      END IF

      IF NOT fzxIsBodyTouchingBody(__gmEntity(playerId).objectID, fzxBodyManagerID("senQUIT_Y")) THEN
        SYSTEM
      END IF

      IF NOT fzxIsBodyTouchingBody(__gmEntity(playerId).objectID, fzxBodyManagerID("senCREDITS")) THEN
        moveCamera __fzxBody(__gmEntity(playerId).objectID).fzx.position
        fzxFSMChangeState __gmEngine.gameMode, cFSM_GAMEMODE_CREDITS_SETUP
      END IF

      IF NOT fzxIsBodyTouchingBody(__gmEntity(playerId).objectID, fzxBodyManagerID("senQUIT")) THEN
        stopMusic __gmPlayList
        findLandmarkPosition __gmLandmark(), "lmQUIT", tempVec
        fzxSetBody cFZX_PARAMETER_POSITION, __gmEntity(playerId).objectID, tempVec.x, tempVec.y
        moveCamera __fzxBody(__gmEntity(playerId).objectID).fzx.position
      END IF

      IF NOT fzxIsBodyTouchingBody(__gmEntity(playerId).objectID, fzxBodyManagerID("senOPTIONS")) THEN
        findLandmarkPosition __gmLandmark(), "lmOptions", tempVec
        fzxSetBody cFZX_PARAMETER_POSITION, __gmEntity(playerId).objectID, tempVec.x, tempVec.y
        moveCamera __fzxBody(__gmEntity(playerId).objectID).fzx.position
      END IF

      IF NOT fzxIsBodyTouchingBody(__gmEntity(playerId).objectID, fzxBodyManagerID("senReturnToMainMenu")) THEN
        findLandmarkPosition __gmLandmark(), "lmNEVERMIND", tempVec
        fzxSetBody cFZX_PARAMETER_POSITION, __gmEntity(playerId).objectID, tempVec.x, tempVec.y
        moveCamera __fzxBody(__gmEntity(playerId).objectID).fzx.position
      END IF
    CASE "Level_1.tmx"
      IF NOT fzxIsBodyTouchingBody(__gmEntity(playerId).objectID, fzxBodyManagerID("senMUSIC_2")) THEN
        playMusic __gmPlayList, __gmSounds(), "MUSIC_2"
      END IF
    CASE "PLAYERLAB.tmx"
      IF NOT fzxIsBodyTouchingBody(__gmEntity(playerId).objectID, fzxBodyManagerID("senMUSIC_1")) THEN
        playMusic __gmPlayList, __gmSounds(), "MUSIC_3"
      END IF

  END SELECT
END SUB



FUNCTION handleMapChange (tile() AS tTILE, tilemap AS tTILEMAP, message() AS tMESSAGE)

  DIM AS LONG door, playerId, playerBodyId
  DIM AS tDOOR tempDoor
  DIM AS tFZX_VECTOR2d tempVec
  handleMapChange = 0
  door = handleDoors
  IF NOT door THEN
    'PRINT #__logfile, "Current Map: "; _TRIM$(__gmEngine.currentMap)
    'PRINT #__logfile, "Door name:"; __gmPortals(door).doorName
    ' __gmPortals(UBOUND(__gmPortals) - 1).map
    stopMusic __gmPlayList
    tempDoor = __gmPortals(door): 'make a copy of the activated Door
    REDIM context(0) AS tFZX_STRINGTUPLE
    freeAllTiles tile()
    clearMapData tile(), message()
    removeAllMusic __gmPlayList, __gmSounds()
    __gmEngine.currentMap = _TRIM$(tempDoor.map)
    XMLparse _CWD$ + OSPathJoin$ + "Assets" + OSPathJoin$ + _TRIM$(__gmEngine.currentMap), context()
    XMLapplyAttributes tile(), tilemap, context()
    ' Mouse pointer = 516
    REDIM context(0) AS tFZX_STRINGTUPLE
    XMLparse _TRIM$(__gmEngine.assetsDirectory) + _TRIM$(__gmEngine.gui.inventoryMapFile), context()
    XMLGUI __gmEngine.gui.inventoryMapFile, __gmGuiLayout(cGUI_LAYOUT_INVENTORY), context(), 1
    REDIM context(0) AS tFZX_STRINGTUPLE
    XMLparse _TRIM$(__gmEngine.assetsDirectory) + _TRIM$(__gmEngine.gui.lootMapFile), context()
    XMLGUI __gmEngine.gui.lootMapFile, __gmGuiLayout(cGUI_LAYOUT_LOOT), context(), 0

    initInputDevice tile(idToTile(tile(), 516 + 1)).t

    '        __gmEntity(playerID).objectID = playerBodyID

    playerId = entityManagerID("PLAYER")
    playerBodyId = fzxBodyManagerID("PLAYER")

    IF playerId < 0 OR playerBodyId < 0 THEN
      PRINT "Player does not exist!    playerId: "; playerId; "  playerBodyID: "; playerBodyId: waitkey: END
    END IF

    findLandmarkPositionHash __gmLandmark(), tempDoor.landmarkHash, tempVec
    fzxSetBody cFZX_PARAMETER_POSITION, __gmEntity(playerId).objectID, tempVec.x, tempVec.y
    moveCamera __fzxBody(__gmEntity(playerId).objectID).fzx.position
    fzxCalculateFOV
    'PRINT #__logfile, "PlayerEntityId: "; playerId; "  playerBodyID: "; playerBodyId
    'PRINT #__logfile, "New Map: "; _TRIM$(__gmEngine.currentMap)
    'PRINT #__logfile, "Landmark: "; __gmLandmark(findLandmarkHash(__gmLandmark(), tempDoor.landmarkHash)).landmarkName
    'PRINT #__logfile, USING " pos: ##### #####"; tempVec.x; tempVec.y
    __debugDumpBodies
    handleMapChange = -1
  END IF

END FUNCTION

SUB updateGUI (gui AS LONG, tilemap AS tTILEMAP)
  __gmEngine.gui.hud = gui
  IF __gmEngine.guiRefresh THEN
    __gmEngine.guiRefresh = 0
    DIM m AS tMESSAGE
    DIM AS LONG indx, playerID
    playerID = entityManagerID("PLAYER")
    ' clear the overlay screen
    clearOverlayScr
    clearSensorMap
    ' put the template image on the overlay screen
    ' setup the message construct
    m.baseImage = __gmGuiLayout(gui).tileMap
    m.scale = .5
    m.bgColor = __gmEngine.displayClearColor
    ' iterate through the fields
    FOR indx = 1 TO UBOUND(__gmGuiFields)
      ' is the field on this particular menu?
      IF gui = __gmGuiFields(indx).menuType THEN
        ' set message construct to its position
        m.position = __gmGuiFields(indx).position
        ' _DEST __gmEngine.displayScr
        _DEST __gmEngine.overlayScr
        ' Select which menu is active and fill in the fields for that menu.

        SELECT CASE __gmGuiFields(indx).menuType
          CASE cGUI_LAYOUT_INVENTORY
            SELECT CASE _TRIM$(__gmGuiFields(indx).Id)
              CASE "fNAME"
                renderText __gmGuiTile(), __gmGuiLayout(cGUI_LAYOUT_INVENTORY), m, formatString$(__gmEntity(playerID).stats.nameString, 12)
              CASE "fACTION"
                renderText __gmGuiTile(), __gmGuiLayout(cGUI_LAYOUT_INVENTORY), m, formatNumberString$(__gmEntity(playerID).stats.ap, 3)
              CASE "fACTION_MAX"
                renderText __gmGuiTile(), __gmGuiLayout(cGUI_LAYOUT_INVENTORY), m, formatNumberString$(__gmEntity(playerID).stats.apMax, 3)
              CASE "fHEALTH"
                renderText __gmGuiTile(), __gmGuiLayout(cGUI_LAYOUT_INVENTORY), m, formatNumberString$(__gmEntity(playerID).stats.hp, 3)
              CASE "fHEALTH_MAX"
                renderText __gmGuiTile(), __gmGuiLayout(cGUI_LAYOUT_INVENTORY), m, formatNumberString$(__gmEntity(playerID).stats.hpMax, 3)
              CASE "fSTAMINA"
                renderText __gmGuiTile(), __gmGuiLayout(cGUI_LAYOUT_INVENTORY), m, formatNumberString$(__gmEntity(playerID).stats.stamina, 3)
              CASE "fSTAMINA_MAX"
                renderText __gmGuiTile(), __gmGuiLayout(cGUI_LAYOUT_INVENTORY), m, formatNumberString$(__gmEntity(playerID).stats.staminaMax, 3)
              CASE "fMANA"
                renderText __gmGuiTile(), __gmGuiLayout(cGUI_LAYOUT_INVENTORY), m, formatNumberString$(__gmEntity(playerID).stats.mana, 3)
              CASE "fMANA_MAX"
                renderText __gmGuiTile(), __gmGuiLayout(cGUI_LAYOUT_INVENTORY), m, formatNumberString$(__gmEntity(playerID).stats.manaMax, 3)
              CASE "fHUNGER"
                renderText __gmGuiTile(), __gmGuiLayout(cGUI_LAYOUT_INVENTORY), m, formatNumberString$(__gmEntity(playerID).stats.hunger, 2)
              CASE "fTHIRST"
                renderText __gmGuiTile(), __gmGuiLayout(cGUI_LAYOUT_INVENTORY), m, formatNumberString$(__gmEntity(playerID).stats.thirst, 2)
              CASE "fLEVEL"
                renderText __gmGuiTile(), __gmGuiLayout(cGUI_LAYOUT_INVENTORY), m, formatNumberString$(__gmEntity(playerID).stats.level, 3)
              CASE "fXP"
                renderText __gmGuiTile(), __gmGuiLayout(cGUI_LAYOUT_INVENTORY), m, formatNumberString$(__gmEntity(playerID).stats.xp, 4)
              CASE "fGOLD"
                renderText __gmGuiTile(), __gmGuiLayout(cGUI_LAYOUT_INVENTORY), m, formatNumberString$(__gmEntity(playerID).stats.gold, 6)
              CASE "fDEFENSE"
                renderText __gmGuiTile(), __gmGuiLayout(cGUI_LAYOUT_INVENTORY), m, formatNumberString$(0, 3)
              CASE "fOFFENSE"
                renderText __gmGuiTile(), __gmGuiLayout(cGUI_LAYOUT_INVENTORY), m, formatNumberString$(0, 3)
            END SELECT
          CASE cGUI_LAYOUT_LOOT
            SELECT CASE _TRIM$(__gmGuiFields(indx).Id)
              CASE "fINV_LIST"
                renderTextEx __gmGuiTile(), __gmGuiLayout(cGUI_LAYOUT_LOOT), m, formatString$("~00370 test", 9)
              CASE "fINV_LOOT"
                renderTextEx __gmGuiTile(), __gmGuiLayout(cGUI_LAYOUT_LOOT), m, formatString$("~00422 test", 9)
              CASE "fGOLD"
                renderText __gmGuiTile(), __gmGuiLayout(cGUI_LAYOUT_INVENTORY), m, formatNumberString$(__gmEntity(playerID).stats.gold, 6)
            END SELECT

          CASE cGUI_LAYOUT_HUD
            IF __gmEngine.gameMode.currentState = cFSM_GAMEMODE_COMBAT_PLAYER_TURN THEN
            END IF
            ' TODO : this will have to be fixed later with a value from tile UDT
            __gmConsole.xSize = 58
            __gmConsole.ySize = 4
            __gmConsole.yPos = fzxScalarMax(0, __gmConsole.lc - __gmConsole.ySize) * tilemap.tileHeight
            SELECT CASE _TRIM$(__gmGuiFields(indx).Id)
              CASE "fNAME"
                renderText __gmGuiTile(), __gmGuiLayout(cGUI_LAYOUT_HUD), m, formatString$(__gmEntity(playerID).stats.nameString, 12)
              CASE "fAP"
                renderText __gmGuiTile(), __gmGuiLayout(cGUI_LAYOUT_HUD), m, formatNumberString$(__gmEntity(playerID).stats.ap, 2)
              CASE "fHP"
                renderText __gmGuiTile(), __gmGuiLayout(cGUI_LAYOUT_HUD), m, formatNumberString$(__gmEntity(playerID).stats.hp, 3)
              CASE "fHPMax"
                renderText __gmGuiTile(), __gmGuiLayout(cGUI_LAYOUT_HUD), m, formatNumberString$(__gmEntity(playerID).stats.hpMax, 3)
            END SELECT
          CASE cGUI_LAYOUT_HUD_LARGE_CONSOLE
            IF __gmEngine.gameMode.currentState = cFSM_GAMEMODE_COMBAT_PLAYER_TURN THEN
            END IF
            __gmConsole.xSize = 58
            __gmConsole.ySize = 20
            __gmConsole.yPos = fzxScalarMax(0, __gmConsole.lc - __gmConsole.ySize) * tilemap.tileHeight
            SELECT CASE _TRIM$(__gmGuiFields(indx).Id)
              CASE "fNAME"
                renderText __gmGuiTile(), __gmGuiLayout(cGUI_LAYOUT_HUD_LARGE_CONSOLE), m, formatString$(__gmEntity(playerID).stats.nameString, 12)
              CASE "fAP"
                renderText __gmGuiTile(), __gmGuiLayout(cGUI_LAYOUT_HUD_LARGE_CONSOLE), m, formatNumberString$(__gmEntity(playerID).stats.ap, 2)
              CASE "fHP"
                renderText __gmGuiTile(), __gmGuiLayout(cGUI_LAYOUT_HUD_LARGE_CONSOLE), m, formatNumberString$(__gmEntity(playerID).stats.hp, 3)
              CASE "fHPMax"
                renderText __gmGuiTile(), __gmGuiLayout(cGUI_LAYOUT_HUD_LARGE_CONSOLE), m, formatNumberString$(__gmEntity(playerID).stats.hpMax, 3)
            END SELECT

        END SELECT

        IF __gmGuiFields(indx).buttonId > 0 THEN
          ' If its a button then place a box in the sensormap so that it can be used later
          _DEST __gmEngine.gui.sensorMap
          LINE (__gmGuiFields(indx).position.x * 2, _
                __gmGuiFields(indx).position.y * 2 _
             )-(__gmGuiFields(indx).position.x * 2 + __gmGuiFields(indx).size.x * 2, _
                __gmGuiFields(indx).position.y * 2 + __gmGuiFields(indx).size.y * 2),_
                 _RGB32(0, 0, __gmGuiFields(indx).buttonId), BF
        END IF
      END IF
    NEXT
    _PUTIMAGE , __gmGuiLayout(gui).tileMap, __gmEngine.overlayScr
  END IF
  _DEST 0
END SUB


'**********************************************************************************************
'   Entity Management Subs
'**********************************************************************************************
SUB _______________ENTITY_MANAGEMENT (): END SUB
' Entities are add-ons to the fzxbodys they will not always
FUNCTION entityCreate (tilemap AS tTILEMAP, entityName AS STRING, position AS tFZX_VECTOR2d)
  DIM AS LONG index, tempid
  index = UBOUND(__gmEntity)

  tempid = fzxCreateBoxBodyEx(entityName, tilemap.tileWidth / 2.1, tilemap.tileHeight / 2.1)
  __gmEntity(index).objectID = tempid
  __gmEntity(index).objectHash = __fzxBody(tempid).objectHash
  fzxSetBody cFZX_PARAMETER_POSITION, tempid, position.x - tilemap.tileWidth, position.y - tilemap.tileHeight
  fzxSetBody cFZX_PARAMETER_NOPHYSICS, tempid, 0, 0
  fzxSetBody cFZX_PARAMETER_ENTITYID, tempid, index, 0

  setDefaultEntityStats index
  REDIM _PRESERVE __gmEntity(index + 1) AS tENTITY
  entityCreate = index
END FUNCTION

SUB setDefaultEntityStats (id AS LONG)
  __gmEntity(id).stats.nameString = "Isaac"
  __gmEntity(id).stats.level = 1
  __gmEntity(id).stats.xp = 0
  __gmEntity(id).stats.hpMax = 10
  __gmEntity(id).stats.hp = 10
  __gmEntity(id).stats.apMax = 5
  __gmEntity(id).stats.ap = 5
  __gmEntity(id).stats.staminaMax = 10
  __gmEntity(id).stats.stamina = 10
  __gmEntity(id).stats.manaMax = 10
  __gmEntity(id).stats.mana = 10
  __gmEntity(id).stats.gold = INT(RND * 20)
  __gmEntity(id).parameters.activated = 0
END SUB

FUNCTION entityManagerID (entityName AS STRING)
  DIM AS LONG id
  id = fzxBodyManagerID(entityName)

  IF id >= 0 THEN
    entityManagerID = __fzxBody(id).entityID
  ELSE
    entityManagerID = -1
  END IF
END FUNCTION

'**********************************************************************************************
'   Entity Behavior
'**********************************************************************************************
SUB _______________ENTITY_HANDLING (): END SUB

SUB moveEntity (entity AS tENTITY, endPos AS tFZX_VECTOR2d, tilemap AS tTILEMAP)
  DIM AS tFZX_VECTOR2d startPos, endPosDiv
  'Convert start and end to gamemap X and Y
  fzxVector2DSet startPos, INT(__fzxBody(entity.objectID).fzx.position.x / tilemap.tileWidth), INT(__fzxBody(entity.objectID).fzx.position.y / tilemap.tileHeight)
  fzxVector2DSet endPosDiv, INT(endPos.x / tilemap.tileWidth), INT(endPos.y / tilemap.tileHeight)
  entity.fsmSecondary.timerState.start = TIMER(.001)
  entity.fsmSecondary.timerState.duration = entity.fsmSecondary.timerState.start + entity.parameters.movementSpeed
  entity.fsmSecondary.arg3 = 1 'ARG3 in this case is used to keep track of the step in the A-star path
  entity.pathString = AStarSetPath$(entity, startPos, endPosDiv, tilemap)
  IF LEN(trim$(entity.pathString)) > 0 THEN ' make sure path was created
    fzxFSMChangeState entity.fsmPrimary, cFSM_ENTITY_MOVE
    fzxFSMChangeState entity.fsmSecondary, cFSM_ENTITY_MOVE_SETUP 'Calculate next tile
  END IF
END SUB

SUB handleEntitys (tile() AS tTILE, tilemap AS tTILEMAP)
  DIM AS LONG index, iD, playerID, mouseID, playerTouching, mouseTouching, hitP, hitM, hitPa, hitPb, hitMa, hitMb, mtest
  DIM AS _BYTE sameTouch
  DIM AS _FLOAT progress
  DIM AS STRING dir
  DIM AS tFZX_VECTOR2d temp

  playerID = fzxBodyManagerID("PLAYER")
  '  mouseID = fzxBodyManagerID("_mouse")
  mouseID = __fzxInputDevice.mouse.mouseBody
  IF playerID < 0 THEN
    PRINT "Player does not exist!": END
  END IF
  IF mouseID < 0 THEN
    PRINT "Mouse object does not exist!": END
  END IF


  FOR index = 0 TO UBOUND(__gmEntity)
    iD = __gmEntity(index).objectID

    'IF __gmEntity(index).parameters.activated THEN
    '  fzxSetBody p(), body(), cFZX_PARAMETER_TEXTURE, iD, tile(__gmEntity(index).parameters.activatedTile).t, 0
    'ELSE
    '  fzxSetBody p(), body(), cFZX_PARAMETER_TEXTURE, iD, tile(__gmEntity(index).parameters.normalTile).t, 0
    'END IF

    ' fzxisbodytouchingbody returns -1 for not bodies touching and the index of the fzxhits array if it is touching

    hitP = fzxIsBodyTouchingBody(playerID, iD)
    IF hitP > -1 THEN
      hitPa = __fzxHits(hitP).A: hitPb = __fzxHits(hitP).B
    END IF

    hitM = fzxIsBodyTouchingBody(mouseID, iD)
    IF hitM > -1 THEN
      hitMa = __fzxHits(hitM).A: hitMb = __fzxHits(hitM).B
    END IF
    ' is the player and the mouse touching the same thing?
    sameTouch = (hitM > -1 AND hitP > -1) AND (hitMa = iD OR hitMb = iD) AND (hitPa = iD OR hitPb = iD)

    IF hitP > -1 AND iD <> playerID THEN
      playerTouching = -1
    ELSE
      playerTouching = 0
    END IF

    IF hitM > -1 THEN
      mouseTouching = -1
    ELSE
      mouseTouching = 0
    END IF


    ' If entity is moving then
    '  - Primary FSM is for moving the whole trip
    '  - Secondary FSM is traversing tile to tile
    'Primary State Machine
    IF __gmEngine.gameMode.currentState <> cFSM_GAMEMODE_COMBAT_PLAYER_TURN OR iD = playerID THEN
      SELECT CASE __gmEntity(index).fsmPrimary.currentState
        CASE cFSM_ENTITY_IDLE:
          SELECT CASE __gmEntity(index).parameters.behavior
            CASE cENTITY_BEHAVIOR_NONE
            CASE cENTITY_BEHAVIOR_WANDER
              'pause for a few second between movements
              __gmEntity(index).fsmPrimary.timerState.duration = 5 + (RND * 5)
              fzxFSMChangeState __gmEntity(index).fsmPrimary, cFSM_ENTITY_WAIT
            CASE cENTITY_BEHAVIOR_CONTAINER
              IF __gmEngine.gameMode.currentState <> cFSM_GAMEMODE_LOOTMENU_SETUP AND __gmEngine.gameMode.currentState <> cFSM_GAMEMODE_LOOTMENU THEN
                'need to make sure player and mouse are touching the same thing
                IF __fzxInputDevice.mouse.b1.PosEdge THEN
                  IF sameTouch THEN
                    IF NOT __gmEntity(index).parameters.activated THEN
                      __gmEntity(playerID).parameters.target = index
                      __gmEntity(index).parameters.activated = NOT __gmEntity(index).parameters.activated

                      IF __gmEntity(index).parameters.activated THEN
                        fzxFSMChangeState __gmEngine.gameMode, cFSM_GAMEMODE_LOOTMENU_SETUP
                        fzxSetBody cFZX_PARAMETER_TEXTURE, iD, tile(__gmEntity(index).parameters.activatedTile).t, 0
                        ' findAdjacentTile tilemap, playerID, temp
                        ' fzxSetBody cFZX_PARAMETER_POSITION, playerID, temp.x, temp.y
                        EXIT SUB
                      ELSE
                        fzxSetBody cFZX_PARAMETER_TEXTURE, iD, tile(__gmEntity(index).parameters.normalTile).t, 0
                      END IF
                    END IF
                  END IF
                END IF
              END IF
          END SELECT
        CASE cFSM_ENTITY_WAIT:
          SELECT CASE __gmEntity(index).parameters.behavior
            CASE cENTITY_BEHAVIOR_NONE
            CASE cENTITY_BEHAVIOR_WANDER
              'pause for a few second between movements
              fzxFSMChangeStateOnTimer __gmEntity(index).fsmPrimary, cFSM_ENTITY_MOVE_SETUP
            CASE cENTITY_BEHAVIOR_CONTAINER
          END SELECT
        CASE cFSM_ENTITY_MOVE_SETUP:
          SELECT CASE __gmEntity(index).parameters.behavior
            CASE cENTITY_BEHAVIOR_NONE
            CASE cENTITY_BEHAVIOR_WANDER
              temp.x = __fzxBody(iD).fzx.position.x + ((RND * 5 - 2.5) * tilemap.tileWidth)
              temp.y = __fzxBody(iD).fzx.position.y + ((RND * 5 - 2.5) * tilemap.tileWidth)
              moveEntity __gmEntity(index), temp, tilemap
              ' Dont need to move state to FSM_MOVE because Move entity does it automatically
            CASE cENTITY_BEHAVIOR_CONTAINER
          END SELECT
        CASE cFSM_ENTITY_MOVE: 'Move whole trip
          'Secondary State Machine
          SELECT CASE __gmEntity(index).fsmSecondary.currentState
            CASE cFSM_ENTITY_IDLE:
            CASE cFSM_ENTITY_MOVE_SETUP: 'Determine next tile
              'pathstring is always have a length of what was initialized regardless of actual length, so we have to trim it
              IF __gmEntity(index).fsmSecondary.arg3 <= LEN(_TRIM$(__gmEntity(index).pathString)) THEN
                'extract next direction from pathstring
                dir = MID$(__gmEntity(index).pathString, __gmEntity(index).fsmSecondary.arg3, 1)
                'ARG 1 will be the start position
                __gmEntity(index).fsmSecondary.arg1 = __fzxBody(iD).fzx.position
                'ARG 2 will be the finish position
                SELECT CASE dir
                  CASE "U":
                    fzxVector2DSet __gmEntity(index).fsmSecondary.arg2, __fzxBody(iD).fzx.position.x, __fzxBody(iD).fzx.position.y - tilemap.tileHeight
                  CASE "D":
                    fzxVector2DSet __gmEntity(index).fsmSecondary.arg2, __fzxBody(iD).fzx.position.x, __fzxBody(iD).fzx.position.y + tilemap.tileHeight
                  CASE "L":
                    fzxVector2DSet __gmEntity(index).fsmSecondary.arg2, __fzxBody(iD).fzx.position.x - tilemap.tileWidth, __fzxBody(iD).fzx.position.y
                    fzxSetBody cFZX_PARAMETER_FLIPTEXTURE, iD, 1, 0
                  CASE "R":
                    fzxVector2DSet __gmEntity(index).fsmSecondary.arg2, __fzxBody(iD).fzx.position.x + tilemap.tileWidth, __fzxBody(iD).fzx.position.y
                    fzxSetBody cFZX_PARAMETER_FLIPTEXTURE, iD, 0, 0
                END SELECT
                'Center Entity on destination tile
                __gmEntity(index).fsmSecondary.arg2.x = INT(__gmEntity(index).fsmSecondary.arg2.x / tilemap.tileWidth) * tilemap.tileWidth + (tilemap.tileWidth / 2)
                __gmEntity(index).fsmSecondary.arg2.y = INT(__gmEntity(index).fsmSecondary.arg2.y / tilemap.tileHeight) * tilemap.tileHeight + (tilemap.tileHeight / 2)
                'Setup movement timers
                __gmEntity(index).fsmSecondary.timerState.start = TIMER(.001)
                __gmEntity(index).fsmSecondary.timerState.duration = __gmEntity(index).fsmSecondary.timerState.start + __gmEntity(index).parameters.movementSpeed
                fzxFSMChangeState __gmEntity(index).fsmSecondary, cFSM_ENTITY_MOVE
              ELSE
                'finish the trip
                fzxFSMChangeState __gmEntity(index).fsmPrimary, cFSM_ENTITY_IDLE
                fzxFSMChangeState __gmEntity(index).fsmSecondary, cFSM_ENTITY_IDLE
                IF __gmEngine.gameMode.currentState = cFSM_GAMEMODE_COMBAT_PLAYER_TURN AND iD = playerID THEN
                  fzxFSMChangeState __gmEngine.gameMode, cFSM_GAMEMODE_COMBAT_SETUP
                END IF
              END IF
            CASE cFSM_ENTITY_MOVE: 'Move between individual tiles
              progress = fzxScalarLERPProgress(__gmEntity(index).fsmSecondary.timerState.start, __gmEntity(index).fsmSecondary.timerState.duration)
              fzxVector2DLERP __fzxBody(iD).fzx.position, __gmEntity(index).fsmSecondary.arg1, __gmEntity(index).fsmSecondary.arg2, progress
              IF fzxScalarRoughEqual(progress, 1.0, .1) THEN 'When done move to the next step
                'increment to next step
                __gmEntity(index).fsmSecondary.arg3 = __gmEntity(index).fsmSecondary.arg3 + 1
                fzxFSMChangeState __gmEntity(index).fsmSecondary, cFSM_ENTITY_MOVE_SETUP
                IF __gmEngine.gameMode.currentState = cFSM_GAMEMODE_COMBAT_PLAYER_TURN AND iD = playerID THEN
                  __gmEntity(index).stats.ap = __gmEntity(index).stats.ap - 1
                  IF __gmEntity(index).stats.ap < 0 THEN
                    __gmEntity(index).stats.ap = __gmEntity(index).stats.apMax
                    fzxFSMChangeState __gmEntity(index).fsmPrimary, cFSM_ENTITY_IDLE
                    fzxFSMChangeState __gmEntity(index).fsmSecondary, cFSM_ENTITY_IDLE
                    fzxFSMChangeState __gmEngine.gameMode, cFSM_GAMEMODE_COMBAT_SETUP
                  END IF
                  ' update the hud after AP change
                  __gmEngine.guiRefresh = 1
                  updateGUI __gmEngine.gui.hud, tilemap 'cGUI_LAYOUT_HUD
                END IF
              END IF
          END SELECT
      END SELECT
    END IF
  NEXT
END SUB


SUB findAdjacentTile (tilemap AS tTILEMAP, entityID AS LONG, o AS tFZX_VECTOR2d)
  DIM AS tFZX_VECTOR2d tempvec, tempvec2
  DIM AS LONG xs, ys

  FOR xs = -1 TO 1
    FOR ys = -1 TO 1
      IF xs <> 0 OR ys <> 0 THEN
        fzxVector2DSet tempvec, xs, ys
        vector2dToGameMapXY tilemap, __fzxBody(entityID).fzx.position, tempvec2
        fzxVector2DAddVectorND tempvec, tempvec, tempvec2
        IF AStarCollision(tilemap, tempvec) THEN
          gameMapXYToVector2d tilemap, tempvec, o
          addTileCenter tilemap, o, o
          EXIT SUB
        END IF
      END IF
    NEXT
  NEXT
END SUB
'**********************************************************************************************
'   Inventory
'**********************************************************************************************
SUB _______________INVENTORY: END SUB

SUB archTypeInitialize (arch() AS tARCHTYPE, con() AS tFZX_STRINGTUPLE)
  DIM AS LONG index, uB
  DIM AS STRING contextName, argument
  FOR index = 0 TO UBOUND(con) - 1
    contextName = trim$(con(index).contextName)
    argument = trim$(con(index).arg)

    uB = UBOUND(arch)
    SELECT CASE contextName
      CASE "items item"
        addArchtypeEx arch(), _
        getXMLArgString(argument, " name="), _
        getXMLArgValue(argument, " category="), _
        getXMLArgValue(argument, " id="), _
        getXMLArgValue(argument, " sprite="), _
        getXMLArgValue(argument, " weight="), _
        getXMLArgValue(argument, " level="), _
        getXMLArgValue(argument, " stackCount=")
    END SELECT
  NEXT
END SUB
' Items are general and not specific to whats in the inventory i.e. short sword
SUB addArchtypeEx (arch() AS tARCHTYPE, n AS STRING, id AS LONG, itemType AS LONG, sp AS LONG, weight AS SINGLE, level AS LONG, stackCount AS LONG)
  DIM i AS tARCHTYPE
  i.nameString = n
  i.id = id
  i.itemType = itemType
  i.sprite = sp
  i.weight = weight
  i.level = level
  i.stackCount = stackCount
  addArchtype arch(), i
END SUB

SUB addArchtype (archtype() AS tARCHTYPE, itemI AS tARCHTYPE)
  archtype(UBOUND(archtype)) = itemI
  REDIM _PRESERVE archtype(UBOUND(archtype) + 1) AS tARCHTYPE
END SUB

FUNCTION addItemToContainer (arch() AS tARCHTYPE, container AS tCONTAINER, itemIndx AS LONG)
  DIM AS LONG indx, id, cnt, qty
  ' See if archtype is already in inventory
  FOR indx = 1 TO container.lItemCount
    id = readArrayLong(container.lItemId, indx)
    IF id = arch(itemIndx).id THEN ' id is specific to the item
      qty = readArrayLong(container.lItemQty, indx)
      ' make sure it does not exceed stack counts
      IF qty <= arch(itemIndx).stackCount THEN
        qty = qty + 1
        setArrayLong container.lItemQty, indx, qty
        EXIT FUNCTION
      END IF
    END IF
  NEXT
  ' Presumably this the first of this item in the inventory
  setArrayLong container.lItemId, container.lItemCount, arch(itemIndx).id
  setArrayLong container.lItemType, container.lItemCount, arch(itemIndx).itemType
  setArrayLong container.lItemQty, container.lItemCount, 1
  container.lItemCount = container.lItemCount + 1

END FUNCTION



'**********************************************************************************************
'   Collision Tools
'**********************************************************************************************
SUB _______________COLLISION_QUERY_TOOLS_EX: END SUB
FUNCTION isOnSensor (p AS tFZX_VECTOR2d)
  _SOURCE __gmEngine.hiddenScr
  isOnSensor = _BLUE(POINT(p.x, p.y))
  _SOURCE __gmEngine.displayScr
END FUNCTION

FUNCTION isOnGUISensor (p AS tFZX_VECTOR2d)
  _SOURCE __gmEngine.gui.sensorMap
  isOnGUISensor = _BLUE(POINT(p.x, p.y))
  _SOURCE __gmEngine.displayScr
END FUNCTION



'**********************************************************************************************
'   Misc Tools
'**********************************************************************************************
SUB _______________MISC: END SUB

SUB waitkey
  _DISPLAY
  DO: LOOP UNTIL INKEY$ <> ""
END SUB

FUNCTION formatNumberString$ (number AS LONG, length AS LONG)
  DIM l AS LONG
  DIM o AS STRING
  o = _TRIM$(STR$(number))
  l = LEN(o)
  formatNumberString = STRING$(length - l, "0") + o
END FUNCTION

FUNCTION formatString$ (i AS STRING, length AS LONG)
  DIM l AS LONG
  DIM o AS STRING
  o = _TRIM$(i)
  l = LEN(o)
  formatString = o + STRING$(length - l - 1, " ")
END FUNCTION

FUNCTION charProp& (ch AS STRING)
  DIM AS _BYTE ascii
  DIM AS LONG o
  ascii = ASC(LEFT$(ch, 1))
  SELECT EVERYCASE ascii
    CASE 48 TO 57
      o = o OR cIsNumber
    CASE 65 TO 90
      o = o OR cIsAlpha
      o = o OR cIsUpper
    CASE 97 TO 122
      o = o OR cIsAlpha
      o = o OR cIsLower
    CASE 32, 9
      o = o OR cIsWhiteSpace
    CASE 95
      o = o OR cIsUnderscore
    CASE 10, 13
      o = o OR cIsCRLF
    CASE 33, 43, 42, 45, 47, 60, 61, 62, 37, 94
      o = o OR cIsOperator
    CASE 33, 34, 39, 46, 58, 59, 63, 96
      o = o OR cIsPunc
    CASE 40, 41
      o = o OR cIsParenthesis
    CASE 0 TO 31
      o = o OR cIsControl
    CASE 128 TO 255
      o = o OR cIsSpecial
  END SELECT
  charProp = o
END FUNCTION

FUNCTION isChar (ch AS STRING, query AS LONG)
  isChar = charProp(ch) AND query
END FUNCTION


'**********************************************************************************************
'   World to Gamemap Conversions
'**********************************************************************************************

SUB ____________WORLD_AND_GAMEMAP_CONVERSION: END SUB

FUNCTION xyToGameMapPlain (tilemap AS tTILEMAP, x AS LONG, y AS LONG)
  DIM p AS tFZX_VECTOR2d
  fzxVector2DSet p, x, y
  xyToGameMapPlain = vector2dToGameMapPlain(tilemap, p)
END FUNCTION

FUNCTION vector2dToGameMapPlain (tilemap AS tTILEMAP, p AS tFZX_VECTOR2d)
  'IF p.x < 0 OR p.x > tilemap.tileWidth OR p.y < 0 OR p.y > tilemap.mapHeight THEN
  '  PRINT #__logfile, USING " tilemapsize : #### #### px: ###### py: #####"; tilemap.mapWidth; tilemap.mapHeight; p.x; p.y
  'END IF
  p.x = fzxImpulseClamp(0, tilemap.mapWidth, p.x)
  p.y = fzxImpulseClamp(0, tilemap.mapHeight, p.y)
  vector2dToGameMapPlain = p.x + (p.y * tilemap.mapWidth)
END FUNCTION

FUNCTION xyToGameMap (tilemap AS tTILEMAP, x AS LONG, y AS LONG)
  DIM p AS tFZX_VECTOR2d
  fzxVector2DSet p, x, y
  xyToGameMap = vector2dToGameMap(tilemap, p)
END FUNCTION

FUNCTION vector2dToGameMap (tilemap AS tTILEMAP, p AS tFZX_VECTOR2d)
  vector2dToGameMap = INT((((p.x * tilemap.tilescale) / tilemap.tileWidth) + ((p.y * tilemap.tilescale) / tilemap.tileHeight) * tilemap.mapWidth))
END FUNCTION

SUB vector2dToGameMapXY (tilemap AS tTILEMAP, p AS tFZX_VECTOR2d, o AS tFZX_VECTOR2d)
  o.x = INT((p.x * tilemap.tilescale) / tilemap.tileWidth)
  o.y = INT((p.y * tilemap.tilescale) / tilemap.tileHeight)
END SUB

SUB gameMapXYToVector2d (tilemap AS tTILEMAP, p AS tFZX_VECTOR2d, o AS tFZX_VECTOR2d)
  o.x = INT((p.x * tilemap.tilescale) * tilemap.tileWidth)
  o.y = INT((p.y * tilemap.tilescale) * tilemap.tileHeight)
END SUB

SUB addTileCenter (tilemap AS tTILEMAP, p AS tFZX_VECTOR2d, o AS tFZX_VECTOR2d)
  o.x = p.x + (tilemap.tileWidth / 2)
  o.y = p.y + (tilemap.tileHeight / 2)
END SUB


'**********************************************************************************************
'   TIMER
'**********************************************************************************************
SUB _______________TIMER_CODE: END SUB

SUB handleTimers
  DIM AS LONG i
  FOR i = 0 TO UBOUND(__gmTimers)
    __gmTimers(i).last = TIMER(.001)
  NEXT
END SUB

FUNCTION addTimer (duration AS LONG)
  __gmTimers(UBOUND(__gmTimers)).start = TIMER(.001)
  __gmTimers(UBOUND(__gmTimers)).duration = duration
  addTimer = UBOUND(__gmTimers)
  REDIM _PRESERVE __gmTimers(UBOUND(__gmTimers) + 1) AS tFZX_ELAPSEDTIMER
END FUNCTION

SUB freeTimer (index AS LONG)
  DIM AS LONG i
  FOR i = index TO UBOUND(__gmTimers) - 1
    __gmTimers(i) = __gmTimers(i + 1)
  NEXT
  REDIM _PRESERVE __gmTimers(UBOUND(__gmTimers) - 1) AS tFZX_ELAPSEDTIMER
END SUB


'**********************************************************************************************
'   Handle Input Devices
'**********************************************************************************************
SUB _______________INPUT_HANDLING (): END SUB

SUB initInputDevice (icon AS LONG)
  __fzxInputDevice.mouse.mouseIcon = icon
  __fzxInputDevice.mouse.mouseBody = fzxCreateCircleBodyEx("_mouse", 1)
  fzxSetBody cFZX_PARAMETER_POSITION, __fzxInputDevice.mouse.mouseBody, 0, 0
  fzxSetBody cFZX_PARAMETER_ORIENT, __fzxInputDevice.mouse.mouseBody, 0, 0
  fzxSetBody cFZX_PARAMETER_STATIC, __fzxInputDevice.mouse.mouseBody, 0, 0
  fzxSetBody cFZX_PARAMETER_NOPHYSICS, __fzxInputDevice.mouse.mouseBody, 1, 0
  __fzxInputDevice.mouse.mouseMode = 1
END SUB

SUB handleInputDevice (tilemap AS tTILEMAP)
  STATIC AS tFZX_VECTOR2d mouse
  STATIC AS tFZX_SETTINGS set
  __fzxSettings.mouse.doubleclickdelay = .25
  fzxHandleInputDevice
  IF __fzxInputDevice.mouse.mouseMode AND __fzxInputDevice.mouse.mouseOnScreen THEN
    'Mouse screen position to world
    'fzxVector2DSet mouse, __fzxInputDevice.mouse.position.x, __fzxInputDevice.mouse.position.y
    '    fzxCameratoWorldScEx  mouse, iDevice.mouse.worldPosition
    vector2dToGameMapXY tilemap, __fzxInputDevice.mouse.worldPosition, __fzxInputDevice.mouse.gamePosition
    fzxSetBody cFZX_PARAMETER_POSITION, __fzxInputDevice.mouse.mouseBody, __fzxInputDevice.mouse.worldPosition.x, __fzxInputDevice.mouse.worldPosition.y
    alphaImage 255, __fzxInputDevice.mouse.mouseIcon, __fzxInputDevice.mouse.position, __fzxCamera.zoom
  END IF
END SUB



'**********************************************************************************************
'   Camera Behavior
'**********************************************************************************************
SUB _______________CAMERA_HANDLING (): END SUB

SUB moveCamera (targetPosition AS tFZX_VECTOR2d)
  __fzxCamera.fsm.timerState.duration = 1
  __fzxCamera.fsm.arg1 = __fzxCamera.position
  __fzxCamera.fsm.arg2 = targetPosition
  __fzxCamera.fsm.arg3 = 0
  fzxFSMChangeState __fzxCamera.fsm, cFSM_CAMERA_MOVING
END SUB

SUB handleCamera
  DIM AS _FLOAT progress
  SELECT CASE __fzxCamera.fsm.currentState
    CASE cFSM_CAMERA_IDLE:
    CASE cFSM_CAMERA_MOVING:
      progress = fzxScalarLERPProgress(__fzxCamera.fsm.timerState.start, __fzxCamera.fsm.timerState.start + __fzxCamera.fsm.timerState.duration)
      fzxVector2DLERPSmoother __fzxCamera.position, __fzxCamera.fsm.arg1, __fzxCamera.fsm.arg2, progress
      IF progress > .95 THEN
        fzxFSMChangeState __fzxCamera.fsm, cFSM_CAMERA_IDLE
      END IF
  END SELECT
END SUB


'**********************************************************************************************
'   Rendering
'**********************************************************************************************
SUB _______________RENDERING (): END SUB
SUB renderBodies (tilemap AS tTILEMAP)
  DIM AS LONG i, layer
  DIM hitcount AS LONG
  DIM AS tFZX_VECTOR2d viewPortSize, viewPortCenter, camUpLeft, BB

  clearScreen
  fzxCalculateFOV
  fzxVector2DSet viewPortSize, _WIDTH, _HEIGHT
  fzxVector2DSet viewPortCenter, _WIDTH / 2.0, _HEIGHT / 2.0
  fzxVector2DSubVectorND camUpLeft, __fzxCamera.position, viewPortCenter
  FOR layer = 3 TO 0 STEP -1 ' Crude layering from rear to front
    FOR i = 0 TO UBOUND(__fzxBody)
      IF __fzxBody(i).shape.renderOrder = layer THEN
        IF __fzxBody(i).enable THEN
          'AABB to cut down on rendering objects out of camera view
          fzxVector2DAddVectorND BB, __fzxBody(i).fzx.position, __fzxCamera.AABB
          IF fzxAABBOverlap(camUpLeft.x, camUpLeft.y, viewPortSize.x, viewPortSize.y, BB.x, BB.y, __fzxCamera.AABB_size.x, __fzxCamera.AABB_size.y) THEN
            IF __fzxBody(i).shape.ty = cFZX_SHAPE_CIRCLE THEN
              IF __fzxBody(i).specFunc.func = 0 THEN '0-normal 1-sensor
                IF __fzxBody(i).shape.texture THEN
                  renderTexturedCircle i
                END IF
              ELSE
                _DEST __gmEngine.hiddenScr
                renderTexturedCircle i
                _DEST 0
              END IF
              IF cRENDER_WIREFRAME THEN renderWireframeCircle i
            ELSE IF __fzxBody(i).shape.ty = cFZX_SHAPE_POLYGON THEN
                IF __fzxBody(i).specFunc.func = 0 THEN
                  IF __fzxBody(i).shape.texture THEN
                    renderTexturedBox i
                  END IF
                ELSE
                  _DEST __gmEngine.hiddenScr
                  renderTexturedBox i
                  _DEST 0
                END IF
                IF cRENDER_WIREFRAME THEN renderWireFramePoly i
              END IF
            END IF
            IF cRENDER_AABB THEN
              DIM AS tFZX_VECTOR2d am, mm
              am.x = fzxScalarMax(__fzxBody(i).shape.maxDimension.x, __fzxBody(i).shape.maxDimension.y) / 2
              am.y = fzxScalarMax(__fzxBody(i).shape.maxDimension.x, __fzxBody(i).shape.maxDimension.y) / 2
              fzxVector2DNegND mm, am
              fzxWorldToCameraBodyNR i, am
              fzxWorldToCameraBodyNR i, mm
              LINE (am.x, am.y)-(mm.x, mm.y), _RGB(0, 255, 0), B
              CIRCLE (am.x, am.y), 5
            END IF
          END IF
        END IF
      END IF
    NEXT
  NEXT
  IF cRENDER_JOINTS THEN
    FOR i = 1 TO UBOUND(__fzxJoints)
      renderJoints i
    NEXT
  END IF
  'IF cRENDER_COLLISIONS THEN
  '  hitcount = 0
  '  DO WHILE __fzxHits(hitcount).A <> __fzxHits(hitcount).B
  '    renderWireframeCircleVector hits(hitcount).position, camera
  '    hitcount = hitcount + 1
  '    IF hitcount > UBOUND(hits) THEN EXIT DO
  '  LOOP
  'END IF
  IF __gmEngine.overlayEnable THEN
    _PUTIMAGE , __gmEngine.overlayScr, __gmEngine.displayScr
    FOR i = 1 TO UBOUND(__gmGuiFields)
      IF __gmGuiFields(i).buttonState = cFZX_MOUSE_HOVER THEN
        _DEST __gmEngine.displayScr
        ' draw a highlight around buttons
        LINE (__gmGuiFields(i).position.x * 2, _
              __gmGuiFields(i).position.y * 2 _
           )-(__gmGuiFields(i).position.x * 2 + __gmGuiFields(i).size.x * 2,_
              __gmGuiFields(i).position.y * 2 + __gmGuiFields(i).size.y * 2), _
              _RGB32(255, 255, 255), B , &B0101010101010101
        __gmGuiFields(i).buttonState = cFZX_MOUSE_NONE
      END IF

      SELECT CASE __gmEngine.gui.hud
        CASE cGUI_LAYOUT_HUD
          IF _TRIM$(__gmGuiFields(i).Id) = "fConsole" THEN
            _DEST __gmEngine.displayScr
            _PUTIMAGE (__gmGuiFields(i).position.x * 2, __gmGuiFields(i).position.y * 2)-(__gmGuiFields(i).position.x * 2 + __gmGuiFields(i).size.x * 2, __gmGuiFields(i).position.y * 2 + __gmGuiFields(i).size.y * 2), __gmConsole.img, __gmEngine.displayScr, (0, __gmConsole.yPos)-(__gmConsole.xSize * tilemap.tileWidth, __gmConsole.ySize * tilemap.tileHeight + __gmConsole.yPos)
          END IF
        CASE cGUI_LAYOUT_HUD_LARGE_CONSOLE
          IF _TRIM$(__gmGuiFields(i).Id) = "fConsoleLrg" THEN
            _DEST __gmEngine.displayScr
            _PUTIMAGE (__gmGuiFields(i).position.x * 2, __gmGuiFields(i).position.y * 2)-(__gmGuiFields(i).position.x * 2 + __gmGuiFields(i).size.x * 2, __gmGuiFields(i).position.y * 2 + __gmGuiFields(i).size.y * 2), __gmConsole.img, __gmEngine.displayScr, (0, __gmConsole.yPos)-(__gmConsole.xSize * tilemap.tileWidth, __gmConsole.ySize * tilemap.tileHeight + __gmConsole.yPos)
          END IF

      END SELECT
    NEXT
  END IF
END SUB

SUB initScreen (w AS LONG, h AS LONG, bpp AS LONG)
  _DELAY .5 ' Keeps from segfaulting when starting

  __gmEngine.renderPipeline = _MEMNEW(cSCREENLAYERS * 8)

  __gmEngine.displayScr = _NEWIMAGE(w, h, bpp)
  __gmEngine.hiddenScr = _NEWIMAGE(w, h, bpp)
  __gmEngine.overlayScr = _NEWIMAGE(w, h, bpp)
  __gmEngine.gui.sensorMap = _NEWIMAGE(w, h, bpp)
  SCREEN __gmEngine.displayScr
  _SCREENMOVE _MIDDLE

END SUB

SUB clearScreen
  _DEST __gmEngine.displayScr
  _PRINTMODE _KEEPBACKGROUND
  CLS , __gmEngine.displayClearColor
  _DEST __gmEngine.hiddenScr
  CLS , 0
  _DEST __gmEngine.displayScr
END SUB

SUB clearOverlayScr
  _DEST __gmEngine.overlayScr
  _PRINTMODE _KEEPBACKGROUND
  CLS , 0
  _DEST __gmEngine.displayScr
END SUB

SUB clearSensorMap
  _DEST __gmEngine.gui.sensorMap
  _PRINTMODE _KEEPBACKGROUND
  CLS , 0
  _DEST __gmEngine.displayScr
END SUB


SUB renderJoints (index AS LONG)
  DIM v1 AS tFZX_VECTOR2d
  DIM v2 AS tFZX_VECTOR2d
  fzxWorldToCameraBody __fzxJoints(index).body1, v1
  fzxWorldToCameraBody __fzxJoints(index).body2, v2
  LINE (v1.x, v1.y)-(v2.x, v2.y), __fzxJoints(index).wireframe_color
END SUB

SUB renderWireFramePoly (index AS LONG) STATIC
  DIM AS LONG polyCount, i
  polyCount = fzxGetBodyD(CFZX_PARAMETER_POLYCOUNT, index, 0)
  DIM AS tFZX_VECTOR2d vert1, vert2
  i = 0: DO WHILE i <= polyCount
    fzxGetBodyVert index, i, vert1
    fzxGetBodyVert index, fzxArrayNextIndex(i, polyCount), vert2

    fzxWorldToCamera index, vert1
    fzxWorldToCamera index, vert2
    LINE (vert1.x, vert1.y)-(vert2.x, vert2.y), _RGB(0, 255, 0)
  i = i + 1: LOOP
END SUB

SUB renderTexturedBox (index AS LONG)
  DIM vert(3) AS tFZX_VECTOR2d

  DIM AS SINGLE W, H
  DIM bm AS LONG ' Texture map
  bm = __fzxBody(index).shape.texture
  W = _WIDTH(bm): H = _HEIGHT(bm)

  DIM i AS LONG
  FOR i = 0 TO 3
    fzxGetBodyVert index, i, vert(i)
    vert(i).x = vert(i).x + __fzxBody(index).shape.offsetTexture.x
    vert(i).y = vert(i).y + __fzxBody(index).shape.offsetTexture.y
    vert(i).x = vert(i).x * __fzxBody(index).shape.scaleTexture.x
    vert(i).y = vert(i).y * __fzxBody(index).shape.scaleTexture.y
    fzxWorldToCameraBody index, vert(i)
  NEXT

  IF __fzxBody(index).fzx.velocity.x > 1 OR __fzxBody(index).shape.flipTexture = 0 THEN
    _MAPTRIANGLE (0, 0)-(W - 1, 0)-(W - 1, H - 1), bm TO(vert(3).x, vert(3).y)-(vert(0).x, vert(0).y)-(vert(1).x, vert(1).y)
    _MAPTRIANGLE (0, 0)-(0, H - 1)-(W - 1, H - 1), bm TO(vert(3).x, vert(3).y)-(vert(2).x, vert(2).y)-(vert(1).x, vert(1).y)
  ELSE
    _MAPTRIANGLE (0, 0)-(W - 1, 0)-(W - 1, H - 1), bm TO(vert(0).x, vert(0).y)-(vert(3).x, vert(3).y)-(vert(2).x, vert(2).y)
    _MAPTRIANGLE (0, 0)-(0, H - 1)-(W - 1, H - 1), bm TO(vert(0).x, vert(0).y)-(vert(1).x, vert(1).y)-(vert(2).x, vert(2).y)
  END IF

END SUB

SUB renderWireframeCircle (index AS LONG)
  DIM tv AS tFZX_VECTOR2d
  fzxWorldToCameraBody index, tv
  CIRCLE (tv.x, tv.y), __fzxBody(index).shape.radius * __fzxCamera.zoom, __fzxBody(index).c
  ' Add a line from center to outer edge to give a visual reference for rotation
  LINE (tv.x, tv.y)-(tv.x + COS(__fzxbody(index).fzx.orient) * (__fzxbody(index).shape.radius * __fzxcamera.zoom), _
                     tv.y + SIN(__fzxbody(index).fzx.orient) * (__fzxbody(index).shape.radius) * __fzxcamera.zoom), __fzxbody(index).c
END SUB

SUB renderWireframeCircleVector (in AS tFZX_VECTOR2d)
  DIM tv AS tFZX_VECTOR2d
  fzxWorldToCameraEx in, tv
  CIRCLE (tv.x, tv.y), 2.0 * __fzxCamera.zoom, _RGB(127, 127, 0)
END SUB

SUB renderSolidCircleVector (in AS tFZX_VECTOR2d, rad AS SINGLE, c AS LONG)
  DIM tv AS tFZX_VECTOR2d
  fzxWorldToCameraEx in, tv
  'renderFastCircle tv.x, tv.y, 2.0 * camera.zoom, _RGB(127, 127, 0)
  renderFastCircle tv.x, tv.y, rad * __fzxCamera.zoom, c
END SUB


SUB renderFastCircle (xc AS LONG, yc AS LONG, r AS LONG, c AS LONG)
  DIM AS LONG e, x, y
  DIM AS LONG l0, l1

  x = r
  y = 0
  e = 0
  $CHECKING:OFF
  DO
    l0 = x * 2
    l1 = y * 2

    LINE (xc - x, yc - y)-(xc - x + l0, yc - y), c
    LINE (xc - x, yc + y)-(xc - x + l0, yc + y), c
    LINE (xc - y, yc - x)-(xc - y + l1, yc - x), c
    LINE (xc - y, yc + x)-(xc - y + l1, yc + x), c

    IF x <= y THEN EXIT DO
    e = e + y * 2 + 1
    y = y + 1
    IF e > x THEN
      e = e + 1 - x * 2
      x = x - 1
    END IF
  LOOP
  $CHECKING:ON
END SUB


SUB renderTexturedCircle (index AS LONG)
  ' A textured Circle will still be a box.
  ' It is up to the Artwork to trim off the corners
  DIM vert(3) AS tFZX_VECTOR2d
  DIM W, H AS LONG
  DIM bm AS LONG
  bm = __fzxBody(index).shape.texture
  W = _WIDTH(bm): H = _HEIGHT(bm)
  fzxVector2DSet vert(0), -__fzxBody(index).shape.radius, -__fzxBody(index).shape.radius
  fzxVector2DSet vert(1), -__fzxBody(index).shape.radius, __fzxBody(index).shape.radius
  fzxVector2DSet vert(2), __fzxBody(index).shape.radius, __fzxBody(index).shape.radius
  fzxVector2DSet vert(3), __fzxBody(index).shape.radius, -__fzxBody(index).shape.radius
  DIM i AS LONG
  FOR i = 0 TO 3
    fzxWorldToCameraBody index, vert(i)
  NEXT
  _MAPTRIANGLE (0, 0)-(0, H - 1)-(W - 1, H - 1), bm TO(vert(0).x, vert(0).y)-(vert(1).x, vert(1).y)-(vert(2).x, vert(2).y)
  _MAPTRIANGLE (0, 0)-(W - 1, 0)-(W - 1, H - 1), bm TO(vert(0).x, vert(0).y)-(vert(3).x, vert(3).y)-(vert(2).x, vert(2).y)
END SUB

SUB mapImage (src AS LONG, dest AS LONG, p AS tFZX_VECTOR2d, bitmask AS LONG)
  ' The Tiles from TILED program have bits set for orientation
  ' BIT31 is a horizontal flip
  ' BIT30 is a vertical flip
  ' BIT29 is a ROTATION
  ' Using these in combination will allow a tile to rendered in any orienatation

  DIM AS tFZX_VECTOR2d srcVert(3), vert(3)
  DIM AS LONG w, h, bitMaskHorz, bitMaskVert, bitMaskXYYX
  w = _WIDTH(src): h = _HEIGHT(src)
  fzxVector2DSet vert(0), p.x, p.y
  fzxVector2DSet vert(1), p.x + w, p.y
  fzxVector2DSet vert(2), p.x + w, p.y + h
  fzxVector2DSet vert(3), p.x, p.y + h

  fzxVector2DSet srcVert(0), 0, 0
  fzxVector2DSet srcVert(1), w - 1, 0
  fzxVector2DSet srcVert(2), w - 1, h - 1
  fzxVector2DSet srcVert(3), 0, h - 1

  bitMaskHorz = _SHR(bitmask, 31) AND 1
  bitMaskVert = _SHR(bitmask, 30) AND 1
  bitMaskXYYX = _SHR(bitmask, 29) AND 1

  IF bitMaskXYYX THEN
    fzxVector2DSwap srcVert(1), srcVert(3)
  END IF

  IF bitMaskHorz THEN
    fzxVector2DSwap srcVert(0), srcVert(1)
    fzxVector2DSwap srcVert(2), srcVert(3)
  END IF

  IF bitMaskVert THEN
    fzxVector2DSwap srcVert(0), srcVert(3)
    fzxVector2DSwap srcVert(1), srcVert(2)
  END IF

  _MAPTRIANGLE (srcVert(0).x, srcVert(0).y)-(srcVert(1).x, srcVert(1).y)-(srcVert(2).x, srcVert(2).y), _
         src TO(vert(0).x, vert(0).y)-(vert(1).x, vert(1).y)-(vert(2).x, vert(2).y), dest
  _MAPTRIANGLE (srcVert(0).x, srcVert(0).y)-(srcVert(3).x, srcVert(3).y)-(srcVert(2).x, srcVert(2).y), _
         src TO(vert(0).x, vert(0).y)-(vert(3).x, vert(3).y)-(vert(2).x, vert(2).y), dest

END SUB

SUB alphaImage (alpha AS LONG, image AS LONG, p AS tFZX_VECTOR2d, scale AS _FLOAT)
  ' This is the method used for fadining in and out images
  _SETALPHA alpha, 0 TO _RGB(255, 255, 255), image
  _CLEARCOLOR _RGB(0, 0, 0), image
  _PUTIMAGE (p.x, p.y)-(p.x + (_WIDTH(image) * scale), p.y + (_HEIGHT(image) * scale)), image
END SUB

SUB createLightingMask (tile() AS tTILE, xs AS LONG, ys AS LONG)
  __gmEngine.displayMask = allocateTextureEX(tile(), _NEWIMAGE(xs, ys, 32))
  DIM AS LONG position, maxdist
  DIM AS tFZX_VECTOR2d p, c, z
  DIM AS _UNSIGNED _BYTE dist
  DIM AS _MEM buffer
  DIM AS _OFFSET offset, lastOffset
  buffer = _MEMIMAGE(tile(__gmEngine.displayMask).t)
  offset = buffer.OFFSET
  lastOffset = buffer.OFFSET + xs * ys * 4
  position = 0
  c.x = xs / 2
  c.y = ys / 2
  z.x = 0
  z.y = 0
  maxdist = INT(fzxVector2DDistance(c, z))
  DO
    p.x = position MOD xs
    p.y = INT(position / xs)
    dist = fzxImpulseClamp(0, 255, fzxVector2DDistance(p, c) / maxdist * 255.0)
    _MEMPUT buffer, offset + 0, &H00 AS _UNSIGNED _BYTE
    _MEMPUT buffer, offset + 1, &H00 AS _UNSIGNED _BYTE
    _MEMPUT buffer, offset + 2, &H00 AS _UNSIGNED _BYTE
    _MEMPUT buffer, offset + 3, dist AS _UNSIGNED _BYTE 'Alpha channel
    position = position + 1
    offset = offset + 4
  LOOP UNTIL offset = lastOffset
  _MEMFREE buffer
END SUB

SUB colorMixBitmap (img AS LONG, rgb AS LONG, amount AS _FLOAT)
  DIM AS _UNSIGNED _BYTE r, g, b, nr, ng, nb
  DIM AS _MEM buffer
  DIM AS _OFFSET offset, lastOffset
  buffer = _MEMIMAGE(img)
  offset = buffer.OFFSET
  lastOffset = buffer.OFFSET + _WIDTH(img) * _HEIGHT(img) * 4
  $CHECKING:OFF
  DO
    r = _MEMGET(buffer, offset + 0, _UNSIGNED _BYTE)
    g = _MEMGET(buffer, offset + 1, _UNSIGNED _BYTE)
    b = _MEMGET(buffer, offset + 2, _UNSIGNED _BYTE)
    nr = colorChannelMixer(r, _RED(rgb), amount)
    ng = colorChannelMixer(g, _GREEN(rgb), amount)
    nb = colorChannelMixer(b, _BLUE(rgb), amount)
    _MEMPUT buffer, offset + 0, nr AS _UNSIGNED _BYTE
    _MEMPUT buffer, offset + 1, ng AS _UNSIGNED _BYTE
    _MEMPUT buffer, offset + 2, nb AS _UNSIGNED _BYTE
    offset = offset + 4
  LOOP UNTIL offset = lastOffset
  $CHECKING:ON
  _MEMFREE buffer

END SUB

'**********************************************************************************************
'   Texture Loading
'**********************************************************************************************
SUB _______________TEXTURE_HANDLING (): END SUB

FUNCTION allocateTexture (tile() AS tTILE)
  allocateTexture = UBOUND(tile)
  REDIM _PRESERVE tile(UBOUND(tile) + 1) AS tTILE
END FUNCTION

FUNCTION allocateTextureEX (tile() AS tTILE, img AS LONG)
  tile(UBOUND(tile)).t = img
  allocateTextureEX = UBOUND(tile)
  REDIM _PRESERVE tile(UBOUND(tile) + 1) AS tTILE
END FUNCTION

SUB loadBitmapError (tile() AS tTILE, index AS LONG, fl AS STRING)
  IF tile(index).t > -2 THEN
    PRINT "Unable to load image "; fl; " with return of "; tile(index).t
    END
  END IF
END SUB

SUB tileMapImagePosition (tile AS LONG, t AS tTILEMAP, sx1 AS LONG, sy1 AS LONG, sx2 AS LONG, sy2 AS LONG)
  DIM tile_width AS LONG
  DIM tile_height AS LONG
  DIM tile_x, tile_y AS LONG

  tile_width = t.tileSize + t.tilePadding
  tile_height = t.tileSize + t.tilePadding

  tile_x = tile MOD t.numberOfTilesX
  tile_y = INT(tile / t.numberOfTilesX)

  sx1 = tile_x * tile_width
  sy1 = tile_y * tile_height

  sx2 = sx1 + t.tileSize - t.tilePadding
  sy2 = sy1 + t.tileSize - t.tilePadding
END SUB

FUNCTION idToTile (t() AS tTILE, id AS LONG)
  DIM AS LONG index
  FOR index = 0 TO UBOUND(t)
    IF t(index).id = id THEN
      idToTile = index
      EXIT FUNCTION
    END IF
  NEXT
  idToTile = -1
END FUNCTION

SUB freeImageEX (tile() AS tTILE, img AS LONG)
  IF img < -1 THEN
    DIM AS LONG i, j
    FOR i = 0 TO UBOUND(tile) - 1
      IF tile(i).t = img THEN
        FOR j = i TO UBOUND(tile) - 1
          tile(j) = tile(j + 1)
        NEXT
        IF UBOUND(tile) > 0 THEN REDIM _PRESERVE tile(UBOUND(tile) - 1) AS tTILE
        IF img < -1 THEN _FREEIMAGE img
        EXIT SUB
      END IF
    NEXT
  END IF
END SUB

SUB freeAllTiles (tile() AS tTILE)
  DO WHILE UBOUND(tile)
    IF tile(UBOUND(tile) - 1).t < -1 THEN
      freeImageEX tile(), tile(UBOUND(tile) - 1).t
    ELSE
      REDIM _PRESERVE tile(UBOUND(tile) - 1) AS tTILE
    END IF
  LOOP
END SUB

'**********************************************************************************************
'   TMX Loading
' Related functions are in XML Section
'**********************************************************************************************

SUB _______________TMX_FILE_HANDLING (): END SUB

SUB loadFile (fl AS STRING, in() AS STRING)
  fl = LTRIM$(RTRIM$(fl)) 'clean the filename
  DIM AS LONG file_num
  IF _FILEEXISTS(fl) THEN
    file_num = FREEFILE
    OPEN fl FOR INPUT AS #file_num
    DO UNTIL EOF(file_num)
      LINE INPUT #file_num, in(UBOUND(in))
      REDIM _PRESERVE in(UBOUND(in) + 1) AS STRING
    LOOP
    CLOSE file_num
  ELSE
    PRINT "File not found :"; fl
    END
  END IF
END SUB

SUB loadTSX (dir AS STRING, tile() AS tTILE, tilemap AS tTILEMAP, firstid AS LONG)
  DIM AS STRING tsx(0), i
  DIM AS LONG img, index, id, arg

  loadFile _TRIM$(dir) + _TRIM$(tilemap.tsxFile), tsx()
  FOR index = 0 TO UBOUND(tsx)
    i = tsx(index)
    IF INSTR(i, "<tileset") THEN
      tilemap.numberOfTilesX = getXMLArgValue(i, "columns=")
      tilemap.tileCount = getXMLArgValue(i, "tilecount=")
      tilemap.tilePadding = 0
    END IF
    IF INSTR(i, "<image source=") THEN
      tilemap.file = getXMLArgString$(i, "<image source=")
      img = allocateTextureEX(tile(), _LOADIMAGE(_TRIM$(dir) + _TRIM$(tilemap.file)))
      tilemap.tileMap = tile(img).t
      loadBitmapError tile(), img, _TRIM$(dir) + _TRIM$(tilemap.file)
      loadTilesIntoBuffer tile(), tilemap, firstid
    END IF
    IF INSTR(i, "<tile ") THEN
      id = idToTile(tile(), getXMLArgValue(i, "id="))
      tile(id).class = getXMLArgString$(i, "type=")
      IF INSTR(tile(id).class, "CHARACTER") THEN
        index = index + 1: i = tsx(index)
        IF INSTR(i, "<properties>") THEN
          index = index + 1: i = tsx(index)
          DO
            IF INSTR(i, "<property ") THEN
              IF getXMLArgString$(i, "name=") = "CHAR" THEN
                arg = ASC(getXMLArgString$(i, "value="))
                __gmFont(arg).id = id + 2 ' No Idea why this is off
                __gmFont(arg).t = tile(idToTile(tile(), __gmFont(arg).id)).t
                __gmFont(arg).c = arg
              END IF
            END IF
            index = index + 1: i = tsx(index)
          LOOP UNTIL INSTR(i, "/")
        END IF
      END IF
    END IF
  NEXT
END SUB

SUB loadTilesIntoBuffer (tile() AS tTILE, tilemap AS tTILEMAP, firstid AS LONG)
  DIM AS LONG textmapCount
  DIM AS LONG x1, y1, x2, y2, index
  FOR index = 0 TO tilemap.tileCount - 1
    textmapCount = allocateTextureEX(tile(), _NEWIMAGE(tilemap.tileWidth, tilemap.tileHeight, 32))
    tileMapImagePosition index, tilemap, x1, y1, x2, y2
    _PUTIMAGE (0, 0), tilemap.tileMap, tile(textmapCount).t, (x1, y1)-(x2, y2)
    tile(textmapCount).id = firstid + index
  NEXT
  freeImageEX tile(), tilemap.tileMap
END SUB

'**********************************************************************************************
'   Construct GUI Map
'**********************************************************************************************
SUB _______________CONSTRUCT_GUIMAP (): END SUB
SUB constructGUIMap (idString AS STRING, __gmGuiMap() AS tTILE, __gmGuiTile() AS tTILE, __gmGuiLayout AS tTILEMAP)
  DIM AS LONG xs, ys, tempID, imageID
  xs = __gmGuiLayout.mapWidth * __gmGuiLayout.tileWidth * __gmGuiLayout.tilescale
  ys = __gmGuiLayout.mapHeight * __gmGuiLayout.tileHeight * __gmGuiLayout.tilescale

  tempID = fzxCreateBoxBodyEx(_TRIM$(idString), xs / 2, ys / 2)
  fzxSetBody cFZX_PARAMETER_POSITION, tempID, (xs / 2), xs / 2
  fzxSetBody cFZX_PARAMETER_ORIENT, tempID, 0, 0
  fzxSetBody cFZX_PARAMETER_STATIC, tempID, 1, 0
  fzxSetBody cFZX_PARAMETER_COLLISIONMASK, tempID, 0, 0
  fzxSetBody cFZX_PARAMETER_NOPHYSICS, tempID, 1, 0
  fzxSetBody cFZX_PARAMETER_RENDERORDER, tempID, 3, 0
  fzxSetBody cFZX_PARAMETER_ENABLE, tempID, 0, 0
  imageID = allocateTextureEX(__gmGuiTile(), _NEWIMAGE(__gmGuiLayout.tileWidth * __gmGuiLayout.mapWidth, __gmGuiLayout.tileHeight * __gmGuiLayout.mapHeight, 32))
  CLS , __gmEngine.displayClearColor
  buildMultiTileMap __gmGuiMap(), __gmGuiTile(), __gmGuiLayout, __gmGuiTile(imageID).t, 0
  fzxSetBody cFZX_PARAMETER_TEXTURE, tempID, __gmGuiTile(imageID).t, 0
  __gmGuiLayout.tileMap = __gmGuiTile(imageID).t
END SUB


'**********************************************************************************************
'   Construct Game Map
'**********************************************************************************************
SUB _______________CONSTRUCT_GAMEMAP (): END SUB

SUB constructGameMap (tile() AS tTILE, tilemap AS tTILEMAP, lights() AS tLIGHT)
  DIM AS LONG xs, ys, tempID, backgroundImageID
  xs = tilemap.mapWidth * tilemap.tileWidth * tilemap.tilescale
  ys = tilemap.mapHeight * tilemap.tileHeight * tilemap.tilescale

  tempID = fzxCreateBoxBodyEx("_BACKGROUND", xs / 2, ys / 2)
  fzxSetBody cFZX_PARAMETER_POSITION, tempID, xs / 2, xs / 2
  fzxSetBody cFZX_PARAMETER_ORIENT, tempID, 0, 0
  fzxSetBody cFZX_PARAMETER_STATIC, tempID, 1, 0
  fzxSetBody cFZX_PARAMETER_COLLISIONMASK, tempID, 0, 0
  fzxSetBody cFZX_PARAMETER_NOPHYSICS, tempID, 1, 0
  fzxSetBody cFZX_PARAMETER_RENDERORDER, tempID, 3, 0

  backgroundImageID = allocateTextureEX(tile(), _NEWIMAGE(tilemap.tileWidth * tilemap.mapWidth, tilemap.tileHeight * tilemap.mapHeight, 32))
  CLS , __gmEngine.displayClearColor

  applyGameMapToBody tile(), tilemap, tile(backgroundImageID).t, lights()
  fzxSetBody cFZX_PARAMETER_TEXTURE, tempID, tile(backgroundImageID).t, 0
END SUB

SUB addLightsToGamemap (tilemap AS tTILEMAP, lights() AS tLIGHT)
  DIM AS LONG index
  FOR index = 0 TO UBOUND(lights) - 1
    __gmMap(xyToGameMap(tilemap, lights(index).position.x, lights(index).position.y)).lightColor = lights(index).lightColor
  NEXT
END SUB

FUNCTION createLightingMask (tile() AS tTILE, tilemap AS tTILEMAP, lights() AS tLIGHT)
  DIM AS LONG img, index, x, y, lc, flatPos, W, dx, dy, vlq
  DIM AS _FLOAT dist, maxDist
  ' DIM AS tfzx_vector2d current
  maxDist = tilemap.tileWidth * __gmEngine.mapParameters.maxLightDistance ' Maximum Light influence
  img = allocateTextureEX(tile(), _NEWIMAGE(tilemap.tileWidth * tilemap.mapWidth, tilemap.tileHeight * tilemap.mapHeight, 32))
  DIM AS _MEM buffer
  DIM AS _OFFSET offset, lastOffset
  buffer = _MEMIMAGE(tile(img).t)
  offset = buffer.OFFSET
  lastOffset = buffer.OFFSET + _WIDTH(tile(img).t) * _HEIGHT(tile(img).t) * 4
  flatPos = 0
  $CHECKING:OFF
  W = _WIDTH(tile(img).t)
  DO
    x = flatPos MOD W
    y = INT(flatPos / W)
    lc = 0
    FOR index = 0 TO UBOUND(lights) - 1
      dx = x - lights(index).position.x
      dy = y - lights(index).position.y
      vlq = dx * dx + dy * dy
      IF vlq < maxDist * maxDist THEN
        dist = SQR(vlq)
        lc = colorMixer(lights(index).lightColor, lc, fzxImpulseClamp(0, 1, (maxDist / dist) / UBOUND(lights) * .2))
        _MEMPUT buffer, offset + 0, _BLUE(lc) AS _UNSIGNED _BYTE
        _MEMPUT buffer, offset + 1, _GREEN(lc) AS _UNSIGNED _BYTE
        _MEMPUT buffer, offset + 2, _RED(lc) AS _UNSIGNED _BYTE
        _MEMPUT buffer, offset + 3, _ALPHA(lc) AS _UNSIGNED _BYTE
      END IF
    NEXT
    offset = offset + 4
    flatPos = flatPos + 1
  LOOP UNTIL offset = lastOffset
  $CHECKING:ON
  createLightingMask = img
  _MEMFREE buffer

END FUNCTION

SUB refreshGameMap (tile() AS tTILE, tilemap AS tTILEMAP, lights() AS tLIGHT)
  DIM AS LONG xs, ys, tempID, backgroundImageID
  xs = tilemap.mapWidth * tilemap.tileWidth * tilemap.tilescale
  ys = tilemap.mapHeight * tilemap.tileHeight * tilemap.tilescale
  tempID = fzxBodyManagerID("_BACKGROUND")
  IF tempID > -1 THEN
    backgroundImageID = __fzxBody(tempID).shape.texture
    _DEST backgroundImageID
    CLS , __gmEngine.displayClearColor
    _DEST 0
    applyGameMapToBody tile(), tilemap, backgroundImageID, lights()
  END IF
END SUB

SUB applyGameMapToBody (tile() AS tTILE, tilemap AS tTILEMAP, backGroundImageID AS LONG, lights() AS tLIGHT)
  DIM AS LONG x, y
  DIM AS LONG lightmask, bgc, lmc

  buildMultiTileMap __gmMap(), tile(), tilemap, backGroundImageID, 0

  lightmask = createLightingMask(tile(), tilemap, lights())
  FOR y = 0 TO _HEIGHT(tile(lightmask).t)
    FOR x = 0 TO _WIDTH(tile(lightmask).t)
      _SOURCE tile(lightmask).t
      lmc = POINT(x, y)
      _SOURCE backGroundImageID
      _DEST backGroundImageID
      bgc = POINT(x, y)
      PSET (x, y), colorMixer(lmc, bgc, .75)
    NEXT
  NEXT
  freeImageEX tile(), lightmask
  _SOURCE 0
  _DEST 0
END SUB

SUB buildMultiTileMap (map() AS tTILE, tile() AS tTILE, layout AS tTILEMAP, img AS LONG, layer AS INTEGER)
  DIM AS LONG index
  DIM AS LONG sx, tileId, bitMaskLo, tileLayer
  DIM AS tFZX_VECTOR2d p
  sx = layout.tilescale * layout.tileSize
  FOR index = 0 TO UBOUND(map)
    IF layer = 0 THEN
      tileLayer = map(index).t
    ELSE
      tileLayer = map(index).t0
    END IF
    IF tileLayer <> 0 THEN
      bitMaskLo = tileLayer AND &H00FFFFFF 'Extract actual Tile ID number
      p.x = (index MOD layout.mapWidth) * sx
      p.y = INT(index / layout.mapWidth) * sx
      tileId = idToTile(tile(), bitMaskLo)
      mapImage tile(tileId).t, img, p, tileLayer
    END IF
  NEXT
END SUB

'**********************************************************************************************
'   GUI Handling
'**********************************************************************************************
SUB _______________GUI_MESSAGE_HANDLING (): END SUB
SUB renderText (tile() AS tTILE, tilemap AS tTILEMAP, message AS tMESSAGE, messageString AS STRING)
  message.scale = 1
  renderTextEx tile(), tilemap, message, messageString
END SUB

SUB consoleOut (tile() AS tTILE, tilemap AS tTILEMAP, s AS STRING)
  s = s + "_" 'CHR$(13)
  MID$(__gmConsole.txt, lenTxt(__gmConsole.txt), LEN(s)) = s
  consoleText tile(), tilemap
  __gmConsole.yPos = fzxScalarMax(0, __gmConsole.lc - __gmConsole.ySize) * tilemap.tileHeight
END SUB

SUB consoleText (tile() AS tTILE, tilemap AS tTILEMAP)
  DIM m AS tMESSAGE
  DIM AS LONG iter, iter2, iter3, l, lc, chunck, bottom
  DIM AS STRING ch, ch1, tempCon(100) ' temporary console broke up into lines
  l = lenTxt(__gmConsole.txt)
  ' PRINT #__logfile, " LenTXT:"; l
  lc = 0 ' line count

  iter = 1: DO WHILE iter <= l
    chunck = __gmConsole.xSize 'how much text per line

    IF chunck + iter > l THEN 'if your at the last line set chunk to whats left
      chunck = l - iter
      IF chunck < 1 THEN EXIT DO
    END IF
    'check for carriage return
    iter2 = 0: DO WHILE iter2 <= chunck
      IF MID$(__gmConsole.txt, iter + iter2, 1) = "_" THEN
        chunck = iter2 + 1
        EXIT DO
      END IF
    iter2 = iter2 + 1: LOOP
    tempCon(lc) = MID$(__gmConsole.txt, iter, chunck)
    'PRINT #__logfile, tempCon(lc)
    ' Handle special characters
    'iter2 = iter: DO WHILE iter2 <= iter + chunck
    '  ch = MID$(__gmConsole.txt, iter2, 1)
    '  IF ch = "~" THEN ' do not count the digits in the special character
    '    DO
    '      iter2 = iter2 + 1
    '      ch1 = MID$(__gmConsole.txt, iter2, 1)
    '    LOOP WHILE INSTR(ch1, "0123456789") AND iter2 < iter + 5
    '  END IF
    'iter2 = iter2 + 1: LOOP
    lc = lc + 1
    ' resize if more lines are needed
    IF lc > UBOUND(tempCon) THEN REDIM _PRESERVE tempCon(UBOUND(tempCon) + 100) AS STRING
  iter = iter + chunck: LOOP

  bottom = tilemap.tileHeight * m.scale * lc
  IF bottom >= _HEIGHT(m.baseImage) THEN ' console text is larger than the image
    iter = INT((bottom - _HEIGHT(m.baseImage)) / tilemap.tileHeight)
    _DEST m.baseImage
    CLS , m.bgColor
    _DEST 0
    lc = INT(_HEIGHT(m.baseImage) / tilemap.tileHeight)
  ELSE
    iter = 0
  END IF

  __gmConsole.lc = lc
  m.baseImage = __gmConsole.img: fzxVector2DSet m.position, 0, 0: m.scale = 1: m.bgColor = __gmEngine.displayClearColor

  bottom = tilemap.tileHeight * m.scale * lc
  IF bottom >= _HEIGHT(m.baseImage) THEN ' console text is larger than the image
    iter = INT((bottom - _HEIGHT(m.baseImage)) / tilemap.tileHeight)
    _DEST m.baseImage
    CLS , m.bgColor
    _DEST 0
  ELSE
    iter = 0
  END IF
  DO WHILE iter <= lc

    renderTextEx tile(), tilemap, m, tempCon(iter)
    m.position.y = m.position.y + (tilemap.tileHeight * m.scale)
    'PRINT #__logfile, " tpos:"; m.position.y
  iter = iter + 1: LOOP
  _DEST 0
END SUB

FUNCTION lenTxt (t AS STRING)
  DIM AS LONG iter, count
  count = 1
  ' QB64 UDT strings have a fixed length set at initialization
  ' so we need to find the end which is null terminated
  iter = 1: DO WHILE iter <= LEN(t) AND MID$(t, iter, 1) <> CHR$(0)
    ' dont count the extra characters for the special character expression towards the tottal length.
    'IF MID$(t, iter, 1) = "~" THEN
    '  '  ' detect a special character and subtract the excess i.e. ~00601 becomes Å
    '  count = count - 3
    'ELSE
    count = count + 1
    ' END IF
  iter = iter + 1: LOOP
  IF count < 1 THEN count = 1
  lenTxt = count
END FUNCTION


SUB renderTextEx (tile() AS tTILE, tilemap AS tTILEMAP, message AS tMESSAGE, messageString AS STRING)
  DIM AS LONG i, numberOfLines, linelengthCount, longestLine, ch, directchar, mw, mh, tw, th, fnt
  DIM AS tFZX_VECTOR2d cursor
  numberOfLines = 1
  longestLine = 1
  'prescanline to determine dimensions
  FOR i = 1 TO LEN(messageString)
    linelengthCount = linelengthCount + 1
    ch = ASC(MID$(messageString, i, 1))
    IF ch = 126 THEN '~#####  is used to render tiles directly
      i = i + 5
      IF i > LEN(messageString) THEN EXIT FOR
    ELSE
      IF ch = 95 OR ch = 13 THEN ' check for underscore
        numberOfLines = numberOfLines + 1
        IF linelengthCount > longestLine THEN longestLine = linelengthCount
        linelengthCount = 0
      END IF
    END IF
  NEXT
  IF linelengthCount > longestLine THEN longestLine = linelengthCount

  ' Draw the actual text
  _DEST message.baseImage
  tw = tilemap.tileWidth * message.scale
  th = tilemap.tileHeight * message.scale
  mw = longestLine * tw
  mh = numberOfLines * th
  ' LINE (message.position.x, message.position.y)-(message.position.x + mw, message.position.y + mh), message.bgColor, BF
  FOR i = 1 TO LEN(messageString)
    ch = ASC(MID$(UCASE$(messageString), i, 1))
    IF ch = 32 THEN
      cursor.x = cursor.x + tilemap.tileWidth * message.scale
    ELSE
      IF ch = 95 OR ch = 13 THEN
        cursor.x = 0
        cursor.y = cursor.y + tilemap.tileHeight * message.scale
      ELSE
        IF ch = 126 THEN '~#####  is used to render tiles directly
          directchar = VAL(MID$(messageString, i + 1, 5))
          IF tile(directchar).t < -1 THEN _PUTIMAGE (cursor.x + message.position.x, cursor.y + message.position.y)-(tw + cursor.x + message.position.x, th + cursor.y + message.position.y), tile(directchar).t, message.baseImage
          i = i + 5
          IF i > LEN(messageString) THEN EXIT FOR
        ELSE
          fnt = __gmFont(ch).t
          'PRINT #__logfile, "fnt:"; fnt; " img:"; message.baseImage; "   pos:"; cursor.x + message.position.x; "   "; cursor.y + message.position.y
          IF fnt < -1 THEN _PUTIMAGE (cursor.x + message.position.x, cursor.y + message.position.y)-(tw + cursor.x + message.position.x, th + cursor.y + message.position.y), fnt, message.baseImage
        END IF
        cursor.x = cursor.x + tilemap.tileWidth * message.scale
      END IF
    END IF
  NEXT
  _DEST 0
END SUB


SUB prepMessage (tile() AS tTILE, tilemap AS tTILEMAP, message AS tMESSAGE, messageString AS STRING)
  DIM AS LONG i, numberOfLines, linelengthCount, longestLine, ch, directchar, tw, th
  DIM AS tFZX_VECTOR2d cursor
  numberOfLines = 1
  longestLine = 1
  'prescanline to determine dimensions
  FOR i = 1 TO LEN(messageString)
    linelengthCount = linelengthCount + 1
    ch = ASC(MID$(messageString, i, 1))
    IF ch = 126 THEN '~#####  is used to render tiles directly
      i = i + 5
      IF i > LEN(messageString) THEN EXIT FOR
    ELSE
      IF ch = 95 OR ch = 13 THEN ' check for underscore
        numberOfLines = numberOfLines + 1
        IF linelengthCount > longestLine THEN longestLine = linelengthCount
        linelengthCount = 0
      END IF

    END IF

  NEXT
  IF linelengthCount > longestLine THEN longestLine = linelengthCount
  message.baseImage = allocateTextureEX(tile(), _NEWIMAGE(longestLine * tilemap.tileWidth, numberOfLines * tilemap.tileHeight, 32))
  _DEST tile(message.baseImage).t
  CLS 1, __gmEngine.displayClearColor
  '_DONTBLEND
  tw = tilemap.tileWidth ' * message.scale
  th = tilemap.tileHeight ' * message.scale

  FOR i = 1 TO LEN(messageString)
    ch = ASC(MID$(UCASE$(messageString), i, 1))
    IF ch = 95 OR ch = 13 THEN
      cursor.x = 0
      cursor.y = cursor.y + tilemap.tileHeight
    ELSE IF ch = 32 THEN ' this was added due to the XML parsing routines cannot handle a space as the return value of an argument.
        cursor.x = cursor.x + tilemap.tileWidth
      ELSE
        IF ch = 126 THEN '~#####  is used to render tiles directly
          directchar = VAL(MID$(messageString, i + 1, 5))
          _PUTIMAGE (cursor.x, cursor.y), tile(directchar).t, tile(message.baseImage).t
          cursor.x = cursor.x + tilemap.tileWidth
          i = i + 5
          IF i > LEN(messageString) THEN EXIT FOR
        ELSE
          _PUTIMAGE (cursor.x, cursor.y), __gmFont(ch).t, tile(message.baseImage).t
          cursor.x = cursor.x + tilemap.tileWidth
        END IF
      END IF
    END IF
  NEXT
  _DEST 0
END SUB

SUB addMessage (tile() AS tTILE, tilemap AS tTILEMAP, message() AS tMESSAGE, messageString AS STRING, timeOut AS LONG, position AS tFZX_VECTOR2d, scale AS _FLOAT)
  DIM AS LONG m
  REDIM _PRESERVE message(UBOUND(message) + 1) AS tMESSAGE
  m = UBOUND(message)
  prepMessage tile(), tilemap, message(m), messageString
  message(m).fsm.timerState.duration = timeOut
  message(m).position = position
  message(m).scale = scale
  fzxFSMChangeState message(m).fsm, cFSM_MESSAGE_INIT
END SUB

SUB handleMessages (tile() AS tTILE, message() AS tMESSAGE)
  DIM AS LONG alpha, i
  i = UBOUND(message)
  IF i > 0 THEN
    SELECT CASE message(i).fsm.currentState
      CASE cFSM_MESSAGE_IDLE:
      CASE cFSM_MESSAGE_INIT:
        fzxFSMChangeState message(i).fsm, cFSM_MESSAGE_FADEIN
      CASE cFSM_MESSAGE_FADEIN:
        alpha = fzxScalarLERPSmoother#(0, 255, fzxScalarLERPProgress(message(i).fsm.timerState.start, message(i).fsm.timerState.start + (message(i).fsm.timerState.duration * .1)))
        alphaImage alpha, tile(message(i).baseImage).t, message(i).position, message(i).scale
        fzxFSMChangeStateOnTimer message(i).fsm, cFSM_MESSAGE_SHINE
      CASE cFSM_MESSAGE_SHINE:
        alphaImage 255, tile(message(i).baseImage).t, message(i).position, message(i).scale
        fzxFSMChangeStateOnTimer message(i).fsm, cFSM_MESSAGE_FADEOUT
      CASE cFSM_MESSAGE_FADEOUT:
        alpha = fzxScalarLERPSmoother#(255, 0, fzxScalarLERPProgress(message(i).fsm.timerState.start, message(i).fsm.timerState.start + (message(i).fsm.timerState.duration * .1)))
        'Potential crash here. Switching rooms before the messages finish their cycle might cause crash
        ' Need to Fix or cleanup
        alphaImage alpha, tile(message(i).baseImage).t, message(i).position, message(i).scale
        fzxFSMChangeStateOnTimer message(i).fsm, cFSM_MESSAGE_CLEANUP
      CASE cFSM_MESSAGE_CLEANUP:
        freeImageEX tile(), tile(message(i).baseImage).t
        removeMessage message(), i
        'No need to change back to IDLE since we are deleting this message
      CASE ELSE
        'Nada
    END SELECT
  END IF
END SUB

SUB removeMessage (message() AS tMESSAGE, i AS LONG)
  DIM AS LONG j
  IF i < UBOUND(message) THEN
    FOR j = i TO UBOUND(message) - 1
      message(j) = message(j + 1)
    NEXT
  END IF
  IF UBOUND(message) > 0 THEN REDIM _PRESERVE message(UBOUND(message) - 1) AS tMESSAGE
END SUB

'**********************************************************************************************
'   A* Path Finding
'  Needs Proper Integration
'**********************************************************************************************

SUB _______________A_STAR_PATHFINDING (): END SUB

FUNCTION AStarSetPath$ (entity AS tENTITY, startPos AS tFZX_VECTOR2d, TargetPos AS tFZX_VECTOR2d, tilemap AS tTILEMAP)
  ' Verify all positions are valid
  IF TargetPos.x >= 0 AND TargetPos.x <= tilemap.mapWidth AND _
     TargetPos.y >= 0 AND TargetPos.y <= tilemap.mapHeight AND _
     AStarCollision( tilemap, targetpos) THEN

    DIM TargetFound AS _BYTE

    DIM AS LONG maxpathlength, ix, iy, count, i
    DIM NewG AS LONG
    DIM OpenPathCount AS LONG
    DIM LowF AS LONG
    DIM AS LONG ixOptimal, iyOptimal, OptimalPath_i
    DIM startreached AS LONG
    DIM pathlength AS LONG
    DIM AS STRING pathString
    DIM AS tFZX_VECTOR2d currPos, nextPos
    DIM AS tFZX_VECTOR2d currentPosition

    maxpathlength = tilemap.mapWidth * tilemap.mapHeight

    DIM SearchPathSet(4) AS tPATH
    DIM OpenPathSet(maxpathlength) AS tPATH
    DIM PathMap(maxpathlength) AS tPATH

    currentPosition = startPos

    ' Set the path map positions
    FOR ix = 0 TO tilemap.mapWidth - 1
      FOR iy = 0 TO tilemap.mapHeight - 1
        PathMap(xyToGameMapPlain(tilemap, ix, iy)).position.x = ix
        PathMap(xyToGameMapPlain(tilemap, ix, iy)).position.y = iy
      NEXT
    NEXT
    TargetFound = FALSE

    DO
      PathMap(xyToGameMapPlain(tilemap, currentPosition.x, currentPosition.y)).status = 2
      count = count + 1

      IF PathMap(xyToGameMapPlain(tilemap, TargetPos.x, TargetPos.y)).status = 2 THEN TargetFound = TRUE: EXIT DO
      IF count > maxpathlength THEN EXIT DO ' make sure we do not overrun the array OpenPathSet

      ' set up the SearchPath Array to the current position and the four surrounding positions
      SearchPathSet(0) = PathMap(xyToGameMapPlain(tilemap, currentPosition.x, currentPosition.y))
      IF currentPosition.x < tilemap.mapWidth THEN SearchPathSet(1) = PathMap(xyToGameMapPlain(tilemap, currentPosition.x + 1, currentPosition.y))
      IF currentPosition.x > 0 THEN SearchPathSet(2) = PathMap(xyToGameMapPlain(tilemap, currentPosition.x - 1, currentPosition.y))
      IF currentPosition.y < tilemap.mapHeight THEN SearchPathSet(3) = PathMap(xyToGameMapPlain(tilemap, currentPosition.x, currentPosition.y + 1))
      IF currentPosition.y > 0 THEN SearchPathSet(4) = PathMap(xyToGameMapPlain(tilemap, currentPosition.x, currentPosition.y - 1))

      'scan the postions and determine if it is valid, if it is then calculate cost.
      FOR i = 1 TO 4
        IF AStarCollision(tilemap, SearchPathSet(i).position) THEN

          IF SearchPathSet(i).status = 1 THEN
            NewG = AStarPathGCost(SearchPathSet(0).g)
            IF NewG < SearchPathSet(i).g THEN SearchPathSet(i).g = NewG
          END IF

          IF SearchPathSet(i).status = 0 THEN
            SearchPathSet(i).parent = SearchPathSet(0).position
            SearchPathSet(i).status = 1
            SearchPathSet(i).g = AStarPathGCost(SearchPathSet(0).g)
            SearchPathSet(i).h = AStarPathHCost(SearchPathSet(i), TargetPos, entity)
            SearchPathSet(i).f = SearchPathSet(i).g + SearchPathSet(i).h ' + (AStarWalkway(tilemap, SearchPathSet(i).position) * 10)
            OpenPathSet(OpenPathCount) = SearchPathSet(i)
            OpenPathCount = OpenPathCount + 1
          END IF
        END IF
      NEXT

      IF currentPosition.x < tilemap.mapWidth THEN PathMap(xyToGameMapPlain(tilemap, currentPosition.x + 1, currentPosition.y)) = SearchPathSet(1)
      IF currentPosition.x > 0 THEN PathMap(xyToGameMapPlain(tilemap, currentPosition.x - 1, currentPosition.y)) = SearchPathSet(2)
      IF currentPosition.y < tilemap.mapHeight THEN PathMap(xyToGameMapPlain(tilemap, currentPosition.x, currentPosition.y + 1)) = SearchPathSet(3)
      IF currentPosition.y > 0 THEN PathMap(xyToGameMapPlain(tilemap, currentPosition.x, currentPosition.y - 1)) = SearchPathSet(4)

      IF OpenPathCount > (maxpathlength - 4) THEN EXIT DO

      ' serach through the available positions for the most optimal route
      LowF = 32000: ixOptimal = 0: iyOptimal = 0
      FOR i = 0 TO OpenPathCount
        IF OpenPathSet(i).status = 1 AND OpenPathSet(i).f <> 0 THEN
          IF OpenPathSet(i).f < LowF THEN
            LowF = OpenPathSet(i).f
            ixOptimal = OpenPathSet(i).position.x
            iyOptimal = OpenPathSet(i).position.y
            OptimalPath_i = i
          END IF
        END IF
      NEXT

      IF ixOptimal = 0 AND iyOptimal = 0 THEN EXIT DO
      currentPosition = PathMap(xyToGameMapPlain(tilemap, ixOptimal, iyOptimal)).position
      OpenPathSet(OptimalPath_i).status = 2
    LOOP

    IF TargetFound = TRUE THEN

      DIM backpath(maxpathlength) AS tPATH
      backpath(0).position = PathMap(xyToGameMapPlain(tilemap, TargetPos.x, TargetPos.y)).position

      startreached = FALSE
      FOR i = 1 TO count
        backpath(i).position = PathMap(xyToGameMapPlain(tilemap, backpath(i - 1).position.x, backpath(i - 1).position.y)).parent
        IF (startreached = FALSE) AND (backpath(i).position.x = currentPosition.x) AND (backpath(i).position.y = currentPosition.y) THEN
          pathlength = i
          startreached = TRUE
        END IF
      NEXT

      pathString = ""
      FOR i = count TO 1 STEP -1
        IF backpath(i).position.x > 0 AND backpath(i).position.x < tilemap.mapWidth AND backpath(i).position.y > 0 AND backpath(i).position.y < tilemap.mapHeight THEN
          currPos = backpath(i).position
          nextPos = backpath(i - 1).position
          IF nextPos.x < currPos.x THEN pathString = pathString + "L"
          IF nextPos.x > currPos.x THEN pathString = pathString + "R"
          IF nextPos.y < currPos.y THEN pathString = pathString + "U"
          IF nextPos.y > currPos.y THEN pathString = pathString + "D"
        END IF
      NEXT
    END IF
    AStarSetPath = pathString
  END IF
END FUNCTION

FUNCTION AStarPathGCost (ParentG)
  AStarPathGCost = ParentG + 10
END FUNCTION

FUNCTION AStarPathHCost (TilePath AS tPATH, TargetPos AS tFZX_VECTOR2d, entity AS tENTITY)
  DIM dx, dy AS LONG
  DIM distance AS DOUBLE
  DIM SearchIntensity AS LONG
  dx = ABS(TilePath.position.x - TargetPos.x)
  dy = ABS(TilePath.position.y - TargetPos.y)
  distance = SQR(dx ^ 2 + dy ^ 2)
  SearchIntensity = INT(RND * entity.parameters.drunkiness)
  AStarPathHCost = ((SearchIntensity / 20) + 10) * (dx + dy + ((SearchIntensity / 10) * distance))
END FUNCTION

FUNCTION AStarCollision (tilemap AS tTILEMAP, position AS tFZX_VECTOR2d)
  ' This is hack that requires the block at 0 to be a collider block
  DIM AS LONG idx, c1, c2: idx = vector2dToGameMapPlain(tilemap, position)
  c1 = __gmMap(idx).collision
  c2 = __gmMap(0).collision
  AStarCollision = NOT c1 = c2
END FUNCTION

FUNCTION AStarWalkway (tilemap AS tTILEMAP, position AS tFZX_VECTOR2d)
  'This is to detect optimal paths based on using sidewalks
  'I'm using the same block as collision block except the rotated bit is set
  AStarWalkway = (__gmMap(vector2dToGameMapPlain(tilemap, position)).collision AND &HFFFFFF) = (__gmMap(0).collision AND &HFFFFFF)
END FUNCTION

'**********************************************************************************************
'   XML
'**********************************************************************************************

SUB _______________XML_HANDLING (): END SUB

SUB XMLGUI (guiIDString AS STRING, _
            layout AS tTILEMAP, _
            con() AS tFZX_STRINGTUPLE, reloadTSX as _byte)
  DIM AS STRING context, arg, elementString, objectGroupName, objectType, mapLayer
  DIM AS LONG index, firstId, start, comma, mapIndex, fx, fy, fw, fh, menutype, elementValue
  DIM AS _FLOAT tempVal

  FOR index = 0 TO UBOUND(con) - 1
    context = _TRIM$(con(index).contextName)
    arg = _TRIM$(con(index).arg)
    SELECT CASE context
      CASE "map":
        layout.mapWidth = getXMLArgValue(arg, " width=")
        layout.mapHeight = getXMLArgValue(arg, " height=")
        layout.tileWidth = getXMLArgValue(arg, " tilewidth=")
        layout.tileHeight = getXMLArgValue(arg, " tileheight=")
        layout.tileSize = layout.tileWidth
        layout.tilescale = 1

      CASE "map tileset":

        layout.tsxFile = _TRIM$(getXMLArgString$(arg, " source="))
        firstId = getXMLArgValue(arg, " firstgid=")
        IF reloadTSX THEN loadTSX __gmEngine.assetsDirectory, __gmGuiTile(), layout, firstId
      CASE "map layer":
        mapLayer = getXMLArgString$(arg, " name=")

      CASE "map layer data": ' Load GameMap
        elementString = getXMLArgString$(arg, "encoding=")
        IF elementString = "csv" THEN
          mapIndex = 0
        ELSE
          'Read in comma delimited gamemap data
          start = 1
          arg = _TRIM$(arg)
          DO WHILE start <= LEN(arg)
            comma = INSTR(start, arg, ",")
            IF comma = 0 THEN
              IF start < LEN(arg) THEN ' catch the last value at the end of the list
                tempVal = VAL(RIGHT$(arg, LEN(arg) - start + 1))
                XMLsetGameMap __gmGuiMap(), mapIndex, mapLayer, tempVal

              END IF
              EXIT DO
            END IF
            tempVal = VAL(MID$(arg, start, comma - start))
            XMLsetGameMap __gmGuiMap(), mapIndex, mapLayer, tempVal

            start = comma + 1
          LOOP
        END IF
      CASE "map objectgroup": 'Get object group name
        objectGroupName = getXMLArgString$(arg, " name=")
      CASE "map objectgroup object": 'Get object name
        SELECT CASE objectGroupName
          CASE "Fields"
            REDIM _PRESERVE __gmGuiFields(UBOUND(__gmGuiFields) + 1) AS tGUI_FIELDS
            objectType = getXMLArgString$(arg, " name=")
            menutype = getXMLArgValue(arg, " type=")
            fx = getXMLArgValue(arg, " x=")
            fy = getXMLArgValue(arg, " y=")
            fw = getXMLArgValue(arg, " width=")
            fh = getXMLArgValue(arg, " height=")
            __gmGuiFields(UBOUND(__gmGuiFields)).Id = objectType
            __gmGuiFields(UBOUND(__gmGuiFields)).menuType = menutype
            __gmGuiFields(UBOUND(__gmGuiFields)).position.x = fx
            __gmGuiFields(UBOUND(__gmGuiFields)).position.y = fy
            __gmGuiFields(UBOUND(__gmGuiFields)).size.x = fw
            __gmGuiFields(UBOUND(__gmGuiFields)).size.y = fh
            __gmGuiFields(UBOUND(__gmGuiFields)).scale = 1
        END SELECT
      CASE "map objectgroup object properties property"
        elementString = getXMLArgString$(arg, " name=")
        SELECT CASE elementString
          CASE "ACTIVATED_TILE"
            elementValue = getXMLArgValue(arg, " value=")
            __gmGuiFields(UBOUND(__gmGuiFields)).activatedTile = elementValue
          CASE "BUTTON"
            elementValue = getXMLArgValue(arg, " value=")
            __gmGuiFields(UBOUND(__gmGuiFields)).buttonId = elementValue
        END SELECT
    END SELECT
  NEXT
  constructGUIMap guiIDString, __gmGuiMap(), __gmGuiTile(), layout

END SUB


SUB XMLapplyAttributes (tile() AS tTILE, tilemap AS tTILEMAP, con() AS tFZX_STRINGTUPLE)
  DIM AS STRING context, arg, elementName, elementString, objectGroupName, objectName, objectType, propertyName, propertyValueString, objectID, mapLayer, elementValueString
  DIM AS LONG index, firstId, start, comma, mapIndex, tempId, sensorImage, tempColor
  DIM AS tFZX_VECTOR2d o, tempVec
  DIM AS _FLOAT elementValue, xp, yp, xs, ys, propertyValue, tempVal, xl, yl
  DIM AS tLIGHT lights(0)
  FOR index = 0 TO UBOUND(con) - 1
    context = _TRIM$(con(index).contextName)
    arg = _TRIM$(con(index).arg)
    SELECT CASE context
      CASE "map":
        tilemap.mapWidth = getXMLArgValue(arg, " width=")
        tilemap.mapHeight = getXMLArgValue(arg, " height=")
        tilemap.tileWidth = getXMLArgValue(arg, " tilewidth=")
        tilemap.tileHeight = getXMLArgValue(arg, " tileheight=")
        tilemap.tileSize = tilemap.tileWidth
      CASE "map group":
        elementName = getXMLArgString$(arg, " name=")
      CASE "map group properties property":
        SELECT CASE elementName
          CASE "SOUNDS":
            addMusic __gmSounds(), getXMLArgString$(arg, " value="), getXMLArgString$(arg, " name=")
        END SELECT
      CASE "map tileset":
        tilemap.tsxFile = _TRIM$(getXMLArgString$(arg, " source="))
        firstId = getXMLArgValue(arg, " firstgid=")

        loadTSX _TRIM$(__gmEngine.assetsDirectory), tile(), tilemap, firstId
      CASE "map properties property":
        elementName = getXMLArgString$(arg, " name=")
        elementValue = getXMLArgValue#(arg, " value=")
        elementValueString = getXMLArgString$(arg, " value=")
        SELECT CASE elementName
          CASE "GRAVITY_X":
            __fzxWorld.gravity.x = elementValue
            fzxVector2DMultiplyScalarND o, __fzxWorld.gravity, cFZX_DT: __gmEngine.resting = fzxVector2DLengthSq(o) + cFZX_EPSILON
          CASE "GRAVITY_Y":
            __fzxWorld.gravity.y = elementValue
            fzxVector2DMultiplyScalarND o, __fzxWorld.gravity, cFZX_DT: __gmEngine.resting = fzxVector2DLengthSq(o) + cFZX_EPSILON
          CASE "CAMERA_ZOOM":
            __fzxCamera.zoom = elementValue
          CASE "CAMERA_FOCUS_X":
            __fzxCamera.position.x = elementValue
          CASE "CAMERA_FOCUS_Y":
            __fzxCamera.position.y = elementValue
          CASE "CAMERA_AABB_X":
            __fzxCamera.AABB.x = elementValue
          CASE "CAMERA_AABB_Y":
            __fzxCamera.AABB.y = elementValue
          CASE "CAMERA_AABB_SIZE_X":
            __fzxCamera.AABB_size.x = elementValue
          CASE "CAMERA_AABB_SIZE_Y":
            __fzxCamera.AABB_size.y = elementValue
          CASE "CAMERA_MODE"
          CASE "LIGHT_MAX_DISTANCE":
            __gmEngine.mapParameters.maxLightDistance = elementValue
        END SELECT
      CASE "map layer":
        mapLayer = getXMLArgString$(arg, " name=")
      CASE "map layer data": ' Load GameMap
        elementString = getXMLArgString$(arg, "encoding=")
        IF elementString = "csv" THEN
          mapIndex = 0
        ELSE
          'Read in comma delimited gamemap data
          start = 1
          arg = _TRIM$(arg)
          DO WHILE start <= LEN(arg)
            comma = INSTR(start, arg, ",")
            IF comma = 0 THEN
              IF start < LEN(arg) THEN ' catch the last value at the end of the list
                tempVal = VAL(RIGHT$(arg, LEN(arg) - start + 1))
                XMLsetGameMap __gmMap(), mapIndex, mapLayer, tempVal
              END IF
              EXIT DO
            END IF
            tempVal = VAL(MID$(arg, start, comma - start))
            XMLsetGameMap __gmMap(), mapIndex, mapLayer, tempVal
            start = comma + 1
          LOOP
        END IF
      CASE "map objectgroup": 'Get object group name
        objectGroupName = getXMLArgString$(arg, " name=")
      CASE "map objectgroup object": 'Get object name
        SELECT CASE objectGroupName
          CASE "Objects":
            objectType = getXMLArgString$(arg, " type=")
            SELECT CASE objectType
              CASE "PLAYER":
                objectName = getXMLArgString$(arg, " name=")
                xp = getXMLArgValue(arg, " x=") * tilemap.tilescale
                yp = getXMLArgValue(arg, " y=") * tilemap.tilescale
                fzxVector2DSet tempVec, xp + tilemap.tileWidth, yp + tilemap.tileHeight
                tempId = entityCreate(tilemap, objectName, tempVec)

              CASE "ENTITY":
                objectName = getXMLArgString$(arg, " name=")
                xp = getXMLArgValue(arg, " x=") * tilemap.tilescale
                yp = getXMLArgValue(arg, " y=") * tilemap.tilescale
                fzxVector2DSet tempVec, xp + tilemap.tileWidth, yp + tilemap.tileHeight
                tempId = entityCreate(tilemap, objectName, tempVec)
                'PRINT tempId; "  >"; objectName; "<"
              CASE "SENSOR":
                objectName = getXMLArgString$(arg, " name=")
                xp = getXMLArgValue(arg, " x=") * tilemap.tilescale
                yp = getXMLArgValue(arg, " y=") * tilemap.tilescale
                xs = (getXMLArgValue(arg, " width=") * tilemap.tilescale) / 2
                ys = (getXMLArgValue(arg, " height=") * tilemap.tilescale) / 2
                tempId = fzxCreateBoxBodyEx(objectName, xs, ys)
                fzxSetBody cFZX_PARAMETER_POSITION, tempId, xp + xs, yp + ys
                fzxSetBody cFZX_PARAMETER_ORIENT, tempId, 0, 0
                fzxSetBody cFZX_PARAMETER_STATIC, tempId, 1, 0
                fzxSetBody cFZX_PARAMETER_COLOR, tempId, _RGBA32(0, 255, 0, 255), 0
                fzxSetBody cFZX_PARAMETER_NOPHYSICS, tempId, 1, 0
                fzxSetBody cFZX_PARAMETER_SPECIALFUNCTION, tempId, 1, tempId
                'Sensors have couple of ways to trigger
                'There is the body collision, and there is the image collision
                'There is a hidden image that is the same size as the gamemap
                'The hidden image is black except for the images of the sensors
                'This allows for you to detect sensor collisions with the POINT command
                'This is useful for mouse interactions with menu items
                'The color is embedded with bodyID to help sort which sensor got hit
                sensorImage = allocateTextureEX(tile(), _NEWIMAGE(64, 64, 32))
                _DEST tile(sensorImage).t
                LINE (0, 0)-(64, 64), _RGB(0, 0, tempId), BF
                _DEST 0
                fzxSetBody cFZX_PARAMETER_TEXTURE, tempId, tile(sensorImage).t, 0
              CASE "LANDMARK":
                objectName = getXMLArgString$(arg, " name=")
                xp = getXMLArgValue(arg, " x=") * tilemap.tilescale
                yp = getXMLArgValue(arg, " y=") * tilemap.tilescale
                __gmLandmark(UBOUND(__gmLandmark)).landmarkName = objectName
                __gmLandmark(UBOUND(__gmLandmark)).landmarkHash = fzxComputeHash&&(objectName)
                __gmLandmark(UBOUND(__gmLandmark)).position.x = xp
                __gmLandmark(UBOUND(__gmLandmark)).position.y = yp
                REDIM _PRESERVE __gmLandmark(UBOUND(__gmLandmark) + 1) AS tLANDMARK
              CASE "DOOR":
                objectName = getXMLArgString$(arg, " name=")
                xp = getXMLArgValue(arg, " x=") * tilemap.tilescale
                yp = getXMLArgValue(arg, " y=") * tilemap.tilescale
                xs = (getXMLArgValue(arg, " width=") * tilemap.tilescale) / 2
                ys = (getXMLArgValue(arg, " height=") * tilemap.tilescale) / 2
                tempId = fzxCreateBoxBodyEx(objectName, xs, ys) 'was objectid
                fzxSetBody cFZX_PARAMETER_POSITION, tempId, xp + xs, yp + ys
                fzxSetBody cFZX_PARAMETER_ORIENT, tempId, 0, 0
                fzxSetBody cFZX_PARAMETER_STATIC, tempId, 1, 0
                fzxSetBody cFZX_PARAMETER_NOPHYSICS, tempId, 1, 0
                fzxSetBody cFZX_PARAMETER_COLOR, tempId, _RGBA32(255, 0, 0, 255), 0
                __gmPortals(UBOUND(__gmPortals)).bodyId = tempId
                __gmPortals(UBOUND(__gmPortals)).doorName = objectName
                __gmPortals(UBOUND(__gmPortals)).doorHash = fzxComputeHash&&(objectName)
                __gmPortals(UBOUND(__gmPortals)).position.x = xp
                __gmPortals(UBOUND(__gmPortals)).position.y = yp
                REDIM _PRESERVE __gmPortals(UBOUND(__gmPortals) + 1) AS tDOOR
            END SELECT

          CASE "Collision":
            objectID = getXMLArgString$(arg, " id=")
            xp = getXMLArgValue(arg, " x=") * tilemap.tilescale
            yp = getXMLArgValue(arg, " y=") * tilemap.tilescale
            xs = (getXMLArgValue(arg, " width=") * tilemap.tilescale) / 2
            ys = (getXMLArgValue(arg, " height=") * tilemap.tilescale) / 2
            tempId = fzxCreateBoxBodyEx(objectID, xs, ys)
            fzxSetBody cFZX_PARAMETER_POSITION, tempId, xp + xs, yp + ys
            fzxSetBody cFZX_PARAMETER_ORIENT, tempId, 0, 0
            fzxSetBody cFZX_PARAMETER_STATIC, tempId, 1, 0
            fzxSetBody cFZX_PARAMETER_COLOR, tempId, _RGBA32(255, 0, 0, 255), 0
          CASE "Lights":
            xl = getXMLArgValue(arg, " x=")
            yl = getXMLArgValue(arg, " y=")
          CASE "fzxBody":
            XMLaddRigidBody tile(), tilemap, arg
        END SELECT
      CASE "map objectgroup object properties property":
        SELECT CASE objectGroupName
          CASE "Objects":
            SELECT CASE objectType
              CASE "PLAYER", "ENTITY":
                propertyName = getXMLArgString$(arg, " name=")
                propertyValue = getXMLArgValue(arg, " value=")
                tempId = fzxBodyManagerID(objectName)
                IF tempId < 0 THEN PRINT "Body doesn't exist :->"; objectName; "<-": PRINT context: PRINT arg: END
                SELECT CASE propertyName
                  CASE "TileID":
                    fzxSetBody cFZX_PARAMETER_TEXTURE, tempId, tile(idToTile(tile(), propertyValue + 1)).t, 0
                    __gmEntity(__fzxBody(tempId).entityID).parameters.normalTile = propertyValue
                  CASE "TileID_ACTIVATED":
                    __gmEntity(__fzxBody(tempId).entityID).parameters.activatedTile = propertyValue
                  CASE "MAX_FORCE_X":
                    __gmEntity(__fzxBody(tempId).entityID).parameters.maxForce.x = propertyValue
                  CASE "MAX_FORCE_Y":
                    __gmEntity(__fzxBody(tempId).entityID).parameters.maxForce.y = propertyValue
                  CASE "NO_PHYSICS":
                    fzxSetBody cFZX_PARAMETER_NOPHYSICS, tempId, propertyValue, 0
                  CASE "BEHAVIOR":
                    __gmEntity(__fzxBody(tempId).entityID).parameters.behavior = propertyValue
                  CASE "MOVEMENT_SPEED":
                    __gmEntity(__fzxBody(tempId).entityID).parameters.movementSpeed = propertyValue
                  CASE "MOVEMENT_DRUNKINESS":
                    __gmEntity(__fzxBody(tempId).entityID).parameters.drunkiness = propertyValue
                  CASE "SCALE":
                    __gmEntity(__fzxBody(tempId).entityID).parameters.scale = propertyValue
                    fzxSetBody cFZX_PARAMETER_SCALETEXTURE, tempId, propertyValue, propertyValue
                END SELECT
              CASE "SENSOR": ' No properties
              CASE "WAYPOINT": ' No properties
              CASE "DOOR":
                propertyName = getXMLArgString$(arg, " name=")
                propertyValue = getXMLArgValue(arg, " value=")
                propertyValueString = getXMLArgString$(arg, " value=")
                SELECT CASE propertyName
                  CASE "LANDMARK":
                    __gmPortals(UBOUND(__gmPortals) - 1).landmarkHash = fzxComputeHash&&(propertyValueString)
                  CASE "MAP":
                    __gmPortals(UBOUND(__gmPortals) - 1).map = propertyValueString
                  CASE "OPEN_CLOSED_LOCKED":
                    __gmPortals(UBOUND(__gmPortals) - 1).status = propertyValue
                  CASE "TILE_CLOSED":
                    __gmPortals(UBOUND(__gmPortals) - 1).tileOpen = propertyValue
                  CASE "TILE_OPEN":
                    __gmPortals(UBOUND(__gmPortals) - 1).tileClosed = propertyValue
                END SELECT
            END SELECT
          CASE "Lights":
            elementValueString = getXMLArgString$(arg, " value=")
            elementValueString = UCASE$("&H" + RIGHT$(elementValueString, LEN(elementValueString) - INSTR(elementValueString, "#")))
            tempColor = VAL(elementValueString)
            lights(UBOUND(lights)).position.x = xl
            lights(UBOUND(lights)).position.y = yl
            lights(UBOUND(lights)).lightColor = tempColor
            REDIM _PRESERVE lights(UBOUND(lights) + 1) AS tLIGHT
        END SELECT
    END SELECT
  NEXT
  constructGameMap tile(), tilemap, lights()
END SUB

SUB XMLaddRigidBody (tile() AS tTILE, tilemap AS tTILEMAP, arg AS STRING)
  DIM AS STRING objectId, objectName, objectType
  DIM AS _FLOAT xp, yp, xs, ys
  DIM AS LONG tempId

  objectId = getXMLArgString$(arg, " id=")
  objectName = getXMLArgString$(arg, " name=")
  objectType = getXMLArgString$(arg, " type=")

  xp = getXMLArgValue(arg, " x=") * tilemap.tilescale
  yp = getXMLArgValue(arg, " y=") * tilemap.tilescale
  xs = (getXMLArgValue(arg, " width=") * tilemap.tilescale)
  ys = (getXMLArgValue(arg, " height=") * tilemap.tilescale)
  ' Create Ridid body
  IF objectType = "BOX" THEN
    tempId = fzxCreateBoxBodyEx(objectName, xs / 2, ys / 2)
  ELSE IF objectType = "CIRCLE" THEN
      tempId = fzxCreateCircleBodyEx(objectName, xs / 2)
    END IF
  END IF
  fzxSetBody cFZX_PARAMETER_POSITION, tempId, xp + (xs / 2), yp + (ys / 2)
  fzxSetBody cFZX_PARAMETER_ORIENT, tempId, 0, 0
  fzxSetBody cFZX_PARAMETER_NOPHYSICS, tempId, 0, 0
  'build texture for Box
  DIM AS tTILEMAP tempLayout
  DIM AS LONG tx, ty, tileStartX, tileStartY, mapSizeX, mapSizeY, gamemapX, gameMapY, tempMapPos, gameMapPos, imgId
  tileStartX = xp / tilemap.tileWidth
  tileStartY = yp / tilemap.tileHeight
  mapSizeX = xs / tilemap.tileWidth
  mapSizeY = ys / tilemap.tileHeight
  imgId = allocateTextureEX(tile(), _NEWIMAGE(xs, ys, 32))
  DIM AS tTILE tempMAP(mapSizeX * mapSizeY)
  FOR ty = 0 TO mapSizeY - 1
    FOR tx = 0 TO mapSizeX - 1
      gamemapX = tx + tileStartX
      gameMapY = ty + tileStartY
      gameMapPos = gamemapX + (gameMapY * tilemap.mapWidth)
      tempMapPos = tx + ty * mapSizeX
      tempMAP(tempMapPos) = __gmMap(gameMapPos)
    NEXT
  NEXT
  tempLayout = tilemap
  tempLayout.mapWidth = mapSizeX
  tempLayout.mapHeight = mapSizeY
  buildMultiTileMap tempMAP(), tile(), tempLayout, tile(imgId).t, 1
  fzxSetBody cFZX_PARAMETER_TEXTURE, tempId, tile(imgId).t, 0
END SUB

SUB XMLsetGameMap (map() AS tTILE, mapindex AS LONG, mapLayer AS STRING, value AS _FLOAT)

  IF mapindex > UBOUND(map) THEN REDIM _PRESERVE map(mapindex) AS tTILE
  SELECT CASE mapLayer
    CASE "Tile Layer 1":
      map(mapindex).t = value
    CASE "Tile Rigid Body":
      map(mapindex).t0 = value
    CASE "Tile Collision":
      map(mapindex).collision = value
  END SELECT
  mapindex = mapindex + 1
END SUB

'**********************************************************************************************
'   MAP/LEVEL Functions/Subs
'**********************************************************************************************
SUB _______________MAP_LEVEL_HANDLING (): END SUB

SUB clearMapData (tile() AS tTILE, _
                  message() AS tMESSAGE)
  fzxJointClear
  fzxBodyClearPerm
  levelSave
  ERASE __gmMap
  REDIM __gmMap(0) AS tTILE
  ERASE tile
  REDIM tile(0) AS tTILE
  ERASE __gmPortals
  REDIM __gmPortals(0) AS tDOOR
  ERASE __gmEntity
  REDIM __gmEntity(0) AS tENTITY
  ERASE message
  REDIM message(0) AS tMESSAGE
END SUB

SUB levelSave

  OPEN _CWD$ + "\" + OSPathJoin$ + "Saves" + OSPathJoin$ + _TRIM$(__gmEngine.currentMap) + ".mp" FOR BINARY AS #56
  PUT #56, , __gmMap()
  CLOSE #56
  OPEN _CWD$ + "\" + OSPathJoin$ + "Saves" + OSPathJoin$ + _TRIM$(__gmEngine.currentMap) + ".pt" FOR BINARY AS #56
  PUT #56, , __gmPortals()
  CLOSE #56
  OPEN _CWD$ + "\" + OSPathJoin$ + "Saves" + OSPathJoin$ + _TRIM$(__gmEngine.currentMap) + ".et" FOR BINARY AS #56
  PUT #56, , __gmEntity()
  CLOSE #56

END SUB

SUB loadlevel
  'REDIM __gmMap(0) AS tTILE
  OPEN _CWD$ + "\" + OSPathJoin$ + "Saves" + OSPathJoin$ + _TRIM$(__gmEngine.currentMap) + ".mp" FOR BINARY AS #56
  GET #56, , __gmMap()
  CLOSE #56
  OPEN _CWD$ + "\" + OSPathJoin$ + "Saves" + OSPathJoin$ + _TRIM$(__gmEngine.currentMap) + ".pt" FOR BINARY AS #56
  PUT #56, , __gmPortals()
  CLOSE #56
  OPEN _CWD$ + "\" + OSPathJoin$ + "Saves" + OSPathJoin$ + _TRIM$(__gmEngine.currentMap) + ".et" FOR BINARY AS #56
  PUT #56, , __gmEntity()
  CLOSE #56

END SUB


'**********************************************************************************************
'   SOUND Functions/Subs
'**********************************************************************************************
SUB _______________SOUND_HANDLING (): END SUB

SUB playMusic (playlist AS tPLAYLIST, sounds() AS tSOUND, id AS STRING)
  DIM AS LONG music
  music = soundManagerIDClass(sounds(), id)
  IF music > -1 THEN
    IF NOT _SNDPLAYING(sounds(music).handle) THEN
      IF playlist.fsm.currentState = cFSM_SOUND_IDLE THEN
        playlist.currentMusic = music
      ELSE
        playlist.nextMusic = music
      END IF
    END IF
  END IF
END SUB

SUB stopMusic (playlist AS tPLAYLIST)
  playlist.nextMusic = -1
  fzxFSMChangeState playlist.fsm, cFSM_SOUND_LEADOUT
END SUB

SUB handleMusic (playlist AS tPLAYLIST, sounds() AS tSOUND)
  playlist.fsm.timerState.duration = 3
  SELECT CASE playlist.fsm.currentState
    CASE cFSM_SOUND_IDLE:
      IF playlist.currentMusic > -1 THEN
        fzxFSMChangeState playlist.fsm, cFSM_SOUND_START
      END IF
    CASE cFSM_SOUND_START:
      _SNDVOL sounds(playlist.currentMusic).handle, 0
      _SNDPLAY sounds(playlist.currentMusic).handle
      _SNDLOOP sounds(playlist.currentMusic).handle
      fzxFSMChangeState playlist.fsm, cFSM_SOUND_LEADIN
    CASE cFSM_SOUND_LEADIN:
      _SNDVOL sounds(playlist.currentMusic).handle, __gmOptions.musicVolume * fzxScalarLERPProgress#(playlist.fsm.timerState.start, playlist.fsm.timerState.start + playlist.fsm.timerState.duration)
      fzxFSMChangeStateOnTimer playlist.fsm, cFSM_SOUND_PLAY
    CASE cFSM_SOUND_PLAY:
      _SNDVOL sounds(playlist.currentMusic).handle, __gmOptions.musicVolume
      IF playlist.currentMusic <> playlist.nextMusic AND playlist.nextMusic > -1 THEN
        fzxFSMChangeState playlist.fsm, cFSM_SOUND_LEADOUT
      END IF
    CASE cFSM_SOUND_LEADOUT:
      IF playlist.currentMusic > -1 THEN
        _SNDVOL sounds(playlist.currentMusic).handle, __gmOptions.musicVolume * (1 - fzxScalarLERPProgress#(playlist.fsm.timerState.start, playlist.fsm.timerState.start + playlist.fsm.timerState.duration))
        fzxFSMChangeStateOnTimer playlist.fsm, cFSM_SOUND_CLEANUP
      ELSE
        fzxFSMChangeState playlist.fsm, cFSM_SOUND_CLEANUP
      END IF
    CASE cFSM_SOUND_CLEANUP:
      IF playlist.currentMusic > -1 THEN _SNDSTOP sounds(playlist.currentMusic).handle
      IF playlist.nextMusic = -1 THEN
        playlist.currentMusic = -1
        fzxFSMChangeState playlist.fsm, cFSM_SOUND_IDLE
      ELSE
        playlist.currentMusic = playlist.nextMusic
        playlist.nextMusic = -1
        fzxFSMChangeState playlist.fsm, cFSM_SOUND_START
      END IF
  END SELECT
END SUB

SUB addMusic (sounds() AS tSOUND, filename AS STRING, class AS STRING)
  DIM AS LONG index
  index = UBOUND(sounds)
  sounds(index).handle = _SNDOPEN(_CWD$ + OSPathJoin$ + "Assets" + OSPathJoin$ + filename)
  IF sounds(index).handle = 0 THEN
    PRINT "Could not open "; _CWD$ + OSPathJoin$ + "Assets" + OSPathJoin$ + filename
    waitkey
    SYSTEM
  END IF
  sounds(index).fileName = filename
  sounds(index).fileHash = fzxComputeHash&&(filename)
  sounds(index).class = class
  sounds(index).classHash = fzxComputeHash&&(class)
  REDIM _PRESERVE sounds(index + 1) AS tSOUND
END SUB

SUB removeAllMusic (playlist AS tPLAYLIST, sounds() AS tSOUND)
  DIM AS LONG index
  playlist.nextMusic = -1
  playlist.currentMusic = -1
  fzxFSMChangeState playlist.fsm, cFSM_SOUND_IDLE
  FOR index = 0 TO UBOUND(sounds)
    _SNDSTOP sounds(index).handle
    _SNDCLOSE sounds(index).handle
  NEXT
  REDIM sounds(0) AS tSOUND
END SUB

FUNCTION soundManagerIDFilename (sounds() AS tSOUND, objName AS STRING)
  DIM i AS LONG
  DIM uID AS _INTEGER64
  uID = fzxComputeHash&&(RTRIM$(LTRIM$(objName)))
  soundManagerIDFilename = -1
  FOR i = 0 TO UBOUND(sounds) - 1
    IF sounds(i).fileHash = uID THEN
      soundManagerIDFilename = i
      EXIT FUNCTION
    END IF
  NEXT
END FUNCTION

FUNCTION soundManagerIDClass (sounds() AS tSOUND, objName AS STRING)
  DIM i AS LONG
  DIM uID AS _INTEGER64
  uID = fzxComputeHash&&(RTRIM$(LTRIM$(objName)))
  soundManagerIDClass = -1
  FOR i = 0 TO UBOUND(sounds)
    IF sounds(i).classHash = uID THEN
      soundManagerIDClass = i
      EXIT FUNCTION
    END IF
  NEXT
END FUNCTION


'**********************************************************************************************
'   Color Mixer Functions/Subs
'**********************************************************************************************
SUB _______________COLOR_MIXER (): END SUB
FUNCTION colorChannelMixer (colorChannelA AS _UNSIGNED _BYTE, colorChannelB AS _UNSIGNED _BYTE, amountToMix AS _FLOAT)
  DIM AS _FLOAT channelA, channelB
  channelA = colorChannelA * amountToMix
  channelB = colorChannelB * (1 - amountToMix)
  colorChannelMixer = INT(channelA + channelB)
END FUNCTION

FUNCTION colorMixer& (rgbA AS LONG, rgbB AS LONG, amountToMix AS _FLOAT)
  DIM AS _UNSIGNED _BYTE r, g, b
  r = colorChannelMixer(_RED(rgbA), _RED(rgbB), amountToMix)
  g = colorChannelMixer(_GREEN(rgbA), _GREEN(rgbB), amountToMix)
  b = colorChannelMixer(_BLUE(rgbA), _BLUE(rgbB), amountToMix)
  colorMixer = _RGB(r, g, b)
END FUNCTION

' the following Sub is by Galleon
SUB DarkenImage (Image AS LONG, Value_From_0_To_1 AS SINGLE)
  IF Value_From_0_To_1 <= 0 OR Value_From_0_To_1 >= 1 OR _PIXELSIZE(Image) <> 4 THEN EXIT SUB
  DIM Buffer AS _MEM: Buffer = _MEMIMAGE(Image) 'Get a memory reference to our image
  DIM Frac_Value AS LONG: Frac_Value = Value_From_0_To_1 * 65536 'Used to avoid slow floating point calculations
  DIM O AS _OFFSET, O_Last AS _OFFSET
  O = Buffer.OFFSET 'We start at this offset
  O_Last = Buffer.OFFSET + _WIDTH(Image) * _HEIGHT(Image) * 4 'We stop when we get to this offset
  'use on error free code ONLY!
  $CHECKING:OFF
  DO
    _MEMPUT Buffer, O, _MEMGET(Buffer, O, _UNSIGNED _BYTE) * Frac_Value \ 65536 AS _UNSIGNED _BYTE
    _MEMPUT Buffer, O + 1, _MEMGET(Buffer, O + 1, _UNSIGNED _BYTE) * Frac_Value \ 65536 AS _UNSIGNED _BYTE
    _MEMPUT Buffer, O + 2, _MEMGET(Buffer, O + 2, _UNSIGNED _BYTE) * Frac_Value \ 65536 AS _UNSIGNED _BYTE
    O = O + 4
  LOOP UNTIL O = O_Last
  'turn checking back on when done!
  $CHECKING:ON
  _MEMFREE Buffer
END SUB


'**********************************************************************************************
'     LandMarks Functions/Subs
'**********************************************************************************************
SUB _______________gmLandmark_SUBS (): END SUB

SUB findLandmarkPosition (landmarks() AS tLANDMARK, id AS STRING, o AS tFZX_VECTOR2d)
  DIM AS LONG index
  DIM AS _INTEGER64 hash
  hash = fzxComputeHash&&(id)
  FOR index = 0 TO UBOUND(landmarks) - 1
    IF landmarks(index).landmarkHash = hash THEN
      o = landmarks(index).position
      EXIT SUB
    END IF
  NEXT
END SUB

SUB findLandmarkPositionHash (landmarks() AS tLANDMARK, hash AS _INTEGER64, o AS tFZX_VECTOR2d)
  DIM AS LONG index
  FOR index = 0 TO UBOUND(landmarks) - 1
    IF landmarks(index).landmarkHash = hash THEN
      o = landmarks(index).position
      EXIT SUB
    END IF
  NEXT
END SUB

FUNCTION findLandmark (landmarks() AS tLANDMARK, id AS STRING)
  DIM AS LONG index
  DIM AS _INTEGER64 hash
  hash = fzxComputeHash&&(id)
  FOR index = 0 TO UBOUND(landmarks) - 1
    IF landmarks(index).landmarkHash = hash THEN
      findLandmark = index
      EXIT FUNCTION
    END IF
  NEXT
END FUNCTION

FUNCTION findLandmarkHash (landmarks() AS tLANDMARK, hash AS _INTEGER64)
  DIM AS LONG index
  FOR index = 0 TO UBOUND(landmarks) - 1
    IF landmarks(index).landmarkHash = hash THEN
      findLandmarkHash = index
      EXIT FUNCTION
    END IF
  NEXT
END FUNCTION


'**********************************************************************************************
'     Door Functions/Subs
'**********************************************************************************************
SUB _______________DOOR_FUNCTION (): END SUB

FUNCTION handleDoors&
  DIM AS LONG index, playerid
  playerid = entityManagerID("PLAYER")
  handleDoors = -1
  FOR index = 0 TO UBOUND(__gmPortals) - 1
    IF NOT fzxIsBodyTouchingBody(__gmEntity(playerid).objectID, __gmPortals(index).bodyId) THEN
      handleDoors = index
      EXIT FUNCTION
    END IF
  NEXT
END FUNCTION

'**********************************************************************************************
'     Operating System Related
'**********************************************************************************************
SUB _______________OS_CONSIDERATIONS (): END SUB

FUNCTION OSPathJoin$
  ' This can be easily optomized, however more cases may come up and I want
  ' to be able to include those as well.
  SELECT CASE LEFT$(_OS$, INSTR(2, _OS$, "]"))
    CASE "[WINDOWS]":
      OSPathJoin$ = "\"
    CASE "[LINUX]":
      OSPathJoin$ = "/"
    CASE "[MACOSX]":
      OSPathJoin$ = "/"
    CASE ELSE
      OSPathJoin$ = "/"
  END SELECT
END FUNCTION




