'$include:'fzxNGN_ini.bas'

$IF FZXFPSINCLUDE = UNDEFINED THEN
  $LET FZXFPSINCLUDE = TRUE
  SUB fzxInitFPS
    DIM timerOne AS LONG
    timerOne = _FREETIMER
    ON TIMER(timerOne, 1) fzxFPS
    TIMER(timerOne) ON

    'timerOne = _FREETIMER
    'ON TIMER(timerOne, 1) fzxFPSMain
    'TIMER(timerOne) ON

    'timerOne = _FREETIMER
    'ON TIMER(timerOne, .001) fzxFPSdt
    'TIMER(timerOne) ON
  END SUB

  SUB fzxFPS
    'DIM fpss AS STRING
    'fpss = "   MAIN LOOP FPS:" + STR$(__fzxFPSCount.fpsLast) + "  OPENGL FPS:" + STR$(__fzxFPSCount.fpsLast1) + "   "
    '_PRINTSTRING ((_WIDTH / 2) - (_PRINTWIDTH(fpss) / 2), 0), fpss
    __fzxStats.fps = __fzxFPSCount.fpsLast
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


$END IF

