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
            print('Setting '..k);
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

utils.start = function(self)
    self.inboundSocket = net.createUDPSocket();
    self.inboundSocket:listen(gossip.config.inboundPort);
    self.inboundSocket:on('receive', gossip:receiveData());
end

return utils;
