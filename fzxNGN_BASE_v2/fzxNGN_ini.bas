'**********************************************************************************************

'   Physics code ported from RandyGaul's Impulse Engine
'   https://github.com/RandyGaul/ImpulseEngine
'   http://RandyGaul.net
'**********************************************************************************************
'    Copyright (c) 2013 Randy Gaul http://RandyGaul.net

'    This software is provided 'as-is', without any express or implied
'    warranty. In no event will the authors be held liable for any damages
'    arising from the use of this software.

'    Permission is granted to anyone to use this software for any purpose,
'    including commercial applications, and to alter it and redistribute it
'    freely, subject to the following restrictions:
'      1. The origin of this software must not be misrepresented; you must not
'         claim that you wrote the original software. If you use this software
'         in a product, an acknowledgment in the product documentation would be
'         appreciated but is not required.
'      2. Altered source versions must be plainly marked as such, and must not be
'         misrepresented as being the original software.
'      3. This notice may not be removed or altered from any source distribution.
'
$IF FZXINIINCLUDE = UNDEFINED THEN
  $LET FZXINIINCLUDE = TRUE

  TYPE tFZX_VECTOR2d
    x AS DOUBLE
    y AS DOUBLE
  END TYPE

  TYPE tFZX_TRIANGLE ' Not used
    a AS tFZX_VECTOR2d
    b AS tFZX_VECTOR2d
    c AS tFZX_VECTOR2d
  END TYPE

  TYPE tFZX_LINE2d ' Not used
    a AS tFZX_VECTOR2d
    b AS tFZX_VECTOR2d
  END TYPE

  TYPE tFZX_FACE2d ' Not used
    f0 AS tFZX_VECTOR2d
    f1 AS tFZX_VECTOR2d
  END TYPE

  TYPE tFZX_VECTOR2dl
    x AS LONG
    y AS LONG
  END TYPE

  TYPE tFZX_QUAD
    a AS tFZX_VECTOR2d
    b AS tFZX_VECTOR2d
  END TYPE

  TYPE tFZX_BOX
    start AS tFZX_VECTOR2d
    finish AS tFZX_VECTOR2d
  END TYPE

  TYPE tFZX_ELAPSEDTIMER
    start AS _FLOAT
    last AS _FLOAT
    duration AS _FLOAT
  END TYPE

  TYPE tFZX_FSM
    currentState AS LONG
    previousState AS LONG
    timerState AS tFZX_ELAPSEDTIMER
    arg1 AS tFZX_VECTOR2d ' keep some info on goals
    arg2 AS tFZX_VECTOR2d
    arg3 AS _FLOAT
    arg4 AS LONG
  END TYPE

  TYPE tFZX_MOUSEBUTTON
    button AS _BYTE
    lastButton AS _BYTE
    time AS DOUBLE
    clickCount AS LONG
    PosEdge AS _BYTE
    NegEdge AS _BYTE
    anchorPosition AS tFZX_VECTOR2d
    dropPosition AS tFZX_VECTOR2d
    singleClick AS _BYTE
    doubleClick AS _BYTE
    drag AS _BYTE
  END TYPE

  TYPE tFZX_MOUSE
    mouseMode AS LONG '0 - hidden, 1 - show
    mouseOnScreen AS INTEGER
    mouseIcon AS LONG ' mouse pointer sprite
    mouseBody AS LONG ' for rigid body applications
    velocity AS tFZX_VECTOR2d
    position AS tFZX_VECTOR2d
    lastPosition AS tFZX_VECTOR2d
    worldPosition AS tFZX_VECTOR2d
    gamePosition AS tFZX_VECTOR2d ' used for tile based positions
    offset AS tFZX_VECTOR2d
    b1 AS tFZX_MOUSEBUTTON
    b2 AS tFZX_MOUSEBUTTON
    b3 AS tFZX_MOUSEBUTTON
    w AS INTEGER 'wheel
    wCount AS INTEGER 'wheelCount
    wCountLast AS INTEGER 'for checking for changes in Mouse wheel
    wheelChange AS _BYTE
    hoverOver AS LONG ' id of window currently over
    hoverOverElement AS LONG 'Element which the mouse is touching
  END TYPE

  TYPE tFZX_MOUSESETTINGS
    doubleclickdelay AS DOUBLE
  END TYPE

  TYPE tFZX_KEYBOARD
    keyHit AS LONG
    keyHitPosEdge AS _BYTE
    keyHitNegEdge AS _BYTE
    keyReleased AS LONG
    lastKeyHit AS LONG
    lastKeyReleased AS LONG
    r_ctrl AS _UNSIGNED _BYTE
    r_alt AS _UNSIGNED _BYTE
    r_shift AS _UNSIGNED _BYTE
    l_ctrl AS _UNSIGNED _BYTE
    l_alt AS _UNSIGNED _BYTE
    l_shift AS _UNSIGNED _BYTE

  END TYPE

  TYPE tFZX_INPUTDEVICE
    mouse AS tFZX_MOUSE
    keyboard AS tFZX_KEYBOARD
  END TYPE


  TYPE tFZX_MATRIX2D
    m00 AS DOUBLE
    m01 AS DOUBLE
    m10 AS DOUBLE
    m11 AS DOUBLE
  END TYPE

  TYPE tFZX_SETTINGS
    mouse AS tFZX_MOUSESETTINGS
  END TYPE

  TYPE tFZX_SHAPE
    ty AS LONG ' cFZX_SHAPE_CIRCLE = 1, cFZX_SHAPE_POLYGON = 2
    radius AS DOUBLE ' Only necessary for circle shapes
    maxDimension AS tFZX_VECTOR2d 'To optomize fzxAABB for collision
    u AS tFZX_MATRIX2D ' Only necessary for fzxPolygons
    vert AS _MEM
    norm AS _MEM
    texture AS LONG
    textureID AS LONG
    renderOrder AS LONG 'Needs to be implemented to sort BACK TO FRONT
    timing AS LONG
    flipTexture AS LONG 'flag for flipping texture depending on direction
    repeatTexture AS tFZX_VECTOR2d
    scaleTexture AS tFZX_VECTOR2d
    offsetTexture AS tFZX_VECTOR2d
    ' Texture Coordinates
    uv0 AS tFZX_VECTOR2d
    uv1 AS tFZX_VECTOR2d
    uv2 AS tFZX_VECTOR2d
    uv3 AS tFZX_VECTOR2d
  END TYPE

  TYPE tFZX_POLYATTRIB 'keep track of vertices counts in a body
    count AS LONG ' number of vertices in fzxPolygon
  END TYPE

  TYPE tFZX_PHYSICS
    isStatic AS LONG
    position AS tFZX_VECTOR2d
    velocity AS tFZX_VECTOR2d
    force AS tFZX_VECTOR2d
    angularVelocity AS DOUBLE
    torque AS DOUBLE
    orient AS DOUBLE
    mass AS DOUBLE
    invMass AS DOUBLE
    inertia AS DOUBLE
    invInertia AS DOUBLE
    staticFriction AS DOUBLE
    dynamicFriction AS DOUBLE
    restitution AS DOUBLE

  END TYPE

  TYPE tFZX_SPECIALFUNCTION
    func AS LONG
    arg AS LONG
  END TYPE

  TYPE tFZX_BODY
    objectName AS STRING * 64
    objectHash AS _INTEGER64
    entityID AS LONG
    lifetime AS tFZX_ELAPSEDTIMER
    overwrite AS _BYTE ' 0 - normal, 1 - overwrite body
    fzx AS tFZX_PHYSICS
    shape AS tFZX_SHAPE
    pa AS tFZX_POLYATTRIB
    c AS LONG ' color
    enable AS LONG 'Used to determine if body is active or not
    collisionMask AS _UNSIGNED INTEGER 'is a bit mask is used by 'AND'ing together to test collisions
    noPhysics AS LONG 'Allows collisions but does not apply any fzxImpulses
    specFunc AS tFZX_SPECIALFUNCTION 'Special Function
    zPosition AS DOUBLE ' only used for rendering - higher number closer to camera
  END TYPE

  TYPE tFZX_MANIFOLD
    A AS LONG
    B AS LONG
    penetration AS DOUBLE
    normal AS tFZX_VECTOR2d
    contactCount AS LONG
    e AS DOUBLE
    df AS DOUBLE
    sf AS DOUBLE
    cv AS DOUBLE 'contact velocity
  END TYPE

  TYPE tFZX_HIT
    A AS LONG
    B AS LONG
    position AS tFZX_VECTOR2d
    cv AS DOUBLE
  END TYPE

  TYPE tFZX_JOINT
    jointName AS STRING * 64
    jointHash AS _INTEGER64
    overwrite AS _BYTE ' 0 - normal 1 - overwrite
    M AS tFZX_MATRIX2D
    localAnchor1 AS tFZX_VECTOR2d
    localAnchor2 AS tFZX_VECTOR2d
    r1 AS tFZX_VECTOR2d
    r2 AS tFZX_VECTOR2d
    bias AS tFZX_VECTOR2d
    P AS tFZX_VECTOR2d
    body1 AS LONG
    body2 AS LONG
    biasFactor AS DOUBLE
    softness AS DOUBLE
    wireframe_color AS LONG
    max_bias AS DOUBLE
    render AS _BYTE
  END TYPE

  TYPE tFZX_WORLD
    plusLimit AS tFZX_VECTOR2d
    minusLimit AS tFZX_VECTOR2d
    gravity AS tFZX_VECTOR2d
    spawn AS tFZX_VECTOR2d
    terrainPosition AS tFZX_VECTOR2d
    resting AS DOUBLE
    dT AS DOUBLE
    iterations AS INTEGER
  END TYPE

  TYPE tFZX_VEHICLE
    vehicleName AS STRING * 64
    vehicleHash AS _INTEGER64
    body AS LONG
    wheelOne AS LONG
    wheelTwo AS LONG
    axleJointOne AS LONG
    axleJointTwo AS LONG
    auxBodyOne AS LONG
    auxJointOne AS LONG
    wheelOneOffset AS tFZX_VECTOR2d
    wheelTwoOffset AS tFZX_VECTOR2d
    auxOneOffset AS tFZX_VECTOR2d
    torque AS DOUBLE
  END TYPE

  TYPE tFZX_BODYMANAGER
    objectCount AS LONG
    jointCount AS LONG
  END TYPE

  TYPE tFZX_CAMERA
    position AS tFZX_VECTOR2d
    invZoom AS DOUBLE
    zoom AS DOUBLE
    fov AS tFZX_VECTOR2d
    fsm AS tFZX_FSM
    AABB AS tFZX_VECTOR2d
    AABB_size AS tFZX_VECTOR2d
    bkImg AS LONG ' static background image
  END TYPE


  TYPE tFZX_NETWORK
    SorC AS LONG ' boolean Server or Client
    address AS STRING * 1024
    port AS LONG
    protocol AS STRING * 32
    HCHandle AS LONG
    connectionHandle AS LONG
  END TYPE

  TYPE tFZX_STRINGTUPLE
    contextName AS STRING * 64
    arg AS STRING * 4096
  END TYPE

  TYPE tFZX_FPS
    fpsCountFine AS LONG
    fpsLastFine AS LONG
    fpsCount AS LONG
    fpsLast AS LONG
    fpsCount1 AS LONG
    fpsLast1 AS LONG
    dt AS DOUBLE
  END TYPE

  CONST cFZX_FALSE = 0
  CONST cFZX_TRUE = -1


  CONST cFZX_SHAPE_CIRCLE = 1
  CONST cFZX_SHAPE_POLYGON = 2

  CONST cFZX_AABB_TOLERANCE! = 1.5
  CONST cFZX_PRECISION! = 100

  CONST cFZX_PI! = 3.14159
  CONST cFZX_EPSILON! = 0.0001
  CONST cFZX_EPSILON_SQ! = cFZX_EPSILON * cFZX_EPSILON
  CONST cFZX_BIAS_RELATIVE! = 0.95
  CONST cFZX_BIAS_ABSOLUTE! = 0.01
  CONST cFZX_DT! = 1.0 / 30.0
  CONST cFZX_ITERATIONS = 400
  CONST cFZX_PENETRATION_ALLOWANCE! = 0.05
  CONST cFZX_PENETRATION_CORRECTION! = 0.4
  CONST cFZX_MASS_DENSITY! = 0.00001


  CONST cFZX_PARAMETER_POSITION = 1
  CONST cFZX_PARAMETER_VELOCITY = 2
  CONST cFZX_PARAMETER_FORCE = 3
  CONST cFZX_PARAMETER_ANGULARVELOCITY = 4
  CONST cFZX_PARAMETER_TORQUE = 5
  CONST cFZX_PARAMETER_ORIENT = 6
  CONST cFZX_PARAMETER_STATICFRICTION = 7
  CONST cFZX_PARAMETER_DYNAMICFRICTION = 8
  CONST cFZX_PARAMETER_RESTITUTION = 9
  CONST cFZX_PARAMETER_COLOR = 10
  CONST cFZX_PARAMETER_ENABLE = 11
  CONST cFZX_PARAMETER_STATIC = 12
  CONST cFZX_PARAMETER_TEXTURE = 13
  CONST cFZX_PARAMETER_FLIPTEXTURE = 14
  CONST cFZX_PARAMETER_COLLISIONMASK = 15
  CONST cFZX_PARAMETER_INVERTNORMALS = 16
  CONST cFZX_PARAMETER_NOPHYSICS = 17
  CONST cFZX_PARAMETER_SPECIALFUNCTION = 18
  CONST cFZX_PARAMETER_RENDERORDER = 19
  CONST cFZX_PARAMETER_ENTITYID = 20
  CONST cFZX_PARAMETER_SCALETEXTURE = 21
  CONST cFZX_PARAMETER_OFFSETTEXTURE = 22
  CONST cFZX_PARAMETER_LIFETIME = 23
  CONST cFZX_PARAMETER_REPEATTEXTURE = 24
  CONST cFZX_PARAMETER_ZPOSITION = 25
  CONST cFZX_PARAMETER_UV0 = 25
  CONST cFZX_PARAMETER_UV1 = 26
  CONST cFZX_PARAMETER_UV2 = 27
  CONST cFZX_PARAMETER_UV3 = 28

  CONST cFZX_NET_NONE = 0
  CONST cFZX_NET_SERVER = 1
  CONST cFZX_NET_CLIENT = 2


  CONST cSTARTINGNUMBEROFOBJECTS = 1000 ' Max number of objects at one time
  CONST cSTARTINGNUMBEROFJOINTS = 100
  CONST cSTARTINGNUMBEROFHITS = 2000
  CONST cMAXVERTSPERBODY = 64


  DIM SHARED AS tFZX_BODY __fzxBody(cSTARTINGNUMBEROFOBJECTS)
  DIM SHARED AS tFZX_JOINT __fzxJoints(cSTARTINGNUMBEROFJOINTS)
  DIM SHARED AS tFZX_HIT __fzxHits(cSTARTINGNUMBEROFHITS)
  DIM SHARED AS tFZX_CAMERA __fzxCamera
  DIM SHARED AS tFZX_WORLD __fzxWorld
  DIM SHARED AS tFZX_FPS __fzxFPSCount
  DIM SHARED AS tFZX_INPUTDEVICE __fzxInputDevice
  DIM SHARED AS tFZX_SETTINGS __fzxSettings 'currently only used for the mouse doubleclick delay

  DIM AS LONG iter
  FOR iter = 0 TO UBOUND(__fzxBody)
    __fzxBody(iter).overwrite = 1
  NEXT

  FOR iter = 0 TO UBOUND(__fzxJoints)
    __fzxJoints(iter).overwrite = 1
  NEXT

$END IF
