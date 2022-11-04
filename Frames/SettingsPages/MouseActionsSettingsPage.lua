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
local Settings = _p.Settings;
local PlayerInfo = _p.PlayerInfo;
local FrameUtil = _p.FrameUtil;
local FramePool = _p.FramePool;
local SettingsUtil = _p.SettingsUtil;

local SettingsUtil_ProcessMouseAction = SettingsUtil.ProcessMouseAction;
local ParseLink = _p.ParseLink;

_p.MouseActionsSettingsPage = {};
local MouseActionsSettingsPage = _p.MouseActionsSettingsPage;

local _editorPool = FramePool.Create();
local _gridLayoutDescriptor = {
    rowHeight = 26,
    columnSpacing = 2,
    rowSpacing = 3,
    childListPropertyName = "editors",
    gridFramePropertyName = "editorContainer",
    [1] = {
        heading = "",
        width = 20,
        cellFramePropertyName = "cellErrorIcon",
        visible = true,
    },
    [2] = {
        heading = L["Type"],
        width = 120,
        cellFramePropertyName = "cellDropDownBindingType",
        visible = true,
    },
    [3] = {
        heading = L["Spell/Item"],
        width = "*",
        cellFramePropertyName = "editBoxContainer",
        visible = true,
    },
    [4] = {
        heading = L["Binding"],
        width = 100,
        cellFramePropertyName = "cellTextKeybind",
        visible = true,
    },
    [5] = {
        heading = L["Set Binding"],
        width = 85,
        cellFramePropertyName = "cellButtonSetKeybind",
        visible = true,
    },
    [6] = {
        heading = L[""],
        width = 20,
        cellFramePropertyName = "cellRemoveButton",
        visible = true,
    },
}
local function MouseActionEditor_Layout(self)
    local totalHeight = 0;

    _gridLayoutDescriptor[1].visible = false;
    for i=1, #self.editors do
        if (self.editors[i].errorIcon:IsShown()) then
            _gridLayoutDescriptor[1].visible = true;
            break;
        end
    end
    _gridLayoutDescriptor[5].width = self.editors[1].buttonSetKeybind:GetWidth();
    FrameUtil.GridLayoutFromObjects(self, _gridLayoutDescriptor);

    totalHeight = totalHeight + self.dropDownHeader:GetHeight();
    totalHeight = totalHeight + self.editorContainer:GetHeight();
    totalHeight = totalHeight + self.buttonAddBinding:GetHeight() + 5;

    self:SetHeight(totalHeight);
end

local MouseActionEditor_CreateMouseActionEditor, MouseActionEditor_UpdateForCurrentSpecSelection;
do
    local _dropDownCount = 0;
    local _bindingTypes = SettingsUtil.ValidMouseActionBindingTypes;
    local _bindingButtonAttributeMapping = SettingsUtil.MouseActionButtonAttributeMapping;
    local function MouseActionEditor_DropDownSelectBindingType(dropDownButton, arg1BindingTypeKey, arg2, checked)
        local editor = dropDownButton.owner;
        editor.boundTable.type = arg1BindingTypeKey;
        editor:OnDataChanged();
    end
    local function MouseActionEditor_DropDownSelectBindingTypeInit(frame, level, menuList)
        local editor = frame:GetParent();
        local info = UIDropDownMenu_CreateInfo();
        info.func = MouseActionEditor_DropDownSelectBindingType;
        for i=1, #_bindingTypes do
            local bindingType = _bindingTypes[i];
            info.text = bindingType.text;
            info.arg1 = bindingType.value;
            info.owner = editor;
            if (editor.boundTable == nil) then
                info.checked = false;
            else
                info.checked = editor.boundTable.type == bindingType.value;
            end
            UIDropDownMenu_AddButton(info);
        end
    end
    local function MouseActionEditor_CheckValidData(self)
        return SettingsUtil_ProcessMouseAction(self.boundList, self.boundIndex, true);
    end

    local _textBuffer = {};
    local function MouseActionEditor_RefreshFromBoundTable(self)
        local boundTable = self.boundTable;

        local bindingTypeText = "please select";
        for i=1, #_bindingTypes do
            local bindingType = _bindingTypes[i];
            if (bindingType.value == boundTable.type) then
                bindingTypeText = bindingType.text;
            end
        end
        UIDropDownMenu_SetText(self.dropDownBindingType, bindingTypeText);

        if (boundTable.type == "spell" or boundTable.type == "item") then
            self.editBoxContainer:Show();
            self.editBoxSpellSelect:Show();
            self.spellIconDisplay:Show();
            --this needs to be filtered if there are any types added that dont have a link or have a different name
            self.editBoxSpellSelect.allowedLinkType = boundTable.type;
        else
            self.editBoxContainer:Hide();
            self.editBoxSpellSelect:Hide();
            self.spellIconDisplay:Hide();

            self.editBoxSpellSelect.allowedLinkType = nil;
        end

        wipe(_textBuffer);
        if (boundTable.alt == true) then
            _textBuffer[#_textBuffer + 1] = L["ALT"];
        end
        if (boundTable.ctrl == true) then
            _textBuffer[#_textBuffer + 1] = L["CTRL"];
        end
        if (boundTable.shift == true) then
            _textBuffer[#_textBuffer + 1] = L["SHIFT"];
        end
        local keybindText = nil;
        for i=1, #_bindingButtonAttributeMapping do
            local mapping = _bindingButtonAttributeMapping[i];
            if (mapping.attributeName == boundTable.button) then
                keybindText = mapping.displayName;
                break;
            end
        end
        if (keybindText == nil) then
            _textBuffer[#_textBuffer + 1] = L["Not Set!"];
        else
            _textBuffer[#_textBuffer + 1] = keybindText;
        end
        local keybindTextComplete = table.concat(_textBuffer, " + ");
        FrameUtil.CreateTextTooltip(self.cellTextKeybind, keybindTextComplete, self.cellTextKeybind, nil, 0, 0, 1, 1, 1, 1);
        self.textSetKeybind:SetText(keybindTextComplete);

        if (self.boundTable.type == "spell") then
            local name, _, icon, _, _, _, spellId = GetSpellInfo(self.boundTable.spellId);
            if (spellId ~= nil) then
                self.spellIconDisplay.texture:SetTexture(icon);
                self.editBoxSpellSelect:SetText(name);
            else
                self.spellIconDisplay.texture:SetTexture(134400);
                self.editBoxSpellSelect:SetText("");
            end
            self.editBoxSpellSelect:SetCursorPosition(0);
        elseif (self.boundTable.type == "item") then
            local itemAsNumber = tonumber(self.boundTable.itemSelector);
            local itemID, _, _, _, icon = GetItemInfoInstant(SecureCmdItemParse(self.boundTable.itemSelector) or "");
            if (itemAsNumber ~= nil and itemAsNumber > 0 and itemAsNumber == math.floor(itemAsNumber) and itemAsNumber <= 23) then
                self.editBoxSpellSelect:SetText(L["Item slot #{i}"]:gsub("{i}", itemAsNumber));
                self.editBoxSpellSelect:SetCursorPosition(0);
                self.spellIconDisplay.texture:SetTexture(icon);
            else
                if (itemID ~= nil) then
                    self.editBoxSpellSelect:SetText(itemID);
                    self.spellIconDisplay.texture:SetTexture(icon);
                    local item = Item:CreateFromItemID(itemID)
                    item:ContinueOnItemLoad(function()
                        self.editBoxSpellSelect:SetText(item:GetItemName());
                        self.editBoxSpellSelect:SetCursorPosition(0);
                    end);
                else
                    self.spellIconDisplay.texture:SetTexture(134400);
                    self.editBoxSpellSelect:SetText("");
                end
                self.editBoxSpellSelect:SetCursorPosition(0);
            end 
        end

        local isValid, errorMsg = MouseActionEditor_CheckValidData(self);
        if (isValid == false) then
            --self.errorText:SetText(L["Invalid Binding: {msg}"]:gsub("{msg}", errorMsg));
            --self.errorText:SetHeight(select(2, self.errorText:GetFont()));
            --can't hide/set to 0 because anchors wouldn't work
            FrameUtil.CreateTextTooltip(self.errorIcon, errorMsg, self.errorIcon, nil, 0, 0, 1, 1, 0, 1);
            self.errorIcon:SetWidth(self.errorIcon:GetHeight());
            self.errorIcon:Show();
        else
            self.errorIcon:SetWidth(1);
            self.errorIcon:Hide();
        end
    end
    local function MouseActionEditor_OnDataChanged(self)
        if (self.onDataChangedListener ~= nil) then
            self.onDataChangedListener(self);
        end
    end
    local function MouseActionEditor_SetOnDataChangedListener(self, callback)
        self.onDataChangedListener = callback;
    end
    local function MouseActionEditor_OnRemove(self)
        if (self.onRemoveListener ~= nil) then
            self.onRemoveListener(self);
        end
    end
    local function MouseActionEditor_SetOnRemoveListener(self, callback)
        self.onRemoveListener = callback;
    end
    local function MouseActionEditor_OnRemoveClick(removeButton)
        MouseActionEditor_OnRemove(removeButton:GetParent());
    end
    local function MouseActionEditor_SetBoundTable(self, tableList, index)
        self.boundList = tableList;
        self.boundIndex = index;
        self.boundTable = tableList[index];
        MouseActionEditor_RefreshFromBoundTable(self);
    end
    local function MouseActionEditor_ButtonSetKeybind_OnMouseDown(self, buttonName)
        local editor = self:GetParent();
        local boundTable = editor.boundTable;

        boundTable.alt = IsAltKeyDown();
        boundTable.ctrl = IsControlKeyDown();
        boundTable.shift = IsShiftKeyDown();

        local mappedButton;
        for i=1, #_bindingButtonAttributeMapping do
            local mapping = _bindingButtonAttributeMapping[i];
            if (mapping.clickName == buttonName) then
                mappedButton = mapping.attributeName;
                break;
            end
        end
        boundTable.button = mappedButton;
        editor:OnDataChanged();
    end
    local activeEditBox = nil;
    hooksecurefunc("ChatEdit_InsertLink", function(link)
        if (activeEditBox ~= nil and activeEditBox:IsVisible() and activeEditBox:HasFocus()) then
            local _, _, _, linkType = ParseLink(link);
            if (activeEditBox.allowedLinkType == linkType) then
                activeEditBox:SetText(link);
                activeEditBox:SetFocus();
            else
                _p.UserChatMessage(L["This doesn't go here!"]);
            end
            --StackSplitFrame:Hide(); --hide stack split frame that is triggered by shift-click
        end
        return true;
    end);
    local function EditBoxSpellSelect_FocusGained(self)
        activeEditBox = self;
        local editor = self:GetParent();
        local enteredText = self:GetText();
        if (editor.boundTable.type == "spell") then
            if (editor.boundTable.spellId == nil) then
                self:SetText("");
            else
                self:SetText(editor.boundTable.spellId);
            end
        elseif (editor.boundTable.type == "item") then
            if (editor.boundTable.itemSelector == nil) then
                self:SetText("");
            else
                self:SetText(editor.boundTable.itemSelector);
            end
        end
        editor.spellIconDisplay.texture:SetTexture(134400);
        self:SetCursorPosition(self:GetNumLetters());
    end
    local function EditBoxSpellSelect_FocusLost(self)
        local editor = self:GetParent();
        local enteredText = self:GetText();
        if (editor.boundTable.type == "spell") then
            if (enteredText == "") then
                editor.boundTable.spellId = nil;
            else
                local name, icon, spellId;

                local asNumber = tonumber(enteredText);
                if (asNumber ~= nil) then
                    name, _, icon, _, _, _, spellId = GetSpellInfo(asNumber);
                else
                    name, _, icon, _, _, _, spellId = GetSpellInfo(enteredText);
                end 
                
                if (spellId == nil) then
                    local _, _, _, linkType, spellIdFromLink = ParseLink(enteredText);
                    if (linkType == "spell") then
                        name, _, icon, _, _, _, spellId = GetSpellInfo(spellIdFromLink);
                    end
                end
                if (spellId ~= nil) then
                    editor.boundTable.spellId = spellId;
                else
                    _p.UserChatMessage(L["Spell string was invalid. Resetting to previous value."]);
                end
            end
        elseif (editor.boundTable.type == "item") then
            if (enteredText == "") then
                editor.boundTable.itemSelector = nil;
            else
                local itemID, _, _, _, icon = GetItemInfoInstant(SecureCmdItemParse(enteredText) or "");
                if (itemID ~= nil) then
                    editor.boundTable.itemSelector = enteredText;
                else
                    _p.UserChatMessage(L["Item string was invalid. Resetting to previous value. All strings that work in macros should work here (Character Slot, Item ID and Item Name)."]);
                end
            end
        end
        editor:OnDataChanged();
        activeEditBox = nil;
    end
    local function EditBoxSpellSelect_OnMouseDown(self, button)
        if (button == "LeftButton") then
            local type, info1, info2, info3 = GetCursorInfo();
            if type == nil then
                self:SetFocus();
            elseif type == self.allowedLinkType then
                self:SetFocus();
                if (type == "item") then
                    --"item", itemID, itemLink
                    local itemLink = info2;
                    self:SetText(itemLink);
                elseif (type == "spell") then
                    --"spell", spellIndex, bookType, spellID
---@diagnostic disable-next-line: param-type-mismatch
                    local spellLink = GetSpellLink(info3);
                    self:SetText(spellLink);
                end
                self:ClearFocus();
                ClearCursor();
            else
                _p.UserChatMessage(L["This doesn't go here!"]);
            end
        end
    end
    local function EditBoxSpellSelect_OnReceiveDrag(self)
        local type, info1, info2, info3 = GetCursorInfo();
        if type == self.allowedLinkType then
            self:SetFocus();
            if (type == "item") then
                --"item", itemID, itemLink
                local itemLink = info2;
                self:SetText(itemLink);
            elseif (type == "spell") then
                --"spell", spellIndex, bookType, spellID
---@diagnostic disable-next-line: param-type-mismatch
                local spellLink = GetSpellLink(info3);
                self:SetText(spellLink);
            end
            self:ClearFocus();
        else
            _p.UserChatMessage(L["This doesn't go here!"]);
        end
        ClearCursor();
    end
    local function SpellIconDisplay_OnEnter(self)
        local parent = self:GetParent();
        if (not parent.editBoxSpellSelect:HasFocus()) then
            local boundTable = parent.boundTable;
            if (boundTable.type == "item") then
                local itemSelector = boundTable.itemSelector;
                if (itemSelector ~= nil and itemSelector ~= "") then
                    local itemId = GetItemInfoInstant(SecureCmdItemParse(boundTable.itemSelector));
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
                    GameTooltip:SetItemByID(itemId);
                    GameTooltip:Show();
                end
            elseif (boundTable.type == "spell") then
                if (boundTable.spellId ~= nil) then
                    local _, _, _, _, _, _, spellId = GetSpellInfo(boundTable.spellId);
                    if (spellId ~= nil) then
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
                        GameTooltip:SetSpellByID(spellId);
                        GameTooltip:Show();
                    end
                end
            end
        end
    end
    local function SpellIconDisplay_OnLeave(self)
        GameTooltip:Hide();
    end
    MouseActionEditor_CreateMouseActionEditor = function(parent)
        local frame = CreateFrame("Frame", nil, parent);
        frame.SetBoundTable = MouseActionEditor_SetBoundTable;
        frame.SetOnDataChangedListener = MouseActionEditor_SetOnDataChangedListener;
        frame.RefreshFromBoundTable = MouseActionEditor_RefreshFromBoundTable;
        frame.OnDataChanged = MouseActionEditor_OnDataChanged;
        frame.SetOnRemoveListener = MouseActionEditor_SetOnRemoveListener;
        FrameUtil.ColorFrame(frame, .5, .5, .5, .2)
        local totalHeight = 0;
        local totalWidth = 0;

        frame.cellErrorIcon = CreateFrame("Frame", nil, frame);
        local errorIcon = CreateFrame("Frame", nil, frame);
        frame.errorIcon = errorIcon;
        errorIcon:SetSize(20, 20);
        errorIcon:SetPoint("CENTER", frame.cellErrorIcon, "CENTER");
        errorIcon.icon = frame.errorIcon:CreateTexture();
        errorIcon.icon:SetAllPoints();
        errorIcon.icon:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew");
        errorIcon:EnableMouse();
        totalWidth = totalWidth + errorIcon:GetWidth();
        totalHeight = math.max(totalHeight, errorIcon:GetHeight());

        _dropDownCount = _dropDownCount + 1;
        frame.cellDropDownBindingType = CreateFrame("Frame", nil, frame);
        local dropDownBindingType = CreateFrame("Frame", "MacFramesDropdownMouseActionSelectBindingType" .. _dropDownCount, frame, "UIDropDownMenuTemplate");
        frame.dropDownBindingType = dropDownBindingType;
        UIDropDownMenu_SetWidth(dropDownBindingType, 100);
        UIDropDownMenu_Initialize(dropDownBindingType, MouseActionEditor_DropDownSelectBindingTypeInit);
        dropDownBindingType:SetPoint("CENTER", frame.cellDropDownBindingType, "CENTER", 0, -2);
        totalWidth = totalWidth + dropDownBindingType:GetWidth();
        totalHeight = math.max(totalHeight, dropDownBindingType:GetHeight());

        local editBoxContainer = CreateFrame("Frame", nil, frame);
        frame.editBoxContainer = editBoxContainer;
---@diagnostic disable-next-line: param-type-mismatch
        editBoxContainer:SetPoint("LEFT", dropDownBindingType, "RIGHT");

        local spellIconDisplay = CreateFrame("Frame", nil, frame);
        frame.spellIconDisplay = spellIconDisplay;
        spellIconDisplay:SetSize(20, 20);
        spellIconDisplay.texture = spellIconDisplay:CreateTexture();
        spellIconDisplay.texture:SetAllPoints();
        spellIconDisplay.texture:SetTexCoord(FrameUtil.GetStandardIconZoomTransform());
        FrameUtil.CreateSolidBorder(spellIconDisplay, 1, .5, .5, .5, 1);
        spellIconDisplay:SetPoint("LEFT", editBoxContainer, "LEFT");
        spellIconDisplay:EnableMouse(true);
        spellIconDisplay:SetScript("OnEnter", SpellIconDisplay_OnEnter);
        spellIconDisplay:SetScript("OnLeave", SpellIconDisplay_OnLeave);

        local editBoxSpellSelect = CreateFrame("EditBox", nil, frame, "InputBoxTemplate");
        frame.editBoxSpellSelect = editBoxSpellSelect;
        editBoxSpellSelect:SetAutoFocus(false);
        editBoxSpellSelect:SetWidth(130);
        editBoxSpellSelect:ClearAllPoints();
        editBoxSpellSelect:SetHeight(20);
        editBoxSpellSelect:SetPoint("LEFT", spellIconDisplay, "RIGHT", 8, 0);
        editBoxSpellSelect:SetPoint("RIGHT", editBoxContainer, "RIGHT", 0, 0);
        
        editBoxSpellSelect:SetScript("OnEnterPressed", EditBox_ClearFocus);
        editBoxSpellSelect:SetScript("OnTabPressed", EditBox_ClearFocus);
        editBoxSpellSelect:SetScript("OnEditFocusLost", EditBoxSpellSelect_FocusLost);
        editBoxSpellSelect:SetScript("OnEditFocusGained", EditBoxSpellSelect_FocusGained);
        editBoxSpellSelect:SetScript("OnMouseDown", EditBoxSpellSelect_OnMouseDown);
        editBoxSpellSelect:SetScript("OnReceiveDrag", EditBoxSpellSelect_OnReceiveDrag);
        
        editBoxContainer:SetHeight(math.max(editBoxSpellSelect:GetHeight(), spellIconDisplay:GetHeight()));
        editBoxContainer:SetWidth(spellIconDisplay:GetWidth() + editBoxSpellSelect:GetWidth() + 8);

        totalWidth = totalWidth + editBoxContainer:GetWidth();
        totalHeight = math.max(totalHeight, editBoxContainer:GetHeight());

        frame.cellTextKeybind = CreateFrame("Frame", nil, frame);
        local textSetKeybind = FrameUtil.CreateText(frame, "Ctrl+Alt+Shift+Left", nil, "GameFontNormalSmall");
        frame.textSetKeybind = textSetKeybind;
        textSetKeybind:SetAllPoints(frame.cellTextKeybind);
        totalWidth = totalWidth + textSetKeybind:GetWidth();
        totalHeight = math.max(totalHeight, textSetKeybind:GetHeight());

        frame.cellButtonSetKeybind = CreateFrame("Frame", nil, frame);
        local buttonSetKeybind = FrameUtil.CreateTextButton(frame, nil, L["Click to set"], nil);
        frame.buttonSetKeybind = buttonSetKeybind;
        buttonSetKeybind:RegisterForClicks("AnyDown");
        buttonSetKeybind:SetScript("OnMouseDown", MouseActionEditor_ButtonSetKeybind_OnMouseDown);
        buttonSetKeybind:SetPoint("CENTER", frame.cellButtonSetKeybind, "CENTER");
        totalWidth = totalWidth + buttonSetKeybind:GetWidth();
        totalHeight = math.max(totalHeight, buttonSetKeybind:GetHeight());

        frame.cellRemoveButton = CreateFrame("Frame", nil, frame);
        local removeButton = CreateFrame("Button", nil, frame);
        frame.removeButton = removeButton;
        removeButton:SetSize(25, 25);
        removeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up");
        removeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down");
        removeButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight");
        removeButton:RegisterForClicks("LeftButtonUp");
        removeButton:SetPoint("CENTER", frame.cellRemoveButton, "CENTER");
        removeButton:SetScript("OnClick", MouseActionEditor_OnRemoveClick);

        frame:SetSize(totalWidth, totalHeight);
        return frame;
    end

end
local function RecycleEditor(editor)
    editor:SetOnDataChangedListener(nil);
    editor:SetOnRemoveListener(nil);
    _editorPool:Put(editor);
end
local function MouseActionEditor_OnEditorDataChanged(editor)
    editor.boundTable._changed = true;
    local parent = editor:GetParent();
    for i=1, #parent.editors do
        --refresh all views because there are validations that depend on all elements
        parent.editors[i]:RefreshFromBoundTable();
    end
    editor.boundList[editor.boundIndex] = editor.boundTable;
    parent:Layout();
end

local function MouseActionEditor_OnEditorRemove(editor)
    editor.boundList:Remove(editor.boundIndex);
    MouseActionEditor_UpdateForCurrentSpecSelection(editor:GetParent());
end

MouseActionEditor_UpdateForCurrentSpecSelection = function(self)
    local classId, specId = self.selectedClassId, self.selectedSpecId;
    if (classId == nil or specId == nil) then error("unexpected selection!") end;

    local profile = self.category:GetProfile();
    local specEntries = profile.MouseActions[classId][specId];

    self.mouseActionList = specEntries;
    for i=1, #self.editors do  --clear current editors
        RecycleEditor(self.editors[i]);
    end
    wipe(self.editors);

    local lastFrame = nil;
    for i=1, specEntries:Length() do
        local editor = _editorPool:Take();
        if (editor == nil) then
            editor = MouseActionEditor_CreateMouseActionEditor(self);
        else
            editor:SetParent(self);
            editor:Show();
        end
        editor:SetOnDataChangedListener(MouseActionEditor_OnEditorDataChanged);
        editor:SetOnRemoveListener(MouseActionEditor_OnEditorRemove);
        editor:SetBoundTable(specEntries, i);
        
        self.editors[#self.editors + 1] = editor;
        lastFrame = editor;
    end
    MouseActionEditor_Layout(self);
end

local function SelectSpec(self, classId, specId)
    local className, classFile, classID = GetClassInfo(classId);
    local specId, specName, _, specIcon, _, _ = GetSpecializationInfoByID(specId);
    self.selectedClassId = classId;
    self.selectedSpecId = specId;
    UIDropDownMenu_SetText(self.dropDownSelectClass, specName .. " " .. className);
    UIDropDownMenu_SetIconImage(self.dropDownSelectClass.Icon, specIcon, UIDropDownMenu_CreateInfo());
    MouseActionEditor_UpdateForCurrentSpecSelection(self);
end

local DropDownSelectClassInit;
do
    local function DropDownSpecSelected(self, arg1ClassId, arg2SpecId, checked)
        SelectSpec(self.owner:GetParent(), arg1ClassId, arg2SpecId);
        CloseDropDownMenus(1);
    end
    DropDownSelectClassInit = function(frame, level, menuList)
        local level = level or 1;
        local info = UIDropDownMenu_CreateInfo();
        if (level == 1) then
            local numClasses = GetNumClasses();
            for i=1,numClasses do
                local className, classFile, classID = GetClassInfo(i);
                info.text = className;
                info.menuList = classID;
                info.hasArrow = true;
                info.arg1 = classID;
                info.owner = frame;
                info.keepShownOnClick = true;
                info.ignoreAsMenuSelection = true;
                info.notCheckable = true;
                UIDropDownMenu_AddButton(info);
            end
        elseif (level == 2) then
            local classID = menuList;
            local numSpecs = GetNumSpecializationsForClassID(classID);
            for n=1, numSpecs do
                local specID, name, _, icon = GetSpecializationInfoForClassID(classID, n);
                info.text = name;
                info.hasArrow = false;
                info.arg1 = classID;
                info.arg2 = specID;
                info.owner = frame;
                info.checked = (classID == frame:GetParent().selectedClassId) and (specID == frame:GetParent().selectedSpecId);
                info.icon = icon;
                info.func = DropDownSpecSelected;
                UIDropDownMenu_AddButton(info, level);
            end
        end
    end
end

local function AddNewBinding(self)
    self.mouseActionList:Add({});
    MouseActionEditor_UpdateForCurrentSpecSelection(self);
end

function MouseActionsSettingsPage.Create(parent, category)
    local frame = CreateFrame("Frame", nil, parent);
    frame.category = category;

    frame.dropDownHeader = CreateFrame("Frame", nil, frame);
    frame.dropDownHeader:SetPoint("TOP", frame, "TOP");
    frame.dropDownHeader.text = FrameUtil.CreateText(frame.dropDownHeader, L["Configure for:"]);
    frame.dropDownHeader.text:SetPoint("LEFT", frame.dropDownHeader, "LEFT", 0, 2);
    frame.dropDownSelectClass = CreateFrame("Frame", "MacFramesDropdownMouseActionSelectClass", frame, "UIDropDownMenuTemplate");
    frame.dropDownSelectClass:SetPoint("RIGHT", frame.dropDownHeader, "RIGHT", 16, 0);
    UIDropDownMenu_SetWidth(frame.dropDownSelectClass, 200);
    UIDropDownMenu_Initialize(frame.dropDownSelectClass, DropDownSelectClassInit);

    frame.dropDownHeader:SetHeight(math.max(frame.dropDownHeader:GetHeight(), frame.dropDownSelectClass:GetHeight()));
    frame.dropDownHeader:SetWidth(frame.dropDownHeader.text:GetWidth() + 5 + frame.dropDownSelectClass:GetWidth());

    frame.editorContainer = CreateFrame("Frame", "test123", frame);
    frame.editorContainer:SetPoint("TOP", frame.dropDownHeader, "BOTTOM");
    frame.editorContainer:SetPoint("LEFT", frame, "LEFT");
    frame.editorContainer:SetPoint("RIGHT", frame, "RIGHT");

    frame.buttonAddBinding = FrameUtil.CreateTextButton(frame, nil, L["Add Binding"], function() AddNewBinding(frame) end);
    frame.buttonAddBinding:SetPoint("TOP", frame.editorContainer, "BOTTOM", 0, -5);
    frame.buttonAddBinding:SetPoint("LEFT", frame, "LEFT");

    frame.editors = {};
    SelectSpec(frame, PlayerInfo.classId, PlayerInfo.specId);
    
    frame.RefreshFromProfile = MouseActionEditor_UpdateForCurrentSpecSelection;
    frame.Layout = MouseActionEditor_Layout;
    frame.IsChangingSettings = function () return false; end;
    return frame;
end