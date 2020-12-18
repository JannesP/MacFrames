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

local FrameUtil = _p.FrameUtil;
local BaseEditorFrame = _p.BaseEditorFrame;
local OptionType = _p.Settings.OptionType;
local MacEnum = _p.MacEnum;

_p.EnumDropDownEditorFrame = {};
local EnumDropDownEditorFrame = _p.EnumDropDownEditorFrame;

local _elementCount = 0;

local function ChangedValue(self, text, newValue)
    self.option.Set(newValue);
    UIDropDownMenu_SetText(self.dropDown, text);
end

local function RefreshFromProfile(self)
    local text = MacEnum.GetByValue(self.option.EnumValues, self.option.Get())
    UIDropDownMenu_SetText(self.dropDown, L[text]);
end

local function DropDownBarItemSelected(dropDownButton, arg1Text, arg2Key, checked)
    ChangedValue(dropDownButton.owner, arg1Text, arg2Key);
end

local function DropDownSelectBarInit(frame, level, menuList)
    local editor = frame:GetParent();
    local selectedValue = editor.option.Get();
    local info = UIDropDownMenu_CreateInfo();
    info.func = DropDownBarItemSelected;
    local enum = editor.option.EnumValues;
    for k, v in pairs(enum) do
        info.text = L[k];
        info.arg1 = info.text;
        info.arg2 = v;
        info.owner = editor;
        info.checked = selectedValue == v;
        UIDropDownMenu_AddButton(info);
    end
end

--###### Constructor ######

function EnumDropDownEditorFrame.Create(parent, option)
    local value = option.Get();
    local frame = BaseEditorFrame.CreateBaseFrame(parent, option);

    _elementCount = _elementCount + 1;
    
    local dropDownWidth = frame:GetWidth() - 6;

    local dropDown = CreateFrame("Frame", "MacFramesEnumDropDownEditorFrame" .. _elementCount, frame, "UIDropDownMenuTemplate");
    frame.dropDown = dropDown;
    UIDropDownMenu_SetWidth(dropDown, dropDownWidth - 12);
    UIDropDownMenu_Initialize(dropDown, DropDownSelectBarInit);
    dropDown:SetPoint("CENTER", frame, "CENTER", 0, -10);

    if (option.Description ~= nil) then
        FrameUtil.CreateTextTooltip(frame, option.Description, frame, 1, 1, 1, 1);
        FrameUtil.CreateTextTooltip(dropDown, option.Description, frame, 1, 1, 1, 1);
    end

    frame.RefreshFromProfile = BaseEditorFrame.CreateRefreshSettingsFromProfile(RefreshFromProfile);
    return frame;
end

BaseEditorFrame.AddConstructor(OptionType.EnumDropDown, EnumDropDownEditorFrame.Create);