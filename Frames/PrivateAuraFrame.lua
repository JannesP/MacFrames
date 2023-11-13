local _, _p = ...;
local FrameUtil = _p.FrameUtil;
local PixelPerfect = _p.PixelPerfect;

_p.PrivateAuraFrame = {};
local PrivateAuraFrame = _p.PrivateAuraFrame;

local _framePool = _p.FramePool.Create();

local function ClearPrivateAnchor(self)
    if (self.privateAnchorId ~= nil) then
        C_UnitAuras.RemovePrivateAuraAnchor(self.privateAnchorId);
        self.privateAnchorId = nil;
    end
end

local function SetPrivateAnchor(self)
    ClearPrivateAnchor(self);
    self.privateAnchorId = C_UnitAuras.AddPrivateAuraAnchor({
        unitToken = self.params.unit,
        auraIndex = self.params.auraIndex,
        parent = self,
        showCountdownFrame = true,
        showCountdownNumbers = false,
        iconInfo = {
            iconWidth = self.params.width,
            iconHeight = self.params.height,
            iconAnchor = {
                point = "CENTER",
                relativeTo = self,
                relativePoint = "CENTER",
                offsetX = 0,
                offsetY = 0,
            },
        },
        --[[durationAnchor = {
            point = "TOP",
            relativeTo = frame,
            relativePoint = "BOTTOM",
            offsetX = 0,
            offsetY = 0,
        },]]
    });
end

function PrivateAuraFrame.new(parent, width, height, unit, auraIndex)
    local frame = _framePool:Take();
    if (frame == nil) then
        frame = CreateFrame("Frame", nil, parent);
        frame.params = {};
    else
        frame:SetParent(parent);
    end
    frame.params.width = width;
    frame.params.height = height;
    frame.params.unit = unit;
    frame.params.auraIndex = auraIndex;
    PixelPerfect.SetSize(frame, width, height);

    SetPrivateAnchor(frame);

    frame:Show();
    return frame;
end

function PrivateAuraFrame.Destroy(self)
    ClearPrivateAnchor(self);
    self:SetParent(nil);
    self:Hide();
end

function PrivateAuraFrame.SetUnit(self, unit, index)
    self.params.unit = unit;
    self.params.auraIndex = index;
    SetPrivateAnchor(self);
end