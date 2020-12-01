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

local Constants = _p.Constants;
local Settings = _p.Settings;
local FrameUtil = _p.FrameUtil;
local BaseEditorFrame = _p.BaseEditorFrame;
local SliderEditorFrame = _p.SliderEditorFrame;
local CheckBoxEditorFrame = _p.CheckBoxEditorFrame;

_p.GenericOptionsSettingsPage = {};
local GenericOptionsSettingsPage = _p.GenericOptionsSettingsPage;

local _tabPanelCount = 0;

local _borderPadding = Constants.TooltipBorderClearance;
local function Section_Layout(self, width, height)
    local height = 0;
    if (self.seperator) then
        height = height + self.seperator:GetHeight();
    end
    if (self.optionsContainer) then
        FrameUtil.FlowChildren(self.optionsContainer, self.optionsContainer.optionEditors, 6, 6, width);
        height = height + self.optionsContainer:GetHeight();
    end
    local sections = self.sections;
    if (sections) then
        for i=1, #sections do
            local section = sections[i];
            section:Layout(width, height);
            height = height + section:GetHeight();
        end
    end
    self:SetHeight(height);
end
local function CreateSection(parent, section, depth)
    local s = CreateFrame("Frame", nil, parent);
    local seperator;
    if (depth > 1) then
        seperator = FrameUtil.CreateHorizontalSeperatorWithText(s, section.Name);
        seperator:SetPoint("TOPLEFT", s, "TOPLEFT", 0, 0);
        seperator:SetPoint("TOPRIGHT", s, "TOPRIGHT", 0, 0);
        s.seperator = seperator;
    end
    if (section.Options and #section.Options > 0) then
        s.optionsContainer = CreateFrame("Frame", nil, s);
        s.optionsContainer:ClearAllPoints();
        if (seperator) then
            s.optionsContainer:SetPoint("TOPLEFT", seperator, "BOTTOMLEFT", 0, 0);
            s.optionsContainer:SetPoint("TOPRIGHT", seperator, "BOTTOMRIGHT", 0, 0);
        else
            s.optionsContainer:SetPoint("TOPLEFT", s, "TOPLEFT", 0, 0);
            s.optionsContainer:SetPoint("TOPRIGHT", s, "TOPRIGHT", 0, 0);
        end
        s.optionsContainer.optionEditors = {};
        local options = section.Options;
        for i=1, #options do
            local editor = BaseEditorFrame.Create(s.optionsContainer, options[i]);
            s.optionsContainer.optionEditors[i] = editor;
        end
    end
    local sections = section.Sections;
    if (sections and #sections > 0) then
        s.sections = {};
        local lastSection = nil;
        for i=1, #sections do
            local sFrame = nil;
            sFrame = CreateSection(s, sections[i], depth + 1);
            sFrame:ClearAllPoints();
            if (lastSection == nil) then
                if (s.optionsContainer) then
                    sFrame:SetPoint("TOPLEFT", s.optionsContainer, "BOTTOMLEFT", 0, 0);
                    sFrame:SetPoint("TOPRIGHT", s.optionsContainer, "BOTTOMRIGHT", 0, 0);
                else
                    sFrame:SetPoint("TOPLEFT", s, "TOPLEFT", 0, 0);
                    sFrame:SetPoint("TOPRIGHT", s, "TOPRIGHT", 0, 0);
                end
            else
                sFrame:SetPoint("TOPLEFT", lastSection, "BOTTOMLEFT", 0, 0);
                sFrame:SetPoint("TOPRIGHT", lastSection, "BOTTOMRIGHT", 0, 0);
            end
            lastSection = sFrame;
            s.sections[i] = sFrame;
        end
    end
    s.Layout = Section_Layout;
    return s;
end
local function TabPanel_Reflow(self)
    local tabs = self.Tabs;
    for i=1, #tabs do
        PanelTemplates_TabResize(tabs[i], 4);
    end
    PanelTemplates_ResizeTabsToFit(self, self:GetWidth() + ((#tabs - 1) * 16));
end

local function SectionSelected(self)
    local tabIndex = PanelTemplates_GetSelectedTab(self.tabPanelSectionSelector);
    for i=1, #self.optionSections do
        local section = self.optionSections[i];
        if (i == tabIndex) then
            section.content:Layout();
            section.scrollFrame:Show();
            section.scrollFrame:RefreshScrollBarVisibility();
        else
            section.scrollFrame:Hide();
        end
    end
end

local function TabButton_OnClick(self)
    local parent = self:GetParent();
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
    PanelTemplates_Tab_OnClick(self, parent);
    SectionSelected(self.optionsPage);
    TabPanel_Reflow(parent);
end

local ForEachEditor;
do
    local function Do(section, action)
        local editors = section.optionsContainer and section.optionsContainer.optionEditors;
        if (editors) then
            for i=1, #editors do
                action(editors[i]);
            end
        end
        local sections = section.sections;
        if (sections) then
            for i=1, #sections do
                Do(sections[i], action);
            end
        end
    end
    ForEachEditor = function(self, action)
        for i=1, #self.optionSections do
            if (Do(self.optionSections[i].content, action) == true) then
                break;
            end
        end
    end
end

local RefreshFromProfile;
do
    local function Refresh(editor)
        editor:RefreshFromProfile();
    end
    RefreshFromProfile = function(self)
        ForEachEditor(self, Refresh);
    end
end

local function CreateTabSectionSelector(parent, tabIndex, text)
    local button = CreateFrame("Button", parent:GetName() .. "Tab" .. tabIndex, parent, "OptionsFrameTabButtonTemplate");
    button:SetText(text);
    PanelTemplates_TabResize(button, 2);
    button:SetID(tabIndex);
    return button;
end

local _numGenericOptionsPage = 0;
function GenericOptionsSettingsPage.Create(parent, category)
    _numGenericOptionsPage = _numGenericOptionsPage + 1;
    local frame = CreateFrame("Frame", "MacFramesGenericOptionsPage" .. _numGenericOptionsPage .. category.Name, parent);

    _tabPanelCount = _tabPanelCount + 1;
    frame.tabPanelSectionSelector = CreateFrame("Frame", frame:GetName() .. "TabPanelSectionSelector" .. _tabPanelCount, frame);
    frame.tabPanelSectionSelector:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0);
    frame.tabPanelSectionSelector:SetPoint("RIGHT", frame, "RIGHT", 0, 0);
    frame.tabPanelSectionSelector:SetHeight(22);
    frame.tabPanelSectionSelector.Tabs = {};
    frame.tabPanelSectionSelector:SetScript("OnSizeChanged", TabPanel_Reflow);
    frame.tabPanelSectionSelector:SetScript("OnShow", TabPanel_Reflow);

    frame.contentContainer = CreateFrame("Frame", frame:GetName() .. "ContentContainer", frame, "TooltipBorderBackdropTemplate");
    frame.contentContainer:SetPoint("TOPLEFT", frame.tabPanelSectionSelector, "BOTTOMLEFT", 0, 0);
    frame.contentContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0);

    frame.contentHost = CreateFrame("Frame", frame:GetName() .. "ContentHost", frame.contentContainer);
    frame.contentHost:SetPoint("TOPLEFT", frame.contentContainer, "TOPLEFT", _borderPadding, -_borderPadding);
    frame.contentHost:SetPoint("BOTTOMRIGHT", frame.contentContainer, "BOTTOMRIGHT", -_borderPadding, _borderPadding);

    frame.optionSections = {};

    local lastTabButton = nil;
    for n=1, #category.Sections do
        local section = category.Sections[n];
        local uiSection = {};
        uiSection.tabButton = CreateTabSectionSelector(frame.tabPanelSectionSelector, n, section.Name);
        uiSection.tabButton.optionsPage = frame;
        if (lastTabButton == nil) then
            uiSection.tabButton:SetPoint("BOTTOMLEFT", frame.tabPanelSectionSelector, "BOTTOMLEFT", 0, 0);
        else
            uiSection.tabButton:SetPoint("BOTTOMLEFT", lastTabButton, "BOTTOMRIGHT", -16, 0);
        end
        tinsert(frame.tabPanelSectionSelector.Tabs, uiSection.tabButton);
        lastTabButton = uiSection.tabButton;
        uiSection.tabButton:SetScript("OnClick", TabButton_OnClick);

        uiSection.content = CreateSection(nil, section, 1);
        uiSection.scrollFrame = FrameUtil.CreateVerticalScrollFrame(frame.contentHost, uiSection.content);
        uiSection.scrollFrame:ClearAllPoints();
        uiSection.scrollFrame:SetPoint("TOPLEFT", frame.contentHost, "TOPLEFT");
        uiSection.scrollFrame:SetPoint("BOTTOMRIGHT", frame.contentHost, "BOTTOMRIGHT", 0, 0);
        uiSection.content:SetScript("OnSizeChanged", function(self, width, height)
            self:Layout(width, height);
            uiSection.scrollFrame:RefreshScrollBarVisibility();
        end);
        uiSection.content:SetScript("OnShow", function(self, width, height)
            self:Layout(width, height);
            uiSection.scrollFrame:RefreshScrollBarVisibility();
        end);
        frame.optionSections[n] = uiSection;
    end
    frame.RefreshFromProfile = RefreshFromProfile;
    frame.IsChangingSettings = function(self)
        local foundOne = false;
        ForEachEditor(self, function(editor)
            if (editor:IsChangingSettings()) then
                foundOne = true;
                return true;
            end
        end);
        return foundOne;
    end
    PanelTemplates_SetNumTabs(frame.tabPanelSectionSelector, #category.Sections);
    PanelTemplates_SetTab(frame.tabPanelSectionSelector, 1);
    SectionSelected(frame);
    return frame;
end