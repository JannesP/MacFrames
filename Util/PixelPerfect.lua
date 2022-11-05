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

_p.PixelPerfect = {}
local PixelPerfect = _p.PixelPerfect;

local eventFrame = CreateFrame("Frame");
eventFrame:SetScript("OnEvent", function(_, event, cvar, _)
    if (event == "UI_SCALE_CHANGED") then
    end
end);
eventFrame:RegisterEvent("UI_SCALE_CHANGED");

---Sets the size respecting the pixel grid.
---@param region Frame | Region
---@param width number
---@param height number
function PixelPerfect.SetSize(region, width, height)
    height = height or width;
    region:SetSize(width, height);
end

---Sets the width respecting the pixel grid.
---@param region Frame | Region
---@param width number
function PixelPerfect.SetWidth(region, width)
    region:SetWidth(width);
end

---Sets the height respecting the pixel grid.
---@param region Frame | Region
---@param height number
function PixelPerfect.SetHeight(region, height)
    region:SetHeight(height);
end

---Sets the point respecting the pixel grid.
---@param region Frame | Region
function PixelPerfect.SetPoint(region, ...)
    region:SetPoint(...);
end