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

_p.EnumDropDownEditorFrame = {};
local EnumDropDownEditorFrame = _p.EnumDropDownEditorFrame;

local _elementCount = 0;

local function ChangedValue(self, text, newValue)
    self.option.Set(newValue);
    if (not _p.isDragonflight) then
        UIDropDownMenu_SetText(self.dropDown, text);
    end
end

local function RefreshFromProfile(self)
    local text = MacEnum.GetByValue(self.option.EnumValues, self.option.Get())
    if (not _p.isDragonflight) then
        UIDropDownMenu_SetText(self.dropDown, L[text]);
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

MacFramesTextSelectionPopoutEntryDetailsMixin = {};
function MacFramesTextSelectionPopoutEntryDetailsMixin:GetTooltipText()
    return "Tooltip YEP";
end
function MacFramesTextSelectionPopoutEntryDetailsMixin:AdjustWidth(multipleColumns, width)
    self:SetWidth(width);
end
function MacFramesTextSelectionPopoutEntryDetailsMixin:SetupDetails(selectionData, index, isSelected, hasIneligibleChoice, hasLockedChoice)
    self.Text:SetText(selectionData.label);
    if (isSelected) then
        self.Text:SetTextColor(NORMAL_FONT_COLOR:GetRGB());
    else
        self.Text:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB());
    end
    self.Text:Show();
end

MacFramesTextSelectionPopoutEntryMixin = CreateFromMixins(SelectionPopoutEntryMixin);
function MacFramesTextSelectionPopoutEntryMixin:GetTooltipText()
	return self.SelectionDetails:GetTooltipText();
end

function MacFramesTextSelectionPopoutEntryMixin:OnEnter()
    SelectionPopoutEntryMixin.OnEnter(self);
    self.HighlightBGTex:SetAlpha(0.15);
end

function MacFramesTextSelectionPopoutEntryMixin:OnLeave()
    SelectionPopoutEntryMixin.OnLeave(self);
    self.HighlightBGTex:SetAlpha(0);
end

function MacFramesTextSelectionPopoutEntryMixin:OnClick()
    SelectionPopoutEntryMixin.OnClick(self);
end

do
    local function CreateNotDF(parent, option)
        local value = option.Get();
        local frame = BaseEditorFrame.CreateBaseFrame(parent, option);

        _elementCount = _elementCount + 1;
        
        local dropDownWidth = 140 - 6;

        local dropDown = CreateFrame("Frame", "MacFramesEnumDropDownEditorFrame" .. _elementCount, frame, "UIDropDownMenuTemplate");
        frame.dropDown = dropDown;
        UIDropDownMenu_SetWidth(dropDown, dropDownWidth - 12);
        UIDropDownMenu_Initialize(dropDown, DropDownSelectBarInit);
        dropDown:SetPoint("CENTER", frame, "CENTER", -14, -2);

        if (option.Description ~= nil) then
            FrameUtil.CreateTextTooltip(frame, option.Description, nil, frame, 0, 0, 1, 1, 1, 1);
            FrameUtil.CreateTextTooltip(dropDown, option.Description, nil, frame, 0, 0, 1, 1, 1, 1);
        end

        frame.RefreshFromProfile = BaseEditorFrame.CreateRefreshSettingsFromProfile(RefreshFromProfile);
        frame.GetMeasuredSize = EnumDropDownEditorFrame.GetMeasuredSize;
        return frame;
    end
    function EnumDropDownEditorFrame.Create(parent, option)
        if (not _p.isDragonflight) then
            return CreateNotDF(parent, option);
        end
        
        local optionValue = option.Get();
        local frame = BaseEditorFrame.CreateBaseFrame(parent, option);

        _elementCount = _elementCount + 1;
        
        local dropDownWidth = 140 - 6;

        local dropDown = CreateFrame("EventButton", nil, frame, "MacFramesTextDropDownButtonTemplate");
        frame.dropDown = dropDown;
        dropDown:SetPoint("LEFT", frame);
        dropDown:RegisterCallback("OnValueChanged", function(randomInt, selection)
            ChangedValue(selection.owner, selection.name, selection.value);
        end);
        dropDown:EnableMouseWheel(false);
        local selections = {};
        local selectedIndex = 1;
        for name, v in pairs(option.EnumValues) do
            local data = { label = name, value = v, owner = frame };
            tinsert(selections, data);
            if (data.value == optionValue) then
                selectedIndex = #selections;
            end
        end
        dropDown:SetupSelections(selections, selectedIndex);

        if (option.Description ~= nil) then
            --FrameUtil.CreateTextTooltip(frame, option.Description, nil, frame, 0, 0, 1, 1, 1, 1);
            --FrameUtil.CreateTextTooltip(dropDown, option.Description, nil, frame, 0, 0, 1, 1, 1, 1);
        end

        frame.RefreshFromProfile = BaseEditorFrame.CreateRefreshSettingsFromProfile(RefreshFromProfile);
        frame.GetMeasuredSize = EnumDropDownEditorFrame.GetMeasuredSize;
        return frame;
    end
end

function EnumDropDownEditorFrame:GetMeasuredSize()
    return self.dropDown:GetWidth(), self:GetDefaultHeight();
end

BaseEditorFrame.AddConstructor(OptionType.EnumDropDown, EnumDropDownEditorFrame.Create);