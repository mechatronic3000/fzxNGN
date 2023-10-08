'$include:'RougeLikeTypes.bi'
'$include:'RougeLikeConst.bi'
$IF GLOBALVARS = UNDEFINED THEN
  $LET GLOBALVARS = TRUE

  DIM SHARED __gmEngine AS tENGINE
  DIM SHARED __gmOptions AS tGAMEOPTIONS
  DIM SHARED __gmTimers(0) AS tFZX_ELAPSEDTIMER
  DIM SHARED __gmFont(255) AS tTILEFONT
  DIM SHARED __gmSounds(0) AS tSOUND
  DIM SHARED __gmPlayList AS tPLAYLIST
  DIM SHARED __logfile AS LONG
  DIM SHARED __gmLandmark(0) AS tLANDMARK
  DIM SHARED __gmPortals(0) AS tDOOR
  DIM SHARED __gmEntity(1) AS tENTITY
  DIM SHARED __gmMap(0) AS tTILE
  DIM SHARED __gmGuiMap(0) AS tTILE
  DIM SHARED __gmGuiTile(0) AS tTILE
  DIM SHARED __gmGuiLayout(10) AS tTILEMAP
  DIM SHARED __gmGuiFields(0) AS tGUI_FIELDS
  DIM SHARED __gmConsole AS tCONSOLE
  'DIM SHARED tileMap AS tTILEMAP
  'DIM SHARED tile(0) AS tTILE


$END IF
