local gossip = {};
local constants = {};
local utils = {};
local network = {};
local state = {};

-- Utils

utils.logVerbose = function(message)
    if (gossip.config.debugLevel <= constants.debugLevel.VERBOSE) then
        print(message);
    end
end

utils.logInfo = function(message)
    if (gossip.config.debugLevel <= constants.debugLevel.INFO) then
        print(message);
    end
end

utils.getNetworkState = function()
    return sjson.encode(gossip.networkState)
end

utils.isNodeDataValid = function(nodeData)
    return nodeData.revision ~= nil and nodeData.heartbeat ~= nil and nodeData.state ~= nil
end

utils.compareNodeData = function(data0, data1)
    if not utils.isNodeDataValid(data1) then
        return 0;
    end
    if data0.revision == data1.revision and data0.heartbeat == data1.heartbeat and data0.state == data1.state then
        return -1;
    end
    if data0.revision > data1.revision then
        return 0;
    end
    if data1.revision > data0.revision then
        return 1;
    end
    if data0.heartbeat > data1.heartbeat then
        return 0;
    end
    if data1.heartbeat > data0.heartbeat then
        return 1;
    end
    if data0.state > data1.state then
        return 0;
    end
    if data1.state > data0.state then
        return 1;
    end
    return 0;
end

utils.getNetworkStateDiff = function(synRequestData)
    local diff = {};
    local diffUpdateList='';
    for ip, nodeData in pairs(gossip.networkState) do
        if synRequestData[ip] == nil or utils.compareNodeData(nodeData, synRequestData[ip]) == 0 then
            diffUpdateList = diffUpdateList..ip..' ';
            diff[ip]=nodeData;
        end
    end
    utils.logVerbose('Computed diff: '..diffUpdateList);
    return diff;
end

utils.setConfig = function(userConfig)
    for k, v in pairs(userConfig) do
        if (gossip.config[k] ~= nil and type(gossip.config[k]) == type(v)) then
            gossip.config[k] = v;
            utils.logVerbose('Set value for '.. k);
        end
    end
end

-- State

state.setRev = function(revNumber)
    local revision = 0;
    local revFile = constants.revFileName;

    if revNumber ~= nil then
        revision = revNumber;
    elseif file.exists(revFile) then
        revision = file.getcontents(revFile) + 1;
    end
    file.putcontents(revFile, revision);
    gossip.currentState.revision = revision;
    utils.logVerbose('Revision set to ' .. gossip.currentState.revision);
end

state.setRevManually = function(revNumber)
    state.setRev(revNumber);
    utils.logInfo('Revision overriden to '..revNumber);
end

state.start = function()
    if gossip.started then
        utils.logInfo('Gossip already started.');
        return;
    end
    gossip.ip = wifi.sta.getip();
    if gossip.ip == nil then
        utils.logInfo('Node not connected to network. Gossip will not start.');
        return;
    end
    state.setRev();
    gossip.networkState[gossip.ip] = gossip.currentState;

    gossip.inboundSocket = net.createUDPSocket();
    gossip.inboundSocket:listen(gossip.config.comPort);
    gossip.inboundSocket:on('receive', network.stateUpdate());

    gossip.started = true;
    gossip.timer = tmr.create();
    gossip.timer:register(gossip.config.roundInterval, tmr.ALARM_AUTO, network.sendSyn);
    gossip.timer:start();
end

-- Network

network.updateNetworkState = function(synData)
    local updatedNodes = '';
    for ip, synNodeData in pairs(synData) do
        if gossip.networkState[ip] ~= nil then
            if utils.compareNodeData(gossip.networkState[ip], synNodeData) == 1 then
                gossip.networkState[ip] = synNodeData;
                updatedNodes = updatedNodes..ip..' ';
            end
        elseif utils.isNodeDataValid(synNodeData) then
            table.insert(gossip.config.seedList, ip);
            utils.logInfo('Inserted '..ip..' into seed list.');
            gossip.networkState[ip] = synNodeData;
            updatedNodes = updatedNodes..ip..' ';
        end
    end
    utils.logVerbose('Updated networkState with nodes: '..updatedNodes);
end

network.sendSyn = function()
    gossip.networkState[gossip.ip].heartbeat = tmr.time();
    local randomNode = network.pickRandomNode();
    if randomNode ~= nil then
        network.sendData(randomNode, gossip.networkState, constants.updateType.SYN);
        utils.logInfo('Sent network state to '..randomNode);
        if gossip.networkState[randomNode] ~= nil then
            local nodeState = gossip.networkState[randomNode].state;
            if nodeState > constants.nodeState.DOWN then
                nodeState = nodeState - 1;
                gossip.networkState[randomNode].state = nodeState;
            end
        end
    end
end

network.pickRandomNode = function()
    local randomListPick = {};
    if table.getn(gossip.config.seedList) > 0 then
       randomListPick = node.random(1, table.getn(gossip.config.seedList));
    else
        utils.logInfo('Seedlist is empty. Please provide one or wait for node to be contacted.');
        return nil;
    end
    return gossip.config.seedList[randomListPick];
end

network.sendData = function(ip, data, dataType)
    local outboundSocket = net.createUDPSocket();
    utils.logVerbose('Sending '..dataType..' to '..ip);
    local dataToSend = string.gsub(sjson.encode(data), constants.updateType.TEMPLATE, dataType, 1);
    outboundSocket:send(gossip.config.comPort, ip, dataToSend);
end

network.receiveSyn = function(ip, updateData)
    local diff = utils.getNetworkStateDiff(updateData);
    network.updateNetworkState(updateData);
    network.sendData(ip, diff, constants.updateType.ACK);
end

network.sendAck = function(updateData)
    local dataToUpdate = ''
    for k,v in pairs(updateData) do
        if utils.compareNodeData(gossip.networkState[k], updateData[k]) == 1 then
            gossip.networkState[k] = v;
            dataToUpdate = dataToUpdate..k..' ';
        end
    end
    if #dataToUpdate > 1 then
        utils.logVerbose('Updated via ack from peer : '..dataToUpdate);
    else
        utils.logVerbose('Received ack from peer with no updates.');
    end
end

network.stateUpdate = function()
    return function(socket, data, port, ip)
        if gossip.networkState[ip] ~= nil then
            gossip.networkState[ip].state = constants.nodeState.UP;
        end
        utils.logVerbose('Received data from ' .. ip);
        local messageDecoded, updateData = pcall(sjson.decode, data);
        if not messageDecoded then
            utils.logInfo('Invalid JSON received from '..ip);
            utils.logVerbose('Error msg: '..updateData..'\n'..data);
            return;
        end
        local updateType = updateData.type;
        updateData.type = nil;
        if updateType == constants.updateType.SYN then
            network.receiveSyn(ip, updateData);
        elseif updateType == constants.updateType.ACK then
            network.sendAck(updateData);
        else
            utils.logVerbose('Invalid data comming from ip '..ip..'. No type specified.');
            return;
        end
    end
end

-- Constants

constants.debugLevel = {
    VERBOSE = 0,
    INFO = 1
}

constants.nodeState = {
    REMOVE = 0,
    DOWN = 1,
    SUSPECT = 2,
    UP = 3
}

constants.defaultConfig = {
    seedList = {},
    roundInterval = 10000,
    comPort = 5000,
    pickStrategy = 'random',
    partnerPick = 1,
    timeout = 5000,
    debugLevel = constants.debugLevel.VERBOSE
}

constants.initialState = {
    revision = 1,
    heartbeat = 0,
    state = constants.nodeState.UP
}

constants.updateType = {
    ACK = 'ACK',
    SYN = 'SYN',
    TEMPLATE = '{{TYPE}}'
}

constants.revFileName = 'gossip/rev.dat';

-- Return

gossip = {
    started = false,
    config = constants.defaultConfig,
    currentState = constants.initialState,
    setConfig = utils.setConfig,
    start = state.start,
    setRevManually = state.setRevManually,
    networkState = {type = constants.updateType.TEMPLATE},
    getNetworkState = utils.getNetworkState
};

if (net == nil or file == nil or tmr == nil or wifi == nil) then
    error('Gossip requires these modules to work: net, file, tmr, wifi');
else
return gossip;
end
