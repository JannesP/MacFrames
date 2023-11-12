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
local MyAuraUtil = _p.MyAuraUtil;
local AuraManager = _p.AuraManager;
local FrameUtil = _p.FrameUtil;
local PixelPerfect = _p.PixelPerfect;

local AuraFrame = {};
_p.AuraFrame = AuraFrame;
AuraFrame.ColoringMode = {
    None = "none",
    Custom = "custom",
    Debuff = "debuff",
    Buff = "buff",
};
local ColoringMode = AuraFrame.ColoringMode;

local _framePool = _p.FramePool.Create();

function AuraFrame.new(parent, width, height, zoom)
    local frame = _framePool:Take();
    if (frame == nil) then
        frame = CreateFrame("Frame", nil, parent, "MacFramesUnitFrameAuraTemplate");
        frame:SetScript("OnEnter", AuraFrame.DisplayTooltip);
        frame:SetScript("OnLeave", AuraFrame.HideTooltip);
        frame.iconOverlay:SetBlendMode("BLEND");
        frame.iconOverlay:SetColorTexture(.15, .95, .3, .7);
        AuraFrame.EnableTooltip(frame, false);
    else
        frame:SetParent(parent);
    end
    PixelPerfect.SetSize(frame, width, height);

    frame.pinnedAura = nil;
    frame.cooldown:SetDrawEdge(false);
    frame.cooldown:SetHideCountdownNumbers(true);
    frame.cooldown:Resume();

    frame.coloringMode = ColoringMode.Debuff;

    if (zoom == nil) then
        frame.icon:SetTexCoord(0,1,0,1);
    else
        frame.icon:SetTexCoord(_p.FrameUtil.GetIconZoomTransform(zoom));
    end

    if (frame.borderHost == nil) then
        frame.borderHost = CreateFrame("Frame", nil, frame);
        frame.borderHost:SetAllPoints();
        frame.borderHost:Hide();
        frame.borderHost.api = FrameUtil.CreateSolidBorder(frame.borderHost, 1, 0, 0, 0, 1);
        
    end

    PixelPerfect.SetPoint(frame.icon, "TOPLEFT", frame, "TOPLEFT", 1, -1);
    PixelPerfect.SetPoint(frame.icon, "BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1);
    frame.icon:SetDrawLayer("ARTWORK", 2);
    frame.iconOverlay:SetDrawLayer("ARTWORK", 3);
    frame.iconOverlay:SetAllPoints(frame.icon);
    frame.cooldown:SetAllPoints(frame.icon);

    frame:Hide();
    return frame;
end

function AuraFrame.SetTestAura(self, ...)
    if (select('#', ...) > 0) then
        AuraFrame.DisplayAura(self, nil, nil, ...);
        self.cooldown:Pause();
    else
        AuraFrame.DisplayAura(self);
    end
end

function AuraFrame.SetColoringMode(self, coloringMode, ...)
    self.coloringMode = coloringMode;
    if (coloringMode == ColoringMode.None) then
        self.borderHost:Hide();
    else
        if (coloringMode == ColoringMode.Custom) then
            self.borderHost.api:SetColor(...);
            self.borderHost:Show();
        elseif (coloringMode == ColoringMode.Debuff) then
            self.borderHost.api:SetColor(1, 0, 0, 1);
            self.borderHost:Show();
        elseif (coloringMode == ColoringMode.Buff) then
            self.borderHost.api:SetColor(0.2, 0.9, 0.9, 1);
            self.borderHost:Show();
        else
            self.borderHost.api:SetColor(0, 1, 1, 1);
            self.borderHost:Show();
        end
    end
end

function AuraFrame.Recycle(self)
    _framePool:Put(self);
end

function AuraFrame.SetPinnedAuraWithId(self, unit, auraId, debuff, onlyByPlayer)
    self.pinnedAura = {
        unit = unit,
        id = auraId,
        debuff = debuff,
        onlyByPlayer = onlyByPlayer,
    };
    local _, _, spellIcon = GetSpellInfo(auraId);
    self.icon:SetTexture(spellIcon);
    self:Hide();
end

do
    local frame, pinnedAura, displayed;
    local function ProcessAuraFunc(slot, info, ...)
        if (not pinnedAura.onlyByPlayer or info.byPlayer) then
            info.displayed = true;
            displayed = true;
            AuraFrame.DisplayAura(frame, pinnedAura.unit, slot, ...);
            return true;
        end
        return false;
    end
    function AuraFrame.UpdateFromPinnedAura(self)
        frame = self;
        pinnedAura = self.pinnedAura;
        displayed = false;

        if pinnedAura.debuff == true then
            AuraManager.ForAllDebuffsByAuraId(pinnedAura.unit, pinnedAura.id, ProcessAuraFunc);
        else
            AuraManager.ForAllBuffsByAuraId(pinnedAura.unit, pinnedAura.id, ProcessAuraFunc);
        end
        if (not displayed) then
            self:Hide();
        end
    end
end

function AuraFrame.SetBackgroundColor(self, debuffType)
    if (self.coloringMode == ColoringMode.Debuff) then
        local color = DebuffTypeColor[debuffType] or DebuffTypeColor["none"];
        self.borderHost.api:SetColor(color.r, color.g, color.b);
    end
end

function AuraFrame.GetDisplayedAuraInformation(self)
    if (self.auraSlot == nil) then return nil; end
    local color = DebuffTypeColor[self.auraDebuffType];
    return self.auraSlot, self.auraSpellId, color;
end
do
    local hasRShamSetBuff;
    local function ProcessRestoShamanTiersetBuff(_, info, ...)
        if (info.byPlayer) then
            hasRShamSetBuff = true;
            return true;
        end
        return false;
    end
    function AuraFrame.DisplayAura(self, unit, slot, ...)
        local _, icon, stacks, debuffType, duration, expirationTime = ...;
        if (icon == nil or duration == nil or expirationTime == nil) then
            self.unit = nil;
            self.auraSlot = nil;
            self.auraSpellId = nil;
            self.auraDebuffType = nil;
            self:Hide();
        else
            AuraFrame.SetBackgroundColor(self, debuffType);
            self.unit = unit;
            self.auraSlot = slot;
            self.auraSpellId = select(10, ...);
            self.auraDebuffType = debuffType;
            self.icon:SetTexture(icon);
            self.cooldown:SetCooldown(expirationTime - duration, duration);
            self.cooldown:Resume();
            self:Show();

            --resto shaman 10.2 tier set handling
            self.iconOverlay:Hide();
            if (self.auraSpellId == 61295) then --riptide
                if (expirationTime - GetTime() > 14) then
                    hasRShamSetBuff = false;
                    AuraManager.ForAllBuffsByAuraId(self.unit, 424461, ProcessRestoShamanTiersetBuff);
                    if (not hasRShamSetBuff) then
                        self.iconOverlay:Show();
                    end
                end
            end

            if (GameTooltip:IsOwned(self)) then
                AuraFrame.DisplayTooltip(self);
            end

            if (stacks > 0) then
                self.count:SetText(stacks);
                self.count:Show();
            else
                self.count:Hide();
            end
        end
    end
end

function AuraFrame.EnableTooltip(self, enableFlag)
    self:EnableMouse(enableFlag);
end

function AuraFrame.DisplayTooltip(self)
    if (self.auraSlot ~= nil) then
        GameTooltip_SetDefaultAnchor(GameTooltip, self);
        GameTooltip:SetSpellByID(self.auraSpellId);
        GameTooltip:Show();
    else
        AuraFrame.HideTooltip(self);
    end
end

function AuraFrame.HideTooltip(self)
    if (GameTooltip:IsOwned(self)) then
        GameTooltip:Hide();
    end
end

function AuraFrame.Hide(self)
    AuraFrame.HideTooltip(self);
    self.unit = nil;
    self.auraSlot = nil;
    self.auraSpellId = nil;
    self.auraDebuffType = nil;
    self:Hide();
end