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

_p.AuraBlacklist = {
    --[600] = true,       --Exhaustion (Hero/BL/Drums Debuff)
    --[6788] = true,      --Weakened Soul
    --[206151] = true,    --Challenger's Burden
    --[319346] = true,    --Infinity's Toll

    --###### Hero/BL ######
    --[57724] = true,     --Sated
    --[57723] = true,     --Exhaustion

    --####### Toys ########
    --[188409] = true,    --Felflame Campfire
    --[195776] = true,    --Moonfeather Fever
}