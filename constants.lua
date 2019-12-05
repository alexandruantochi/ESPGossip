local constants = {} ;

constants.debugLevel = {
    VERBOSE = 0,
    INFO = 1
}

constants.nodeStatus = {
    DOWN = 1,
    FLAGGED = 2,
    UP = 3
}

constants.defaultConfig = {
    seedList = {},
    roundInterval = 10000,
    outbounPort = 5000,
    inboundPort = 5000,
    pickStrategy = 'random',
    partnerPick = 1,
    timeout = 5000,
    debugLevel = constants.debugLevel.VERBOSE
}

constants.status = {
    starting = 'starting',
    active = 'active',
    closing = 'closing'
}

constants.initialState = {
    revision = 1,
    heartbeat = 0,
    status = constants.status.starting
}

return constants;