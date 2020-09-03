local ADDON_NAME, _p = ...;
local Addon = _p.Addon;

SLASH_MACFRAMES1, SLASH_MACFRAMES2 = "/macframes", "/mf";
local AvailableOptions = {
    Config = { key = "config", description = "Shows the config ui." },

    TestOff = { key = "test", description = "Turns off test mode." },
    TestOff2 = { key = "t", description = "Turns off test mode." },

    TestParty = { key = "test party", description = "Puts the partyframes into test mode." },
    TestParty2 = { key = "tp", description = "Puts the partyframes into test mode." },

    TestRaid = { key = "test raid", description = "Puts the raidframes into test mode." },
    TestRaid2 = { key = "tr", description = "Puts the raidframes into test mode." },
};
SlashCmdList["MACFRAMES"] = function(msg, chatEditBox)
    msg = string.lower(msg);
    if (msg == AvailableOptions.Config.key) then
        _p.ConfigurationWindow.Toggle();
    elseif (msg == AvailableOptions.TestOff.key or msg == AvailableOptions.TestOff2.key) then
        Addon.ToggleTestMode(Addon.TestMode.Disabled);
    elseif (msg == AvailableOptions.TestOff.key or msg == AvailableOptions.TestParty2.key) then
        Addon.ToggleTestMode(Addon.TestMode.Party);
    elseif (msg == AvailableOptions.TestRaid.key or msg == AvailableOptions.TestRaid2.key) then
        Addon.ToggleTestMode(Addon.TestMode.Raid);
    else
        local message = "Available commands for /macframes (/mf):";
        for _, command in pairs(AvailableOptions) do
            message = message .. "\n" .. command.key .. " -- " .. command.description;
        end
        _p.UserChatMessage(message);
    end
end