local network = {};

network.pickRandomNode = function(self)
    local randomListPick = node.random(1, tables.getn(self.config.seedList));
    return self.config.seedList[randomListPick];
end

network.receiveData = function(self)
    return function(socket, data, port, ip)
        print('Received from:' .. ip);
        local data = sjson.decode(data);
        for ip, nodeState in pairs(data) do
            print('Ip: ' .. ip);
            if nodeState.status ~= nil then
                print('Status: ' .. nodeState.status);
            end
        end
    end
end

network.sendData = function(self)
    return function(port, ip, data)
        print('Sent info to ' .. ip);
    end
end

return network;
