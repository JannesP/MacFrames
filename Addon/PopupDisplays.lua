local ADDON_NAME, _p = ...;
local L = _p.L;
local Addon = _p.Addon;
local ProfileManager = _p.ProfileManager;


StaticPopupDialogs["MACFRAMES_RESET_SAVED_VARIABLES"] = {
    text = L["Do you really want to reset the addon settings?\nALL PROFILES WILL BE DELETED!"],
    button1 = YES,
    button2 = NO,
    OnAccept = function(self)
        ProfileManager.ResetAddonSettings();
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    showAlert = true,
    preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
}