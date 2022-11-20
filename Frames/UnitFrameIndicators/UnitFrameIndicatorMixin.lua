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
local FramePool = _p.FramePool;
local L = _p.L;

_p.UnitFrameIndicator = {};
local UnitFrameIndicator = _p.UnitFrameIndicator;

UnitFrameIndicator.framePools = {};
UnitFrameIndicator.typeList = {};

function UnitFrameIndicator.TryGetFrame(type)
    local pool = UnitFrameIndicator.framePools[type];
    if (pool) then
        return pool:Take();
    end
    return nil;
end

function UnitFrameIndicator.PutFrameIntoPool(frame)
    local pool = UnitFrameIndicator.framePools[type];
    if (not pool) then
        pool = FramePool.Create();
        UnitFrameIndicator.framePools[frame:GetIndicatorType()] = pool;
    end
    pool:Put(frame);
    return nil;
end

function UnitFrameIndicator.Create(typeKey, unitFrame, alignTo, settings)
    if (type(typeKey) ~= "string") then
        error("typeKey must be a string.");
    end
    local indicatorDefinition = UnitFrameIndicator.typeList[typeKey];
    if (indicatorDefinition == nil) then
        error("Type " .. typeKey .. " not registered!");
    end
    return indicatorDefinition.constructor(unitFrame, alignTo, settings);
end

function UnitFrameIndicator.RegisterIndicatorType(typeKey, displayName, constructor)
    if (type(typeKey) ~= "string") then
        error("typeKey must be a string.");
    end
    if (UnitFrameIndicator.typeList[typeKey] ~= nil) then
        error("Type " .. typeKey .. " already registered!");
    end
    UnitFrameIndicator.typeList[typeKey] = {
        key = typeKey,
        displayName = L[displayName],
        constructor = constructor,
    };
end

UnitFrameIndicator.Events = {
    OnRequestedSizeChanged = "OnRequestedSizeChanged",
}

_p.UnitFrameIndicatorMixin = CreateFromMixins(CallbackRegistryMixin);
local UnitFrameIndicatorMixin = _p.UnitFrameIndicatorMixin;

function UnitFrameIndicatorMixin:Init(unitFrame, growDirection)
    if (not unitFrame) then error("unitFrame was nil") end;
    CallbackRegistryMixin.OnLoad(self);
    local events = {};
    for _, v in pairs(UnitFrameIndicator.Events) do
        tinsert(events, v);
    end 
    self:GenerateCallbackEvents(events);
    self:SetParent(unitFrame);
    self.unitFrame = unitFrame;
    self.growDirection = growDirection or UnitFrameIndicatorMixin.GrowDirection.Center;
    self.previewModeEnabled = false;
end

function UnitFrameIndicatorMixin:GetSettingsFrame()
    return nil;
end

function UnitFrameIndicatorMixin:SetAlignTo(alignTo)
    self.alignTo = alignTo;
end

function UnitFrameIndicatorMixin:GetAlignTo()
    return self.alignTo;
end

function UnitFrameIndicatorMixin:SetPreviewModeEnabled(enabled)
    self.previewModeEnabled = enabled;
end

function UnitFrameIndicatorMixin:IsPreviewModeEnabled()
    return self.previewModeEnabled;
end

function UnitFrameIndicatorMixin:RequiresFullLength()
    return true;
end

function UnitFrameIndicatorMixin:GetIndicatorType()
    error("This must be overridden!");
end

function UnitFrameIndicatorMixin:GetRequestedSize()
    error("This must be overridden!");
end

function UnitFrameIndicatorMixin:Destroy()
    self.unitFrame = nil;
    self.growDirection = nil;
    self.previewModeEnabled = nil;
    self.alignTo = nil;
    self.settings = nil;
    self:UnregisterEvents();
    wipe(self.Event);
    UnitFrameIndicator.PutFrameIntoPool(self);
end

