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

_p.FilteredEditBox = {};
local FilteredEditBox = _p.FilteredEditBox;

local function SetFilter(self, func)
    self.filterFunc = func;
end

local function SetOnFilteredValueSet(self, func)
    self.filteredListener = func;
end

---@diagnostic disable-next-line: unused-function, unused-local
local function SetValidateOnTextChange(self, flag)
    self.validateOnTextChange = flag;
end

local function ValidateText(self)
    local text = gsub(self:GetText(), "|c0ff00000(.-)|r", "%1");
    if (self.validateOnTextChange) then
        if (self.filterFunc(self) == false) then
            self:SetText("|c0ff00000" .. text .. "|r");
        end
    else
        self:SetText(text);
    end
end

local function OnEditFocusLost(self)
    if (self.filterFunc(self)) then
        self.filteredListener(self);
    else
        self:SetText("");
    end
end

function FilteredEditBox.Create(parent)
    local editBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate");
    editBox.SetFilter = SetFilter;
    editBox.SetOnFilteredValueSet = SetOnFilteredValueSet;

    editBox:SetScript("OnEnterPressed", EditBox_ClearFocus);
    editBox:SetScript("OnTabPressed", EditBox_ClearFocus);
    editBox:SetScript("OnEscapePressed", EditBox_ClearFocus);
    editBox:SetScript("OnEditFocusLost", OnEditFocusLost);
    editBox:SetScript("OnTextChanged", ValidateText);
    return editBox;
end