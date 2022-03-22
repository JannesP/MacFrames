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

_p.SpellCache = {};
local SpellCache = _p.SpellCache;

local GetSpellInfo = GetSpellInfo;
local debugprofilestop = debugprofilestop;

local _cache;
local _cacheLoadCoroutine;
local _loadCallbacks = {};

local _updateFrame = CreateFrame("Frame", nil);
_updateFrame:HookScript("OnUpdate", function(self, elapsed)
    if (_cacheLoadCoroutine == nil) then
        _updateFrame:StopProcessing();
    else
        --call the coroutine for 8ms each frame
        if (select(2, coroutine.resume(_cacheLoadCoroutine, debugprofilestop() + 8))) then
            for i=1,#_loadCallbacks do
                _loadCallbacks[i](_cache);
            end
            wipe(_loadCallbacks);
            _updateFrame:StopProcessing();
        end
    end
end);
function _updateFrame:StartProcessing()
    self:SetParent(UIParent);
    self:Show();
end
function _updateFrame:StopProcessing()
    self:Hide();
    self:SetParent(nil);
end

function SpellCache.Load(callback)
    if (_cache) then
        callback(_cache);
        return true;
    end
    _loadCallbacks[#_loadCallbacks + 1] = callback;
    _cacheLoadCoroutine = coroutine.create(function(firstYieldAt)
        local id = 0;
        local misses = 0;
        local nextYield = firstYieldAt;
        local cache = {};

        while misses < 400 do
            id = id + 1
            local name, _, icon = GetSpellInfo(id)

            if(icon == 136243) then -- 136243 is the a gear icon, we can ignore those spells
                misses = 0;
            elseif name and name ~= "" then
                cache[name] = cache[name] or {}
                cache[name].spells = cache[name].spells or {}
                cache[name].spells[id] = icon
                misses = 0
            else
                misses = misses + 1
            end
            if (nextYield < debugprofilestop()) then
                nextYield = coroutine.yield(false);
            end
        end
        _cache = cache;
        coroutine.yield(true);
    end)
    _updateFrame:StartProcessing();
    return false;
end