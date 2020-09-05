local ADDON_NAME, _p = ...;

_p.isDebugMode = true;
_p.isLoggingEnabled = _p.isDebugMode;
_p.versionNumber = 0;
_p.isRunningShadowlands = select(4, GetBuildInfo()) > 90000;

_p.PlayerInfo = {
    class = nil,
    specId = nil,
};

_p.L = setmetatable({}, {__index = function(L, key) return key; end});

_p.tprint = function(tbl, indent)
    if not indent then indent = 0 end
    local toprint = string.rep(" ", indent) .. "{\n";
    indent = indent + 2;
    for k, v in pairs(tbl) do
        toprint = toprint .. string.rep(" ", indent);
        if (type(k) == "number") then
            toprint = toprint .. "[" .. k .. "]: ";
        elseif (type(k) == "string") then
            toprint = toprint  .. k ..  ": ";  
        end
        if (type(v) == "number") then
            toprint = toprint .. v .. ",\n";
        elseif (type(v) == "boolean") then
            toprint = toprint .. tostring(v) .. ",\n";
        elseif (type(v) == "string") then
            toprint = toprint .. "\"" .. v .. "\",\n";
        elseif (type(v) == "table") then
            toprint = toprint .. _p.tprint(v, indent + 2) .. ",\n";
        else
            toprint = toprint .. "\"" .. tostring(v) .. "\",\n";
        end
    end
    toprint = toprint .. "}";
    return toprint;
end

_p.UserChatMessage = function(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg, 1, 1, 0, GetChatTypeIndex("SYSTEM"));
end

_p.Log = function(...)
    if (not _p.isLoggingEnabled) then return; end
    local msg = { ... };
    if (#msg == 1) then
        msg = msg[1];
    end
    local msgType = type(msg);
    if (msgType == "table") then
        print(_p.tprint(msg));
    else
        print(msg);
    end
    
end

_p.Log("Finished init.");