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
local UnitFrame = _p.UnitFrame;
local FrameUtil = _p.FrameUtil;
local ProfileManager = _p.ProfileManager;
local BlizzardFrameUtil = _p.BlizzardFrameUtil;
local StringUtil = _p.StringUtil;
local MacEnum = _p.MacEnum;

local String_EndsWith = StringUtil.EndsWith;

_p.PartyFrame = {};
local PartyFrame = _p.PartyFrame;

local _frame = nil;
local _unitFrames = nil;
local _sortedFrames = nil;
local _sortedPetFrames = nil;
local _partySettings = nil;
local _disabledBlizzardFrames = false;
local _forcedVisibility = nil;
local _groupChangedInCombat = false;
local _isTestMode = false;

local _changingSettings = false;

local function PartySettings_PropertyChanged(key)
    if (_changingSettings == true or _frame == nil) then return; end
    if (key == "FrameStrata") then
        _frame:SetFrameStrata(_partySettings.FrameStrata);
        _frame.petFrame:SetFrameStrata(_partySettings.FrameStrata);
    elseif (key == "FrameLevel") then
        _frame:SetFrameLevel(_partySettings.FrameLevel);
        _frame.petFrame:SetFrameLevel(_partySettings.FrameLevel);
    elseif (key == "Vertical") then
        PartyFrame.ProcessLayout(_frame, true);
    elseif (key == "RoleSortingOrder") then
        PartyFrame.ProcessLayout(_frame, true);
    elseif (key == "Enabled") then
        _frame.enabled = _partySettings.Enabled;
    elseif (key == "DisableBlizzardFrames") then
        PartyFrame.SetDisableBlizzardFrame(_partySettings.DisableBlizzardFrames);
    elseif (key == "AlwaysShowPlayer") then
        if (_isTestMode == false) then
            PartyFrame.SetForcedVisibility(_forcedVisibility);
        end
    else
        PartyFrame.ProcessLayout(_frame, true);
    end
end

local function PetSettings_PropertyChanged(key)
    if (_changingSettings == true or _frame == nil) then return; end
    if (key == "Enabled") then
        PartyFrame.ProcessLayout(_frame, true);
    elseif (key == "PositionTo" or key == "AlignWithPlayer") then
        PartyFrame.ProcessLayout(_frame, true);
    else
        PartyFrame.ProcessLayout(_frame);
    end
end

local function PartySettings_AnchorInfo_PropertyChanged(key)
    if (_changingSettings == true or _frame == nil) then return; end
    PartyFrame.ProcessLayout(_frame, true);
end

ProfileManager.RegisterProfileChangedListener(function(newProfile)
    if (_partySettings ~= nil) then
        _partySettings:UnregisterPropertyChanged(PartySettings_PropertyChanged);
        _partySettings.PetFrames:UnregisterPropertyChanged(PetSettings_PropertyChanged);
        _partySettings.AnchorInfo:UnregisterPropertyChanged(PartySettings_AnchorInfo_PropertyChanged);
    end
    _partySettings = newProfile.PartyFrame;
    _partySettings:RegisterPropertyChanged(PartySettings_PropertyChanged);
    _partySettings.PetFrames:RegisterPropertyChanged(PetSettings_PropertyChanged);
    _partySettings.AnchorInfo:RegisterPropertyChanged(PartySettings_AnchorInfo_PropertyChanged);

    if (_frame ~= nil) then
        for i=1, #_unitFrames do
            UnitFrame.SetSettings(_unitFrames[i], _partySettings);
        end
        local petFrames = _frame.petFrame.unitFrames;
        for i=1, #petFrames do
            UnitFrame.SetSettings(petFrames[i], _partySettings.PetFrames);
        end
        PartyFrame.ProcessLayout(_frame, true);
    end

    PartyFrame.SetDisableBlizzardFrame(_partySettings.DisableBlizzardFrames);
end);

function PartyFrame.RegisterEvents(self)
    self:SetScript("OnEvent", PartyFrame.OnEvent);

    self:RegisterEvent("PLAYER_REGEN_ENABLED");
    self:RegisterEvent("GROUP_ROSTER_UPDATE");
    self:RegisterEvent("PLAYER_ROLES_ASSIGNED");
end

function PartyFrame.OnEvent(self, event, ...)
    if event == "PLAYER_REGEN_ENABLED" then
        if (_groupChangedInCombat) then
            PartyFrame.ProcessLayout(self, false);
        end
    elseif event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ROLES_ASSIGNED" then
        if InCombatLockdown() then
            _groupChangedInCombat = true;
        else
            PartyFrame.ProcessLayout(self, false);
        end
    end
end

function PartyFrame.SetDisableBlizzardFrame(disable)
    if (_disabledBlizzardFrames == true) then
        if (disable == false) then
            _p.PopupDisplays.ShowSettingsUiReloadRequired();
        end
    else
        if (disable == true) then
            if (InCombatLockdown()) then error(L["Cannot disable blizzard frames in combat."]); end;
            _disabledBlizzardFrames = true;
            BlizzardFrameUtil.DisablePartyFrames();
        end
    end
end

do
    local onSizeChangedSpacing, onSizeChangedMargin;
    local function Frame_OnSizeChanged(self, width, height, isFinal)
        _changingSettings = true;
        local frameWidth, frameHeight;
        if (_partySettings.Vertical) then
            frameWidth = width - (2 * onSizeChangedMargin);
            frameHeight = (height - ((#_unitFrames - 1) * onSizeChangedSpacing) - (2 * onSizeChangedMargin)) / #_unitFrames;
        else
            frameWidth = width - (((#_unitFrames - 1) * onSizeChangedSpacing) - (2 * onSizeChangedMargin)) / #_unitFrames;
            frameHeight = height - (2 * onSizeChangedMargin);
        end
        if (isFinal) then
            _partySettings.FrameWidth = Round(frameWidth);
            _partySettings.FrameHeight = Round(frameHeight);
        else
            _partySettings.FrameWidth = frameWidth;
            _partySettings.FrameHeight = frameHeight;
        end
        _changingSettings = false;
        PartyFrame.ProcessLayout(self);
    end
    function PartyFrame.create()
        if _frame ~= nil then error("You can only create a single PartyFrame.") end
        local frameName = Constants.PartyFrameGlobalName;
        _frame = CreateFrame("Frame", frameName, _p.UIParent, "MacFramesPixelPerfectSecureHandlerStateTemplate");
        _frame:SetFrameStrata(_partySettings.FrameStrata);
        _frame:SetFrameLevel(_partySettings.FrameLevel);

        _frame.petFrame = CreateFrame("Frame", frameName .. "Pets", _frame, "MacFramesPixelPerfectTemplate");
        _frame.petFrame:SetFrameStrata(_partySettings.FrameStrata);
        _frame.petFrame:SetFrameLevel(_partySettings.FrameLevel);

        _frame.dragDropHost = FrameUtil.CreateDragDropOverlay(_frame, function(dragDropHost, frameToMove)
            _changingSettings = true;
            local point, relativeTo, relativePoint, xOffset, yOffset = frameToMove:GetPoint(1);
            _partySettings.AnchorInfo.OffsetX = Round(xOffset);
            _partySettings.AnchorInfo.OffsetY = Round(yOffset);
            _partySettings.AnchorInfo.AnchorPoint = point;
            for i=1, #_unitFrames do
                UnitFrame.SnapToPixels(_unitFrames[i]);
            end
            _changingSettings = false;
        end, false);
        
        FrameUtil.AddResizer(_frame.dragDropHost, _frame,
            function(dragDropHost, frame)   --resizeStart
                onSizeChangedSpacing = _partySettings.FrameSpacing;
                onSizeChangedMargin = _partySettings.Margin;
                _frame:SetScript("OnSizeChanged", Frame_OnSizeChanged);
            end, 
            function(dragDropHost, frame)   --resizeEnd
                ---@diagnostic disable-next-line: param-type-mismatch
                _frame:SetScript("OnSizeChanged", nil);
                Frame_OnSizeChanged(_frame, _frame:GetWidth(), _frame:GetHeight(), true);
            end
        );

        _unitFrames = {};
        _sortedFrames = {};
        _sortedPetFrames = {};
        _frame.unitFrames = _unitFrames;
        _frame.petFrame.unitFrames = {};

        --ugly name for the party player frame but OmniCD doesn't work otherwise
        local player = UnitFrame.new("player", _frame, nil, _partySettings, frameName .. "_" .. "party5");
        tinsert(_unitFrames, player);
        local playerPet = UnitFrame.new("pet", _frame.petFrame, nil, _partySettings.PetFrames);
        tinsert(_frame.petFrame.unitFrames, playerPet);
        player.petFrame = playerPet;
        for i=1,4 do
            local partyX = UnitFrame.new("party" .. i, _frame, nil, _partySettings);
            tinsert(_unitFrames, partyX);
            local petFrame = UnitFrame.new("partypet" .. i, _frame.petFrame, nil, _partySettings.PetFrames);
            tinsert(_frame.petFrame.unitFrames, petFrame);
            partyX.petFrame = petFrame;
        end

        
        for i=1,4 do
            
        end

        _frame:Hide();
        _frame:SetScript("OnShow", PartyFrame.RegisterEvents);
        _frame:SetScript("OnHide", function(self) self:SetScript("OnEvent", nil); end);

        PartyFrame.ProcessLayout(_frame, true);
        PartyFrame.SetForcedVisibility(_forcedVisibility);
        return _frame;
    end
end

function PartyFrame.GetAllUnitFrames()
    return _unitFrames;
end

function PartyFrame.SetTestMode(enabled)
    if (enabled == true) then
        _isTestMode = true;
        UnregisterAttributeDriver(_frame, "state-visibility");
        _frame:Show();
    else
        PartyFrame.SetForcedVisibility(_forcedVisibility);
        _isTestMode = false;
    end
    PartyFrame.SetChildTestModes(enabled);
end
function PartyFrame.SetForcedVisibility(visible)
    if (visible == true) then
        UnregisterAttributeDriver(_frame, "state-visibility");
        _frame:Show();
    elseif (visible == false) then
        UnregisterAttributeDriver(_frame, "state-visibility");
        _frame:Hide();
    else
        if (_partySettings.AlwaysShowPlayer) then
            RegisterAttributeDriver(_frame, "state-visibility", _partySettings.StateDriverVisibilityForcePlayer);
        else
            RegisterAttributeDriver(_frame, "state-visibility", _partySettings.StateDriverVisibility);
        end
    end
    _forcedVisibility = visible;
end

function PartyFrame.SetMovable(movable)
    if (movable) then
        PartyFrame.SetTestMode(true);
        _frame.dragDropHost:Show();
        _frame:SetFrameStrata(Constants.TestModeFrameStrata);
    else
        PartyFrame.SetTestMode(false);
        _frame.dragDropHost:Hide();
        _frame:SetFrameStrata(_partySettings.FrameStrata);
    end
end

function PartyFrame.SetChildTestModes(enabled)
    for i=1, #_unitFrames do
        UnitFrame.SetTestMode(_unitFrames[i], enabled);
    end
end

function PartyFrame.SetDisabled(disabled)
    if (disabled) then
        PartyFrame.SetForcedVisibility(false);
    else
        PartyFrame.SetForcedVisibility(nil);
    end
end

local function LayoutVerticalPets(self, petFrames)
    local frameWidth = _partySettings.FrameWidth;
    local frameHeight = _partySettings.FrameHeight;
    local spacing = _partySettings.FrameSpacing;
    local margin = _partySettings.Margin;

    local petSettings = _partySettings.PetFrames;
    local petFrameWidth = petSettings.FrameWidth;
    local petFrameHeight = petSettings.FrameHeight;

    if (petSettings.AlignWithPlayer == MacEnum.Settings.PetFramePartyAlignment.Compact) then
        local totalPetWidth = petFrameWidth + (2 * margin);
        local totalPetHeight = (#petFrames * petFrameHeight) + ((#petFrames - 1) * spacing) + (2 * margin);
        self.petFrame:SetSize(totalPetWidth, totalPetHeight);

        for i=1, #petFrames do
            local frame = petFrames[i];
            local x = margin;
            local y = margin + ((i - 1) * (petFrameHeight + spacing));
            
            frame:ClearAllPoints();
            frame:SetPoint("TOPLEFT", self.petFrame, "TOPLEFT", x, -y);
            
            frame:SetScaledSize(petFrameWidth, petFrameHeight);
        end
    elseif (petSettings.AlignWithPlayer == MacEnum.Settings.PetFramePartyAlignment.Beginning) then
        local totalPetWidth = petFrameWidth + (2 * margin);
        local totalPetHeight = ((#petFrames - 1) * frameHeight) + petFrameHeight + ((#petFrames - 1) * spacing) + (2 * margin);
        self.petFrame:SetScaledSize(self.petFrame, totalPetWidth, totalPetHeight);

        local lastFrame;
        for i=1, #petFrames do
            local frame = petFrames[i];
            frame:ClearAllPoints();
            if (lastFrame ~= nil) then
                frame:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", margin, -spacing);
            else
                frame:SetPoint("TOPLEFT", self.petFrame, "TOPLEFT", margin, -margin);
            end
            frame:SetScaledSize(petFrameWidth, petFrameHeight);
            lastFrame = frame;
        end
    elseif (petSettings.AlignWithPlayer == MacEnum.Settings.PetFramePartyAlignment.Center) then
        local totalPetWidth = petFrameWidth + (2 * margin);
        local totalPetHeight = (#petFrames * frameHeight) + ((#petFrames - 1) * spacing) + (2 * margin);
        self.petFrame:SetSize(totalPetWidth, totalPetHeight);

        for i=1, #petFrames do
            local frame = petFrames[i];
            local x = margin;
            local y = margin + ((i - 1) * (frameHeight + spacing)) + (frameHeight - petFrameHeight) / 2;
            
            frame:ClearAllPoints();
            frame:SetPoint("TOPLEFT", self.petFrame, "TOPLEFT", x, -y);
            
            frame:SetSize(petFrameWidth, petFrameHeight);
        end
    elseif (petSettings.AlignWithPlayer == MacEnum.Settings.PetFramePartyAlignment.End) then
        local totalPetWidth = petFrameWidth + (2 * margin);
        local totalPetHeight = ((#petFrames) * frameHeight) + ((#petFrames - 1) * spacing) + (2 * margin);
        self.petFrame:SetSize(totalPetWidth, totalPetHeight);

        for i=1, #petFrames do
            local frame = petFrames[i];
            local x = margin;
            local y = margin + ((i - 1) * (frameHeight + spacing)) + (frameHeight - petFrameHeight);
            
            frame:ClearAllPoints();
            frame:SetPoint("TOPLEFT", self.petFrame, "TOPLEFT", x, -y);
            
            frame:SetSize(petFrameWidth, petFrameHeight);
        end
    end
end

local function LayoutHorizontalPets(self, petFrames)
    local frameWidth = _partySettings.FrameWidth;
    local frameHeight = _partySettings.FrameHeight;
    local spacing = _partySettings.FrameSpacing;
    local margin = _partySettings.Margin;

    local petSettings = _partySettings.PetFrames;
    local petFrameWidth = petSettings.FrameWidth;
    local petFrameHeight = petSettings.FrameHeight;

    if (petSettings.AlignWithPlayer == MacEnum.Settings.PetFramePartyAlignment.Compact) then
        local totalPetWidth = (#petFrames * petFrameWidth) + ((#petFrames - 1) * spacing) + (2 * margin);
        local totalPetHeight = petFrameHeight + (2 * margin);
        self.petFrame:SetSize(totalPetWidth, totalPetHeight);

        for i=1, #petFrames do
            local frame = petFrames[i];
            local y = margin;
            local x = margin + ((i - 1) * (petFrameWidth + spacing));
            
            frame:ClearAllPoints();
            frame:SetPoint("TOPLEFT", self.petFrame, "TOPLEFT", x, -y);
            frame:SetSize(petFrameWidth, petFrameHeight);
        end
    elseif (petSettings.AlignWithPlayer == MacEnum.Settings.PetFramePartyAlignment.Beginning) then
        local totalPetWidth = ((#petFrames - 1) * frameWidth) + petFrameWidth + ((#petFrames - 1) * spacing) + (2 * margin);
        local totalPetHeight = petFrameHeight + (2 * margin);
        self.petFrame:SetSize(totalPetWidth, totalPetHeight);

        for i=1, #petFrames do
            local frame = petFrames[i];
            local y = margin;
            local x = margin + ((i - 1) * (frameWidth + spacing));
            
            frame:ClearAllPoints();
            frame:SetPoint("TOPLEFT", self.petFrame, "TOPLEFT", x, -y);
            frame:SetSize(petFrameWidth, petFrameHeight);
        end
    elseif (petSettings.AlignWithPlayer == MacEnum.Settings.PetFramePartyAlignment.Center) then
        local totalPetWidth = (#petFrames * frameWidth) + ((#petFrames - 1) * spacing) + (2 * margin);
        local totalPetHeight = petFrameHeight + (2 * margin);
        self.petFrame:SetSize(totalPetWidth, totalPetHeight);

        for i=1, #petFrames do
            local frame = petFrames[i];
            local y = margin;
            local x = margin + ((i - 1) * (frameWidth + spacing)) + (frameWidth - petFrameWidth) / 2;
            
            frame:ClearAllPoints();
            frame:SetPoint("TOPLEFT", self.petFrame, "TOPLEFT", x, -y);
            frame:SetSize(petFrameWidth, petFrameHeight);
        end
    elseif (petSettings.AlignWithPlayer == MacEnum.Settings.PetFramePartyAlignment.End) then
        local totalPetWidth = (#petFrames * frameWidth) + ((#petFrames - 1) * spacing) + (2 * margin);
        local totalPetHeight = petFrameHeight + (2 * margin);
        self.petFrame:SetSize(totalPetWidth, totalPetHeight);

        for i=1, #petFrames do
            local frame = petFrames[i];
            local y = margin;
            local x = margin + ((i - 1) * (frameWidth + spacing)) + (frameWidth - petFrameWidth);
            
            frame:ClearAllPoints();
            frame:SetPoint("TOPLEFT", self.petFrame, "TOPLEFT", x, -y);
            frame:SetSize(petFrameWidth, petFrameHeight);
        end
    end
end
do
    local _roleCache = {};
    local function RefreshRoleCache()
        for _, unitFrame in ipairs(_unitFrames) do
            _roleCache[unitFrame.unit] = UnitGroupRolesAssigned(unitFrame.unit);
        end
    end
    local function AddRoles(source, target, petTarget, role)
        for _, unitFrame in ipairs(source) do
            if (_roleCache[unitFrame.unit] == role) then
                tinsert(target, unitFrame);
                tinsert(petTarget, unitFrame.petFrame);
            end
        end
    end
    local function AddRolesByOrder(source, target, petTarget, role1, role2, role3)
        AddRoles(source, target, petTarget, role1);
        AddRoles(source, target, petTarget, role2);
        AddRoles(source, target, petTarget, role3);
        AddRoles(source, target, petTarget, "NONE");
    end
    function PartyFrame.ProcessLayout(self, reanchor)
        if (InCombatLockdown()) then
            return;
        end
        local frameWidth = _partySettings.FrameWidth;
        local frameHeight = _partySettings.FrameHeight;
        local spacing = _partySettings.FrameSpacing;
        local margin = _partySettings.Margin;

        local petSettings = _partySettings.PetFrames;
        local petFrameWidth = petSettings.FrameWidth;
        local petFrameHeight = petSettings.FrameHeight;
        
        local minUfWidth, minUfHeight = Constants.UnitFrame.MinWidth, Constants.UnitFrame.MinHeight;
        
        if (reanchor == true) then
            local anchorInfo = _partySettings.AnchorInfo;
            self:ClearAllPoints();
            self:SetPoint(anchorInfo.AnchorPoint, _p.UIParent, anchorInfo.AnchorPoint, anchorInfo.OffsetX, anchorInfo.OffsetY);
        end

        local unitFrames, petFrames;
        local roleSortingOrder = _partySettings.RoleSortingOrder;
        if (roleSortingOrder == MacEnum.Settings.RoleSortingOrder.Disabled) then
            unitFrames = _unitFrames;
            petFrames = _frame.petFrame.unitFrames;
        else
            wipe(_sortedFrames);
            wipe(_sortedPetFrames);
            unitFrames = _sortedFrames;
            petFrames = _sortedPetFrames;
            RefreshRoleCache();
            if (roleSortingOrder == MacEnum.Settings.RoleSortingOrder.TankHealDps) then
                AddRolesByOrder(_unitFrames, _sortedFrames, _sortedPetFrames, "TANK", "HEALER", "DAMAGER");
            elseif (roleSortingOrder == MacEnum.Settings.RoleSortingOrder.HealTankDps) then
                AddRolesByOrder(_unitFrames, _sortedFrames, _sortedPetFrames, "HEALER", "TANK", "DAMAGER");
            elseif (roleSortingOrder == MacEnum.Settings.RoleSortingOrder.DpsTankHeal) then
                AddRolesByOrder(_unitFrames, _sortedFrames, _sortedPetFrames, "DAMAGER", "TANK", "HEALER");
            elseif (roleSortingOrder == MacEnum.Settings.RoleSortingOrder.DpsHealTank) then
                AddRolesByOrder(_unitFrames, _sortedFrames, _sortedPetFrames, "DAMAGER", "HEALER", "TANK");
            else
                error("unexpected value for _partySettings.RoleSortingOrder");
            end
        end
        if (_partySettings.Vertical) then
            self:SetResizeBounds(minUfWidth + (2 * margin), (minUfHeight * #unitFrames) + (2 * margin) + ((#unitFrames - 1) * spacing));

            local totalWidth = frameWidth + (2 * margin);
            local totalHeight = (#unitFrames * frameHeight) + ((#unitFrames - 1) * spacing) + (2 * margin);
            self:SetSize(totalWidth, totalHeight);

            for i=1, #unitFrames do
                local frame = unitFrames[i];
                local x = margin;
                local y = margin + ((i - 1) * (frameHeight + spacing));
                
                frame:ClearAllPoints();
                frame:SetPoint("TOPLEFT", self, "TOPLEFT", x, -y);
                frame:SetSize(frameWidth, frameHeight);
            end

            self.petFrame:ClearAllPoints();
            if (petSettings.Enabled == false) then
                self.petFrame:Hide();
            else
                LayoutVerticalPets(self, petFrames);
                local positions = MacEnum.Settings.PetFramePosition;
                local position = petSettings.PositionTo;
                if (position == positions.Right) then
                    self.petFrame:SetPoint("TOPLEFT", self, "TOPRIGHT");
                elseif (position == positions.Left) then
                    self.petFrame:SetPoint("TOPRIGHT", self, "TOPLEFT");
                elseif (position == positions.Top) then
                    self.petFrame:SetPoint("BOTTOM", self, "TOP");
                elseif (position == positions.Bottom) then
                    self.petFrame:SetPoint("TOP", self, "BOTTOM");
                end
                self.petFrame:Show();
            end
        else
            self:SetResizeBounds((minUfWidth * #unitFrames) + (2 * margin) + ((#unitFrames - 1) * spacing), minUfHeight + (2 * margin));

            local totalWidth = (#unitFrames * frameWidth) + ((#unitFrames - 1) * spacing) + (2 * margin);
            local totalHeight = frameHeight + (2 * margin);
            
            self:SetSize(self, totalWidth, totalHeight);
            
            local lastFrame;
            for i=1, #unitFrames do
                local frame = unitFrames[i];
                frame:ClearAllPoints();
                frame:SetScaledSize(frameWidth, frameHeight);
                if (lastFrame ~= nil) then
                    frame:SetPoint("TOPLEFT", lastFrame, "TOPLEFT", margin, -spacing);
                else
                    frame:SetPoint("TOPLEFT", self, "TOPLEFT", margin, -margin);
                end
                lastFrame = frame;
            end

            self.petFrame:ClearAllPoints();
            if (petSettings.Enabled == false) then
                self.petFrame:Hide();
            else
                LayoutHorizontalPets(self, petFrames);
                local positions = MacEnum.Settings.PetFramePosition;
                local position = petSettings.PositionTo;
                if (position == positions.Right) then
                    self.petFrame:SetPoint("LEFT", self, "RIGHT");
                elseif (position == positions.Left) then
                    self.petFrame:SetPoint("RIGHT", self, "LEFT");
                elseif (position == positions.Top) then
                    self.petFrame:SetPoint("BOTTOMLEFT", self, "TOPLEFT");
                elseif (position == positions.Bottom) then
                    self.petFrame:SetPoint("TOPLEFT", self, "BOTTOMLEFT");
                end
                self.petFrame:Show();
            end
        end
    end
end
