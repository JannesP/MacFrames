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
local UnitFrameIndicatorMixin = _p.UnitFrameIndicatorMixin;
local UnitFrameIndicator = _p.UnitFrameIndicator;
local SettingsUtil = _p.SettingsUtil;
local UnitFrame = _p.UnitFrame;
local PixelPerfect = _p.PixelPerfect;


_p.NameIndicator = {};
local NameIndicator = _p.NameIndicator;

local NameIndicatorMixin = {};

local _indicatorType = "NameIndicator";

local _settings = {
    showServerName = false,
    fontUseClassColor = false,
    fontManualColor = { r = 1, g = 1, b = 1 },
    fontName = "",
    fontSize = 1,
};

function NameIndicator.Create(unitFrame, alignTo, settings)
    local frame = UnitFrameIndicator.TryGetFrame(_indicatorType);
    if (not frame) then
        frame = CreateFrame("Frame", nil, nil);
        Mixin(frame, UnitFrameIndicatorMixin, NameIndicatorMixin);

        frame.children = {};

        frame.children.name = frame:CreateFontString(nil, "ARTWORK");
        frame.children.name:SetMaxLines(1);
---@diagnostic disable-next-line: redundant-parameter
        frame.children.name:SetWordWrap(false);
        frame.children.name:SetShadowColor(0, 0, 0);
        frame.children.name:SetShadowOffset(1, -1);
    end
    UnitFrameIndicatorMixin.Init(frame, unitFrame, alignTo, settings);
    return frame;
end

-- UnitFrameIndicatorMixin overrides
function NameIndicatorMixin:GetIndicatorType()
    return _indicatorType;
end

function NameIndicatorMixin:SetPreviewModeEnabled(enabled)
    UnitFrameIndicatorMixin.SetPreviewModeEnabled(self, enabled);
    if (not enabled) then return; end

    self:SetName(GetUnitName("player", self.settings.showServerName));
end

function NameIndicatorMixin:GetRequestedSize()
    return self.children.name:GetUnboundedStringWidth(), self.children.name:GetLineHeight();
end

function NameIndicatorMixin:UpdateAllSettings()
    UnitFrameIndicatorMixin.UpdateAllSettings(self);

    self:UpdateFontFromSettings();
end

function NameIndicatorMixin:UpdateAll()
    UnitFrameIndicatorMixin.UpdateAll(self);

    self:UpdateName();
    self:UpdateFontColor();
end

function NameIndicatorMixin:EnableEvents()
    local unit = UnitFrameIndicatorMixin.EnableEvents(self);
    if (unit == nil) then return; end

    self:RegisterUnitEvent("UNIT_NAME_UPDATE", unit);
end

function NameIndicatorMixin:OnEvent(event, arg1, arg2, arg3, ...)
    if (UnitFrameIndicatorMixin.OnEvent(self, event, arg1, arg2, arg3, ...)) then return; end
    
    local eventUnit = arg1;
    if (eventUnit ~= self.unitFrame.unit) then
        return;
    end
    if (event == "UNIT_NAME_UPDATE") then
        self:UpdateName();
        self:UpdateFontColor();
    end
end

function NameIndicatorMixin:Layout()
    UnitFrameIndicatorMixin.Layout(self);

    self.children.name:ClearAllPoints();
    local alignTo = self.alignTo;
    self.children.name:SetAllPoints();
    if (alignTo == "LEFT" or alignTo == "BOTTOMLEFT" or alignTo == "TOPLEFT") then
        self.children.name:SetJustifyH("LEFT");
    elseif (alignTo == "RIGHT" or alignTo == "BOTTOMRIGHT" or alignTo == "TOPRIGHT") then
        self.children.name:SetJustifyH("RIGHT");
    else
        self.children.name:SetJustifyH("CENTER");
    end

    if (alignTo == "TOPLEFT" or alignTo == "TOP" or alignTo == "TOPRIGHT") then
        self.children.name:SetJustifyV("TOP");
    elseif (alignTo == "BOTTOMLEFT" or alignTo == "BOTTOM" or alignTo == "BOTTOMRIGHT") then
        self.children.name:SetJustifyV("BOTTOM");
    else
        self.children.name:SetJustifyV("MIDDLE");
    end
end

-- new type members

function NameIndicatorMixin:UpdateName()
    self:SetName(GetUnitName(self.unitFrame.unit, self.settings.showServerName));
end

function NameIndicatorMixin:SetName(name)
    self.children.name:SetText(name);
    self:TriggerEvent(UnitFrameIndicator.Events.OnRequestedSizeChanged);
end

function NameIndicatorMixin:UpdateFontColor()
    local r, g, b;
    if (self.settings.fontUseClassColor) then
        if (not UnitIsConnected(self.unitFrame.unit)) then
            r, g, b = 1, 1, 1;
        else
            local classFileName = select(2, UnitClass(self.unitFrame.unit));
            r, g, b = UnitFrame.CalculateUnitClassColor(self.unitFrame, UnitIsPlayer(self.unitFrame.unit), classFileName);
        end
    else
        r, g, b = SettingsUtil.UnpackRGB(self.settings.fontManualColor);
    end
    self.children.name:SetTextColor(r, g, b, 1);
end

function NameIndicatorMixin:UpdateFontFromSettings()
    local fontPath, usedLsmName, changed = SettingsUtil.GetFontFromName(self.settings.fontName);
    if (changed) then
        self.settings.fontName = usedLsmName;
    end
    self.children.name:SetFont(fontPath, self.settings.fontSize);
    self:TriggerEvent(UnitFrameIndicator.Events.OnRequestedSizeChanged);
end


UnitFrameIndicator.RegisterIndicatorType(_indicatorType, L["Name"], NameIndicator.Create);