local ADDON_NAME, _p = ...;
local MyAuraUtil = _p.MyAuraUtil;
local AuraManager = _p.AuraManager;

local AuraFrame = {};
_p.AuraFrame = AuraFrame;
AuraFrame.ColoringMode = {
    Custom = "custom",
    Debuff = "debuff",
    Buff = "buff",
};
local ColoringMode = AuraFrame.ColoringMode;

local _framePool = _p.FramePool.new();

function AuraFrame.new(parent, width, height, zoom)
    local frame = _framePool:Take();
    if (frame == nil) then
        frame = CreateFrame("Frame", nil, parent, "MacFramesUnitFrameAuraTemplate");
    else
        frame:SetParent(parent);
    end
    PixelUtil.SetSize(frame, width, height);
    
    frame.pinnedAura = nil;
    frame.cooldown:SetDrawEdge(false);
    frame.cooldown:SetHideCountdownNumbers(true);

    frame.coloringMode = ColoringMode.Debuff;

    if (zoom == nil) then
        frame.icon:SetTexCoord(0,1,0,1);
    else
        frame.icon:SetTexCoord(_p.PixelUtil.GetIconZoomTransform(zoom));
    end

    PixelUtil.SetPoint(frame.icon, "TOPLEFT", frame, "TOPLEFT", 1, -1);
    PixelUtil.SetPoint(frame.icon, "BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1);

    PixelUtil.SetPoint(frame.cooldown, "TOPLEFT", frame, "TOPLEFT", 1, -1);
    PixelUtil.SetPoint(frame.cooldown, "BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1);

    frame:Hide();
    return frame;
end

function AuraFrame.SetTestAura(self, aura)
    if (aura ~= nil) then
        AuraFrame.DisplayAura(self, aura);
        self.cooldown:Pause();
    else
        self.cooldown:Resume();
        AuraFrame.DisplayAura(self, nil);
    end
end

function AuraFrame.SetColoringMode(self, coloringMode, ...)
    self.coloringMode = coloringMode;
    if (coloringMode == ColoringMode.Custom) then
        self.background:SetColorTexture(...);
    elseif (coloringMode == ColoringMode.Debuff) then
        self.background:SetColorTexture(1, 0, 0, 1);
    elseif (coloringMode == ColoringMode.Buff) then
        self.background:SetColorTexture(0.2, 0.9, 0.9, 1);
    else
        self.background:SetColorTexture(0, 1, 1, 1);
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
        onlyByPlayer, onlyByPlayer,
    };
    local _, _, spellIcon = GetSpellInfo(auraId);
    self.icon:SetTexture(spellIcon);
    self:Hide();
end

function AuraFrame.UpdateFromPinnedAura(self)
    local aura;
    if self.pinnedAura.debuff == true then
        aura = AuraManager.GetPlayerDebuffByAuraId(self.pinnedAura.unit, self.pinnedAura.id, self.pinnedAura.onlyByPlayer);
    else
        aura = AuraManager.GetPlayerBuffByAuraId(self.pinnedAura.unit, self.pinnedAura.id, self.pinnedAura.onlyByPlayer);
    end
    AuraFrame.DisplayAura(self, aura);
end

function AuraFrame.SetBackgroundColor(self, aura)
    if (self.coloringMode == ColoringMode.Debuff) then
        local color = DebuffTypeColor[aura[4]] or DebuffTypeColor["none"];
        self.background:SetColorTexture(color.r, color.g, color.b);
    end
end

function AuraFrame.DisplayAura(self, aura)
    if (aura == nil) then
        self:Hide();
        return;
    end
    local icon = aura[2];
    local stacks = aura[3];
    local duration = aura[5];
    local expirationTime = aura[6];
    if (icon == nil or duration == nil or expirationTime == nil) then
        self:Hide();
    else
        AuraFrame.SetBackgroundColor(self, aura);
        self.icon:SetTexture(icon);
        self.cooldown:SetCooldown(expirationTime - duration, duration);
        self:Show();

        if (stacks > 0) then
            self.count:SetText(stacks);
            self.count:Show();
        else
            self.count:Hide();
        end
    end
end

function AuraFrame.Hide(self)
    self:Hide();
end