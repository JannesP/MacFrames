local ADDON_NAME, _p = ...;

_p.MyAuraUtil = {}
local MyAuraUtil = _p.MyAuraUtil;

do
    local function SpellIdPredicate(idToFind, _, _, ...)
        return select(10, ...) == idToFind;
    end
    function MyAuraUtil.FindBySpellId(unit, filter, spellId)
        return AuraUtil.FindAura(SpellIdPredicate, unit, filter, spellId);
    end
end

do
    local function AllUnitAuraSlotsRecurse(unit, filter, continuationToken, resultsTable)
       local slots = { UnitAuraSlots(unit, filter, nil, continuationToken) };
       --the continuationToken from UnitAuraSlots is at slots[1]
       for i=2,#slots do
          tinsert(resultsTable, slots[i]);
       end
       return slots[1]; 
    end
    
    function MyAuraUtil.AllUnitAuraSlots(unit, filter, resultsTable)
       if resultsTable == nil then
          resultsTable = {};
       end
       local continuationToken;
       repeat
          continuationToken = AllUnitAuraSlotsRecurse(unit, filter, continuationToken, resultsTable);
       until continuationToken == nil;
       return resultsTable;
    end
 end

function MyAuraUtil.IsBossAura(aura)
   return aura[12];
end