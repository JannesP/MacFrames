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

local Constants = _p.Constants;
local Resources = _p.Resources;
local UnitFrame = _p.UnitFrame;
local FrameUtil = _p.FrameUtil;
local ProfileManager = _p.ProfileManager;
local BlizzardFrameUtil = _p.BlizzardFrameUtil;
local MacEnum = _p.MacEnum;

_p.RaidFrame = {};
local RaidFrame = _p.RaidFrame;

local _raidSettings = nil;
local _frame = nil;
local _groupFrames = nil;
local _unitFrames = nil;
local _groupChangedInCombat = false;
local _changingSettings = false;
local _disabledBlizzardFrames = false;
local _forcedVisibility = nil;

local function RaidSettings_PropertyChanged(key)
    if (_changingSettings == true or _frame == nil) then return; end
    if (key == "FrameStrata") then
        _frame:SetFrameStrata(_raidSettings.FrameStrata);
    elseif (key == "FrameLevel") then
        _frame:SetFrameLevel(_raidSettings.FrameLevel);
    elseif (key == "Enabled") then
        _frame.enabled = _raidSettings.Enabled;
    elseif (key == "DisableBlizzardFrames") then
        RaidFrame.SetDisableBlizzardFrame(_raidSettings.DisableBlizzardFrames);
    else
        RaidFrame.UpdateRect(_frame);
        RaidFrame.ProcessLayout(_frame);
    end
end

local function RaidSettings_AnchorInfo_PropertyChanged(key)
    if (_changingSettings == true or _frame == nil) then return; end
    RaidFrame.UpdateRect(_frame);
    RaidFrame.ProcessLayout(_frame);
end

ProfileManager.RegisterProfileChangedListener(function(newProfile)
    if (_raidSettings ~= nil) then
        _raidSettings:UnregisterPropertyChanged(RaidSettings_PropertyChanged);
        _raidSettings.AnchorInfo:UnregisterPropertyChanged(RaidSettings_AnchorInfo_PropertyChanged);
    end
    _raidSettings = newProfile.RaidFrame;
    _raidSettings:RegisterPropertyChanged(RaidSettings_PropertyChanged);
    _raidSettings.AnchorInfo:RegisterPropertyChanged(RaidSettings_AnchorInfo_PropertyChanged);
    if (_frame ~= nil) then
        RaidFrame.UpdateRect(_frame);
        RaidFrame.ProcessLayout(_frame);
        for i=1, #_unitFrames do
            UnitFrame.SetSettings(_unitFrames[i], _raidSettings);
        end
    end
    RaidFrame.SetDisableBlizzardFrame(_raidSettings.DisableBlizzardFrames);
end);

function RaidFrame.SetDisableBlizzardFrame(disable)
    if (_disabledBlizzardFrames == true) then
        if (disable == false) then
            _p.PopupDisplays.ShowSettingsUiReloadRequired();
        end
    else
        if (disable == true) then
            if (InCombatLockdown()) then error(L["Cannot disable blizzard frames in combat."]); end;
            _disabledBlizzardFrames = true;
            BlizzardFrameUtil.DisableCompactUnitFrames();
        end
    end
end

do
    local onSizeChangedSpacing, onSizeChangedMargin;
    local function Frame_OnSizeChanged(self, width, height)
        _changingSettings = true;
        _raidSettings.FrameWidth = (width - ((Constants.GroupSize - 1) * onSizeChangedSpacing) - (2 * onSizeChangedMargin)) / Constants.GroupSize;
        _raidSettings.FrameHeight = (height - ((Constants.RaidGroupCount - 1) * onSizeChangedSpacing) - (2 * onSizeChangedMargin)) / Constants.RaidGroupCount;
        _changingSettings = false;
        RaidFrame.ProcessLayout(self);
    end
    function RaidFrame.create()
        if _frame ~= nil then error("You can only create a single RaidFrame.") end
        local frameName = Constants.RaidFrameGlobalName;
        _frame = CreateFrame("Frame", frameName, UIParent, "SecureHandlerStateTemplate");
        _frame:SetFrameStrata(_raidSettings.FrameStrata);
        _frame:SetFrameLevel(_raidSettings.FrameLevel);

        _frame.dragDropHost = FrameUtil.CreateDragDropOverlay(_frame, function(dragDropHost, frame)
            RaidFrame.UpdateAnchorFromCurrentPosition(frame);
            RaidFrame.UpdateRect(frame);
            RaidFrame.ProcessLayout(frame);
        end, false);

        FrameUtil.AddResizer(_frame.dragDropHost, _frame, 
            function(dragDropHost, frame)   --resizeStart
                onSizeChangedSpacing = _raidSettings.FrameSpacing;
                onSizeChangedMargin = _raidSettings.Margin;
                _frame:SetScript("OnSizeChanged", Frame_OnSizeChanged);
            end, 
            function(dragDropHost, frame)   --resizeEnd
---@diagnostic disable-next-line: param-type-mismatch
                _frame:SetScript("OnSizeChanged", nil);
                RaidFrame.UpdateAnchorFromCurrentPosition(frame);
                RaidFrame.UpdateRect(frame);
                RaidFrame.ProcessLayout(frame);
            end
        );

        _groupFrames = {};
        for i=1,8 do
            _groupFrames[i] = CreateFrame("Frame", frameName .. "Group" .. i, _frame);
            _groupFrames[i].attachedFrames = {};
        end
        _frame.groups = _groupFrames;
        _unitFrames = {};
        for i=1,40 do
            tinsert(_unitFrames, UnitFrame.new("raid" .. i, _frame, nil, _raidSettings));
        end

        RaidFrame.UpdateRect(_frame);
        RaidFrame.ProcessLayout(_frame);
        RaidFrame.SetForcedVisibility(_forcedVisibility);
        RaidFrame.SetupEvents(_frame);
        return _frame;
    end
end

function RaidFrame.UpdateAnchorFromCurrentPosition(self)
    local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint(1);
    _changingSettings = true;
    _raidSettings.AnchorInfo.OffsetX = xOfs;
    _raidSettings.AnchorInfo.OffsetY = yOfs;
    _raidSettings.AnchorInfo.AnchorPoint = point;
    _changingSettings = false;
end

function RaidFrame.GetAllUnitFrames()
    return _unitFrames;
end

function RaidFrame.SetTestMode(enabled)
    if (enabled == true) then
        UnregisterAttributeDriver(_frame, "state-visibility");
        _frame:Show();
        for i=1, #_groupFrames do
            _groupFrames[i]:Show();
        end
    else
        RaidFrame.SetForcedVisibility(_forcedVisibility);
    end
    RaidFrame.SetChildTestModes(enabled);
end

function RaidFrame.SetForcedVisibility(visible)
    if (visible == true) then
        UnregisterAttributeDriver(_frame, "state-visibility");
        _frame:Show();
    elseif (visible == false) then
        UnregisterAttributeDriver(_frame, "state-visibility");
        _frame:Hide();
    else
        RegisterAttributeDriver(_frame, "state-visibility", _raidSettings.StateDriverVisibility);
    end
    _forcedVisibility = visible;
end

function RaidFrame.SetMovable(movable)
    if (movable) then
        RaidFrame.SetTestMode(true);
        _frame:SetFrameStrata(Constants.TestModeFrameStrata);
        _frame.dragDropHost:Show();
    else
        RaidFrame.SetTestMode(false);
        _frame:SetFrameStrata(_raidSettings.FrameStrata);
        _frame.dragDropHost:Hide();
    end
end

function RaidFrame.SetDisabled(disabled)
    if (disabled) then
        UnregisterAttributeDriver(_frame, "state-visibility");
        _frame:Hide();
    else
        RegisterAttributeDriver(_frame, "state-visibility", _raidSettings.StateDriverVisibility);
    end
end

function RaidFrame.SetChildTestModes(enabled)
    for i=1, #_unitFrames do
        UnitFrame.SetTestMode(_unitFrames[i], enabled);
    end
end

function RaidFrame.SetupEvents(self)
    self:SetScript("OnEvent", RaidFrame.OnEvent);

    self:RegisterEvent("PLAYER_REGEN_ENABLED");
    self:RegisterEvent("PLAYER_REGEN_DISABLED");
    self:RegisterEvent("GROUP_ROSTER_UPDATE");
    self:RegisterEvent("PLAYER_ROLES_ASSIGNED");
end

do
    local function QueueLayoutUpdate(self)
        if InCombatLockdown() then
            _groupChangedInCombat = true;
        else
            RaidFrame.ProcessLayout(self);
        end
    end

    function RaidFrame.OnEvent(self, event, ...)
        if event == "PLAYER_REGEN_DISABLED" then
            RaidFrame.EnteringCombat(self);
        elseif event == "PLAYER_REGEN_ENABLED" then
            RaidFrame.LeavingCombat(self);
        elseif event == "PLAYER_ROLES_ASSIGNED" then
            if (_raidSettings.RoleSortingOrder ~= MacEnum.Settings.RoleSortingOrder.Disabled) then
                QueueLayoutUpdate(self);
            end
        elseif event == "GROUP_ROSTER_UPDATE" then
            QueueLayoutUpdate(self);
        end
    end
end

function RaidFrame.EnteringCombat(self)
    RaidFrame.HideGroupsForContent(self);
end

function RaidFrame.LeavingCombat(self)
    if _groupChangedInCombat then
        _groupChangedInCombat = false;
        RaidFrame.ProcessLayout(self);
    end
    RaidFrame.ShowAllGroups(self);
end

function RaidFrame.HideGroupsForContent(self)
    if (_raidSettings.HideUnnecessaryGroupsInCombat) then
        local _, _, difficultyId = GetInstanceInfo();
        local groupNumberToShow = Constants.RaidGroupCount;
        --https://wow.gamepedia.com/DifficultyID
        if (difficultyId == 14) then        --normal
            groupNumberToShow = 6;
        elseif (difficultyId == 15) then    --heroic
            groupNumberToShow = 6;
        elseif (difficultyId == 16) then    --mythic
            groupNumberToShow = 4;
        end

        for i=groupNumberToShow + 1,#_groupFrames do
            _groupFrames[i]:Hide();
        end
    end
end

function RaidFrame.ShowAllGroups(self)
    for i=1, #_groupFrames do
        _groupFrames[i]:Show();
    end
end

function RaidFrame.UpdateRect(self)
    local frameWidth = _raidSettings.FrameWidth;
    local frameHeight = _raidSettings.FrameHeight;
    local spacing = _raidSettings.FrameSpacing;
    local margin = _raidSettings.Margin;
    local totalWidth, totalHeight;
    if (_raidSettings.Vertical) then
        totalHeight = (Constants.GroupSize * frameHeight) + ((Constants.GroupSize - 1) * spacing) + (2 * margin);
        totalWidth = (Constants.RaidGroupCount * frameWidth) + ((Constants.RaidGroupCount - 1) * spacing) + (2 * margin);
    else
        totalHeight = (Constants.GroupSize * frameWidth) + ((Constants.GroupSize - 1) * spacing) + (2 * margin);
        totalWidth = (Constants.RaidGroupCount * frameHeight) + ((Constants.RaidGroupCount - 1) * spacing) + (2 * margin);
    end
    local anchorInfo = _raidSettings.AnchorInfo;

    local minUfWidth, minUfHeight = Constants.UnitFrame.MinWidth, Constants.UnitFrame.MinHeight;
    local minWidth, minHeight;
    if (_raidSettings.Vertical) then
        minHeight = (Constants.GroupSize * minUfHeight) + ((Constants.GroupSize - 1) * spacing) + (2 * margin);
        minWidth = (Constants.RaidGroupCount * minUfWidth) + ((Constants.RaidGroupCount - 1) * spacing) + (2 * margin);
    else
        minHeight = (Constants.GroupSize * minUfWidth) + ((Constants.GroupSize - 1) * spacing) + (2 * margin);
        minWidth = (Constants.RaidGroupCount * minUfHeight) + ((Constants.RaidGroupCount - 1) * spacing) + (2 * margin);
    end
    
    
    if (_p.isDragonflight) then
        self:SetResizeBounds(PixelUtil.GetNearestPixelSize(minWidth, self:GetParent():GetEffectiveScale()), 
            PixelUtil.GetNearestPixelSize(minHeight, self:GetParent():GetEffectiveScale()));
    else
        self:SetMinResize(PixelUtil.GetNearestPixelSize(minWidth, self:GetParent():GetEffectiveScale()), 
            PixelUtil.GetNearestPixelSize(minHeight, self:GetParent():GetEffectiveScale()));
    end

    self:ClearAllPoints();
    PixelUtil.SetPoint(self, anchorInfo.AnchorPoint, UIParent, anchorInfo.AnchorPoint, anchorInfo.OffsetX, anchorInfo.OffsetY);
    PixelUtil.SetSize(self, totalWidth, totalHeight);
end

do
    local _roleCache = {
        TANK = {}, 
        HEALER = {}, 
        DAMAGER = {}, 
        NONE = {},
    };
    local _sorted = {};
    local function WipeCaches()
        for _, v in pairs(_roleCache) do
            wipe(v);
        end
    end
    local function BuildCache(source)
        WipeCaches();
        for _, unitFrame in ipairs(source) do
            tinsert(_roleCache[UnitGroupRolesAssigned(unitFrame.unit)], unitFrame);
        end
    end
    local function GetCachedInOrder(...)
        wipe(_sorted);
        for _, role in ipairs({...}) do
            for _, unitFrame in ipairs(_roleCache[role]) do
                tinsert(_sorted, unitFrame);
            end
        end
        return _sorted;
    end
    local function GetOrderForSetting(roleSortingOrder)
        local rsoEnum = MacEnum.Settings.RoleSortingOrder;
        if (roleSortingOrder == rsoEnum.TankHealDps) then
            return "TANK", "HEALER", "DAMAGER", "NONE";
        elseif (roleSortingOrder == rsoEnum.HealTankDps) then
            return "HEALER", "TANK", "DAMAGER", "NONE";
        elseif (roleSortingOrder == rsoEnum.DpsTankHeal) then
            return "DAMAGER", "TANK", "HEALER", "NONE";
        elseif (roleSortingOrder == rsoEnum.DpsHealTank) then
            return "DAMAGER", "HEALER", "TANK", "NONE";
        else
            error("unexpected value for _partySettings.RoleSortingOrder");
        end
    end
    local function GetCachedInOrderBySetting(roleSortingOrder)
        return GetCachedInOrder(GetOrderForSetting(roleSortingOrder));
    end

    function RaidFrame.ProcessLayout(self)
        if (InCombatLockdown()) then
            error("Cannot call this in combat!");
        end

        local frameWidth = _raidSettings.FrameWidth;
        local frameHeight = _raidSettings.FrameHeight;
        local spacing = _raidSettings.FrameSpacing;
        local margin = _raidSettings.Margin;
        local totalWidth, totalHeight = self:GetSize();
        local vertical = _raidSettings.Vertical;
        local roleSortingOrder = _raidSettings.RoleSortingOrder;
        local sortIgnoringGroups = _raidSettings.SortIgnoringGroups;
        
        
        for i=1, #_groupFrames do
            local attachedFrames = _groupFrames[i].attachedFrames;
            for n=1, #attachedFrames do
                attachedFrames[n]:ClearAllPoints();
            end
            wipe(attachedFrames);
        end

        for raidIndex=1, #_unitFrames do
            local frame = _unitFrames[raidIndex];
            local name, _, group = GetRaidRosterInfo(raidIndex);
            if (name ~= nil) then
                tinsert(_groupFrames[group].attachedFrames, frame);
                frame.isGrouped = true;
            else
                frame.isGrouped = false;
            end
        end

        for raidIndex=1, #_unitFrames do
            local frame = _unitFrames[raidIndex];
            if frame.isGrouped == false then
                for i=1, #_groupFrames do
                    local group = _groupFrames[i];
                    if #group.attachedFrames < Constants.GroupSize then
                        tinsert(group.attachedFrames, frame);
                        break;
                    end
                end
            end
        end

        for groupIndex=1, #_groupFrames do
            local groupFrame = _groupFrames[groupIndex];
            groupFrame:ClearAllPoints();
            if (vertical) then
                local x = margin + ((groupIndex - 1) * (frameWidth + spacing));
                PixelUtil.SetPoint(groupFrame, "TOPLEFT", self, "TOPLEFT", x, -margin);
                PixelUtil.SetSize(groupFrame, totalHeight - (2 * margin), frameWidth);
            else
                local y = margin + ((groupIndex - 1) * (frameHeight + spacing));
                PixelUtil.SetPoint(groupFrame, "TOPLEFT", self, "TOPLEFT", margin, -y);
                PixelUtil.SetSize(groupFrame, totalWidth - (2 * margin), frameHeight);
            end
            if (roleSortingOrder == MacEnum.Settings.RoleSortingOrder.Disabled) then
                attachedFrames = groupFrame.attachedFrames;
            else
                BuildCache(groupFrame.attachedFrames);
                attachedFrames = GetCachedInOrderBySetting(roleSortingOrder);
            end
            for i, frame in ipairs(attachedFrames) do
                frame:ClearAllPoints();
                frame:SetParent(groupFrame);
                if (vertical) then
                    local y = (i - 1) * (frameHeight + spacing);
                    PixelUtil.SetPoint(frame, "TOPLEFT", groupFrame, "TOPLEFT", 0, -y);
                    PixelUtil.SetSize(frame, frameWidth, frameHeight);
                else
                    local x = (i - 1) * (frameWidth + spacing);
                    PixelUtil.SetPoint(frame, "TOPLEFT", groupFrame, "TOPLEFT", x, 0);
                    PixelUtil.SetSize(frame, frameWidth, frameHeight);
                end
                
            end
        end
    end
end
