return (function()
    local constants = require('constants');
    local utils = require('utils');
    local network = require('network');

    local gossip = {
        started = false,
        config = constants.defaultConfig;
        state = constants.initialState,
        setConfig = utils.setConfig,
        pickRandomNode = network.pickRandomNode,
        receiveData = network.receiveData,
        sendData = network.sendData,
        logInfo = utils.logInfo,
        logVerbose = utils.logVerbose,
        start = state.start
    };
    utils = nil;

    return gossip;
end)();