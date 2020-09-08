local ADDON_NAME, _p = ...;
local L = _p.L;
local ProfileManager = _p.ProfileManager;

_p.ConfigurationOptions = {};
local ConfigurationOptions = _p.ConfigurationOptions;

ProfileManager.RegisterProfileChangedListener(function(newProfile)
    _profile = newProfile;
end);
local _profile = nil;

ConfigurationOptions.Type = {
    SliderValue = "SliderValue",
    ProfileSelector = "ProfileSelector",
    CheckBox = "CheckBox",
}
local CType = ConfigurationOptions.Type;

ConfigurationOptions.Categories = {
    [1] = {
        Name = L["Raidframes"],
        Options = {
            [1] = {
                Name = L["Width"],
                Type = CType.SliderValue,
                Min = select(1, _p.UnitFrame.GetMinimumSize()),
                SoftMax = 400,
                Set = function(value)
                    _profile.RaidFrame.FrameWidth = value;
                end,
                Get = function()
                    return _profile.RaidFrame.FrameWidth;
                end,
            },
            [2] = {
                Name = L["Height"],
                Type = CType.SliderValue,
                Min = select(2, _p.UnitFrame.GetMinimumSize()),
                SoftMax = 200,
                Set = function(value)
                    _profile.RaidFrame.FrameHeight = value;
                end,
                Get = function()
                    return _profile.RaidFrame.FrameHeight;
                end,
            },
        },
    },
    [2] = {
        Name = L["Partyframes"],
        Options = {
            [1] = {
                Name = L["Width"],
                Type = CType.SliderValue,
                Min = select(1, _p.UnitFrame.GetMinimumSize()),
                SoftMax = 400,
                Set = function(value)
                    _profile.RaidFrame.PartyFrame = value;
                end,
                Get = function()
                    return _profile.RaidFrame.PartyFrame;
                end,
            },
            [2] = {
                Name = L["Height"],
                Type = CType.SliderValue,
                Min = select(2, _p.UnitFrame.GetMinimumSize()),
                SoftMax = 300,
                Set = function(value)
                    _profile.RaidFrame.FrameHeight = value;
                end,
                Get = function()
                    return _profile.RaidFrame.FrameHeight;
                end,
            },
        }
    },
    [3] = {
        Name = L["Profiles"],
        Options = {
            [1] = {
                Name = L["Profile"],
                Type = CType.ProfileSelector,
            },
        }
    },
}