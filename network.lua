local network = {};

network.pickRandomNode = function(self)
    local randomListPick = node.random(1, tables.getn(self.config.seedList));
    return self.config.seedList[randomListPick];
end

network.receiveData = function(self)
    return function(socket, data, port, ip)
        print('Received : ' .. data .. ' from ip: ' .. ip .. ' on port ' .. port);
    end
end

network.sendData = function(self)
    return function(port, ip, data)
        print('Sent info to ' .. ip);
    end
end