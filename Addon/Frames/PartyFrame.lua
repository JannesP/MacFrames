local ADDON_NAME, _p = ...;

local Constants = _p.Constants;
local UnitFrame = _p.UnitFrame;

_p.PartyFrame = {};
local PartyFrame = _p.PartyFrame;
local PartySettings = _p.Settings.PartyFrame;

local _frame = nil;
local _unitFrames = nil;

function PartyFrame.create()
    if _frame ~= nil then error("You can only create a single PartyFrame.") end
    local frameName = Constants.PartyFrameGlobalName;
    _frame = CreateFrame("Frame", frameName, UIParent, "SecureHandlerStateTemplate");

    _unitFrames = {};
    _frame.unitFrames = _unitFrames;
    tinsert(_unitFrames, UnitFrame.new("player", _frame));
    for i=1,4 do
        tinsert(_unitFrames, UnitFrame.new("party" .. i, _frame));
    end

    PartyFrame.ProcessLayout(_frame);
    RegisterAttributeDriver(_frame, "state-visibility", PartySettings.StateDriverVisibility);
    return _frame;
end

function PartyFrame.ProcessLayout(self)
    if (not InCombatLockdown()) then
        local frameWidth = PartySettings.FrameWidth;
        local frameHeight = PartySettings.FrameHeight;
        local spacing = PartySettings.FrameSpacing;
        local margin = PartySettings.Margin;
        local anchorInfo = PartySettings.AnchorInfo;

        self:ClearAllPoints();
        PixelUtil.SetPoint(self, anchorInfo.AnchorPoint, UIParent, anchorInfo.AnchorPoint, anchorInfo.OffsetX, anchorInfo.OffsetY);

        if (PartySettings.Vertical) then
            local totalWidth = frameWidth + (2 * margin);
            local totalHeight = (#_unitFrames * frameHeight) + ((#_unitFrames - 1) * spacing) + (2 * margin);

            PixelUtil.SetSize(self, totalWidth, totalHeight);

            for i, frame in ipairs(_unitFrames) do
                local x = margin;
                local y = margin + ((i - 1) * (frameHeight + spacing));
                
                frame:ClearAllPoints();
                PixelUtil.SetPoint(frame, "TOPLEFT", self, "TOPLEFT", x, -y);
                PixelUtil.SetSize(frame, frameWidth, frameHeight);
            end
        else
            local totalWidth = (#_unitFrames * frameWidth) + ((#_unitFrames - 1) * spacing) + (2 * margin);
            local totalHeight = frameHeight + (2 * margin);
            
            PixelUtil.SetSize(self, totalWidth, totalHeight);
            
            for i, frame in ipairs(_unitFrames) do
                local x = margin + ((i - 1) * (frameWidth + spacing));
                local y = margin;
                frame:ClearAllPoints();
                PixelUtil.SetPoint(frame, "TOPLEFT", self, "TOPLEFT", x, -y);
                PixelUtil.SetSize(frame, frameWidth, frameHeight);
            end
        end
    end
end
