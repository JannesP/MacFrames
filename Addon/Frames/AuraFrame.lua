local ADDON_NAME, _p = ...;
local MyAuraUtil = _p.MyAuraUtil;
local AuraManager = _p.AuraManager;
local FrameUtil = _p.FrameUtil;

local AuraFrame = {};
_p.AuraFrame = AuraFrame;
AuraFrame.ColoringMode = {
    None = "none",
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
    frame.cooldown:Resume();

    frame.coloringMode = ColoringMode.Debuff;

    if (zoom == nil) then
        frame.icon:SetTexCoord(0,1,0,1);
    else
        frame.icon:SetTexCoord(_p.PixelUtil.GetIconZoomTransform(zoom));
    end

    if (frame.borderHost == nil) then
        frame.borderHost = CreateFrame("Frame", nil, frame);
        frame.borderHost:SetAllPoints();
        frame.borderHost:Hide();
        frame.borderHost.api = FrameUtil.CreateSolidBorder(frame.borderHost, 1, 0, 0, 0, 1);
    end    

    PixelUtil.SetPoint(frame.icon, "TOPLEFT", frame, "TOPLEFT", 1, -1, 1, 1);
    PixelUtil.SetPoint(frame.icon, "BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1, 1, 1);

    PixelUtil.SetPoint(frame.cooldown, "TOPLEFT", frame, "TOPLEFT", 1, -1, 1, 1);
    PixelUtil.SetPoint(frame.cooldown, "BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1, 1, 1);

    frame:Hide();
    return frame;
end

function AuraFrame.SetTestAura(self, ...)
    if (select('#', ...) > 0) then
        AuraFrame.DisplayAura(self, ...);
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

function AuraFrame.UpdateFromPinnedAura(self)
    local pinnedAura = self.pinnedAura;
    local displayed = false;

    local function ProcessAuraFunc(slot, info, ...)
        if (not pinnedAura.onlyByPlayer or info.byPlayer) then
            info.displayed = true;
            displayed = true;
            AuraFrame.DisplayAura(self, ...);
            return true;
        end
        return false;
    end

    if pinnedAura.debuff == true then
        AuraManager.ForAllDebuffsByAuraId(pinnedAura.unit, pinnedAura.id, ProcessAuraFunc);
    else
        AuraManager.ForAllBuffsByAuraId(pinnedAura.unit, pinnedAura.id, ProcessAuraFunc);
    end
    if (not displayed) then
        self:Hide();
    end
end

function AuraFrame.SetBackgroundColor(self, debuffType)
    if (self.coloringMode == ColoringMode.Debuff) then
        local color = DebuffTypeColor[debuffType] or DebuffTypeColor["none"];
        self.borderHost.api:SetColor(color.r, color.g, color.b);
    end
end

function AuraFrame.DisplayAura(self, ...)
    local _, icon, stacks, debuffType, duration, expirationTime = ...;
    if (icon == nil or duration == nil or expirationTime == nil) then
        self:Hide();
    else
        AuraFrame.SetBackgroundColor(self, debuffType);
        self.icon:SetTexture(icon);
        self.cooldown:SetCooldown(expirationTime - duration, duration);
        self.cooldown:Resume();
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