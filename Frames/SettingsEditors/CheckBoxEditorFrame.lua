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

_p.CheckBoxEditorFrame = {};
local CheckBoxEditorFrame = _p.CheckBoxEditorFrame;

local function RefreshFromProfile(self)
    self.checkBox:SetChecked(self.option.Get());
end

local function CheckBox_OnChange(self)
    self.editorFrame:SetOptionValue(self:GetChecked());
end

function CheckBoxEditorFrame.Create(parent, option)
    local value = option.Get();
    local frame = BaseEditorFrame.CreateBaseFrame(parent, option);

    local checkBox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate");
    frame.checkBox = checkBox;
    checkBox.editorFrame = frame;
    checkBox:SetPoint("TOP", frame.heading, "BOTTOM", 0, 0);
    checkBox:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0);

    checkBox:SetScript("OnClick", BaseEditorFrame.CreateEditorOnChange(frame, CheckBox_OnChange));

    if (option.Description ~= nil) then
        FrameUtil.CreateTextTooltip(frame, option.Description, frame, 1, 1, 1, 1);
        FrameUtil.CreateTextTooltip(checkBox, option.Description, frame, 1, 1, 1, 1);
    end

    frame.RefreshFromProfile = BaseEditorFrame.CreateRefreshSettingsFromProfile(RefreshFromProfile);
    return frame;
end

BaseEditorFrame.AddConstructor(OptionType.CheckBox, CheckBoxEditorFrame.Create);