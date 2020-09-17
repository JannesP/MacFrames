local ADDON_NAME, _p = ...;
local Constants = _p.Constants;
local LSM = LibStub("LibSharedMedia-3.0");

local Resources = {
    SB_HEALTH_FILL = "Interface\\AddOns\\MacFrames\\Media\\HealthBar-fill.tga",
    SB_HEALTH_BACKGROUND = "Interface\\AddOns\\MacFrames\\Media\\HealthBar-background.tga",

    BORDER_HEALTH_TARGET = "Interface\\AddOns\\MacFrames\\Media\\Border-target.tga",
    BORDER_HEALTH_AGGRO = "Interface\\AddOns\\MacFrames\\Media\\Border-aggro.tga",
}
_p.Resources = Resources;

LSM:Register("statusbar", Constants.HealthBarDefaultTextureName, Resources.SB_HEALTH_FILL);

LSM:Register("border", Constants.TargetBorderDefaultTextureName, Resources.BORDER_HEALTH_TARGET);
LSM:Register("border", Constants.AggroBorderDefaultTextureName, Resources.BORDER_HEALTH_AGGRO);