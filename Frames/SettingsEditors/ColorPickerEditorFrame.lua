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
local PixelPerfect = _p.PixelPerfect;

_p.ColorPickerEditorFrame = {};
local ColorPickerEditorFrame = _p.ColorPickerEditorFrame;

local _elementCount = 0;

local ColorPreviewMixin = {};
function ColorPreviewMixin:Init(r, g, b)
    self.NineSlice.Center:SetColorTexture(1, 1, 1, 1);
    self:SetBackdropColor(r, g, b, 1);
end
function ColorPreviewMixin:SetColor(r, g, b)
    self:SetBackdropColor(r, g, b, 1);
end

local function ValidateRGBValues(r, g, b)
    if (type(r) ~= "number" or r < 0 or r > 1) then error("r was not a valid color value: " .. r) end
    if (type(g) ~= "number" or g < 0 or g > 1) then error("g was not a valid color value: " .. g) end
    if (type(b) ~= "number" or b < 0 or b > 1) then error("b was not a valid color value: " .. b) end
end

local function ShowColorPicker(r, g, b, a, changedCallback)
    ColorPickerFrame.hasOpacity, ColorPickerFrame.opacity = (a ~= nil), a;
    ColorPickerFrame.previousValues = { r, g, b, a };
    ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = 
     changedCallback, changedCallback, changedCallback;
    ColorPickerFrame:SetColorRGB(r, g, b);
    ColorPickerFrame:Hide(); -- Need to run the OnShow handler.
    ColorPickerFrame:Show();
end

local DropDownValues = {
    [1] = { value = "Custom", name = L["Custom"] },
    [2] = { value = "White", name = L["White"], color = { r = 1, g = 1, b = 1 } },
    [3] = { value = "Black", name = L["Black"], color = { r = 0, g = 0, b = 0 } },
    [4] = { value = "Red", name = L["Red"], color = { r = 0.9, g = 0.2, b = 0.2 } },
    [5] = { value = "Green", name = L["Green"], color = { r = 0.2, g = 0.9, b = 0.2 } },
    [6] = { value = "Blue", name = L["Blue"], color = { r = 0.2, g = 0.2, b = 0.9 } },
    [7] = { value = "VeryDarkGray", name = L["Very Dark Gray"], color = { r = 0.15, g = 0.15, b = 0.15 } },
    [8] = { value = "VeryLightGray", name = L["Very Light Gray"], color = { r = 0.85, g = 0.85, b = 0.85 } },
};

local DropDownCollection = CreateFromMixins(MacFramesTextDropDownCollectionMixin);
for i=1, #DropDownValues do
    local value = DropDownValues[i];
    DropDownCollection:Add(value.value, value.name, value.color and ("R: " .. value.color.r .. ", G: " .. value.color.g .. ", B: " .. value.color.b));
end

local function GetSelectedDropDownIndexByColor(r, g, b)
    for i=1, #DropDownValues do
        local value = DropDownValues[i];
        if (value.color) then
            if (value.color.r == r and value.color.g == g and value.color.b == b) then
                return i;
            end
        end
    end
    return 1;
end
local function GetSelectedDropDownValueByColor(r, g, b)
    return DropDownValues[GetSelectedDropDownIndexByColor(r, g, b)];
end

local function ColorPicker_RefreshFromProfile(self)
    local r, g, b = self.option.Get();
    self.colorPreview:SetColor(r, g, b);
    self.dropDownColor:SetSelectedIndex(GetSelectedDropDownIndexByColor(r, g, b));
end

local function SetOptionValueInternal(self, r, g, b)
    ValidateRGBValues(r, g, b);
    self.dropDownColor:SetSelectedIndex(GetSelectedDropDownIndexByColor(r, g, b));
    self.colorPreview:SetColor(r, g, b);
    self:SetOptionValue(r, g, b);
end

local function DropDown_ChangedValue(self, text, newValue)
    if (newValue == "Custom") then
        return;
    end
    for i=1, #DropDownValues do
        local value = DropDownValues[i];
        if (value.value == newValue) then
            if (value.color) then
                SetOptionValueInternal(self, value.color.r, value.color.g, value.color.b);
                return;
            end
        end
    end
end

local function ColorPickerColorChange(frame, restore)
    local r, g, b;
    if (restore) then
        r, g, b = unpack(restore, 1, 3);
    else
        r, g, b = ColorPickerFrame:GetColorRGB();
    end
    
    SetOptionValueInternal(frame, r, g, b);
end

function ColorPickerEditorFrame.Create(parent, option)
    local valueR, valueG, valueB = option.Get();
    local frame = BaseEditorFrame.CreateBaseFrame(parent, option);

    _elementCount = _elementCount + 1;

    frame.colorPreview = CreateFrame("Button", nil, frame, "TooltipBorderedFrameTemplate");
    Mixin(frame.colorPreview, ColorPreviewMixin);
    frame.colorPreview:Init(valueR, valueG, valueB);
    frame.colorPreview:SetScript("OnClick", function()
        local r, g, b = option.Get();
        ShowColorPicker(r, g, b, nil, function(...) ColorPickerColorChange(frame, ...) end);
    end);
    FrameUtil.CreateTextTooltip(frame.colorPreview, L["Click to change!"], nil, frame.colorPreview, 0, 0, 1, 1, 1, 1);

    PixelPerfect.SetPoint(frame.colorPreview, "LEFT", frame, "LEFT");
    local colorPreviewSize = frame:GetDefaultHeight();
    PixelPerfect.SetSize(frame.colorPreview, colorPreviewSize * 2, colorPreviewSize);

    frame.dropDownColor = CreateFrame("EventButton", nil, frame, "MacFramesTextDropDownButtonTemplate");
    frame.dropDownColor.editor = frame;
    frame.dropDownColor:RegisterCallback("OnValueChanged", function(randomInt, selection)
        DropDown_ChangedValue(selection.dropDown.editor, selection.displayText, selection.value);
    end);
    frame.dropDownColor:EnableMouseWheel(false);
    frame.dropDownColor:SetupFromMacFramesTextDropDownCollection(DropDownCollection, GetSelectedDropDownValueByColor(valueR, valueG, valueB));
    PixelPerfect.SetPoint(frame.dropDownColor, "LEFT", frame.colorPreview, "RIGHT", 4, 0);

    if (option.Description ~= nil) then
        
    end

    frame.RefreshFromProfile = BaseEditorFrame.CreateRefreshSettingsFromProfile(ColorPicker_RefreshFromProfile);
    frame.GetMeasuredSize = ColorPickerEditorFrame.GetMeasuredSize;
    return frame;
end

function ColorPickerEditorFrame:GetMeasuredSize()
    return 200, self:GetDefaultHeight();
end

BaseEditorFrame.AddConstructor(OptionType.ColorPicker, ColorPickerEditorFrame.Create);