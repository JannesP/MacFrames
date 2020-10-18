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
_p.Log(ADDON_NAME .. " version " .. _p.versionNumber .. " loaded.");
local UnitFrame = _p.UnitFrame;
local PlayerInfo = _p.PlayerInfo;
local ProfileManager = _p.ProfileManager;
local PartyFrame = _p.PartyFrame;
local RaidFrame = _p.RaidFrame;
local PopupDisplays = _p.PopupDisplays;
local BlizzardFrameUtil = _p.BlizzardFrameUtil;

--these can only be loaded after the addon is loaded
local SettingsWindow;

local _partyFrame;
local _raidFrame;

local Addon = {};
_p.Addon = Addon;

Addon.TestMode = {
    Disabled = 0,
    Party = 1,
    Raid = 2,
}

Addon.testMode = Addon.TestMode.Disabled;
Addon.framesMovable = false;

function Addon.ToggleAnchors(override)
    if (InCombatLockdown()) then
        _p.UserChatMessage("Cannot change anchor mode in combat.");
        return;
    end
    local newValue;
    if (override ~= nil) then
        newValue = override;
    else
        if (Addon.framesMovable == true) then
            newValue = false;
        else
            newValue = true;
        end
    end
    if (newValue ~= Addon.framesMovable) then
        Addon.ToggleTestMode(Addon.TestMode.Disabled);
        Addon.framesMovable = newValue;
        PartyFrame.SetMovable(newValue);
        RaidFrame.SetMovable(newValue);
    end
end

function Addon.Loaded()
    SettingsWindow = _p.SettingsWindow;
end

function Addon.EnteringCombat()
    Addon.ToggleTestMode(Addon.TestMode.Disabled);
    Addon.ToggleAnchors(false);
    SettingsWindow.Close();
end

function Addon.UpdatePlayerInfo()
    local _, englishClass, classId = UnitClass("player");
    if (PlayerInfo.ClassSpecializations == nil) then
        local numSpecs = GetNumSpecializations();
        PlayerInfo.ClassSpecializations = {};
        for i=1,numSpecs do
            local id, name, description, icon, _, role, _ = GetSpecializationInfo(i);
            tinsert(PlayerInfo.ClassSpecializations, {
                SpecId = id,
                Name = name,
                Icon = icon,
                Role = role,
            });
        end
    end

    local currentSpecIndex = GetSpecialization();
    local currentSpec = PlayerInfo.ClassSpecializations[currentSpecIndex];
    local changedInfo = false;
    if (PlayerInfo.classId ~= classId) then
        PlayerInfo.class = englishClass;
        PlayerInfo.classId = classId;
        changedInfo = true;
    end
    if (currentSpec ~= nil and PlayerInfo.specId ~= currentSpec.SpecId) then
        PlayerInfo.specId = currentSpec.SpecId;
        changedInfo = true;
    end

    _p.Log("Logged on with class: " .. englishClass .. " (" .. currentSpec.Name .. ")");
    if (changedInfo) then
        ProfileManager.PlayerInfoChanged();
        UnitFrame.PlayerInfoChanged();
    end
end

function Addon.ToggleTestMode(type)
    if (InCombatLockdown()) then
        _p.UserChatMessage("Cannot change test mode in combat.");
        return;
    end
    local newValue;
    if (Addon.testMode == type) then
        newValue = Addon.TestMode.Disabled;
    else
        newValue = type;
    end
    if Addon.testMode ~= newValue then
        Addon.ToggleAnchors(false);
        Addon.testMode = newValue;
        if (Addon.testMode == Addon.TestMode.Disabled) then
            RaidFrame.SetTestMode(false);
            PartyFrame.SetTestMode(false);
        elseif (Addon.testMode == Addon.TestMode.Party) then
            RaidFrame.SetDisabled(true);
            PartyFrame.SetTestMode(true);
        elseif (Addon.testMode == Addon.TestMode.Raid) then
            RaidFrame.SetTestMode(true);
            PartyFrame.SetDisabled(true);
        end
    end
end

do
    local _disabledCUFManager = false;
    local function SetDisableBlizzardCUFManager(disable)
        if (_disabledCUFManager == true) then
            if (disable == false) then
                _p.PopupDisplays.ShowSettingsUiReloadRequired();
            end
        else
            if (disable == true) then
                if (InCombatLockdown()) then error(L["Cannot disable blizzard frames in combat."]); end;
                _disabledCUFManager = true;
                BlizzardFrameUtil.DisableCompactUnitFrameManager();
            end
        end
    end
    local function ProfileSettingChanged(key, value)
        if (key == "DisableCompactUnitFrameManager") then
            SetDisableBlizzardCUFManager(value);
        end
    end
    ProfileManager.RegisterProfileChangedListener(function(newProfile, oldProfile)
        if (oldProfile ~= nil) then
            oldProfile:UnregisterPropertyChanged(ProfileSettingChanged);
        end
        newProfile:RegisterPropertyChanged(ProfileSettingChanged);
    
        SetDisableBlizzardCUFManager(newProfile.DisableCompactUnitFrameManager);
    end);
end

-- ########### EVENT HANDLING ############
local _eventFrame, _events = CreateFrame("Frame"), {};
function _events:ADDON_LOADED(addonName)
    if (addonName == ADDON_NAME) then
        Addon.Loaded();
    end
end
do
    local function ProfileLoadError(err)
        if (type(err) == "table") then
            return err;
        else
            return err .. "\n" .. debugstack();
        end
    end
    function _events:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
        Addon.UpdatePlayerInfo();
        if (isInitialLogin or isReloadingUi) then
            _p.Log({ UnitName("player"), GetRealmName(), { UnitClassBase("player") }, GetSpecialization() });
            local success, result = xpcall(ProfileManager.AddonLoaded, ProfileLoadError);
            if (not success) then
                ProfileManager.TriggerErrorState();
                if (type(result) == "table") then
                    PopupDisplays.ShowGenericMessage(
[[Error loading profiles: 
"]]..result.UserMessage..[["
Make sure the SavedVariables are correct and restart your game.
As long as this message pops up no profile changes will be saved between reloads!
To clear the settings type '/macframes reset'.
Alternatively you can report this error on github, please attach your MacFrames.lua from the WTF folder.]], true);
                else
                    PopupDisplays.ShowGenericMessage(
[[Error loading profiles: Unknown Error, please report this.
Make sure the SavedVariables are correct and restart your game.
As long as this message pops up no profile changes will be saved between reloads!
To clear the settings type '/macframes reset'.
Alternatively you can report this error on github, please attach your MacFrames.lua from the WTF folder.]], true);
                    error(result);
                end
            else
                _partyFrame = PartyFrame.create();
                _raidFrame = RaidFrame.create();
            end
        end
    end
end
function _events:PLAYER_REGEN_DISABLED()
    Addon.EnteringCombat();
end
function _events:PLAYER_REGEN_ENABLED()
    --Addon.LeftCombat();
end
function _events:PLAYER_SPECIALIZATION_CHANGED(unit)
    if unit == "player" then
        Addon.UpdatePlayerInfo();
    end
end
function _events:PLAYER_LOGOUT()
    ProfileManager.SaveSVars();
end
EventRecord = {};
_eventFrame:SetScript("OnEvent", function(self, event, ...)
    if (event ~= "ADDON_LOADED" or select(1, ...) == ADDON_NAME) then
        tinsert(EventRecord, event);
    end
    _events[event](self, ...); -- call one of the functions above
end);
for k, v in pairs(_events) do
    _eventFrame:RegisterEvent(k); -- Register all events for which handlers have been defined
end