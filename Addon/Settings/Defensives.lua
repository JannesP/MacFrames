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

_p.Defensives = {   --priority is the number to the right (higher is a higher priority)
    [111759] = 1,   --Levitate
    [121557] = 2,   --Angelic Feather
    --[17] = 3,       --PW: S

    --###### Externals #######
    [33206] = 1000,     --Pain Suppression
    [47788] = 1000,     --Guardian Spirit
    [102342] = 1000,    --Ironbark
    [6940] = 1000,      --Blessing of Sacrifice
    [1022] = 1000,      --Blessing of Protection
    [204018] = 1000,    --Blessing of Spellwarding
    [1044] = 1000,      --Blessing of Freedom
    [116849] = 1000,    --Life Cocoon
    

    --###### Personals #######
    [104773] = 100,     --Unending Resolve

    [108271] = 100,     --Astral Shift

    [19236] = 100,      --Desperate Prayer
    
    [225080] = 1,       --Ahnk (while dead)

    --######### AOE ##########
    [81782] = 3,        --PW: Barrier
    [98007] = 3,        --Spirit Link
    [201633] = 2,       --Earthen Wall Totem
    [207498] = 1,       --Ancestral Protection Totem
    [255234] = 1,       --APT Procc (while dead)
    [196718] = 1,       -- Darkness
    
    --####### Racials ########
    [65116] = 1,        --Stone Form(Racial)
};
