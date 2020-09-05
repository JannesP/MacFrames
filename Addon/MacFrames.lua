local ADDON_NAME, _p = ...;
_p.Log(ADDON_NAME .. " version " .. _p.versionNumber .. " loaded.");
local UnitFrame = _p.UnitFrame;
local PlayerInfo = _p.PlayerInfo;
local ProfileManager = _p.ProfileManager;

local PartyFrame = _p.PartyFrame;
local _partyFrame;
local RaidFrame = _p.RaidFrame;
local _raidFrame;

local Addon = {};
_p.Addon = Addon;

Addon.TestMode = {
    Disabled = "disabled",
    Party = "party",
    Raid = "raid",
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
        Addon.framesMovable = newValue;
        PartyFrame.SetMovable(newValue);
        RaidFrame.SetMovable(newValue);
    end
end

function Addon.Loaded()
    _p.Log({ UnitName("player"), GetRealmName() });
    local success, result = pcall(ProfileManager.AddonLoaded);
    if (not success) then
        _p.UserChatMessage("Error loading profiles. Make sure the SavedVariables are correct and restart your game. To clear the settings type '/macframes reset'.");
        error(result);
    else
        _partyFrame = PartyFrame.create();
        _raidFrame = RaidFrame.create();
    end
end

function Addon.EnteringCombat()
    Addon.ToggleTestMode(Addon.TestMode.Disabled);
    Addon.ToggleAnchors(false);
    ConfigurationWindow.Close();
end

function Addon.UpdatePlayerInfo()
    local _, englishClass, _ = UnitClass("player");
    local specIndex = GetSpecialization();
    local specId, name = GetSpecializationInfo(specIndex);
    local changedInfo = false;
    if (PlayerInfo.class ~= englishClass) then
        PlayerInfo.class = englishClass;
        changedInfo = true;
    end
    if (PlayerInfo.specId ~= specId) then
        PlayerInfo.specId = specId;
        changedInfo = true;
    end

    _p.Log("Logged on with class: " .. englishClass .. " (" .. name .. ")");
    if (changedInfo) then
        UnitFrame.PlayerInfoChanged();
    end
end

function Addon.ToggleTestMode(type)
    if (InCombatLockdown()) then
        _p.UserChatMessage("Cannot change test mode in combat.");
        return;
    end
    if (Addon.testMode == type) then
        newValue = Addon.TestMode.Disabled;
    else
        newValue = type;
    end
    if Addon.testMode ~= newValue then
        Addon.testMode = newValue;
        _p.Log("Setting test mode to: " .. Addon.testMode);
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


-- ########### EVENT HANDLING ############
local _eventFrame, _events = CreateFrame("Frame"), {};
function _events:ADDON_LOADED(addonName)
    if (addonName == ADDON_NAME) then
        Addon.Loaded();
    end
end
function _events:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
    if (isInitialLogin or isReloadingUi) then
        Addon.UpdatePlayerInfo();
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

_eventFrame:SetScript("OnEvent", function(self, event, ...)
    _events[event](self, ...); -- call one of the functions above
end);
for k, v in pairs(_events) do
    _eventFrame:RegisterEvent(k); -- Register all events for which handlers have been defined
end