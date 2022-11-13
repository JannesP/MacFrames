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

local BaseEditorFrame = _p.BaseEditorFrame;
local OptionType = _p.Settings.OptionType;
local PixelPerfect = _p.PixelPerfect;

_p.TextDropDownEditorFrame = {};
local TextDropDownEditorFrame = _p.TextDropDownEditorFrame;

local _elementCount = 0;

local TextDropDownEditorFrameMixin = {};
function TextDropDownEditorFrameMixin:GetMeasuredSize()
    return self.dropDown:GetWidth(), self:GetDefaultHeight();
end

function TextDropDownEditorFrameMixin:SetDisabled(disabled)
    local changed = BaseEditorFrame.Mixin.SetDisabled(self, disabled);
    if (changed) then
        self.dropDown:SetEnabled(not disabled);
    end
    return changed;
end

local function ChangedValue(self, text, newValue)
    self.option.Set(newValue);
end

local function RefreshFromProfile(self)
    local selectedValue = self.option.Get();
    self.dropDown:SetSelectedValue(selectedValue);
end

function TextDropDownEditorFrame.Create(parent, option)
    local optionValue = option.Get();
    local frame = BaseEditorFrame.CreateBaseFrame(parent, option);
    Mixin(frame, TextDropDownEditorFrameMixin);

    _elementCount = _elementCount + 1;

    local dropDown = CreateFrame("EventButton", nil, frame, "MacFramesTextDropDownButtonTemplate");
    frame.dropDown = dropDown;
    dropDown.editor = frame;
    PixelPerfect.SetPoint(dropDown, "LEFT", frame);
    dropDown:RegisterCallback("OnValueChanged", function(randomInt, selection)
        ChangedValue(selection.dropDown.editor, selection.displayText, selection.value);
    end);
    dropDown:EnableMouseWheel(false);

    dropDown:SetupFromMacFramesTextDropDownCollection(option.DropDownCollection, optionValue);

    frame.RefreshFromProfile = BaseEditorFrame.CreateRefreshSettingsFromProfile(RefreshFromProfile);
    return frame;
end

BaseEditorFrame.AddConstructor(OptionType.TextDropDown, TextDropDownEditorFrame.Create);