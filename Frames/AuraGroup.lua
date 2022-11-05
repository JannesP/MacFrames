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
local AuraFrame = _p.AuraFrame;
local MyAuraUtil = _p.MyAuraUtil;
local AuraManager = _p.AuraManager;
local AuraBlacklist = _p.AuraBlacklist;
local TablePool = _p.TablePool;
local PixelPerfect = _p.PixelPerfect;
local FrameUtil = _p.FrameUtil;

local math_min, table_sort = math.min, table.sort;

local _framePool = _p.FramePool.Create();

local AuraGroup = {};
_p.AuraGroup = AuraGroup;

AuraGroup.Type = {
    DispellableDebuff = "debuffDispellable",
    UndispellableDebuff = "debuffUndispellable",
    BossAura = "bossAuras",
    DefensiveBuff = "buffDefensive",
    Buff = "buff",
    PredefinedAuraSet = "predefinedAuraSet",
}

local function CreateAuraFrame(self)
    local auraFrame = AuraFrame.new(self, self.iconWidth, self.iconHeight, self.iconZoom);
    auraFrame.displayingAura = false;
    AuraFrame.SetColoringMode(auraFrame, self.coloringMode, self.customColor.r, self.customColor.g, self.customColor.b, self.customColor.a);
    tinsert(self.auraFrames, auraFrame);
    return auraFrame;
end

local function LayoutFrames(self)
    local auraFrames = self.auraFrames;
    local frameCount = #auraFrames;
    local spacing = self.spacing;
    local iconWidth, iconHeight = self.iconWidth, self.iconHeight;
    if (frameCount > 0) then
        iconWidth, iconHeight = auraFrames[1]:GetSize();
    end
    PixelPerfect.SetSize(self, (iconWidth * frameCount) + (spacing * (frameCount - 1)), iconHeight);

    local lastFrame = nil;
    if (self.reverse == true) then
        for i=1,frameCount do
            local auraFrame = auraFrames[i];
            auraFrame:ClearAllPoints();
            if (lastFrame == nil) then
                PixelPerfect.SetPoint(auraFrame, "TOPRIGHT", self, "TOPRIGHT", 0, 0);
            else
                PixelPerfect.SetPoint(auraFrame, "TOPRIGHT", lastFrame, "TOPLEFT", -spacing, 0);
            end
            lastFrame = auraFrame;
        end
    else
        for i=1,frameCount do
            local auraFrame = auraFrames[i];
            auraFrame:ClearAllPoints();
            if (lastFrame == nil) then
                PixelPerfect.SetPoint(auraFrame, "TOPLEFT", self, "TOPLEFT", 0, 0);
            else
                PixelPerfect.SetPoint(auraFrame, "TOPLEFT", lastFrame, "TOPRIGHT", spacing, 0);
            end
            lastFrame = auraFrame;
        end
    end
end

function AuraGroup.new(parent, unit, auraGroupType, count, iconWidth, iconHeight, spacing, iconZoom)
    local frame = _framePool:Take();
    if frame == nil then
        frame = CreateFrame("Frame", nil, parent);
        frame.customColor = {};
    else
        frame:SetParent(parent);
    end
    frame.unit = unit;
    frame.auraGroupType = auraGroupType;

    frame.iconWidth = iconWidth;
    frame.iconHeight = iconHeight;
    frame.spacing = spacing;
    frame.iconZoom = iconZoom;

    frame.useFixedPositions = false;
    frame.predefinedAuras = nil;

    frame.useBlizzardAuraFilter = false;
    frame.reverse = false;
    frame.ignoreBlacklist = false;
    frame.allowDisplayed = false;
    frame.enableTooltips = false;

    if (frame.auraFrames == nil) then
        frame.auraFrames = {};
    else
        if #frame.auraFrames ~= 0 then
            error("A frame from the pool shouldn't have any auraFrames!");
        end
    end

    if (auraGroupType == AuraGroup.Type.DispellableDebuff or auraGroupType == AuraGroup.Type.UndispellableDebuff or auraGroupType == AuraGroup.Type.BossAura) then
        AuraGroup.SetColoringMode(frame, AuraFrame.ColoringMode.Debuff);
    elseif (auraGroupType == AuraGroup.Type.DefensiveBuff) then
        AuraGroup.SetColoringMode(frame, AuraFrame.ColoringMode.Custom, 1, 1, 0, 1);
    elseif (auraGroupType == AuraGroup.Type.PredefinedAuraSet or auraGroupType == AuraGroup.Type.Buff) then
        AuraGroup.SetColoringMode(frame, AuraFrame.ColoringMode.Custom, .5, .5, .5, 1);
    else
        error("Each AuraGroup type requires an aura color setting! Missing for: " .. tostring(auraGroupType));
    end

    for i=1, (count or 0) do
        CreateAuraFrame(frame);
    end
    LayoutFrames(frame);
    return frame;
end

function AuraGroup.SetColoringMode(self, mode, r, g, b, a)
    self.coloringMode = mode;
    local c = self.customColor;

    c.r = r or 0;
    c.g = g or 0;
    c.b = b or 0;
    c.a = a or 1;

    for i=1,#self.auraFrames do
        AuraFrame.SetColoringMode(self.auraFrames[i], mode, c.r, c.g, c.b, c.a);
    end
end

function AuraGroup.Recycle(self)
    local af = self.auraFrames;
    for i=1, #af do
        AuraFrame.Recycle(af[i]);
    end
    wipe(self.auraFrames);
    _framePool:Put(self);
end

function AuraGroup.SetUnit(self, unit)
    self.unit = unit;
end

function AuraGroup.SetIgnoreBlacklist(self, ignoreBlacklist)
    self.ignoreBlacklist = ignoreBlacklist;
end

function AuraGroup.SetAllowDisplayedAuras(self, allowDisplayed)
    self.allowDisplayed = allowDisplayed;
end

function AuraGroup.SetUseFixedPositions(self, useFixedPositions)
    if (self.auraGroupType ~= AuraGroup.Type.PredefinedAuraSet) then error("Cannot set fixed position when not configured for " .. AuraGroup.Type.PredefinedAuraSet .. ".") end;
    self.useFixedPositions = useFixedPositions;
    LayoutFrames(self);
end

function AuraGroup.SetUseBlizzardAuraFilter(self, useBlizzardAuraFilter)
    self.useBlizzardAuraFilter = useBlizzardAuraFilter;
end

function AuraGroup.SetPredefinedAuras(self, auraList)
    self.predefinedAuras = auraList;
    AuraGroup.SetCount(self, #auraList);
end

function AuraGroup.EnableTooltips(self, enableFlag)
    if (enableFlag == nil) then
        enableFlag = true;
    end
    local auraFrames = self.auraFrames;
    self.enableTooltips = enableFlag;
    for i=1,#auraFrames do
        local auraFrame = auraFrames[i];
        AuraFrame.EnableTooltip(auraFrame, enableFlag);
    end
end

function AuraGroup.SetReverseOrder(self, reverse)
    self.reverse = reverse;
    LayoutFrames(self);
end

function AuraGroup.SetCount(self, count)
    local countChanged = false;
    while(#self.auraFrames < #self.predefinedAuras) do
        CreateAuraFrame(self);
        countChanged = true;
    end
    while(#self.auraFrames > #self.predefinedAuras) do
        AuraFrame.Recycle(self.auraFrames[#self.auraFrames]);
        self.auraFrames[#self.auraFrames] = nil;
        countChanged = true;
    end
    if (countChanged) then
        LayoutFrames(self);
    end
end

do
    local testDispellable = { 
        nil,
        136118,
        3,
        "Magic",
        10000,
        GetTime() - 3500,
    };
    local testUndispellable = { 
        nil,
        136113,
        3,
        "none",
        10000,
        GetTime() - 3500,
    };
    local testBoss = { 
        nil,
        1769069,
        3,
        "none",
        10000,
        GetTime() - 3500,
    };
    local testDefensive = { 
        nil,
        135936,
        3,
        "none",
        10000,
        GetTime() - 3500,
    };
    local testBuff = { 
        nil,
        135987,
        3,
        "none",
        10000,
        GetTime() - 3500,
    };
    local testSpecial = {
        nil,
        458720,
        3,
        "none",
        10000,
        GetTime() - 3500,
    }
    function AuraGroup.SetTestMode(self, enabled)
        if (enabled == true) then
            local types = AuraGroup.Type;
            
            local auraFrames = self.auraFrames;
            if (self.auraGroupType == types.PredefinedAuraSet) then
                AuraGroup.SetCount(self, #self.auraGroupType);
                local aura = testSpecial;
                for i=1, #self.predefinedAuras do
                    aura[2] = select(3, GetSpellInfo(self.predefinedAuras[i].spellId));
                    AuraFrame.SetTestAura(auraFrames[i], unpack(aura));
                end
            else
                local aura;
                if self.auraGroupType == types.DispellableDebuff then
                    aura = testDispellable;
                elseif self.auraGroupType == types.UndispellableDebuff then
                    aura = testUndispellable;
                elseif self.auraGroupType == types.BossAura then
                    aura = testBoss;
                elseif self.auraGroupType == types.DefensiveBuff then
                    aura = testDefensive;
                elseif self.auraGroupType == types.Buff then
                    aura = testBuff;
                else
                    error("invalid AuraGroup.Type: " .. self.auraGroupType);
                end
                for i=1, #auraFrames do
                    AuraFrame.SetTestAura(auraFrames[i], unpack(aura));
                end
            end
            
        else
            AuraGroup.Update(self);
        end
    end
end

do
    --The following two functions are literally copied from CompactUnitFrame_UtilShouldDisplayBuff and CompactUnitFrame_Util_ShouldDisplayDebuff.
    --For some reason they work here but not in CompactUnitFrame.lua
    local function ShouldDisplayDebuff(...)
        local _, _, _, _, _, _, unitCaster, _, _, spellId, canApplyAura = ...;
        local hasCustom, alwaysShowMine, showForMySpec = SpellGetVisibilityInfo(spellId, UnitAffectingCombat("player") and "RAID_INCOMBAT" or "RAID_OUTOFCOMBAT");
        if (hasCustom) then
            return showForMySpec or (alwaysShowMine and (unitCaster == "player" or unitCaster == "pet" or unitCaster == "vehicle"));	--Would only be "mine" in the case of something like forbearance.
        else
            return true;
        end
    end

    local function ShouldDisplayBuff(...)
        local _, _, _, _, _, _, unitCaster, _, _, spellId, canApplyAura = ...;
        if (spellId == 320224) then return true; end --Podtender
        if (spellId == 27827) then return true; end --Spirit of Redemption
        local hasCustom, alwaysShowMine, showForMySpec = SpellGetVisibilityInfo(spellId, UnitAffectingCombat("player") and "RAID_INCOMBAT" or "RAID_OUTOFCOMBAT");
        if (hasCustom) then
            return showForMySpec or (alwaysShowMine and (unitCaster == "player" or unitCaster == "pet" or unitCaster == "vehicle"));
        else
            return (unitCaster == "player" or unitCaster == "pet" or unitCaster == "vehicle") and canApplyAura and not SpellIsSelfBuff(spellId);
        end
    end

    local function IsAllowedBySettings(self, slot, info, ...)
        local result = true;        
        if (not self.ignoreBlacklist and AuraBlacklist[select(10, ...)] == true) then
            result = false;
        elseif (not self.allowDisplayed and info.displayed) then
            result = false;
        else
            if (self.useBlizzardAuraFilter == true) then
                if (info.isDebuff == true) then
                    result = ShouldDisplayDebuff(...);
                else
                    result = ShouldDisplayBuff(...);
                end
            end
        end
        return result;
    end
    local function DisplayInFrame(self, frameIndex, auraSlot, ...)
        local auraFrame = self.auraFrames[frameIndex];
        auraFrame.displayingAura = true;
        AuraFrame.DisplayAura(auraFrame, self.unit, auraSlot, ...);
    end
    local _auraTablePool = TablePool.Create(function(table)
        wipe(table);
    end);
    local _auraList = {};
    local function ClearAuraList()
        for _, aura in pairs(_auraList) do
            _auraTablePool:Put(aura);
        end
        wipe(_auraList);
    end
    local function SetInAuraList(index, slot, info, priority, ...)
        local holder = _auraTablePool:Take();
        local auraLength = select('#', ...);
        for i=1,auraLength do
            holder[i] = select(i, ...);
        end
        holder.n = auraLength;
        holder.slot = slot;
        holder.priority = priority;
        holder.info = info;
        _auraList[index] = holder;
    end
    do
        local frame, displayedCount, frameCount;
        local function NormalDisplayAuraFunc(slot, info, ...)
            if (IsAllowedBySettings(frame, slot, info, ...)) then
                --info.displayed = true;
                displayedCount = displayedCount + 1;
                DisplayInFrame(frame, displayedCount, slot, ...);
                if (frameCount <= displayedCount) then
                    return true;
                end
            end
            return false;
        end
        local function DefensiveBuffAuraFunc(slot, info, priority, ...)
            if (IsAllowedBySettings(frame, slot, info, ...)) then
                SetInAuraList(#_auraList + 1, slot, info, priority, ...);
            end
            return false;
        end
        local _predefinedDebuffCount = 0;
        local _predefinedBuffCount = 0;
        local _predefinedIteratingDebuffs = false;
        local function PredefinedAuraSetFunc(slot, info, ...)
            if (IsAllowedBySettings(frame, slot, info, ...)) then
                for i=1, #frame.predefinedAuras do
                    local predefined = frame.predefinedAuras[i];
                    if (select(10, ...) == predefined.spellId) then
                        if (predefined.onlyByPlayer == true and info.byPlayer == false) then
                            break;
                        end
                        if (predefined.enabled == false) then
                            break;
                        end
                        if (predefined.hideInCombat == true and UnitAffectingCombat("player")) then
                            break;
                        end
                        SetInAuraList(i, slot, info, nil, ...);
                        if (_predefinedIteratingDebuffs) then
                            _predefinedDebuffCount = _predefinedDebuffCount - 1;
                            if (_predefinedDebuffCount == 0) then
                                return true;
                            end
                        else
                            _predefinedBuffCount = _predefinedBuffCount - 1;
                            if (_predefinedBuffCount == 0) then
                                return true;
                            end
                        end
                        return false;
                    end 
                end
            end
            return false;
        end
        local function CompareAuraPriority(a, b)
            return a.priority > b.priority;
        end
        function AuraGroup.Update(self)
            frame = self;
            displayedCount = 0;

            frameCount = #self.auraFrames;
            for i=1, frameCount do
                self.auraFrames[i].displayingAura = false;
            end
            
            local types = AuraGroup.Type;
            if self.auraGroupType == types.DispellableDebuff then
                AuraManager.ForAllDispellableDebuffs(self.unit, NormalDisplayAuraFunc);
            elseif self.auraGroupType == types.UndispellableDebuff then
                AuraManager.ForAllUndispellableDebuffs(self.unit, NormalDisplayAuraFunc);
            elseif self.auraGroupType == types.BossAura then
                AuraManager.ForAllBossAuras(self.unit, NormalDisplayAuraFunc);
            elseif self.auraGroupType == types.Buff then
                AuraManager.ForAllBuffs(self.unit, NormalDisplayAuraFunc);
            elseif self.auraGroupType == types.DefensiveBuff then
                ClearAuraList();
                AuraManager.ForAllDefensiveBuffs(self.unit, DefensiveBuffAuraFunc);
                table_sort(_auraList, CompareAuraPriority);
                for i=1, math_min(#_auraList, frameCount) do
                    local aura = _auraList[i];
                    aura.info.displayed = true;
                    displayedCount = displayedCount + 1;
                    DisplayInFrame(self, displayedCount, aura.slot, unpack(aura));
                end
            elseif self.auraGroupType == types.PredefinedAuraSet then
                if (self.predefinedAuras ~= nil) then
                    ClearAuraList();
                    local predefinedAuraCount = #self.predefinedAuras;
                    AuraGroup.SetCount(self, predefinedAuraCount);

                    _predefinedDebuffCount = 0;
                    _predefinedBuffCount = 0;
                    for i=1, predefinedAuraCount do
                        if (self.predefinedAuras[i].debuff == true) then
                            _predefinedDebuffCount = _predefinedDebuffCount + 1;
                        else
                            _predefinedBuffCount = _predefinedBuffCount + 1;
                        end
                    end
                    if (_predefinedDebuffCount > 0) then
                        _predefinedIteratingDebuffs = true;
                        AuraManager.ForAllDebuffs(self.unit, PredefinedAuraSetFunc);
                    end
                    if (_predefinedBuffCount > 0) then
                        _predefinedIteratingDebuffs = false;
                        AuraManager.ForAllBuffs(self.unit, PredefinedAuraSetFunc);
                    end
                    if (self.useFixedPositions) then
                        for i=1, predefinedAuraCount do
                            local aura = _auraList[i];
                            if (aura ~= nil) then
                                DisplayInFrame(self, i, aura.slot, unpack(aura));
                                aura.info.displayed = true;
                            end
                        end
                    else
                        for i=1, predefinedAuraCount do
                            local aura = _auraList[i];
                            if (aura ~= nil) then
                                displayedCount = displayedCount + 1;
                                DisplayInFrame(self, displayedCount, aura.slot, unpack(aura));
                                aura.info.displayed = true;
                            end
                        end
                    end
                end
            else
                error("invalid AuraGroup.Type: " .. self.auraGroupType);
            end
            --hide frames that aren't in use
            for i=1, frameCount do
                local auraFrame = self.auraFrames[i];
                if auraFrame.displayingAura ~= true then
                    auraFrame:Hide();
                end
            end
        end
    end
end
