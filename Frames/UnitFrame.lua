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
local LSM = LibStub("LibSharedMedia-3.0");
local L = _p.L;

local UnitIsDeadOrGhost = UnitIsDeadOrGhost;

local Constants = _p.Constants;
local Resources = _p.Resources;
local PlayerInfo = _p.PlayerInfo;
local SettingsUtil = _p.SettingsUtil;
local MyAuraUtil = _p.MyAuraUtil;
local AuraFrame = _p.AuraFrame;
local AuraGroup = _p.AuraGroup;
local AuraManager = _p.AuraManager;
local ProfileManager = _p.ProfileManager;
local FrameUtil = _p.FrameUtil;
local FramePool = _p.FramePool;
local StringUtil = _p.StringUtil;

local String_EndsWith = StringUtil.EndsWith;

local _classColorsByIndex = {};
for key, value in pairs(RAID_CLASS_COLORS) do
    tinsert(_classColorsByIndex, value);
end

local _currentProfile = nil;
local _mouseActions = nil;
local _auraTooltipHostPool = FramePool.Create();
local _auraTooltipHostList = {};

local _unitFrames = {};
_p.UnitFrames = _unitFrames;

local UnitFrame = {};
_p.UnitFrame = UnitFrame;

local function ProfileMouseActions_OnChange(key)
    UnitFrame.UpdateAllMouseActions();
end

local function LoadMouseActionsForSpec()
    if (_currentProfile ~= nil) then
        if (_mouseActions ~= nil) then
            _mouseActions:UnregisterPropertyChanged(ProfileMouseActions_OnChange);
        end
        _mouseActions = _currentProfile.MouseActions[PlayerInfo.classId][PlayerInfo.specId];
        _mouseActions:RegisterPropertyChanged(ProfileMouseActions_OnChange);
        ProfileMouseActions_OnChange();
    end
end

ProfileManager.RegisterProfileChangedListener(function(newProfile)
    _currentProfile = newProfile;
    LoadMouseActionsForSpec();
end);

function UnitFrame.OnSettingChanged(self, key, _, path)
    if (self == nil or self.isChangingSettings == true) then return; end
    if (String_EndsWith(path, ".NameFont")) then
        UnitFrame.UpdateNameFontFromSettings(self);
    elseif (String_EndsWith(path, ".StatusTextFont")) then
        UnitFrame.UpdateStatusTextFontFromSettings(self);
    elseif (key == "HealthBarTextureName") then
        UnitFrame.UpdateHealthBarTextureFromSettings(self);
    elseif (key == "PowerBarTextureName") then
        UnitFrame.UpdatePowerBarTextureFromSettings(self);
    elseif (key == "PowerBarEnabled" or key == "PowerBarHeight") then
        UnitFrame.LayoutHealthAndPowerBar(self);
        UnitFrame.UpdatePowerMax(self);
        UnitFrame.UpdatePower(self);
        UnitFrame.UpdatePowerColor(self);
    elseif (key == "TargetBorderWidth") then
        UnitFrame.UpdateTargetHighlightTextureFromSettings(self);
    elseif (key == "AggroBorderWidth") then
        UnitFrame.UpdateAggroHighlightTextureFromSettings(self);
    elseif (key == "StatusIconSize") then
        UnitFrame.LayoutStatusIcons(self);
    elseif (key == "RangeCheckThrottleSeconds") then
        UnitFrame.UpdateRangeCheckTicker(self);
    elseif (key == "BossPollingThrottleSeconds") then
        UnitFrame.UpdateBossPollingTicker(self);
    elseif (key == "RaidTargetIconSize") then
        UnitFrame.UpdateRaidTargetIconSizeFromSettings(self);
    elseif (key == "RaidTargetIconAlpha") then
        UnitFrame.UpdateRaidTargetIconAlphaFromSettings(self);
    elseif (key == "RaidTargetIconEnabled") then
        UnitFrame.UpdateRaidTargetIconEnabledFromSettings(self);
        UnitFrame.UpdateRaidTargetIcon(self);
    elseif (key == "Padding") then
        UnitFrame.CreateAuraDisplays(self);
        if self.isTestMode then
            UnitFrame.SetTestMode(self, true, true);
        end
    else    --settings that affect test mode data
        if self.isTestMode then
            UnitFrame.SetTestMode(self, true, true);
        else
            if (key == "DisplayServerNames") then
                UnitFrame.UpdateName(self);
            elseif (key == "BlendToDangerColors" or key == "BlendToDangerColorsRatio" or key == "BlendToDangerColorsMinimum" or key == "BlendToDangerColorsMaximum") then
                UnitFrame.UpdateHealth(self);
            elseif (key == "OutOfRangeAlpha") then
                UnitFrame.UpdateInRange(self);
            elseif (key == "RoleIconSize") then
                UnitFrame.UpdateRoleIcon(self);
            end
        end
    end
end

do
    local function CreateAuraChanged(self, auraCreator)
        return function(key)
            auraCreator(self);
            if (self.isTestMode) then
                UnitFrame.SetTestMode(self, true, true);
            else
                UnitFrame.UpdateAuras(self);
            end
        end
    end
    local function E(self, eventHandler, forwardArgs)
        if (forwardArgs) then
            return function(...)
                if (self == nil or self.isChangingSettings == true) then return; end
                eventHandler(self, ...);
            end
        else
            return function(key)
                if (self == nil or self.isChangingSettings == true) then return; end
                eventHandler(self);
            end
        end
    end
    local function CreateBuffGroupsFromSettings(...)
        UnitFrame.CreateSpecialClassDisplayFromSettings(...);
        UnitFrame.CreateBuffsFromSettings(...);
    end
    function UnitFrame.SetSettings(self, settings, suppressUpdate)
        if (self.propertyChangedHandlers == nil) then
            self.propertyChangedHandlers = {
                Frames = E(self, UnitFrame.OnSettingChanged, true),
                DispellableDebuffs = E(self, CreateAuraChanged(self, UnitFrame.CreateDispellablesFromSettings)),
                OtherDebuffs = E(self, CreateAuraChanged(self, UnitFrame.CreateUndispellablesFromSettings)),
                BossAuras = E(self, CreateAuraChanged(self, UnitFrame.CreateBossAurasFromSettings)),
                DefensiveBuff = E(self, CreateAuraChanged(self, UnitFrame.CreateDefensivesFromSettings)),
                SpecialClassDisplay = E(self, CreateAuraChanged(self, CreateBuffGroupsFromSettings)),
                Buffs = E(self, CreateAuraChanged(self, CreateBuffGroupsFromSettings)),
            };
        end
        local handlers = self.propertyChangedHandlers;

        if (self.settings ~= nil) then
            local oldSettings = self.settings;
            oldSettings.Frames:UnregisterAllPropertyChanged(handlers.Frames);
            oldSettings.DispellableDebuffs:UnregisterPropertyChanged(handlers.DispellableDebuffs);
            oldSettings.OtherDebuffs:UnregisterPropertyChanged(handlers.OtherDebuffs);
            oldSettings.BossAuras:UnregisterPropertyChanged(handlers.BossAuras);
            oldSettings.DefensiveBuff:UnregisterPropertyChanged(handlers.DefensiveBuff);
            oldSettings.SpecialClassDisplay:UnregisterPropertyChanged(handlers.SpecialClassDisplay);
            oldSettings.Buffs:UnregisterPropertyChanged(handlers.Buffs);
        end

        self.settings = settings;
        local newSettings = settings;
        newSettings.Frames:RegisterAllPropertyChanged(handlers.Frames);
        newSettings.DispellableDebuffs:RegisterPropertyChanged(handlers.DispellableDebuffs);
        newSettings.OtherDebuffs:RegisterPropertyChanged(handlers.OtherDebuffs);
        newSettings.BossAuras:RegisterPropertyChanged(handlers.BossAuras);
        newSettings.DefensiveBuff:RegisterPropertyChanged(handlers.DefensiveBuff);
        newSettings.SpecialClassDisplay:RegisterPropertyChanged(handlers.SpecialClassDisplay);
        newSettings.Buffs:RegisterPropertyChanged(handlers.Buffs);

        if (not suppressUpdate) then
            UnitFrame.UpdateAllSettings(self);
            UnitFrame.UpdateAll(self);
        end
    end
end

UnitFrame.new = function(unit, parent, namePrefix, settings, frameNameOverride)
    local frameName;
    if (frameNameOverride == nil) then
        if (namePrefix == nil) then
            namePrefix = parent:GetName();
            if (namePrefix == nil) then
                error("A prefix for the unit frames is required.");
            end
        end
        frameName = namePrefix .. "_" .. unit;
    else
        frameName = frameNameOverride;
    end
    local frame = _unitFrames[frameName];
    if (frame == nil) then
        frame = CreateFrame("Button", frameName, parent, "MacFramesUnitFrameTemplate");
        frame.statusIconsFrame = CreateFrame("Frame", nil, frame);

        frame.targetBorder = CreateFrame("Frame", nil, frame);
        frame.targetBorder:SetAllPoints();
        frame.targetBorder.children = FrameUtil.CreateSolidBorder(frame.targetBorder, 2, 1, 1, 1, 1);

        frame.aggroBorder = CreateFrame("Frame", nil, frame);
        frame.aggroBorder:SetAllPoints();
        frame.aggroBorder.children = FrameUtil.CreateSolidBorder(frame.aggroBorder, 1, 1, 0, 0, 1);

        _unitFrames[frameName] = frame;
    end

    frame.isChangingSettings = false;
    frame.displayUnit = unit;
    frame.unit = unit;
    UnitFrame.SetSettings(frame, settings, true);
    UnitFrame.Setup(frame);
    UnitFrame.RegisterEvents(frame);
    UnitFrame.UpdateAllSettings(frame);
    UnitFrame.SetUnit(frame, unit);
    return frame;
end

function UnitFrame.SnapToPixels(self)
    local testMode = self.isTestMode;
    UnitFrame.Setup(self);
    UnitFrame.UpdateAllSettings(self);
    if (testMode == true) then
        UnitFrame.SetTestMode(self, true);
    else
        UnitFrame.UpdateAll(self);
    end
end

function UnitFrame.Setup(self)
    self:SetAlpha(1);
    self.background:SetTexture(Resources.SB_HEALTH_BACKGROUND);
    
    self.targetBorder:Hide();
    self.aggroBorder:Hide();

    self.rankIcon:ClearAllPoints();
    PixelUtil.SetSize(self.rankIcon, 1, self.settings.Frames.RoleIconSize);
    PixelUtil.SetPoint(self.rankIcon, "TOPLEFT", self, "TOPLEFT", 3, -3);

    self.roleIcon:ClearAllPoints();
    PixelUtil.SetSize(self.roleIcon, 1, self.settings.Frames.RoleIconSize);
    PixelUtil.SetPoint(self.roleIcon, "TOPLEFT", self.rankIcon, "TOPRIGHT", 1, 0);
    PixelUtil.SetPoint(self.roleIcon, "BOTTOMLEFT", self.rankIcon, "BOTTOMRIGHT", 1, 0);

    local nameFontName, nameFontSize, nameFontFlags = self.name:GetFont();
    PixelUtil.SetPoint(self.name, "TOPLEFT", self.roleIcon, "TOPRIGHT", 2, 0);
    PixelUtil.SetPoint(self.name, "BOTTOMLEFT", self.roleIcon, "BOTTOMRIGHT", 2, 0);
    PixelUtil.SetPoint(self.name, "RIGHT", self, "RIGHT", -2, 0);
    self.name:SetWordWrap(false);
    self.name:SetJustifyH("LEFT");
    
    local sic = self.statusIconContainer;
    sic.statusText.fontHeight = select(2, sic.statusText:GetFont());
    PixelUtil.SetHeight(sic, self.settings.Frames.StatusIconSize + sic.statusText.fontHeight);
    PixelUtil.SetPoint(sic, "LEFT", self, "LEFT", 0, -(nameFontSize / 2));
    PixelUtil.SetPoint(sic, "RIGHT", self, "RIGHT", 0, -(nameFontSize / 2));
    sic:Show();
    
    PixelUtil.SetPoint(sic.statusText, "TOP", sic, "TOP", 0, 0);
    sic.statusText:SetJustifyH("CENTER");

    sic.readyCheckIcon:ClearAllPoints();
    sic.readyCheckIcon:SetTexture(READY_CHECK_WAITING_TEXTURE);
    sic.readyCheckIcon:Hide();

    sic.summonIcon:ClearAllPoints();
    sic.summonIcon:SetAtlas("Raid-Icon-SummonPending");
    sic.summonIcon:SetTexCoord(0, 1, 0, 1);
    sic.summonIcon:Hide();

    sic.resurrectIcon:ClearAllPoints();
    sic.resurrectIcon:SetTexture("Interface\\RaidFrame\\Raid-Icon-Rez");
    sic.resurrectIcon:Hide();

    sic.phasingIcon:ClearAllPoints();
    sic.phasingIcon:SetTexture("Interface\\TargetingFrame\\UI-PhasingIcon");
    sic.phasingIcon:SetTexCoord(0.15625, 0.84375, 0.15625, 0.84375);
    sic.phasingIcon:Hide();

    sic.lfgIcon:ClearAllPoints();
    sic.lfgIcon:SetTexture("Interface\\LFGFrame\\LFG-Eye");
    sic.lfgIcon:SetTexCoord(0.125, 0.25, 0.25, 0.5);
    sic.lfgIcon:Hide();

    local rti = self.raidTargetIcon;
    local iconTexture = rti.texture;
    PixelUtil.SetPoint(rti, "CENTER", self, "CENTER", 0, 0);
    iconTexture:SetAllPoints();
    iconTexture:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons");
    UnitFrame.UpdateRaidTargetIconSizeFromSettings(self);
    UnitFrame.UpdateRaidTargetIconAlphaFromSettings(self);
    UnitFrame.UpdateRaidTargetIconEnabledFromSettings(self);
    iconTexture:Show();
    rti:Hide();
end

function UnitFrame.UpdateRaidTargetIcon(self)
    if (not self.raidTargetIcon.enabled) then
        self.raidTargetIcon:Hide();
        return;
    end
    local usedIconIndex = GetRaidTargetIndex(self.unit);
    if (usedIconIndex ~= nil) then
        UnitFrame.SetRaidTargetIconByIndex(self, usedIconIndex);
    else
        self.raidTargetIcon:Hide();
    end
end

function UnitFrame.SetRaidTargetIconByIndex(self, index)
    local left = mod((index-1)/4, 1);
    local right = left + 0.25;
    local top = floor((index-1)/4) * 0.25;
    local bottom = top + 0.25;

    self.raidTargetIcon.texture:SetTexCoord(left, right, top, bottom);
    self.raidTargetIcon:Show();
end

---@diagnostic disable: undefined-field
function UnitFrame.GetTextureFromSettings(lsmType, lsmName, defaultLsmName)
    local usedName = lsmName;
    local texturePath = LSM:Fetch(lsmType, lsmName, true);
    if (texturePath == nil) then
        _p.UserChatMessage(L["Couldn't find a selected texture. Resetting to default."]);
        usedName = defaultLsmName;
        texturePath = LSM:Fetch(lsmType, defaultLsmName, true);
        if (texturePath == nil) then
            usedName = LSM:GetDefault(lsmType);
            texturePath = LSM:Fetch(lsmType, usedName, false);
        end
    end
    return texturePath, usedName;
end

function UnitFrame.GetFontFromSettings(lsmName)
    local usedName = lsmName;
    local lsmEntry = LSM:Fetch("font", lsmName, true);
    if (lsmEntry == nil) then
        usedName = LSM:GetDefault("font");
        lsmEntry = LSM:Fetch("font", usedName);
    end
    return lsmEntry, usedName;
end
---@diagnostic enable: undefined-field

function UnitFrame.UpdateTargetHighlightTextureFromSettings(self)
    self.targetBorder.children:Resize(self.settings.Frames.TargetBorderWidth);
end

function UnitFrame.UpdateAggroHighlightTextureFromSettings(self)
    self.aggroBorder.children:Resize(self.settings.Frames.AggroBorderWidth)
end

function UnitFrame.UpdateRaidTargetIconEnabledFromSettings(self)
    self.raidTargetIcon.enabled = self.settings.Frames.RaidTargetIconEnabled;
end

function UnitFrame.UpdateRaidTargetIconSizeFromSettings(self)
    PixelUtil.SetSize(self.raidTargetIcon, self.settings.Frames.RaidTargetIconSize, self.settings.Frames.RaidTargetIconSize);
end

function UnitFrame.UpdateRaidTargetIconAlphaFromSettings(self)
    self.raidTargetIcon.texture:SetAlpha(self.settings.Frames.RaidTargetIconAlpha);
end

function UnitFrame.UpdateHealthBarTextureFromSettings(self)
    self.isChangingSettings = true;
    local healthBarTexturePath, usedLsmName = UnitFrame.GetTextureFromSettings(
        "statusbar", self.settings.Frames.HealthBarTextureName, Constants.HealthBarDefaultTextureName);
    self.settings.Frames.HealthBarTextureName = usedLsmName;
    self.isChangingSettings = false;
    self.healthBar:SetStatusBarTexture(healthBarTexturePath, "BORDER");
    local healthBarTexture = self.healthBar:GetStatusBarTexture();
    self.healthBar.texture = healthBarTexture;

    self.healthBar.overlay:ClearAllPoints();
    self.healthBar.overlay:SetPoint("TOPLEFT", healthBarTexture, "TOPLEFT", 0, 0);
    self.healthBar.overlay:SetPoint("BOTTOMRIGHT", healthBarTexture, "BOTTOMRIGHT", 0, 0);
    self.healthBar.overlay:SetColorTexture(1, 1, 0, 1);
    self.healthBar.overlay:SetBlendMode("BLEND");

    self.healAbsorb:ClearAllPoints();
    self.healAbsorb:SetBlendMode("BLEND");
    self.healAbsorb:SetColorTexture(1, 0, 0, 1);
    self.healAbsorb:SetVertexColor(0.2, 0, 0, 0.7);
    PixelUtil.SetPoint(self.healAbsorb, "TOPRIGHT", healthBarTexture, "TOPRIGHT", 0, 0);
    PixelUtil.SetPoint(self.healAbsorb, "BOTTOMRIGHT", healthBarTexture, "BOTTOMRIGHT", 0, 0);

    self.totalAbsorb:ClearAllPoints();
    self.totalAbsorb:SetTexture(healthBarTexturePath);
    self.totalAbsorb:SetVertexColor(0.6, 0.9, 1, 1);
    PixelUtil.SetPoint(self.totalAbsorb, "TOPLEFT", healthBarTexture, "TOPLEFT", 0, 0);
    PixelUtil.SetPoint(self.totalAbsorb, "BOTTOMLEFT", healthBarTexture, "BOTTOMLEFT", 0, 0);

    self.overAbsorb:ClearAllPoints();
    self.overAbsorb:SetTexture(Resources.HEALTH_OVER_ABSORB);
    self.overAbsorb:SetBlendMode("ADD");
    PixelUtil.SetPoint(self.overAbsorb, "TOPRIGHT", self.healthBar, "TOPRIGHT", 0, 0);
    PixelUtil.SetPoint(self.overAbsorb, "BOTTOMRIGHT", self.healthBar, "BOTTOMRIGHT", 0, 0);
    self.overAbsorb:SetWidth(6);

    self.healPrediction:ClearAllPoints();
    self.healPrediction:SetTexture(healthBarTexturePath);
    self.healPrediction:SetVertexColor(0, 0.55, 0.1, 0.5);
    PixelUtil.SetPoint(self.healPrediction, "TOPLEFT", healthBarTexture, "TOPLEFT", 0, 0);
    PixelUtil.SetPoint(self.healPrediction, "BOTTOMLEFT", healthBarTexture, "BOTTOMLEFT", 0, 0);
end

function UnitFrame.UpdatePowerBarTextureFromSettings(self)
    self.isChangingSettings = true;
    local powerBarTexturePath, usedLsmName = UnitFrame.GetTextureFromSettings(
        "statusbar", self.settings.Frames.PowerBarTextureName, Constants.PowerBarDefaultTextureName);
    self.settings.Frames.PowerBarTextureName = usedLsmName;
    self.isChangingSettings = false;
    self.powerBar:SetStatusBarTexture(powerBarTexturePath, "BORDER");
end

function UnitFrame.LayoutHealthAndPowerBar(self)
    local powerBar = self.powerBar;
    local healthBar = self.healthBar;

    if (self.settings.Frames.PowerBarEnabled) then
        powerBar.enabled = true;
        local powerBarHeightPixelized = PixelUtil.GetNearestPixelSize(self.settings.Frames.PowerBarHeight, self:GetEffectiveScale(), 1);
        powerBar:SetPoint("TOP", self, "BOTTOM", 0, powerBarHeightPixelized + 1);
        powerBar:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 1, 1);
        powerBar:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -1, 1);
        powerBar:Show();

        healthBar:ClearAllPoints();
        healthBar:SetPoint("TOP", self, "TOP", 0, -1);
        healthBar:SetPoint("BOTTOMLEFT", powerBar, "TOPLEFT", 0, 0);
        healthBar:SetPoint("BOTTOMRIGHT", powerBar, "TOPRIGHT", 0, 0);
    else
        powerBar.enabled = false;
        powerBar:ClearAllPoints();
        powerBar:Hide();
        healthBar:ClearAllPoints();
        healthBar:SetPoint("TOPLEFT", self, "TOPLEFT", 1, -1);
        healthBar:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -1, 1);
        --PixelUtil.SetPoint(self.healthBar, "TOPLEFT", self, "TOPLEFT", 1, -1);
        --PixelUtil.SetPoint(self.healthBar, "BOTTOMRIGHT", self, "BOTTOMRIGHT", -1, 1);
    end
end

function UnitFrame.UpdateNameFontFromSettings(self)
    local fontPath, usedLsmName = UnitFrame.GetFontFromSettings(self.settings.Frames.NameFont.Name);
    self.settings.Frames.NameFont.Name = usedLsmName;
    self.name:SetFont(fontPath, self.settings.Frames.NameFont.Size);
    self.name:ClearAllPoints();
    PixelUtil.SetPoint(self.name, "TOPLEFT", self.roleIcon, "TOPRIGHT", 2, 0);
    PixelUtil.SetPoint(self.name, "RIGHT", self, "RIGHT", -2, 0);
end

function UnitFrame.UpdateStatusTextFontFromSettings(self)
    local fontPath, usedLsmName = UnitFrame.GetFontFromSettings(self.settings.Frames.StatusTextFont.Name);
    self.settings.Frames.StatusTextFont.Name = usedLsmName;
    self.statusIconContainer.statusText:SetFont(fontPath, self.settings.Frames.StatusTextFont.Size);
    UnitFrame.LayoutStatusIcons(self);
end

function UnitFrame.UpdateAllSettings(self)
    UnitFrame.UpdateHealthBarTextureFromSettings(self);
    UnitFrame.UpdatePowerBarTextureFromSettings(self);
    UnitFrame.LayoutHealthAndPowerBar(self);

    UnitFrame.UpdateTargetHighlightTextureFromSettings(self);
    UnitFrame.UpdateAggroHighlightTextureFromSettings(self);

    UnitFrame.UpdateNameFontFromSettings(self);
    UnitFrame.UpdateStatusTextFontFromSettings(self);

    UnitFrame.CreateAuraDisplays(self);

    UnitFrame.UpdateRaidTargetIconSizeFromSettings(self);
    UnitFrame.UpdateRaidTargetIconAlphaFromSettings(self);
    UnitFrame.UpdateRaidTargetIconEnabledFromSettings(self);
    UnitFrame.UpdateRaidTargetIcon(self);
end
do
    function UnitFrame.SetTestMode(self, enabled, preserveTestModeData)
        if (enabled == true) then
            self:SetScript("OnShow", nil);
            self:SetScript("OnHide", nil);
            UnitFrame.DisableScripts(self);
            UnregisterUnitWatch(self);
            self:Show();
            
            self:SetScript("OnSizeChanged", UnitFrame.UpdateTestDisplay);

            self.isTestMode = true;
            if (self.testModeData == nil) then
                self.testModeData = {};
            end
            if (not preserveTestModeData) then
                self.testModeData.power = math.random(1, 1000);
                self.testModeData.maxPower = 1000;
                self.testModeData.health = math.random(1, 1000);
                self.testModeData.maxHealth = 1000;
                self.testModeData.incomingHeal = math.random(0, 200);
                self.testModeData.absorb = math.random(0, 300);
                self.testModeData.healAbsorb = math.random(0, 100);
                self.testModeData.classColor = _classColorsByIndex[math.random(1, #_classColorsByIndex)];
                self.testModeData.displayServerPlaceholder = (math.random(0, 1) == 0);
                self.testModeData.isInRange = (math.random(0, 3) > 0);
                self.testModeData.name = GetUnitName("player", self.settings.Frames.DisplayServerNames);
                self.testModeData.raidTargetIconIndex = math.random(1, 8);
            end
            
            UnitFrame.SetIcon(self, self.roleIcon, "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES", GetTexCoordsForRoleSmallCircle("DAMAGER"));
            UnitFrame.UpdateTestDisplay(self);
            for _, group in pairs(self.auraGroups) do
                AuraGroup.SetTestMode(group, enabled);
            end
        else
            self:SetScript("OnSizeChanged", nil);

            self:SetScript("OnShow", self.onShowScript);
            self:SetScript("OnHide", self.onHideScript);
            if (UnitExists(self.unit)) then
                UnitFrame.EnableScripts(self);
            end
            RegisterUnitWatch(self);

            self.isTestMode = false;
            UnitFrame.UpdateAll(self);
        end
    end
end
function UnitFrame.UpdateTestDisplay(self)
    local data = self.testModeData;
    local classColor = data.classColor;
    UnitFrame.SetHealthColor(self, classColor.r, classColor.g, classColor.b);
    self.name:SetText(data.name);
    UnitFrame.SetInRange(self, data.isInRange);
    self.healthBar:SetMinMaxValues(0, data.maxHealth);
    UnitFrame.SetHealthBarExtraInfo(self, data.health, data.maxHealth, data.incomingHeal, data.absorb, data.healAbsorb);
    UnitFrame.SetHealth(self, data.health);
    self.powerBar:SetMinMaxValues(0, data.maxPower);
    UnitFrame.SetPower(self, data.power);
    UnitFrame.SetRaidTargetIconByIndex(self, data.raidTargetIconIndex);
end
do
    local _visibleFrames = {};
    local function ProcessIcon(icon)
        if (icon:IsShown()) then
            tinsert(_visibleFrames, icon);
        end
    end
    function UnitFrame.LayoutStatusIcons(self)
        local sic = self.statusIconContainer;
        if (sic.disableLayouting == true) then --mostly for UpdateAll to prevent excessive recalculating
            return;
        end
        local visibleFrames = _visibleFrames;
        wipe(visibleFrames);

        PixelUtil.SetHeight(sic, self.settings.Frames.StatusIconSize + sic.statusText.fontHeight);

        ProcessIcon(sic.readyCheckIcon);
        ProcessIcon(sic.summonIcon);
        ProcessIcon(sic.resurrectIcon);
        ProcessIcon(sic.phasingIcon);
        ProcessIcon(sic.lfgIcon);

        if (#visibleFrames == 0) then
            --no frames visible, we just move the status text in the middle
            sic.statusText:ClearAllPoints();
            PixelUtil.SetPoint(sic.statusText, "CENTER", sic, "CENTER", 0, 0);
        else
            local iconSize = self.settings.Frames.StatusIconSize;
            local totalWidth = #visibleFrames * iconSize;
            PixelUtil.SetPoint(visibleFrames[1], "BOTTOMLEFT", sic, "BOTTOMLEFT", (sic:GetWidth() / 2) - (totalWidth / 2), 0);
            PixelUtil.SetSize(visibleFrames[1], iconSize, iconSize);
            for i=2,#visibleFrames do
                PixelUtil.SetPoint(visibleFrames[i], "TOPLEFT", visibleFrames[i - 1], "TOPRIGHT", 0, 0);
                PixelUtil.SetSize(visibleFrames[i], iconSize, iconSize);
            end
            --since we displayed an icon we need to move the statusText up
            sic.statusText:ClearAllPoints();
            PixelUtil.SetPoint(sic.statusText, "TOP", sic, "TOP", 0, 0);
        end
    end
end

function UnitFrame.CreateAuraDisplays(self)
    if (self.auraGroups == nil) then
        self.auraGroups = {};
    end
    UnitFrame.CreateSpecialClassDisplayFromSettings(self);
    UnitFrame.CreateBuffsFromSettings(self);
    UnitFrame.CreateDefensivesFromSettings(self);
    UnitFrame.CreateUndispellablesFromSettings(self);
    UnitFrame.CreateDispellablesFromSettings(self);
    UnitFrame.CreateBossAurasFromSettings(self);
    for i=#_auraTooltipHostList, 1, -1 do
        local frame = _auraTooltipHostList[i];
        UnitFrame.RemoveMyAttributes(frame);
        _auraTooltipHostPool:Put(frame);
    end
end

function UnitFrame.CreateSpecialClassDisplayFromSettings(self, classDisplayList)
    local s = self.settings.SpecialClassDisplay;
    local auraGroup = self.auraGroups.specialClassDisplay;
    if (auraGroup ~= nil) then
        AuraGroup.Recycle(self.auraGroups.specialClassDisplay);
    end
    if (s.enabled == false) then
        self.auraGroups.specialClassDisplay = nil;
        return;
    end
    if (classDisplayList == nil) then
        classDisplayList = SettingsUtil.GetSpecialClassDisplays();
    end
    auraGroup = AuraGroup.new(self, self.unit, AuraGroup.Type.PredefinedAuraSet, nil, s.iconWidth, s.iconHeight, s.iconSpacing, s.iconZoom);
    self.auraGroups.specialClassDisplay = auraGroup;
    AuraGroup.SetPredefinedAuras(auraGroup, classDisplayList);
    AuraGroup.SetIgnoreBlacklist(auraGroup, true);
    AuraGroup.SetUseBlizzardAuraFilter(auraGroup, s.useBlizzardAuraFilter);
    AuraGroup.SetReverseOrder(auraGroup, true);
    AuraGroup.SetUseFixedPositions(auraGroup, s.fixedPositions);
    AuraGroup.EnableTooltips(auraGroup, s.EnableAuraTooltips);
    local padding = self.settings.Frames.Padding;
    PixelUtil.SetPoint(auraGroup, "TOPRIGHT", self, "TOPRIGHT", -padding, -padding);
    auraGroup:SetFrameLevel(self:GetFrameLevel() + 1);
    auraGroup:Show();
    return auraGroup;
end

function UnitFrame.CreateBuffsFromSettings(self)
    local s = self.settings.Buffs;
    local auraGroup = self.auraGroups.buffs;
    if (auraGroup ~= nil) then
        AuraGroup.Recycle(self.auraGroups.buffs);
    end
    if (s.Enabled == false) then
        self.auraGroups.buffs = nil;
        return nil;
    end
    auraGroup = AuraGroup.new(self, self.unit, AuraGroup.Type.Buff, s.iconCount, s.iconWidth, s.iconHeight, s.iconSpacing, s.iconZoom);
    self.auraGroups.buffs = auraGroup;
    AuraGroup.SetUseBlizzardAuraFilter(auraGroup, s.useBlizzardAuraFilter);
    AuraGroup.SetReverseOrder(auraGroup, true);
    AuraGroup.EnableTooltips(auraGroup, s.EnableAuraTooltips);
    local padding = self.settings.Frames.Padding;
    if (self.auraGroups.specialClassDisplay ~= nil) then
        PixelUtil.SetPoint(auraGroup, "TOPRIGHT", self.auraGroups.specialClassDisplay, "BOTTOMRIGHT", 0, -1);
    else
        PixelUtil.SetPoint(auraGroup, "TOPRIGHT", self, "TOPRIGHT", -padding, -padding);
    end
    auraGroup:SetFrameLevel(self:GetFrameLevel() + 1);
    auraGroup:Show();
    return auraGroup;
end

function UnitFrame.CreateDefensivesFromSettings(self)
    local s = self.settings.DefensiveBuff;
    local auraGroup = self.auraGroups.defensives;
    if (auraGroup ~= nil) then
        AuraGroup.Recycle(self.auraGroups.defensives);
    end
    if (s.Enabled == false) then
        self.auraGroups.defensives = nil;
        return nil;
    end
    auraGroup = AuraGroup.new(self, self.unit, AuraGroup.Type.DefensiveBuff, s.iconCount, s.iconWidth, s.iconHeight, s.iconSpacing, s.iconZoom);
    self.auraGroups.defensives = auraGroup;
    AuraGroup.SetUseBlizzardAuraFilter(auraGroup, s.useBlizzardAuraFilter);
    AuraGroup.SetReverseOrder(auraGroup, true);
    AuraGroup.EnableTooltips(auraGroup, s.EnableAuraTooltips);
    local padding = self.settings.Frames.Padding;
    PixelUtil.SetPoint(auraGroup, "BOTTOMRIGHT", self, "BOTTOMRIGHT", -padding, padding);
    auraGroup:SetFrameLevel(self:GetFrameLevel() + 1);
    auraGroup:Show();
    return auraGroup;
end

function UnitFrame.CreateUndispellablesFromSettings(self)
    local s = self.settings.OtherDebuffs;
    local auraGroup = self.auraGroups.undispellable;
    if (auraGroup ~= nil) then
        AuraGroup.Recycle(self.auraGroups.undispellable);
    end
    if (s.Enabled == false) then
        self.auraGroups.undispellable = nil;
        return nil;
    end
    auraGroup = AuraGroup.new(self, self.unit, AuraGroup.Type.UndispellableDebuff, s.iconCount, s.iconWidth, s.iconHeight, s.iconSpacing, s.iconZoom);
    self.auraGroups.undispellable = auraGroup;
    AuraGroup.SetUseBlizzardAuraFilter(auraGroup, s.useBlizzardAuraFilter);
    AuraGroup.EnableTooltips(auraGroup, s.EnableAuraTooltips);
    local padding = self.settings.Frames.Padding;
    PixelUtil.SetPoint(auraGroup, "BOTTOMLEFT", self, "BOTTOMLEFT", padding, padding);
    auraGroup:SetFrameLevel(self:GetFrameLevel() + 2);
    auraGroup:Show();
    return auraGroup;
end

function UnitFrame.CreateDispellablesFromSettings(self)
    local s = self.settings.DispellableDebuffs;
    local auraGroup = self.auraGroups.dispellable;
    if (auraGroup ~= nil) then
        AuraGroup.Recycle(self.auraGroups.dispellable);
    end
    if (s.Enabled == false) then
        self.auraGroups.dispellable = nil;
        return nil;
    end
    auraGroup = AuraGroup.new(self, self.unit, AuraGroup.Type.DispellableDebuff, s.iconCount, s.iconWidth, s.iconHeight, s.iconSpacing, s.iconZoom);
    self.auraGroups.dispellable = auraGroup;
    AuraGroup.SetUseBlizzardAuraFilter(auraGroup, s.useBlizzardAuraFilter);
    AuraGroup.EnableTooltips(auraGroup, s.EnableAuraTooltips);
    PixelUtil.SetPoint(auraGroup, "BOTTOMLEFT", self.auraGroups.undispellable, "TOPLEFT", 0, 1);
    auraGroup:SetFrameLevel(self:GetFrameLevel() + 2);
    auraGroup:Show();
    return auraGroup;
end

function UnitFrame.CreateBossAurasFromSettings(self)
    local s = self.settings.BossAuras;
    local auraGroup = self.auraGroups.bossAuras;
    if (auraGroup ~= nil) then
        AuraGroup.Recycle(self.auraGroups.bossAuras);
    end
    if (s.Enabled == false) then
        self.auraGroups.bossAuras = nil;
        return nil;
    end
    auraGroup = AuraGroup.new(self, self.unit, AuraGroup.Type.BossAura, s.iconCount, s.iconWidth, s.iconHeight, s.iconSpacing, s.iconZoom);
    self.auraGroups.bossAuras = auraGroup;
    AuraGroup.EnableTooltips(auraGroup, s.EnableAuraTooltips);
    AuraGroup.SetUseBlizzardAuraFilter(auraGroup, s.useBlizzardAuraFilter);
    PixelUtil.SetPoint(auraGroup, "CENTER", self, "CENTER", 0, 0);
    auraGroup:SetFrameLevel(self:GetFrameLevel() + 3);
    auraGroup:Show();
    return auraGroup;
end

function UnitFrame.SetAttribute(self, name, value)
    self:SetAttribute(name, value);
    if (not self.myAttributeList) then self.myAttributeList = {}; end
    self.myAttributeList[name] = value;
end

function UnitFrame.RemoveMyAttributes(self)
    if self.myAttributeList == nil then return; end
    for k, _ in pairs(self.myAttributeList) do
        UnitFrame.SetAttribute(self, k, nil);
    end
end

local _stringTable
function UnitFrame.SetupMouseActions(self)
    local bindings = _mouseActions;
    UnitFrame.RemoveMyAttributes(self);
    UnitFrame.SetAttribute(self, "unit", self.unit);
    for i=1, bindings:Length() do
        local binding = bindings[i];
        if (SettingsUtil.ProcessMouseAction(bindings, i, false) == true) then
            local prefix = "";
            if (binding.alt) then prefix = prefix .. "alt-"; end
            if (binding.ctrl) then prefix = prefix .. "ctrl-"; end
            if (binding.shift) then prefix = prefix .. "shift-" end

            local suffix = binding.button;
            if (binding.type == "spell") then
                UnitFrame.SetAttribute(self, prefix .. binding.type .. suffix, binding.spellId);
            elseif (binding.type == "item") then
                UnitFrame.SetAttribute(self, prefix .. binding.type .. suffix, binding.itemSelector);
            elseif (binding.type == "target") then
            elseif (binding.type == "togglemenu") then
            elseif (binding.type == "focus") then
            else
                error("Couldn't find binding type definition: " .. binding.type);
            end
            UnitFrame.SetAttribute(self, prefix .. "type" .. suffix, binding.type);
            UnitFrame.SetAttribute(self, prefix .. "unit" .. suffix, self.unit);
        end
    end
end

function UnitFrame.SetUnit(self, unit)
    if InCombatLockdown() then error("Cannot call this in combat. You need to delay triggered updates til combat ends.") end;
    UnitFrame.RemoveMyAttributes(self);
    self.displayUnit = unit;
    self.unit = unit;
    self.isPet = string.match(self.unit, "pet[0-9]*") ~= nil;
    self.isBoss = string.match(self.unit, "boss[0-9]*") ~= nil;
    UnitFrame.SetAttribute(self, "unit", unit);
    UnitFrame.RegisterUnitEvents(self);
    UnitFrame.SetupMouseActions(self);
    for _, group in pairs(self.auraGroups) do
        AuraGroup.SetUnit(group, unit);
    end
    RegisterUnitWatch(self);
    UnitFrame.ResetReadyCheck(self);
    UnitFrame.UpdateAll(self);
end

function UnitFrame.EnableScripts(self)
    self:SetScript("OnEvent", UnitFrame.OnEvent);
    --self:SetScript("OnUpdate", UnitFrame.OnUpdate); --currently not required, just left here for quick reimplementation
    UnitFrame.CreateBossPollingTicker(self);
    UnitFrame.CreateRangeCheckTicker(self);
    local readyCheckIcon = self.statusIconContainer.readyCheckIcon;
    if (readyCheckIcon.timerDecay ~= nil) then
        readyCheckIcon.timerDecay:Cancel();
        readyCheckIcon.timerDecay = nil;
    end
    UnitFrame.UpdateReadyCheckStatus(self);
end

function UnitFrame.DisableScripts(self)
    self:SetScript("OnEvent", nil);
    --self:SetScript("OnUpdate", UnitFrame.OnUpdate); --currently not required, just left here for quick reimplementation
    UnitFrame.DisableRangeCheckTicker(self);
    UnitFrame.DisableBossPollingTicker(self);
    
    local readyCheckIcon = self.statusIconContainer.readyCheckIcon;
    if (readyCheckIcon.timerDecay ~= nil) then
        readyCheckIcon.timerDecay:Cancel();
        readyCheckIcon.timerDecay = nil;
    end
    UnitFrame.UpdateReadyCheckStatus(self);
end

function UnitFrame.CreateRangeCheckTicker(self)
    if (self.rangeCheckTicker ~= nil) then
        return;
    end
    if (self.rangeCheckTickerCallback == nil) then
        self.rangeCheckTickerCallback = function() UnitFrame.UpdateInRange(self); end
    end
    self.rangeCheckTicker = C_Timer.NewTicker(self.settings.Frames.RangeCheckThrottleSeconds, self.rangeCheckTickerCallback);
end

function UnitFrame.UpdateRangeCheckTicker(self)
    if (self.rangeCheckTicker ~= nil) then
        self.rangeCheckTicker:Cancel();
        self.rangeCheckTicker = nil;
        UnitFrame.CreateRangeCheckTicker(self);
    end
end

function UnitFrame.DisableRangeCheckTicker(self)
    if (self.rangeCheckTicker ~= nil) then
        self.rangeCheckTicker:Cancel();
        self.rangeCheckTicker = nil;
    end
end

do
    local function UnitFrame_OnShow(self)
        if (not self.isTestMode) then 
            UnitFrame.EnableScripts(self);
            --the group roster update fires sometimes before this, so we have to trigger a manual update
            UnitFrame.UpdateAll(self);
        end
    end
    local function UnitFrame_OnHide(self)
        if (not self.isTestMode) then 
            UnitFrame.DisableScripts(self);
        end
    end
    function UnitFrame.RegisterEvents(self)
        UnitFrame.EnableScripts(self);
        if (self.onShowScript == nil) then
            self.onShowScript = UnitFrame_OnShow;
        end
        self:SetScript("OnShow", self.onShowScript);
        if (self.onHideScript == nil) then
            self.onHideScript = UnitFrame_OnHide;
        end
        self:SetScript("OnHide", self.onHideScript);

        self:RegisterForClicks("AnyDown");
        self:RegisterEvent("PLAYER_ENTERING_WORLD");
        self:RegisterEvent("GROUP_ROSTER_UPDATE");
        self:RegisterEvent("PLAYER_ROLES_ASSIGNED");
        self:RegisterEvent("PLAYER_TARGET_CHANGED");
        self:RegisterEvent("PLAYER_FOCUS_CHANGED");
        self:RegisterEvent("READY_CHECK");
        self:RegisterEvent("READY_CHECK_FINISHED");
        self:RegisterEvent("PARTY_LEADER_CHANGED");
        self:RegisterEvent("PLAYER_REGEN_DISABLED");
        self:RegisterEvent("PLAYER_REGEN_ENABLED");
        self:RegisterEvent("PARTY_MEMBER_DISABLE");
	    self:RegisterEvent("PARTY_MEMBER_ENABLE");
        self:RegisterEvent("RAID_TARGET_UPDATE");
    end
end

function UnitFrame.RegisterUnitEvents(self)
    local unit = self.unit;
	local displayUnit;
	if ( unit ~= self.displayUnit ) then
		displayUnit = self.displayUnit;
    end
    self:RegisterUnitEvent("UNIT_HEALTH", unit, displayUnit);
    self:RegisterUnitEvent("UNIT_FLAGS", unit, displayUnit);
    self:RegisterUnitEvent("UNIT_PHASE", unit, displayUnit);
    self:RegisterUnitEvent("UNIT_MAXHEALTH", unit, displayUnit);
    self:RegisterUnitEvent("UNIT_NAME_UPDATE", unit, displayUnit);
    self:RegisterUnitEvent("UNIT_CONNECTION", unit, displayUnit);
    self:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", unit, displayUnit);
    self:RegisterUnitEvent("UNIT_HEAL_PREDICTION", unit, displayUnit);
    self:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", unit, displayUnit);
    self:RegisterUnitEvent("UNIT_AURA", unit, displayUnit);
    self:RegisterUnitEvent("PLAYER_FLAGS_CHANGED", unit, displayUnit);
    self:RegisterUnitEvent("UNIT_THREAT_SITUATION_UPDATE", unit, displayUnit);
    self:RegisterUnitEvent("INCOMING_RESURRECT_CHANGED", unit, displayUnit);
    self:RegisterUnitEvent("READY_CHECK_CONFIRM", unit, displayUnit);
    self:RegisterUnitEvent("INCOMING_SUMMON_CHANGED", unit, displayUnit);
    self:RegisterUnitEvent("UNIT_MAXPOWER", unit, displayUnit);
    self:RegisterUnitEvent("UNIT_DISPLAYPOWER", unit, displayUnit);
    self:RegisterUnitEvent("UNIT_POWER_UPDATE", unit, displayUnit);
    self:RegisterUnitEvent("UNIT_THREAT_LIST_UPDATE", unit, displayUnit);
    self:RegisterUnitEvent("UNIT_PET", unit, displayUnit);
    self:RegisterUnitEvent("UNIT_CTR_OPTIONS", unit, displayUnit);
end

function UnitFrame.OnEvent(self, event, ...)
    local arg1, arg2, arg3, arg4 = ...;
    if (event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE") then
        UnitFrame.UpdateAll(self);
    elseif (event == "PLAYER_TARGET_CHANGED") then
        if (UnitIsUnit("target", self.unit) or UnitIsUnit("target", self.displayUnit)) then
            UnitFrame.UpdateMaxHealth(self);
            UnitFrame.UpdateHealth(self);
            UnitFrame.UpdateHealthColor(self);
            UnitFrame.UpdateHealthBarExtraInfo(self);
            UnitFrame.UpdateName(self);
        end
        UnitFrame.UpdateTargetHighlight(self);
    elseif (event == "PLAYER_FOCUS_CHANGED") then
        if (UnitIsUnit("focus", self.unit) or UnitIsUnit("focus", self.displayUnit)) then
            UnitFrame.UpdateMaxHealth(self);
            UnitFrame.UpdateHealth(self);
            UnitFrame.UpdateHealthColor(self);
            UnitFrame.UpdateHealthBarExtraInfo(self);
            UnitFrame.UpdateName(self);
            UnitFrame.UpdateAuras(self);
        end
    elseif (event == "PLAYER_ROLES_ASSIGNED") then
        UnitFrame.UpdateRoleIcon(self);
    elseif (event == "PARTY_LEADER_CHANGED") then
        UnitFrame.UpdateRoleIcon(self);
    elseif (event == "READY_CHECK") then
        UnitFrame.UpdateReadyCheckStatus(self);
    elseif (event == "READY_CHECK_FINISHED") then
        UnitFrame.FinishReadyCheck(self);
    elseif (event == "PLAYER_REGEN_DISABLED") then
        --entering combat
        UnitFrame.UpdateAuras(self);    --some auras can be filtered to be hidden in combat
    elseif (event == "PLAYER_REGEN_ENABLED") then
        --leaving combat
        UnitFrame.UpdateAuras(self);    --some auras can be filtered to be hidden in combat
    elseif (event == "PARTY_MEMBER_DISABLE" or event == "PARTY_MEMBER_ENABLE") then	--Alternate power info may now be available.
		UnitFrame.UpdatePowerMax(self);
        UnitFrame.UpdatePower(self);
        UnitFrame.UpdatePowerColor(self);
    elseif (event == "RAID_TARGET_UPDATE") then
        UnitFrame.UpdateRaidTargetIcon(self);
    else
        local eventUnit = arg1;
        if (eventUnit == self.unit or eventUnit == self.displayUnit) then
            if (event == "UNIT_HEALTH") then
                UnitFrame.UpdateHealth(self);
                UnitFrame.UpdateHealthBarExtraInfo(self);
                UnitFrame.UpdateStatusText(self);
            elseif (event == "UNIT_MAXHEALTH") then
                UnitFrame.UpdateMaxHealth(self);
                UnitFrame.UpdateHealth(self);
                UnitFrame.UpdateHealthBarExtraInfo(self);
                UnitFrame.UpdateStatusText(self);
            elseif (event == "UNIT_ABSORB_AMOUNT_CHANGED" or event == "UNIT_HEAL_PREDICTION" or event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED") then
                UnitFrame.UpdateHealthBarExtraInfo(self);
            elseif (event == "UNIT_POWER_UPDATE") then
                UnitFrame.UpdatePower(self);
            elseif (event == "UNIT_MAXPOWER") then
                UnitFrame.UpdatePowerMax(self);
                UnitFrame.UpdatePower(self);
            elseif (event == "UNIT_DISPLAYPOWER") then
                UnitFrame.UpdatePowerMax(self);
                UnitFrame.UpdatePower(self);
                UnitFrame.UpdatePowerColor(self);
            elseif (event == "UNIT_NAME_UPDATE") then
                UnitFrame.UpdateName(self);
                UnitFrame.UpdateHealthColor(self);
            elseif (event == "UNIT_CONNECTION") then
                UnitFrame.UpdateStatusText(self);
                UnitFrame.UpdateHealthColor(self);
                UnitFrame.UpdatePowerColor(self);
                UnitFrame.UpdateMaxHealth(self);
                UnitFrame.UpdateHealth(self);
                UnitFrame.UpdateHealthBarExtraInfo(self);
            elseif (event == "UNIT_AURA") then
                UnitFrame.UpdateAuras(self);
            elseif (event == "PLAYER_FLAGS_CHANGED") then
                UnitFrame.UpdateStatusText(self);
            elseif (event == "UNIT_PHASE" or event == "UNIT_FLAGS" or event == "UNIT_CTR_OPTIONS") then
                self.statusIconContainer.disableLayouting = true;
                UnitFrame.UpdatePhasingStatus(self);
                UnitFrame.UpdateLFGStatus(self);
                self.statusIconContainer.disableLayouting = false;
                UnitFrame.LayoutStatusIcons(self);
                UnitFrame.UpdateStatusText(self);
            elseif (event == "UNIT_THREAT_SITUATION_UPDATE") then
                UnitFrame.UpdateAggroHighlight(self);
            elseif (event == "INCOMING_RESURRECT_CHANGED") then
                UnitFrame.UpdateResurrectionStatus(self);
            elseif (event == "INCOMING_SUMMON_CHANGED") then
                UnitFrame.UpdateSummonStatus(self);
            elseif (event == "READY_CHECK_CONFIRM") then
                UnitFrame.UpdateReadyCheckStatus(self);
            elseif (event == "UNIT_THREAT_LIST_UPDATE") then
                UnitFrame.UpdateHealthColor(self);
                UnitFrame.UpdateName(self);
            elseif (event == "UNIT_PET") then
                UnitFrame.UpdateAll(self);
            end
        end
    end
end

function UnitFrame.UpdateAll(self)
    if (UnitExists(self.displayUnit)) then
        UnitFrame.UpdateName(self);
        UnitFrame.UpdateHealthColor(self);
        UnitFrame.UpdateMaxHealth(self);
        UnitFrame.UpdateHealth(self);
        UnitFrame.UpdatePowerMax(self);
        UnitFrame.UpdatePower(self);
        UnitFrame.UpdatePowerColor(self);
        UnitFrame.UpdateHealthBarExtraInfo(self);
        UnitFrame.UpdateInRange(self);
        UnitFrame.UpdateRoleIcon(self);
        UnitFrame.UpdateTargetHighlight(self);
        UnitFrame.UpdateAggroHighlight(self);
        UnitFrame.UpdateAuras(self);
        UnitFrame.UpdateStatusText(self);
        UnitFrame.UpdateRaidTargetIcon(self);

        self.statusIconContainer.disableLayouting = true;
        UnitFrame.UpdateSummonStatus(self);
        UnitFrame.UpdateLFGStatus(self);
        UnitFrame.UpdatePhasingStatus(self);
        UnitFrame.UpdateReadyCheckStatus(self);
        UnitFrame.UpdateResurrectionStatus(self);
        self.statusIconContainer.disableLayouting = false;
        UnitFrame.LayoutStatusIcons(self);
    end
end

function UnitFrame.UpdateDistance(self)
	local distance, checkedDistance = UnitDistanceSquared(self.displayUnit);

	if (checkedDistance == true) then
		local inDistance = distance < DISTANCE_THRESHOLD_SQUARED;
		if (inDistance ~= self.inDistance) then
			self.inDistance = inDistance;
            UnitFrame.UpdateLFGStatus(self);
            UnitFrame.UpdatePhasingStatus(self);
		end
	end
end

function UnitFrame.UpdateSummonStatus(self)
    local icon = self.statusIconContainer.summonIcon;
    if C_IncomingSummon.HasIncomingSummon(self.unit) then
        local status = C_IncomingSummon.IncomingSummonStatus(self.unit);
        if(status == Enum.SummonStatus.Pending) then
            icon:SetAtlas("Raid-Icon-SummonPending");
        elseif( status == Enum.SummonStatus.Accepted ) then
            icon:SetAtlas("Raid-Icon-SummonAccepted");
        elseif( status == Enum.SummonStatus.Declined ) then
            icon:SetAtlas("Raid-Icon-SummonDeclined");
        end
        if (not icon:IsVisible()) then
            icon:Show();
            UnitFrame.LayoutStatusIcons(self);
        end
    else
        if (icon:IsVisible()) then
            icon:Hide();
            UnitFrame.LayoutStatusIcons(self);
        end
    end
end

function UnitFrame.UpdateLFGStatus(self)
    local icon = self.statusIconContainer.lfgIcon;
---@diagnostic disable-next-line: redundant-parameter
    if UnitInOtherParty(self.unit) then
        if (not icon:IsVisible()) then
            icon:Show();
            UnitFrame.LayoutStatusIcons(self);
        end
    else
        if (icon:IsVisible()) then
            icon:Hide();
            UnitFrame.LayoutStatusIcons(self);
        end
    end
end

function UnitFrame.UpdatePhasingStatus(self)
    local icon = self.statusIconContainer.phasingIcon;
    if self.inDistance and UnitPhaseReason(self.unit) then
        if (not icon:IsVisible()) then
            icon:Show();
            UnitFrame.LayoutStatusIcons(self);
        end
    else
        if (icon:IsVisible()) then
            icon:Hide();
            UnitFrame.LayoutStatusIcons(self);
        end
    end
end

function UnitFrame.UpdateResurrectionStatus(self)
    local icon = self.statusIconContainer.resurrectIcon;
    if UnitHasIncomingResurrection(self.unit) then
        if (not icon:IsVisible()) then
            icon:Show();
            UnitFrame.LayoutStatusIcons(self);
        end
    else
        if (icon:IsVisible()) then
            icon:Hide();
            UnitFrame.LayoutStatusIcons(self);
        end
    end
end

function UnitFrame.ResetReadyCheck(self)
    local icon = self.statusIconContainer.readyCheckIcon;
    icon.readyCheckStatus = nil;
    if (icon.timerDecay ~= nil) then
        icon.timerDecay:Cancel();
        icon.timerDecay = nil;
    end
    UnitFrame.UpdateReadyCheckStatus(self);
end

function UnitFrame.UpdateReadyCheckStatus(self)
    local icon = self.statusIconContainer.readyCheckIcon;
    local show = false;
    if GetReadyCheckTimeLeft() > 0 then
        local readyCheckStatus = GetReadyCheckStatus(self.unit);
        icon.readyCheckStatus = readyCheckStatus;
        if (readyCheckStatus == "ready") then
            icon:SetTexture(READY_CHECK_READY_TEXTURE);
            show = true;
        elseif (readyCheckStatus == "notready") then
            icon:SetTexture(READY_CHECK_NOT_READY_TEXTURE);
            show = true;
        elseif (readyCheckStatus == "waiting") then
            icon:SetTexture(READY_CHECK_WAITING_TEXTURE);
            show = true;
        end
    end
    if (show) then
        if (not icon:IsVisible()) then
            icon:Show();
            UnitFrame.LayoutStatusIcons(self);
        end
    else
        if (icon:IsVisible()) then
            icon:Hide();
            UnitFrame.LayoutStatusIcons(self);
        end
    end
end

do
    local function HideReadyCheckIcon(self)
        local icon = self.statusIconContainer.readyCheckIcon;
        icon.timerDecay = nil;
        UnitFrame.UpdateReadyCheckStatus(self);
    end
    function UnitFrame.FinishReadyCheck(self)
        local icon = self.statusIconContainer.readyCheckIcon;
        if (icon.readyCheckStatus == "waiting") then	--If you haven't responded, you are not ready.
            icon:SetTexture(READY_CHECK_NOT_READY_TEXTURE);
            if (not icon:IsVisible()) then
                icon:Show();
                UnitFrame.LayoutStatusIcons(self);
            end
        end
        if (icon.timerDecayCallback == nil) then
            icon.timerDecayCallback = function() HideReadyCheckIcon(self); end;
        end
        icon.timerDecay = C_Timer.NewTimer(CUF_READY_CHECK_DECAY_TIME, icon.timerDecayCallback);
    end
end

function UnitFrame.UpdateAggroHighlight(self)
    local status = UnitThreatSituation(self.displayUnit);
	if (status and status > 0) then
		self.aggroBorder.children:SetColor(GetThreatStatusColor(status));
		self.aggroBorder:Show();
	else
		self.aggroBorder:Hide();
	end
end

function UnitFrame.UpdateTargetHighlight(self)
    if (UnitIsUnit(self.unit, "target")) then
        self.targetBorder:Show();
    else
        self.targetBorder:Hide();
    end
end

function UnitFrame.UpdateRoleIcon(self)
    local raidID = UnitInRaid(self.unit);
    local _, rank, _, _, _, _, _, _, _, role;
    if (raidID) then
        _, rank, _, _, _, _, _, _, _, role = GetRaidRosterInfo(raidID);
    end
    if (UnitInVehicle(self.unit) and UnitHasVehicleUI(self.unit)) then
        UnitFrame.SetIcon(self, self.roleIcon, "Interface\\Vehicles\\UI-Vehicles-Raid-Icon", 0, 1, 0, 1);
    elseif (raidID and role) then
        UnitFrame.SetIcon(self, self.roleIcon, "Interface\\GroupFrame\\UI-Group-"..role.."Icon", 0, 1, 0, 1);
	else
		local role = UnitGroupRolesAssigned(self.unit);
		if (role == "TANK" or role == "HEALER" or role == "DAMAGER") then
            UnitFrame.SetIcon(self, self.roleIcon, "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES", GetTexCoordsForRoleSmallCircle(role));
		else
			self.roleIcon:Hide();
			PixelUtil.SetSize(self.roleIcon, 1, self.settings.Frames.RoleIconSize);
		end
    end
    if (raidID and rank > 0) then
        if (rank == 1) then
            UnitFrame.SetIcon(self, self.rankIcon, "Interface\\GroupFrame\\UI-Group-AssistantIcon", 0, 1, 0, 1);
        elseif (rank == 2) then
            UnitFrame.SetIcon(self, self.rankIcon, "Interface\\GroupFrame\\UI-Group-LeaderIcon", 0, 1, 0, 1);
        else
            error("Rank evaluated 'true' but not 1 or 2!");
        end
    else
        if (UnitIsGroupLeader(self.unit)) then
            UnitFrame.SetIcon(self, self.rankIcon, "Interface\\GroupFrame\\UI-Group-LeaderIcon", 0, 1, 0, 1);
        else
            self.rankIcon:Hide();
            PixelUtil.SetSize(self.rankIcon, 1, self.settings.Frames.RoleIconSize);
        end
    end
end

function UnitFrame.SetIcon(self, icon, texture, ...)
    local roleIconSize = self.settings.Frames.RoleIconSize;
    icon:SetTexture(texture);
    icon:SetTexCoord(...);
    icon:Show();
    PixelUtil.SetSize(icon, roleIconSize, roleIconSize);
end

function UnitFrame.UpdateStatusText(self)
    local text = self.statusIconContainer.statusText;
    if (self.isPet) then
        text:Hide();
    elseif not UnitIsConnected(self.unit) then
        text:SetText(L["Offline"]);
        text:Show();
    elseif UnitIsDeadOrGhost(self.unit) then
        text:SetText(L["Dead"]);
        text:Show();
    elseif not UnitAffectingCombat("player") and UnitIsAFK(self.unit) then
        text:SetText(L["AFK"]);
        text:Show();
    elseif not UnitAffectingCombat("player") and UnitIsDND(self.unit) then
        text:SetText(L["DND"]);
        text:Show();
    else
        text:Hide();
    end
end

function UnitFrame.UpdateHealth(self)
    if (UnitIsDeadOrGhost(self.displayUnit)) then 
        --otherwise looks weird when somebody is a ghost
        self.healthBar:SetValue(0);
    else
        UnitFrame.SetHealth(self, UnitHealth(self.displayUnit));
    end
end

function UnitFrame.UpdatePower(self)
    if (UnitIsDeadOrGhost(self.displayUnit)) then 
        --otherwise looks weird when somebody is a ghost
        self.powerBar:SetValue(0);
    else
        UnitFrame.SetPower(self, UnitPower(self.displayUnit, nil, true));
    end
end

function UnitFrame.SetPower(self, power)
    if (self.powerBar.enabled ~= true) then
        return;
    end
    self.powerBar:SetValue(power);
end

function UnitFrame.UpdatePowerColor(self)
    if (self.powerBar.enabled ~= true) then
        return;
    end
    local r, g, b;
    if (not UnitIsConnected(self.unit)) then
		--Color it gray
		r, g, b = 0.5, 0.5, 0.5;
	else
        local powerType, powerToken, altR, altG, altB = UnitPowerType(self.displayUnit);
        local info = PowerBarColor[powerToken];
        if (info) then
                r, g, b = info.r, info.g, info.b;
        else
            if (not altR) then
                -- couldn't find a power token entry...default to indexing by power type or just mana if we don't have that either
                info = PowerBarColor[powerType] or PowerBarColor["MANA"];
                r, g, b = info.r, info.g, info.b;
            else
                r, g, b = altR, altG, altB;
            end
        end
    end
    self.powerBar:SetStatusBarColor(r, g, b);
end


function UnitFrame.UpdatePowerMax(self)
    if (self.powerBar.enabled ~= true) then
        return;
    end
    self.powerBar:SetMinMaxValues(0, UnitPowerMax(self.displayUnit, nil, true));
end

do
    local function ProjectNumberRange(value, oldMin, oldMax, newMin, newMax)
        return (((value - oldMin) * (newMax - newMin)) / (oldMax - oldMin)) + newMin; 
    end

    function UnitFrame.SetHealth(self, health)
        local hb = self.healthBar;
        hb:SetValue(health);
        if (self.settings.Frames.BlendToDangerColors) then
            local blendRatio = self.settings.Frames.BlendToDangerColorsRatio;
            local blendMinimum = self.settings.Frames.BlendToDangerColorsMinimum;
            local blendMaximum = self.settings.Frames.BlendToDangerColorsMaximum;
            local _, maxValue = hb:GetMinMaxValues();
            if (maxValue == 0) then
                hb.texture:SetAlpha(1);
                hb.overlay:SetAlpha(0);
                return;
            end
            local ratio = hb:GetValue() / maxValue;
            if (ratio >= blendMaximum) then
                hb.texture:SetAlpha(1);
                hb.overlay:SetAlpha(0);
            elseif (ratio >= blendRatio) then
                local lratio = ProjectNumberRange(ratio, blendRatio, blendMaximum, 0, 1);
                hb.texture:SetAlpha(lratio);
                hb.overlay:SetVertexColor(1, 1, 0, 1 - lratio);
            elseif (ratio <= blendMinimum) then
                hb.texture:SetAlpha(0);
                hb.overlay:SetVertexColor(1, 0, 0, 1);
            elseif (ratio < blendRatio) then
                local lratio = ProjectNumberRange(ratio, blendMinimum, blendRatio, 0, 1);
                hb.overlay:SetVertexColor(1, lratio, 0, 1);
                hb.texture:SetAlpha(0);
            end
            
            hb.overlay:Show();
        else
            hb.texture:SetAlpha(1);
            hb.overlay:Hide();
        end
    end
end

function UnitFrame.UpdateMaxHealth(self)
    local maxHealth = UnitHealthMax(self.displayUnit);
    self.healthBar:SetMinMaxValues(0, maxHealth);
end

do
    local function HideExtraInfos(self)
        self.healPrediction:Hide();
        self.totalAbsorb:Hide();
        self.healAbsorb:Hide();
        self.overAbsorb:Hide();
    end
    function UnitFrame.UpdateHealthBarExtraInfo(self)
        local _, maxHealth = self.healthBar:GetMinMaxValues();
        if (maxHealth <= 0) then
            HideExtraInfos(self);
            return;
        end
        local currentHealth = max(0, self.healthBar:GetValue());
        if (currentHealth == 0) then
            HideExtraInfos(self);
        else
            local incomingHeal = UnitGetIncomingHeals(self.displayUnit) or 0;
            if (incomingHeal == nil) then incomingHeal = 0; end --can happen during a duel, unit is in party but not friendly
            local absorb = UnitGetTotalAbsorbs(self.displayUnit) or 0;
            local healAbsorb = UnitGetTotalHealAbsorbs(self.displayUnit) or 0;
            UnitFrame.SetHealthBarExtraInfo(self, currentHealth, maxHealth, incomingHeal, absorb, healAbsorb);
        end
    end
end

function UnitFrame.SetHealthBarExtraInfo(self, currentHealth, maxHealth, incomingHeal, absorb, healAbsorb)
    local totalWidth = self.healthBar:GetWidth();
    if (currentHealth == maxHealth and absorb == 0) then
        self.totalAbsorb:Hide();
        self.healPrediction:Hide();
        self.overAbsorb:Hide();
    else
        local nextAnchorFrame, overAmount;
        local remainingEmptyHealth = maxHealth - currentHealth;
        remainingEmptyHealth, nextAnchorFrame, overAmount = UnitFrame.ProcessHealthBarExtraInfoBar(self.healPrediction, incomingHeal, self.healthBar:GetStatusBarTexture(), remainingEmptyHealth, maxHealth, totalWidth);
        if (overAmount > 0) then
            --overcapped heal prediction
        end
        remainingEmptyHealth, nextAnchorFrame, overAmount = UnitFrame.ProcessHealthBarExtraInfoBar(self.totalAbsorb, absorb, nextAnchorFrame, remainingEmptyHealth, maxHealth, totalWidth);
        if (overAmount > 0) then
            --overcapped absorbs
            self.overAbsorb:Show();
        else
            self.overAbsorb:Hide();
        end
    end
    if (healAbsorb == 0) then
        self.healAbsorb:Hide();
    else
        if (healAbsorb > currentHealth) then
            healAbsorb = currentHealth;
        end
        local healAbsorbWidth = (healAbsorb / maxHealth) * totalWidth;
        PixelUtil.SetWidth(self.healAbsorb, healAbsorbWidth);
        self.healAbsorb:Show();
    end
end

function UnitFrame.ProcessHealthBarExtraInfoBar(texture, amount, previousFrame, remainingEmptyHealth, maxLife, barWidth)
    local overAmount = 0;
    if (amount == 0 or remainingEmptyHealth == 0) then
        texture:Hide();
        return remainingEmptyHealth, previousFrame, amount;
    elseif (amount > remainingEmptyHealth) then
        overAmount = amount - remainingEmptyHealth;
        amount = remainingEmptyHealth;
        remainingEmptyHealth = 0;
    else
        remainingEmptyHealth = remainingEmptyHealth - amount;
    end
    
    local width = (amount / maxLife) * barWidth;
    texture:SetPoint("TOPLEFT", previousFrame, "TOPRIGHT", 0, 0);
    texture:SetPoint("BOTTOMLEFT", previousFrame, "BOTTOMRIGHT", 0, 0);
    texture:SetWidth(width);
    texture:Show();
    return remainingEmptyHealth, texture, overAmount;
end

function UnitFrame.UpdateName(self)
    local name = GetUnitName(self.displayUnit, self.settings.Frames.DisplayServerNames);
    self.name:SetText(name);
end

function UnitFrame.IsTapDenied(self)
	return not UnitPlayerControlled(self.unit) and UnitIsTapDenied(self.unit);
end

function UnitFrame.UpdateHealthColor(self)
	local r, g, b;
	if (not UnitIsConnected(self.unit) ) then
		--Color it grey
		r, g, b = 0.5, 0.5, 0.5;
	else
        --Try to color it by class.
        local _, englishClass = UnitClass(self.unit);
        local classColor = RAID_CLASS_COLORS[englishClass];
        local isPlayer = UnitIsPlayer(self.unit);
        
        if (isPlayer and UnitIsEnemy("player", self.unit) and classColor) then
            -- e.g. Mind Controlled
            -- use class colors for now 
            r, g, b = classColor.r, classColor.g, classColor.b;
        elseif ((isPlayer or UnitTreatAsPlayerForDisplay(self.unit)) and classColor) then
            -- Use class colors for players if class color option is turned on
            r, g, b = classColor.r, classColor.g, classColor.b;
        elseif (UnitFrame.IsTapDenied(self)) then
            -- Use grey if not a player and can't get tap on unit
            r, g, b = 0.9, 0.9, 0.9;
        elseif (self.isPet) then
            r, g, b = 0.0, 0.75, 0.0;
        elseif (not isPlayer and UnitIsFriend("player", self.unit)) then
            r, g, b = UnitSelectionColor(self.unit, true);
        else
            r, g, b = 0.9, 0.0, 0.0;
        end
    end
    UnitFrame.SetHealthColor(self, r, g, b);
end

function UnitFrame.SetHealthColor(self, r, g, b)
    if (r ~= self.healthBar.r or g ~= self.healthBar.g or b ~= self.healthBar.b) then
		self.healthBar:SetStatusBarColor(r, g, b);
		self.healthBar.r, self.healthBar.g, self.healthBar.b = r, g, b;
	end
end

function UnitFrame.SetPowerColor(self, r, g, b)
    if (r ~= self.powerBar.r or g ~= self.powerBar.g or b ~= self.powerBar.b) then
		self.powerBar:SetStatusBarColor(r, g, b);
		self.powerBar.r, self.powerBar.g, self.powerBar.b = r, g, b;
	end
end

function UnitFrame.UpdateInRange(self)
    local inRange, checkedRange = UnitInRange(self.displayUnit);
    if (checkedRange and not inRange) then
        UnitFrame.SetInRange(self, false);
    else
        UnitFrame.SetInRange(self, true);
    end
end

function UnitFrame.SetInRange(self, isInRange)
    if (isInRange) then
        self:SetAlpha(1);
    else
        self:SetAlpha(self.settings.Frames.OutOfRangeAlpha);
    end
end

function UnitFrame.UpdateAuras(self)
    AuraManager.LoadUnitAuras(self.displayUnit);
    local groups = self.auraGroups;

    --can't iterate over groups because the order is important for aura duplicate checking
    if (groups.specialClassDisplay ~= nil) then AuraGroup.Update(groups.specialClassDisplay) end;
    if (groups.defensives ~= nil) then AuraGroup.Update(groups.defensives) end;
    if (groups.undispellable ~= nil) then AuraGroup.Update(groups.undispellable) end;
    if (groups.dispellable ~= nil) then AuraGroup.Update(groups.dispellable) end;
    if (groups.bossAuras ~= nil) then AuraGroup.Update(groups.bossAuras) end;
    if (groups.buffs ~= nil) then AuraGroup.Update(groups.buffs) end;
end

function UnitFrame.CreateSpecialClassDisplays()
    if (next(_unitFrames) == nil) then return; end;
    local requiredDisplays = SettingsUtil.GetSpecialClassDisplays();
    if (requiredDisplays == nil) then return end
    for _, frame in pairs(_unitFrames) do
        UnitFrame.CreateSpecialClassDisplayFromSettings(frame, requiredDisplays);
    end
end

function UnitFrame.CreateBossPollingTicker(self)
    if (not self.isBoss) then
        return;
    end
    if (self.bossUpdateTickerCallback == nil) then
        self.bossUpdateTickerCallback = function() 
            if (UnitExists(self.unit)) then
                UnitFrame.UpdateMaxHealth(self);
                UnitFrame.UpdateHealth(self);
                UnitFrame.UpdateHealthColor(self);
                UnitFrame.UpdateHealthBarExtraInfo(self);
                UnitFrame.UpdateAuras(self);
            end
        end
    end

    if (self.bossUpdateTicker == nil) then
        self.bossUpdateTicker = C_Timer.NewTicker(self.settings.Frames.BossPollingThrottleSeconds, self.bossUpdateTickerCallback);
    end
end

function UnitFrame.UpdateBossPollingTicker(self)
    UnitFrame.DisableBossPollingTicker(self);
    UnitFrame.CreateBossPollingTicker(self);
end

function UnitFrame.DisableBossPollingTicker(self)
    if (self.bossUpdateTicker ~= nil) then
        self.bossUpdateTicker:Cancel();
        self.bossUpdateTicker = nil;
    end
end

function UnitFrame.UpdateAllMouseActions()
    for _, frame in pairs(_unitFrames) do
        UnitFrame.SetupMouseActions(frame);
    end
end

function UnitFrame.PlayerInfoChanged()
    UnitFrame.CreateSpecialClassDisplays();
    LoadMouseActionsForSpec();
end
