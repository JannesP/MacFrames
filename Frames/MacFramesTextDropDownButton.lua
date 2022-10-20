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
local L = _p.L;

MacFramesTextDropDownButtonMixin = CreateFromMixins(SelectionPopoutButtonMixin);

function MacFramesTextDropDownButtonMixin:SetupFromMacFramesTextDropDownCollection(collection, currentValue)
    self.mfCollection = collection;
    collection.dropDown = self;
    local entries = collection:GetEntries();
    local selectedIndex = 1;
    for i, entry in ipairs(entries) do
        entry.dropDown = self;
        if (entry.value == currentValue) then
            selectedIndex = i;
        end
    end
    self:SetupSelections(entries, selectedIndex);
end

--####### MacFramesTextSelectionPopoutEntryDetailsMixin #######--
MacFramesTextSelectionPopoutEntryDetailsMixin = {};
function MacFramesTextSelectionPopoutEntryDetailsMixin:GetTooltipText()
    return self.selectionData.tooltip;
end
function MacFramesTextSelectionPopoutEntryDetailsMixin:AdjustWidth(multipleColumns, width)
    self:SetWidth(width);
end
function MacFramesTextSelectionPopoutEntryDetailsMixin:SetupDetails(selectionData, index, isSelected, hasIneligibleChoice, hasLockedChoice)
    if (selectionData == nil) then
        return;
    end
    self.selectionData = selectionData;
    self.Text:SetText(selectionData.displayText);
    if (isSelected or not self.selectable) then
        self.Text:SetTextColor(NORMAL_FONT_COLOR:GetRGB());
    else
        self.Text:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB());
    end
    self.Text:Show();
end

--####### MacFramesTextSelectionPopoutEntryMixin #######--
MacFramesTextSelectionPopoutEntryMixin = CreateFromMixins(SelectionPopoutEntryMixin);
function MacFramesTextSelectionPopoutEntryMixin:GetTooltipText()
	return self.SelectionDetails:GetTooltipText();
end

function MacFramesTextSelectionPopoutEntryMixin:OnEnter()
    SelectionPopoutEntryMixin.OnEnter(self);
    self.HighlightBGTex:SetAlpha(0.15);
end

function MacFramesTextSelectionPopoutEntryMixin:OnLeave()
    SelectionPopoutEntryMixin.OnLeave(self);
    self.HighlightBGTex:SetAlpha(0);
end

function MacFramesTextSelectionPopoutEntryMixin:OnClick()
    SelectionPopoutEntryMixin.OnClick(self);
end

--####### MacFramesTextDropDownCollectionMixin #######--
MacFramesTextDropDownCollectionMixin = {}

function MacFramesTextDropDownCollectionMixin:Add(value, displayText, tooltip)
    if (self.entries == nil) then
        self.entries = {};
    end
    tinsert(self.entries, { 
        value = value, 
        displayText = displayText, 
        tooltip = tooltip,
        collection = self,
    });
end

function MacFramesTextDropDownCollectionMixin:GetByIndex(index)
    if (self.entries == nil) then
        return nil;
    end
    return self.entries[index];
end

function MacFramesTextDropDownCollectionMixin:GetByValue(value)
    if (self.entries == nil) then
        return nil;
    end
    for _, data in ipairs(self.entries) do
        if (data.value == value) then
            return data;
        end
    end
    return nil;
end

function MacFramesTextDropDownCollectionMixin:GetEntries()
    if (self.entries == nil) then
        self.entries = {};
    end
    return self.entries;
end
