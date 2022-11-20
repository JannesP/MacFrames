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
        frame.children.name:SetWordWrap(false);
        frame.children.name:SetShadowColor(0, 0, 0);
        frame.children.name:SetShadowOffset(1, -1);

        frame:HookScript("OnShow", function(self)
            self:EnableEvents();
            self:UpdateAllSettings();
            self:UpdateAll();
        end);

        frame:HookScript("OnHide", function(self)
            self:DisableEvents();
        end);
    end
    UnitFrameIndicatorMixin.Init(frame, unitFrame, alignTo);
    frame.settings = settings;

    frame:SetAlignTo(alignTo);

    frame:UpdateAllSettings();
    frame:UpdateAll();
    return frame;
end

-- UnitFrameIndicatorMixin overrides
function NameIndicatorMixin:GetIndicatorType()
    return _indicatorType;
end

function NameIndicatorMixin:SetAlignTo(alignTo)
    UnitFrameIndicatorMixin.SetAlignTo(self, alignTo);
    self:Layout();
end

function NameIndicatorMixin:SetPreviewModeEnabled(enabled)
    UnitFrameIndicatorMixin.SetPreviewModeEnabled(self, enabled);
    if (enabled) then
        self:DisableEvents();
        self:SetName(GetUnitName("player", self.settings.showServerName));
    else
        self:EnableEvents();
        self:UpdateAll();
    end
end

function NameIndicatorMixin:Destroy()
    self:DisableEvents();
    UnitFrameIndicatorMixin.Destroy(self);
end

function NameIndicatorMixin:GetRequestedSize()
    return self.children.name:GetUnboundedStringWidth(), self.children.name:GetLineHeight();
end

function UnitFrameIndicatorMixin:RequiresFullLength()
    return false;
end

-- new type members
function NameIndicatorMixin:OnEvent(event, arg1, arg2, arg3, ...)
    if (event == "PLAYER_FOCUS_CHANGED" or event == "PLAYER_TARGET_CHANGED") then
        self:UpdateAll();
    else
        local eventUnit = arg1;
        if (eventUnit ~= self.unitFrame.unit) then
            return;
        end
        if (event == "UNIT_NAME_UPDATE") then
            self:UpdateName();
        end
    end
end

function NameIndicatorMixin:EnableEvents()
    self.unitFrame:RegisterCallback(UnitFrame.Events.OnUnitChanged, self.OnUnitChanged, self);

    local unit = self.unitFrame.unit;
    if (unit == nil) then
        return;
    end
    self:SetScript("OnEvent", self.OnEvent);
    self:RegisterUnitEvent("UNIT_NAME_UPDATE", unit);
    if (unit == "focus") then
        self:RegisterEvent("PLAYER_FOCUS_CHANGED");
    elseif (unit == "target") then
        self:RegisterEvent("PLAYER_TARGET_CHANGED");
    end
end

function NameIndicatorMixin:DisableEvents()
    self.unitFrame:UnregisterCallback(UnitFrame.Events.OnUnitChanged, self);

    self:UnregisterAllEvents();
    self:SetScript("OnEvent", nil);
end

function NameIndicatorMixin:OnUnitChanged()
    self:DisableEvents();
    self:EnableEvents();
    self:UpdateAll();
end

function NameIndicatorMixin:Layout()
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

function NameIndicatorMixin:UpdateAllSettings()
    self:UpdateFontFromSettings();
end

function NameIndicatorMixin:UpdateAll()
    self:UpdateName();
    self:UpdateFontColor();
end

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