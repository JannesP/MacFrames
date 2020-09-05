local ADDON_NAME, _p = ...;
local L = _p.L;

local Constants = _p.Constants;
local Resources = _p.Resources;
local UnitFrame = _p.UnitFrame;
local FrameUtil = _p.FrameUtil;
local ProfileManager = _p.ProfileManager;

_p.RaidFrame = {};
local RaidFrame = _p.RaidFrame;

local _raidSettings = nil;
local _frame = nil;
local _groupFrames = nil;
local _frames = nil;
local _groupChangedInCombat = false;
local _changingSettings = false;

local function RaidSettings_PropertyChanged(key)
    if (_changingSettings == true) then return; end
    if (key == "FrameStrata") then
        _frame:SetFrameStrata(_raidSettings.FrameStrata);
    elseif (key == "FrameLevel") then
        _frame:SetFrameLevel(_raidSettings.FrameLevel);
    else
        RaidFrame.ProcessLayout(_frame);
    end
end

local function RaidSettings_AnchorInfo_PropertyChanged(key)
    if (_changingSettings == true) then return; end
    RaidFrame.UpdateRect(_frame);
    RaidFrame.ProcessLayout(_frame);
end

ProfileManager.RegisterProfileChangedListener(function(newProfile)
    if (_raidSettings ~= nil) then
        _raidSettings:UnregisterPropertyChanged(RaidSettings_PropertyChanged);
        _raidSettings.AnchorInfo:UnregisterPropertyChanged(RaidSettings_AnchorInfo_PropertyChanged);
    end
    _raidSettings = newProfile.RaidFrame;
    _raidSettings:RegisterPropertyChanged(RaidSettings_PropertyChanged);
    _raidSettings.AnchorInfo:RegisterPropertyChanged(RaidSettings_AnchorInfo_PropertyChanged);
end);

function RaidFrame.create()
    if _frame ~= nil then error("You can only create a single RaidFrame.") end
    local frameName = Constants.RaidFrameGlobalName;
    _frame = CreateFrame("Frame", frameName, UIParent, "SecureHandlerStateTemplate");
    _frame:SetFrameStrata(_raidSettings.FrameStrata);
    _frame:SetFrameLevel(_raidSettings.FrameLevel);

    _frame.dragDropHost = FrameUtil.CreateDragDropOverlay(_frame, function(dragDropHost, frame)
        RaidFrame.UpdateAnchorFromCurrentPosition(frame);
        RaidFrame.UpdateRect(frame);
        RaidFrame.ProcessLayout(frame);
    end);

    FrameUtil.AddResizer(_frame.dragDropHost, _frame, 
        function(dragDropHost, frame)   --resizeStart
            local spacing = _raidSettings.FrameSpacing;
            local margin = _raidSettings.Margin;
            _frame:SetScript("OnSizeChanged", function(frame, width, height)
                _raidSettings.FrameWidth = (width - ((Constants.GroupSize - 1) * spacing) - (2 * margin)) / Constants.GroupSize;
                _raidSettings.FrameHeight = (height - ((Constants.RaidGroupCount - 1) * spacing) - (2 * margin)) / Constants.RaidGroupCount;
                RaidFrame.ProcessLayout(frame);
            end);
        end, 
        function(dragDropHost, frame)   --resizeEnd
            _frame:SetScript("OnSizeChanged", nil);
            RaidFrame.UpdateAnchorFromCurrentPosition(frame);
            RaidFrame.UpdateRect(frame);
            RaidFrame.ProcessLayout(frame);
        end
    );
    

    _groupFrames = {};
    for i=1,8 do
        _groupFrames[i] = CreateFrame("Frame", frameName .. "Group" .. i, _frame);
        _groupFrames[i].attachedFrames = {};
    end
    _frame.groups = _groupFrames;
    _frames = {};
    for i=1,40 do
        tinsert(_frames, UnitFrame.new("raid" .. i, _frame));
    end

    RaidFrame.UpdateRect(_frame);
    RaidFrame.ProcessLayout(_frame);
    RegisterAttributeDriver(_frame, "state-visibility", _raidSettings.StateDriverVisibility);
    RaidFrame.SetupEvents(_frame);
    return _frame;
end

function RaidFrame.UpdateAnchorFromCurrentPosition(self)
    local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint(1);
    _changingSettings = true;
    _raidSettings.AnchorInfo.OffsetX = xOfs;
    _raidSettings.AnchorInfo.OffsetY = yOfs;
    _raidSettings.AnchorInfo.AnchorPoint = point;
    _changingSettings = false;
end

function RaidFrame.SetTestMode(enabled)
    if (enabled == true) then
        UnregisterAttributeDriver(_frame, "state-visibility");
        _frame:Show();
        for _, frame in ipairs(_groupFrames) do
            frame:Show();
        end
    else
        RegisterAttributeDriver(_frame, "state-visibility", _raidSettings.StateDriverVisibility);
    end
    RaidFrame.SetChildTestModes(enabled);
end

function RaidFrame.SetMovable(movable)
    if (movable) then
        RaidFrame.SetTestMode(true);
        _frame:SetFrameStrata(Constants.TestModeFrameStrata);
        _frame.dragDropHost:Show();
    else
        RaidFrame.SetTestMode(false);
        _frame:SetFrameStrata(_raidSettings.FrameStrata);
        _frame.dragDropHost:Hide();
    end
end

function RaidFrame.SetDisabled(disabled)
    if (disabled) then
        UnregisterAttributeDriver(_frame, "state-visibility");
        _frame:Hide();
    else
        RegisterAttributeDriver(_frame, "state-visibility", _raidSettings.StateDriverVisibility);
    end
end

function RaidFrame.SetChildTestModes(enabled)
    for _, frame in ipairs(_frames) do
        UnitFrame.SetTestMode(frame, enabled);
    end
end

function RaidFrame.SetupEvents(self)
    self:SetScript("OnEvent", RaidFrame.OnEvent);

    self:RegisterEvent("PLAYER_REGEN_ENABLED");
    self:RegisterEvent("PLAYER_REGEN_DISABLED");
    self:RegisterEvent("GROUP_ROSTER_UPDATE");
end

function RaidFrame.OnEvent(self, event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        RaidFrame.EnteringCombat(self);
    elseif event == "PLAYER_REGEN_ENABLED" then
        RaidFrame.LeavingCombat(self);
    elseif event == "GROUP_ROSTER_UPDATE" then
        if InCombatLockdown() then
            _groupChangedInCombat = true;
        else
            RaidFrame.ProcessLayout(self, false);
        end
    end
end

function RaidFrame.EnteringCombat(self)
    RaidFrame.HideGroupsForContent(self);
end

function RaidFrame.LeavingCombat(self)
    if _groupChangedInCombat then
        _groupChangedInCombat = false;
        RaidFrame.ProcessLayout(self);
    end
    RaidFrame.ShowAllGroups(self);
end

function RaidFrame.HideGroupsForContent(self)
    if (_raidSettings.HideUnnecessaryGroupsInCombat) then
        local _, _, difficultyId = GetInstanceInfo();
        local groupNumberToShow = Constants.RaidGroupCount;
        --https://wow.gamepedia.com/DifficultyID
        if (difficultyId == 14) then        --normal
            groupNumberToShow = 6;
        elseif (difficultyId == 15) then    --heroic
            groupNumberToShow = 6;
        elseif (difficultyId == 16) then    --mythic
            groupNumberToShow = 4;
        end

        for i=groupNumberToShow + 1,#_groupFrames do
            _groupFrames[i]:Hide();
        end
    end
end

function RaidFrame.ShowAllGroups(self)
    for _, group in ipairs(_groupFrames) do
        group:Show();
    end
end

function RaidFrame.UpdateRect(self)
    local frameWidth = _raidSettings.FrameWidth;
    local frameHeight = _raidSettings.FrameHeight;
    local spacing = _raidSettings.FrameSpacing;
    local margin = _raidSettings.Margin;
    local totalWidth = (Constants.GroupSize * frameWidth) + ((Constants.GroupSize - 1) * spacing) + (2 * margin);
    local totalHeight = (Constants.RaidGroupCount * frameHeight) + ((Constants.RaidGroupCount - 1) * spacing) + (2 * margin);
    local anchorInfo = _raidSettings.AnchorInfo;

    local minUfWidth, minUfHeight = UnitFrame.GetMinimumSize();
    local minWidth = (Constants.GroupSize * minUfWidth) + ((Constants.GroupSize - 1) * spacing) + (2 * margin);
    local minHeight = (Constants.RaidGroupCount * minUfHeight) + ((Constants.RaidGroupCount - 1) * spacing) + (2 * margin);
    self:SetMinResize(PixelUtil.GetNearestPixelSize(minWidth, self:GetParent():GetEffectiveScale()), 
        PixelUtil.GetNearestPixelSize(minHeight, self:GetParent():GetEffectiveScale()));

    self:ClearAllPoints();
    PixelUtil.SetPoint(self, anchorInfo.AnchorPoint, UIParent, anchorInfo.AnchorPoint, anchorInfo.OffsetX, anchorInfo.OffsetY);
    PixelUtil.SetSize(self, totalWidth, totalHeight);
end

function RaidFrame.ProcessLayout(self)
    if (InCombatLockdown()) then
        error("Cannot call this in combat!");
    end

    local frameWidth = _raidSettings.FrameWidth;
    local frameHeight = _raidSettings.FrameHeight;
    local spacing = _raidSettings.FrameSpacing;
    local margin = _raidSettings.Margin;
    local totalWidth, totalHeight = self:GetSize();
    
    for _, group in ipairs(_groupFrames) do
        for _, frame in ipairs(group.attachedFrames) do
            frame:ClearAllPoints();
        end
        wipe(group.attachedFrames);
    end

    for raidIndex, frame in ipairs(_frames) do
        local name, _, group = GetRaidRosterInfo(raidIndex);
        if (name ~= nil) then
            tinsert(_groupFrames[group].attachedFrames, frame);
            frame.isGrouped = true;
        else
            frame.isGrouped = false;
        end
    end

    for raidIndex, frame in ipairs(_frames) do
        if frame.isGrouped == false then
            for _, group in ipairs(_groupFrames) do
                if #group.attachedFrames < Constants.GroupSize then
                    tinsert(group.attachedFrames, frame);
                    break;
                end
            end
        end
    end

    for group, groupFrame in ipairs(_groupFrames) do
        local y = margin + ((group - 1) * (frameHeight + spacing));
        groupFrame:ClearAllPoints();
        PixelUtil.SetPoint(groupFrame, "TOPLEFT", self, "TOPLEFT", margin, -y);
        PixelUtil.SetSize(groupFrame, totalWidth - (2 * margin), frameHeight);
        --PixelUtil.SetPoint(groupFrame, "BOTTOMRIGHT", self, "TOPRIGHT", -margin, -y - frameHeight)
        for i,frame in ipairs(groupFrame.attachedFrames) do
            local x = (i - 1) * (frameWidth + spacing);
            frame:ClearAllPoints();
            frame:SetParent(groupFrame);
            PixelUtil.SetPoint(frame, "TOPLEFT", groupFrame, "TOPLEFT", x, 0);
            PixelUtil.SetSize(frame, frameWidth, frameHeight);
        end
    end
end
