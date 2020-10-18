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
local L = _p.L;
local Addon = _p.Addon;
local ProfileManager = _p.ProfileManager;

_p.PopupDisplays = {};
local PopupDisplays = _p.PopupDisplays;
PopupDisplays.GenericMessage = "MACFRAMES_GENERIC_MESSAGE";
PopupDisplays.ResetSavedVariables = "MACFRAMES_RESET_SAVED_VARIABLES";
PopupDisplays.SettingsUiReloadRequired = "MACFRAMES_SETTINGS_UI_RELOAD_REQUIRED";
PopupDisplays.CopyProfileEnterName = "MACFRAMES_COPY_PROFILE_ENTER_NAME";
PopupDisplays.RenameProfileEnterName = "MACFRAMES_RENAME_PROFILE_ENTER_NAME";
PopupDisplays.DeleteProfile = "MACFRAMES_DELETE_PROFILE";

function PopupDisplays.ShowGenericMessage(message, isAlert)
    StaticPopupDialogs[PopupDisplays.GenericMessage].text = message;
    StaticPopupDialogs[PopupDisplays.GenericMessage].showAlert = isAlert;
    StaticPopup_Show(PopupDisplays.GenericMessage);
end
StaticPopupDialogs[PopupDisplays.GenericMessage] = {
    text = L["Do you really want to reset the addon settings? This will reload your UI.\nALL PROFILES WILL BE DELETED!"],
    button1 = L["Ok"],
    OnAccept = function(self)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    showAlert = false,
}

function PopupDisplays.ShowSettingsUiReloadRequired()
    StaticPopup_Show(PopupDisplays.SettingsUiReloadRequired);
end
StaticPopupDialogs[PopupDisplays.SettingsUiReloadRequired] = {
    text = L["To set the desired settings a UI reload is required. Do you want to reload the UI now?"],
    button1 = YES,
    button2 = NO,
    OnAccept = function(self)
        if (not InCombatLockdown()) then
            C_UI.Reload();
        else
            _p.UserChatMessage(L["Cannot reload UI in combat. Please consider reloading after the combat ends."]);
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    showAlert = false,
}

function PopupDisplays.ShowResetSettingsPrompt()
    StaticPopup_Show(PopupDisplays.ResetSavedVariables);
end
StaticPopupDialogs[PopupDisplays.ResetSavedVariables] = {
    text = L["Do you really want to reset the addon settings? This will reload your UI.\nALL PROFILES WILL BE DELETED!"],
    button1 = YES,
    button2 = NO,
    OnAccept = function(self)
        ProfileManager.ResetAddonSettings();
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    showAlert = true,
}

function PopupDisplays.ShowCopyProfileEnterName(profileToCopyName)
    local dialog = StaticPopup_Show(PopupDisplays.CopyProfileEnterName);
    dialog.data = profileToCopyName;
end
StaticPopupDialogs[PopupDisplays.CopyProfileEnterName] = {
    text = L["Please enter the name for the new profile:"],
    button1 = L["Ok"],
    button2 = L["Cancel"],
    OnAccept = function(self, data, data2)
        ProfileManager.CreateProfileCopy(data, self.editBox:GetText());
    end,
    OnShow = function(self)
        self.button1:Disable();
    end,
    EditBoxOnTextChanged = function(editBox)
        local isValid, reason = ProfileManager.IsNewProfileNameValid(editBox:GetText());
        if (isValid) then
            editBox:GetParent().button1:Enable();
        else
            _p.UserChatMessage(L["Profile name invalid: "] .. reason);
            editBox:GetParent().button1:Disable();
        end
    end,
    hasEditBox = true,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

function PopupDisplays.ShowRenameProfileEnterName(profileToRenameName)
    StaticPopupDialogs[PopupDisplays.RenameProfileEnterName].text = L["Please enter the new name for the profile \""] .. profileToRenameName .. "\":";
    local dialog = StaticPopup_Show(PopupDisplays.RenameProfileEnterName);
    dialog.data = profileToRenameName;
end
StaticPopupDialogs[PopupDisplays.RenameProfileEnterName] = {
    text = "",  --set in the "Show" function
    button1 = L["Ok"],
    button2 = L["Cancel"],
    OnAccept = function(self, data, data2)
        ProfileManager.RenameProfile(data, self.editBox:GetText());
    end,
    OnShow = function(self)
        self.button1:Disable();
    end,
    EditBoxOnTextChanged = function(editBox)
        local isValid, reason = ProfileManager.IsNewProfileNameValid(editBox:GetText());
        if (isValid) then
            editBox:GetParent().button1:Enable();
        else
            _p.UserChatMessage(L["Profile name invalid: "] .. reason);
            editBox:GetParent().button1:Disable();
        end
    end,
    hasEditBox = true,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}


function PopupDisplays.ShowDeleteProfile(profileName)
    local charactersForProfile = ProfileManager.GetCharacterListForProfileName(profileName);
    if (#charactersForProfile == 0) then
        StaticPopupDialogs[PopupDisplays.DeleteProfile].text = L["Do you really want to delete the profile \""] .. profileName .. L["? This cannot be undone."];
    else
        local characterListString = table.concat(charactersForProfile, ", ");
        StaticPopupDialogs[PopupDisplays.DeleteProfile].text = L["This profile is currently in use by "] .. #charactersForProfile ..
            L["characters. If you delete this profile all usages will be replaced with the default profile.\nCharacters affected: "] .. characterListString;
    end
    local dialog = StaticPopup_Show(PopupDisplays.DeleteProfile);
    dialog.data = profileName;
end
StaticPopupDialogs[PopupDisplays.DeleteProfile] = {
    text = "",  --set in the "Show" function
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, data, data2)
        ProfileManager.DeleteProfile(data);
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    showAlert = true,
}