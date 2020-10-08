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

local ProfileSettingsTypes = _p.ProfileSettingsTypes;

_p.Profile = {};
local Profile = _p.Profile;

local _currentProfileVersion = _p.DefaultProfileSettings.Version;

local CreateWrapper, NewWrapper, NewArrayWrapper;
do
    local function Wrapper_OnPropertyChanged(self, key)
        for callback, _ in pairs(self._propertyChangedListeners) do
            callback(key);
        end
    end
    local function Wrapper_RegisterPropertyChanged(self, callback)
        self._propertyChangedListeners[callback] = true;
    end
    local function Wrapper_UnregisterPropertyChanged(self, callback)
        self._propertyChangedListeners[callback] = nil;
    end
    local function Wrapper_RegisterAllPropertyChanged(self, callback)
        self:RegisterPropertyChanged(callback);
        for _, setting in pairs(self._settings) do
            if (type(setting) == "table") then
                setting:RegisterAllPropertyChanged(callback);
            end
        end
    end
    local function Wrapper_UnregisterAllPropertyChanged(self, callback)
        self:UnregisterPropertyChanged(callback);
        for _, setting in pairs(self._settings) do
            if (type(setting) == "table") then
                setting:UnregisterAllPropertyChanged(callback);
            end
        end
    end
    local function Wrapper_GetRawEntries(self)
        return self._settings;
    end
    local function Wrapper_Metatable__index(self, key)
        local result = self._settings[key];
        if (result == nil) then
            local default = self._defaults[key];
            if (default ~= nil) then
                _p.Log("Loading default ("..key.."): "..tostring(default));
                result = CreateWrapper(default);
                self._settings[key] = result;
            end
        end
        return result;
    end
    local function Wrapper_Metatable__newindex(self, key, value)
        if (type(value) == "table") then
            error("Cannot assign tables to normal settings!");
        end
        if (InCombatLockdown()) then
            error("Cannot change settings in combat!");
        end
        if (self._settings[key] ~= value) then
            print("Changing ", key, " value: ", value);
            self._settings[key] = value;
            self:OnPropertyChanged(key);
        end
    end

    local function ArrayWrapper_Metatable__newindex(self, key, value)
        if (type(key) ~= "number" or key ~= math.floor(key)) then
            error("Only integers can be used on array settings!");
        end
        print("Changing ", key, " value: ", tostring(value));
        self._settings[key] = value;
        self:OnPropertyChanged(key);
    end
    local function ArrayWrapper_Metatable__len(self)
        return #self._settings;
    end
    local function ArrayWrapper_Add(self, value)
        tinsert(self._settings, value);
        self:OnPropertyChanged(#self._settings);
    end
    local function ArrayWrapper_Remove(self, index)
        local settings = self._settings;
        if (#settings == index) then
            tremove(self._settings);
            self:OnPropertyChanged(index);
        else
            tremove(self._settings, index);
            self:OnPropertyChanged(nil);
        end
    end
    NewWrapper = function(defaults)
        return setmetatable({
                _defaults = defaults,
                _settings = {},
                _propertyChangedListeners = {},
                _settingsType = ProfileSettingsTypes.Properties,
                OnPropertyChanged = Wrapper_OnPropertyChanged,
                RegisterPropertyChanged = Wrapper_RegisterPropertyChanged,
                UnregisterPropertyChanged = Wrapper_UnregisterPropertyChanged,
                RegisterAllPropertyChanged = Wrapper_RegisterAllPropertyChanged,
                UnregisterAllPropertyChanged = Wrapper_UnregisterAllPropertyChanged,
                GetRawEntries = Wrapper_GetRawEntries,
            }, {
                __index = Wrapper_Metatable__index,
                __newindex = Wrapper_Metatable__newindex,
            }
        );
    end
    NewArrayWrapper = function()
        return setmetatable({
                _defaults = {},
                _settings = {},
                _propertyChangedListeners = {},
                _settingsType = ProfileSettingsTypes.Array,
                OnPropertyChanged = Wrapper_OnPropertyChanged,
                RegisterPropertyChanged = Wrapper_RegisterPropertyChanged,
                UnregisterPropertyChanged = Wrapper_UnregisterPropertyChanged,
                RegisterAllPropertyChanged = Wrapper_RegisterPropertyChanged,
                UnregisterAllPropertyChanged = Wrapper_UnregisterPropertyChanged,
                GetRawEntries = Wrapper_GetRawEntries,
                Add = ArrayWrapper_Add,
                Remove = ArrayWrapper_Remove,
                Length = ArrayWrapper_Metatable__len,
            }, {
                __index = Wrapper_Metatable__index,
                __newindex = ArrayWrapper_Metatable__newindex,
                --this sadly doesn't work since wow is using lua 5.1 and the feature requires lua 5.2+
                --please use Length() instead
                __len = ArrayWrapper_Metatable__len,
            }
        );
    end
end

--copied from http://lua-users.org/wiki/CopyTable
local function deepcopy(orig)
    local orig_type = type(orig);
    local copy;
    if orig_type == 'table' then
        copy = {};
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value);
        end
        --disable setmetatable since we don't need it
        --setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig;
    end
    return copy;
end

CreateWrapper = function(setting, defaults)
    if (type(setting) == 'table') then
        local wrapper;
        local stype = setting._settingsType;
        if (stype == nil or stype == ProfileSettingsTypes.Properties) then
            wrapper = NewWrapper(defaults);
            for key, value in pairs(setting) do
                if (string.find(key, "_.*") == nil) then    --skip all members with '_' at the beginning
                    wrapper._settings[key] = CreateWrapper(value, defaults[key]);
                end
            end
        elseif (stype == ProfileSettingsTypes.Array) then
            wrapper = NewArrayWrapper();
            for i=1, #setting do
                wrapper._settings[i] = deepcopy(setting[i]);
            end
        else
            error("ProfileSettingsType '" .. stype .. "' is not implemented in CreateWrapper!");
        end
        return wrapper;
    else
        return setting;
    end
end

local function UpdateProfileVersion(svars)
    if (svars.Version == nil) then
        error(_p.CreateError("Your profile is too old and cannot be upgraded, sorry :(", nil, true));
    end
    if (svars.Version > _currentProfileVersion) then
        error(_p.CreateError("Cannot load profile because your addon version is too old. Please update the addon.", nil, true));
    end
    while (svars.Version < _currentProfileVersion) do
        if (svars.Version == 0) then
            --nothing yet
        else
            if (svars.Version ~= _currentProfileVersion) then
                error(_p.CreateError("No upgrade path from profile version " .. tostring(svars.Version) .. " to current version " .. tostring(_currentProfileVersion) .. " could be found.", nil, true));
            end
        end
    end
end

do
    local function Profile_GetSVars(self)
        if (type(self) == 'table') then
            local unwrapped;
            local stype = self._settingsType;
            if (stype == nil or stype == ProfileSettingsTypes.Properties) then
                unwrapped = {};
                for key, value in pairs(self._settings) do
                    unwrapped[key] = Profile_GetSVars(value);
                end
            elseif (stype == ProfileSettingsTypes.Array) then
                unwrapped = deepcopy(self._settings);
            else
                error("ProfileSettingsType '" .. stype .. "' is not implemented in Profile_GetSVars!");
            end
            unwrapped._settingsType = stype;
            unwrapped.Version = self.Version;
            return unwrapped;
        else
            return self;
        end
    end
    function Profile.GetSVars(self)
        local svars = Profile_GetSVars(self);
        svars.Version = self.Version;
        return svars;
    end
end

function Profile.LoadDefault()
    return Profile.Load(_p.DefaultProfileSettings);
end

function Profile.Load(svars)
    UpdateProfileVersion(svars);
    local profile = CreateWrapper(svars, _p.DefaultProfileSettings);
    profile.Version = svars.Version;
    return profile;
end
