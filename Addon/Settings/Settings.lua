local ADDON_NAME, _p = ...;

local Settings = {
    PartyFrame = {
        StateDriverVisibility = "[group:raid] hide; show;",
        AnchorInfo = {
            OffsetX = -350,
            OffsetY = 0,
            AnchorPoint = "CENTER",
        },
        Vertical = true,
        FrameWidth = 100,
        FrameHeight = 50,
        FrameSpacing = 2,
        Margin = 0,
    },
    RaidFrame = {
        StateDriverVisibility = "[group:raid] show; hide;",
        AnchorInfo = {
            OffsetX = -480,
            OffsetY = -100,
            AnchorPoint = "CENTER",
        },
        HideUnnecessaryGroupsInCombat = true,
        FrameWidth = 85,
        FrameHeight = 45,
        FrameSpacing = 1,
        Margin = 0,
    },
    Frames = {
        RangeCheckThrottleSeconds = 0.050,  --The minimum time between range checks in seconds (used with GetTime())
        OutOfRangeAlpha = 0.4,  --The alpha (0.0 to 1.0) for out of range units.
        DisplayServerNames = false,  --display the server name for people on a different server or display "(*)"
        HealthBarTextureName = "JFrames Health Bar", --resource key for statusbar type in LibSharedResource
        BorderTargetName = "JFrames Target Border", --resource key for border type in LibSharedResource
        BorderAggroName = "JFrames Aggro Border", --resource key for border type in LibSharedResource
        RoleIconSize = 10,
        StatusIconSize = 14,
        BlendToDangerColors = false,
        BlendToDangerColorsRatio = 0.5,     --where the blending switches from alpha to yellow-red [0, 1]
        BlendToDangerColorsMinimum = 0.15,  --the minimum point for blending, below this everything is red  
        BlendToDangerColorsMaximum = 0.8,   --the maximum point for blending, above this everything is normal
        Padding = 2,
    },
    SpecialClassDisplay = {
        iconWidth = 14,
        iconHeight = 14,
        iconZoom = 0.1,  
    },
    DispellableDebuffs = {
        iconWidth = 18,
        iconHeight = 18,
        iconZoom = 0.1,  
        iconCount = 3,
        iconSpacing = 1,
    },
    OtherDebuffs = {
        iconWidth = 14,
        iconHeight = 14,
        iconZoom = 0.1,  
        iconCount = 3,
        iconSpacing = 1,
        UseBlizzardAuraFilter = false,
    },
    BossAuras = {
        iconWidth = 16,
        iconHeight = 16,
        iconZoom = 0.1,  
        iconCount = 2,
        iconSpacing = 2,
    },
    DefensiveBuff = {
        iconWidth = 16,
        iconHeight = 16,
        iconZoom = 0.1,  
        iconCount = 2,
        iconSpacing = 2,
    },
    SpecialClassDisplays = {    --shown in top right in order of appearance here (top right to top left)
        ["PRIEST"] = {
            [256] = {   --discipline
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
            [258] = {   --shadow
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
                [1] = { --earth shield
                    spellId = 974,
                    enabled = true,
                    debuff = false,
                    onlyByPlayer = true,
                },
            },
            [263] = {   --enh
                [1] = { --earth shield
                    spellId = 974,
                    enabled = true,
                    debuff = false,
                    onlyByPlayer = true,
                },
            },
            [264] = {   --resto
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
            },
            [66] = {   --prot
            },
            [70] = {   --ret
            },
        },
        ["MONK"] = {
            [268] = {   --brewmaster
            },
            [269] = {   --mistweaver
            },
            [270] = {   --windwalker
            },
        },
        ["DRUID"] = {
            [102] = {   --Balance
            },
            [103] = {   --Feral
            },
            [104] = {   --Guardian
            },
            [105] = {   --resto
            },
        },
        ["MAGE"] = {
            [62] = {   --arcane
            },
            [63] = {   --fire
            },
            [64] = {   --frost
            },
        },
        ["HUNTER"] = {
            [253] = {   --bm
            },
            [254] = {   --marksman
            },
            [255] = {   --survival
            },
        },
        ["WARLOCK"] = {
            [265] = {   --affli
                [1] = { --Soulstone
                    spellId = 20707,
                    enabled = true,
                    debuff = false,
                    onlyByPlayer = true,
                },
            },
            [266] = {   --demo
                [1] = { --Soulstone
                    spellId = 20707,
                    enabled = true,
                    debuff = false,
                    onlyByPlayer = true,
                },
            },
            [267] = {   --destro
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
            },
            [260] = {   --outlaw
            },
            [261] = {   --sub
            },
        },
    },

}
_p.Settings = Settings;