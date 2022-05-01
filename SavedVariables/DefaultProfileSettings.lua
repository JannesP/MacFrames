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
local Constants = _p.Constants;
local MacEnum = _p.MacEnum;

local LSM = LibStub("LibSharedMedia-3.0");
--fonts (especially size) might need tweaking for other locales, but you can change them in the settings anyways
local _defaultFont = LSM:GetDefault("font");
local _defaultFontSizeSmall = 10;
local _defaultFontSizeNormal = 12;

_p.ProfileSettingsTypes = {
    Properties = "properties",
    Array = "array",
}
local ProfileSettingsTypes = _p.ProfileSettingsTypes;

_p.DefaultProfileSettings = {
    Version = 0,
    DisableCompactUnitFrameManager = false,
    PartyFrame = {
        FrameStrata = "MEDIUM",
        FrameLevel = 1000,
        StateDriverVisibility = "[group:raid] hide; [group:party] show; hide;",
        StateDriverVisibilityForcePlayer = "[group:raid] hide; show;",
        AlwaysShowPlayer = true,
        DisableBlizzardFrames = true,
        Enabled = true,
        AnchorInfo = {
            OffsetX = 450,
            OffsetY = -450,
            AnchorPoint = "TOPLEFT",
        },
        Vertical = true,
        FrameWidth = 100,
        FrameHeight = 50,
        FrameSpacing = 2,
        Margin = 0,
        PetFrames = {
            Enabled = true,
            PositionTo = MacEnum.Settings.PetFramePosition.Right,
            AlignWithPlayer = MacEnum.Settings.PetFramePartyAlignment.Beginning,
            FrameWidth = 80,
            FrameHeight = 35,
            Frames = {
                RangeCheckThrottleSeconds = 0.200,  --The minimum time between range checks in seconds (used with C_Timer)
                BossPollingThrottleSeconds = 0.500,  --The minimum time between range checks in seconds (used with C_Timer)
                OutOfRangeAlpha = 0.4,  --The alpha (0.0 to 1.0) for out of range units.
                DisplayServerNames = false,  --display the server name for people on a different server or display "(*)"
                HealthBarTextureName = Constants.HealthBarDefaultTextureName, --resource key for statusbar type in LibSharedResource
                PowerBarTextureName = Constants.PowerBarDefaultTextureName, --resource key for statusbar type in LibSharedResource
                PowerBarEnabled = false,
                PowerBarHeight = 5,
                RoleIconSize = 10,
                RaidTargetIconEnabled = true,
                RaidTargetIconSize = 20,
                RaidTargetIconAlpha = 0.6,
                StatusIconSize = 14,
                BlendToDangerColors = false,
                BlendToDangerColorsRatio = 0.5,     --where the blending switches from alpha to yellow-red [0, 1]
                BlendToDangerColorsMinimum = 0.15,  --the minimum point for blending, below this everything is red  
                BlendToDangerColorsMaximum = 0.8,   --the maximum point for blending, above this everything is normal
                Padding = 2,
                TargetBorderWidth = 2,
                AggroBorderWidth = 1,
                NameFont = {
                    Name = _defaultFont,
                    Size = _defaultFontSizeSmall,
                },
                StatusTextFont = {
                    Name = _defaultFont,
                    Size = _defaultFontSizeNormal,
                },
            },
            SpecialClassDisplay = {
                enabled = false,
            },
            DispellableDebuffs = {
                Enabled = false,
            },
            OtherDebuffs = {
                Enabled = false,
            },
            BossAuras = {
                Enabled = false,
            },
            DefensiveBuff = {
                Enabled = false,
            },
            Buffs = {
                Enabled = false,
            },
        },
        Frames = {
            RangeCheckThrottleSeconds = 0.100,  --The minimum time between range checks in seconds (used with C_Timer)
            BossPollingThrottleSeconds = 0.200,  --The minimum time between range checks in seconds (used with C_Timer)
            OutOfRangeAlpha = 0.4,  --The alpha (0.0 to 1.0) for out of range units.
            DisplayServerNames = false,  --display the server name for people on a different server or display "(*)"
            HealthBarTextureName = Constants.HealthBarDefaultTextureName, --resource key for statusbar type in LibSharedResource
            PowerBarTextureName = Constants.PowerBarDefaultTextureName, --resource key for statusbar type in LibSharedResource
            PowerBarEnabled = true,
            PowerBarHeight = 5,
            RoleIconSize = 10,
            RaidTargetIconEnabled = true,
            RaidTargetIconSize = 20,
            RaidTargetIconAlpha = 0.6,
            StatusIconSize = 14,
            BlendToDangerColors = false,
            BlendToDangerColorsRatio = 0.5,     --where the blending switches from alpha to yellow-red [0, 1]
            BlendToDangerColorsMinimum = 0.15,  --the minimum point for blending, below this everything is red  
            BlendToDangerColorsMaximum = 0.8,   --the maximum point for blending, above this everything is normal
            Padding = 2,
            TargetBorderWidth = 2,
            AggroBorderWidth = 1,
            NameFont = {
                Name = _defaultFont,
                Size = _defaultFontSizeSmall,
            },
            StatusTextFont = {
                Name = _defaultFont,
                Size = _defaultFontSizeNormal,
            },
        },
        SpecialClassDisplay = {
            iconWidth = 14,
            iconHeight = 14,
            iconZoom = 0.1,
            iconSpacing = 1,
            fixedPositions = false,
            useBlizzardAuraFilter = false,
            enabled = false,
            EnableAuraTooltips = false,
        },
        DispellableDebuffs = {
            iconWidth = 14,
            iconHeight = 14,
            iconZoom = 0.1,  
            iconCount = 2,
            iconSpacing = 1,
            useBlizzardAuraFilter = true,
            EnableAuraTooltips = false,
            Enabled = true,
        },
        OtherDebuffs = {
            iconWidth = 14,
            iconHeight = 14,
            iconZoom = 0.1,  
            iconCount = 3,
            iconSpacing = 1,
            useBlizzardAuraFilter = true,
            EnableAuraTooltips = false,
            Enabled = true,
        },
        BossAuras = {
            iconWidth = 20,
            iconHeight = 20,
            iconZoom = 0.1,  
            iconCount = 1,
            iconSpacing = 2,
            useBlizzardAuraFilter = true,
            EnableAuraTooltips = false,
            Enabled = true,
        },
        DefensiveBuff = {
            iconWidth = 16,
            iconHeight = 16,
            iconZoom = 0.1,  
            iconCount = 2,
            iconSpacing = 2,
            useBlizzardAuraFilter = false,
            EnableAuraTooltips = false,
            Enabled = true,
        },
        Buffs = {
            iconWidth = 14,
            iconHeight = 14,
            iconZoom = 0.1,  
            iconCount = 2,
            iconSpacing = 2,
            useBlizzardAuraFilter = true,
            EnableAuraTooltips = false,
            Enabled = true,
        },
    },
    RaidFrame = {
        FrameStrata = "MEDIUM",
        FrameLevel = 1000,
        StateDriverVisibility = "[group:raid] show; hide;",
        DisableBlizzardFrames = true,
        Enabled = true,
        AnchorInfo = {
            OffsetX = -480,
            OffsetY = -100,
            AnchorPoint = "CENTER",
        },
        HideUnnecessaryGroupsInCombat = true,
        FrameWidth = 90,
        FrameHeight = 50,
        FrameSpacing = 1,
        Margin = 0,
        Frames = {
            RangeCheckThrottleSeconds = 0.050,  --The minimum time between range checks in seconds (used with C_Timer)
            BossPollingThrottleSeconds = 0.200,  --The minimum time between range checks in seconds (used with C_Timer)
            OutOfRangeAlpha = 0.4,  --The alpha (0.0 to 1.0) for out of range units.
            DisplayServerNames = false,  --display the server name for people on a different server or display "(*)"
            HealthBarTextureName = Constants.HealthBarDefaultTextureName, --resource key for statusbar type in LibSharedResource
            PowerBarTextureName = Constants.PowerBarDefaultTextureName, --resource key for statusbar type in LibSharedResource
            PowerBarEnabled = false,
            PowerBarHeight = 5,
            RoleIconSize = 10,
            RaidTargetIconEnabled = true,
            RaidTargetIconSize = 20,
            RaidTargetIconAlpha = 0.6,
            StatusIconSize = 14,
            BlendToDangerColors = false,
            BlendToDangerColorsRatio = 0.5,     --where the blending switches from alpha to yellow-red [0, 1]
            BlendToDangerColorsMinimum = 0.15,  --the minimum point for blending, below this everything is red  
            BlendToDangerColorsMaximum = 0.8,   --the maximum point for blending, above this everything is normal
            Padding = 2,
            TargetBorderWidth = 2,
            AggroBorderWidth = 1,
            NameFont = {
                Name = _defaultFont,
                Size = _defaultFontSizeSmall,
            },
            StatusTextFont = {
                Name = _defaultFont,
                Size = _defaultFontSizeNormal,
            },
        },
        SpecialClassDisplay = {
            iconWidth = 14,
            iconHeight = 14,
            iconZoom = 0.1,
            iconSpacing = 1,
            fixedPositions = false,
            useBlizzardAuraFilter = false,
            enabled = false,
            EnableAuraTooltips = false,
        },
        DispellableDebuffs = {
            iconWidth = 14,
            iconHeight = 14,
            iconZoom = 0.1,  
            iconCount = 2,
            iconSpacing = 1,
            useBlizzardAuraFilter = true,
            EnableAuraTooltips = false,
            Enabled = true,
        },
        OtherDebuffs = {
            iconWidth = 14,
            iconHeight = 14,
            iconZoom = 0.1,  
            iconCount = 3,
            iconSpacing = 1,
            useBlizzardAuraFilter = true,
            EnableAuraTooltips = false,
            Enabled = true,
        },
        BossAuras = {
            iconWidth = 20,
            iconHeight = 20,
            iconZoom = 0.1,  
            iconCount = 1,
            iconSpacing = 2,
            useBlizzardAuraFilter = true,
            EnableAuraTooltips = false,
            Enabled = true,
        },
        DefensiveBuff = {
            iconWidth = 16,
            iconHeight = 16,
            iconZoom = 0.1,  
            iconCount = 2,
            iconSpacing = 2,
            useBlizzardAuraFilter = false,
            EnableAuraTooltips = false,
            Enabled = true,
        },
        Buffs = {
            iconWidth = 14,
            iconHeight = 14,
            iconZoom = 0.1,  
            iconCount = 2,
            iconSpacing = 2,
            useBlizzardAuraFilter = true,
            EnableAuraTooltips = false,
            Enabled = true,
        },
        PetFrames = {
            Enabled = false,
            PositionTo = MacEnum.Settings.PetFramePosition.Top,
            FrameWidth = 90,
            FrameHeight = 20,
            Frames = {
                RangeCheckThrottleSeconds = 0.200,  --The minimum time between range checks in seconds (used with C_Timer)
                BossPollingThrottleSeconds = 0.200,  --The minimum time between range checks in seconds (used with C_Timer)
                OutOfRangeAlpha = 0.4,  --The alpha (0.0 to 1.0) for out of range units.
                DisplayServerNames = false,  --display the server name for people on a different server or display "(*)"
                HealthBarTextureName = Constants.HealthBarDefaultTextureName, --resource key for statusbar type in LibSharedResource
                PowerBarTextureName = Constants.PowerBarDefaultTextureName, --resource key for statusbar type in LibSharedResource
                PowerBarEnabled = false,
                PowerBarHeight = 5,
                RoleIconSize = 10,
                RaidTargetIconEnabled = true,
                RaidTargetIconSize = 20,
                RaidTargetIconAlpha = 0.6,
                StatusIconSize = 14,
                BlendToDangerColors = false,
                BlendToDangerColorsRatio = 0.5,     --where the blending switches from alpha to yellow-red [0, 1]
                BlendToDangerColorsMinimum = 0.15,  --the minimum point for blending, below this everything is red  
                BlendToDangerColorsMaximum = 0.8,   --the maximum point for blending, above this everything is normal
                Padding = 2,
                TargetBorderWidth = 2,
                AggroBorderWidth = 1,
                NameFont = {
                    Name = _defaultFont,
                    Size = _defaultFontSizeSmall,
                },
                StatusTextFont = {
                    Name = _defaultFont,
                    Size = _defaultFontSizeNormal,
                },
            },
            SpecialClassDisplay = {
                enabled = false,
            },
            DispellableDebuffs = {
                Enabled = false,
            },
            OtherDebuffs = {
                Enabled = false,
            },
            BossAuras = {
                Enabled = false,
            },
            DefensiveBuff = {
                Enabled = false,
            },
            Buffs = {
                Enabled = false,
            },
        },
    },
    SpecialClassDisplays = {    --shown in top right in order of appearance here (top right to top left)
        ["PRIEST"] = {
            [256] = {   --discipline
                _settingsType = ProfileSettingsTypes.Array;
                [1] = { --Atonement
                    spellId = 194384,   
                    enabled = true,
                    debuff = false,
                    onlyByPlayer = true,
                },    
                [2] = { --Weakened Soul
                    spellId = 6788, 
                    enabled = true,
                    debuff = true,
                    onlyByPlayer = true,
                },
                [3] = { --PI
                    spellId = 10060, 
                    enabled = true,
                    debuff = false,
                    onlyByPlayer = false,
                },
            },
            [257] = {   --holy
                _settingsType = ProfileSettingsTypes.Array;
                [1] = { --Renew
                    spellId = 139,
                    enabled = true,
                    debuff = false,
                    onlyByPlayer = true,
                },
                [2] = { --PoM
                    spellId = 41635, 
                    enabled = true,
                    debuff = false,
                    onlyByPlayer = true,
                },
                [3] = { --PI
                    spellId = 10060, 
                    enabled = true,
                    debuff = false,
                    onlyByPlayer = false,
                },
                [4] = { --Weakened Soul
                    spellId = 6788, 
                    enabled = true,
                    debuff = true,
                    onlyByPlayer = true,
                },
            },
            [258] = {   --shadow
                _settingsType = ProfileSettingsTypes.Array;
                [1] = { --Weakened Soul
                    spellId = 6788,
                    enabled = true,
                    debuff = true,
                    onlyByPlayer = true,
                },
                [2] = { --PI
                    spellId = 10060, 
                    enabled = true,
                    debuff = false,
                    onlyByPlayer = false,
                },
            },
        },
        ["SHAMAN"] = {
            [262] = {   --ele
                _settingsType = ProfileSettingsTypes.Array;
                [1] = { --earth shield
                    spellId = 974,
                    enabled = true,
                    debuff = false,
                    onlyByPlayer = true,
                },
            },
            [263] = {   --enh
                _settingsType = ProfileSettingsTypes.Array;
                [1] = { --earth shield
                    spellId = 974,
                    enabled = true,
                    debuff = false,
                    onlyByPlayer = true,
                },
            },
            [264] = {   --resto
                _settingsType = ProfileSettingsTypes.Array;
                [1] = { --riptide
                    spellId = 61295,
                    enabled = true,
                    debuff = false,
                    onlyByPlayer = true,
                },
                [2] = { --earth shield
                    spellId = 974,
                    enabled = true,
                    debuff = false,
                    onlyByPlayer = true,
                },
            },
        },
        ["PALADIN"] = {
            [65] = {   --holy
                _settingsType = ProfileSettingsTypes.Array;
            },
            [66] = {   --prot
                _settingsType = ProfileSettingsTypes.Array;
            },
            [70] = {   --ret
                _settingsType = ProfileSettingsTypes.Array;
            },
        },
        ["MONK"] = {
            [268] = {   --brewmaster
                _settingsType = ProfileSettingsTypes.Array;
            },
            [269] = {   --mistweaver
                _settingsType = ProfileSettingsTypes.Array;
            },
            [270] = {   --windwalker
                _settingsType = ProfileSettingsTypes.Array;
            },
        },
        ["DRUID"] = {
            [102] = {   --Balance
                _settingsType = ProfileSettingsTypes.Array;
            },
            [103] = {   --Feral
                _settingsType = ProfileSettingsTypes.Array;
            },
            [104] = {   --Guardian
                _settingsType = ProfileSettingsTypes.Array;
            },
            [105] = {   --resto
                _settingsType = ProfileSettingsTypes.Array;
            },
        },
        ["MAGE"] = {
            [62] = {   --arcane
                _settingsType = ProfileSettingsTypes.Array;
            },
            [63] = {   --fire
                _settingsType = ProfileSettingsTypes.Array;
            },
            [64] = {   --frost
                _settingsType = ProfileSettingsTypes.Array;
            },
        },
        ["HUNTER"] = {
            [253] = {   --bm
                _settingsType = ProfileSettingsTypes.Array;
            },
            [254] = {   --marksman
                _settingsType = ProfileSettingsTypes.Array;
            },
            [255] = {   --survival
                _settingsType = ProfileSettingsTypes.Array;
            },
        },
        ["WARLOCK"] = {
            [265] = {   --affli
                _settingsType = ProfileSettingsTypes.Array;
                [1] = { --Soulstone
                    spellId = 20707,
                    enabled = true,
                    debuff = false,
                    onlyByPlayer = true,
                },
            },
            [266] = {   --demo
                _settingsType = ProfileSettingsTypes.Array;
                [1] = { --Soulstone
                    spellId = 20707,
                    enabled = true,
                    debuff = false,
                    onlyByPlayer = true,
                },
            },
            [267] = {   --destro
                _settingsType = ProfileSettingsTypes.Array;
                [1] = { --Soulstone
                    spellId = 20707,
                    enabled = true,
                    debuff = false,
                    onlyByPlayer = true,
                },
            },
        },
        ["ROGUE"] = {
            [259] = {   --assa
                _settingsType = ProfileSettingsTypes.Array;
            },
            [260] = {   --outlaw
                _settingsType = ProfileSettingsTypes.Array;
            },
            [261] = {   --sub
                _settingsType = ProfileSettingsTypes.Array;
            },
        },
    },
    MouseActions = {},         --generated below
}
local DefaultMouseActions = _p.DefaultProfileSettings.MouseActions;
local _clickBindingDefaults = {
    _settingsType = ProfileSettingsTypes.Array;
    [1] = {
        alt = false,
        ctrl = false,
        shift = false,
        button = "1",       --a mouse button for use with SetAttribute
        helpHarm = "help",  --unused for now but defaults to 'help' in case I want to make target frames at some point
        type = "target",    --a type for use with SetAttribute
        spellId = nil,      --spellId for language changes
        spellName = nil,    --translated spell name for use with SetAttribute
        itemSelector = nil, --macro item slot or item name
    },
    [2] = {
        alt = false,
        ctrl = false,
        shift = false,
        button = "2",
        helpHarm = "help",
        type = "togglemenu",
        spellName = nil,
        itemSelector = nil,
    },
};
local numClasses = GetNumClasses();
for i=1,numClasses do
    local _, _, classID = GetClassInfo(i);
    local specList = {};
    DefaultMouseActions[classID] = specList;
    local numSpecs = GetNumSpecializationsForClassID(classID);
    for n=1, numSpecs do
        local specID = GetSpecializationInfoForClassID(classID, n);
        specList[specID] = _clickBindingDefaults;
    end
end