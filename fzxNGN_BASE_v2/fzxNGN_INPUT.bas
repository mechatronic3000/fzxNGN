'$include:'fzxNGN_ini.bas'
'$include:'fzxNGN_CAMERA.bas'
$IF FZXINPUTINCLUDE = UNDEFINED THEN
  $LET FZXINPUTINCLUDE = TRUE

  SUB fzxHandleInputDevice

    __fzxInputDevice.mouse.lastPosition = __fzxInputDevice.mouse.position
    __fzxInputDevice.mouse.b1.lastButton = __fzxInputDevice.mouse.b1.button
    __fzxInputDevice.mouse.b2.lastButton = __fzxInputDevice.mouse.b2.button
    __fzxInputDevice.mouse.b3.lastButton = __fzxInputDevice.mouse.b3.button
    __fzxInputDevice.mouse.wCountLast = __fzxInputDevice.mouse.wCount
    __fzxInputDevice.keyboard.lastKeyHit = __fzxInputDevice.keyboard.keyHit

    '    _KEYCLEAR
    __fzxInputDevice.keyboard.keyHit = _KEYHIT
    DO WHILE _MOUSEINPUT
      __fzxInputDevice.mouse.position.x = _MOUSEX
      __fzxInputDevice.mouse.position.y = _MOUSEY
      __fzxInputDevice.mouse.b1.button = _MOUSEBUTTON(1)
      __fzxInputDevice.mouse.b2.button = _MOUSEBUTTON(2)
      __fzxInputDevice.mouse.b3.button = _MOUSEBUTTON(3)
      __fzxInputDevice.mouse.w = _MOUSEWHEEL
      __fzxInputDevice.mouse.wCount = __fzxInputDevice.mouse.wCount + __fzxInputDevice.mouse.w
      __fzxInputDevice.mouse.velocity.x = __fzxInputDevice.mouse.position.x - __fzxInputDevice.mouse.lastPosition.x
      __fzxInputDevice.mouse.velocity.y = __fzxInputDevice.mouse.position.y - __fzxInputDevice.mouse.lastPosition.y
    LOOP

    IF __fzxInputDevice.keyboard.keyHit <> __fzxInputDevice.keyboard.lastKeyHit THEN
      IF __fzxInputDevice.keyboard.keyHit THEN
        __fzxInputDevice.keyboard.keyHitPosEdge = __fzxInputDevice.keyboard.keyHit
      ELSE
        __fzxInputDevice.keyboard.keyHitNegEdge = __fzxInputDevice.keyboard.keyHit
      END IF
    ELSE
      __fzxInputDevice.keyboard.keyHitPosEdge = 0
      __fzxInputDevice.keyboard.keyHitNegEdge = 0
    END IF

    ' Button Down
    IF __fzxInputDevice.mouse.b1.button AND NOT __fzxInputDevice.mouse.b1.lastButton THEN
      __fzxInputDevice.mouse.b1.anchorPosition = __fzxInputDevice.mouse.position
      __fzxInputDevice.mouse.b1.PosEdge = cFZX_TRUE
      __fzxInputDevice.mouse.b1.time = TIMER(.001)
    ELSE
      __fzxInputDevice.mouse.b1.PosEdge = cFZX_FALSE
      IF TIMER(.001) - __fzxInputDevice.mouse.b1.time > __fzxSettings.mouse.doubleclickdelay THEN
        __fzxInputDevice.mouse.b1.clickCount = 0
      END IF
    END IF

    IF __fzxInputDevice.mouse.b2.button AND NOT __fzxInputDevice.mouse.b2.lastButton THEN
      __fzxInputDevice.mouse.b2.anchorPosition = __fzxInputDevice.mouse.position
      __fzxInputDevice.mouse.b2.PosEdge = cFZX_TRUE
      __fzxInputDevice.mouse.b2.time = TIMER(.001)
    ELSE
      __fzxInputDevice.mouse.b2.PosEdge = cFZX_FALSE
      IF TIMER(.001) - __fzxInputDevice.mouse.b2.time > __fzxSettings.mouse.doubleclickdelay THEN
        __fzxInputDevice.mouse.b2.clickCount = 0
      END IF
    END IF

    IF __fzxInputDevice.mouse.b3.button AND NOT __fzxInputDevice.mouse.b3.lastButton THEN
      __fzxInputDevice.mouse.b3.anchorPosition = __fzxInputDevice.mouse.position
      __fzxInputDevice.mouse.b3.PosEdge = cFZX_TRUE
      __fzxInputDevice.mouse.b3.time = TIMER(.001)
    ELSE
      __fzxInputDevice.mouse.b3.PosEdge = cFZX_FALSE
      IF TIMER(.001) - __fzxInputDevice.mouse.b3.time > __fzxSettings.mouse.doubleclickdelay THEN
        __fzxInputDevice.mouse.b3.clickCount = 0
      END IF
    END IF

    'Button Release
    IF NOT __fzxInputDevice.mouse.b1.button AND __fzxInputDevice.mouse.b1.lastButton THEN
      __fzxInputDevice.mouse.b1.dropPosition = __fzxInputDevice.mouse.position
      __fzxInputDevice.mouse.b1.NegEdge = cFZX_TRUE
      IF TIMER(.001) - __fzxInputDevice.mouse.b1.time < __fzxSettings.mouse.doubleclickdelay THEN
        __fzxInputDevice.mouse.b1.clickCount = __fzxInputDevice.mouse.b1.clickCount + 1
        __fzxInputDevice.mouse.b1.time = TIMER(.001)
      ELSE
        __fzxInputDevice.mouse.b1.clickCount = 0
      END IF
    ELSE
      __fzxInputDevice.mouse.b1.NegEdge = cFZX_FALSE
    END IF

    IF NOT __fzxInputDevice.mouse.b2.button AND __fzxInputDevice.mouse.b2.lastButton THEN
      __fzxInputDevice.mouse.b2.dropPosition = __fzxInputDevice.mouse.position
      __fzxInputDevice.mouse.b2.NegEdge = cFZX_TRUE
      IF TIMER(.001) - __fzxInputDevice.mouse.b2.time < __fzxSettings.mouse.doubleclickdelay THEN
        __fzxInputDevice.mouse.b2.clickCount = __fzxInputDevice.mouse.b2.clickCount + 1
        __fzxInputDevice.mouse.b2.time = TIMER(.001)
      ELSE
        __fzxInputDevice.mouse.b2.clickCount = 0
      END IF
    ELSE
      __fzxInputDevice.mouse.b2.NegEdge = cFZX_FALSE
    END IF

    IF NOT __fzxInputDevice.mouse.b3.button AND __fzxInputDevice.mouse.b3.lastButton THEN
      __fzxInputDevice.mouse.b3.dropPosition = __fzxInputDevice.mouse.position
      __fzxInputDevice.mouse.b3.PosEdge = cFZX_TRUE
      IF TIMER(.001) - __fzxInputDevice.mouse.b3.time < __fzxSettings.mouse.doubleclickdelay THEN
        __fzxInputDevice.mouse.b3.clickCount = __fzxInputDevice.mouse.b3.clickCount + 1
        __fzxInputDevice.mouse.b3.time = TIMER(.001)
      ELSE
        __fzxInputDevice.mouse.b3.clickCount = 0
      END IF
    ELSE
      __fzxInputDevice.mouse.b3.PosEdge = cFZX_FALSE
    END IF

    __fzxInputDevice.mouse.b1.drag = __fzxInputDevice.mouse.b1.button AND (__fzxInputDevice.mouse.position.x <> __fzxInputDevice.mouse.b1.anchorPosition.x OR __fzxInputDevice.mouse.position.y <> __fzxInputDevice.mouse.b1.anchorPosition.y)
    __fzxInputDevice.mouse.b2.drag = __fzxInputDevice.mouse.b2.button AND (__fzxInputDevice.mouse.position.x <> __fzxInputDevice.mouse.b2.anchorPosition.x OR __fzxInputDevice.mouse.position.y <> __fzxInputDevice.mouse.b2.anchorPosition.y)
    __fzxInputDevice.mouse.b3.drag = __fzxInputDevice.mouse.b3.button AND (__fzxInputDevice.mouse.position.x <> __fzxInputDevice.mouse.b3.anchorPosition.x OR __fzxInputDevice.mouse.position.y <> __fzxInputDevice.mouse.b3.anchorPosition.y)

    __fzxInputDevice.mouse.b1.doubleClick = (__fzxInputDevice.mouse.b1.NegEdge AND __fzxInputDevice.mouse.b1.clickCount = 2)
    __fzxInputDevice.mouse.b2.doubleClick = (__fzxInputDevice.mouse.b2.NegEdge AND __fzxInputDevice.mouse.b2.clickCount = 2)
    __fzxInputDevice.mouse.b3.doubleClick = (__fzxInputDevice.mouse.b3.NegEdge AND __fzxInputDevice.mouse.b3.clickCount = 2)

    __fzxInputDevice.mouse.b1.singleClick = (__fzxInputDevice.mouse.b1.NegEdge AND __fzxInputDevice.mouse.b1.clickCount = 1)
    __fzxInputDevice.mouse.b2.singleClick = (__fzxInputDevice.mouse.b2.NegEdge AND __fzxInputDevice.mouse.b2.clickCount = 1)
    __fzxInputDevice.mouse.b3.singleClick = (__fzxInputDevice.mouse.b3.NegEdge AND __fzxInputDevice.mouse.b3.clickCount = 1)

    __fzxInputDevice.mouse.wheelChange = __fzxInputDevice.mouse.wCount <> __fzxInputDevice.mouse.wCountLast
    __fzxInputDevice.mouse.mouseOnScreen = __fzxInputDevice.mouse.position.x > 0 AND __fzxInputDevice.mouse.position.x < _WIDTH AND __fzxInputDevice.mouse.position.y > 0 AND __fzxInputDevice.mouse.position.y < _HEIGHT


    fzxCameratoWorldScEx __fzxInputDevice.mouse.position, __fzxInputDevice.mouse.worldPosition
  END SUB
$END IF

