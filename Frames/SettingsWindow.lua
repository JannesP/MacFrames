--[[
-- MacFrames - WoW Raid and Party Frames <https://github.com/JannesP/MacFrames>
--Copyright (C) 2022  Jannes Peters
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
local FrameUtil = _p.FrameUtil;
local PlayerInfo = _p.PlayerInfo;
local PopupDisplays = _p.PopupDisplays;
local SettingsPageFactory = _p.SettingsPageFactory;
local Settings = _p.Settings;

_p.SettingsWindow = {};
local SettingsWindow = _p.SettingsWindow;

---@diagnostic disable-next-line: undefined-doc-name
---@type Frame|BackdropTemplate|DefaultPanelBaseTemplate|Region
local _window;

local function TabPanel_Reflow(self)
    local tabs = self.Tabs;
    for i=1, #tabs do
        PanelTemplates_TabResize(tabs[i], 2);
    end
    PanelTemplates_ResizeTabsToFit(self, self:GetParent():GetWidth());
end

local function TabButton_OnClick(self)
    local parent = self:GetParent();
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
    PanelTemplates_Tab_OnClick(self, parent);
    SettingsWindow.SetActiveTab(parent:GetParent(), self);
    TabPanel_Reflow(parent);
end

local function CreateTabPanel(parent)
    local frameName = parent:GetName() .. "TabPanel";
    local frame = CreateFrame("Frame", frameName, parent);
    frame.Tabs = {};
    local lastTab = nil;
    local categories = Settings.Categories;
    for i=1, #categories do
        local category = categories[i];
        local tabButton = CreateFrame("Button", frameName .. "Tab" .. i, frame, (_p.isDragonflight and "PanelTabButtonTemplate") or "CharacterFrameTabButtonTemplate");
        if (not _p.isDragonflight) then
            if (lastTab ~= nil) then
                tabButton:SetPoint("TOPLEFT", lastTab, "TOPRIGHT", -16, 0);
            end
            lastTab = tabButton;
        end
        tabButton:SetID(i);
        tabButton:SetText(category.Name);
        tabButton:SetScript("OnClick", TabButton_OnClick);
        tabButton.page = SettingsPageFactory.CreatePage(frame, category);
        tabButton.index = i;
        if (not _p.isDragonflight) then
            frame.Tabs[i] = tabButton;
        end
        PanelTemplates_TabResize(tabButton, 2);
    end
    frame.Tabs[1]:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, 3);
    PanelTemplates_SetNumTabs(frame, #categories);
    TabPanel_Reflow(frame);
    PanelTemplates_SetTab(frame, 1);
    SettingsWindow.SetActiveTab(parent, frame.Tabs[1]);
    
    frame:SetHeight(34);
    frame:SetScript("OnSizeChanged", TabPanel_Reflow);
    frame:SetScript("OnShow", TabPanel_Reflow);
    return frame;
end

function SettingsWindow.SetActiveTab(self, tabButton)
    if (self.contentHost.content ~= nil) then
        self.contentHost.content:Hide();
        self.contentHost.content:ClearAllPoints();
    end

    local page = tabButton.page;
    self.contentHost.content = page;
    page:SetAllPoints(self.contentHost);
    page:Show();
end
---@diagnostic disable: param-type-mismatch
function CreateOldWindow() 
    local _backdropSettings = {
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        edgeSize = 20,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    };
    local function CreateCloseButton(parent)
        local closeButtonFrame = CreateFrame("Frame", nil, parent, "BackdropTemplate");
        closeButtonFrame:SetBackdrop(_backdropSettings);
        closeButtonFrame:SetSize(32, 32);

        local closeButton = CreateFrame("Button", nil, closeButtonFrame);
        closeButton:SetSize(30, 30);
        closeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up");
        closeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down");
        closeButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight");
        closeButton:RegisterForClicks("LeftButtonUp");
        closeButton:SetPoint("CENTER");
        closeButton:SetScript("OnClick", SettingsWindow.Close);
        return closeButtonFrame;
    end
    local function CreateHeading(parent)
        local headerFrame = CreateFrame("Frame", nil, parent, "BackdropTemplate");
        headerFrame:SetBackdrop(_backdropSettings);

        headerFrame.text = FrameUtil.CreateText(headerFrame, L["MacFrames Options"], "ARTWORK");
        headerFrame.text:ClearAllPoints();
        headerFrame.text:SetPoint("CENTER", headerFrame, "CENTER");
        FrameUtil.WidthByText(headerFrame, headerFrame.text);
        headerFrame:SetHeight(30);
        return headerFrame;
    end

    _window = CreateFrame("Frame", "MacFramesSettingsWindow", UIParent, "BackdropTemplate");
    _window:SetBackdrop(_backdropSettings);
    _window.closeButton = CreateCloseButton(_window);
    _window.closeButton:SetPoint("CENTER", _window, "TOPRIGHT", -30, 0);

    _window.heading = CreateHeading(_window);
    _window.heading:ClearAllPoints();
    _window.heading:SetPoint("BOTTOM", _window, "TOP", 0, -10);

    FrameUtil.ConfigureDragDropHost(_window.heading, _window, nil, true);
    return _window;
end

function SettingsWindow.Open()
    if (PlayerInfo.specId == nil) then
        PopupDisplays.ShowGenericMessage("MacFrames currently doesn't support characters without a specialization.\nI kinda forgot about fresh characters. Please consider using the default frames until you are able to select a specialization.\nSorry :(");
        return;
    end
    if (not InCombatLockdown()) then
        if (_window == nil) then
            if (not _p.isDragonflight) then
                _window = CreateOldWindow();
            else
                
                _window = CreateFrame("Frame", "MacFramesSettingsWindow", UIParent, "DefaultPanelBaseTemplate");
---@diagnostic disable-next-line: undefined-field
                _window:SetTitle(L["MacFrames Options"]);
                _window:SetFrameStrata("HIGH");
                tinsert(UISpecialFrames, _window:GetName());
                _window:SetScript("OnShow", function () PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN); end);
                _window:SetScript("OnHide", function () PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE); end);

                _window.background = CreateFrame("Frame", nil, _window, "FlatPanelBackgroundTemplate");
                _window.background:SetPoint("TOPLEFT", _window, "TOPLEFT", 7, -18);
                _window.background:SetPoint("BOTTOMRIGHT", _window, "BOTTOMRIGHT", -2, 3);

                _window.closeButton = CreateFrame("Button", nil, _window, "UIPanelCloseButtonDefaultAnchors");
                _window.closeButton:SetScript("OnClick", SettingsWindow.Close);

                ---@diagnostic disable: undefined-field
                _window.dragDropHost = CreateFrame("Frame", nil, _window.TitleContainer);
                _window.dragDropHost:SetPoint("TOPLEFT", _window.TitleContainer, "TOPLEFT", 7, -2);
                ---@diagnostic enable: undefined-field
                _window.dragDropHost:SetPoint("BOTTOMRIGHT", _window.closeButton, "BOTTOMLEFT", 0, 3);

                FrameUtil.ConfigureDragDropHost(_window.dragDropHost, _window, nil, true);
            end

            local padding = 5;

            _window.contentHost = CreateFrame("Frame", _window:GetName() .. "TabHost", _window);
            _window.contentHost:SetPoint("TOPLEFT", _window, "TOPLEFT", padding, -14 - padding);
            _window.contentHost:SetPoint("BOTTOMRIGHT", _window, "BOTTOMRIGHT", -padding, padding);

            _window.tabPanel = CreateTabPanel(_window);
            _window.tabPanel:ClearAllPoints();
            _window.tabPanel:SetPoint("TOPLEFT", _window, "BOTTOMLEFT", padding, 0);
            _window.tabPanel:SetPoint("TOPRIGHT", _window, "BOTTOMRIGHT", 0, 0);
            
            FrameUtil.AddResizer(_window, _window);
            if (_p.isDragonflight) then
---@diagnostic disable-next-line: undefined-field
                _window:SetResizeBounds(600, 400, 1280, 800);
            else
                _window:SetMinResize(600, 300);
                _window:SetMaxResize(1000, 800);
            end
            _window:EnableMouse(true);

            _window:SetSize(800, 500);
            _window:SetPoint("CENTER", UIParent, "CENTER", 0, 0);            
        end
        _window:Show();
    else
        _p.UserChatMessage(L["Cannot open settings in combat."]);
    end
end
---@diagnostic enable: param-type-mismatch

function SettingsWindow.Close()
    if (_window ~= nil) then
        _window:Hide();
    end
end

function SettingsWindow.Toggle()
    if (_window == nil or _window:IsVisible() == false) then
        SettingsWindow.Open();
    else
        SettingsWindow.Close();
    end
end