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
   local function AddUnitAuraSlots(resultsTable, ...)
      --the continuationToken from UnitAuraSlots is at select(1, ...) so we start at 2
      for i=2,select('#', ...) do
         resultsTable[#resultsTable + 1] = select(i, ...);
      end
      return select(1, ...); 
   end

   function MyAuraUtil.AllUnitAuraSlots(unit, filter, resultsTable)
      wipe(resultsTable);
      local continuationToken;
      repeat
         continuationToken = AddUnitAuraSlots(resultsTable, UnitAuraSlots(unit, filter, nil, continuationToken));
      until continuationToken == nil;
   end
end

function MyAuraUtil.IsBossAura(...)
   return select(12, ...);
end