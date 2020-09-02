local ADDON_NAME, _p = ...;
local LSM = LibStub("LibSharedMedia-3.0");

local Resources = {
    SB_HEALTH_FILL = "Interface\\AddOns\\MacFrames\\Media\\HealthBar-fill.tga",
    SB_HEALTH_BACKGROUND = "Interface\\AddOns\\MacFrames\\Media\\HealthBar-background.tga",
    SB_HEALTH_ABSORB = "Interface\\AddOns\\MacFrames\\Media\\HealthBar-absorb.tga",
    SB_HEALTH_INCOMING_HEAL = "Interface\\AddOns\\MacFrames\\Media\\HealthBar-incomingHeal.tga",

    BORDER_HEALTH_TARGET = "Interface\\AddOns\\MacFrames\\Media\\Border-target.tga",
    BORDER_HEALTH_AGGRO = "Interface\\AddOns\\MacFrames\\Media\\Border-aggro.tga",
}
_p.Resources = Resources;

LSM:Register("statusbar", "MacFrames Health Bar", Resources.SB_HEALTH_FILL);

LSM:Register("border", "MacFrames Target Border", Resources.BORDER_HEALTH_TARGET);
LSM:Register("border", "MacFrames Aggro Border", Resources.BORDER_HEALTH_AGGRO);