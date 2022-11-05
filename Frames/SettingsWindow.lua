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
local PixelPerfect = _p.PixelPerfect;

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
        local tabButton = CreateFrame("Button", frameName .. "Tab" .. i, frame, "PanelTabButtonTemplate");
        tabButton:SetID(i);
        tabButton:SetText(category.Name);
        tabButton:SetScript("OnClick", TabButton_OnClick);
        tabButton.page = SettingsPageFactory.CreatePage(frame, category);
        tabButton.index = i;
        PanelTemplates_TabResize(tabButton, 2);
    end
    PixelPerfect.SetPoint(frame.Tabs[1], "TOPLEFT", frame, "TOPLEFT", 5, 3);
    PanelTemplates_SetNumTabs(frame, #categories);
    TabPanel_Reflow(frame);
    PanelTemplates_SetTab(frame, 1);
    SettingsWindow.SetActiveTab(parent, frame.Tabs[1]);
    
    PixelPerfect.SetHeight(frame, 34);
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
function SettingsWindow.Open()
    if (PlayerInfo.specId == nil) then
        PopupDisplays.ShowGenericMessage("MacFrames currently doesn't support characters without a specialization.\nI kinda forgot about fresh characters. Please consider using the default frames until you are able to select a specialization.\nSorry :(");
        return;
    end
    if (not InCombatLockdown()) then
        if (_window == nil) then
            _window = CreateFrame("Frame", "MacFramesSettingsWindow", _p.UIParent, "DefaultPanelBaseTemplate");
            _window:SetTitle(L["MacFrames Options"]);
            _window:SetFrameStrata("HIGH");
            tinsert(UISpecialFrames, _window:GetName());
            _window:SetScript("OnShow", function () PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN); end);
            _window:SetScript("OnHide", function () PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE); end);

            _window.background = CreateFrame("Frame", nil, _window, "FlatPanelBackgroundTemplate");
            PixelPerfect.SetPoint(_window.background, "TOPLEFT", _window, "TOPLEFT", 7, -18);
            PixelPerfect.SetPoint(_window.background, "BOTTOMRIGHT", _window, "BOTTOMRIGHT", -2, 3);

            _window.closeButton = CreateFrame("Button", nil, _window, "UIPanelCloseButtonDefaultAnchors");
            _window.closeButton:SetScript("OnClick", SettingsWindow.Close);

            _window.dragDropHost = CreateFrame("Frame", nil, _window.TitleContainer);
            PixelPerfect.SetPoint(_window.dragDropHost, "TOPLEFT", _window.TitleContainer, "TOPLEFT", 7, -2);
            PixelPerfect.SetPoint(_window.dragDropHost, "BOTTOMRIGHT", _window.closeButton, "BOTTOMLEFT", 0, 3);

            FrameUtil.ConfigureDragDropHost(_window.dragDropHost, _window, nil, true);

            local padding = 5;

            _window.contentHost = CreateFrame("Frame", _window:GetName() .. "TabHost", _window);
            PixelPerfect.SetPoint(_window.contentHost, "TOPLEFT", _window, "TOPLEFT", padding, -14 - padding);
            PixelPerfect.SetPoint(_window.contentHost, "BOTTOMRIGHT", _window, "BOTTOMRIGHT", -padding, padding);

            _window.tabPanel = CreateTabPanel(_window);
            _window.tabPanel:ClearAllPoints();
            PixelPerfect.SetPoint(_window.tabPanel, "TOPLEFT", _window, "BOTTOMLEFT", padding, 0);
            PixelPerfect.SetPoint(_window.tabPanel, "TOPRIGHT", _window, "BOTTOMRIGHT");
            
            FrameUtil.AddResizer(_window, _window);
            _window:SetResizeBounds(600, 400, 1280, 800);
            _window:EnableMouse(true);

            PixelPerfect.SetSize(_window, 800, 500);
            PixelPerfect.SetPoint(_window, "CENTER", _p.UIParent, "CENTER");
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