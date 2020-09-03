local ADDON_NAME, _p = ...;
local AuraFrame = _p.AuraFrame;
local MyAuraUtil = _p.MyAuraUtil;
local AuraManager = _p.AuraManager;

local _framePool = _p.FramePool.new();

local AuraGroup = {};
_p.AuraGroup = AuraGroup;

AuraGroup.Type = {
    DispellableDebuff = "debuffDispellable",
    UndispellableDebuff = "debuffUndispellable",

    BossAura = "bossAuras",
    DefensiveBuff = "buffDefensive",
}

function AuraGroup.new(parent, unit, auraGroupType, count, iconWidth, iconHeight, spacing, iconZoom)
    local frame = _framePool:Take();
    if frame == nil then
        frame = CreateFrame("Frame", nil, parent);
    else
        frame:SetParent(parent);
    end
    PixelUtil.SetWidth(frame, (iconWidth * count) + (spacing * (count - 1)));
    PixelUtil.SetHeight(frame, iconHeight);
    frame.unit = unit;
    frame.auraGroupType = auraGroupType;

    frame.reverse = false;

    if (frame.auraFrames == nil) then
        frame.auraFrames = {};
    else
        if #frame.auraFrames ~= 0 then
            error("A frame from the pool shouldn't have any auraFrames!");
        end
    end

    local frameColoringMode = AuraFrame.ColoringMode.Custom;
    local cr = 0;
    local cg = 1;
    local cb = 0;
    if (auraGroupType == AuraGroup.Type.DispellableDebuff or auraGroupType == AuraGroup.Type.UndispellableDebuff or auraGroupType == AuraGroup.Type.BossAura) then
        frameColoringMode = AuraFrame.ColoringMode.Debuff;
    elseif (auraGroupType == AuraGroup.Type.DefensiveBuff) then
        frameColoringMode = AuraFrame.ColoringMode.Custom;
        cr = 1;
        cg = 1;
        cb = 0;
    else
        error("Each AuraGroup type requires an aura color setting!");
    end

    local lastFrame = nil;
    for i=1,count do
        local auraFrame = AuraFrame.new(frame, iconWidth, iconHeight, iconZoom);
        AuraFrame.SetColoringMode(auraFrame, frameColoringMode, cr, cg, cb);
        if (lastFrame == nil) then
            PixelUtil.SetPoint(auraFrame, "TOPLEFT", frame, "TOPLEFT", 0, 0);
        else
            PixelUtil.SetPoint(auraFrame, "TOPLEFT", lastFrame, "TOPRIGHT", spacing, 0);
        end
        tinsert(frame.auraFrames, auraFrame);
        lastFrame = auraFrame;
    end
    return frame;
end

function AuraGroup.Recycle(self)
    for _, frame in ipairs(self.auraFrames) do
        AuraFrame.Recycle(frame);
    end
    wipe(self.auraFrames);
    _framePool:Put(self);
end

function AuraGroup.SetUnit(self, unit)
    self.unit = unit;
end

function AuraGroup.SetReverseOrder(self, reverse)
    self.reverse = reverse;
end

function AuraGroup.SetTestMode(self, enabled)
    if (enabled == true) then
        local types = AuraGroup.Type;
        local aura;
        if self.auraGroupType == types.DispellableDebuff then
            aura = { 
                [2] = 136118,
                [3] = 3,
                [4] = "Magic",
                [5] = 10000,
                [6] = GetTime() - 3500,
            };
        elseif self.auraGroupType == types.UndispellableDebuff then
            aura = { 
                [2] = 136113,
                [3] = 3,
                [4] = "none",
                [5] = 10000,
                [6] = GetTime() - 3500,
            };
        elseif self.auraGroupType == types.BossAura then
            aura = { 
                [2] = 1769069,
                [3] = 3,
                [4] = "none",
                [5] = 10000,
                [6] = GetTime() - 3500,
            };
        elseif self.auraGroupType == types.DefensiveBuff then
            aura = { 
                [2] = 135936,
                [3] = 3,
                [4] = "none",
                [5] = 10000,
                [6] = GetTime() - 3500,
            };
        else
            error("invalid AuraGroup.Type: " .. self.auraGroupType);
        end
        for _, frame in ipairs(self.auraFrames) do
            AuraFrame.SetTestAura(frame, aura);
        end
    else
        AuraGroup.Update(self);
    end
end

function AuraGroup.Update(self)
    local auraList;
    local types = AuraGroup.Type;
    if self.auraGroupType == types.DispellableDebuff then
        auraList = AuraManager.GetDispellableDebuffs(self.unit, #self.auraFrames);
    elseif self.auraGroupType == types.UndispellableDebuff then
        auraList = AuraManager.GetUndispellableDebuffs(self.unit, #self.auraFrames);
    elseif self.auraGroupType == types.BossAura then
        auraList = AuraManager.GetBossAuras(self.unit, #self.auraFrames);
    elseif self.auraGroupType == types.DefensiveBuff then
        auraList = AuraManager.GetDefensiveBuffs(self.unit, #self.auraFrames);
    else
        error("invalid AuraGroup.Type: " .. self.auraGroupType);
    end

    if (self.reverse == true) then
        for i=#self.auraFrames, 1, -1 do
            local frame = self.auraFrames[i];
            local aura = auraList[#self.auraFrames - i + 1];
            if (aura == nil) then
                AuraFrame.Hide(frame);
            else
                AuraFrame.DisplayAura(frame, aura);
            end
        end
    else
        for i=1, #self.auraFrames do
            local frame = self.auraFrames[i];
            local aura = auraList[i];
            if (aura == nil) then
                AuraFrame.Hide(frame);
            else
                AuraFrame.DisplayAura(frame, aura);
            end
        end
    end
end
