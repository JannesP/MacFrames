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

local Constants = _p.Constants;
local FrameUtil = _p.FrameUtil;
local OptionType = _p.Settings.OptionType;
local PixelPerfect = _p.PixelPerfect;

_p.BaseEditorFrame = {};
local BaseEditorFrame = _p.BaseEditorFrame;

local _constructors = {};

function BaseEditorFrame.AddConstructor(type, func)
    if (_constructors[type] ~= nil) then error("Cannot register a type twice!"); end;
    _constructors[type] = func;
end

function BaseEditorFrame.CreateEditorOnChange(self, handler)
    return function(...)
        if (self.isRefreshingFromProfile) then return end;
        handler(...);
    end
end

function BaseEditorFrame.CreateNotYetImplemented(parent, option)
    local frame = BaseEditorFrame.CreateBaseFrame(parent, option);
    local text = FrameUtil.CreateText(frame, "Not yet implemented :(");
    PixelPerfect.SetPoint(text, "CENTER");
    frame.RefreshFromProfile = _p.Noop;
    frame.GetMeasuredSize = function(self)
        return text:GetSize();
    end
    return frame;
end

function BaseEditorFrame.CreateRefreshSettingsFromProfile(handler)
    return function(self)
        self.isRefreshingFromProfile = true;
        if (type(handler) == "table") then _p.Log(self); end;
        handler(self);
        self.isRefreshingFromProfile = false;
    end
end

local BaseEditorMixin = {};
function BaseEditorMixin:SetOptionValue(...)
    self.isChangingSettings = true;
    self.option.Set(...);
    self.isChangingSettings = false;
end
function BaseEditorMixin:IsChangingSettings()
    return self.isChangingSettings;
end
function BaseEditorMixin:GetDefaultHeight()
    return 30;
end
function BaseEditorMixin:SetDisabled(disabled)
    if (self.option.IsActive == nil) then return false; end
    if (self.disabled == disabled) then return false; end
    self.disabled = disabled;
    if (disabled) then
        self.disabledBlocker:Show();
    else
        self.disabledBlocker:Hide();
    end
    return true;
end

function BaseEditorFrame.Create(parent, option)
    if (_constructors[option.Type] == nil) then
        error("Couldn't find constructor for " .. option.Type);
    end
    return _constructors[option.Type](parent, option);
end

function BaseEditorFrame.CreateBaseFrame(parent, option)
    local frame = CreateFrame("Frame", nil, parent);
    frame.option = option;

    if (frame.option.IsActive) then
        frame.disabledBlocker = CreateFrame("Frame", nil, frame);
        frame.disabledBlocker:SetAllPoints(frame);
        frame.disabledBlocker:SetFrameLevel(200);
        frame.disabledBlocker:EnableMouse(true);
        frame.disabledBlocker:Hide();
        if (option.Description ~= nil) then
            FrameUtil.CreateTextTooltip(frame.disabledBlocker, option.Description, frame.disabledBlocker, "ANCHOR_LEFT", 0, 0, 1, 1, 1, 1);
        end
    end
    

    Mixin(frame, BaseEditorMixin);
    frame.isChangingSettings = false;
    return frame;
end

BaseEditorFrame.AddConstructor(OptionType.NotYetImplemented, BaseEditorFrame.CreateNotYetImplemented);