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
local Profile = _p.Profile;
local Constants = _p.Constants;
local PlayerInfo = _p.PlayerInfo;

_p.ProfileManager = {};
local ProfileManager  = _p.ProfileManager;

local _defaultProfileMarker = Constants.DefaultProfileMarker;
ProfileManager.AddonDefaults = _defaultProfileMarker .. L["Addon Defaults"] .. _defaultProfileMarker;

local _isErrorState = false;

local _currentSettingsVersion = 4;
local _profileChangedListeners = {};
local _profileListChangedListeners = {};
local _characterProfileMapping;
local _defaultProfileName;
local _currentProfile, _currentProfileName;
local _minimapSettings;
local _profiles;

local function OnProfileChanged(newProfile)
    for listener, _ in pairs(_profileChangedListeners) do
        listener(newProfile);
    end
end

function ProfileManager.RegisterProfileChangedListener(callback)
    _profileChangedListeners[callback] = true;
end

function ProfileManager.UnregisterProfileChangedListener(callback)
    _profileChangedListeners[callback] = nil;
end

local function OnProfileListChanged()
    for listener, _ in pairs(_profileListChangedListeners) do
        listener();
    end
end

function ProfileManager.RegisterProfileListChangedListener(callback)
    _profileListChangedListeners[callback] = true;
end

function ProfileManager.UnregisterProfileListChangedListener(callback)
    _profileListChangedListeners[callback] = nil;
end

local function GetCurrentCharacterKey()
    return UnitName("player") .. "-" .. GetRealmName();
end

local function GetProfileForCurrentCharacter()
    local resultProfile, resultProfileName;
    local characterKey = GetCurrentCharacterKey();
    local characterProfileNames = _characterProfileMapping[characterKey];
    if (characterProfileNames ~= nil) then
        local specProfileName = characterProfileNames[PlayerInfo.specId];
        if (specProfileName ~= nil) then
            resultProfile = _profiles[specProfileName];
            if (resultProfile ~= nil) then
                resultProfileName = specProfileName;
            end
        end
    end

    if (resultProfile == nil or resultProfileName == nil) then
        local defaultProfileName, _ = ProfileManager.GetDefaultProfile();
        if (characterProfileNames == nil) then
            characterProfileNames = {};
            local classSpecs = PlayerInfo.ClassSpecializations;
            for i=1, #classSpecs do
                characterProfileNames[classSpecs[i].SpecId] = defaultProfileName;
            end
            _characterProfileMapping[characterKey] = characterProfileNames;
        end
        if (characterProfileNames[PlayerInfo.specId] == nil) then
            characterProfileNames[PlayerInfo.specId] = defaultProfileName;
        end

        resultProfileName = characterProfileNames[PlayerInfo.specId];
        resultProfile = _profiles[resultProfileName];
    end
    return resultProfileName, resultProfile;
end
local UpdateSavedVarsVersion;
do
    local function ForEachProfile(svars, func)
        for k, v in pairs(svars.Profiles) do
            func(k, v);
        end
    end
    --declared above do block
    UpdateSavedVarsVersion = function(svars)
        if (svars.Version == nil) then
            error(_p.CreateError("Your settings are too old and cannot be upgraded, sorry :(", nil, true));
        end
        while (svars.Version < _currentSettingsVersion) do
            if (svars.Version == 0) then
                svars.Version = 1;
            elseif (svars.Version == 1) then
                svars.MinimapSettings = { hide = false };
                svars.Version = 2;
            elseif (svars.Version == 2) then
                ForEachProfile(svars, function(name, profile)
                    profile.PartyFrame.StateDriverVisibility = "[group:raid] hide; [group:party] show; hide;";
                end);
                svars.Version = 3;
            elseif (svars.Version == 3) then
                ForEachProfile(svars, function(name, profile)
                    profile.PartyFrame.FrameStrata = "MEDIUM";
                    profile.PartyFrame.FrameLevel = 1000;
                    profile.RaidFrame.FrameStrata = "MEDIUM";
                    profile.RaidFrame.FrameLevel = 1000;
                end);
                svars.Version = 4;
            else
                if (svars.Version ~= _currentSettingsVersion) then
                    error(_p.CreateError("No upgrade path from settings version " .. tostring(svars.Version) .. " to current version " .. tostring(_currentSettingsVersion) .. " could be found.", nil, true));
                end
            end
        end
    end
end

function ProfileManager.AddonLoaded()
    if (MacFramesSavedVariables == nil) then
        _characterProfileMapping = {};
        _profiles = {};
        _minimapSettings = {};
    else
        local function ProfileLoadError(err)
            if (type(err) == "table") then
                return err;
            else
                return err .. "\n" .. debugstack();
            end
        end
        local success, err = xpcall(ProfileManager.LoadSVars, ProfileLoadError, MacFramesSavedVariables);
        if (not success) then
            return false, err;
        end
    end
    _currentProfileName, _currentProfile = GetProfileForCurrentCharacter();
    MacFramesSavedVariables = ProfileManager.BuildSavedVariables();
    OnProfileChanged(_currentProfile);
    return true;
end

function ProfileManager.PlayerInfoChanged()
    if _characterProfileMapping ~= nil then
        local newProfileName, _  = GetProfileForCurrentCharacter();
        ProfileManager.SetActiveProfile(newProfileName);
    end
end

function ProfileManager.GetCurrent()
    return _currentProfile, _currentProfileName;
end

function ProfileManager.GetDefaultProfile()
    if (_defaultProfileName == nil) then
        _defaultProfileName = Constants.DefaultProfileName;
    end
    local profile = _profiles[_defaultProfileName];
    if (profile == nil) then
        profile = Profile.LoadDefault();
        _profiles[_defaultProfileName] = profile;
    end
    return _defaultProfileName, profile;
end

function ProfileManager.GetSelectedProfileNameForSpec(specId)
    local characterKey = GetCurrentCharacterKey();
    local profilesForCharacter = _characterProfileMapping[characterKey];
    local result = profilesForCharacter[specId];
    if (result == nil) then
        result = select(1, ProfileManager.GetDefaultProfile());
        profilesForCharacter[PlayerInfo.specId] = result;
    end
    return result;
end

function ProfileManager.SelectProfileForSpec(specId, profileName)
    local characterKey = GetCurrentCharacterKey();
    local profilesForCharacter = _characterProfileMapping[characterKey];
    profilesForCharacter[specId] = profileName;
    if (specId == PlayerInfo.specId) then
        ProfileManager.SetActiveProfile(profileName);
    end
end

function ProfileManager.ResetAddonSettings()
    if (InCombatLockdown()) then
        _p.UserChatMessage(L["Cannot reset settings while in combat!"]);
    end
    MacFramesSavedVariables = nil;
    _profiles = nil;
    C_UI.Reload();
end

function ProfileManager.LoadSVars(svars)
    UpdateSavedVarsVersion(svars);
    _defaultProfileName = svars.DefaultProfileName;
    _minimapSettings = svars.MinimapSettings;
    _characterProfileMapping = svars.CharacterProfileMapping;
    _profiles = {};
    if (svars.Profiles) then
        local profiles = {};
        for name, profileData in pairs(svars.Profiles) do
            local profile = Profile.Load(profileData);
            profiles[name] = profile;
        end
        _profiles = profiles;
    end
end

function ProfileManager.SaveSVars()
    if (_isErrorState == true) then
        _p.UserChatMessage(L["Didn't save config because loading failed. To clear your settings please use '/macframes reset'"]);
        return;
    end
    MacFramesSavedVariables = ProfileManager.BuildSavedVariables();
end

function ProfileManager.BuildSavedVariables()
    local svars = {};
    svars.DefaultProfileName = _defaultProfileName;
    svars.CharacterProfileMapping = _characterProfileMapping;
    svars.Profiles = {};
    svars.Version = _currentSettingsVersion;
    svars.MinimapSettings = _minimapSettings;
    for name, profile in pairs(_profiles) do
        svars.Profiles[name] = Profile.GetSVars(profile);
    end
    return svars;
end

function ProfileManager.GetProfileList()
    return _profiles;
end

function ProfileManager.SetActiveProfile(name)
    if (name ~= _currentProfileName) then
        local newActiveProfile = _profiles[name];
        if (newActiveProfile == nil) then error("Profile with name '" .. name .. "' not found!"); end
        _currentProfileName = name;
        _currentProfile = newActiveProfile;
        OnProfileChanged(newActiveProfile);
    end
end

function ProfileManager.TriggerErrorState()
    _isErrorState = true;
end

function ProfileManager.IsNewProfileNameValid(name)
    if (name == nil or name == "") then
        return false, nil;
    elseif (type(name) ~= "string") then
        error("This function requires a string!");
    elseif (name == ProfileManager.AddonDefaults) then
        return false, L["This name is reserved!"];
    elseif (_profiles[name] ~= nil) then
        return false, L["This name is already in use!"];
    elseif (#name == 0) then
        return false, L["The name cannot be empty!"];
    elseif (string.find(name, _defaultProfileMarker) ~= nil) then
        return false, L["Profile names cannot contain '"] .. _defaultProfileMarker .. "'!";
    else
        return true;
    end
end

function ProfileManager.CreateProfileCopy(oldProfileName, newProfileName)
    local isNewNameValid, newNameError = ProfileManager.IsNewProfileNameValid(newProfileName);
    if (not isNewNameValid) then
        if (newNameError ~= nil and newNameError ~= "") then
            _p.UserChatMessage(newNameError);
        end
        return;
    end
    if (oldProfileName == ProfileManager.AddonDefaults) then
        _profiles[newProfileName] = Profile.LoadDefault();
    else
        local oldProfile = _profiles[oldProfileName];
        if (oldProfile) then
            _profiles[newProfileName] = Profile.Load(Profile.GetSVars(oldProfile));
        end
    end
    OnProfileListChanged();
end

function ProfileManager.RenameProfile(oldProfileName, newProfileName)
    if (oldProfileName == newProfileName) then
        return; --nothing changed
    end
    local isNewNameValid, newNameError = ProfileManager.IsNewProfileNameValid(newProfileName);
    if (not isNewNameValid) then
        _p.UserChatMessage(newNameError);
        return;
    end
    _profiles[newProfileName] = _profiles[oldProfileName];
    _profiles[oldProfileName] = nil;
    for characterKey, specMapping in pairs(_characterProfileMapping) do
        for spec, selectedProfile in pairs(specMapping) do
            if (selectedProfile == oldProfileName) then
                specMapping[spec] = newProfileName;
            end
        end
    end
    if (oldProfileName == _currentProfileName) then
        ProfileManager.SetActiveProfile(newProfileName);
    end
    OnProfileListChanged();
end

do
    local characterListReturnValue = {};
    function ProfileManager.GetCharacterListForProfileName(profileName)
        wipe(characterListReturnValue);
        for characterKey, specMapping in pairs(_characterProfileMapping) do
            for spec, selectedProfile in pairs(specMapping) do
                if (selectedProfile == profileName) then
                    tinsert(characterListReturnValue, characterKey);
                    break;
                end
            end
        end
        return characterListReturnValue;
    end
end

function ProfileManager.DeleteProfile(profileName)
    if (_profiles[profileName] == nil) then
        return; -- nothing changed
    end
    if (_currentProfileName == profileName) then
        _p.UserChatMessage(L["Cannot remove currently used profile."]);
        return;
    end
    local setDefaultProfile = false;
    for characterKey, specMapping in pairs(_characterProfileMapping) do
        for spec, selectedProfile in pairs(specMapping) do
            if (selectedProfile == profileName) then
                specMapping[spec] = _defaultProfileName;
                if (setDefaultProfile == false) then
                    setDefaultProfile = true;
                end
            end
        end
    end
    if (setDefaultProfile == true) then
        -- create default profile if it doesn't exist
        ProfileManager.GetDefaultProfile();
    end
    _profiles[profileName] = nil;
    OnProfileListChanged();
end

function ProfileManager.GetMinimapSettings()
    return _minimapSettings;
end