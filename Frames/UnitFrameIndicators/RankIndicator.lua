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


_p.RankIndicator = {};
local RankIndicator = _p.RankIndicator;

local RankIndicatorMixin = {};

local _indicatorType = "RankIndicator";

local _settings = {
    iconSize = 5,
    hideIfNoRole = true,
};

function RankIndicator.Create(unitFrame, alignTo, settings)
    local frame = UnitFrameIndicator.TryGetFrame(_indicatorType);
    if (not frame) then
        frame = CreateFrame("Frame", nil, nil);
        Mixin(frame, UnitFrameIndicatorMixin, RankIndicatorMixin);

        frame.children = {};

        frame.children.icon = frame:CreateTexture(nil, "ARTWORK");
        frame.children.icon:SetAllPoints();
    end
    UnitFrameIndicatorMixin.Init(frame, unitFrame, alignTo, settings);
    return frame;
end

-- UnitFrameIndicatorMixin overrides
function RankIndicatorMixin:GetIndicatorType()
    return _indicatorType;
end

function RankIndicatorMixin:SetPreviewModeEnabled(enabled)
    UnitFrameIndicatorMixin.SetPreviewModeEnabled(self, enabled);
    if (not enabled) then return; end

    local isLeader = math.random(2) == 1;
    if (isLeader) then
        self:SetIcon("Interface\\GroupFrame\\UI-Group-LeaderIcon", 0, 1, 0, 1);
    else
        self:SetIcon(nil);
    end
end

function RankIndicatorMixin:GetRequestedSize()
    return (not self.isDisplayingIcon and self.settings.hideIfNoRole and 1) or self.settings.iconSize, self.settings.iconSize;
end

function RankIndicatorMixin:UpdateAll()
    UnitFrameIndicatorMixin.UpdateAll(self);

    self:UpdateRankIcon();
end

function RankIndicatorMixin:EnableEvents()
    local unit = UnitFrameIndicatorMixin.EnableEvents(self);
    if (unit == nil) then return; end
    
    self:RegisterEvent("PLAYER_ROLES_ASSIGNED");
    self:RegisterEvent("PARTY_LEADER_CHANGED");
end

function RankIndicatorMixin:OnEvent(event, arg1, arg2, arg3, ...)
    if (UnitFrameIndicatorMixin.OnEvent(self, event, arg1, arg2, arg3, ...)) then return; end
    if (event == "PLAYER_ROLES_ASSIGNED" or event == "PARTY_LEADER_CHANGED") then
        self:UpdateRankIcon();
    end
end

function RankIndicatorMixin:Layout()
    UnitFrameIndicatorMixin.Layout(self);

    self.children.icon:SetAllPoints();
end

-- new type members

function RankIndicatorMixin:UpdateRankIcon()
    local raidID = UnitInRaid(self.unitFrame.unit);
    local _, rank;
    if (raidID) then
        _, rank = GetRaidRosterInfo(raidID);
    end
    if (raidID and rank > 0) then
        if (rank == 1) then
            self:SetIcon("Interface\\GroupFrame\\UI-Group-AssistantIcon", 0, 1, 0, 1);
        elseif (rank == 2) then
            self:SetIcon("Interface\\GroupFrame\\UI-Group-LeaderIcon", 0, 1, 0, 1);
        else
            error("Rank evaluated 'true' but not 1 or 2!");
        end
    else
        if (UnitIsGroupLeader(self.unitFrame.unit)) then
            self:SetIcon("Interface\\GroupFrame\\UI-Group-LeaderIcon", 0, 1, 0, 1);
        else
            self:SetIcon(nil);
        end
    end
end

function RankIndicatorMixin:SetIcon(texture, ...)
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

UnitFrameIndicator.RegisterIndicatorType(_indicatorType, L["Rank"], RankIndicator.Create);