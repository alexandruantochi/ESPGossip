local constants = {};
local utils = {};
local network = {};
local state = {};

-- Gossip

local function initRev(gossip)
    gossip.currentState.ip = wifi.sta.getip();
    local revFile = 'gossip/rev.dat';
    if (file.exists(revFile)) then
        local revision = file.getcontents(revFile) + 1;
        file.putcontents(revFile, revision);
        gossip.currentState.revision = revision;
        gossip:logVerbose('Updated revision to ' .. gossip.currentState.revision);
    else
        file.putcontents(revFile, gossip.currentState.revision);
        gossip:logVerbose('Revision set to ' .. gossip.currentState.revision);
    end
end

-- State

state.start = function(self)
    if self.started then
        self:logInfo('Gossip already started.');
        return;
    end
    initRev(self);
    self.outbounSocket = net.createUDPSocket();
    self.inboundSocket = net.createUDPSocket();
    self.inboundSocket:listen(self.config.inboundPort);
    self.inboundSocket:on('receive', self:stateUpdate());
    self.started = true;
end

state.updateHeartbeat = function(self)
    self.state.heartbeat = tmr.time();
end

-- Network

local function compareData(data0, data1)
    if data1.revision == nil or data1.heartBeat == nil then
        return 0;
    end
    if data0.revision > data1.revision then
        return 0;
    elseif data1.revision > data0.revision then
        return 1;
    end
    if data0.heartBeat > data1.heartBeat then
        return 0;
    elseif data1.heartBeat > data0.heartBeat then
        return 1;
    end
    if data0.nodeState > data1.nodeState then
        return 0;
    elseif data1.nodeState > data0.nodeState then
        return 1;
    end
    return -1;
end

local function updateNetworkState(self, updateData)
    local diff = {};

    for ip, stateData in pairs(self.networkState) do
        if updateData[ip] == nil then
            self:logVerbose('Adding data to replyData for ip ' ..ip);
            table.insert(diff, stateData);
        end
    end

    for ip, stateData in pairs(updateData) do
        if self.networkState[ip] ~= nil then
            local dataResult = compareData(self.networkState[ip], stateData);
            if dataResult == 0 then
                self:logVerbose('Adding data to replyData for ip '..ip);
                table.insert(diff, self.networkState[ip]);
            elseif dataResult == 1 then
                self:logVerbose('Updating state for ' ..ip);
                self.networkState[ip] = stateData;
            end
        else
            self:logVerbose('Updating state for ' ..ip);
            self.networkState[ip] = stateData;
        end
    end

    return diff;
end

network.pickRandomNode = function(self)
    local randomListPick = node.random(1, tables.getn(self.config.seedList));
    return self.config.seedList[randomListPick];
end

local synNetworkState = function(self, updateData)
    local replyDiff = updateNetworkState(self, updateData);
    if table.getn(replyDiff) > 0 then
        replyDiff.type = constants.ACK;
        self:logVerbose('Replying with updated data for '..table.getn(replyDiff)..' nodes.');
        -- reply with difference here
    else
        -- reply with just ack
    end
end

local ackNetworkState = function(self, updateData)
    for k,v in pairs(updateData) do
        -- do a check before update?
        self.networkState[k] = v;
    end
end

network.stateUpdate = function(self)
    return function(socket, data, port, ip)
        if self.networkState[ip] ~= nil then
            self.networkState[ip].nodeStatus = constants.nodeStatus.UP;
        end
        self:logVerbose('Received data from ' .. ip);
        local messageDecoded, updateData = pcall(sjson.decode, data);
        if not messageDecoded then
            self:logInfo('Invalid JSON received from '..ip);
            self:logVerbose('Error msg: '..updateData..'\n'..data);
            return;
        end
        local updateDataType = updateData.type;
        updateData.type = nil;
        if updateDataType == constants.SYN then
            synNetworkState(self, updateData);
        elseif updateDataType == constants.ACK then
            ackNetworkState(self, updateData);
        else
            self:logVerbose('Invalid data comming from ip '..ip..'. No type specified');
            return;
        end
    end
end

network.replyDiff = function(self)
    return function(port, ip, data)
        print('Sent info to ' .. ip);
    end
end

-- Utils

utils.logVerbose = function(self, message)
    if (self.config.debugLevel < 1) then
        print(message);
    end
end

utils.logInfo = function(self, message)
    if (self.config.debugLevel < 2) then
        print(message);
    end
end

utils.setConfig = function(self, userConfig)
    for k, v in pairs(userConfig) do
        if (self.config[k] ~= nil and type(self.config[k]) == type(v)) then
            self:logVerbose('Setting ' .. k);
            self.config[k] = v;
        end
    end
end

-- Constants

constants.debugLevel = {
    VERBOSE = 0,
    INFO = 1
}

constants.nodeStatus = {
    DOWN = 0,
    SUSPECT = 1,
    UP = 2
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

constants.initialState = {
    revision = 1,
    heartbeat = 0,
}

constants.updateType =
{
    ACK = 'ACK',
    SYN = 'SYN'
}

-- Return

local gossip = {
    started = false,
    config = constants.defaultConfig;
    currentState = constants.initialState,
    setConfig = utils.setConfig,
    pickRandomNode = network.pickRandomNode,
    stateUpdate = network.stateUpdate,
    replyDiff = network.replyDiff,
    logInfo = utils.logInfo,
    logVerbose = utils.logVerbose,
    start = state.start,
    networkState = {}
};

if (net == nil or file == nil or tmr == nil) then
    error('Gossip requires these modules to work: net, file, tmr');
else
return gossip;
end
