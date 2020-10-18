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