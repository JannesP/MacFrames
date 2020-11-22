--[[
-- MacFrames - WoW Raid and Party Frames <https://github.com/JannesP/MacFrames>
--Copyright (C) 2020  Jannes Peters
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
local L = _p.L;
local Constants = _p.Constants;
local Settings = _p.Settings;
local FrameUtil = _p.FrameUtil;
local ProfileManager = _p.ProfileManager;
local ProfileEditorSettingsPage = _p.ProfileEditorSettingsPage;
local MouseActionsSettingsPage = _p.MouseActionsSettingsPage;
local AuraBlacklistSettingsPage = _p.AuraBlacklistSettingsPage;
local GenericOptionsSettingsPage = _p.GenericOptionsSettingsPage;

_p.SettingsPageFactory = {};
local SettingsPageFactory = _p.SettingsPageFactory;

local CategoryType = Settings.CategoryType;

local _borderPadding = Constants.TooltipBorderClearance;
local _frames = {};
local _refreshingSettingsFromProfile = false;

local function RefreshFromProfile()
    _refreshingSettingsFromProfile = true;
    for i=1, #_frames do
        _frames[i].content:RefreshFromProfile();
    end
    _refreshingSettingsFromProfile = false;
end

local function OnOptionChanged()
    if (_refreshingSettingsFromProfile) then return end;
    for i=1,#_frames do
        if (_frames[i].content:IsChangingSettings()) then
            return;
        end
    end
    RefreshFromProfile();
end
ProfileManager.RegisterProfileChangedListener(function (newProfile, oldProfile)
    if (oldProfile ~= nil) then
        oldProfile:UnregisterAllPropertyChanged(OnOptionChanged);
    end
    newProfile:RegisterAllPropertyChanged(OnOptionChanged);
    RefreshFromProfile();
end);

local function SetupContentScrollContainer(parent, content)
    parent.contentContainer = CreateFrame("Frame", parent:GetName() .. "ContentContainer", parent, "BackdropTemplate");
    parent.contentContainer:SetBackdrop(BACKDROP_TOOLTIP_0_16);
    parent.contentContainer:SetAllPoints(parent);

    parent.contentHost = CreateFrame("Frame", parent:GetName() .. "ContentHost", parent.contentContainer);
    parent.contentHost:SetPoint("TOPLEFT", parent.contentContainer, "TOPLEFT", _borderPadding, -_borderPadding);
    parent.contentHost:SetPoint("BOTTOMRIGHT", parent.contentContainer, "BOTTOMRIGHT", -_borderPadding, _borderPadding);

    parent.scrollFrame = FrameUtil.CreateVerticalScrollFrame(parent.contentHost, content);
    parent.scrollFrame:SetAllPoints();
    parent.contentHost:SetScript("OnSizeChanged", function(self, width, height)
        content:Layout(width, height);
        parent.scrollFrame:RefreshScrollBarVisibility();
    end);
    parent.contentHost:SetScript("OnShow", function(self, width, height)
        content:Layout(width, height);
        parent.scrollFrame:RefreshScrollBarVisibility();
    end);
end

local _configFramesCount = 0;
function SettingsPageFactory.CreatePage(parent, category)
    _configFramesCount = _configFramesCount + 1;
    local frame = CreateFrame("Frame", parent:GetName() .. "FrameTab" .. _configFramesCount, parent);
    frame.category = category;
    frame.type = category.Type;
    if (category.Type == CategoryType.Profile) then
        frame.content = ProfileEditorSettingsPage.Create(frame, category);
        SetupContentScrollContainer(frame, frame.content);
    elseif (category.Type == CategoryType.MouseActions) then
        frame.content = MouseActionsSettingsPage.Create(frame, category);
        SetupContentScrollContainer(frame, frame.content);
    elseif (category.Type == CategoryType.AuraBlacklist) then
        frame.content = AuraBlacklistSettingsPage.Create(frame, category);
        SetupContentScrollContainer(frame, frame.content);
    elseif (category.Type == CategoryType.Options) then
        frame.content = GenericOptionsSettingsPage.Create(frame, category);
        frame.content:SetAllPoints();
    else
        error("encountered unknown category type: '" .. category.Type .. "'");
    end
    tinsert(_frames, frame);
    frame.content:RefreshFromProfile();
    return frame;
end