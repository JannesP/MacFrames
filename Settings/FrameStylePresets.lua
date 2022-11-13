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

_p.FrameStylePresets = {};
local FrameStylePresets = _p.FrameStylePresets;

local function CreateRGB(r, g, b)
    return {
        r = r,
        g = g or r,
        b = b or r,
    };
end

local function DoSettingsMatchProfileData(preset, setting)
    if (type(preset) ~= type(setting)) then return false; end
    if (type(preset) == "table") then
        for key, value in pairs(preset) do
            if (not DoSettingsMatchProfileData(value, setting[key])) then
                return false;
            end
        end
        return true;
    end
    return preset == setting;
end

local function SetPresetOnSettings(preset, setting)
    if (type(preset) ~= "table" or type(setting) ~= "table") then
        error("This can only be called with tables.");
    end
    for key, value in pairs(preset) do
        if (type(value) == "table") then
            if (type(setting[key]) ~= "table") then
                error("Setting structure didn't match preset: " .. key .. " in setting was not a table.");
            end
            SetPresetOnSettings(value, setting[key]);
        else 
            if (type(setting[key]) == "table") then
                error("Setting structure didn't match preset: " .. key .. " in setting was a table.");
            end
            setting[key] = value;
        end
    end
end

FrameStylePresets.Presets = {
    [1] = {
        key = "Custom",
        name = L["Custom"],
    },
    [2] = {
        key = "Default",
        name = L["Default"],
        data = {
            HealthBarUseClassColor = true,
            HealthBarMissingHealthColor = CreateRGB(0.1),
            HealthBarDisconnectedColor = CreateRGB(0.5),
            NameFont = {
                UseClassColor = false,
                ManualColor = CreateRGB(1),
            },
        },
    },
    [3] = {
        key = "Dark",
        name = L["Dark"],
        data = {
            HealthBarUseClassColor = false,
            HealthBarManualColor = CreateRGB(0.15),
            HealthBarMissingHealthColor = CreateRGB(0.85),
            HealthBarDisconnectedColor = CreateRGB(0.5),
            NameFont = {
                UseClassColor = true,
            },
        },
    },
    [4] = {
        key = "Light",
        name = L["Light"],
        data = {
            HealthBarUseClassColor = false,
            HealthBarManualColor = CreateRGB(0.95),
            HealthBarMissingHealthColor = CreateRGB(0.15),
            HealthBarDisconnectedColor = CreateRGB(0.5),
            NameFont = {
                UseClassColor = true,
            },
        },
    },
}
FrameStylePresets.PresetsByKey = {};
for i = 1, #FrameStylePresets.Presets do
    local preset = FrameStylePresets.Presets[i];
    FrameStylePresets.PresetsByKey[preset.key] = preset;
end

function FrameStylePresets:CreateDropDownCollection()
    local collection = CreateFromMixins(MacFramesTextDropDownCollectionMixin);
    for i = 1, #FrameStylePresets.Presets do
        local preset = FrameStylePresets.Presets[i];
        collection:Add(preset.key, preset.name, nil);
    end
    return collection;
end

function FrameStylePresets:ApplyPreset(presetKey, setting)
    local preset = FrameStylePresets.PresetsByKey[presetKey];
    if (preset.data) then
        SetPresetOnSettings(preset.data, setting);
    end
end

function FrameStylePresets:GetPresetName(presetKey)
    return FrameStylePresets.PresetsByKey[presetKey].name;
end

function FrameStylePresets:GetSelectedPreset(setting)
    for _, value in ipairs(FrameStylePresets.Presets) do
        if (value.data) then
            if (DoSettingsMatchProfileData(value.data, setting)) then
                return value.key;
            end
        end
    end
    return FrameStylePresets.Presets[1].key;
end