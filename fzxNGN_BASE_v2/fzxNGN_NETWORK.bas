'$include:'fzxNGN_ini.bas'

$IF FZXNETWORKINCLUDE = UNDEFINED THEN
  $LET FZXNETWORKINCLUDE = TRUE
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
$END IF
