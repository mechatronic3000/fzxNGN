'$include:'fzxNGN_ini.bas'

$IF FZXFSMINCLUDE = UNDEFINED THEN
  $LET FZXFSMINCLUDE = TRUE
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
$END IF

