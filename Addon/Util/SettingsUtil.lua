local ADDON_NAME, _p = ...; 
local Settings = _p.Settings;
local PlayerInfo = _p.PlayerInfo;
local ProfileManager = _p.ProfileManager;

local SettingsUtil = {
    GetSpecialClassDisplays = function()
        if (PlayerInfo.class == nil or PlayerInfo.specId == nil) then
            return nil;
        end
        local classDisplay = ProfileManager.GetCurrent().SpecialClassDisplays[PlayerInfo.class][PlayerInfo.specId];
        if (classDisplay ~= nil) then
            classDisplay = classDisplay:GetRawEntries();
        else
            classDisplay = nil;
        end
        return classDisplay;
    end,
};
_p.SettingsUtil = SettingsUtil;