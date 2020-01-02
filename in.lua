local credentials = require('credentials');

function Startup()
    gossip = require('gossip');
    gossip.setConfig({seedList = {'192.168.0.157', '192.168.0.185'}, });
    gossip.start();
end

local wifi_got_ip_event = function(T)
    print("Wifi connection is ready! IP address is: " .. T.IP);
    Startup();
end

local wifi_disconnect_event = function(T)
    print('Wifi disconnected.');
end

wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, wifi_got_ip_event);
wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, wifi_disconnect_event);

print("Connecting to WiFi access point...");

if wifi.sta.getip()==nil then
wifi.setmode(wifi.STATION);
wifi.sta.config({ssid = credentials.SSID, pwd = credentials.PASSWORD});
else
    Startup();
end


