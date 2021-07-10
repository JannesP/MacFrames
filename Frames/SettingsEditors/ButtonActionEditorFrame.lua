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

_p.ButtonActionEditorFrame = {};
local ButtonActionEditorFrame = _p.ButtonActionEditorFrame;

local _elementCount = 0;

local function Button_OnClick(self)
    print("test");
    self.editorFrame:SetOptionValue();
end

function ButtonActionEditorFrame.Create(parent, option)
    local value = option.Get();
    local frame = BaseEditorFrame.CreateBaseFrame(parent, option);

    _elementCount = _elementCount + 1;
    local buttonCenterFrame = CreateFrame("Frame", nil, frame);
    buttonCenterFrame:SetPoint("TOP", frame.heading, "BOTTOM", 0, 0);
    buttonCenterFrame:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0);
    buttonCenterFrame:SetPoint("RIGHT");
    buttonCenterFrame:SetPoint("LEFT");
    local button = FrameUtil.CreateTextButton(buttonCenterFrame, nil, option.ButtonText, BaseEditorFrame.CreateEditorOnChange(frame, Button_OnClick));
    frame.button = button;
    button.editorFrame = frame;
    button:SetPoint("RIGHT");
    button:SetPoint("LEFT");

    if (option.Description ~= nil) then
        FrameUtil.CreateTextTooltip(frame, option.Description, frame, 1, 1, 1, 1);
        --FrameUtil.CreateTextTooltip(button, option.Description, frame, 1, 1, 1, 1);
    end

    frame.RefreshFromProfile = BaseEditorFrame.CreateRefreshSettingsFromProfile(_p.Noop);
    return frame;
end

BaseEditorFrame.AddConstructor(OptionType.ButtonAction, ButtonActionEditorFrame.Create);