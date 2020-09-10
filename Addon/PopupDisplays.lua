local ADDON_NAME, _p = ...;
local L = _p.L;
local Addon = _p.Addon;
local ProfileManager = _p.ProfileManager;

_p.PopupDisplays = {};
local PopupDisplays = _p.PopupDisplays;
PopupDisplays.ResetSavedVariables = "MACFRAMES_RESET_SAVED_VARIABLES";
PopupDisplays.CopyProfileEnterName = "MACFRAMES_COPY_PROFILE_ENTER_NAME";

function PopupDisplays.ShowResetSettingsPrompt()
    StaticPopup_Show(PopupDisplays.ResetSavedVariables);
end
StaticPopupDialogs[PopupDisplays.ResetSavedVariables] = {
    text = L["Do you really want to reset the addon settings? This will reload your UI.\nALL PROFILES WILL BE DELETED!"],
    button1 = YES,
    button2 = NO,
    OnAccept = function(self)
        ProfileManager.ResetAddonSettings();
        C_UI.Reload();
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
        if (ProfileManager.IsNewProfileNameValid(editBox:GetText())) then
            editBox:GetParent().button1:Enable();
        else
            editBox:GetParent().button1:Disable();
        end
    end,
    hasEditBox = true,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}