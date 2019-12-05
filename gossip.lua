return (function()
    local constants = require('constants');
    local utils = require('utils');

    local gossip = {
        config = constants.defaultConfig;
        state = constants.initialState,
        setConfig = utils.setConfig,
        pickRandomNode = utils.pickRandomNode,
        receiveData = utils.receiveData,
        sendData = utils.sendData,
        logInfo = utils.logInfo,
        logVerbose = utils.logVerbose,
        start = utils.start
    };
    constants = nil;
    utils = nil;

    return gossip;
end)();