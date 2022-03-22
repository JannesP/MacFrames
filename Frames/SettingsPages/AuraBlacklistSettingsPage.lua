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

_p.AuraBlacklistSettingsPage = {};
local AuraBlacklistSettingsPage = _p.AuraBlacklistSettingsPage;

local L = _p.L;
local FrameUtil = _p.FrameUtil;

function AuraBlacklistSettingsPage.Create(parent)
    local frame = CreateFrame("Frame", nil, parent);
    frame.text = FrameUtil.CreateText(frame, L["AuraBlacklistEditor not yet implemented :("]);
    frame.text:SetPoint("CENTER", frame, "CENTER");
    frame:SetHeight(100);
    
    frame.RefreshFromProfile = _p.Noop;
    frame.Layout = _p.Noop;
    frame.IsChangingSettings = function () return false; end;
    return frame;
end
