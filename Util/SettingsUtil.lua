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
local PlayerInfo = _p.PlayerInfo;
local ProfileManager = _p.ProfileManager;
local L = _p.L;

_p.SettingsUtil = {};
local SettingsUtil = _p.SettingsUtil;

local _emptyObject = {};
function SettingsUtil.GetSpecialClassDisplays()
    local result = _emptyObject;

    if (PlayerInfo.class ~= nil and PlayerInfo.specId ~= nil) then
        local classDisplays = ProfileManager.GetCurrent().SpecialClassDisplays[PlayerInfo.class];
    
        if (classDisplays ~= nil) then
            local specDisplay = classDisplays[PlayerInfo.specId];
            if (specDisplay ~= nil) then
                result = specDisplay:GetRawEntries();
            end
        end
    end
    
    return result;
end

--[[
    Here are some definitions for the MouseAction bindings 
    since they need to be validatable outside of the configuration ui.
]]
SettingsUtil.ValidMouseActionBindingTypes = {
    [1] = {
        value = "spell",
        text = L["Cast Spell"],
    },
    [2] = {
        value = "target",
        text = L["Target Unit"],
    },
    [3] = {
        value = "togglemenu",
        text = L["Open Menu"],
    },
    [4] = {
        value = "focus",
        text = L["Focus Unit"],
    },
    [5] = {
        value = "item",
        text = L["Use Item"],
    },
}
SettingsUtil.MouseActionButtonAttributeMapping = {
    [1] = {
        clickName = "LeftButton",
        attributeName = "1",
        displayName = L["Left"],
    },
    [2] = {
        clickName = "RightButton",
        attributeName = "2",
        displayName = L["Right"],
    },
    [3] = {
        clickName = "MiddleButton",
        attributeName = "3",
        displayName = L["Middle"],
    },
    [4] = {
        clickName = "Button4",
        attributeName = "4",
        displayName = L["Back (Mouse 4)"],
    },
    [5] = {
        clickName = "Button5",
        attributeName = "5",
        displayName = L["Forward (Mouse 5)"],
    },
}

--[[
{ 
    alt = false,
    ctrl = false,
    shift = false,
    button = "1",       --a mouse button for use with SetAttribute
    helpHarm = "help",  --unused for now but defaults to 'help' in case I want to make target frames at some point
    type = "target",    --a type for use with SetAttribute
    spellId = nil,      --spellId for language changes (used with GetSpellInfo to fill spellName)
    spellName = nil,    --translated spell name for use with SetAttribute
    itemSelector = nil, --macro item slot or anything language agnostic to use with GetItemInfo
    itemName = nil,     --translated item name/item slot for use with SetAttribute
}
]]
local _checkedBindings = setmetatable({}, { __mode = "k" });    --created with weak key references
local _bindingTypes = SettingsUtil.ValidMouseActionBindingTypes;
local _bindingButtonAttributeMapping = SettingsUtil.MouseActionButtonAttributeMapping;
local function ProcessType(actionList, indexToCheck, toCheck)
    local hasValidSelection = false;
    for i=1, #_bindingTypes do
        if (_bindingTypes[i].value == toCheck.type) then
            hasValidSelection = true;
            break;
        end
    end
    if (hasValidSelection == true) then
        return true, nil;
    else
        return false, L["Binding type is not selected."];
    end
end
local function ProcessTypeArguments(actionList, indexToCheck, toCheck)
    local isValid, errorMessage;
    if (toCheck.type == "spell") then
        local name = GetSpellInfo(toCheck.spellId);
        toCheck.spellName = name;
        if (name == nil) then
            isValid, errorMessage = false, L["The spell is not valid."];
        else
            isValid, errorMessage = true, nil;
        end
    elseif (toCheck.type == "item") then
        if (toCheck.itemSelector == nil) then
            isValid, errorMessage = false, L["The item selector is not valid."];
        else
            local itemSelectorAsNum = tonumber(toCheck.itemSelector);
            if (itemSelectorAsNum == nil) then
                if (type(toCheck.itemSelector) == "string") then
                    --other items are also always valid since GetItemInfo might query the data asynchronously and I can't be bothered to implement this at the moment
                    --https://wow.gamepedia.com/API_GetItemInfo#Details
                    isValid, errorMessage = true, nil;
                end
            else
                if (itemSelectorAsNum == math.floor(itemSelectorAsNum)) then
                    if (itemSelectorAsNum <= 23) then   --character item slots are always valid (engi enchants, trinkets etc)
                        isValid, errorMessage = true, nil;
                    else
                        isValid, errorMessage = false, L["Item IDs are not supported. Use the item name instead."];
                    end
                end
            end
        end
        
    else
        isValid, errorMessage = true, nil;
    end
    return isValid, errorMessage;
end
local function ProcessMouseBinding(actionList, indexToCheck, toCheck)
    local isValid, errorMessage;
    if (toCheck.button == nil) then
        isValid, errorMessage = false, L["Binding not set."];
    else
        --check for duplicates ... yes this has a quadratic runtime since it's run on all elements, but you won't get large collections here
        local duplicate = false;
        for i=1, actionList:Length() do
            if (i ~= indexToCheck) then
                local otherAction = actionList[i];
                if (otherAction.alt == toCheck.alt and otherAction.ctrl == toCheck.ctrl and otherAction.shift == toCheck.shift and otherAction.button == toCheck.button) then
                    --same keybind
                    duplicate = true;
                    break;
                end
            end
        end
        if (duplicate == false) then
            isValid, errorMessage = true, nil;
        else
            isValid, errorMessage = false, L["This binding already exists."];
        end
    end
    return isValid, errorMessage;
end
function SettingsUtil.ProcessMouseAction(actionList, indexToCheck, forceCheck)
    local toCheck = actionList[indexToCheck];
    local checkResult = _checkedBindings[toCheck];
    if (forceCheck == true or (toCheck._changed == true or checkResult == nil)) then
        if (checkResult == nil) then
            checkResult = {};
            _checkedBindings[toCheck] = checkResult;
        end
        toCheck._changed = false;
        checkResult.isValid = nil;
        checkResult.errorMessage = nil;
    
        checkResult.isValid, checkResult.errorMessage = ProcessType(actionList, indexToCheck, toCheck);
    
        if (checkResult.isValid) then
            checkResult.isValid, checkResult.errorMessage = ProcessTypeArguments(actionList, indexToCheck, toCheck);
        end

        if (checkResult.isValid) then
            checkResult.isValid, checkResult.errorMessage = ProcessMouseBinding(actionList, indexToCheck, toCheck);
        end
    end
    return checkResult.isValid, checkResult.errorMessage;
end
