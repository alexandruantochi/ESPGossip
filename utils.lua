local utils = {};

local function compareData(data0, data1)
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

utils.updateAndComputeDiff = function(self, receivedData)
    local diff = {}
    for ip in receivedData do
        if self.networkState[ip] ~= nil then
            local dataResult = compareData(self.networkState[ip], receivedData[ip]);
            if dataResult == 0 then
                table.insert(diff, self.networkState[ip]);
            elseif dataResult == 1 then
                self.networkState[ip] = receivedData[ip];
            end
        end
    end

    for ip in self.networkState do
        if receivedData[ip] == nil then
            table.insert(diff, self.networkState[ip]);
        end
    end

    return diff;
end

return utils;
