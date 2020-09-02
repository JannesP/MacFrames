local ADDON_NAME, _p = ...;
local LSM = LibStub("LibSharedMedia-3.0");

local Resources = {
    SB_HEALTH_FILL = "Interface\\AddOns\\JFrames\\Media\\HealthBar-fill.tga",
    SB_HEALTH_BACKGROUND = "Interface\\AddOns\\JFrames\\Media\\HealthBar-background.tga",
    SB_HEALTH_ABSORB = "Interface\\AddOns\\JFrames\\Media\\HealthBar-absorb.tga",
    SB_HEALTH_INCOMING_HEAL = "Interface\\AddOns\\JFrames\\Media\\HealthBar-incomingHeal.tga",

    BORDER_HEALTH_TARGET = "Interface\\AddOns\\JFrames\\Media\\Border-target.tga",
    BORDER_HEALTH_AGGRO = "Interface\\AddOns\\JFrames\\Media\\Border-aggro.tga",
}
_p.Resources = Resources;

LSM:Register("statusbar", "JFrames Health Bar", Resources.SB_HEALTH_FILL);

LSM:Register("border", "JFrames Target Border", Resources.BORDER_HEALTH_TARGET);
LSM:Register("border", "JFrames Aggro Border", Resources.BORDER_HEALTH_AGGRO);