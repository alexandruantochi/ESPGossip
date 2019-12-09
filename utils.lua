local utils = {};

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

utils.pickRandomNode = function(self)
    local randomListPick = node.random(1, tables.getn(self.config.seedList));
    return self.config.seedList[randomListPick];
end

utils.setConfig = function(self, userConfig)
    for k, v in pairs(userConfig) do
        if (self.config[k] ~= nil and type(self.config[k]) == type(v)) then
            self.logVerbose('Setting ' .. k);
            self.config[k] = v;
        end
    end
end

utils.receiveData = function(self)
    return function(socket, data, port, ip)
        print('Received : ' .. data .. ' from ip: ' .. ip .. ' on port ' .. port);
    end
end

utils.sendData = function(self)
    return function(port, ip, data)
        print('Sent info to ' .. ip);
    end
end

local function initRev(gossip)
    local revFile = 'gossip/rev.dat';
    if (file.exists(revFile)) then
        local revision = file.getcontents(revFile) + 1;
        file.putcontents(revFile, revision);
        gossip.state.revision = revision;
        gossip:logVerbose('Updated revision to ' .. gossip.state.revision);
    else
        file.putcontents(revFile, gossip.state.revision);
        gossip:logVerbose('Revision set to ' .. gossip.state.revision);
    end
end

utils.start = function(self)
    if self.started then
        self:logInfo('Gossip already started.');
        return;
    end
    initRev(self);
    self.inboundSocket = net.createUDPSocket();
    self.inboundSocket:listen(self.config.inboundPort);
    self.inboundSocket:on('receive', self:receiveData());
    self.started = true;
end

utils.updateHeartbeat = function(self)
    self.state.heartbeat = tmr.time();
end

return utils;
