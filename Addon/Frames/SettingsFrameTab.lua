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
local SettingsUtil = _p.SettingsUtil;
local PlayerInfo = _p.PlayerInfo;
local FrameUtil = _p.FrameUtil;
local FramePool = _p.FramePool;
local ProfileManager = _p.ProfileManager;
local PopupDisplays = _p.PopupDisplays;

_p.SettingsFrameTab = {};
local SettingsFrameTab = _p.SettingsFrameTab;

local math_max = math.max;

local OptionType = Settings.OptionType;
local CategoryType = Settings.CategoryType;
local CreateSectionSeperator, CreateEditor, CreateProfileEditor, CreateSliderValueEditor, CreateCheckBoxValueEditor, CreateNotYetImplementedEditor;

local _innerMargin = 10;
local _innserSpacing = 5;
local _frames = {};
local _refreshingSettingsFromProfile = false;
local _changingSetting = false;
local function RefreshFromProfile()
    _refreshingSettingsFromProfile = true;
    for i=1, #_frames do
        local frame = _frames[i];
        SettingsFrameTab.RefreshFromProfile(frame);
    end
    _refreshingSettingsFromProfile = false;
end

local function OnOptionChanged()
    if (_refreshingSettingsFromProfile or _changingSetting) then return end;
    RefreshFromProfile();
end
local function RegisterOnOptionChanged(profile)
    profile:RegisterPropertyChanged(OnOptionChanged);
    for _, setting in pairs(profile) do
        if (type(setting) == "table" and setting.RegisterOnOptionChanged) then
            RegisterOnOptionChanged(setting);
        end
    end
end
local function UnregisterOnOptionChanged(profile)
    profile:UnregisterPropertyChanged(OnOptionChanged);
    for _, setting in pairs(profile) do
        if (type(setting) == "table" and setting.UnregisterPropertyChanged) then
            UnregisterOnOptionChanged(setting);
        end
    end
end
ProfileManager.RegisterProfileChangedListener(function (newProfile, oldProfile)
    if (oldProfile ~= nil) then
        oldProfile:UnregisterAllPropertyChanged(OnOptionChanged);
    end
    newProfile:RegisterAllPropertyChanged(OnOptionChanged);
    RefreshFromProfile();
end);

local _tabPanelCount = 0;
local _configFramesCount = 0;

do
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
            seperator = CreateSectionSeperator(s, section.Name);
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
                local editor = CreateEditor(s.optionsContainer, options[i]);
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
    local function TabButton_OnClick(self)
        local parent = self:GetParent();
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
        PanelTemplates_Tab_OnClick(self, parent);
        SettingsFrameTab.SectionSelected(self.settingsFrameTab);
        TabPanel_Reflow(parent);
    end
    local function SetupContentScrollContainer(parent, content)
        parent.contentContainer = CreateFrame("Frame", parent:GetName() .. "ContentContainer", parent, BackdropTemplateMixin and "BackdropTemplate");
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
    function SettingsFrameTab.Create(parent, category)
        _configFramesCount = _configFramesCount + 1;
        local frame = CreateFrame("Frame", parent:GetName() .. "FrameTab" .. _configFramesCount, parent);
        frame.category = category;
        if (category.Type == CategoryType.Profile) then
            local profileEditor = CreateProfileEditor(frame);
            SetupContentScrollContainer(frame, profileEditor);
            frame.optionSections = {
                [1] = {
                    options = {
                        [1] = profileEditor,
                    },
                    content = {
                        Layout = profileEditor.Layout,
                    }
                },
            };
        elseif (category.Type == CategoryType.MouseActions) then
            local mouseActionPage = CreateMouseActionPage(frame, category);
            SetupContentScrollContainer(frame, mouseActionPage);
            frame.optionSections = {
                [1] = {
                    options = {
                        [1] = mouseActionPage,
                    },
                    content = {
                        Layout = mouseActionPage.Layout,
                    }
                },
            };
        elseif (category.Type == CategoryType.AuraBlacklist) then
            local auraBlacklistEditor = CreateAuraBlacklistEditor(frame, category);
            SetupContentScrollContainer(frame, auraBlacklistEditor);
            frame.optionSections = {
                [1] = {
                    options = {
                        [1] = auraBlacklistEditor,
                    },
                    content = {
                        Layout = auraBlacklistEditor.Layout,
                    }
                },
            };
            
        elseif (category.Type == CategoryType.Options) then
            frame.type = category.Type;
            frame.optionSections = {};

            _tabPanelCount = _tabPanelCount + 1;
            frame.tabPanelSectionSelector = CreateFrame("Frame", frame:GetName() .. "TabPanelSectionSelector" .. _tabPanelCount, frame);
            frame.tabPanelSectionSelector:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0);
            frame.tabPanelSectionSelector:SetPoint("RIGHT", frame, "RIGHT", 0, 0);
            frame.tabPanelSectionSelector:SetHeight(22);
            frame.tabPanelSectionSelector.Tabs = {};
            frame.tabPanelSectionSelector:SetScript("OnSizeChanged", TabPanel_Reflow);
            frame.tabPanelSectionSelector:SetScript("OnShow", TabPanel_Reflow);

            frame.contentContainer = CreateFrame("Frame", frame:GetName() .. "ContentContainer", frame, BackdropTemplateMixin and "TooltipBorderBackdropTemplate");
            --frame.contentContainer:SetBackdrop(BACKDROP_TOOLTIP_0_16);
            frame.contentContainer:SetPoint("TOPLEFT", frame.tabPanelSectionSelector, "BOTTOMLEFT", 0, 0);
            frame.contentContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0);

            frame.contentHost = CreateFrame("Frame", frame:GetName() .. "ContentHost", frame.contentContainer);
            frame.contentHost:SetPoint("TOPLEFT", frame.contentContainer, "TOPLEFT", _borderPadding, -_borderPadding);
            frame.contentHost:SetPoint("BOTTOMRIGHT", frame.contentContainer, "BOTTOMRIGHT", -_borderPadding, _borderPadding);

            local lastTabButton = nil;
            for n=1, #category.Sections do
                local section = category.Sections[n];
                local uiSection = {};
                uiSection.tabButton = CreateTabSectionSelector(frame.tabPanelSectionSelector, n, section.Name);
                uiSection.tabButton.settingsFrameTab = frame;
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
            PanelTemplates_SetNumTabs(frame.tabPanelSectionSelector, #category.Sections);
            PanelTemplates_SetTab(frame.tabPanelSectionSelector, 1);
            SettingsFrameTab.SectionSelected(frame);
        else
            error("encountered unknown category type: '" .. category.Type .. "'");
        end
        tinsert(_frames, frame);
        SettingsFrameTab.RefreshFromProfile(frame);
        return frame;
    end
end

function SettingsFrameTab.SectionSelected(self)
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

do
    local function Refresh(section)
        local editors = section.optionsContainer and section.optionsContainer.optionEditors;
        if (editors) then
            for i=1, #editors do
                editors[i]:RefreshFromProfile();
            end
        end
        local sections = section.sections;
        if (sections) then
            for i=1, #sections do
                Refresh(sections[i]);
            end
        end
    end
    function SettingsFrameTab.RefreshFromProfile(self)
        
        for i=1, #self.optionSections do
            Refresh(self.optionSections[i].content);
        end
    end
end

CreateSectionSeperator = function(parent, text)
    local frame = CreateFrame("Frame", nil, parent);
    frame.leftLine = frame:CreateTexture();
    frame.rightLine = frame:CreateTexture();
    frame.text = FrameUtil.CreateText(frame, text, nil, "GameFontNormal");

    frame.leftLine:SetColorTexture(.4, .4, .4, 1);
    PixelUtil.SetHeight(frame.leftLine, 2);

    frame.rightLine:SetColorTexture(.4, .4, .4, 1);
    PixelUtil.SetHeight(frame.rightLine, 2);

    frame.text:SetPoint("CENTER", frame, "CENTER");
    frame.text:SetJustifyH("CENTER");
    frame:SetHeight(select(2, frame.text:GetFont()));
    local p = 5;
    frame.leftLine:SetPoint("LEFT", frame, "LEFT", p, 0);
    frame.leftLine:SetPoint("RIGHT", frame.text, "LEFT", -p, 0);
    frame.rightLine:SetPoint("LEFT", frame.text, "RIGHT", p, 0);
    frame.rightLine:SetPoint("RIGHT", frame, "RIGHT", -p, 0);
    return frame;
end

CreateTabSectionSelector = function(parent, tabIndex, text)
    local button = CreateFrame("Button", parent:GetName() .. "Tab" .. tabIndex, parent, "OptionsFrameTabButtonTemplate");
    button:SetText(text);
    PanelTemplates_TabResize(button, 2);
    button:SetID(tabIndex);
    return button;
end

CreateEditor = function(parent, option)
    if (option.Type == OptionType.SliderValue) then
        return CreateSliderValueEditor(parent, option);
    elseif (option.Type == OptionType.CheckBox) then
        return CreateCheckBoxValueEditor(parent, option);
    elseif (option.Type == OptionType.NotYetImplemented) then
        return CreateNotYetImplementedEditor(parent, option);
    else
        error("Option type '" .. option.Type .. "' not implemented!");
    end
end

do
    local function DropDownCreateProfileOnSelect(self, profileNameArg1, arg2, checked)
        PopupDisplays.ShowCopyProfileEnterName(profileNameArg1);
    end
    local function InitializeDropDownCreateProfile(frame, level, menuList)
        local info = UIDropDownMenu_CreateInfo();
        info.func = DropDownCreateProfileOnSelect;
        info.notCheckable = true;

        info.text = ProfileManager.AddonDefaults;
        info.arg1 = ProfileManager.AddonDefaults;
        UIDropDownMenu_AddButton(info);
        UIDropDownMenu_AddSeparator();

        local profiles = ProfileManager.GetProfileList();
        for name, profile in pairs(profiles) do
            info.text = name;
            info.arg1 = name;
            UIDropDownMenu_AddButton(info);
        end
    end

    local function DropDownRenameProfileOnSelect(self, profileNameArg1, arg2, checked)
        PopupDisplays.ShowRenameProfileEnterName(profileNameArg1);
    end
    local function InitializeDropDownRenameProfile(frame, level, menuList)
        local info = UIDropDownMenu_CreateInfo();
        info.func = DropDownRenameProfileOnSelect;
        info.notCheckable = true;

        local profiles = ProfileManager.GetProfileList();
        for name, profile in pairs(profiles) do
            info.text = name;
            info.arg1 = name;
            UIDropDownMenu_AddButton(info);
        end
    end
    
    local function DropDownDeleteProfileOnSelect(self, profileNameArg1, arg2, checked)
        PopupDisplays.ShowDeleteProfile(profileNameArg1);
    end
    local function InitializeDropDownDeleteProfile(frame, level, menuList)
        local info = UIDropDownMenu_CreateInfo();
        info.func = DropDownDeleteProfileOnSelect;
        info.notCheckable = true;

        local profiles = ProfileManager.GetProfileList();
        for name, profile in pairs(profiles) do
            info.text = name;
            info.arg1 = name;
            UIDropDownMenu_AddButton(info);
        end
    end

    local function DropDownSelectProfileOnSelect(self, arg1, arg2, checked)
        local profileName = arg1;
        local spec = arg2;
        ProfileManager.SelectProfileForSpec(spec.SpecId, profileName);
        UIDropDownMenu_SetText(self.owner, ProfileManager.GetSelectedProfileNameForSpec(spec.SpecId));
    end
    local function GetInitDropDownSelectProfile(dropdown, spec)
        return function(frame, level, menuList)
            local currentProfileNameForSpec = ProfileManager.GetSelectedProfileNameForSpec(spec.SpecId);
            local profiles = ProfileManager.GetProfileList();

            local info = UIDropDownMenu_CreateInfo();
            info.func = DropDownSelectProfileOnSelect;
            local _, currentName = ProfileManager.GetCurrent();
            local profiles = ProfileManager.GetProfileList();
            for name, profile in pairs(profiles) do
                info.text = name;
                info.owner = frame;
                info.arg1 = name;
                info.arg2 = spec;
                info.checked = name == currentProfileNameForSpec;
                UIDropDownMenu_AddButton(info);
            end
        end
    end

    local function CreateProfileSelectForSpec(parent, spec)
        local frame = CreateFrame("Frame", nil, parent);
        frame.spec = spec;
        frame.textSpecName = FrameUtil.CreateText(frame, spec.Name);
        local textHeight = frame.textSpecName:GetHeight();
        
        frame.iconSpec = frame:CreateTexture();
        frame.iconSpec:SetTexture(spec.Icon);
        frame.iconSpec:SetSize(textHeight, textHeight);
        frame.iconSpec:ClearAllPoints();
        frame.iconSpec:SetPoint("LEFT", frame, "LEFT", 0, 0);
        frame.textSpecName:SetPoint("LEFT", frame.iconSpec, "RIGHT", textHeight, 0);

        frame.dropDownSelectProfile = CreateFrame("Frame", "MacFramesDropdownSelectProfile" .. spec.SpecId, frame, "UIDropDownMenuTemplate");
        --dropdowns are wider than they actually draw, so the offset of 16 pixels lets it appear in the middle
        frame.dropDownSelectProfile:SetPoint("RIGHT", frame, "RIGHT", 16, 0);
        UIDropDownMenu_SetWidth(frame.dropDownSelectProfile, 150);
        UIDropDownMenu_Initialize(frame.dropDownSelectProfile, GetInitDropDownSelectProfile(frame.dropDownSelectProfile, spec));
        UIDropDownMenu_SetText(frame.dropDownSelectProfile, ProfileManager.GetSelectedProfileNameForSpec(spec.SpecId));

        local width = frame.iconSpec:GetWidth() + frame.textSpecName:GetWidth() + frame.dropDownSelectProfile:GetWidth();
        frame:SetSize(width, frame.dropDownSelectProfile:GetHeight());
        return frame;
    end

    local function CreateProfileEditorFrame(parent, dropDownNameSuffix, leftText, dropDownText, initFunc)
        local frame = CreateFrame("Frame", nil, parent);
        frame.text = FrameUtil.CreateText(frame, leftText);
        frame.text:SetPoint("LEFT", frame, "LEFT");
        frame.dropDown = CreateFrame("Frame", "MacFramesDropdown" .. dropDownNameSuffix, frame, "UIDropDownMenuTemplate");
        frame.dropDown:SetPoint("RIGHT", frame, "RIGHT", 16, 0);
        UIDropDownMenu_SetWidth(frame.dropDown, 150);
        UIDropDownMenu_Initialize(frame.dropDown, initFunc);
        UIDropDownMenu_SetText(frame.dropDown, dropDownText);
        frame:SetWidth(frame.text:GetWidth() + frame.dropDown:GetWidth());
        frame:SetHeight(frame.dropDown:GetHeight());
        return frame;
    end
    local _profileEditorFrame;
    local function RefreshDropDownTexts()
        local profileSelectors = _profileEditorFrame.profileSelectors;
        for i=1, #profileSelectors do
            local selector = profileSelectors[i];
            UIDropDownMenu_SetText(selector.dropDownSelectProfile, ProfileManager.GetSelectedProfileNameForSpec(selector.spec.SpecId));
        end
    end
    CreateProfileEditor = function(parent)
        local frame = CreateFrame("Frame", nil, parent);
        _profileEditorFrame = frame;
        local largestWidth = 0;
        local totalHeight = 0;

        local frameCreateNewProfile = CreateProfileEditorFrame(frame, "CreateProfile", L["Create new profile:"], L["select profile to copy"], InitializeDropDownCreateProfile);
        frameCreateNewProfile:SetPoint("TOP", frame, "TOP");
        largestWidth = math_max(largestWidth, frameCreateNewProfile:GetWidth());
        totalHeight = totalHeight + frameCreateNewProfile:GetHeight();

        local frameRenameProfile = CreateProfileEditorFrame(frame, "RenameProfile", L["Rename a profile:"], L["select profile to rename"], InitializeDropDownRenameProfile);
        frameRenameProfile:SetPoint("TOP", frameCreateNewProfile, "BOTTOM");
        largestWidth = math_max(largestWidth, frameRenameProfile:GetWidth());
        totalHeight = totalHeight + frameRenameProfile:GetHeight();

        local frameDeleteProfile = CreateProfileEditorFrame(frame, "DeleteProfile", L["Delete a profile:"], L["select profile to delete"], InitializeDropDownDeleteProfile);
        frameDeleteProfile:SetPoint("TOP", frameRenameProfile, "BOTTOM");
        largestWidth = math_max(largestWidth, frameDeleteProfile:GetWidth());
        totalHeight = totalHeight + frameDeleteProfile:GetHeight();

        frame.seperatorProfileSelect = CreateSectionSeperator(frame, L["Select Profiles"]);
        frame.seperatorProfileSelect:SetPoint("TOP", frameDeleteProfile, "BOTTOM");
        frame.seperatorProfileSelect:SetPoint("LEFT", frame, "LEFT");
        frame.seperatorProfileSelect:SetPoint("RIGHT", frame, "RIGHT");
        frame.seperatorProfileSelect:Show();
        totalHeight = totalHeight + frame.seperatorProfileSelect:GetHeight();
        
        frame.profileSelectors = {};
        local profileSelectors = frame.profileSelectors;
        local lastFrame = nil;
        local specs = PlayerInfo.ClassSpecializations;
        for i=1, #specs do
            local profileSelector = CreateProfileSelectForSpec(frame, specs[i]);
            if (lastFrame == nil) then
                profileSelector:SetPoint("TOP", frame.seperatorProfileSelect, "BOTTOM", 0, -5);
                totalHeight = totalHeight + 5;
            else
                profileSelector:SetPoint("TOP", lastFrame, "BOTTOM", 0, 0);
            end
            largestWidth = math_max(largestWidth, profileSelector:GetWidth());
            totalHeight = totalHeight + profileSelector:GetHeight();
            tinsert(profileSelectors, profileSelector);
            lastFrame = profileSelector;
        end

        frameCreateNewProfile:SetWidth(largestWidth);
        frameRenameProfile:SetWidth(largestWidth);
        frameDeleteProfile:SetWidth(largestWidth);
        for i=1, #profileSelectors do
            profileSelectors[i]:SetWidth(largestWidth);
        end

        frame.RefreshFromProfile = function() end;
        frame.Layout = function() end;
        frame:SetHeight(totalHeight);

        ProfileManager.RegisterProfileListChangedListener(RefreshDropDownTexts);
        return frame;
    end
end

do
    local _editorPool = FramePool.Create();
    local _gridLayoutDescriptor = {
        rowHeight = 26,
        columnSpacing = 2,
        rowSpacing = 3,
        childListPropertyName = "editors",
        gridFramePropertyName = "editorContainer",
        [1] = {
            heading = "",
            width = 20,
            cellFramePropertyName = "cellErrorIcon",
            visible = true,
        },
        [2] = {
            heading = L["Type"],
            width = 120,
            cellFramePropertyName = "cellDropDownBindingType",
            visible = true,
        },
        [3] = {
            heading = L["Spell/Item"],
            width = "*",
            cellFramePropertyName = "editBoxContainer",
            visible = true,
        },
        [4] = {
            heading = L["Binding"],
            width = "*",
            cellFramePropertyName = "cellTextKeybind",
            visible = true,
        },
        [5] = {
            heading = L["Set Binding"],
            width = 85,
            cellFramePropertyName = "cellButtonSetKeybind",
            visible = true,
        },
        [6] = {
            heading = L[""],
            width = 20,
            cellFramePropertyName = "cellRemoveButton",
            visible = true,
        },
    }
    local function MouseActionEditor_Layout(self)
        local totalHeight = 0;
        
        _gridLayoutDescriptor[5].width = self.editors[1].buttonSetKeybind:GetWidth();
        FrameUtil.GridLayoutFromObjects(self, _gridLayoutDescriptor);

        totalHeight = totalHeight + self.dropDownHeader:GetHeight();
        totalHeight = totalHeight + self.editorContainer:GetHeight();
        totalHeight = totalHeight + self.buttonAddBinding:GetHeight() + 5;

        self:SetHeight(totalHeight);
    end

    local MouseActionEditor_CreateMouseActionEditor, MouseActionEditor_UpdateForCurrentSpecSelection;
    do
        local _dropDownCount = 0;
        local _bindingTypes = Settings.ValidMouseActionBindingTypes;
        local _bindingButtonAttributeMapping = Settings.MouseActionButtonAttributeMapping;
        local function MouseActionEditor_DropDownSelectBindingType(dropDownButton, arg1BindingTypeKey, arg2, checked)
            local editor = dropDownButton.owner;
            editor.boundTable.type = arg1BindingTypeKey;
            editor:OnDataChanged();
        end
        local function MouseActionEditor_DropDownSelectBindingTypeInit(frame, level, menuList)
            local editor = frame:GetParent();
            local info = UIDropDownMenu_CreateInfo();
            info.func = MouseActionEditor_DropDownSelectBindingType;
            for i=1, #_bindingTypes do
                local bindingType = _bindingTypes[i];
                info.text = bindingType.text;
                info.arg1 = bindingType.value;
                info.owner = editor;
                if (editor.boundTable == nil) then
                    info.checked = false;
                else
                    info.checked = editor.boundTable.type == bindingType.value;
                end
                UIDropDownMenu_AddButton(info);
            end
        end
        local SettingsUtil_ProcessMouseAction = SettingsUtil.ProcessMouseAction;
        local function MouseActionEditor_CheckValidData(self)
            return SettingsUtil_ProcessMouseAction(self.boundList, self.boundIndex, true);
        end

        local _textBuffer = {};
        local function MouseActionEditor_RefreshFromBoundTable(self)
            local boundTable = self.boundTable;

            local bindingTypeText = "please select";
            for i=1, #_bindingTypes do
                local bindingType = _bindingTypes[i];
                if (bindingType.value == boundTable.type) then
                    bindingTypeText = bindingType.text;
                end
            end
            UIDropDownMenu_SetText(self.dropDownBindingType, bindingTypeText);

            if (boundTable.type == "spell" or boundTable.type == "item") then
                self.editBoxContainer:Show();
                self.editBoxSpellSelect:Show();
                self.spellIconDisplay:Show();
            else
                self.editBoxContainer:Hide();
                self.editBoxSpellSelect:Hide();
                self.spellIconDisplay:Hide();
            end

            wipe(_textBuffer);
            if (boundTable.alt == true) then
                _textBuffer[#_textBuffer + 1] = L["ALT"];
            end
            if (boundTable.ctrl == true) then
                _textBuffer[#_textBuffer + 1] = L["CTRL"];
            end
            if (boundTable.shift == true) then
                _textBuffer[#_textBuffer + 1] = L["SHIFT"];
            end
            local keybindText = nil;
            for i=1, #_bindingButtonAttributeMapping do
                local mapping = _bindingButtonAttributeMapping[i];
                if (mapping.attributeName == boundTable.button) then
                    keybindText = mapping.displayName;
                    break;
                end
            end
            if (keybindText == nil) then
                _textBuffer[#_textBuffer + 1] = L["Not Set!"];
            else
                _textBuffer[#_textBuffer + 1] = keybindText;
            end
            local keybindTextComplete = table.concat(_textBuffer, " + ");
            FrameUtil.CreateTextTooltip(self.cellTextKeybind, keybindTextComplete, 1, 1, 1, 1);
            self.textSetKeybind:SetText(keybindTextComplete);

            if (self.boundTable.type == "spell") then
                local name, _, icon, _, _, _, spellId = GetSpellInfo(self.boundTable.spellId);
                print("loading")
                if (spellId ~= nil) then
                    self.spellIconDisplay.texture:SetTexture(icon);
                    self.editBoxSpellSelect:SetText(name);
                else
                    self.spellIconDisplay.texture:SetTexture(134400);
                    self.editBoxSpellSelect:SetText("");
                end
                self.editBoxSpellSelect:SetCursorPosition(0);
            elseif (self.boundTable.type == "item") then
                local itemAsNumber = tonumber(self.boundTable.itemSelector);
                local itemID, _, _, _, icon = GetItemInfoInstant(SecureCmdItemParse(self.boundTable.itemSelector) or "");
                if (itemAsNumber > 0 and itemAsNumber == math.floor(itemAsNumber) and itemAsNumber <= 23) then
                    self.editBoxSpellSelect:SetText(L["Item slot #{i}"]:gsub("{i}", itemAsNumber));
                    self.editBoxSpellSelect:SetCursorPosition(0);
                    self.spellIconDisplay.texture:SetTexture(icon);
                else
                    if (itemID ~= nil) then
                        self.editBoxSpellSelect:SetText(itemID);
                        self.spellIconDisplay.texture:SetTexture(icon);
                        local item = Item:CreateFromItemID(itemID)
                        item:ContinueOnItemLoad(function()
                            self.editBoxSpellSelect:SetText(item:GetItemName());
                            self.editBoxSpellSelect:SetCursorPosition(0);
                        end);
                    else
                        self.spellIconDisplay.texture:SetTexture(134400);
                        self.editBoxSpellSelect:SetText("");
                    end
                    self.editBoxSpellSelect:SetCursorPosition(0);
                end 
            end

            local isValid, errorMsg = MouseActionEditor_CheckValidData(self);
            if (isValid == false) then
                --self.errorText:SetText(L["Invalid Binding: {msg}"]:gsub("{msg}", errorMsg));
                --self.errorText:SetHeight(select(2, self.errorText:GetFont()));
                --can't hide/set to 0 because anchors wouldn't work
                FrameUtil.CreateTextTooltip(self.errorIcon, errorMsg, 1, 1, 0, 1);
                self.errorIcon:SetWidth(self.errorIcon:GetHeight());
                self.errorIcon:Show();
            else
                self.errorIcon:SetWidth(1);
                self.errorIcon:Hide();
            end
        end
        local function MouseActionEditor_OnDataChanged(self)
            if (self.onDataChangedListener ~= nil) then
                self.onDataChangedListener(self);
            end
        end
        local function MouseActionEditor_SetOnDataChangedListener(self, callback)
            self.onDataChangedListener = callback;
        end
        local function MouseActionEditor_OnRemove(self)
            if (self.onRemoveListener ~= nil) then
                self.onRemoveListener(self);
            end
        end
        local function MouseActionEditor_SetOnRemoveListener(self, callback)
            self.onRemoveListener = callback;
        end
        local function MouseActionEditor_OnRemoveClick(removeButton)
            MouseActionEditor_OnRemove(removeButton:GetParent());
        end
        local function MouseActionEditor_SetBoundTable(self, tableList, index)
            self.boundList = tableList;
            self.boundIndex = index;
            self.boundTable = tableList[index];
            MouseActionEditor_RefreshFromBoundTable(self);
        end
        local function MouseActionEditor_ButtonSetKeybind_OnMouseDown(self, buttonName)
            local editor = self:GetParent();
            local boundTable = editor.boundTable;

            boundTable.alt = IsAltKeyDown();
            boundTable.ctrl = IsControlKeyDown();
            boundTable.shift = IsShiftKeyDown();

            local mappedButton;
            for i=1, #_bindingButtonAttributeMapping do
                local mapping = _bindingButtonAttributeMapping[i];
                if (mapping.clickName == buttonName) then
                    mappedButton = mapping.attributeName;
                    break;
                end
            end
            boundTable.button = mappedButton;
            editor:OnDataChanged();
        end
        local function EditBoxSpellSelect_FocusGained(self)
            local editor = self:GetParent();
            local enteredText = self:GetText();
            if (editor.boundTable.type == "spell") then
                self:SetText(editor.boundTable.spellId);
            elseif (editor.boundTable.type == "item") then
                self:SetText(editor.boundTable.itemSelector);
            end
            editor.spellIconDisplay.texture:SetTexture(134400);
            self:SetCursorPosition(self:GetNumLetters());
        end
        local function EditBoxSpellSelect_FocusLost(self)
            local editor = self:GetParent();
            local enteredText = self:GetText();
            if (editor.boundTable.type == "spell") then
                if (enteredText == "") then
                    editor.boundTable.spellId = nil;
                else
                    local name, _, icon, _, _, _, spellId = GetSpellInfo(enteredText);
                    if (spellId ~= nil) then
                        editor.boundTable.spellId = spellId;
                    end
                end
            elseif (editor.boundTable.type == "item") then
                if (enteredText == "") then
                    editor.boundTable.itemSelector = nil;
                else
                    local itemID, _, _, _, icon = GetItemInfoInstant(SecureCmdItemParse(enteredText) or "");
                    if (itemID ~= nil) then
                        editor.boundTable.itemSelector = enteredText;
                    end
                end
            end
            editor:OnDataChanged();
        end
        MouseActionEditor_CreateMouseActionEditor = function(parent)
            local frame = CreateFrame("Frame", nil, parent);
            frame.SetBoundTable = MouseActionEditor_SetBoundTable;
            frame.SetOnDataChangedListener = MouseActionEditor_SetOnDataChangedListener;
            frame.RefreshFromBoundTable = MouseActionEditor_RefreshFromBoundTable;
            frame.OnDataChanged = MouseActionEditor_OnDataChanged;
            frame.SetOnRemoveListener = MouseActionEditor_SetOnRemoveListener;
            FrameUtil.ColorFrame(frame, .5, .5, .5, .2)
            local totalHeight = 0;
            local totalWidth = 0;

            frame.cellErrorIcon = CreateFrame("Frame", nil, frame);
            local errorIcon = CreateFrame("Frame", nil, frame);
            frame.errorIcon = errorIcon;
            errorIcon:SetSize(20, 20);
            errorIcon:SetPoint("CENTER", frame.cellErrorIcon, "CENTER");
            errorIcon.icon = frame.errorIcon:CreateTexture();
            errorIcon.icon:SetAllPoints();
            errorIcon.icon:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew");
            errorIcon:EnableMouse();
            totalWidth = totalWidth + errorIcon:GetWidth();
            totalHeight = math.max(totalHeight, errorIcon:GetHeight());

            _dropDownCount = _dropDownCount + 1;
            frame.cellDropDownBindingType = CreateFrame("Frame", nil, frame);
            local dropDownBindingType = CreateFrame("Frame", "MacFramesDropdownMouseActionSelectBindingType" .. _dropDownCount, frame, "UIDropDownMenuTemplate");
            frame.dropDownBindingType = dropDownBindingType;
            UIDropDownMenu_SetWidth(dropDownBindingType, 100);
            UIDropDownMenu_Initialize(dropDownBindingType, MouseActionEditor_DropDownSelectBindingTypeInit);
            dropDownBindingType:SetPoint("CENTER", frame.cellDropDownBindingType, "CENTER", 0, -2);
            totalWidth = totalWidth + dropDownBindingType:GetWidth();
            totalHeight = math.max(totalHeight, dropDownBindingType:GetHeight());

            local editBoxContainer = CreateFrame("Frame", nil, frame);
            frame.editBoxContainer = editBoxContainer;
            editBoxContainer:SetPoint("LEFT", dropDownBindingType, "RIGHT");

            local spellIconDisplay = CreateFrame("Frame", nil, frame);
            frame.spellIconDisplay = spellIconDisplay;
            spellIconDisplay:SetSize(20, 20);
            spellIconDisplay.texture = spellIconDisplay:CreateTexture();
            spellIconDisplay.texture:SetAllPoints();
            spellIconDisplay.texture:SetTexCoord(FrameUtil.GetStandardIconZoomTransform());
            FrameUtil.CreateSolidBorder(spellIconDisplay, 1, .5, .5, .5, 1);
            spellIconDisplay:SetPoint("LEFT", editBoxContainer, "LEFT");

            local editBoxSpellSelect = CreateFrame("EditBox", nil, frame, "InputBoxTemplate");
            frame.editBoxSpellSelect = editBoxSpellSelect;
            editBoxSpellSelect:SetAutoFocus(false);
            editBoxSpellSelect:SetWidth(130);
            editBoxSpellSelect:ClearAllPoints();
            editBoxSpellSelect:SetHeight(20);
            editBoxSpellSelect:SetPoint("LEFT", spellIconDisplay, "RIGHT", 8, 0);
            editBoxSpellSelect:SetPoint("RIGHT", editBoxContainer, "RIGHT", 0, 0);
            
            editBoxSpellSelect:SetScript("OnEnterPressed", EditBox_ClearFocus);
            editBoxSpellSelect:SetScript("OnTabPressed", EditBox_ClearFocus);
            editBoxSpellSelect:SetScript("OnEditFocusLost", EditBoxSpellSelect_FocusLost);
            editBoxSpellSelect:SetScript("OnEditFocusGained", EditBoxSpellSelect_FocusGained);
            editBoxContainer:SetHeight(math.max(editBoxSpellSelect:GetHeight(), spellIconDisplay:GetHeight()));
            editBoxContainer:SetWidth(spellIconDisplay:GetWidth() + editBoxSpellSelect:GetWidth() + 8);

            totalWidth = totalWidth + editBoxContainer:GetWidth();
            totalHeight = math.max(totalHeight, editBoxContainer:GetHeight());

            frame.cellTextKeybind = CreateFrame("Frame", nil, frame);
            local textSetKeybind = FrameUtil.CreateText(frame, "Ctrl+Alt+Shift+Left", nil, "GameFontNormalSmall");
            frame.textSetKeybind = textSetKeybind;
            textSetKeybind:SetAllPoints(frame.cellTextKeybind);
            totalWidth = totalWidth + textSetKeybind:GetWidth();
            totalHeight = math.max(totalHeight, textSetKeybind:GetHeight());

            frame.cellButtonSetKeybind = CreateFrame("Frame", nil, frame);
            local buttonSetKeybind = FrameUtil.CreateTextButton(frame, nil, L["Click to set"], nil);
            frame.buttonSetKeybind = buttonSetKeybind;
            buttonSetKeybind:RegisterForClicks("AnyDown");
            buttonSetKeybind:SetScript("OnMouseDown", MouseActionEditor_ButtonSetKeybind_OnMouseDown);
            buttonSetKeybind:SetPoint("CENTER", frame.cellButtonSetKeybind, "CENTER");
            totalWidth = totalWidth + buttonSetKeybind:GetWidth();
            totalHeight = math.max(totalHeight, buttonSetKeybind:GetHeight());

            frame.cellRemoveButton = CreateFrame("Frame", nil, frame);
            local removeButton = CreateFrame("Button", nil, frame);
            frame.removeButton = removeButton;
            removeButton:SetSize(25, 25);
            removeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up");
            removeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down");
            removeButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight");
            removeButton:RegisterForClicks("LeftButtonUp");
            removeButton:SetPoint("CENTER", frame.cellRemoveButton, "CENTER");
            removeButton:SetScript("OnClick", MouseActionEditor_OnRemoveClick);

            frame:SetSize(totalWidth, totalHeight);
            return frame;
        end

    end
    local function RecycleEditor(editor)
        editor:SetOnDataChangedListener(nil);
        editor:SetOnRemoveListener(nil);
        _editorPool:Put(editor);
    end
    local function MouseActionEditor_OnEditorDataChanged(editor)
        editor.boundTable._changed = true;
        local parent = editor:GetParent();
        for i=1, #parent.editors do
            --refresh all views because there are validations that depend on all elements
            parent.editors[i]:RefreshFromBoundTable();
        end
        editor.boundList[editor.boundIndex] = editor.boundTable;
    end

    local function MouseActionEditor_OnEditorRemove(editor)
        editor.boundList:Remove(editor.boundIndex);
        MouseActionEditor_UpdateForCurrentSpecSelection(editor:GetParent());
    end
    
    MouseActionEditor_UpdateForCurrentSpecSelection = function(self)
        local classId, specId = self.selectedClassId, self.selectedSpecId;
        if (classId == nil or specId == nil) then error("unexpected selection!") end;

        local profile = self.category:GetProfile();
        local specEntries = profile.ClickBindings[classId][specId];

        self.mouseActionList = specEntries;
        for i=1, #self.editors do  --clear current editors
            RecycleEditor(self.editors[i]);
        end
        wipe(self.editors);

        local lastFrame = nil;
        for i=1, specEntries:Length() do
            local editor = _editorPool:Take();
            if (editor == nil) then
                editor = MouseActionEditor_CreateMouseActionEditor(self);
            else
                editor:SetParent(self);
                editor:Show();
            end
            editor:SetOnDataChangedListener(MouseActionEditor_OnEditorDataChanged);
            editor:SetOnRemoveListener(MouseActionEditor_OnEditorRemove);
            editor:SetBoundTable(specEntries, i);
            
            self.editors[#self.editors + 1] = editor;
            lastFrame = editor;
        end
        MouseActionEditor_Layout(self);
    end

    local function SelectSpec(self, classId, specId)
        local className, classFile, classID = GetClassInfo(classId);
        local specId, specName, _, specIcon, _, _ = GetSpecializationInfoByID(specId);
        self.selectedClassId = classId;
        self.selectedSpecId = specId;
        UIDropDownMenu_SetText(self.dropDownSelectClass, specName .. " " .. className);
        UIDropDownMenu_SetIconImage(self.dropDownSelectClass.Icon, specIcon, UIDropDownMenu_CreateInfo());
        MouseActionEditor_UpdateForCurrentSpecSelection(self);
    end

    local DropDownSelectClassInit;
    do
        --local _classIconTexture = "Interface\\WorldStateFrame\\Icons-Classes";
        local function DropDownSpecSelected(self, arg1ClassId, arg2SpecId, checked)
            SelectSpec(self.owner:GetParent(), arg1ClassId, arg2SpecId);
            CloseDropDownMenus(1);
        end
        DropDownSelectClassInit = function(frame, level, menuList)
            local level = level or 1;
            local info = UIDropDownMenu_CreateInfo();
            if (level == 1) then
                local numClasses = GetNumClasses();
                for i=1,numClasses do
                    local className, classFile, classID = GetClassInfo(i);
                    info.text = className;
                    info.menuList = classID;
                    info.hasArrow = true;
                    info.arg1 = classID;
                    info.owner = frame;
                    info.keepShownOnClick = true;
                    --info.tCoordLeft, info.tCoordRight, info.tCoordTop, info.tCoordBottom = unpack(CLASS_ICON_TCOORDS[classFile]);
                    --info.icon = _classIconTexture;
                    info.ignoreAsMenuSelection = true;
                    info.notCheckable = true;
                    UIDropDownMenu_AddButton(info);
                end
            elseif (level == 2) then
                local classID = menuList;
                local numSpecs = GetNumSpecializationsForClassID(classID);
                for n=1, numSpecs do
                    local specID, name, _, icon = GetSpecializationInfoForClassID(classID, n);
                    info.text = name;
                    info.hasArrow = false;
                    info.arg1 = classID;
                    info.arg2 = specID;
                    info.owner = frame;
                    info.checked = (classID == frame:GetParent().selectedClassId) and (specID == frame:GetParent().selectedSpecId);
                    info.icon = icon;
                    info.func = DropDownSpecSelected;
                    UIDropDownMenu_AddButton(info, level);
                end
            end
        end
    end

    local function AddNewBinding(self)
        self.mouseActionList:Add({});
        MouseActionEditor_UpdateForCurrentSpecSelection(self);
    end

    CreateMouseActionPage = function(parent, category)
        local frame = CreateFrame("Frame", nil, parent);
        frame.category = category;

        frame.dropDownHeader = CreateFrame("Frame", nil, frame);
        frame.dropDownHeader:SetPoint("TOP", frame, "TOP");
        frame.dropDownHeader.text = FrameUtil.CreateText(frame.dropDownHeader, L["Configure for:"]);
        frame.dropDownHeader.text:SetPoint("LEFT", frame.dropDownHeader, "LEFT", 0, 2);
        frame.dropDownSelectClass = CreateFrame("Frame", "MacFramesDropdownMouseActionSelectClass", frame, "UIDropDownMenuTemplate");
        frame.dropDownSelectClass:SetPoint("RIGHT", frame.dropDownHeader, "RIGHT", 16, 0);
        UIDropDownMenu_SetWidth(frame.dropDownSelectClass, 200);
        UIDropDownMenu_Initialize(frame.dropDownSelectClass, DropDownSelectClassInit);

        frame.dropDownHeader:SetHeight(math.max(frame.dropDownHeader:GetHeight(), frame.dropDownSelectClass:GetHeight()));
        frame.dropDownHeader:SetWidth(frame.dropDownHeader.text:GetWidth() + 5 + frame.dropDownSelectClass:GetWidth());

        frame.editorContainer = CreateFrame("Frame", "test123", frame);
        frame.editorContainer:SetPoint("TOP", frame.dropDownHeader, "BOTTOM");
        frame.editorContainer:SetPoint("LEFT", frame, "LEFT");
        frame.editorContainer:SetPoint("RIGHT", frame, "RIGHT");

        frame.buttonAddBinding = FrameUtil.CreateTextButton(frame, nil, L["Add Binding"], function() AddNewBinding(frame) end);
        frame.buttonAddBinding:SetPoint("TOP", frame.editorContainer, "BOTTOM", 0, -5);
        frame.buttonAddBinding:SetPoint("LEFT", frame, "LEFT");

        frame.editors = {};
        SelectSpec(frame, PlayerInfo.classId, PlayerInfo.specId);
        
        frame.RefreshFromProfile = MouseActionEditor_UpdateForCurrentSpecSelection;
        frame.Layout = MouseActionEditor_Layout;
        return frame;
    end
end

do
    CreateAuraBlacklistEditor = function(parent, category)
        local frame = CreateFrame("Frame", nil, parent);
        frame.text = FrameUtil.CreateText(frame, "AuraBlacklistEditor not yet implemented :(");
        frame.text:SetPoint("CENTER", frame, "CENTER");

        frame.RefreshFromProfile = function() end;
        frame.Layout = function() end;
        frame:SetHeight(100);
        return frame;
    end
end

do
    local function EditorOnChange(handler)
        return function(...)
            if (_refreshingSettingsFromProfile) then return end;
            handler(...);
        end
    end

    local function Set(option, ...)
        _changingSetting = true;
        option.Set(...);
        _changingSetting = false;
    end

    local function CreateFrameWithHeading(parent, text)
        local frame = CreateFrame("Frame", nil, parent);
        frame.heading = FrameUtil.CreateText(frame, text, nil, "GameFontNormalSmall");
        frame.heading.fontHeight = select(2, frame.heading:GetFont());
        frame.heading:ClearAllPoints();
        frame.heading:SetJustifyH("CENTER");
        frame.heading:SetPoint("TOP", frame, "TOP", 0, 0);

        frame:SetWidth(Constants.Settings.EditorWidth);
        frame:SetHeight(Constants.Settings.EditorHeight);
        return frame;
    end

    local function SliderEditBox_EditorOnChange(self)
        if (self.isUpdating) then return end;
        self.isUpdating = true;

        local optionFrame = self.optionFrame;
        local option = optionFrame.option;

        local value = self:GetNumber();
        if (option.Min and option.Min > value) or (option.Max and option.Max < value) then
            --out of bounds value
            self:SetNumber(option.Get());
        else
            optionFrame.slider:SetValue(value);
            Set(option, value);
        end
        self:HighlightText(0, 0);
        self:SetCursorPosition(0);
        self.isUpdating = false;
    end

    local function Slider_EditorOnChange(self, value)
        if (self.isUpdating) then return end;
            self.isUpdating = true;
            local optionFrame = self.optionFrame;
            optionFrame.editBox:SetNumber(value);
            Set(optionFrame.option, value);
            self.isUpdating = false;
    end

    local function SliderEditor_RefreshFromProfile(self)
        local value = self.option.Get();
        self.slider:SetValue(value);
        self.editBox:SetNumber(Round(value));
        self.editBox:SetCursorPosition(0);
    end

    CreateSliderValueEditor = function(parent, option)
        local value = option.Get();
        if (value == nil) then
            error("Value for " .. option.Name .. " was nil!");
        end
        local frame = CreateFrameWithHeading(parent, option.Name);
        frame.option = option;

        local slider = CreateFrame("Slider", nil, frame, "OptionsSliderTemplate");
        frame.slider = slider;
        slider.optionFrame = frame;
        slider:SetPoint("TOP", frame.heading, "BOTTOM", 0, 0);
        slider:SetPoint("LEFT", frame, "LEFT", 0, 0);
        slider:SetPoint("RIGHT", frame, "RIGHT", 0, 0);
        slider:SetMinMaxValues(option.Min, option.Max or option.SoftMax or error("Sliders need a maximum value (either SoftMax or Max)"));
        slider:SetValue(value);
        slider:SetValueStep(option.StepSize or 1);
        slider:SetObeyStepOnDrag(false);
        slider.Low:SetPoint("TOPLEFT", slider, "BOTTOMLEFT");
        slider.Low:SetText(option.Min);
        slider.High:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT");
        slider.High:SetText(option.Max or option.SoftMax);

        local editBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate");
        frame.editBox = editBox;
        editBox.optionFrame = frame;
        editBox:SetAutoFocus(false);
        editBox:SetNumeric(true);
        editBox:SetMaxLetters(3);
        editBox:SetNumber(value);
        editBox:SetWidth(27);
        editBox:ClearAllPoints();
        editBox:SetPoint("BOTTOM", frame, "BOTTOM", 0, 4);
        editBox:SetHeight(select(2, slider.Low:GetFont()));
        editBox:SetFrameLevel(slider:GetFrameLevel() + 1);
        
        editBox:SetScript("OnEnterPressed", EditBox_ClearFocus);
        editBox:SetScript("OnTabPressed", EditBox_ClearFocus);
        editBox:SetScript("OnEditFocusLost", EditorOnChange(SliderEditBox_EditorOnChange));

        slider:SetScript("OnValueChanged", EditorOnChange(Slider_EditorOnChange));
        frame.RefreshFromProfile = SliderEditor_RefreshFromProfile;
        return frame;
    end

    CreateCheckBoxValueEditor = function(parent, option)
        local value = option.Get();
        local frame = CreateFrameWithHeading(parent, option.Name);

        local checkBox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate");
        checkBox:SetPoint("TOP", frame.heading, "BOTTOM", 0, 0);
        checkBox:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0);

        checkBox:SetScript("OnClick", EditorOnChange(function(self)
            Set(option, self:GetChecked());
        end));
        frame.RefreshFromProfile = function(self)
            checkBox:SetChecked(option.Get());
        end
        return frame;
    end

    CreateNotYetImplementedEditor = function(parent, option)
        local frame = CreateFrameWithHeading(parent, option.Name);
        local text = FrameUtil.CreateText(frame, "Not yet implemented :(");
        text:SetPoint("TOP", frame.heading, "BOTTOM", 0, 0);
        text:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0);
        frame.RefreshFromProfile = function(self)
        end
        return frame;
    end
end