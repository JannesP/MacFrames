local ADDON_NAME, _p = ...;

local MyAuraUtil = _p.MyAuraUtil;
local DebuffBlacklist = _p.DebuffBlacklist;
local Defensives = _p.Defensives;

local AuraManager = {};
_p.AuraManager = AuraManager;

local _buffCache = {};
AuraManager._buffCache = _buffCache;
local _debuffCache = {};
AuraManager._debuffCache = _debuffCache;

function AuraManager.LoadUnitAuras(unit)
    AuraManager.LoadUnitBuffs(unit);
    AuraManager.LoadUnitDebuffs(unit);
end

function AuraManager.LoadUnitBuffs(unit)
    local buffCache = _buffCache[unit];
    if (buffCache == nil) then
        buffCache = {};
        _buffCache[unit] = buffCache;
    else
        wipe(buffCache);
    end
    local buffSlots = MyAuraUtil.AllUnitAuraSlots(unit, "HELPFUL");
    local playerBuffs = MyAuraUtil.AllUnitAuraSlots(unit, "HELPFUL|PLAYER");
    for _, slot in ipairs(buffSlots) do
        buffCache[slot] = {
            displayed = false,
            byPlayer = false,
        };
    end
    for _, slot in ipairs(playerBuffs) do
        buffCache[slot].byPlayer = true;
    end
end

function AuraManager.LoadUnitDebuffs(unit)
    local debuffCache = _debuffCache[unit];
    if (debuffCache == nil) then
        debuffCache = {};
        _debuffCache[unit] = debuffCache;
    else
        wipe(debuffCache);
    end

    local slots = MyAuraUtil.AllUnitAuraSlots(unit, "HARMFUL");
    local dispellableSlots = MyAuraUtil.AllUnitAuraSlots(unit, "HARMFUL|RAID");
    local playerSlots = MyAuraUtil.AllUnitAuraSlots(unit, "HARMFUL|PLAYER");
    
    for _, slot in ipairs(slots) do
        debuffCache[slot] = {
            dispellable = false,
            displayed = false,
            byPlayer = false,
        }
    end
    for _, slot in ipairs(dispellableSlots) do
        debuffCache[slot].dispellable = true;
    end
    for _, slot in ipairs(playerSlots) do
        debuffCache[slot].byPlayer = true;
    end
end

do
    local function GetAuraFromInfo(unit, slot, info)
        if info.aura == nil then
            info.aura = { UnitAuraBySlot(unit, slot) };
        end
        return info.aura;
    end

    local function GetAurasWithFilter(unit, count, resultList, filterFunc, cache)
        if (resultList == nil) then
            resultList = {};
        end
        for slot, info in pairs(cache) do
            local aura = GetAuraFromInfo(unit, slot, info);
            if (DebuffBlacklist[aura[10]] ~= true) then
                if filterFunc(slot, info) then
                    info.displayed = true;
                    tinsert(resultList, aura);
                    if (count ~= nil and #resultList == count) then
                        return resultList;
                    end
                end
            end
        end
        return resultList;
    end

    local function GetDebuffsWithFilter(unit, count, resultList, filterFunc)
        return GetAurasWithFilter(unit, count, resultList, filterFunc, _debuffCache[unit]);
    end

    local function GetBuffsWithFilter(unit, count, resultList, filterFunc)
        return GetAurasWithFilter(unit, count, resultList, filterFunc, _buffCache[unit]);
    end
    
    function AuraManager.GetDispellableDebuffs(unit, count, resultList)
        return GetDebuffsWithFilter(unit, count, resultList, function(slot, info)
            return info.dispellable and not info.displayed;
        end);
    end

    function AuraManager.GetUndispellableDebuffs(unit, count, resultList)
        return GetDebuffsWithFilter(unit, count, resultList, function(slot, info)
            return not info.dispellable and not info.displayed;
        end);
    end

    do
        local function BossAuraFilter(unit)
            return function (slot, info)
                if not info.displayed then
                    return MyAuraUtil.IsBossAura(GetAuraFromInfo(unit, slot, info));
                end
                return false;
            end
        end

        function AuraManager.GetBossAuras(unit, count, resultList)
            resultList = GetDebuffsWithFilter(unit, count, resultList, BossAuraFilter(unit));
            if (#resultList < count) then
                GetBuffsWithFilter(unit, count, resultList, BossAuraFilter(unit));
            end
            return resultList;
        end
    end

    local function PlayerAuraIdFilter(unit, auraId, byPlayer)
        return function(slot, info)
            if (byPlayer == true and not info.byPlayer) then
                return false;
            end
            if (info.displayed) then
                return false;
            end
            local aura = GetAuraFromInfo(unit, slot, info);
            return aura[10] == auraId;
        end
        
    end

    function AuraManager.GetPlayerBuffByAuraId(unit, auraId, byPlayer)
        return GetBuffsWithFilter(unit, 1, nil, PlayerAuraIdFilter(unit, auraId, byPlayer))[1];
    end

    function AuraManager.GetPlayerDebuffByAuraId(unit, auraId, byPlayer)
        return GetDebuffsWithFilter(unit, 1, nil, PlayerAuraIdFilter(unit, auraId, byPlayer))[1];
    end

    function AuraManager.GetDefensiveBuffs(unit, count)
        local buffs = GetBuffsWithFilter(unit, nil, nil, function (slot, info)
            return not info.displayed;
        end);
        
        local foundBuffs = {};
        for _, aura in ipairs(buffs) do
            local defensiveEntry = Defensives[aura[10]];
            if (defensiveEntry ~= nil) then
                tinsert(foundBuffs, { aura = aura, priority = defensiveEntry });
            end
        end
        
        table.sort(foundBuffs, function(a, b) return a.priority > b.priority end);
        local results = {};
        for i=1,count do
            if i > #foundBuffs then
                return results;
            else 
                tinsert(results, foundBuffs[i].aura);
            end
        end
        return results;
    end
end