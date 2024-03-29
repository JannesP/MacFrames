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
local Addon = _p.Addon;
local ProfileManager = _p.ProfileManager;
local PopupDisplays = _p.PopupDisplays;

SLASH_MACFRAMES1, SLASH_MACFRAMES2 = "/macframes", "/mf";
local AvailableOptions = {
    Config = { key = "config", alt = "c", description = "Shows the config ui." },
    Anchors = { key = "anchors", alt = "a", description = "Allows you to resize/position the frames." },
    TestOff = { key = "test", alt = "t", description = "Turns off test mode." },
    TestParty = { key = "test party", alt = "tp", description = "Puts the partyframes into test mode." },
    TestRaid = { key = "test raid", alt = "tr", description = "Puts the raidframes into test mode." },
    ResetAddonSettings = { key = "reset", alt = "reset", description = "Resets all addon settings and deletes all profiles." },
};
do
    local function Matches(msg, option)
        return msg == option.key or msg == option.alt;
    end
    SlashCmdList["MACFRAMES"] = function(msg, chatEditBox)
        msg = string.lower(msg);
        if (Matches(msg, AvailableOptions.Config)) then
            _p.SettingsWindow.Toggle();
        elseif (Matches(msg, AvailableOptions.TestOff)) then
            Addon.ToggleTestMode(Addon.TestMode.Disabled);
        elseif (Matches(msg, AvailableOptions.TestParty)) then
            Addon.ToggleTestMode(Addon.TestMode.Party);
        elseif (Matches(msg, AvailableOptions.TestRaid)) then
            Addon.ToggleTestMode(Addon.TestMode.Raid);
        elseif (Matches(msg, AvailableOptions.Anchors)) then
            Addon.ToggleAnchors();
        elseif (Matches(msg, AvailableOptions.ResetAddonSettings)) then
            PopupDisplays.ShowResetSettingsPrompt();
        else
            local message = "Available commands for /macframes (/mf):";
            for _, command in pairs(AvailableOptions) do
                message = message .. "\n" .. command.key .. " (" .. command.alt .. ") -- " .. command.description;
            end
            _p.UserChatMessage(message);
        end
    end
end