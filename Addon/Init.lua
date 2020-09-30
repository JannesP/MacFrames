--[[
-- MacFrames - WoW Raid and Party Frames <https://github.com/JannesP/MacFrames>
--Copyright (C) 2020  Jannes Peters
--
--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU General Public License as published by
--the Free Software Foundation, either version 3 of the License, or
--(at your option) any later version.
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU General Public License for more details.
--
--You should have received a copy of the GNU General Public License
--along with this program.  If not, see <https://www.gnu.org/licenses/>.
--]]

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

_p.CreateError = function(technicalMessage, userMessage, traceback)
    local err = {};
    err.TechnicalMessage = technicalMessage;
    if (userMessage == nil) then
        err.UserMessage = technicalMessage;
    else
        err.UserMessage = userMessage;
    end
    if (traceback == true) then
        err.Traceback = debugstack();
    end
    return err;
end

_p.Log = function(...)
    if (not _p.isLoggingEnabled) then return; end
    local msg = { ... };
    if (#msg == 0) then
        print("nil");
        return;
    elseif (#msg == 1) then
        msg = msg[1];
    end
    local msgType = type(msg);
    if (msg == nil) then
        print("nil");
    elseif (msgType == "table") then
        print(_p.tprint(msg));
    else
        print(msg);
    end
    
end

_p.Log("Finished init.");