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

_p.CastBindings = { --https://wow.gamepedia.com/SecureActionButtonTemplate
    ["DEFAULT"] = {
        [1] = {
            alt = false,
            ctrl = false,
            shift = false,
            type = "target", 
            button = "1",
            helpHarm = "help",
        },
        [2] = {
            alt = false,
            ctrl = false,
            shift = false,
            type = "togglemenu",
            button = "2",
            helpHarm = "help",
        },
        [3] = { 
            alt = true,
            ctrl = false,
            shift = false,
            type = "target", 
            button = "1",
            helpHarm = "help",
        },
        [4] = { 
            alt = true,
            ctrl = false,
            shift = false,
            type = "togglemenu",
            button = "2",
            helpHarm = "help",
        },
    },
    ["PRIEST"] = {  --PRIEST
        [256] = {   --discipline
            [1] = { 
                alt = false,
                ctrl = false,
                shift = false,
                type = "spell", 
                button = "1",
                helpHarm = "help",
                value = "Power Word: Shield",
            },
            [2] = { 
                alt = false,
                ctrl = false,
                shift = true,
                type = "spell", 
                button = "1",
                helpHarm = "help",
                value = "Shadow Mend",
            },
            [3] = { 
                alt = false,
                ctrl = false,
                shift = false,
                type = "spell", 
                button = "2",
                helpHarm = "help",
                value = "Power Word: Radiance",
            },
            [4] = { 
                alt = false,
                ctrl = false,
                shift = true,
                type = "spell", 
                button = "2",
                helpHarm = "help",
                value = "Penance",
            },
            [5] = { 
                alt = true,
                ctrl = false,
                shift = false,
                type = "target", 
                button = "1",
                helpHarm = "help",
            },
            [6] = { 
                alt = true,
                ctrl = false,
                shift = false,
                type = "togglemenu",
                button = "2",
                helpHarm = "help",
            },
            [7] = { 
                alt = false,
                ctrl = false,
                shift = false,
                type = "spell",
                button = "3",
                helpHarm = "help",
                value = "Purify",
            },
            [8] = { 
                alt = false,
                ctrl = true,
                shift = false,
                type = "spell",
                button = "1",
                helpHarm = "help",
                value = "Pain Suppression",
            },
            [9] = { 
                alt = false,
                ctrl = true,
                shift = false,
                type = "spell",
                button = "2",
                helpHarm = "help",
                value = "Power Infusion",
            },
        },
        [258] = {   --shadow
            [1] = { 
                alt = false,
                ctrl = false,
                shift = false,
                type = "spell", 
                button = "1",
                helpHarm = "help",
                value = "Power Word: Shield",
            },
            [2] = { 
                alt = false,
                ctrl = false,
                shift = true,
                type = "spell", 
                button = "1",
                helpHarm = "help",
                value = "Shadow Mend",
            },
            [3] = { 
                alt = true,
                ctrl = false,
                shift = false,
                type = "target", 
                button = "1",
                helpHarm = "help",
            },
            [4] = { 
                alt = true,
                ctrl = false,
                shift = false,
                type = "togglemenu",
                button = "2",
                helpHarm = "help",
            },
            [5] = { 
                alt = false,
                ctrl = false,
                shift = false,
                type = "spell",
                button = "3",
                helpHarm = "help",
                value = "Purify Disease",
            },
            [6] = { 
                alt = false,
                ctrl = true,
                shift = false,
                type = "spell",
                button = "2",
                helpHarm = "help",
                value = "Power Infusion",
            },
            [7] = { 
                alt = false,
                ctrl = false,
                shift = false,
                type = "spell",
                button = "2",
                helpHarm = "help",
                value = "Power Infusion",
            },
            [8] = { 
                alt = false,
                ctrl = true,
                shift = false,
                type = "spell",
                button = "3",
                helpHarm = "help",
                value = "Leap of Faith",
            },
        }
    },
    ["SHAMAN"] = {
        [262] = {   --ele
            [1] = { 
                alt = true,
                ctrl = false,
                shift = false,
                type = "target", 
                button = "1",
                helpHarm = "help",
            },
            [2] = { 
                alt = true,
                ctrl = false,
                shift = false,
                type = "togglemenu",
                button = "2",
                helpHarm = "help",
            },
            [3] = { 
                alt = false,
                ctrl = true,
                shift = false,
                type = "spell", 
                button = "2",
                helpHarm = "help",
                value = "Earth Shield",
            },
            [4] = { 
                alt = false,
                ctrl = false,
                shift = true,
                type = "spell", 
                button = "1",
                helpHarm = "help",
                value = "Healing Surge",
            },
            [5] = { 
                alt = false,
                ctrl = false,
                shift = false,
                type = "spell", 
                button = "1",
                helpHarm = "help",
                value = "Healing Surge",
            },
            [6] = { 
                alt = false,
                ctrl = false,
                shift = false,
                type = "spell", 
                button = "3",
                helpHarm = "help",
                value = "Cleanse Spirit",
            },
        },
        [263] = {   --enh
            [1] = { 
                alt = true,
                ctrl = false,
                shift = false,
                type = "target", 
                button = "1",
                helpHarm = "help",
            },
            [2] = { 
                alt = true,
                ctrl = false,
                shift = false,
                type = "togglemenu",
                button = "2",
                helpHarm = "help",
            },
            [3] = { 
                alt = false,
                ctrl = true,
                shift = false,
                type = "spell", 
                button = "2",
                helpHarm = "help",
                value = "Earth Shield",
            },
            [4] = { 
                alt = false,
                ctrl = false,
                shift = true,
                type = "spell", 
                button = "1",
                helpHarm = "help",
                value = "Healing Surge",
            },
            [5] = { 
                alt = false,
                ctrl = false,
                shift = false,
                type = "spell", 
                button = "1",
                helpHarm = "help",
                value = "Healing Surge",
            },
            [6] = { 
                alt = false,
                ctrl = false,
                shift = false,
                type = "spell", 
                button = "3",
                helpHarm = "help",
                value = "Cleanse Spirit",
            },
        },
        [264] = {   --resto
            [1] = { 
                alt = true,
                ctrl = false,
                shift = false,
                type = "target", 
                button = "1",
                helpHarm = "help",
            },
            [2] = { 
                alt = true,
                ctrl = false,
                shift = false,
                type = "togglemenu",
                button = "2",
                helpHarm = "help",
            },
            [3] = { 
                alt = false,
                ctrl = false,
                shift = false,
                type = "spell", 
                button = "1",
                helpHarm = "help",
                value = "Healing Wave",
            },
            [4] = { 
                alt = false,
                ctrl = false,
                shift = false,
                type = "spell", 
                button = "2",
                helpHarm = "help",
                value = "Riptide",
            },
            [5] = { 
                alt = false,
                ctrl = false,
                shift = true,
                type = "spell", 
                button = "1",
                helpHarm = "help",
                value = "Healing Surge",
            },
            [6] = { 
                alt = false,
                ctrl = false,
                shift = true,
                type = "spell", 
                button = "2",
                helpHarm = "help",
                value = "Chain Heal",
            },
            [7] = { 
                alt = false,
                ctrl = true,
                shift = false,
                type = "spell", 
                button = "1",
                helpHarm = "help",
                value = "Unleash Life",
            },
            [8] = { 
                alt = false,
                ctrl = true,
                shift = false,
                type = "spell", 
                button = "2",
                helpHarm = "help",
                value = "Earth Shield",
            },
            [9] = { 
                alt = false,
                ctrl = false,
                shift = false,
                type = "spell", 
                button = "3",
                helpHarm = "help",
                value = "Purify Spirit",
            },
        }
    }
}

function _p.CastBindings.GetBindingsForSpec()
    local class = _p.PlayerInfo.class;
    local specId = _p.PlayerInfo.specId;

    if (_p.PlayerInfo.class == nil or _p.PlayerInfo.specId == nil) then
        return _p.CastBindings["DEFAULT"];
    end

    local selection = nil;
    local classSelection = _p.CastBindings[class];
    if (classSelection ~= nil) then
        selection = classSelection[specId];
    end
    return selection or _p.CastBindings["DEFAULT"];
end