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

local MyAuraUtil = _p.MyAuraUtil;
local AuraBlacklist = _p.AuraBlacklist;
local Defensives = _p.Defensives;
local TablePool = _p.TablePool;

--imported globals
local UnitAuraBySlot = UnitAuraBySlot;
--imported own
local MyAuraUtil_IsBossAura = MyAuraUtil.IsBossAura;
local MyAuraUtil_AllUnitAuraSlots = MyAuraUtil.AllUnitAuraSlots;

local AuraManager = {};
_p.AuraManager = AuraManager;

local _auraInfoCache = TablePool.Create(function (table)
    table.dispellable = false;
    table.displayed = false;
    table.byPlayer = false;
    table.isDebuff = false;
end);
--[[
    _buffCache = {
        "player" = {
            [slot1] = {
                dispellable = false;
                displayed = false;
                byPlayer = false;
            },
            [slot2] = {
                dispellable = false;
                displayed = false;
                byPlayer = false;
            },
        },
        "party1" = {

        },
    }
]]
local _buffCache = {};
AuraManager._buffCache = _buffCache;
local _debuffCache = {};
AuraManager._debuffCache = _debuffCache;

local function GetClearedUnitCache(unit, cache)
    local result = cache[unit];
    if (result == nil) then
        result = {};
        cache[unit] = result;
    else
        for k, auraInfo in pairs(result) do
            _auraInfoCache:Put(auraInfo);
            result[k] = nil;
        end
    end
    return result;
end

local _slotCache = {};

function AuraManager.LoadUnitAuras(unit)
    AuraManager.LoadUnitBuffs(unit);
    AuraManager.LoadUnitDebuffs(unit);
end

function AuraManager.LoadUnitBuffs(unit)
    local buffCache = GetClearedUnitCache(unit, _buffCache);
    
    MyAuraUtil_AllUnitAuraSlots(unit, "HELPFUL", _slotCache);
    for i=1, #_slotCache do
        buffCache[_slotCache[i]] = _auraInfoCache:Take();
    end

    MyAuraUtil_AllUnitAuraSlots(unit, "HELPFUL|PLAYER", _slotCache);
    for i=1, #_slotCache do
        buffCache[_slotCache[i]].byPlayer = true;
    end
end

function AuraManager.LoadUnitDebuffs(unit)
    local debuffCache = GetClearedUnitCache(unit, _debuffCache);

    MyAuraUtil_AllUnitAuraSlots(unit, "HARMFUL", _slotCache);
    for i=1, #_slotCache do
        local debuffInfo = _auraInfoCache:Take();
        debuffInfo.isDebuff = true;
        debuffCache[_slotCache[i]] = debuffInfo;
    end

    MyAuraUtil_AllUnitAuraSlots(unit, "HARMFUL|RAID", _slotCache);
    for i=1, #_slotCache do
        debuffCache[_slotCache[i]].dispellable = true;
    end

    MyAuraUtil_AllUnitAuraSlots(unit, "HARMFUL|PLAYER", _slotCache);
    for i=1, #_slotCache do
        debuffCache[_slotCache[i]].byPlayer = true;
    end
end

do
    local function ForEachAura(unit, slotCache, func)
        if (slotCache ~= nil) then
            for slot, info in pairs(slotCache) do
                if (func(slot, info, UnitAuraBySlot(unit, slot))) then
                    return;
                end
            end
        end
    end

    local function ForAllDebuffs(unit, func)
        ForEachAura(unit, _debuffCache[unit], func);
    end
    AuraManager.ForAllDebuffs = ForAllDebuffs;

    local function ForAllBuffs(unit, func)
        ForEachAura(unit, _buffCache[unit], func);
    end
    AuraManager.ForAllBuffs = ForAllBuffs;
    
    do
        local p_unit, p_func;
        local function ForAllDispellableDebuffsIterator(slot, info, ...)
            if (info.dispellable) then
                return p_func(slot, info, ...);
            else
                return false;
            end
        end
        function AuraManager.ForAllDispellableDebuffs(unit, func)
            p_unit, p_func = unit, func;
            ForAllDebuffs(unit, ForAllDispellableDebuffsIterator);
        end
    end

    do
        local p_unit, p_func;
        local function ForAllUndispellableDebuffsIterator(slot, info, ...)
            if (not info.dispellable) then
                return p_func(slot, info, ...);
            else
                return false;
            end
        end
        function AuraManager.ForAllUndispellableDebuffs(unit, func)
            p_unit, p_func = unit, func;
            ForAllDebuffs(unit, ForAllUndispellableDebuffsIterator);
        end
    end

    do
        local p_unit, p_func;
        local cancelIteration;
        local function ForAllBossAuraIterator(slot, info, ...)
            if (MyAuraUtil_IsBossAura(...)) then
                cancelIteration = p_func(slot, info, ...);
                return cancelIteration;
            else
                return false;
            end
        end
        function AuraManager.ForAllBossAuras(unit, func)
            p_unit, p_func = unit, func;
            cancelIteration = false;
            ForAllDebuffs(unit, ForAllBossAuraIterator);
            if (not cancelIteration) then
                ForAllBuffs(unit, ForAllBossAuraIterator);
            end
        end
    end

    do
        local p_unit, p_auraId, p_func;
        local function ForAllBuffsIterator(slot, info, ...)
            if ((select(10, ...)) == p_auraId) then
                return p_func(slot, info, ...);
            else
                return false;
            end
        end
        function AuraManager.ForAllBuffsByAuraId(unit, auraId, func)
            p_unit, p_auraId, p_func = unit, auraId, func;
            ForAllBuffs(unit, ForAllBuffsIterator);
        end
    end

    do
        local p_unit, p_auraId, p_func;
        local function ForAllDebuffsIterator(slot, info, ...)
            if ((select(10, ...)) == p_auraId) then
                return p_func(slot, info, ...);
            else
                return false;
            end
        end
        function AuraManager.ForAllDebuffsByAuraId(unit, auraId, func)
            p_unit, p_auraId, p_func = unit, auraId, func;
            ForAllDebuffs(unit, ForAllDebuffsIterator);
        end
    end
    do
        local p_unit, p_func;
        local function ForAllDefensiveBuffsIterator(slot, info, ...)
            local priority = Defensives[(select(10, ...))];
            if (priority ~= nil) then
                return p_func(slot, info, priority, ...);
            else
                return false;
            end
        end
        function AuraManager.ForAllDefensiveBuffs(unit, func)
            p_unit, p_func = unit, func;
            ForAllBuffs(unit, ForAllDefensiveBuffsIterator);
        end
    end
end