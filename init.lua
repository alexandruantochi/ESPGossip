local credentials = require('credentials');

function Startup()
    gossip = require('gossip');
    if (wifi.sta.getip() ~= '192.168.0.73') then
    gossip.setConfig({seedList = {'192.168.0.73'}, });
    end
    gossip.start();
end

local wifi_got_ip_event = function(T)
    print("Wifi connection is ready! IP address is: " .. T.IP);
    tmr.create():alarm(3000, tmr.ALARM_SINGLE, Startup);
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
print('Starting in 3 s...');
tmr.create():alarm(3000, tmr.ALARM_SINGLE, Startup);
end


