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

utils.setConfig = function(self, userConfig)
    for k, v in pairs(userConfig) do
        if (self.config[k] ~= nil and type(self.config[k]) == type(v)) then
            self:logVerbose('Setting ' .. k);
            self.config[k] = v;
        end
    end
end

return utils;
