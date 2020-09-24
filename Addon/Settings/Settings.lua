local ADDON_NAME, _p = ...;
local L = _p.L;
local ProfileManager = _p.ProfileManager;
local Constants = _p.Constants;

_p.Settings = {};
local Settings = _p.Settings;

--[[
    structure:
    {
        Name = "Name of the category",
        Type = Settings.CategoryType.???,
        Sections = {
            [1] = {
                Name = "Name of the Section",  
                Options = {
                    [1] = {
                        Name = "Name of the option",
                        Type = Settings.OptionType.???,
                        Set = function to set value from the ui, should do the necessary conversions,
                        Get = function to display in the ui, should do the necessary conversions,
                        [...] = special properties spcific to the given OptionType,
                    }
                },
                Sections = {
                    [1] = { Same structure again },
                }
            },
        }
    }
]]
Settings.Categories = {}
Settings.OptionType = {
    SliderValue = "SliderValue",
    ProfileSelector = "ProfileSelector",
    CheckBox = "CheckBox",
}
Settings.CategoryType = {
    Profile = "profile",
    Options = "options",
}

local OptionType = Settings.OptionType;


local function P()
    return ProfileManager.GetCurrent();
end

local function CreateSection(name)
    return {
        Name = name,
        Options = {},
        Sections = {},
    }
end

local _ufFrameLayoutIndex = 1;

local function AddAuraGroupOptions(targetOptions, GetAuraSettings)
    local auraGroupSettings = {};
    tinsert(auraGroupSettings, {
        Name = L["Width"],
        Type = OptionType.SliderValue,
        Min = 4,
        SoftMax = 100,
        Set = function(value)
            GetAuraSettings().iconWidth = value;
        end,
        Get = function()
            return GetAuraSettings().iconWidth;
        end,
    });
    tinsert(auraGroupSettings, {
        Name = L["Height"],
        Type = OptionType.SliderValue,
        Min = 4,
        SoftMax = 100,
        Set = function(value)
            GetAuraSettings().iconHeight = value;
        end,
        Get = function()
            return GetAuraSettings().iconHeight;
        end,
    });
    tinsert(auraGroupSettings, {
        Name = L["Count"],
        Type = OptionType.SliderValue,
        Min = 1,
        SoftMax = 10,
        Set = function(value)
            GetAuraSettings().iconCount = value;
        end,
        Get = function()
            return GetAuraSettings().iconCount;
        end,
    });
    tinsert(auraGroupSettings, {
        Name = L["Spacing"],
        Type = OptionType.SliderValue,
        Min = 0,
        SoftMax = 10,
        Set = function(value)
            GetAuraSettings().iconSpacing = value;
        end,
        Get = function()
            return GetAuraSettings().iconSpacing;
        end,
    });
        
    for i=1, #auraGroupSettings do
        tinsert(targetOptions, auraGroupSettings[i]);
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
    local frameLayoutOptions = CreateSection(L["Frame Layout"]);
    
    local subSectionIndicators = CreateSection(L["Indicators"]);
    tinsert(frameLayoutOptions.Sections, subSectionIndicators);
    local subSectionPerformance = CreateSection(L["Performance"]);
    tinsert(frameLayoutOptions.Sections, subSectionPerformance);

    tinsert(unitFrameOptions, frameLayoutOptions);
    tinsert(frameLayoutOptions.Options, {
        Name = L["Width"],
        Type = OptionType.SliderValue,
        Min = Constants.UnitFrame.MinWidth,
        SoftMax = 400,
        Set = function(value)
            PS().FrameWidth = value;
        end,
        Get = function()
            return PS().FrameWidth;
        end,
    });
    tinsert(frameLayoutOptions.Options, {
        Name = L["Height"],
        Type = OptionType.SliderValue,
        Min = Constants.UnitFrame.MinHeight,
        SoftMax = 200,
        Set = function(value)
            PS().FrameHeight = value;
        end,
        Get = function()
            return PS().FrameHeight;
        end,
    });
    tinsert(frameLayoutOptions.Options, {
        Name = L["Inner Spacing"],
        Type = OptionType.SliderValue,
        Min = 0,
        SoftMax = 10,
        Set = function(value)
            PS().FrameSpacing = value;
        end,
        Get = function()
            return PS().FrameSpacing;
        end,
    });
    tinsert(frameLayoutOptions.Options, {
        Name = L["Aura Padding"],
        Type = OptionType.SliderValue,
        Min = 0,
        SoftMax = 10,
        Set = function(value)
            PS().Frames.Padding = value;
        end,
        Get = function()
            return PS().Frames.Padding;
        end,
    });
    tinsert(frameLayoutOptions.Options, {
        Name = L["Show Server Names"],
        Type = OptionType.CheckBox,
        Set = function(value)
            PS().Frames.DisplayServerNames = value;
        end,
        Get = function()
            return PS().Frames.DisplayServerNames;
        end,
    });
    
    tinsert(subSectionIndicators.Options, {
        Name = L["Color based on Health"],
        Type = OptionType.CheckBox,
        Set = function(value)
            PS().Frames.BlendToDangerColors = value;
        end,
        Get = function()
            return PS().Frames.BlendToDangerColors;
        end,
    });
    tinsert(subSectionIndicators.Options, {
        Name = L["Out of Range Alpha %"],
        Type = OptionType.SliderValue,
        Min = 0,
        Max = 100,
        StepSize = 1,
        Set = function(value)
            PS().Frames.OutOfRangeAlpha = value / 100;
        end,
        Get = function()
            return PS().Frames.OutOfRangeAlpha * 100;
        end,
    });
    tinsert(subSectionPerformance.Options, {
        Name = L["Range Checks per Second"],
        Type = OptionType.SliderValue,
        Min = 1,
        SoftMax = 144,
        StepSize = 1,
        Set = function(value)
            PS().Frames.RangeCheckThrottleSeconds = 1 / value;
        end,
        Get = function()
            return 1 / PS().Frames.RangeCheckThrottleSeconds;
        end,
    });
    
    local classDisplayOptions = {
        Name = L["Class Displays"],
        Options = {},
    }
    tinsert(unitFrameOptions, classDisplayOptions);
    tinsert(classDisplayOptions.Options, {
        Name = L["Width"],
        Type = OptionType.SliderValue,
        Min = 4,
        SoftMax = 100,
        Set = function(value)
            PS().SpecialClassDisplay.iconWidth = value;
        end,
        Get = function()
            return PS().SpecialClassDisplay.iconWidth;
        end,
    });
    tinsert(classDisplayOptions.Options, {
        Name = L["Height"],
        Type = OptionType.SliderValue,
        Min = 4,
        SoftMax = 100,
        Set = function(value)
            PS().SpecialClassDisplay.iconHeight = value;
        end,
        Get = function()
            return PS().SpecialClassDisplay.iconHeight;
        end,
    });
    
    tinsert(unitFrameOptions, CreateAuraGroupOptions("Defensives", function() return PS().DefensiveBuff; end));
    tinsert(unitFrameOptions, CreateAuraGroupOptions("Boss Auras", function() return PS().BossAuras; end));
    tinsert(unitFrameOptions, CreateAuraGroupOptions("Undispellable Debuffs", function() return PS().OtherDebuffs; end));
    tinsert(unitFrameOptions, CreateAuraGroupOptions("Dispellable Debuffs", function() return PS().DispellableDebuffs; end));

    for i=1, #unitFrameOptions do
        tinsert(targetSections, unitFrameOptions[i]);
    end
end

local _raidFrames = {
    Name = L["Raidframes"],
    Type = Settings.CategoryType.Options,
    Sections = {},
};
AddUnitFrameOptions(_raidFrames.Sections, function() return P().RaidFrame; end);
tinsert(Settings.Categories, _raidFrames);

local _partyFrames = {
    Name = L["Partyframes"],
    Type = Settings.CategoryType.Options,
    Sections = {},
};
AddUnitFrameOptions(_partyFrames.Sections, function() return P().PartyFrame; end);
tinsert(_partyFrames.Sections[_ufFrameLayoutIndex].Options, {
    Name = L["Vertical"],
    Type = OptionType.CheckBox,
    Set = function(value)
        P().PartyFrame.Vertical = value;
    end,
    Get = function()
        return P().PartyFrame.Vertical;
    end,
});
tinsert(Settings.Categories, _partyFrames);

tinsert(Settings.Categories, {
    Name = L["Profiles"],
    Type = Settings.CategoryType.Profile,
});