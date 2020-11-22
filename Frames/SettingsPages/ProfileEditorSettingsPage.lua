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

_p.ProfileEditorSettingsPage = {};
local ProfileEditorSettingsPage = _p.ProfileEditorSettingsPage;

local math_max = math.max;

local L = _p.L;
local FrameUtil = _p.FrameUtil;
local PopupDisplays =_p.PopupDisplays;
local ProfileManager = _p.ProfileManager;
local PlayerInfo = _p.PlayerInfo;

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
function ProfileEditorSettingsPage.Create(parent)
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

    frame.seperatorProfileSelect = FrameUtil.CreateHorizontalSeperatorWithText(frame, L["Select Profiles"]);
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

    frame.RefreshFromProfile = _p.Noop;
    frame.Layout = _p.Noop;
    frame.IsChangingSettings = function () return false; end;
    frame:SetHeight(totalHeight);

    ProfileManager.RegisterProfileListChangedListener(RefreshDropDownTexts);
    return frame;
end
