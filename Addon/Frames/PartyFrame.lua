local ADDON_NAME, _p = ...;
local L = _p.L;

local Constants = _p.Constants;
local UnitFrame = _p.UnitFrame;
local FrameUtil = _p.FrameUtil;
local ProfileManager = _p.ProfileManager;

_p.PartyFrame = {};
local PartyFrame = _p.PartyFrame;

local _frame = nil;
local _unitFrames = nil;
local _partySettings = nil;

local _changingSettings = false;

local function PartySettings_PropertyChanged(key)
    if (_changingSettings == true or _frame == nil) then return; end
    if (key == "FrameStrata") then
        _frame:SetFrameStrata(_partySettings.FrameStrata);
    elseif (key == "FrameLevel") then
        _frame:SetFrameLevel(_partySettings.FrameLevel);
    elseif (key == "Vertical") then
        PartyFrame.ProcessLayout(_frame, true);
    else
        PartyFrame.ProcessLayout(_frame);
    end
end

local function PartySettings_AnchorInfo_PropertyChanged(key)
    if (_changingSettings == true or _frame == nil) then return; end
    PartyFrame.ProcessLayout(_frame, true);
end

ProfileManager.RegisterProfileChangedListener(function(newProfile)
    if (_partySettings ~= nil) then
        _partySettings:UnregisterPropertyChanged(PartySettings_PropertyChanged);
        _partySettings.AnchorInfo:UnregisterPropertyChanged(PartySettings_AnchorInfo_PropertyChanged);
    end
    _partySettings = newProfile.PartyFrame;
    PartyFrame._partySettings = _partySettings;
    _partySettings:RegisterPropertyChanged(PartySettings_PropertyChanged);
    _partySettings.AnchorInfo:RegisterPropertyChanged(PartySettings_AnchorInfo_PropertyChanged);

    if (_frame ~= nil) then
        PartyFrame.ProcessLayout(_frame, true);
        for _, frame in ipairs(_unitFrames) do
            UnitFrame.SetSettings(frame, _partySettings);
        end
    end
end);

function PartyFrame.create()
    if _frame ~= nil then error("You can only create a single PartyFrame.") end
    local frameName = Constants.PartyFrameGlobalName;
    _frame = CreateFrame("Frame", frameName, UIParent, "SecureHandlerStateTemplate");
    _frame:SetFrameStrata(_partySettings.FrameStrata);
    _frame:SetFrameLevel(_partySettings.FrameLevel);

    _frame.dragDropHost = FrameUtil.CreateDragDropOverlay(_frame, function(dragDropHost, frameToMove)
        _changingSettings = true;
        local point, relativeTo, relativePoint, xOfs, yOfs = frameToMove:GetPoint(1);
        _partySettings.AnchorInfo.OffsetX = xOfs;
        _partySettings.AnchorInfo.OffsetY = yOfs;
        _partySettings.AnchorInfo.AnchorPoint = point;
        for _, frame in ipairs(_unitFrames) do
            UnitFrame.SnapToPixels(frame);
        end
        _changingSettings = false;
    end);
    
    FrameUtil.AddResizer(_frame.dragDropHost, _frame, 
        function(dragDropHost, frame)   --resizeStart
            local spacing = _partySettings.FrameSpacing;
            local margin = _partySettings.Margin;
            _frame:SetScript("OnSizeChanged", function(frame, width, height)
                _changingSettings = true;
                if (_partySettings.Vertical) then
                    _partySettings.FrameWidth = width - (2 * margin);
                    _partySettings.FrameHeight = (height - ((#_unitFrames - 1) * spacing) - (2 * margin)) / #_unitFrames;
                else
                    _partySettings.FrameWidth = (width - ((#_unitFrames - 1) * spacing) - (2 * margin)) / #_unitFrames;
                    _partySettings.FrameHeight = height - (2 * margin);
                end
                _changingSettings = false;
                PartyFrame.ProcessLayout(frame);
            end);
        end, 
        function(dragDropHost, frame)   --resizeEnd
            _frame:SetScript("OnSizeChanged", nil);
        end
    );

    _unitFrames = {};
    _frame.unitFrames = _unitFrames;
    tinsert(_unitFrames, UnitFrame.new("player", _frame, nil, _partySettings));
    for i=1,4 do
        tinsert(_unitFrames, UnitFrame.new("party" .. i, _frame, nil, _partySettings));
    end

    PartyFrame.ProcessLayout(_frame, true);
    RegisterAttributeDriver(_frame, "state-visibility", _partySettings.StateDriverVisibility);
    return _frame;
end

function PartyFrame.SetTestMode(enabled)
    if (enabled == true) then
        UnregisterAttributeDriver(_frame, "state-visibility");
        _frame:Show();
    else
        RegisterAttributeDriver(_frame, "state-visibility", _partySettings.StateDriverVisibility);
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
        _frame:SetFrameStrata(_partySettings.FrameStrata);
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
        RegisterAttributeDriver(_frame, "state-visibility", _partySettings.StateDriverVisibility);
    end
end

function PartyFrame.ProcessLayout(self, reanchor)
    if (not InCombatLockdown()) then
        local frameWidth = _partySettings.FrameWidth;
        local frameHeight = _partySettings.FrameHeight;
        local spacing = _partySettings.FrameSpacing;
        local margin = _partySettings.Margin;

        local minUfWidth, minUfHeight = UnitFrame.GetMinimumSize();
        
        if (reanchor == true) then
            local anchorInfo = _partySettings.AnchorInfo;
            self:ClearAllPoints();
            PixelUtil.SetPoint(self, anchorInfo.AnchorPoint, UIParent, anchorInfo.AnchorPoint, anchorInfo.OffsetX, anchorInfo.OffsetY);
        end

        if (_partySettings.Vertical) then
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
                UnitFrame.SnapToPixels(frame);
            end
        end
    end
end
