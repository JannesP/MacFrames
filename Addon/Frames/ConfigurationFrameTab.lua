local ADDON_NAME, _p = ...;
local L = _p.L;
local ConfigurationOptions = _p.ConfigurationOptions;
local PlayerInfo = _p.PlayerInfo;
local FrameUtil = _p.FrameUtil;
local ProfileManager = _p.ProfileManager;
local PopupDisplays = _p.PopupDisplays;

_p.ConfigurationFrameTab = {};
local ConfigurationFrameTab = _p.ConfigurationFrameTab;

local CType = ConfigurationOptions.Type;
local CreateEditor, CreateProfileEditor, CreateSliderValueEditor;

function ConfigurationFrameTab.Create(parent, category)
    local options = category.Options;
    local frame = CreateFrame("Frame", nil, parent);
    frame.options = {};
    if (options[1].Type == CType.ProfileSelector) then
        local profileEditor = CreateProfileEditor(frame, options[1]);
        profileEditor:SetAllPoints(frame);
        tinsert(frame.options, profileEditor);
    else
        for i, option in ipairs(options) do
            local editor = CreateEditor(frame, option);
            tinsert(frame.options, editor);
        end
    
        local lastFrame = nil;
        for i, text in ipairs(frame.options) do
            text:SetWidth(400);
            text:ClearAllPoints();
            if (lastFrame == nil) then
                text:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0);
            else
                text:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, 0);
            end
            lastFrame = text;
        end
    end

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
    CreateProfileEditor = function(parent, option)
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
        return frame;
    end
end

CreateSliderValueEditor = function(parent, option)
    local frame = FrameUtil.CreateFrameWithText(parent, nil, option.Name);
    FrameUtil.WidthByText(frame, frame.text);
    frame:SetHeight(20);
    return frame;
end