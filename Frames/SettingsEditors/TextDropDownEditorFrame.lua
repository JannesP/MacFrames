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
local L = _p.L;

local FrameUtil = _p.FrameUtil;
local BaseEditorFrame = _p.BaseEditorFrame;
local OptionType = _p.Settings.OptionType;
local MacEnum = _p.MacEnum;

_p.TextDropDownEditorFrame = {};
local TextDropDownEditorFrame = _p.TextDropDownEditorFrame;

local _elementCount = 0;

local function ChangedValue(self, text, newValue)
    self.option.Set(newValue);
    if (not _p.isDragonflight) then
        UIDropDownMenu_SetText(self.dropDown, text);
    end
end

local function RefreshFromProfile(self)
    local entry = self.option.DropDownCollection:GetByValue(self.option.Get());
    if (not _p.isDragonflight) then
        UIDropDownMenu_SetText(self.dropDown, L[entry.displayText]);
    end
end

local function DropDownBarItemSelected(dropDownButton, arg1Text, arg2Key, checked)
    ChangedValue(dropDownButton.owner, arg1Text, arg2Key);
end

local function DropDownSelectBarInit(frame, level, menuList)
    local editor = frame:GetParent();
    local selectedValue = editor.option.Get();
    local info = UIDropDownMenu_CreateInfo();
    info.func = DropDownBarItemSelected;
    local collection = editor.option.DropDownCollection;
    for i, data in ipairs(collection:GetEntries()) do
        info.text = L[data.displayText];
        info.arg1 = info.text;
        info.arg2 = data.value;
        info.owner = editor;
        info.checked = selectedValue == data.value;
        UIDropDownMenu_AddButton(info);
    end
end

do
    local function CreateNotDF(parent, option)
        local value = option.Get();
        local frame = BaseEditorFrame.CreateBaseFrame(parent, option);

        _elementCount = _elementCount + 1;
        
        local dropDownWidth = 140 - 6;

        local dropDown = CreateFrame("Frame", "MacFramesTextDropDownEditorFrame" .. _elementCount, frame, "UIDropDownMenuTemplate");
        frame.dropDown = dropDown;
        UIDropDownMenu_SetWidth(dropDown, dropDownWidth - 12);
        UIDropDownMenu_Initialize(dropDown, DropDownSelectBarInit);
        dropDown:SetPoint("CENTER", frame, "CENTER", -14, -2);

        if (option.Description ~= nil) then
            FrameUtil.CreateTextTooltip(frame, option.Description, nil, frame, 0, 0, 1, 1, 1, 1);
            FrameUtil.CreateTextTooltip(dropDown, option.Description, nil, frame, 0, 0, 1, 1, 1, 1);
        end

        frame.RefreshFromProfile = BaseEditorFrame.CreateRefreshSettingsFromProfile(RefreshFromProfile);
        frame.GetMeasuredSize = TextDropDownEditorFrame.GetMeasuredSize;
        return frame;
    end
    function TextDropDownEditorFrame.Create(parent, option)
        if (not _p.isDragonflight) then
            return CreateNotDF(parent, option);
        end
        
        local optionValue = option.Get();
        local frame = BaseEditorFrame.CreateBaseFrame(parent, option);

        _elementCount = _elementCount + 1;
        
        local dropDownWidth = 140 - 6;

        local dropDown = CreateFrame("EventButton", nil, frame, "MacFramesTextDropDownButtonTemplate");
        frame.dropDown = dropDown;
        dropDown.editor = frame;
        dropDown:SetPoint("LEFT", frame);
        dropDown:RegisterCallback("OnValueChanged", function(randomInt, selection)
            ChangedValue(selection.dropDown.editor, selection.displayText, selection.value);
        end);
        dropDown:EnableMouseWheel(false);

        dropDown:SetupFromMacFramesTextDropDownCollection(option.DropDownCollection, optionValue);

        if (option.Description ~= nil) then
            --FrameUtil.CreateTextTooltip(frame, option.Description, nil, frame, 0, 0, 1, 1, 1, 1);
            --FrameUtil.CreateTextTooltip(dropDown, option.Description, nil, frame, 0, 0, 1, 1, 1, 1);
        end

        frame.RefreshFromProfile = BaseEditorFrame.CreateRefreshSettingsFromProfile(RefreshFromProfile);
        frame.GetMeasuredSize = TextDropDownEditorFrame.GetMeasuredSize;
        return frame;
    end
end

function TextDropDownEditorFrame:GetMeasuredSize()
    return self.dropDown:GetWidth(), self:GetDefaultHeight();
end

function TextDropDownEditorFrame.CreateEntryCollection()
    return CreateFromMixins(MacFramesTextDropDownCollectionMixin);
end

BaseEditorFrame.AddConstructor(OptionType.TextDropDown, TextDropDownEditorFrame.Create);