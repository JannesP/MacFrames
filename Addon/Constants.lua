local ADDON_NAME, _p = ...;

_p.Constants = {
    HealthBarDefaultTextureName = "MacFrames Health Bar";
    TargetBorderDefaultTextureName =  "MacFrames Target Border";
    AggroBorderDefaultTextureName =  "MacFrames Aggro Border";
    PartyFrameGlobalName = "MacFramesParty",
    RaidFrameGlobalName = "MacFramesRaid",
    GroupSize = 5,
    RaidGroupCount = 8,
    TestModeFrameStrata = "MEDIUM",
    DefaultProfileName = "Default",
    TooltipBorderClearance = 6,
    UnitFrame = {
        MinHeight = 32,
        MinWidth = 70,
    },
    Settings = {
        EditorWidth = 130,
        EditorHeight = 42,
    }
};
local Constants = _p.Constants;