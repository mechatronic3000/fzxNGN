'$include:'fzxNGN_ini.bas'
'$include:'fzxNGN_VECMATH.bas'
'$include:'fzxNGN_MATRIXMATH.bas'
$IF FZXCAMERAINCLUDE = UNDEFINED THEN
  $LET FZXCAMERAINCLUDE = TRUE
  '**********************************************************************************************
  '   Camera Math
  '**********************************************************************************************
  SUB _______________CAMERA_MATH (): END SUB


  SUB fzxWorldToCamera (index AS INTEGER, vert AS tFZX_VECTOR2d)
    fzxMatrix2x2MultiplyVector __fzxBody(index).shape.u, vert, vert
    fzxVector2DAddVector vert, __fzxBody(index).fzx.position
    fzxVector2DSubVector vert, __fzxCamera.position
    fzxVector2DAddVector vert, __fzxCamera.fov
    fzxVector2DMultiplyScalar vert, __fzxCamera.zoom
  END SUB

  SUB fzxWorldToCameraEx (posVert AS tFZX_VECTOR2d, vert AS tFZX_VECTOR2d)
    '    fzxVector2DAddVector vert, posVert
    vert = posVert
    fzxVector2DSubVector vert, __fzxCamera.position
    fzxVector2DAddVector vert, __fzxCamera.fov
    fzxVector2DMultiplyScalar vert, __fzxCamera.zoom
  END SUB

  SUB fzxCalculateFOV
    __fzxCamera.invZoom = 1 / __fzxCamera.zoom
    fzxVector2DSet __fzxCamera.fov, _WIDTH / 2 * __fzxCamera.invZoom, _HEIGHT / 2 * __fzxCamera.invZoom
  END SUB

  SUB fzxCameraToWorld (oVec AS tFZX_VECTOR2d, iVec AS tFZX_VECTOR2d)
    fzxVector2DMultiplyScalarND oVec, iVec, __fzxCamera.invZoom
    fzxVector2DAddVector oVec, __fzxCamera.position
    fzxVector2DSubVector oVec, __fzxCamera.fov
  END SUB

  SUB fzxCameratoWorldEx (iVec AS tFZX_VECTOR2d, oVec AS tFZX_VECTOR2d)
    'DIM AS tFZX_VECTOR2d Screencenter
    'fzxVector2DSet Screencenter, _WIDTH / 2.0 * (1 / Camera.zoom), _HEIGHT / 2.0 * (1 / Camera.zoom) ' Camera Center
    fzxVector2DSet oVec, iVec.x * __fzxCamera.invZoom, iVec.y * __fzxCamera.invZoom
    fzxVector2DAddVector oVec, __fzxCamera.position
    fzxVector2DSubVector oVec, __fzxCamera.fov
  END SUB

  SUB fzxCameratoWorldScEx (iVec AS tFZX_VECTOR2d, oVec AS tFZX_VECTOR2d)
    DIM AS tFZX_VECTOR2d Screencenter
    fzxVector2DSet Screencenter, (_WIDTH / 2.0) * __fzxCamera.invZoom, (_HEIGHT / 2.0) * __fzxCamera.invZoom ' Camera Center
    fzxVector2DSet oVec, iVec.x * __fzxCamera.invZoom, iVec.y * __fzxCamera.invZoom
    fzxVector2DAddVector oVec, __fzxCamera.position
    fzxVector2DSubVector oVec, __fzxCamera.fov
  END SUB


  SUB fzxWorldToCameraBody (index AS LONG, vert AS tFZX_VECTOR2d)
    DIM screenCenter AS tFZX_VECTOR2d
    fzxVector2DSet screenCenter, _WIDTH / 2 * (1 / __fzxCamera.zoom), _HEIGHT / 2 * (1 / __fzxCamera.zoom) ' Camera Center
    fzxMatrix2x2MultiplyVector __fzxBody(index).shape.u, vert, vert ' Rotate body
    fzxVector2DAddVector vert, __fzxBody(index).fzx.position ' Add Position
    fzxVector2DSubVector vert, __fzxCamera.position 'Sub Camera Position
    fzxVector2DAddVector vert, screenCenter ' Add to Screen Center
    fzxVector2DMultiplyScalar vert, __fzxCamera.zoom 'Zoom everything
  END SUB


  SUB fzxWorldToCameraBodyNR (index AS LONG, vert AS tFZX_VECTOR2d)
    DIM screenCenter AS tFZX_VECTOR2d
    fzxVector2DSet screenCenter, _WIDTH / 2 * (1 / __fzxCamera.zoom), _HEIGHT / 2 * (1 / __fzxCamera.zoom) ' Camera Center
    fzxVector2DAddVector vert, __fzxBody(index).fzx.position ' Add Position
    fzxVector2DSubVector vert, __fzxCamera.position 'Sub Camera Position
    fzxVector2DAddVector vert, screenCenter ' Add to camera Center
    fzxVector2DMultiplyScalar vert, __fzxCamera.zoom 'Zoom everything
  END SUB

$END IF
