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
local L = _p.L;

--weird name because I don't want to hide the default "Enum" object 
_p.MacEnum = {};
local MacEnum = _p.MacEnum;

function MacEnum.GetByValue(enum, value)
    for k, v in pairs(enum) do
        if (v == value) then
            return k;
        end
    end
    return nil;
end

MacEnum.Settings = {};
MacEnum.Settings.PetFramePosition = {
    Right = "right",
    Left = "left",
    Top = "top",
    Bottom = "bottom",
}

MacEnum.Settings.PetFramePartyAlignment = {
    Beginning = "beginning",
    Center = "center",
    End = "end",
    Compact = "compact",
}
