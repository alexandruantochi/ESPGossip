return (function()
    local constants = require('constants');
    local utils = require('utils');
    local network = require('network');
    local state = require('state');

    local gossip = {
        started = false,
        config = constants.defaultConfig;
        currentState = constants.initialState,
        setConfig = utils.setConfig,
        pickRandomNode = network.pickRandomNode,
        receiveData = network.receiveData,
        sendData = network.sendData,
        logInfo = utils.logInfo,
        logVerbose = utils.logVerbose,
        start = state.start,
        networkState = {}
    };
    constants = nil;
    utils = nil;
    network = nil;
    state = nil;

    return gossip;

end)();