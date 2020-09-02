local ADDON_NAME, _p = ...; 
local Settings = _p.Settings;
local PlayerInfo = _p.PlayerInfo;

local SettingsUtil = {
    GetSpecialClassDisplays = function()
        if (PlayerInfo.class == nil or PlayerInfo.specId == nil) then
            return nil;
        end
        return Settings.SpecialClassDisplays[PlayerInfo.class][PlayerInfo.specId];
    end,
};
_p.SettingsUtil = SettingsUtil;