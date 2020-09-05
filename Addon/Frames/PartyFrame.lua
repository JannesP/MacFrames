local ADDON_NAME, _p = ...;
local L = _p.L;

local Constants = _p.Constants;
local UnitFrame = _p.UnitFrame;
local FrameUtil = _p.FrameUtil;

_p.PartyFrame = {};
local PartyFrame = _p.PartyFrame;
local PartySettings = _p.Settings.PartyFrame;

local _frame = nil;
local _unitFrames = nil;

function PartyFrame.create()
    if _frame ~= nil then error("You can only create a single PartyFrame.") end
    local frameName = Constants.PartyFrameGlobalName;
    _frame = CreateFrame("Frame", frameName, UIParent, "SecureHandlerStateTemplate");
    _frame:SetFrameStrata(PartySettings.FrameStrata);
    _frame:SetFrameLevel(PartySettings.FrameLevel);

    _frame.dragDropHost = FrameUtil.CreateDragDropOverlay(_frame, nil);
    
    FrameUtil.AddResizer(_frame.dragDropHost, _frame, 
        function(dragDropHost, frame)   --resizeStart
            local spacing = PartySettings.FrameSpacing;
            local margin = PartySettings.Margin;
            _frame:SetScript("OnSizeChanged", function(frame, width, height)
                if (PartySettings.Vertical) then
                    PartySettings.FrameWidth = width - (2 * margin);
                    PartySettings.FrameHeight = (height - ((#_unitFrames - 1) * spacing) - (2 * margin)) / #_unitFrames;
                else
                    PartySettings.FrameWidth = (width - ((#_unitFrames - 1) * spacing) - (2 * margin)) / #_unitFrames;
                    PartySettings.FrameHeight = height - (2 * margin);
                end
                
                PartyFrame.ProcessLayout(frame);
            end);
        end, 
        function(dragDropHost, frame)   --resizeEnd
            _frame:SetScript("OnSizeChanged", nil);
        end
    );

    _unitFrames = {};
    _frame.unitFrames = _unitFrames;
    tinsert(_unitFrames, UnitFrame.new("player", _frame));
    for i=1,4 do
        tinsert(_unitFrames, UnitFrame.new("party" .. i, _frame));
    end

    PartyFrame.ProcessLayout(_frame, true);
    RegisterAttributeDriver(_frame, "state-visibility", PartySettings.StateDriverVisibility);
    return _frame;
end

function PartyFrame.SetTestMode(enabled)
    if (enabled == true) then
        UnregisterAttributeDriver(_frame, "state-visibility");
        _frame:Show();
    else
        RegisterAttributeDriver(_frame, "state-visibility", PartySettings.StateDriverVisibility);
    end
    PartyFrame.SetChildTestModes(enabled);
end

function PartyFrame.SetMovable(movable)
    if (movable) then
        PartyFrame.SetTestMode(true);
        _frame.dragDropHost:Show();
        _frame:SetFrameStrata(Constants.TestModeFrameStrata);
    else
        PartyFrame.SetTestMode(false);
        _frame.dragDropHost:Hide();
        _frame:SetFrameStrata(PartySettings.FrameStrata);
    end
end

function PartyFrame.SetChildTestModes(enabled)
    for _, frame in ipairs(_unitFrames) do
        UnitFrame.SetTestMode(frame, enabled);
    end
end

function PartyFrame.SetDisabled(disabled)
    if (disabled) then
        UnregisterAttributeDriver(_frame, "state-visibility");
        _frame:Hide();
    else
        RegisterAttributeDriver(_frame, "state-visibility", PartySettings.StateDriverVisibility);
    end
end

function PartyFrame.ProcessLayout(self, reanchor)
    if (not InCombatLockdown()) then
        local frameWidth = PartySettings.FrameWidth;
        local frameHeight = PartySettings.FrameHeight;
        local spacing = PartySettings.FrameSpacing;
        local margin = PartySettings.Margin;

        local minUfWidth, minUfHeight = UnitFrame.GetMinimumSize();
        
        if (reanchor == true) then
            local anchorInfo = PartySettings.AnchorInfo;
            self:ClearAllPoints();
            PixelUtil.SetPoint(self, anchorInfo.AnchorPoint, UIParent, anchorInfo.AnchorPoint, anchorInfo.OffsetX, anchorInfo.OffsetY);
        end

        if (PartySettings.Vertical) then
            self:SetMinResize(minUfWidth + (2 * margin), (minUfHeight * #_unitFrames) + (2 * margin) + ((#_unitFrames - 1) * spacing));

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
            self:SetMinResize((minUfWidth * #_unitFrames) + (2 * margin) + ((#_unitFrames - 1) * spacing), minUfHeight + (2 * margin));

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
