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

local Constants = _p.Constants;
local FrameUtil = _p.FrameUtil;

_p.BaseEditorFrame = {};
local BaseEditorFrame = _p.BaseEditorFrame;

function BaseEditorFrame.CreateEditorOnChange(self, handler)
    return function(...)
        if (self.isRefreshingFromProfile) then return end;
        handler(...);
    end
end

function BaseEditorFrame.CreateNotYetImplemented(parent, option)
    local frame = BaseEditorFrame.Create(parent, option);
    local text = FrameUtil.CreateText(frame, "Not yet implemented :(");
    text:SetPoint("TOP", frame.heading, "BOTTOM", 0, 0);
    text:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0);
    frame.RefreshFromProfile = _p.Noop;
end

function BaseEditorFrame.CreateRefreshSettingsFromProfile(handler)
    return function(self)
        self.isRefreshingFromProfile = true;
        if (type(handler) == "table") then _p.Log(self); end;
        handler(self);
        self.isRefreshingFromProfile = false;
    end
end

local function SetOptionValue(self, ...)
    self.isChangingSettings = true;
    self.option.Set(...);
    self.isChangingSettings = false;
end

local function IsChangingSettings(self)
    return self.isChangingSettings;
end

function BaseEditorFrame.Create(parent, option)
    local frame = CreateFrame("Frame", nil, parent);
    frame.option = option;

    frame.heading = FrameUtil.CreateText(frame, option.Name, nil, "GameFontNormalSmall");
    frame.heading.fontHeight = select(2, frame.heading:GetFont());
    frame.heading:ClearAllPoints();
    frame.heading:SetJustifyH("CENTER");
    frame.heading:SetPoint("TOP", frame, "TOP", 0, 0);

    frame:SetWidth(Constants.Settings.EditorWidth);
    frame:SetHeight(Constants.Settings.EditorHeight);

    frame.isChangingSettings = false;
    frame.IsChangingSettings = IsChangingSettings;
    frame.SetOptionValue = SetOptionValue;
    return frame;
end