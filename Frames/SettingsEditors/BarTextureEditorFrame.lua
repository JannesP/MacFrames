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

local FrameUtil = _p.FrameUtil;
local BaseEditorFrame = _p.BaseEditorFrame;
local OptionType = _p.Settings.OptionType;

local LSM = LibStub("LibSharedMedia-3.0");
local _loadedAceGui = false;
local AceGUI, AceLSMWidgets;

_p.BarTextureEditorFrame = {};
local BarTextureEditorFrame = _p.BarTextureEditorFrame;

local _barSelectorCount = 0;

local function ChangedValue(option, newValue)
    option.Set(newValue);
end

local function RefreshFromProfile(self)
    local optionValue = self.option.Get();
    local valueToSet = optionValue;
    if (LSM:IsValid("statusbar", optionValue) == false) then
        valueToSet = "ERROR '" .. optionValue .. "' NOT FOUND!";
    end
    if (self.dropDown) then
        UIDropDownMenu_SetText(self.dropDown, valueToSet);
    end
    if (self.aceDropDown) then
        self.aceDropDown:SetValue(valueToSet);
    end
end

--###### AceGUI implementation ######

local function CreateAceGUIBarWidget()
    if (_loadedAceGui == false) then
        _loadedAceGui = true;
        AceGUI = LibStub("AceGUI-3.0", true);
        if (AceGUI ~= nil) then
            AceLSMWidgets = LibStub("AceGUISharedMediaWidgets-1.0", true);
        end
    end
    if (AceGUI and AceLSMWidgets) then
        return AceGUI:Create("LSM30_Statusbar");
    else
        return nil;
    end
end

local function AceWidgetOnValueChanged(widget, _, value)
    widget:SetValue(value);
    ChangedValue(widget.owner.option, value);
end

--###### Normal DropDown Fallback ######

local function DropDownBarItemSelected(dropDownButton, arg1BarTexture, arg2, checked)
    ChangedValue(dropDownButton.owner.option, arg1BarTexture);
end

local function DropDownSelectBarInit(frame, level, menuList)
    local editor = frame:GetParent();
    local currentTextureName = editor.option.Get();
    local info = UIDropDownMenu_CreateInfo();
    info.func = DropDownBarItemSelected;
    local registeredBars = LSM:List("statusbar");
    for i=1, #registeredBars do
        local textureName = registeredBars[i];
        info.text = textureName;
        info.arg1 = textureName;
        info.owner = editor;
        info.checked = textureName == currentTextureName;
        UIDropDownMenu_AddButton(info);
    end
end

--###### Constructor ######

function BarTextureEditorFrame.Create(parent, option)
    local value = option.Get();
    local frame = BaseEditorFrame.CreateBaseFrame(parent, option);

    _barSelectorCount = _barSelectorCount + 1;
    
    local dropDownWidth = frame:GetWidth() - 6;

    local dropDown;
    local aceWidget = CreateAceGUIBarWidget();
    if (aceWidget ~= nil) then
        frame.aceDropDown = dropDown;
        aceWidget.owner = frame;
        aceWidget:SetList();
        aceWidget:SetValue(value);
        aceWidget:SetCallback("OnValueChanged", AceWidgetOnValueChanged);
        aceWidget:SetWidth(dropDownWidth);
        aceWidget.frame:SetParent(frame);
        aceWidget.frame:SetPoint("CENTER", frame, "CENTER", 0, 0);
        aceWidget.frame:Show();
    else
        local dropDown = CreateFrame("Frame", "MacFramesDropdownBarTextureSelector" .. _barSelectorCount, frame, "UIDropDownMenuTemplate");
        frame.dropDown = dropDown;
        UIDropDownMenu_SetWidth(dropDown, dropDownWidth - 12);
        UIDropDownMenu_Initialize(dropDown, DropDownSelectBarInit);
        dropDown:SetPoint("CENTER", frame, "CENTER", 0, -10);
    end

    if (option.Description ~= nil) then
        FrameUtil.CreateTextTooltip(frame, option.Description, frame, 1, 1, 1, 1);
        if (dropDown) then
            FrameUtil.CreateTextTooltip(dropDown, option.Description, frame, 1, 1, 1, 1);
        end
        if (aceWidget) then
            FrameUtil.CreateTextTooltip(aceWidget, option.Description, frame, 1, 1, 1, 1);
        end
    end

    frame.RefreshFromProfile = BaseEditorFrame.CreateRefreshSettingsFromProfile(RefreshFromProfile);
    return frame;
end

BaseEditorFrame.AddConstructor(OptionType.BarTexture, BarTextureEditorFrame.Create);