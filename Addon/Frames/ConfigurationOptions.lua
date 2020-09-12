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

local _ufFrameLayoutIndex = 1;


local function AddAuraGroupOptions(targetOptions, GetAuraSettings)
    local auraGroupSettings = {};
    tinsert(auraGroupSettings, {
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
    });
    tinsert(auraGroupSettings, {
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
    });
    tinsert(auraGroupSettings, {
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
    });
    tinsert(auraGroupSettings, {
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
    });
        
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
    local frameLayoutOptions = {
        Name = L["Frame Layout"],
        Options = {},
    }
    tinsert(unitFrameOptions, frameLayoutOptions);
    tinsert(frameLayoutOptions.Options, {
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
    });
    tinsert(frameLayoutOptions.Options, {
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
    });
    tinsert(frameLayoutOptions.Options, {
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
    });
    tinsert(frameLayoutOptions.Options, {
        Name = L["Show Server Names"],
        Type = CType.CheckBox,
        Set = function(value)
            PS().Frames.DisplayServerNames = value;
        end,
        Get = function()
            return PS().Frames.DisplayServerNames;
        end,
    });
    tinsert(frameLayoutOptions.Options, {
        Name = L["Color based on Health"],
        Type = CType.CheckBox,
        Set = function(value)
            PS().Frames.BlendToDangerColors = value;
        end,
        Get = function()
            return PS().Frames.BlendToDangerColors;
        end,
    });
    tinsert(frameLayoutOptions.Options, {
        Name = L["Out of Range Alpha %"],
        Type = CType.SliderValue,
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
    tinsert(frameLayoutOptions.Options, {
        Name = L["Range Checks per Second"],
        Type = CType.SliderValue,
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
        Type = CType.SliderValue,
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
        Type = CType.SliderValue,
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
tinsert(_partyFrames.Sections[_ufFrameLayoutIndex].Options, {
    Name = L["Vertical"],
    Type = CType.CheckBox,
    Set = function(value)
        P().PartyFrame.Vertical = value;
    end,
    Get = function()
        return P().PartyFrame.Vertical;
    end,
});
tinsert(ConfigurationOptions.Categories, _partyFrames);

tinsert(ConfigurationOptions.Categories, {
    Name = L[Constants.ProfileOptionsName],
});