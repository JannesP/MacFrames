--[[
-- MacFrames - WoW Raid and Party Frames <https://github.com/JannesP/MacFrames>
--Copyright (C) 2022  Jannes Peters
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

_p.isDevMode = false;
--@do-not-package@
_p.isDevMode = true;
MF = _p;
--@end-do-not-package@

_p.Noop = function() end;

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

_p.Print = function(...)
    print(...);
end

_p.Log = function(...)
    if (not _p.isDevMode) then return; end
    
    local count = select('#', ...);
    if (count == 0) then
        _p.Print("nil");
        return;
    elseif (count == 1) then
        local msg = select(1, ...);
        local msgType = type(msg);
        if (msg == nil) then
            _p.Print("nil");
        elseif (msgType == "table") then
            local msg = { ... };
            _p.Print(_p.tprint(msg));
        else
            _p.Print(msg);
        end
    else
        _p.Print(...);
    end
end

_p.PrintCurrentTocVersion = function() 
    return _p.Log(select(4, GetBuildInfo()));
end

--from https://wow.gamepedia.com/ItemLink
--return values: startIndex, endIndex, Color, linkType, Id, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, reforging, Name
_p.ParseLink = function(link)
    return string.find(link, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?");
end

_p.isDragonflight = select(4, GetBuildInfo()) >= 100000;

_p.Log("Finished init.");