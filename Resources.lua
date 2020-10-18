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
local Constants = _p.Constants;
local LSM = LibStub("LibSharedMedia-3.0");

local Resources = {
    SB_HEALTH_FILL = "Interface\\AddOns\\MacFrames\\Media\\HealthBar-fill.tga",
    SB_HEALTH_BACKGROUND = "Interface\\AddOns\\MacFrames\\Media\\HealthBar-background.tga",

    BORDER_HEALTH_TARGET = "Interface\\AddOns\\MacFrames\\Media\\Border-target.tga",
    BORDER_HEALTH_AGGRO = "Interface\\AddOns\\MacFrames\\Media\\Border-aggro.tga",
}
_p.Resources = Resources;

LSM:Register("statusbar", Constants.HealthBarDefaultTextureName, Resources.SB_HEALTH_FILL);

LSM:Register("border", Constants.TargetBorderDefaultTextureName, Resources.BORDER_HEALTH_TARGET);
LSM:Register("border", Constants.AggroBorderDefaultTextureName, Resources.BORDER_HEALTH_AGGRO);