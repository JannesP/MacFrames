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

_p.Constants = {
    MinimapIconRegisterName = "MacFrames",
    HealthBarDefaultTextureName = "MacFrames Health Bar",
    PowerBarDefaultTextureName = "MacFrames Health Bar",
    PartyFrameGlobalName = "MacFramesParty",
    RaidFrameGlobalName = "MacFramesRaid",
    DefaultProfileMarker = "*",
    GroupSize = 5,
    RaidGroupCount = 8,
    TestModeFrameStrata = "MEDIUM",
    DefaultProfileName = "Default",
    TooltipBorderClearance = 6,
    UnitFrame = {
        MinHeight = 32,
        MinWidth = 70,
    },
    Settings = {
        EditorWidth = 130,
        EditorHeight = 42,
    }
};
local Constants = _p.Constants;