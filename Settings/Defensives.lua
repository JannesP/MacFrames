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

_p.Defensives = {   --priority is the number to the right (higher is a higher priority)
--@do-not-package@
    [111759] = 1,   --Levitate
    [121557] = 2,   --Angelic Feather
    --[17] = 3,       --PW: S
--@end-do-not-package@
    

    --###### Externals #######
    [33206] = 1000,     --Pain Suppression
    [47788] = 1000,     --Guardian Spirit
    [102342] = 1000,    --Ironbark
    [6940] = 1000,      --Blessing of Sacrifice
    [1022] = 1000,      --Blessing of Protection
    [204018] = 1000,    --Blessing of Spellwarding
    [1044] = 1000,      --Blessing of Freedom
    [116849] = 1000,    --Life Cocoon
    [3411] = 1000,      --Intervene

    --###### Personals #######
    [871] = 101,        --Shield Wall
    [23920] = 101,      --Spell Reflect
    [12975] = 100,      --Last Stand
    [118038] = 100,     --Die by the Sword
    [184364] = 100,     --Enraged Egeneration

    [642] = 10000,      --Divine Shield
    [31850] = 100,      --Argent Defender
    [86659] = 100,      --Guardian of the Ancient Kings
    [498] = 100,        --Divine Protection
    [184662] = 100,     --Shield of Vengeance

    [49028] = 100,      --Dancing Rune Weapon?
    [48792] = 100,      --Icebound Fortitude
    [194679] = 100,     --Runetap
    [55233] = 100,      --Vapiric Blood
    [48707] = 100,      --Anti-Magic Shell

    [115203] = 100,     --Fortifying Brew
    [115167] = 100,     --Zen Meditation
    [122470] = 100,     --Touch of Karma
    [122278] = 100,     --Dampen Harm
    [122783] = 100,     --Diffuse Magic

    [22812] = 100,      --Barkskin
    [22842] = 100,      --Frenzied Regen
    [61336] = 101,      --Survival Instincts
    [102558] = 100,     --Incarnation

    [203720] = 100,     --Demon Spikes
    [191427] = 100,     --Metamorphosis
    [198589] = 100,     --Blur
    [196555] = 10000,   --Netherwalk

    [104773] = 100,     --Unending Resolve

    [186265] = 10000,     --Aspect of the Turtle

    [31224] = 101,      --Cloak of Shadows
    [5277] = 101,       --Evasion
    [1966] = 100,       --Feint

    [108271] = 100,     --Astral Shift
    [225080] = 1,       --Ahnk (while dead)

    [19236] = 100,      --Desperate Prayer
    [47585] = 100,      --Dispersion

    [45438] = 10000,    --Ice Block
    [11426] = 100,      --Ice Barrier
    [235313] = 100,     --Blazing Barrier
    [235450] = 100,     --Prismatic Barrier

    --######### AOE ##########
    [81782] = 3,        --PW: Barrier
    [98007] = 3,        --Spirit Link
    [201633] = 2,       --Earthen Wall Totem
    [207498] = 1,       --Ancestral Protection Totem
    [255234] = 1,       --APT Procc (while dead)
    [51052] = 1,        --Anti-Magic Zone
    [196718] = 1,       --Darkness
    
    --####### Racials ########
    [65116] = 1,        --Stone Form(Racial)
};
