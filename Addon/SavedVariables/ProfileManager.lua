local ADDON_NAME, _p = ...;
local L = _p.L;
local Profile = _p.Profile;
local Constants = _p.Constants;
local PlayerInfo = _p.PlayerInfo;

_p.ProfileManager = {};
local ProfileManager  = _p.ProfileManager;

ProfileManager.AddonDefaults = L["Addon Defaults"];

local _isErrorState = false;

local _profileChangedListeners = {};
local _characterProfileMapping;
local _defaultProfileName;
local _currentProfile, _currentProfileName;
local _profiles;

local function OnProfileChanged(newProfile)
    for listener, _ in pairs(_profileChangedListeners) do
        listener(newProfile);
    end
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
            for _, spec in ipairs(PlayerInfo.ClassSpecializations) do
                characterProfileNames[spec.SpecId] = defaultProfileName;
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

function ProfileManager.AddonLoaded()
    if (MacFramesSavedVariables == nil) then
        _p.Log("first time load!");
        _characterProfileMapping = {};
        _profiles = {};
    else
        ProfileManager.LoadSVars(MacFramesSavedVariables);
    end
    _currentProfileName, _currentProfile = GetProfileForCurrentCharacter();
    MacFramesSavedVariables = ProfileManager.BuildSavedVariables();
    OnProfileChanged(_currentProfile, nil);
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
    if (InCombarLockdown()) then
        _p.UserChatMessage(L["Cannot reset settings while in combat!"]);
    end
    MacFramesSavedVariables = nil;
    C_UI.Reload();
end

function ProfileManager.LoadSVars(svars)
    _defaultProfileName = svars.DefaultProfileName;
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
        local oldProfile = _currentProfile;
        _currentProfile = newActiveProfile;
        OnProfileChanged(newActiveProfile, oldProfile);
    end
end

function ProfileManager.RegisterProfileChangedListener(Callback)
    _profileChangedListeners[Callback] = true;
end

function ProfileManager.UnregisterProfileChangedListener(Callback)
    _profileChangedListeners[Callback] = nil;
end

function ProfileManager.TriggerErrorState()
    _isErrorState = true;
end

function ProfileManager.IsNewProfileNameValid(name)
    if (name == nil) then
        return false, L["No name was given."];
    elseif (type(name) ~= "string") then
        error("This function requires a string!");
    elseif (name == ProfileManager.AddonDefaults) then
        return false, L["This name is reserved!"];
    elseif (_profiles[name] ~= nil) then
        return false, L["This name is already in use!"];
    elseif (#name == 0) then
        return false, L["The name cannot be empty!"];
    else
        return true;
    end
end

function ProfileManager.CreateProfileCopy(oldProfileName, newProfileName)
    local isNewNameValid, newNameError = ProfileManager.IsNewProfileNameValid(newProfileName);
    if (not isNewNameValid) then
        _p.UserChatMessage(newNameError);
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
end