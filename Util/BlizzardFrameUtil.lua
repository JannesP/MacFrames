local ADDON_NAME, _p = ...;

_p.BlizzardFrameUtil = {};
local BlizzardFrameUtil = _p.BlizzardFrameUtil;

--most concepts here are stolen from ShadowedUnitFrames :)
--https://github.com/Nevcairiel/ShadowedUnitFrames/blob/e779c8ed85e9b605b4416ed01277b722f2274869/ShadowedUnitFrames.lua#L646

local HiddenFrame = CreateFrame("Frame");
HiddenFrame:Hide();
local function Noop() end
local function HideFrame(self)
	if(not InCombatLockdown()) then
		self:Hide()
	end
end

local _partyHidden = false;
local _cufHidden = false;
local _cufManagerHidden = false;
local _shouldHideCufManager = false;

local function DisableFrames(taint, ...)
    for i=1, select("#", ...) do
		local frame = select(i, ...);
		UnregisterUnitWatch(frame);
		frame:UnregisterAllEvents();
		frame:Hide();

		if(frame.manabar) then frame.manabar:UnregisterAllEvents() end
		if(frame.healthbar) then frame.healthbar:UnregisterAllEvents() end
		if(frame.spellbar) then frame.spellbar:UnregisterAllEvents() end
		if(frame.powerBarAlt) then frame.powerBarAlt:UnregisterAllEvents() end

		if(taint) then
			frame.Show = Noop;
		else
			frame:SetParent(HiddenFrame)
			frame:HookScript("OnShow", HideFrame)
		end
	end
end

function BlizzardFrameUtil.DisablePartyFrames()
    if (not InCombatLockdown()) then
        if (_partyHidden == true) then return; end;
        _partyHidden = true;
        PartyFrame:UnregisterAllEvents();
        PartyFrame.PartyMemberFramePool:ReleaseAll();
        PartyFrame:Hide();
        if (_shouldHideCufManager == true) then BlizzardFrameUtil.DisableCompactUnitFrameManager(); end;
    end
end

do
    local function DisableRaidManagerButton(button)
        button:SetEnabled(false);
        button.selectedHighlight:Hide();
    end
    local function HideRaidFrames()
        CompactRaidFrameContainer:UnregisterAllEvents();
        
        if(not InCombatLockdown()) then
            CompactRaidFrameContainer:Hide();
            local shown = CompactRaidFrameManager_GetSetting("IsShown")
            if(shown and shown ~= "0") then
                CompactRaidFrameManager_SetSetting("ShowBorders", "0");
                CompactRaidFrameManager_SetSetting("IsShown", "0");
            end
        end
        
        for i=1, 8 do
            DisableRaidManagerButton(_G["CompactRaidFrameManagerDisplayFrameFilterOptionsFilterGroup" .. i]);
        end
        DisableRaidManagerButton(CompactRaidFrameManagerDisplayFrameFilterOptionsFilterRoleTank);
        DisableRaidManagerButton(CompactRaidFrameManagerDisplayFrameFilterOptionsFilterRoleHealer);
        DisableRaidManagerButton(CompactRaidFrameManagerDisplayFrameFilterOptionsFilterRoleDamager);
        CompactRaidFrameManagerDisplayFrameHiddenModeToggle:SetEnabled(false);
    end

    function BlizzardFrameUtil.DisableCompactUnitFrames()
        if (not InCombatLockdown()) then
            if (_cufHidden == true) then return; end;
            _cufHidden = true;
            -- This stops the compact party frame from being shown
            UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE");
            if(CompactPartyFrame) then
                DisableFrames(false, CompactPartyFrame)
            end
            
            CompactRaidFrameContainer:HookScript("OnShow", HideRaidFrames);
            hooksecurefunc("CompactRaidFrameManager_UpdateRoleFilterButton", DisableRaidManagerButton);
            hooksecurefunc("CompactRaidFrameManager_UpdateGroupFilterButton", DisableRaidManagerButton);
            HideRaidFrames();
            if (_shouldHideCufManager == true) then BlizzardFrameUtil.DisableCompactUnitFrameManager(); end;
        end
    end

    function BlizzardFrameUtil.DisableCompactUnitFrameManager()
        if (not InCombatLockdown()) then
            if (_cufManagerHidden == true) then return; end;
            if (_cufHidden == false or _partyHidden == false) then _shouldHideCufManager = true; return; end;
            _cufManagerHidden = true;
            
            CompactRaidFrameManager:UnregisterAllEvents();
            CompactRaidFrameManager:HookScript("OnShow", HideRaidFrames);
            hooksecurefunc("CompactRaidFrameManager_UpdateShown", function()
                CompactRaidFrameManager:Hide();
            end);
            CompactRaidFrameManager:Hide();
        end
    end
end
