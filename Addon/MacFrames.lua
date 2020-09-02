local ADDON_NAME, _p = ...;
_p.Log(ADDON_NAME .. " version " .. _p.versionNumber .. " loaded.");
local UnitFrame = _p.UnitFrame;
local PlayerInfo = _p.PlayerInfo;

local PartyFrame = _p.PartyFrame;
local _partyFrame;
local RaidFrame = _p.RaidFrame;
local _raidFrame;

local _addon = {};
function _addon.Loaded()
    _partyFrame = PartyFrame.create();
    _raidFrame = RaidFrame.create();
end

function _addon.UpdatePlayerInfo()
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

local _eventFrame, _events = CreateFrame("Frame"), {};
function _events:ADDON_LOADED(addonName)
    if (addonName == ADDON_NAME) then
        _addon.Loaded();
    end
end
function _events:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
    _addon.UpdatePlayerInfo();
end
function _events:PLAYER_REGEN_DISABLED()
    --_addon.EnteringCombat();
end
function _events:PLAYER_REGEN_ENABLED()
    --_addon.LeftCombat();
end
function _events:PLAYER_SPECIALIZATION_CHANGED(unit)
    if unit == "player" then
        _addon.UpdatePlayerInfo();
    end
end

_eventFrame:SetScript("OnEvent", function(self, event, ...)
    _events[event](self, ...); -- call one of the functions above
end);
for k, v in pairs(_events) do
    _eventFrame:RegisterEvent(k); -- Register all events for which handlers have been defined
end