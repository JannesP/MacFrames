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

local BaseEditorFrame = _p.BaseEditorFrame;
local OptionType = _p.Settings.OptionType;
local FrameUtil = _p.FrameUtil;
local PixelPerfect = _p.PixelPerfect;

_p.SliderEditorFrame = {};
local SliderEditorFrame = _p.SliderEditorFrame;

local _isInitialLoad = true;

local function SliderEditBox_OnChange(self)
    if (self.isUpdating) then return end;
    self.isUpdating = true;

    local editorFrame = self.editorFrame;
    local option = editorFrame.option;

    local value = self:GetNumber();
    if (option.Rounded) then
        value = Round(value);
    end
    if (option.Min and option.Min > value) or (option.Max and option.Max < value) then
        --out of bounds value
        self:SetNumber(option.Get());
    else
        editorFrame.slider.Slider:SetValue(value);
        editorFrame:SetOptionValue(value);
    end
    self:HighlightText(0, 0);
    self:SetCursorPosition(0);
    self.isUpdating = false;
end

local function Slider_EditorOnChange(self, value)
    if (self.isUpdating) then return end;
    self.isUpdating = true;
    local editorFrame = self.editorFrame;
    local option = editorFrame.option;
    if (option.Rounded) then
        value = Round(value);
    end
    editorFrame.editBox:SetNumber(Round(value));
    editorFrame:SetOptionValue(value);
    self.isUpdating = false;
end

local function SliderEditor_RefreshFromProfile(self)
    local value = self.option.Get();
    if (_isInitialLoad and self.option.Rounded) then
        _isInitialLoad = false;
        self.isUpdating = true;
        value = Round(value);
        self:SetOptionValue(value);
        self.isUpdating = false;
    end
    self.slider.Slider:SetValue(value);
    self.slider.Slider:SetValue(value);
    self.editBox:SetNumber(Round(value));
    self.editBox:SetCursorPosition(0);
end

function SliderEditorFrame.Create(parent, option)
    local value = option.Get();
    if (value == nil) then
        error("Value for " .. option.Name .. " was nil!");
    end
    local frame = BaseEditorFrame.CreateBaseFrame(parent, option);
    frame.option = option;

    local slider = CreateFrame("Frame", nil, frame, "MinimalSliderWithSteppersTemplate");
    frame.slider = slider;
    slider.Slider.editorFrame = frame;
    PixelPerfect.SetPoint(slider, "LEFT", frame);
    PixelPerfect.SetWidth(slider, 250);
    slider.Slider:SetMinMaxValues(option.Min, option.Max or option.SoftMax or error("Sliders need a maximum value (either SoftMax or Max)"));
    slider.Slider:SetValue(value);
    slider.Slider:SetValueStep(option.StepSize or 1);
    slider.Slider:SetObeyStepOnDrag(false);

    local editBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate");
    frame.editBox = editBox;
    editBox.editorFrame = frame;
    editBox:SetAutoFocus(false);
    editBox:SetNumeric(true);
    editBox:SetMaxLetters(3);
    editBox:SetNumber(value);
    PixelPerfect.SetWidth(editBox, 27);
    editBox:ClearAllPoints();
---@diagnostic disable-next-line: param-type-mismatch
    PixelPerfect.SetPoint(editBox, "LEFT", slider, "RIGHT", 5, 0);
    PixelPerfect.SetHeight(editBox, select(2, editBox:GetFont()));
    editBox:SetFrameLevel(slider:GetFrameLevel() + 1);

    local rangeTextContent = "(" .. option.Min .. "-" .. (option.Max or option.SoftMax) .. (option.SoftMax and "+" or "") .. ")";
    local rangeText = FrameUtil.CreateText(frame, rangeTextContent, nil, "GameFontDisable");
    frame.rangeText = rangeText;
    PixelPerfect.SetPoint(rangeText, "LEFT", editBox, "RIGHT", 4, 0);
    
    editBox:SetScript("OnEnterPressed", EditBox_ClearFocus);
    editBox:SetScript("OnTabPressed", EditBox_ClearFocus);
    editBox:SetScript("OnEditFocusLost", BaseEditorFrame.CreateEditorOnChange(frame, SliderEditBox_OnChange));

    slider.Slider:SetScript("OnValueChanged", BaseEditorFrame.CreateEditorOnChange(frame, Slider_EditorOnChange));

    if (option.Description ~= nil) then
        FrameUtil.CreateTextTooltip(frame, option.Description, frame, nil, 0, 0, 1, 1, 1, 1);
    end

    frame.RefreshFromProfile = BaseEditorFrame.CreateRefreshSettingsFromProfile(SliderEditor_RefreshFromProfile);
    frame.GetMeasuredSize = SliderEditorFrame.GetMeasuredSize;
    frame.GetMeasuredSizeInternal = SliderEditorFrame.GetMeasuredSizeInternal;
    return frame;
end

function SliderEditorFrame:GetMeasuredSize()
    local width = self.slider:GetWidth() + 5 + self.editBox:GetWidth() + self.rangeText:GetWidth();
    local height = self:GetDefaultHeight();
    return width, height;
end

BaseEditorFrame.AddConstructor(OptionType.SliderValue, SliderEditorFrame.Create);