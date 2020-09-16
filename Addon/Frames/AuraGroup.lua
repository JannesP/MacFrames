local ADDON_NAME, _p = ...;
local AuraFrame = _p.AuraFrame;
local MyAuraUtil = _p.MyAuraUtil;
local AuraManager = _p.AuraManager;
local AuraBlacklist = _p.AuraBlacklist;
local TablePool = _p.TablePool;

local math_min, table_sort = math.min, table.sort;

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
    frame.ignoreBlacklist = false;
    frame.allowDisplayed = false;

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

function AuraGroup.SetIgnoreBlacklist(self, ignoreBlacklist)
    self.ignoreBlacklist = ignoreBlacklist;
end

function AuraGroup.SetAllowDisplayedAuras(self, allowDisplayed)
    self.allowDisplayed = allowDisplayed;
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
do
    local function IsAllowedBySettings(self, slot, info, ...)
        local result = true;
        if (not self.ignoreBlacklist and AuraBlacklist[select(10, ...)] == true) then
            result = false;
        elseif (not self.allowDisplayed and info.displayed) then
            result = false;
        end
        return result;
    end
    local function DisplayInFrame(self, displayedCount, ...)
        local frameCount = #self.auraFrames;
        local frameIndex;
        if (self.reverse == true) then
            frameIndex = frameCount - displayedCount;
        else
            frameIndex = displayedCount + 1;
        end
        local frame = self.auraFrames[frameIndex];
        AuraFrame.DisplayAura(frame, ...);
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
    function AuraGroup.Update(self)
        local displayedCount = 0;
        local frameCount = #self.auraFrames;

        local function NormalDisplayAuraFunc(slot, info, ...)
            if (IsAllowedBySettings(self, slot, info, ...)) then
                --info.displayed = true;
                DisplayInFrame(self, displayedCount, ...);
                displayedCount = displayedCount + 1;
                if (frameCount <= displayedCount) then
                    return true;
                end
            end
            return false;
        end
        local types = AuraGroup.Type;
        if self.auraGroupType == types.DispellableDebuff then
            AuraManager.ForAllDispellableDebuffs(self.unit, NormalDisplayAuraFunc);
        elseif self.auraGroupType == types.UndispellableDebuff then
            AuraManager.ForAllUndispellableDebuffs(self.unit, NormalDisplayAuraFunc);
        elseif self.auraGroupType == types.BossAura then
            AuraManager.ForAllBossAuras(self.unit, NormalDisplayAuraFunc);
        elseif self.auraGroupType == types.DefensiveBuff then
            ClearAuraList();
            AuraManager.ForAllDefensiveBuffs(self.unit, function(slot, info, priority, ...)
                if (IsAllowedBySettings(self, slot, info, ...)) then
                    local holder = _auraTablePool:Take();
                    local auraLength = select('#', ...);
                    for i=1,auraLength do
                        holder[i] = select(i, ...);
                    end
                    holder.n = auraLength;
                    holder.priority = priority;
                    holder.info = info;
                    _auraList[#_auraList + 1] = holder;
                end
                return false;
            end);
            table_sort(_auraList, function(a, b) return a.priority > b.priority end);
            for i=1, math_min(#_auraList, frameCount) do
                local aura = _auraList[i];
                aura.info.displayed = true;
                DisplayInFrame(self, displayedCount, unpack(aura));
                displayedCount = displayedCount + 1;
            end
        else
            error("invalid AuraGroup.Type: " .. self.auraGroupType);
        end
        --hide frames that aren't in use
        if (displayedCount < frameCount) then
            if (self.reverse == true) then
                for i=frameCount - displayedCount, 1, -1 do
                    self.auraFrames[i]:Hide();
                end
            else
                for i=displayedCount + 1, frameCount do
                    self.auraFrames[i]:Hide();
                end
            end
        end
    end
end
