local state = {};

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

state.start = function(self)
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

state.updateHeartbeat = function(self)
    self.state.heartbeat = tmr.time();
end