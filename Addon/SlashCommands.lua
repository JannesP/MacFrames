local ADDON_NAME, _p = ...;
local Addon = _p.Addon;

SLASH_MACFRAMES1, SLASH_MACFRAMES2 = "/macframes", "/mf";
local AvailableOptions = {
    Config = { key = "config", alt = "c", description = "Shows the config ui." },
    Anchors = { key = "anchors", alt = "a", description = "Allows you to resize/position the frames." },
    TestOff = { key = "test", alt = "t", description = "Turns off test mode." },
    TestParty = { key = "test party", alt = "tp", description = "Puts the partyframes into test mode." },
    TestRaid = { key = "test raid", alt = "tr", description = "Puts the raidframes into test mode." },
};
do
    local function Matches(msg, option)
        return msg == option.key or msg == option.alt;
    end
    SlashCmdList["MACFRAMES"] = function(msg, chatEditBox)
        msg = string.lower(msg);
        if (Matches(msg, AvailableOptions.Config)) then
            _p.ConfigurationWindow.Toggle();
        elseif (Matches(msg, AvailableOptions.TestOff)) then
            Addon.ToggleTestMode(Addon.TestMode.Disabled);
        elseif (Matches(msg, AvailableOptions.TestOff)) then
            Addon.ToggleTestMode(Addon.TestMode.Party);
        elseif (Matches(msg, AvailableOptions.TestRaid)) then
            Addon.ToggleTestMode(Addon.TestMode.Raid);
        elseif (Matches(msg, AvailableOptions.Anchors)) then
            Addon.ToggleAnchors();
        else
            local message = "Available commands for /macframes (/mf):";
            for _, command in pairs(AvailableOptions) do
                message = message .. "\n" .. command.key .. " (" .. command.alt .. ") -- " .. command.description;
            end
            _p.UserChatMessage(message);
        end
    end
end