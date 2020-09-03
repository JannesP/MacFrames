local ADDON_NAME, _p = ...;
_p.Log(ADDON_NAME .. " version " .. _p.versionNumber .. " loaded.");
local UnitFrame = _p.UnitFrame;
local PlayerInfo = _p.PlayerInfo;

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

function Addon.Loaded()
    _partyFrame = PartyFrame.create();
    _raidFrame = RaidFrame.create();
end

function Addon.EnteringCombat()
    Addon.ToggleTestMode(Addon.TestMode.Disabled);
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
    Addon.UpdatePlayerInfo();
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

_eventFrame:SetScript("OnEvent", function(self, event, ...)
    _events[event](self, ...); -- call one of the functions above
end);
for k, v in pairs(_events) do
    _eventFrame:RegisterEvent(k); -- Register all events for which handlers have been defined
end