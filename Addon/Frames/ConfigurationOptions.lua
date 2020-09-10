local ADDON_NAME, _p = ...;
local L = _p.L;
local ProfileManager = _p.ProfileManager;
local Constants = _p.Constants;

_p.ConfigurationOptions = {};
local ConfigurationOptions = _p.ConfigurationOptions;

local function P()
    return ProfileManager.GetCurrent();
end

ConfigurationOptions.Type = {
    SliderValue = "SliderValue",
    ProfileSelector = "ProfileSelector",
    CheckBox = "CheckBox",
}
local CType = ConfigurationOptions.Type;

ConfigurationOptions.Categories = {
    [1] = {
        Name = L["Raidframes"],
        Sections = {
            [1] = {
                Name = L["Frame Layout"],
                Options = {
                    [1] = {
                        Name = L["Width"],
                        Type = CType.SliderValue,
                        Min = select(1, _p.UnitFrame.GetMinimumSize()),
                        SoftMax = 400,
                        Set = function(value)
                            P().RaidFrame.FrameWidth = value;
                        end,
                        Get = function()
                            return P().RaidFrame.FrameWidth;
                        end,
                    },
                    [2] = {
                        Name = L["Height"],
                        Type = CType.SliderValue,
                        Min = select(2, _p.UnitFrame.GetMinimumSize()),
                        SoftMax = 200,
                        Set = function(value)
                            P().RaidFrame.FrameHeight = value;
                        end,
                        Get = function()
                            return P().RaidFrame.FrameHeight;
                        end,
                    },
                },
            },
            [2] = {
                Name = L["Class Displays (top right)"],
                Options = {
                    [1] = {
                        Name = L["Width"],
                        Type = CType.SliderValue,
                        Min = select(1, _p.UnitFrame.GetMinimumSize()),
                        SoftMax = 400,
                        Set = function(value)
                            P().RaidFrame.SpecialClassDisplay.iconWidth = value;
                        end,
                        Get = function()
                            return P().RaidFrame.SpecialClassDisplay.iconWidth;
                        end,
                    },
                    [2] = {
                        Name = L["Height"],
                        Type = CType.SliderValue,
                        Min = select(2, _p.UnitFrame.GetMinimumSize()),
                        SoftMax = 200,
                        Set = function(value)
                            P().RaidFrame.SpecialClassDisplay.iconHeight = value;
                        end,
                        Get = function()
                            return P().RaidFrame.SpecialClassDisplay.iconHeight;
                        end,
                    },
                },
            },
        },
    },
    [2] = {
        Name = L["Partyframes"],
        Sections = {
            [1] = {
                Name = L["Frame Layout"],
                Options = {
                    [1] = {
                        Name = L["Width"],
                        Type = CType.SliderValue,
                        Min = select(1, _p.UnitFrame.GetMinimumSize()),
                        SoftMax = 400,
                        Set = function(value)
                            P().PartyFrame.FrameWidth = value;
                        end,
                        Get = function()
                            return P().PartyFrame.FrameWidth;
                        end,
                    },
                    [2] = {
                        Name = L["Height"],
                        Type = CType.SliderValue,
                        Min = select(2, _p.UnitFrame.GetMinimumSize()),
                        SoftMax = 200,
                        Set = function(value)
                            P().PartyFrame.FrameHeight = value;
                        end,
                        Get = function()
                            return P().PartyFrame.FrameHeight;
                        end,
                    },
                    [3] = {
                        Name = L["Inner Spacing"],
                        Type = CType.SliderValue,
                        Min = 0,
                        SoftMax = 10,
                        Set = function(value)
                            P().PartyFrame.FrameSpacing = value;
                        end,
                        Get = function()
                            return P().PartyFrame.FrameSpacing;
                        end,
                    },
                },
            },
            [2] = {
                Name = L["Class Displays (top right)"],
                Options = {
                    [1] = {
                        Name = L["Width"],
                        Type = CType.SliderValue,
                        Min = 4,
                        SoftMax = 100,
                        Set = function(value)
                            P().PartyFrame.SpecialClassDisplay.iconWidth = value;
                        end,
                        Get = function()
                            return P().PartyFrame.SpecialClassDisplay.iconWidth;
                        end,
                    },
                    [2] = {
                        Name = L["Height"],
                        Type = CType.SliderValue,
                        Min = 4,
                        SoftMax = 100,
                        Set = function(value)
                            P().PartyFrame.SpecialClassDisplay.iconHeight = value;
                        end,
                        Get = function()
                            return P().PartyFrame.SpecialClassDisplay.iconHeight;
                        end,
                    },
                },
            },
        },
    },
    [3] = {
        Name = L[Constants.ProfileOptionsName],
    },
}