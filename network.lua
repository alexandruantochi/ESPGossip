local network = {};

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
    else
        return -1;
    end
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

network.stateUpdate = function(self)
    return function(socket, data, port, ip)
        self:logVerbose('Received data from ' .. ip);
        local messageDecoded, updateData = pcall(sjson.decode, data);
        if not messageDecoded then
            self:logInfo('Invalid JSON received from '..ip);
            self:logVerbose('Error msg: '..updateData..'\n'..data);
            return;
        end
        local replyDiff = updateNetworkState(self, updateData);
        if table.getn(replyDiff) > 0 then
            self:logVerbose('Replying with updated data for '..table.getn(replyDiff)..' nodes.');
        end
    end
end

network.sendData = function(self)
    return function(port, ip, data)
        print('Sent info to ' .. ip);
    end
end

return network;
