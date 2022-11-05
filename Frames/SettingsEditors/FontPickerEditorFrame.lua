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

local FrameUtil = _p.FrameUtil;
local BaseEditorFrame = _p.BaseEditorFrame;
local OptionType = _p.Settings.OptionType;
local PixelPerfect = _p.PixelPerfect;

local LSM = LibStub("LibSharedMedia-3.0");
local _loadedAceGui = false;
local AceGUI, AceLSMWidgets;

local _width = 240;

_p.FontPickerEditorFrame = {};
local FontPickerEditorFrame = _p.FontPickerEditorFrame;

local _fontPickerCount = 0;

local function ChangedValue(option, newValue)
    option.Set(newValue);
end

local function RefreshFromProfile(self)
    local optionValue = self.option.Get();
    local valueToSet = optionValue;
    if (LSM:IsValid("font", optionValue) == false) then
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

local function CreateAceGUIFontWidget()
    if (_loadedAceGui == false) then
        _loadedAceGui = true;
        AceGUI = LibStub("AceGUI-3.0", true);
        if (AceGUI ~= nil) then
            AceLSMWidgets = LibStub("AceGUISharedMediaWidgets-1.0", true);
        end
    end
    if (AceGUI and AceLSMWidgets) then
        return AceGUI:Create("LSM30_Font");
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
    local currentFontName = editor.option.Get();
    local info = UIDropDownMenu_CreateInfo();
    info.func = DropDownBarItemSelected;
    local registeredBars = LSM:List("font");
    for i=1, #registeredBars do
        local fontName = registeredBars[i];
        info.text = fontName;
        info.arg1 = fontName;
        info.owner = editor;
        info.checked = fontName == currentFontName;
        UIDropDownMenu_AddButton(info);
    end
end

--###### Constructor ######

function FontPickerEditorFrame.Create(parent, option)
    local value = option.Get();
    local frame = BaseEditorFrame.CreateBaseFrame(parent, option);

    _fontPickerCount = _fontPickerCount + 1;
    
    local dropDownWidth = _width - 6;

    local dropDown;
    local aceWidget = CreateAceGUIFontWidget();
    if (aceWidget ~= nil) then
        frame.aceDropDown = dropDown;
        aceWidget.owner = frame;
        aceWidget:SetList();
        aceWidget:SetValue(value);
        aceWidget:SetCallback("OnValueChanged", AceWidgetOnValueChanged);
        aceWidget.frame:SetParent(frame);
        aceWidget.frame:SetPoint("CENTER", frame, "CENTER", 0, 10);
        aceWidget:SetWidth(dropDownWidth);
        aceWidget.frame:Show();
    else
        local dropDown = CreateFrame("Frame", "MacFramesFontPickerEditorFrame" .. _fontPickerCount, frame, "UIDropDownMenuTemplate");
        frame.dropDown = dropDown;
        UIDropDownMenu_SetWidth(dropDown, dropDownWidth - 12);
        UIDropDownMenu_Initialize(dropDown, DropDownSelectBarInit);
        PixelPerfect.SetPoint(dropDown, "CENTER", frame, "CENTER", 0, -2);
    end

    if (option.Description ~= nil) then
        FrameUtil.CreateTextTooltip(frame, option.Description, frame, nil, 0, 0, 1, 1, 1, 1);
        if (dropDown) then
            FrameUtil.CreateTextTooltip(dropDown, option.Description, frame, nil, 0, 0, 1, 1, 1, 1);
        end
        if (aceWidget) then
            FrameUtil.CreateTextTooltip(aceWidget.frame, option.Description, frame, nil, 0, 0, 1, 1, 1, 1);
        end
    end

    frame.RefreshFromProfile = BaseEditorFrame.CreateRefreshSettingsFromProfile(RefreshFromProfile);
    frame.GetMeasuredSize = FontPickerEditorFrame.GetMeasuredSize;
    return frame;
end

function FontPickerEditorFrame:GetMeasuredSize()
    return _width, self:GetDefaultHeight();
end

BaseEditorFrame.AddConstructor(OptionType.FontPicker, FontPickerEditorFrame.Create);