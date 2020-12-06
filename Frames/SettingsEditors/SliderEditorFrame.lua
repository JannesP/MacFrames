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

local BaseEditorFrame = _p.BaseEditorFrame;
local OptionType = _p.Settings.OptionType;
local FrameUtil = _p.FrameUtil;

_p.SliderEditorFrame = {};
local SliderEditorFrame = _p.SliderEditorFrame;


local function SliderEditBox_OnChange(self)
    if (self.isUpdating) then return end;
    self.isUpdating = true;

    local editorFrame = self.editorFrame;
    local option = editorFrame.option;

    local value = self:GetNumber();
    if (option.Min and option.Min > value) or (option.Max and option.Max < value) then
        --out of bounds value
        self:SetNumber(option.Get());
    else
        editorFrame.slider:SetValue(value);
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
        editorFrame.editBox:SetNumber(value);
        editorFrame:SetOptionValue(value);
        self.isUpdating = false;
end

local function SliderEditor_RefreshFromProfile(self)
    local value = self.option.Get();
    self.slider:SetValue(value);
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

    local slider = CreateFrame("Slider", nil, frame, "OptionsSliderTemplate");
    frame.slider = slider;
    slider.editorFrame = frame;
    slider:SetPoint("TOP", frame.heading, "BOTTOM", 0, 0);
    slider:SetPoint("LEFT", frame, "LEFT", 0, 0);
    slider:SetPoint("RIGHT", frame, "RIGHT", 0, 0);
    slider:SetMinMaxValues(option.Min, option.Max or option.SoftMax or error("Sliders need a maximum value (either SoftMax or Max)"));
    slider:SetValue(value);
    slider:SetValueStep(option.StepSize or 1);
    slider:SetObeyStepOnDrag(false);
    slider.Low:SetPoint("TOPLEFT", slider, "BOTTOMLEFT");
    slider.Low:SetText(option.Min);
    slider.High:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT");
    slider.High:SetText(option.Max or option.SoftMax);

    local editBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate");
    frame.editBox = editBox;
    editBox.editorFrame = frame;
    editBox:SetAutoFocus(false);
    editBox:SetNumeric(true);
    editBox:SetMaxLetters(3);
    editBox:SetNumber(value);
    editBox:SetWidth(27);
    editBox:ClearAllPoints();
    editBox:SetPoint("BOTTOM", frame, "BOTTOM", 0, 4);
    editBox:SetHeight(select(2, slider.Low:GetFont()));
    editBox:SetFrameLevel(slider:GetFrameLevel() + 1);
    
    editBox:SetScript("OnEnterPressed", EditBox_ClearFocus);
    editBox:SetScript("OnTabPressed", EditBox_ClearFocus);
    editBox:SetScript("OnEditFocusLost", BaseEditorFrame.CreateEditorOnChange(frame, SliderEditBox_OnChange));

    slider:SetScript("OnValueChanged", BaseEditorFrame.CreateEditorOnChange(frame, Slider_EditorOnChange));

    if (option.Description ~= nil) then
        FrameUtil.CreateTextTooltip(frame, option.Description, frame, 1, 1, 1, 1);
    end

    frame.RefreshFromProfile = BaseEditorFrame.CreateRefreshSettingsFromProfile(SliderEditor_RefreshFromProfile);
    return frame;
end

BaseEditorFrame.AddConstructor(OptionType.SliderValue, SliderEditorFrame.Create);