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


_p.RoleIndicator = {};
local RoleIndicator = _p.RoleIndicator;

local RoleIndicatorMixin = {};

local _indicatorType = "RoleIndicator";

local _settings = {
    iconSize = 5,
    hideIfNoRole = true,
};

function RoleIndicator.Create(unitFrame, alignTo, settings)
    local frame = UnitFrameIndicator.TryGetFrame(_indicatorType);
    if (not frame) then
        frame = CreateFrame("Frame", nil, nil);
        Mixin(frame, UnitFrameIndicatorMixin, RoleIndicatorMixin);

        frame.children = {};

        frame.children.icon = frame:CreateTexture(nil, "ARTWORK");
        frame.children.icon:SetAllPoints();

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
function RoleIndicatorMixin:GetIndicatorType()
    return _indicatorType;
end

function RoleIndicatorMixin:SetAlignTo(alignTo)
    UnitFrameIndicatorMixin.SetAlignTo(self, alignTo);
    self:Layout();
end

local _possibleRoles = { "TANK", "HEALER", "DAMAGER" };
function RoleIndicatorMixin:SetPreviewModeEnabled(enabled)
    UnitFrameIndicatorMixin.SetPreviewModeEnabled(self, enabled);
    if (enabled) then
        self:DisableEvents();

        local role = _possibleRoles[math.random(3)];
        self:SetIcon("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES", GetTexCoordsForRoleSmallCircle(role));
    else
        self:EnableEvents();
        self:UpdateAll();
    end
end

function RoleIndicatorMixin:Destroy()
    self:DisableEvents();
    UnitFrameIndicatorMixin.Destroy(self);
end

function RoleIndicatorMixin:GetRequestedSize()
    return (not self.isDisplayingIcon and self.settings.hideIfNoRole and 1) or self.settings.iconSize, self.settings.iconSize;
end

-- new type members
function RoleIndicatorMixin:OnEvent(event, arg1, arg2, arg3, ...)
    if (event == "PLAYER_FOCUS_CHANGED" or event == "PLAYER_TARGET_CHANGED") then
        self:UpdateAll();
    elseif (event == "PLAYER_ROLES_ASSIGNED") then
        self:UpdateRoleIcon();
    end
end

function RoleIndicatorMixin:EnableEvents()
    self.unitFrame:RegisterCallback(UnitFrame.Events.OnUnitChanged, self.OnUnitChanged, self);

    local unit = self.unitFrame.unit;
    if (unit == nil) then
        return;
    end
    self:SetScript("OnEvent", self.OnEvent);
    self:RegisterEvent("PLAYER_ROLES_ASSIGNED", unit);
    if (unit == "focus") then
        self:RegisterEvent("PLAYER_FOCUS_CHANGED");
    elseif (unit == "target") then
        self:RegisterEvent("PLAYER_TARGET_CHANGED");
    end
end

function RoleIndicatorMixin:DisableEvents()
    self.unitFrame:UnregisterCallback(UnitFrame.Events.OnUnitChanged, self);

    self:UnregisterAllEvents();
    self:SetScript("OnEvent", nil);
end

function RoleIndicatorMixin:OnUnitChanged()
    self:DisableEvents();
    self:EnableEvents();
    self:UpdateAll();
end

function RoleIndicatorMixin:UpdateRoleIcon()
    local raidID = UnitInRaid(self.unitFrame.unit);
    local role;
    if (raidID) then
        role = select(10, GetRaidRosterInfo(raidID));
    end
    if (UnitInVehicle(self.unitFrame.unit) and UnitHasVehicleUI(self.unitFrame.unit)) then
        self:SetIcon("Interface\\Vehicles\\UI-Vehicles-Raid-Icon", 0, 1, 0, 1);
    elseif (raidID and role) then
        self:SetIcon("Interface\\GroupFrame\\UI-Group-" .. role .. "Icon", 0, 1, 0, 1);
	else
		local role = UnitGroupRolesAssigned(self.unitFrame.unit);
		if (role == "TANK" or role == "HEALER" or role == "DAMAGER") then
            self:SetIcon("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES", GetTexCoordsForRoleSmallCircle(role));
        else
            self:SetIcon(nil);
		end
    end
end

function RoleIndicatorMixin:SetIcon(texture, ...)
    local isDisplayingIcon;
    if (not texture) then
        isDisplayingIcon = false;
    else
        isDisplayingIcon = true;
        self.children.icon:SetTexture(texture);
        self.children.icon:SetTexCoord(...);
    end
    if (isDisplayingIcon) then
        self.children.icon:Show();
    else
        self.children.icon:Hide();
    end
    if (isDisplayingIcon ~= self.isDisplayingIcon) then
        self.isDisplayingIcon = isDisplayingIcon;
        self:TriggerEvent(UnitFrameIndicator.Events.OnRequestedSizeChanged);
    end
end

function RoleIndicatorMixin:Layout()
    self.children.icon:SetAllPoints();
    
end

function RoleIndicatorMixin:UpdateAllSettings()
end

function RoleIndicatorMixin:UpdateAll()
    self:UpdateRoleIcon();
end

UnitFrameIndicator.RegisterIndicatorType(_indicatorType, L["Role"], RoleIndicator.Create);