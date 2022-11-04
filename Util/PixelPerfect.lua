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

local _multi = UIParent:GetScale();

local eventFrame = CreateFrame("Frame");
eventFrame:SetScript("OnEvent", function(_, event, cvar, _)
    if (event == "CVAR_UPDATE" and (cvar == "uiScale" or cvar == "useUiScale")) then
        _multi = UIParent:GetScale();
    end
end);
eventFrame:RegisterEvent("CVAR_UPDATE");

MacFramesPixelPerfectMixin = {};
function MacFramesPixelPerfectMixin:SetScaledWidth(width)
    self:SetWidth(width);
    --PixelUtil.SetWidth(self, _multi * width);
end

function MacFramesPixelPerfectMixin:SetScaledHeight(height)
    self:SetHeight(height);
    --PixelUtil.SetHeight(self, _multi * height);
end

function MacFramesPixelPerfectMixin:SetScaledSize(width, height)
    self:SetSize(width, height);
    --PixelUtil.SetSize(self, _multi * width, _multi * height);
end