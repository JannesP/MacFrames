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

local _scaledUiToPixelMulti;

local function NearestPixelSize(uiUnits)
    if (uiUnits == 0 or _scaledUiToPixelMulti == 1) then
       return uiUnits;
    end
    
    local y = _scaledUiToPixelMulti;
    if (_scaledUiToPixelMulti > 1) then
       --if real pixels are "bigger" than ui units (screenSize / uiScale > physicalSize) tend to make items bigger
       y = -y;
    end
    if (uiUnits < 0) then
       --invert for positive units to keep the "rounding" behavior the same between negative and positive
       y = -y;
    end
    return uiUnits - uiUnits % y;
 end

local function CalculateScalingFactors()
    local _, physHeight = GetPhysicalScreenSize();
    local _uiToPixelMulti = 768 / physHeight;
    _scaledUiToPixelMulti = _uiToPixelMulti / UIParent:GetScale();

end

local eventFrame = CreateFrame("Frame");
eventFrame:SetScript("OnEvent", function(_, event, cvar, _)
    if (event == "UI_SCALE_CHANGED") then
        CalculateScalingFactors();
    end
end);
eventFrame:RegisterEvent("UI_SCALE_CHANGED");
CalculateScalingFactors();

---Sets the size respecting the pixel grid.
---@param region Frame | Region
---@param width number
---@param height number
function PixelPerfect.SetSize(region, width, height)
    height = height or width;
    region:SetSize(NearestPixelSize(width), NearestPixelSize(height));
end

---Sets the width respecting the pixel grid.
---@param region Frame | Region
---@param width number
function PixelPerfect.SetWidth(region, width)
    region:SetWidth(NearestPixelSize(width));
end

---Sets the height respecting the pixel grid.
---@param region Frame | Region
---@param height number
function PixelPerfect.SetHeight(region, height)
    region:SetHeight(NearestPixelSize(height));
end

---Sets the point respecting the pixel grid.
---@param region Frame | Region
function PixelPerfect.SetPoint(region, arg1, arg2, arg3, arg4, arg5, ...)
    if not arg2 then arg2 = region:GetParent() end

    if type(arg2)=='number' then arg2 = NearestPixelSize(arg2) end
	if type(arg3)=='number' then arg3 = NearestPixelSize(arg3) end
	if type(arg4)=='number' then arg4 = NearestPixelSize(arg4) end
	if type(arg5)=='number' then arg5 = NearestPixelSize(arg5) end

    region:SetPoint(arg1, arg2, arg3, arg4, arg5, ...);
end

function PixelPerfect.GetPixelSize()
    return _scaledUiToPixelMulti;
end