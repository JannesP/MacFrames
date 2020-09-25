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
local Addon = _p.Addon;
local FrameUtil = _p.FrameUtil;
local SettingsFrameTab = _p.SettingsFrameTab;
local Constants = _p.Constants;

_p.SettingsFrame = {};
local SettingsFrame = _p.SettingsFrame;
local Settings = _p.Settings;

local _borderClearance = Constants.TooltipBorderClearance;
local _frameName = "MacFramesSettingsFrame";
local _frame;
local _activeTab;

local function CreateTextButton(parent, nameSuffix, text, onClickHandler)
    local b = CreateFrame("Button", parent:GetName() .. "Button" .. nameSuffix, parent, "UIPanelButtonTemplate");
    b:SetText(text);
    b:SetWidth(b.Text:GetWidth() + 10);
    b:SetScript("OnClick", onClickHandler);
    return b;
end

local function CreateBottomBar(self)
    local frame = CreateFrame("Frame", _frameName .. "BottomBar", self, BackdropTemplateMixin and "BackdropTemplate");
    frame:SetBackdrop(BACKDROP_TOOLTIP_0_16);
    frame:ClearAllPoints();

    frame.children = {};
    tinsert(frame.children, CreateTextButton(frame, "TestRaid", "Toggle Test Mode: Raid", function () Addon.ToggleTestMode(Addon.TestMode.Raid); end));
    tinsert(frame.children, CreateTextButton(frame, "TestParty", "Toggle Test Mode: Party", function () Addon.ToggleTestMode(Addon.TestMode.Party); end));

    tinsert(frame.children, CreateTextButton(frame, "ToggleAnchors", "Toggle Anchors", function () Addon.ToggleAnchors(); end));
    return frame;
end

local function LayoutBottomBar(self, width, height)
    local bar = self.bottomBar;
    FrameUtil.FlowChildren(bar, bar.children, _borderClearance, 0, width);
end

local function CreateTabSelector(self)
    local frameName = _frameName .. "TabSelector";
    local frame = CreateFrame("Frame", frameName, self, BackdropTemplateMixin and "BackdropTemplate");
    frame:SetBackdrop(BACKDROP_TOOLTIP_0_16);
    self.tabs = {};
    local count = 1;
    local lastButton = nil;
    local categories = Settings.Categories;
    for i=1, #categories do
        local category = categories[i];
        local tab = SettingsFrameTab.Create(frame, category);
        local selectButton = CreateFrame("CheckButton", frameName .. "TabSelector" .. count, frame, "OptionsListButtonTemplate");
        self.tabs[selectButton] = tab;
        selectButton.highlight = selectButton:GetHighlightTexture();
        selectButton.highlight:SetVertexColor(.196, .388, .8);
        selectButton:SetText(category.Name);
        selectButton:ClearAllPoints();
        if (lastButton == nil) then
            selectButton:SetPoint("TOPLEFT", frame, "TOPLEFT", _borderClearance, -_borderClearance);
            selectButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -_borderClearance, -_borderClearance);
            SettingsFrame.SetActiveTab(self, selectButton);
        else
            selectButton:SetPoint("TOPLEFT", lastButton, "BOTTOMLEFT", 0, -1);
            selectButton:SetPoint("TOPRIGHT", lastButton, "BOTTOMRIGHT", 0, -1);
        end
        selectButton:SetScript("OnClick", function(thisTab) SettingsFrame.SetActiveTab(self, thisTab) end);
        lastButton = selectButton;
    end
    return frame;
end

function SettingsFrame.SetActiveTab(self, tabButton)
    if (_frame.tabHost.content ~= nil) then
        _frame.tabHost.content:Hide();
        _frame.tabHost.content:ClearAllPoints();
    end
    for button, _ in pairs(_frame.tabs) do
       button.highlight:SetVertexColor(.196, .388, .8);
       button:UnlockHighlight();
    end

    local tab = self.tabs[tabButton];
    _frame.tabHost.content = tab;
    tabButton.highlight:SetVertexColor(1, 1, 0);
    tabButton:LockHighlight()
    tab:SetAllPoints(_frame.tabHost);
    tab:Show();
end

function SettingsFrame.Show(parent)
    if _frame == nil then
        _frame = CreateFrame("Frame", _frameName, parent, BackdropTemplateMixin and "BackdropTemplate");

        _frame.bottomBar = CreateBottomBar(_frame);
        _frame.bottomBar:SetPoint("BOTTOMLEFT", _frame, "BOTTOMLEFT", 0, 0);
        _frame.bottomBar:SetPoint("BOTTOMRIGHT", _frame, "BOTTOMRIGHT", 0, 0);

        _frame.tabHost = CreateFrame("Frame", _frameName .. "TabHost", _frame);

        _frame.tabSelector = CreateTabSelector(_frame);
        _frame.tabSelector:ClearAllPoints();
        _frame.tabSelector:SetPoint("TOPLEFT", _frame, "TOPLEFT", 0, 0);
        _frame.tabSelector:SetPoint("BOTTOMLEFT", _frame.bottomBar, "TOPLEFT", 0, 0);
        _frame.tabSelector:SetWidth(150);

        _frame.tabHost:SetPoint("TOPLEFT", _frame.tabSelector, "TOPRIGHT", 0, 0);
        _frame.tabHost:SetPoint("BOTTOMRIGHT", _frame.bottomBar, "TOPRIGHT", 0, 0);
    else
        _frame:SetParent(parent);
    end
    _frame:SetScript("OnSizeChanged", SettingsFrame.Layout);
    SettingsFrame.Layout(_frame, _frame:GetSize());
    return _frame;
end

function SettingsFrame.Layout(self, width, height)
    LayoutBottomBar(self, width, height);
end