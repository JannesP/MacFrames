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
local L = _p.L;
local ProfileManager = _p.ProfileManager;
local Constants = _p.Constants;
local Addon = _p.Addon;
local MacEnum = _p.MacEnum;

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
    CheckBox = "CheckBox",
    BarTexture = "BarTexture",
    ButtonAction = "ButtonAction",
    FontPicker = "FontPicker",
    EnumDropDown = "EnumDropDown",
    NotYetImplemented = "NotYetImplemented",
}
local OptionType = Settings.OptionType;
Settings.CategoryType = {
    Profile = "Profile",
    MouseActions = "MouseActions",
    AuraBlacklist = "AuraBlacklist",
    Options = "Options",
}

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
        Name = L["Enable"],
        Type = OptionType.CheckBox,
        Set = function(value)
            GetAuraSettings().Enabled = value;
        end,
        Get = function()
            return GetAuraSettings().Enabled;
        end,
    });
    tinsert(auraGroupSettings, {
        Name = L["Display Tooltips"],
        Description = L["This makes all auras in this group opaque for clicks! You won't be able to cast/target through them."],
        Type = OptionType.CheckBox,
        Set = function(value)
            GetAuraSettings().EnableAuraTooltips = value;
        end,
        Get = function()
            return GetAuraSettings().EnableAuraTooltips;
        end,
    });
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

local function CreateAuraGroupOptionsWithBlizzardFilter(name, GetAuraSettings)
    local options = CreateAuraGroupOptions(name, GetAuraSettings);
    tinsert(options.Options, {
        Name = L["Use Blizzard Aura Filter"],
        Description = L["Shows the same buffs the default raidframe shows. Otherwise this will be unfiltered."],
        Type = OptionType.CheckBox,
        Set = function(value)
            GetAuraSettings().useBlizzardAuraFilter = value;
        end,
        Get = function()
            return GetAuraSettings().useBlizzardAuraFilter;
        end,
    });
    return options;
end

local function CreatePetSection(GetUnitFrameSettings)
    local sectionPets = CreateSection(L["Pets"]);
    tinsert(sectionPets.Options, {
        Name = L["Enabled"],
        Type = OptionType.CheckBox,
        Set = function(value)
            GetUnitFrameSettings().PetFrames.Enabled = value;
        end,
        Get = function()
            return GetUnitFrameSettings().PetFrames.Enabled;
        end,
    });
    tinsert(sectionPets.Options, {
        Name = L["Position"],
        Type = OptionType.EnumDropDown,
        EnumValues = MacEnum.Settings.PetFramePosition,
        Set = function(value)
            GetUnitFrameSettings().PetFrames.PositionTo = value;
        end,
        Get = function()
            return GetUnitFrameSettings().PetFrames.PositionTo;
        end,
    });
    tinsert(sectionPets.Options, {
        Name = L["Width"],
        Type = OptionType.SliderValue,
        Min = Constants.UnitFrame.MinWidth,
        SoftMax = 400,
        Set = function(value)
            GetUnitFrameSettings().PetFrames.FrameWidth = value;
        end,
        Get = function()
            return GetUnitFrameSettings().PetFrames.FrameWidth;
        end,
    });
    tinsert(sectionPets.Options, {
        Name = L["Height"],
        Type = OptionType.SliderValue,
        Min = Constants.UnitFrame.MinHeight,
        SoftMax = 200,
        Set = function(value)
            GetUnitFrameSettings().PetFrames.FrameHeight = value;
        end,
        Get = function()
            return GetUnitFrameSettings().PetFrames.FrameHeight;
        end,
    });
    return sectionPets;
end

local function AddUnitFrameOptions(targetSections, PS, addPets)
    local unitFrameOptions = {};
    local frameLayoutOptions = CreateSection(L["Frame Layout"]);
    if (addPets == true) then
        local subSectionPets = CreatePetSection(PS);
        tinsert(frameLayoutOptions.Sections, subSectionPets);
    end
    local subSectionIndicators = CreateSection(L["Indicators"]);
    tinsert(frameLayoutOptions.Sections, subSectionIndicators);
    local subSectionPowerBar = CreateSection(L["Power Bar"]);
    tinsert(frameLayoutOptions.Sections, subSectionPowerBar);
    local subSectionRaidTargetIcon = CreateSection(L["Raid Target Icon"]);
    tinsert(frameLayoutOptions.Sections, subSectionRaidTargetIcon);
    local subSectionPerformance = CreateSection(L["Performance"]);
    tinsert(frameLayoutOptions.Sections, subSectionPerformance);

    tinsert(unitFrameOptions, frameLayoutOptions);
    tinsert(frameLayoutOptions.Options, {
        Name = L["Enabled"],
        Type = OptionType.CheckBox,
        Set = function(value)
            PS().Enabled = value;
        end,
        Get = function()
            return PS().Enabled;
        end,
    });
    tinsert(frameLayoutOptions.Options, {
        Name = L["Reset Position"],
        Description = L["In case you forgot where you put them."],
        Type = OptionType.ButtonAction,
        ButtonText = L["to Screen Center"],
        Set = function(value)
            PS().AnchorInfo.OffsetX = 0;
            PS().AnchorInfo.OffsetY = 0;
            PS().AnchorInfo.AnchorPoint = "CENTER";
        end,
        Get = _p.Noop,
    });
    tinsert(frameLayoutOptions.Options, {
        Name = L["Disable Blizzard Frames"],
        Type = OptionType.CheckBox,
        Set = function(value)
            PS().DisableBlizzardFrames = value;
        end,
        Get = function()
            return PS().DisableBlizzardFrames;
        end,
    });
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
    tinsert(subSectionIndicators.Options, {
        Name = L["Show Server Names"],
        Type = OptionType.CheckBox,
        Set = function(value)
            PS().Frames.DisplayServerNames = value;
        end,
        Get = function()
            return PS().Frames.DisplayServerNames;
        end,
    });

    tinsert(subSectionPowerBar.Options, {
        Name = L["Enabled"],
        Type = OptionType.CheckBox,
        Set = function(value)
            PS().Frames.PowerBarEnabled = value;
        end,
        Get = function()
            return PS().Frames.PowerBarEnabled;
        end,
    });
    tinsert(subSectionPowerBar.Options, {
        Name = L["Height"],
        Type = OptionType.SliderValue,
        Min = 1,
        Max = 40,
        StepSize = 1,
        Set = function(value)
            PS().Frames.PowerBarHeight = value;
        end,
        Get = function()
            return PS().Frames.PowerBarHeight;
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

    tinsert(subSectionPerformance.Options, {
        Name = L["Boss Updates per Second"],
        Type = OptionType.SliderValue,
        Min = 1,
        SoftMax = 144,
        StepSize = 1,
        Set = function(value)
            PS().Frames.BossPollingThrottleSeconds = 1 / value;
        end,
        Get = function()
            return 1 / PS().Frames.BossPollingThrottleSeconds;
        end,
    });

    tinsert(subSectionRaidTargetIcon.Options, {
        Name = L["Enabled"],
        Type = OptionType.CheckBox,
        Set = function(value)
            PS().Frames.RaidTargetIconEnabled = value;
        end,
        Get = function()
            return PS().Frames.RaidTargetIconEnabled;
        end,
    });

    tinsert(subSectionRaidTargetIcon.Options, {
        Name = L["Icon Size"],
        Type = OptionType.SliderValue,
        Min = 5,
        SoftMax = 40,
        StepSize = 1,
        Set = function(value)
            PS().Frames.RaidTargetIconSize = value;
        end,
        Get = function()
            return PS().Frames.RaidTargetIconSize;
        end,
    });

    tinsert(subSectionRaidTargetIcon.Options, {
        Name = L["Alpha %"],
        Type = OptionType.SliderValue,
        Min = 1,
        Max = 100,
        StepSize = 1,
        Set = function(value)
            PS().Frames.RaidTargetIconAlpha = value / 100;
        end,
        Get = function()
            return PS().Frames.RaidTargetIconAlpha * 100;
        end,
    });

    local lookAndFeelOptions = CreateSection(L["Look & Feel"]);
    tinsert(unitFrameOptions, lookAndFeelOptions);
    tinsert(lookAndFeelOptions.Options, {
        Name = L["Health Bar Texture"],
        Type = OptionType.BarTexture,
        Set = function(value)
            PS().Frames.HealthBarTextureName = value;
        end,
        Get = function()
            return PS().Frames.HealthBarTextureName;
        end,
    });
    tinsert(lookAndFeelOptions.Options, {
        Name = L["Power Bar Texture"],
        Type = OptionType.BarTexture,
        Set = function(value)
            PS().Frames.PowerBarTextureName = value;
        end,
        Get = function()
            return PS().Frames.PowerBarTextureName;
        end,
    });

    local nameFontSection = CreateSection(L["Name Font"]);
    tinsert(lookAndFeelOptions.Sections, nameFontSection);
    tinsert(nameFontSection.Options, {
        Name = L["Font"],
        Type = OptionType.FontPicker,
        Set = function(value)
            PS().Frames.NameFont.Name = value;
        end,
        Get = function()
            return PS().Frames.NameFont.Name;
        end,
    });
    tinsert(nameFontSection.Options, {
        Name = L["Font Size"],
        Type = OptionType.SliderValue,
        Min = 6,
        SoftMax = 30,
        StepSize = 1,
        Set = function(value)
            PS().Frames.NameFont.Size = value;
        end,
        Get = function()
            return PS().Frames.NameFont.Size;
        end,
    });

    local statusTextFontSection = CreateSection(L["Status Text Font"]);
    tinsert(lookAndFeelOptions.Sections, statusTextFontSection);
    tinsert(statusTextFontSection.Options, {
        Name = L["Font"],
        Description = L["The font in the middle if someone is AFK or dead."],
        Type = OptionType.FontPicker,
        Set = function(value)
            PS().Frames.StatusTextFont.Name = value;
        end,
        Get = function()
            return PS().Frames.StatusTextFont.Name;
        end,
    });
    tinsert(statusTextFontSection.Options, {
        Name = L["Font Size"],
        Description = L["The font in the middle if someone is AFK or dead."],
        Type = OptionType.SliderValue,
        Min = 6,
        SoftMax = 30,
        StepSize = 1,
        Set = function(value)
            PS().Frames.StatusTextFont.Size = value;
        end,
        Get = function()
            return PS().Frames.StatusTextFont.Size;
        end,
    });

    local classDisplayOptions = CreateSection(L["Class Displays"]);
    tinsert(unitFrameOptions, classDisplayOptions);
    local classDisplayCategoryConfigureAuras = CreateSection(L["Displayed Auras"]);
    tinsert(classDisplayOptions.Sections, classDisplayCategoryConfigureAuras);
    
    tinsert(classDisplayOptions.Options, {
        Name = L["Enabled"],
        Description = L["This setting is mostly for healers to have a consistent order of specific buffs (eg. HoTs).\n'Normal' buffs will be displayed below when this is enabled.'"];
        Type = OptionType.CheckBox,
        Set = function(value)
            PS().SpecialClassDisplay.enabled = value;
        end,
        Get = function()
            return PS().SpecialClassDisplay.enabled;
        end,
    });
    tinsert(classDisplayOptions.Options, {
        Name = L["Display Tooltips"],
        Description = L["This makes all auras in this group opaque for clicks! You won't be able to cast/target through them."],
        Type = OptionType.CheckBox,
        Set = function(value)
            PS().SpecialClassDisplay.EnableAuraTooltips = value;
        end,
        Get = function()
            return PS().SpecialClassDisplay.EnableAuraTooltips;
        end,
    });
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
    tinsert(classDisplayOptions.Options, {
        Name = L["Spacing"],
        Type = OptionType.SliderValue,
        Min = 0,
        SoftMax = 10,
        Set = function(value)
            PS().SpecialClassDisplay.iconSpacing = value;
        end,
        Get = function()
            return PS().SpecialClassDisplay.iconSpacing;
        end,
    });
    tinsert(classDisplayOptions.Options, {
        Name = L["Fixed Positioning"],
        Description = L["Auras have a fixed placement and leave blank spaces in between."],
        Type = OptionType.CheckBox,
        Set = function(value)
            PS().SpecialClassDisplay.fixedPositions = value;
        end,
        Get = function()
            return PS().SpecialClassDisplay.fixedPositions;
        end,
    });
    tinsert(classDisplayCategoryConfigureAuras.Options, {
        Name = L["Aura Selector"],
        Type = OptionType.NotYetImplemented,
        Set = function(value)
        end,
        Get = function()
        end,
    });
    
    tinsert(unitFrameOptions, CreateAuraGroupOptions("Defensives", function() return PS().DefensiveBuff; end));
    tinsert(unitFrameOptions, CreateAuraGroupOptionsWithBlizzardFilter("Boss Auras", function() return PS().BossAuras; end));
    tinsert(unitFrameOptions, CreateAuraGroupOptionsWithBlizzardFilter("Undispellable Debuffs", function() return PS().OtherDebuffs; end));
    tinsert(unitFrameOptions, CreateAuraGroupOptionsWithBlizzardFilter("Dispellable Debuffs", function() return PS().DispellableDebuffs; end));
    tinsert(unitFrameOptions, CreateAuraGroupOptionsWithBlizzardFilter("Buffs", function() return PS().Buffs; end));

    for i=1, #unitFrameOptions do
        tinsert(targetSections, unitFrameOptions[i]);
    end
end

local _general = {
    Name = L["General"],
    Type = Settings.CategoryType.Options,
    GetProfile = P,
    Sections = {},
};
local generalGeneral = CreateSection(L["General"]);
tinsert(_general.Sections, generalGeneral);
tinsert(generalGeneral.Options, {
    Name = L["Disable Raid Settings Drawer"],
    Description = L["The thingy on the left of the screen which has the options for the default raid frames.\nThis will only work when both, default party and -raid frames are hidden."],
    Type = OptionType.CheckBox,
    Set = function(value)
        P().DisableCompactUnitFrameManager = value;
    end,
    Get = function()
        return P().DisableCompactUnitFrameManager;
    end,
});
tinsert(generalGeneral.Options, {
    Name = L["Disable Minimap Icon"],
    Description = L["You can still open the options with /macframes.\nThis setting is saved across profiles."],
    Type = OptionType.CheckBox,
    Set = function(value)
        ProfileManager.GetMinimapSettings().hide = value;
        if (value) then
            Addon.LibMinimapIcon:Hide(Constants.MinimapIconRegisterName);
        else
            Addon.LibMinimapIcon:Show(Constants.MinimapIconRegisterName);
        end
    end,
    Get = function()
        return ProfileManager.GetMinimapSettings().hide;
    end,
});
tinsert(Settings.Categories, _general);

local _raidFrames = {
    Name = L["Raidframes"],
    Type = Settings.CategoryType.Options,
    GetProfile = P,
    Sections = {},
};
AddUnitFrameOptions(_raidFrames.Sections, function() return P().RaidFrame; end, false);
tinsert(Settings.Categories, _raidFrames);

local _partyFrames = {
    Name = L["Partyframes"],
    Type = Settings.CategoryType.Options,
    GetProfile = P,
    Sections = {},
};
AddUnitFrameOptions(_partyFrames.Sections, function() return P().PartyFrame; end, true);
tinsert(_partyFrames.Sections[_ufFrameLayoutIndex].Options, {
    Name = L["Always Show Player"],
    Description = L["Shows the player frame if you're not in a group at all."],
    Type = OptionType.CheckBox,
    Set = function(value)
        P().PartyFrame.AlwaysShowPlayer = value;
    end,
    Get = function()
        return P().PartyFrame.AlwaysShowPlayer;
    end,
});
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

tinsert(_partyFrames.Sections[_ufFrameLayoutIndex].Sections[1].Options, {
    Name = L["Alignment"],
    Type = OptionType.EnumDropDown,
    EnumValues = MacEnum.Settings.PetFramePartyAlignment,
    Set = function(value)
        P().PartyFrame.PetFrames.AlignWithPlayer = value;
    end,
    Get = function()
        return P().PartyFrame.PetFrames.AlignWithPlayer;
    end,
});
tinsert(Settings.Categories, _partyFrames);

tinsert(Settings.Categories, {
    Name = L["Mouse Actions"],
    Type = Settings.CategoryType.MouseActions,
    GetProfile = P,
});

tinsert(Settings.Categories, {
    Name = L["Aura Blacklist"],
    Type = Settings.CategoryType.AuraBlacklist,
    GetProfile = P,
});

tinsert(Settings.Categories, {
    Name = L["Profiles"],
    Type = Settings.CategoryType.Profile,
    GetProfile = P,
});