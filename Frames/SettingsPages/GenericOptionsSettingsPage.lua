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

local Constants = _p.Constants;
local FrameUtil = _p.FrameUtil;
local ProfileManager = _p.ProfileManager;
local BaseEditorFrame = _p.BaseEditorFrame;
local PixelPerfect = _p.PixelPerfect;

_p.GenericOptionsSettingsPage = {};
local GenericOptionsSettingsPage = _p.GenericOptionsSettingsPage;

local _subSectionRowInset = 20;
local _optionTextColumnWidth = 220;

local _tabPanelCount = 0;

local _borderPadding = Constants.TooltipBorderClearance;

local _allRows = {};

local function CheckDependantEditors(rows)
    for i=1, #rows do
        local row = rows[i];
        if (row.editor.option.IsActive and not row.editor.option.IsActive()) then
            if (row.editor:SetDisabled(true)) then
                row:SetAlpha(0.5);
            end
        else
            if (row.editor:SetDisabled(false)) then
                row:SetAlpha(1);
            end
        end
    end
end
local function Section_CheckDependantEditors(self)
    CheckDependantEditors(self.optionsContainer.optionEditorRows);
    if (self.subSections == nil) then return; end 
    for i=1, #self.subSections do
        Section_CheckDependantEditors(self.subSections[i]);
    end
end
local function OnOptionChanged()
    CheckDependantEditors(_allRows);
end
ProfileManager.RegisterProfileChangedListener(function (newProfile, oldProfile)
    if (oldProfile ~= nil) then
        oldProfile:UnregisterAllPropertyChanged(OnOptionChanged);
    end
    newProfile:RegisterAllPropertyChanged(OnOptionChanged);
end);

local function Section_Layout(self, width)
    local height = 0;
    if (self.seperator) then
        height = height + self.seperator:GetHeight();
    end
    if (self.optionsContainer) then
        local usedHeight = FrameUtil.StackVertical(self.optionsContainer, self.optionsContainer.optionEditorRows, 4);
        for _, row in ipairs(self.optionsContainer.optionEditorRows) do
            PixelPerfect.SetWidth(row, self:GetWidth());
        end
        PixelPerfect.SetHeight(self.optionsContainer, usedHeight);
        height = height + usedHeight;
    end
    local subSections = self.subSections;
    if (subSections) then
        for i=1, #subSections do
            local section = subSections[i];
            section:Layout(width, height);
            height = height + section:GetHeight();
        end
    end
    PixelPerfect.SetHeight(self, height);
end
local function CreateSectionHeader(parent, text, fontName)
    local frame = CreateFrame("Frame", nil, parent);
    frame.text = FrameUtil.CreateText(frame, text, nil, fontName);
    PixelPerfect.SetPoint(frame.text, "LEFT");
    return frame;
end
local function CreateOptionEditorRows(options, parent, rowList, depth)
    depth = depth or 1;
    for i=1, #options do
        local option = options[i];
        local rowFrame = CreateFrame("Frame", nil, parent);
        rowFrame.option = option;
        rowFrame.text = FrameUtil.CreateText(rowFrame, option.Name);
        PixelPerfect.SetPoint(rowFrame.text, "CENTER");
        PixelPerfect.SetPoint(rowFrame.text, "LEFT", rowFrame, "LEFT", _subSectionRowInset * depth, 0);

        local editor = BaseEditorFrame.Create(rowFrame, option);
        PixelPerfect.SetSize(editor, editor:GetMeasuredSize());
        PixelPerfect.SetPoint(editor, "CENTER");
        PixelPerfect.SetPoint(editor, "LEFT", rowFrame, "LEFT", _optionTextColumnWidth, 0);

        local textHeight = select(2, rowFrame.text:GetFont());
        local editorHeight = editor:GetHeight();
        PixelPerfect.SetHeight(rowFrame, max(textHeight, editorHeight));

        if (option.Description ~= nil) then
            FrameUtil.CreateTextTooltip(rowFrame, option.Description, rowFrame, "ANCHOR_TOPLEFT", _optionTextColumnWidth + 20, 0, 1, 1, 1, 1);
            --FrameUtil.CreateTextTooltip(rowFrame.text, option.Description, rowFrame, nil, 0, 0, 1, 1, 1, 1);
        end
        rowFrame.editor = editor;
        tinsert(rowList, rowFrame);
        tinsert(_allRows, rowFrame);
        if (option.Options and #option.Options > 0) then
            CreateOptionEditorRows(option.Options, parent, rowList, depth + 1);
        end
        
    end
end
local function CreateSection(parent, section, depth)
    local s = CreateFrame("Frame", nil, parent);
    local seperator;
    if (depth <= 1) then        --this is the section heading
        seperator = CreateSectionHeader(s, section.Name, "GameFontHighlightHuge");
        PixelPerfect.SetPoint(seperator.text, "TOPLEFT", seperator, 0, -4);
        seperator.texSeperatorBar = seperator:CreateTexture();
        seperator.texSeperatorBar:SetAtlas("Options_HorizontalDivider", true);
        PixelPerfect.SetPoint(seperator.texSeperatorBar, "LEFT");
        PixelPerfect.SetPoint(seperator.texSeperatorBar, "RIGHT");
        PixelPerfect.SetPoint(seperator.texSeperatorBar, "BOTTOM", seperator, "BOTTOM", 0, 4);
        PixelPerfect.SetHeight(seperator, select(2, seperator.text:GetFont()) + 14);
    elseif (depth == 2) then --these are subsection headings
        seperator = CreateSectionHeader(s, section.Name, "GameFontHighlightLarge");
        PixelPerfect.SetPoint(seperator.text, "LEFT", seperator, "LEFT", 0, -6);
        PixelPerfect.SetHeight(seperator, select(2, seperator.text:GetFont()) + 16);
    elseif (depth > 2) then  --these are conditionally shown options
        --these don't have a header
    end
    s.seperator = seperator;
    if (s.seperator) then
        PixelPerfect.SetPoint(seperator, "TOPLEFT", s, "TOPLEFT", 0, 0);
        PixelPerfect.SetPoint(seperator, "TOPRIGHT", s, "TOPRIGHT", 0, 0);
    end
    if (section.Options and #section.Options > 0) then
        s.optionsContainer = CreateFrame("Frame", nil, s);
        s.optionsContainer:ClearAllPoints();
        if (seperator) then
            PixelPerfect.SetPoint(s.optionsContainer, "TOPLEFT", seperator, "BOTTOMLEFT", 0, 0);
            PixelPerfect.SetPoint(s.optionsContainer, "TOPRIGHT", seperator, "BOTTOMRIGHT", 0, 0);
        else
            PixelPerfect.SetPoint(s.optionsContainer, "TOPLEFT", s, "TOPLEFT", 0, 0);
            PixelPerfect.SetPoint(s.optionsContainer, "TOPRIGHT", s, "TOPRIGHT", 0, 0);
        end
        s.optionsContainer.optionEditorRows = {};
        CreateOptionEditorRows(section.Options, s.optionsContainer, s.optionsContainer.optionEditorRows);
    end
    local subSections = section.SubSections;
    if (subSections and #subSections > 0) then
        s.subSections = {};
        local lastSection = nil;
        for i=1, #subSections do
            local sFrame = nil;
            sFrame = CreateSection(s, subSections[i], depth + 1);
            sFrame:ClearAllPoints();
            if (lastSection == nil) then
                if (s.optionsContainer) then
                    PixelPerfect.SetPoint(sFrame, "TOPLEFT", s.optionsContainer, "BOTTOMLEFT", 0, 0);
                    PixelPerfect.SetPoint(sFrame, "TOPRIGHT", s.optionsContainer, "BOTTOMRIGHT", 0, 0);
                else
                    PixelPerfect.SetPoint(sFrame, "TOPLEFT", s, "TOPLEFT", 0, 0);
                    PixelPerfect.SetPoint(sFrame, "TOPRIGHT", s, "TOPRIGHT", 0, 0);
                end
            else
                PixelPerfect.SetPoint(sFrame, "TOPLEFT", lastSection, "BOTTOMLEFT", 0, 0);
                PixelPerfect.SetPoint(sFrame, "TOPRIGHT", lastSection, "BOTTOMRIGHT", 0, 0);
            end
            lastSection = sFrame;
            s.subSections[i] = sFrame;
        end
    end
    s.Layout = Section_Layout;
    s.CheckDependantEditors = Section_CheckDependantEditors;
    return s;
end

local function OnSectionSelected(self)
    local sectionIndex = GenericOptionsSettingsPage.GetSelectedSectionIndex(self);
    for i=1, #self.optionSections do
        local section = self.optionSections[i];
        if (i == sectionIndex) then
            section.content:Layout();
            section.scrollFrame:Show();
            section.scrollFrame:RefreshScrollBarVisibility();
            section.scrollFrame:FullUpdate(ScrollBoxConstants.UpdateImmediately);
            section.content:CheckDependantEditors();
        else
            section.scrollFrame:Hide();
        end
    end
end

local ForEachEditor;
do
    local function Do(section, action)
        local editorRows = section.optionsContainer and section.optionsContainer.optionEditorRows;
        if (editorRows) then
            for i=1, #editorRows do
                action(editorRows[i].editor);
            end
        end
        local subSections = section.subSections;
        if (subSections) then
            for i=1, #subSections do
                Do(subSections[i], action);
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

local CreateCategoryButton;
do
    local function Button_UpdateState(self)
        if (self.selected) then
            self.Label:SetFontObject("GameFontHighlight");
            self.Texture:SetAtlas("Options_List_Active", TextureKitConstants.UseAtlasSize);
            self.Texture:Show();
        else
            self.Label:SetFontObject("GameFontNormal");
            if (self.over) then
                self.Texture:SetAtlas("Options_List_Hover", TextureKitConstants.UseAtlasSize);
                self.Texture:Show();
            else
                self.Texture:Hide();
            end
        end
    end

    local function Button_OnEnter(self)
        self.over = true;
        Button_UpdateState(self);
    end

    local function Button_OnLeave(self)
        self.over = false;
        Button_UpdateState(self);
    end

    local function Button_SetSelected(self, selected)
        self.selected = selected;
        Button_UpdateState(self);
    end

    local function Button_IsSelected(self)
        return self.selected;
    end

    CreateCategoryButton = function(parent, categoryIndex, text)
        local button = CreateFrame("Button", parent:GetName() .. "CategoryButton" .. categoryIndex, parent);
        
        button.Texture = button:CreateTexture(nil, "BACKGROUND");
        button.Texture:SetAllPoints(button);
        button.Texture:Hide();

        button.Label = FrameUtil.CreateText(button, text);
        PixelPerfect.SetPoint(button.Label, "CENTER", button, "CENTER");
        button.Label:Show();

        button.SetSelected = Button_SetSelected;
        button.IsSelected = Button_IsSelected;
        
        button:SetScript("OnEnter", Button_OnEnter);
        button:SetScript("OnLeave", Button_OnLeave);
        Button_UpdateState(button);
        
        button:SetID(categoryIndex);
        button:SetScript("OnClick", function(b) b.selected = not b.selected; end);
        return button;
    end
end

local function GetSelectedCategory(sectionList)
    for i=1, #sectionList.Buttons do
        local button = sectionList.Buttons[i];
        if (button:IsSelected()) then
            return button;
        end
    end
    return nil;
end

local function SetupSectionList(sectionList)
    local lastButton = nil;
    for i=1, #sectionList.Buttons do
        local button = sectionList.Buttons[i];
        if (lastButton == nil) then
            PixelPerfect.SetPoint(button, "TOPLEFT", sectionList, "TOPLEFT", 0, -6);
            PixelPerfect.SetPoint(button, "TOPRIGHT", sectionList, "TOPRIGHT", 0, -6);
        else
            PixelPerfect.SetPoint(button, "TOPLEFT", lastButton, "BOTTOMLEFT", 0, -2);
            PixelPerfect.SetPoint(button, "TOPRIGHT", lastButton, "BOTTOMRIGHT", 0, -2);
        end
        PixelPerfect.SetHeight(button, 20);
        button:SetScript("OnClick", function(self)
            if (self:IsSelected()) then
                return;
            end
            for i=1, #sectionList.Buttons do
                local button = sectionList.Buttons[i];
                button:SetSelected(false);
            end
            self:SetSelected(true);
            OnSectionSelected(self.optionsPage);
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
        end);
        lastButton = button;
    end
end

function GenericOptionsSettingsPage.GetSelectedSectionIndex(self)
    local selectedButton = GetSelectedCategory(self.sectionList);
    return (selectedButton and selectedButton:GetID()) or nil;
end

local _numGenericOptionsPage = 0;
function GenericOptionsSettingsPage.Create(parent, category)
    _numGenericOptionsPage = _numGenericOptionsPage + 1;
    local frame = CreateFrame("Frame", parent:GetName() .. "GenericOptionsPage" .. _numGenericOptionsPage .. category.Name, parent);

    _tabPanelCount = _tabPanelCount + 1;
    frame.sectionList = CreateFrame("Frame", frame:GetName() .. "SectionList" .. _tabPanelCount, frame);
    PixelPerfect.SetPoint(frame.sectionList, "TOPLEFT", frame, "TOPLEFT", 0, 0);
    PixelPerfect.SetPoint(frame.sectionList, "BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0);
    PixelPerfect.SetWidth(frame.sectionList, 160);
    frame.sectionList.Buttons = {};

    frame.seperator = FrameUtil.CreateSolidTexture(frame, 0.6, 0.6, 0.6, 0.35);
    PixelPerfect.SetPoint(frame.seperator, "TOPLEFT", frame.sectionList, "TOPRIGHT");
    PixelPerfect.SetPoint(frame.seperator, "BOTTOMRIGHT", frame.sectionList, "BOTTOMRIGHT", 2, 0);

    frame.contentContainer = CreateFrame("Frame", frame:GetName() .. "ContentContainer", frame);
    PixelPerfect.SetPoint(frame.contentContainer, "TOPLEFT", frame.seperator, "TOPRIGHT", 0, 0);
    PixelPerfect.SetPoint(frame.contentContainer, "BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0);

    frame.contentHost = CreateFrame("Frame", frame:GetName() .. "ContentHost", frame.contentContainer);
    PixelPerfect.SetPoint(frame.contentHost, "TOPLEFT", frame.contentContainer, "TOPLEFT", _borderPadding, -_borderPadding);
    PixelPerfect.SetPoint(frame.contentHost, "BOTTOMRIGHT", frame.contentContainer, "BOTTOMRIGHT", -_borderPadding, _borderPadding);

    frame.optionSections = {};

    local lastTabButton = nil;
    for n=1, #category.Sections do
        local section = category.Sections[n];
        local uiSection = {};

        uiSection.categoryButton = CreateCategoryButton(frame.sectionList, n, section.Name);
        uiSection.categoryButton.optionsPage = frame;
        frame.sectionList.Buttons[n] = uiSection.categoryButton;

        uiSection.content = CreateSection(nil, section, 1);
        uiSection.scrollFrame = FrameUtil.CreateVerticalScrollFrame(frame.contentHost, uiSection.content);
        uiSection.scrollFrame:ClearAllPoints();
        PixelPerfect.SetPoint(uiSection.scrollFrame, "TOPLEFT", frame.contentHost, "TOPLEFT");
        PixelPerfect.SetPoint(uiSection.scrollFrame, "BOTTOMRIGHT", frame.contentHost, "BOTTOMRIGHT", 0, 0);
        uiSection.content:SetScript("OnSizeChanged", function(self, width, height)
            self:Layout(width, height);
        end);
        uiSection.content:SetScript("OnShow", function(self, width, height)
            self:Layout(width, height);
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
    SetupSectionList(frame.sectionList);
    frame.sectionList.Buttons[1]:SetSelected(true);
    OnSectionSelected(frame);
    return frame;
end