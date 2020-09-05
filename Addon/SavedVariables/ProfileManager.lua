local ADDON_NAME, _p = ...;
local Profile = _p.Profile;
local Constants = _p.Constants;

_p.ProfileManager = {};
local ProfileManager  = _p.ProfileManager;

local _profileChangedListeners = {};
local _characterProfileMapping;
local _defaultProfileName;
local _currentProfile;
local _profiles;

local function OnProfileChanged(newProfile)
    for listener, _ in pairs(_profileChangedListeners) do
        listener(newProfile);
    end
end

function ProfileManager.AddonLoaded()
    if (MacFramesSavedVariables == nil) then
        _p.Log("first time load!");
        _characterProfileMapping = {};
        _profiles = {};
    else
        ProfileManager.LoadSVars(MacFramesSavedVariables);
    end
    local characterKey = UnitName("player") .. "-" .. GetRealmName();
    profileName = _characterProfileMapping[characterKey];
    print("profile", profileName);
    _currentProfile = _profiles[profileName];
    print("_currentProfile", _currentProfile);
    if (_currentProfile == nil) then
        profileName, _currentProfile = ProfileManager.GetDefaultProfile();
        _characterProfileMapping[characterKey] = profileName;
    end
    MacFramesSavedVariables = ProfileManager.BuildSavedVariables();
    OnProfileChanged(_currentProfile);
end

function ProfileManager.GetCurrent()
    return _currentProfile;
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

function ProfileManager.ResetAddonSettings()
    _characterProfileMapping = nil;
    _defaultProfileName = nil;
    _currentProfile = nil;
    _profiles = nil;
    MacFramesSavedVariables = nil;
    ProfileManager.AddonLoaded();
end

function ProfileManager.LoadSVars(svars)
    _defaultProfileName = svars.DefaultProfileName;
    if (svars.CharacterProfileMapping) then
        _characterProfileMapping = svars.CharacterProfileMapping;
    else
        _p.UserChatMessage("Error loading profiles")
    end
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
    local newActiveProfile = _profiles[name];
    if (newActiveProfile == nil) then error("Profile with name '" .. name .. "' not found!"); end

    _currentProfile = newActiveProfile;
    OnProfileChanged(newActiveProfile);
end

function ProfileManager.RegisterProfileChangedListener(Callback)
    _profileChangedListeners[Callback] = true;
end

function ProfileManager.UnregisterProfileChangedListener(Callback)
    _profileChangedListeners[Callback] = nil;
end