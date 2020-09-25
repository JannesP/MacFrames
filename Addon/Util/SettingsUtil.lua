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
local PlayerInfo = _p.PlayerInfo;
local ProfileManager = _p.ProfileManager;

local SettingsUtil = {
    GetSpecialClassDisplays = function()
        if (PlayerInfo.class == nil or PlayerInfo.specId == nil) then
            return nil;
        end
        local classDisplay = ProfileManager.GetCurrent().SpecialClassDisplays[PlayerInfo.class][PlayerInfo.specId];
        if (classDisplay ~= nil) then
            classDisplay = classDisplay:GetRawEntries();
        else
            classDisplay = nil;
        end
        return classDisplay;
    end,
};
_p.SettingsUtil = SettingsUtil;