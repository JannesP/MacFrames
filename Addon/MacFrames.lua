local ADDON_NAME, _p = ...;
_p.Log(ADDON_NAME .. " version " .. _p.versionNumber .. " loaded.");
local UnitFrame = _p.UnitFrame;
local PlayerInfo = _p.PlayerInfo;
local ProfileManager = _p.ProfileManager;
local PartyFrame = _p.PartyFrame;
local RaidFrame = _p.RaidFrame;

--these can only be loaded after the addon is loaded
local SettingsWindow;

local _partyFrame;
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
    local _, englishClass, _ = UnitClass("player");
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
    if (PlayerInfo.class ~= englishClass) then
        PlayerInfo.class = englishClass;
        changedInfo = true;
    end
    if (PlayerInfo.specId ~= currentSpec.SpecId) then
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
    if (Addon.testMode == type) then
        newValue = Addon.TestMode.Disabled;
    else
        newValue = type;
    end
    if Addon.testMode ~= newValue then
        Addon.ToggleAnchors(false);
        Addon.testMode = newValue;
        _p.Log("Setting test mode to: " .. Addon.testMode);
        if (Addon.testMode == Addon.TestMode.Disabled) then
            RaidFrame.SetTestMode(false);
            PartyFrame.SetTestMode(false);
        elseif (Addon.testMode == Addon.TestMode.Party) then
            RaidFrame.SetDisabled(true);
            PartyFrame.SetTestMode(true);
        elseif (Addon.testMode == Addon.TestMode.Raid) then
            Addon.ToggleAnchors(false);
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
    Addon.UpdatePlayerInfo();
    if (isInitialLogin or isReloadingUi) then
        _p.Log({ UnitName("player"), GetRealmName(), { UnitClassBase("player") }, GetSpecialization() });
        local success, result = pcall(ProfileManager.AddonLoaded);
        if (not success) then
            ProfileManager.TriggerErrorState();
            PopupDisplays.ShowGenericMessage(
                [["Error loading profiles. Make sure the SavedVariables are correct and restart your game.
                As long as this message pops up no profile changes will be saved between reloads!
                To clear the settings type '/macframes reset'.
                Alternatively you can report this error on github, please attach your MacFrames.lua as a pastebin."]], true);
        else
            _partyFrame = PartyFrame.create();
            _raidFrame = RaidFrame.create();
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