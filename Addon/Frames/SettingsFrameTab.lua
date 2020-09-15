local ADDON_NAME, _p = ...;
local L = _p.L;
local Constants = _p.Constants;
local Settings = _p.Settings;
local PlayerInfo = _p.PlayerInfo;
local FrameUtil = _p.FrameUtil;
local ProfileManager = _p.ProfileManager;
local PopupDisplays = _p.PopupDisplays;

_p.SettingsFrameTab = {};
local SettingsFrameTab = _p.SettingsFrameTab;

local OptionType = Settings.OptionType;
local CategoryType = Settings.CategoryType;
local CreateSectionSeperator, CreateEditor, CreateProfileEditor, CreateSliderValueEditor, CreateCheckBoxValueEditor;

local _innerMargin = 10;
local _innserSpacing = 5;
local _frames = {};
local _refreshingSettingsFromProfile = false;
local _changingSetting = false;
local function RefreshFromProfile()
    _refreshingSettingsFromProfile = true;
    for _, frame in ipairs(_frames) do
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
            for i, option in ipairs(section.Options) do
                local editor = CreateEditor(s.optionsContainer, option);
                s.optionsContainer.optionEditors[i] = editor;
            end
        end
        if (section.Sections and #section.Sections > 0) then
            s.sections = {};
            local lastSection = nil;
            for i, childSection in ipairs(section.Sections) do
                local sFrame = nil;
                --if (depth > 1) then
                --    sFrame = CreateSection(parent, childSection, depth + 1);
                --else
                    sFrame = CreateSection(s, childSection, depth + 1);
                --end
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
        s.Layout = function(self, width, height)
            local height = 0;
            local lastElement = self;
            local anchorTo = "TOP";
            local function ReAnchor(frame, target)
                frame:ClearAllPoints();
                frame:SetPoint("TOPLEFT", lastElement, anchorTo.."LEFT");
                frame:SetPoint("TOPRIGHT", lastElement, anchorTo.."RIGHT");
                lastElement = frame;
                anchorTo = "BOTTOM";
            end

            if (self.seperator) then
                height = height + self.seperator:GetHeight();
                ReAnchor(self.seperator);
            end
            if (self.optionsContainer) then
                FrameUtil.FlowChildren(self.optionsContainer, self.optionsContainer.optionEditors, 6, 6, width);
                height = height + self.optionsContainer:GetHeight();
                ReAnchor(self.optionsContainer);
            end
            if (self.sections) then
                for _, section in ipairs(self.sections) do
                    section:Layout(width, height);
                    height = height + section:GetHeight();
                    ReAnchor(section);
                end
            end
            self:SetHeight(height);
        end
        --s:SetScript("OnShow", function (...) 
        --    s.Layout(...);
        --end);
        --s.optionsContainer:SetScript("OnSizeChanged", function (self, width, height) 
        --    FrameUtil.FlowChildren(self, self.optionEditors, 6, 6);
        --end);
        --s:SetScript("OnSizeChanged", function (self, width, height) 
        --    if (self.isUpdating or self:GetWidth() == width) then return; end
        --    s.Layout(self, width, height);
        --end);
        return s;
    end
    function SettingsFrameTab.Create(parent, category)
        _configFramesCount = _configFramesCount + 1;
        local frame = CreateFrame("Frame", parent:GetName() .. "FrameTab" .. _configFramesCount, parent);
        frame.category = category;
        if (category.Type == CategoryType.Profile) then
            local profileEditor = CreateProfileEditor(frame);
            profileEditor:SetAllPoints(frame);
            frame.optionSections = {
                [1] = {
                    options = {
                        [1] = profileEditor,
                    },
                    content = {
                        Layout = function() end,
                    }
                },
            };
        elseif (category.Type == CategoryType.Options) then
            local borderPadding = Constants.TooltipBorderClearance;
            frame.type = category.Type;
            frame.optionSections = {};

            _tabPanelCount = _tabPanelCount + 1;
            frame.tabPanelSectionSelector = CreateFrame("Frame", frame:GetName() .. "TabPanelSectionSelector" .. _tabPanelCount, frame);
            frame.tabPanelSectionSelector:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0);
            frame.tabPanelSectionSelector:SetPoint("RIGHT", frame, "RIGHT", 0, 0);
            frame.tabPanelSectionSelector:SetHeight(22);
            frame.tabPanelSectionSelector.Tabs = {};
            frame.tabPanelSectionSelector:SetScript("OnSizeChanged", function (self)
                for _, tab in ipairs(self.Tabs) do
                    PanelTemplates_TabResize(tab, 4);
                end
                PanelTemplates_ResizeTabsToFit(self, self:GetWidth() + ((#self.Tabs - 1) * 16));
            end);
            frame.tabPanelSectionSelector:SetScript("OnShow", function (self)
                for _, tab in ipairs(self.Tabs) do
                    PanelTemplates_TabResize(tab, 4);
                end
                PanelTemplates_ResizeTabsToFit(self, self:GetWidth() + ((#self.Tabs - 1) * 16));
            end);

            frame.contentContainer = CreateFrame("Frame", frame:GetName() .. "ContentContainer", frame, BackdropTemplateMixin and "BackdropTemplate");
            frame.contentContainer:SetBackdrop(BACKDROP_TOOLTIP_0_16);
            frame.contentContainer:SetPoint("TOPLEFT", frame.tabPanelSectionSelector, "BOTTOMLEFT", 0, 0);
            frame.contentContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0);

            frame.contentHost = CreateFrame("Frame", frame:GetName() .. "ContentHost", frame.contentContainer);
            frame.contentHost:SetPoint("TOPLEFT", frame.contentContainer, "TOPLEFT", borderPadding, -borderPadding);
            frame.contentHost:SetPoint("BOTTOMRIGHT", frame.contentContainer, "BOTTOMRIGHT", -borderPadding, borderPadding);

            local lastTabButton = nil;
            for n, section in ipairs(category.Sections) do
                local uiSection = {};
                uiSection.tabButton = CreateTabSectionSelector(frame.tabPanelSectionSelector, n, section.Name);
                if (lastTabButton == nil) then
                    uiSection.tabButton:SetPoint("BOTTOMLEFT", frame.tabPanelSectionSelector, "BOTTOMLEFT", 0, 0);
                else
                    uiSection.tabButton:SetPoint("BOTTOMLEFT", lastTabButton, "BOTTOMRIGHT", -16, 0);
                end
                tinsert(frame.tabPanelSectionSelector.Tabs, uiSection.tabButton);
                lastTabButton = uiSection.tabButton;
                uiSection.tabButton:SetScript("OnClick", function(self)
                    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
                    PanelTemplates_Tab_OnClick(self, self:GetParent());
                    SettingsFrameTab.SectionSelected(frame);
                end);

                uiSection.content = CreateSection(frame.contentHost, section, 1);
                uiSection.content:ClearAllPoints();
                uiSection.content:SetAllPoints(frame.contentHost);
                uiSection.content:SetScript("OnSizeChanged", function(self, width, height)
                    self:ClearAllPoints();
                    self:SetAllPoints(frame.contentHost);
                    self:Layout(width, height);
                end);
                uiSection.content:SetScript("OnShow", function(self, width, height)
                    self:ClearAllPoints();
                    self:SetAllPoints(frame.contentHost);
                    self:Layout(width, height);
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
    for i, section in ipairs(self.optionSections) do
        if (i == tabIndex) then
            --section.content:SetAllPoints();
            section.content:Show();
            section.content:Layout();
        else
            section.content:Hide();
            --section.content:ClearAllPoints();
        end
    end
end

function SettingsFrameTab.RefreshFromProfile(self)
    local function Refresh(section)
        if (section.optionsContainer and section.optionsContainer.optionEditors) then
            for _, option in ipairs(section.optionsContainer.optionEditors) do
                option:RefreshFromProfile();
            end
        end
        if (section.sections) then
            for _, s in ipairs(section.sections) do
                Refresh(s);
            end
        end
    end
    for _, section in ipairs(self.optionSections) do
        Refresh(section.content);
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
    if (option.Type == OptionType.ProfileSelector) then
        return CreateProfileEditor(parent, option);
    elseif (option.Type == OptionType.SliderValue) then
        return CreateSliderValueEditor(parent, option);
    elseif (option.Type == OptionType.CheckBox) then
        return CreateCheckBoxValueEditor(parent, option);
    else
        error("Option type '" .. option.Type .. "' not implemented!");
    end
end

do
    local function InitializeDropDownCreateProfile(frame, level, menuList)
        local info = UIDropDownMenu_CreateInfo();
        info.func = function(self, profileNameArg1, arg2, checked)
            PopupDisplays.ShowCopyProfileEnterName(profileNameArg1);
        end
        info.notCheckable = true;

        info.text = ProfileManager.AddonDefaults;
        info.arg1 = ProfileManager.AddonDefaults;
        UIDropDownMenu_AddButton(info);

        local profiles = ProfileManager.GetProfileList();
        for name, profile in pairs(profiles) do
            info.text = name;
            info.arg1 = name;
            UIDropDownMenu_AddButton(info);
        end
    end
    local function GetInitDropDownSelectProfile(dropdown, spec)
        return function(frame, level, menuList)
            local currentProfileNameForSpec = ProfileManager.GetSelectedProfileNameForSpec(spec.SpecId);
            local profiles = ProfileManager.GetProfileList();

            local info = UIDropDownMenu_CreateInfo();
            info.func = function(self, arg1, arg2, checked)
                local profileName = arg1;
                ProfileManager.SelectProfileForSpec(spec.SpecId, profileName);
                UIDropDownMenu_SetText(dropdown, ProfileManager.GetSelectedProfileNameForSpec(spec.SpecId));
            end
            local _, currentName = ProfileManager.GetCurrent();
            local profiles = ProfileManager.GetProfileList();
            for name, profile in pairs(profiles) do
                info.text = name;
                info.arg1 = name;
                info.checked = name == currentProfileNameForSpec;
                UIDropDownMenu_AddButton(info);
            end
        end
    end

    local function CreateProfileSelectForSpec(parent, spec)
        local frame = CreateFrame("Frame", nil, parent);
        frame.textSpecName = FrameUtil.CreateText(frame, spec.Name);
        local textHeight = frame.textSpecName:GetHeight();
        
        frame.iconSpec = frame:CreateTexture();
        frame.iconSpec:SetTexture(spec.Icon);
        frame.iconSpec:SetSize(textHeight, textHeight);
        frame.iconSpec:ClearAllPoints();
        frame.iconSpec:SetPoint("LEFT", frame, "LEFT", 0, 0);
        frame.textSpecName:SetPoint("LEFT", frame.iconSpec, "RIGHT", textHeight, 0);

        frame.dropDownSelectProfile = CreateFrame("Frame", "MacFramesDropdownSelectProfile" .. spec.SpecId, frame, "UIDropDownMenuTemplate");
        frame.dropDownSelectProfile:SetPoint("RIGHT", frame, "RIGHT", 0, 0);
        UIDropDownMenu_SetWidth(frame.dropDownSelectProfile, 120);
        UIDropDownMenu_Initialize(frame.dropDownSelectProfile, GetInitDropDownSelectProfile(frame.dropDownSelectProfile, spec));
        UIDropDownMenu_SetText(frame.dropDownSelectProfile, ProfileManager.GetSelectedProfileNameForSpec(spec.SpecId));

        local width = 
            frame.iconSpec:GetWidth() + frame.textSpecName:GetWidth() + frame.dropDownSelectProfile:GetWidth();
        frame:SetSize(width, frame.dropDownSelectProfile:GetHeight());
        return frame;
    end
    CreateProfileEditor = function(parent)
        local frame = CreateFrame("Frame", nil, parent, BackdropTemplateMixin and "BackdropTemplate");
        frame:SetBackdrop(BACKDROP_TOOLTIP_0_16);
        frame.content = CreateFrame("Frame", nil, frame);
        frame.content:SetPoint("TOPLEFT", frame, "TOPLEFT", Constants.TooltipBorderClearance, -Constants.TooltipBorderClearance);
        frame.content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -Constants.TooltipBorderClearance, Constants.TooltipBorderClearance);
        frame.content.textCreateNew = FrameUtil.CreateText(frame.content, L["Create new profile from:"]);
        frame.content.textCreateNew:SetPoint("TOPLEFT", frame.content, "TOPLEFT");
        frame.content.dropDownCreateNew = CreateFrame("Frame", "MacFramesDropdownCreateProfile", frame.content, "UIDropDownMenuTemplate");
        frame.content.dropDownCreateNew:SetPoint("TOPLEFT", frame.content.textCreateNew, "TOPRIGHT");
        UIDropDownMenu_SetWidth(frame.content.dropDownCreateNew, 120);
        UIDropDownMenu_Initialize(frame.content.dropDownCreateNew, InitializeDropDownCreateProfile);
        UIDropDownMenu_SetText(frame.content.dropDownCreateNew, L["select profile to copy"]);
        
        local biggestWidth = 0;
        frame.content.profileSelectors = {};
        local lastFrame = nil;
        for _, spec in ipairs(PlayerInfo.ClassSpecializations) do
            local profileSelector = CreateProfileSelectForSpec(frame.content, spec);
            if (lastFrame == nil) then
                profileSelector:SetPoint("TOP", frame, "TOP", 0, -100);
            else
                profileSelector:SetPoint("TOP", lastFrame, "BOTTOM", 0, 0);
            end
            local width = profileSelector:GetWidth();
            if (biggestWidth < width) then
                biggestWidth = width;
            end
            tinsert(frame.content.profileSelectors, profileSelector);
            lastFrame = profileSelector;
        end

        for _, profileSelector in ipairs(frame.content.profileSelectors) do
            profileSelector:SetWidth(biggestWidth);
        end

        frame.RefreshFromProfile = function(self) end
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

    CreateSliderValueEditor = function(parent, option)
        local value = option.Get();
        local frame = CreateFrameWithHeading(parent, option.Name);
        frame.option = option;

        local slider = CreateFrame("Slider", nil, frame, "OptionsSliderTemplate");
        frame.slider = slider;
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
        editBox:SetAutoFocus(false);
        editBox:SetNumeric(true);
        editBox:SetMaxLetters(3);
        editBox:SetNumber(value);
        editBox:SetWidth(27);
        editBox:ClearAllPoints();
        editBox:SetPoint("BOTTOM", frame, "BOTTOM", 0, 4);
        editBox:SetHeight(select(2, slider.Low:GetFont()));
        editBox:SetFrameLevel(slider:GetFrameLevel() + 1);
        
        local function Unfocus()
            editBox:ClearFocus();
        end
        editBox:SetScript("OnEnterPressed", Unfocus);
        editBox:SetScript("OnTabPressed", Unfocus);

        editBox:SetScript("OnEditFocusLost", EditorOnChange(function(self)
            if (self.isUpdating) then return end;
            self.isUpdating = true;
            local value = self:GetNumber();
            if (option.Min and option.Min > value) or (option.Max and option.Max < value) then
                --out of bounds value
                editBox:SetNumber(option.Get());
            else
                slider:SetValue(value);
                Set(option, value);
            end
            editBox:HighlightText(0, 0);
            editBox:SetCursorPosition(0);
            self.isUpdating = false;
        end));

        slider:SetScript("OnValueChanged", EditorOnChange(function(self, value) 
            if (self.isUpdating) then return end;
            self.isUpdating = true;
            editBox:SetNumber(value);
            Set(option, value);
            self.isUpdating = false;
        end));
        frame.RefreshFromProfile = function(self) 
            local value = option.Get();
            slider:SetValue(value);
            editBox:SetNumber(floor(value));
            editBox:SetCursorPosition(0);
        end
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
end