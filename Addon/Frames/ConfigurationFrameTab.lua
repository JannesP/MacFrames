local ADDON_NAME, _p = ...;
local L = _p.L;
local Constants = _p.Constants;
local ConfigurationOptions = _p.ConfigurationOptions;
local PlayerInfo = _p.PlayerInfo;
local FrameUtil = _p.FrameUtil;
local ProfileManager = _p.ProfileManager;
local PopupDisplays = _p.PopupDisplays;

_p.ConfigurationFrameTab = {};
local ConfigurationFrameTab = _p.ConfigurationFrameTab;

local CType = ConfigurationOptions.Type;
local CreateSectionSeperator, CreateEditor, CreateProfileEditor, CreateSliderValueEditor;

local _innerMargin = 5;
local _frames = {};
local _refreshingSettingsFromProfile = false;
local _changingSetting = false;
local function RefreshFromProfile()
    _refreshingSettingsFromProfile = true;
    for _, frame in ipairs(_frames) do
        ConfigurationFrameTab.RefreshFromProfile(frame);
    end
    _refreshingSettingsFromProfile = false;
end

local function OnOptionChanged()
    if (_refreshingSettingsFromProfile or _changingSetting) then return end;
    RefreshFromProfile();
end
local function RegisterOnOptionChanged(profile)
    print("RegisterOnOptionChanged", profile);
    profile:RegisterPropertyChanged(OnOptionChanged);
    for _, setting in pairs(profile) do
        print("setting: ", setting);
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

function ConfigurationFrameTab.Create(parent, category)
    local frame = CreateFrame("Frame", nil, parent);
    frame.category = category;
    if (category.Name == L[Constants.ProfileOptionsName]) then
        local profileEditor = CreateProfileEditor(frame);
        profileEditor:SetAllPoints(frame);
        frame.optionSections = {
            [1] = {
                options = {
                    [1] = profileEditor,
                },
            },
        };
    else
        frame.optionSections = {};
        for n, section in ipairs(category.Sections) do
            local uiSection = {};
            uiSection.seperator = CreateSectionSeperator(frame, section.Name);
            uiSection.content = CreateFrame("Frame", nil, frame);
            uiSection.options = {};
            for i, option in ipairs(section.Options) do
                local editor = CreateEditor(uiSection.content, option);
                uiSection.options[i] = editor;
            end
            frame.optionSections[n] = uiSection;
        end
        ConfigurationFrameTab.Layout(frame);
        frame:SetScript("OnSizeChanged", ConfigurationFrameTab.Layout);
    end
    tinsert(_frames, frame);
    ConfigurationFrameTab.RefreshFromProfile(frame);
    return frame;
end

function ConfigurationFrameTab.RefreshFromProfile(self)
    for _, section in ipairs(self.optionSections) do
        for _, option in ipairs(section.options) do
            option:RefreshFromProfile();
        end
    end
end

do
    local rows = {};
    local function ClearRows()
        for i, row in ipairs(rows) do
            wipe(row);
        end
    end
    local function AddInRow(num, element)
        if (rows[num] == nil) then
            rows[num] = {};
        end
        tinsert(rows[num], element);
    end
    local function CalcRowSize(row)
        local w, h = 0, 0;
        for _, e in ipairs(row) do
            local eW, eH = e:GetSize();
            w = w + eW;
            if (h < eH) then
                h = eH;
            end
        end
        return w, h;
    end
    function ConfigurationFrameTab.Layout(self)
        local lastLowestFrame = nil;
        for n, section in ipairs(self.optionSections) do
            local seperator = section.seperator;
            if (seperator ~= nil) then
                if (lastLowestFrame == nil) then
                    seperator:SetPoint("TOP", self, "TOP", 0, 0);
                else
                    seperator:SetPoint("TOP", lastLowestFrame, "BOTTOM", 0, 0);
                end
                seperator:SetPoint("LEFT", self, "LEFT", 0, 0);
                seperator:SetPoint("RIGHT", self, "RIGHT", 0, 0);
                lastLowestFrame = seperator;
            end

            local content = section.content;
            if (content == nil) then error("section content needs to be created on creation!") end
            if (lastLowestFrame == nil) then
                content:SetPoint("TOP", self, "TOP", 0, 0);
            else
                content:SetPoint("TOP", lastLowestFrame, "BOTTOM", 0, 0);
            end
            content:SetPoint("LEFT", self, "LEFT", 0, 0);
            content:SetPoint("RIGHT", self, "RIGHT", 0, 0);

            ClearRows();
            local width = content:GetWidth();
            local calcWidth, row = 0, 1;
            for _, option in ipairs(section.options) do
                local oW = option:GetWidth();
                if (oW > width) then
                    if (calcWidth == 0) then
                        AddInRow(row, option);
                        row = row + 1;
                    else
                        row = row + 1;
                        AddInRow(row, option);
                        row = row + 1; --skip row because its already full
                        calcWidth = 0;
                    end
                else
                    if (calcWidth + oW < width) then
                        calcWidth = calcWidth + oW;
                        AddInRow(row, option);
                    else
                        calcWidth = 0;
                        row = row + 1;
                        AddInRow(row, option);
                    end
                end
            end
            
            local rowY = 0;
            for _, row in ipairs(rows) do
                local rowWidth, rowHeight = CalcRowSize(row);
                local spacing = (width - rowWidth) / (#row + 1);
                local lastElement = nil;
                for _, e in ipairs(row) do
                    local eY = (rowHeight - e:GetHeight()) / 2; --- (e:GetHeight() / 2);
                    e:ClearAllPoints();
                    if (lastElement == nil) then
                        e:SetPoint("TOPLEFT", content, "TOPLEFT", spacing, -rowY-eY);
                    else
                        e:SetPoint("LEFT", lastElement, "RIGHT", spacing, 0);
                    end
                    lastElement = e;
                end
                rowY = rowY + rowHeight;
            end
            content:SetHeight(rowY + _innerMargin);
            lastLowestFrame = content;
            ClearRows();
        end
    end
end

CreateSectionSeperator = function(parent, text)
    local frame = CreateFrame("Frame", nil, parent);
    frame.leftLine = frame:CreateTexture();
    frame.rightLine = frame:CreateTexture();
    frame.text = FrameUtil.CreateText(frame, text);

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

CreateEditor = function(parent, option)
    if (option.Type == CType.ProfileSelector) then
        return CreateProfileEditor(parent, option);
    elseif (option.Type == CType.SliderValue) then
        return CreateSliderValueEditor(parent, option);
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
        local frame = CreateFrame("Frame", nil, parent);
        frame.textCreateNew = FrameUtil.CreateText(frame, L["Create new profile from:"]);
        frame.textCreateNew:SetPoint("TOPLEFT", frame, "TOPLEFT");
        frame.dropDownCreateNew = CreateFrame("Frame", "MacFramesDropdownCreateProfile", frame, "UIDropDownMenuTemplate");
        frame.dropDownCreateNew:SetPoint("TOPLEFT", frame.textCreateNew, "TOPRIGHT");
        UIDropDownMenu_SetWidth(frame.dropDownCreateNew, 120);
        UIDropDownMenu_Initialize(frame.dropDownCreateNew, InitializeDropDownCreateProfile);
        UIDropDownMenu_SetText(frame.dropDownCreateNew, L["select profile to copy"]);
        
        local biggestWidth = 0;
        frame.profileSelectors = {};
        local lastFrame = nil;
        for _, spec in ipairs(PlayerInfo.ClassSpecializations) do
            local profileSelector = CreateProfileSelectForSpec(frame, spec);
            if (lastFrame == nil) then
                profileSelector:SetPoint("TOP", frame, "TOP", 0, -100);
            else
                profileSelector:SetPoint("TOP", lastFrame, "BOTTOM", 0, 0);
            end
            local width = profileSelector:GetWidth();
            if (biggestWidth < width) then
                biggestWidth = width;
            end
            tinsert(frame.profileSelectors, profileSelector);
            lastFrame = profileSelector;
        end

        for _, profileSelector in ipairs(frame.profileSelectors) do
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

    CreateSliderValueEditor = function(parent, option)
        local value = option.Get();
        local frame = CreateFrame("Frame", nil, parent);

        local heading = FrameUtil.CreateText(frame, option.Name);
        frame.heading = heading;
        heading.fontHeight = select(2, heading:GetFont());
        heading:ClearAllPoints();
        heading:SetJustifyH("CENTER");
        heading:SetPoint("TOP", frame, "TOP", 0, 0);

        local slider = CreateFrame("Slider", nil, frame, "OptionsSliderTemplate");
        frame.slider = slider;
        slider:SetPoint("TOP", heading, "BOTTOM", 0, 0);
        slider:SetPoint("LEFT", frame, "LEFT", 0, 0);
        slider:SetPoint("RIGHT", frame, "RIGHT", 0, 0);
        slider:SetMinMaxValues(option.Min, option.SoftMax);
        slider:SetValue(value);
        slider:SetValueStep(option.StepSize or 1);
        slider:SetObeyStepOnDrag(true);
        slider.Low:SetText(option.Min);
        slider.High:SetText(option.SoftMax);

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
            editBox:HighlightText(0, 0);
            local value = self:GetNumber();
            slider:SetValue(value);
            Set(option, value);
            self.isUpdating = false;
        end));

        frame:SetWidth(slider:GetWidth());
        frame:SetHeight(heading.fontHeight + editBox:GetHeight() + slider:GetHeight() + 4);
        slider:SetScript("OnValueChanged", EditorOnChange(function(self, value) 
            if (self.isUpdating) then return end;
            self.isUpdating = true;
            editBox:SetNumber(value);
            Set(option, value);
            self.isUpdating = false;
        end));
        frame.RefreshFromProfile = function(self) 
            local value = option.Get();
            print("RefreshFromProfile", value);
            slider:SetValue(value);
            editBox:SetNumber(floor(value));
            editBox:SetCursorPosition(0);
        end
        return frame;
    end
end