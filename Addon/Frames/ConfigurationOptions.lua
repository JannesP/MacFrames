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


local function AddAuraGroupOptions(targetOptions, GetAuraSettings)
    local auraGroupSettings = {
        [1] = {
            Name = L["Width"],
            Type = CType.SliderValue,
            Min = 4,
            SoftMax = 100,
            Set = function(value)
                GetAuraSettings().iconWidth = value;
            end,
            Get = function()
                return GetAuraSettings().iconWidth;
            end,
        },
        [2] = {
            Name = L["Height"],
            Type = CType.SliderValue,
            Min = 4,
            SoftMax = 100,
            Set = function(value)
                GetAuraSettings().iconHeight = value;
            end,
            Get = function()
                return GetAuraSettings().iconHeight;
            end,
        },
        [3] = {
            Name = L["Count"],
            Type = CType.SliderValue,
            Min = 1,
            SoftMax = 10,
            Set = function(value)
                GetAuraSettings().iconCount = value;
            end,
            Get = function()
                return GetAuraSettings().iconCount;
            end,
        },
        [4] = {
            Name = L["Spacing"],
            Type = CType.SliderValue,
            Min = 0,
            SoftMax = 10,
            Set = function(value)
                GetAuraSettings().iconSpacing = value;
            end,
            Get = function()
                return GetAuraSettings().iconSpacing;
            end,
        },
    };
    for _, option in ipairs(auraGroupSettings) do
        tinsert(targetOptions, option);
    end
end

local function CreateAuraGroupOptions(name, GetAuraSettings)
    local options = {
        Name = L[name],
        Options = {},
    };
    AddAuraGroupOptions(options.Options, GetAuraSettings);
    return options;
end

local function AddUnitFrameOptions(targetSections, PS)
    local unitFrameOptions = {};
    tinsert(unitFrameOptions, {
        Name = L["Frame Layout"],
        Options = {
            [1] = {
                Name = L["Width"],
                Type = CType.SliderValue,
                Min = select(1, _p.UnitFrame.GetMinimumSize()),
                SoftMax = 400,
                Set = function(value)
                    PS().FrameWidth = value;
                end,
                Get = function()
                    return PS().FrameWidth;
                end,
            },
            [2] = {
                Name = L["Height"],
                Type = CType.SliderValue,
                Min = select(2, _p.UnitFrame.GetMinimumSize()),
                SoftMax = 200,
                Set = function(value)
                    PS().FrameHeight = value;
                end,
                Get = function()
                    return PS().FrameHeight;
                end,
            },
            [3] = {
                Name = L["Inner Spacing"],
                Type = CType.SliderValue,
                Min = 0,
                SoftMax = 10,
                Set = function(value)
                    PS().FrameSpacing = value;
                end,
                Get = function()
                    return PS().FrameSpacing;
                end,
            },
        },
    });
    tinsert(unitFrameOptions, {
        Name = L["Class Displays (top right)"],
        Options = {
            [1] = {
                Name = L["Width"],
                Type = CType.SliderValue,
                Min = 4,
                SoftMax = 100,
                Set = function(value)
                    PS().SpecialClassDisplay.iconWidth = value;
                end,
                Get = function()
                    return PS().SpecialClassDisplay.iconWidth;
                end,
            },
            [2] = {
                Name = L["Height"],
                Type = CType.SliderValue,
                Min = 4,
                SoftMax = 100,
                Set = function(value)
                    PS().SpecialClassDisplay.iconHeight = value;
                end,
                Get = function()
                    return PS().SpecialClassDisplay.iconHeight;
                end,
            },
        },
    });
    tinsert(unitFrameOptions, CreateAuraGroupOptions("Defensives (bottom right)", function() return PS().DefensiveBuff; end));
    tinsert(unitFrameOptions, CreateAuraGroupOptions("Boss Auras (middle)", function() return PS().BossAuras; end));
    tinsert(unitFrameOptions, CreateAuraGroupOptions("Undispellable Debuffs (bottom left)", function() return PS().OtherDebuffs; end));
    tinsert(unitFrameOptions, CreateAuraGroupOptions("Dispellable Debuffs (bottom left 2nd row)", function() return PS().DispellableDebuffs; end));

    for _, section in ipairs(unitFrameOptions) do
        tinsert(targetSections, section);
    end
end

ConfigurationOptions.Categories = {}
local _raidFrames = {
    Name = L["Raidframes"],
    Sections = {},
};
AddUnitFrameOptions(_raidFrames.Sections, function() return P().RaidFrame; end);
tinsert(ConfigurationOptions.Categories, _raidFrames);

local _partyFrames = {
    Name = L["Partyframes"],
    Sections = {},
};
AddUnitFrameOptions(_partyFrames.Sections, function() return P().PartyFrame; end);
tinsert(ConfigurationOptions.Categories, _partyFrames);

tinsert(ConfigurationOptions.Categories, {
    Name = L[Constants.ProfileOptionsName],
});