local ADDON_NAME, _p = ...;
local LSM = LibStub("LibSharedMedia-3.0");

local Settings = _p.Settings;
local Resources = _p.Resources;
local PlayerInfo = _p.PlayerInfo;
local SettingsUtil = _p.SettingsUtil;
local MyAuraUtil = _p.MyAuraUtil;
local AuraFrame = _p.AuraFrame;
local AuraGroup = _p.AuraGroup;
local AuraManager = _p.AuraManager;

local _padding = Settings.Frames.Padding;
local _classColorsByIndex = {};
for key, value in pairs(RAID_CLASS_COLORS) do
    tinsert(_classColorsByIndex, value);
end

local _unitFrames = {};
_p.UnitFrames = _unitFrames;

local UnitFrame = {};
_p.UnitFrame = UnitFrame;
UnitFrame.new = function(unit, parent, namePrefix)
    if (namePrefix == nil) then
        namePrefix = parent:GetName();
        if (namePrefix == nil) then
            error("A prefix for the unit frames is required.");
        end
    end
    local frameName = namePrefix .. "_" .. unit;
    local frame = _unitFrames[frameName];
    if (frame == nil) then
        frame = CreateFrame("Button", frameName, parent, "MacFramesUnitFrameTemplate");
        frame.statusIconsFrame = CreateFrame("Frame", nil, frame);
        _unitFrames[frameName] = frame;
    end
    UnitFrame.Setup(frame);
    UnitFrame.SetUnit(frame, unit);
    return frame;
end

function UnitFrame.Setup(self)
    self:SetAlpha(1);
    self.background:SetTexture(Resources.SB_HEALTH_BACKGROUND);

    local healthBarTexturePath = LSM:Fetch("statusbar", Settings.Frames.HealthBarTextureName);
    self.healthBar:SetStatusBarTexture(healthBarTexturePath, "BORDER");
    PixelUtil.SetPoint(self.healthBar, "TOPLEFT", self, "TOPLEFT", 1, -1);
    PixelUtil.SetPoint(self.healthBar, "BOTTOMRIGHT", self, "BOTTOMRIGHT", -1, 1);
    local healthBarTexture = self.healthBar:GetStatusBarTexture();
    self.healthBar.texture = healthBarTexture;

    self.healthBar.overlay:ClearAllPoints();
    self.healthBar.overlay:SetPoint("TOPLEFT", healthBarTexture, "TOPLEFT", 0, 0);
    self.healthBar.overlay:SetPoint("BOTTOMRIGHT", healthBarTexture, "BOTTOMRIGHT", 0, 0);
    self.healthBar.overlay:SetColorTexture(1, 1, 0, 1);
    self.healthBar.overlay:SetBlendMode("BLEND");

    self.healAbsorb:ClearAllPoints();
    self.healAbsorb:SetBlendMode("BLEND");
    self.healAbsorb:SetColorTexture(1, 0, 0, 1);
    self.healAbsorb:SetVertexColor(0.2, 0, 0, 0.7);
    PixelUtil.SetPoint(self.healAbsorb, "TOPRIGHT", healthBarTexture, "TOPRIGHT", 0, 0);
    PixelUtil.SetPoint(self.healAbsorb, "BOTTOMRIGHT", healthBarTexture, "BOTTOMRIGHT", 0, 0);

    self.totalAbsorb:ClearAllPoints();
    self.totalAbsorb:SetTexture(healthBarTexturePath);
    self.totalAbsorb:SetVertexColor(0.6, 0.9, 1, 1);
    PixelUtil.SetPoint(self.totalAbsorb, "TOPLEFT", healthBarTexture, "TOPLEFT", 0, 0);
    PixelUtil.SetPoint(self.totalAbsorb, "BOTTOMLEFT", healthBarTexture, "BOTTOMLEFT", 0, 0);

    self.healPrediction:ClearAllPoints();
    self.healPrediction:SetTexture(healthBarTexturePath);
    self.healPrediction:SetVertexColor(0, 0.55, 0.1, 0.5);
    PixelUtil.SetPoint(self.healPrediction, "TOPLEFT", healthBarTexture, "TOPLEFT", 0, 0);
    PixelUtil.SetPoint(self.healPrediction, "BOTTOMLEFT", healthBarTexture, "BOTTOMLEFT", 0, 0);

    self.targetHighlight:SetTexture(LSM:Fetch("border", Settings.Frames.BorderTargetName));
    self.targetHighlight:SetAllPoints();
    self.targetHighlight:Hide();

    self.aggroHighlight:SetTexture(LSM:Fetch("border", Settings.Frames.BorderAggroName));
    self.aggroHighlight:SetAllPoints();
    self.aggroHighlight:Hide();

    self.roleIcon:ClearAllPoints();
    PixelUtil.SetSize(self.roleIcon, 1, Settings.Frames.RoleIconSize);
    PixelUtil.SetPoint(self.roleIcon, "TOPLEFT", self, "TOPLEFT", 3, -3);

    local nameFontName, nameFontSize, nameFontFlags = self.name:GetFont();
    PixelUtil.SetPoint(self.name, "TOPLEFT", self.roleIcon, "TOPRIGHT", 2, 0);
    PixelUtil.SetPoint(self.name, "BOTTOMLEFT", self.roleIcon, "BOTTOMRIGHT", 2, 0);
    self.name:SetJustifyH("LEFT");
    
    local sic = self.statusIconContainer;
    sic.statusText.defaultHeight = select(2, sic.statusText:GetFont());
    PixelUtil.SetHeight(sic, Settings.Frames.StatusIconSize + sic.statusText.defaultHeight);
    PixelUtil.SetWidth(sic, self:GetWidth());
    PixelUtil.SetPoint(sic, "CENTER", self, "CENTER", 0, -(nameFontSize / 2))
    
    PixelUtil.SetPoint(sic.statusText, "TOP", sic, "TOP", 0, 0);
    sic.statusText:SetJustifyH("CENTER");

    sic.readyCheckIcon:ClearAllPoints();
    sic.readyCheckIcon:SetTexture(READY_CHECK_WAITING_TEXTURE);
    sic.readyCheckIcon:Hide();

    sic.summonIcon:ClearAllPoints();
    sic.summonIcon:SetAtlas("Raid-Icon-SummonPending");
    sic.summonIcon:SetTexCoord(0, 1, 0, 1);
    sic.summonIcon:Hide();

    sic.resurrectIcon:ClearAllPoints();
    sic.resurrectIcon:SetTexture("Interface\\RaidFrame\\Raid-Icon-Rez");
    sic.resurrectIcon:Hide();

    sic.phasingIcon:ClearAllPoints();
    sic.phasingIcon:SetTexture("Interface\\TargetingFrame\\UI-PhasingIcon");
    sic.phasingIcon:SetTexCoord(0.15625, 0.84375, 0.15625, 0.84375);
    sic.phasingIcon:Hide();

    sic.lfgIcon:ClearAllPoints();
    sic.lfgIcon:SetTexture("Interface\\LFGFrame\\LFG-Eye");
    sic.lfgIcon:SetTexCoord(0.125, 0.25, 0.25, 0.5);
    sic.lfgIcon:Hide();

    UnitFrame.LayoutStatusIcons(self);
    UnitFrame.CreateAuraDisplays(self);

    UnitFrame.RegisterEvents(self);
end

function UnitFrame.SetTestMode(self, enabled)
    if (enabled == true) then
        UnregisterUnitWatch(self);
        self:SetScript("OnEvent", nil);
        self:SetScript("OnUpdate", nil);

        local health = math.random(1, 1000);
        local incomingHeal = math.random(0, 200);
        local absorb = math.random(0, 300);
        local healAbsorb = math.random(0, 100);

        self:Show();
        self.healthBar:SetMinMaxValues(0, 1000);
        self.healthBar:SetValue(health);
        UnitFrame.SetHealthBarExtraInfo(self, health, 1000, incomingHeal, absorb, healAbsorb);
        UnitFrame.SetHealth(self, health);
        local color =_classColorsByIndex[math.random(1, #_classColorsByIndex)];
        UnitFrame.SetHealthColor(self, color.r, color.g, color.b);
        local name = GetUnitName("player", Settings.Frames.DisplayServerNames);
        if (math.random(0, 1) == 0) then
            name = name .. "(*)";
        end
        self.name:SetText(name);
        UnitFrame.SetRoleIcon(self, "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES", GetTexCoordsForRoleSmallCircle("DAMAGER"));
        for _, auraGroup in ipairs(self.auraGroups) do
            AuraGroup.SetTestMode(auraGroup, enabled);
        end
        local testAura = { 
            [2] = 458720,
            [3] = 3,
            [4] = "Magic",
            [5] = 10000,
            [6] = GetTime() - 3500,
        };
        for _, frame in ipairs(self.specialClassDisplays) do
            AuraFrame.SetTestAura(frame, testAura);
        end
    else
        RegisterUnitWatch(self);
        self:SetScript("OnEvent", UnitFrame.OnEvent);
        self:SetScript("OnUpdate", UnitFrame.OnUpdate);

        UnitFrame.UpdateAll(self);
    end
end

function UnitFrame.LayoutStatusIcons(self)
    local sic = self.statusIconContainer;
    if (sic.disableLayouting == true) then --mostly for UpdateAll to prevent excessive recalculating
        return;
    end
    local visibleFrames = {};

    PixelUtil.SetHeight(sic, Settings.Frames.StatusIconSize + sic.statusText.defaultHeight);
    PixelUtil.SetWidth(sic, self:GetWidth());

    local function ProcessIcon(icon)
        if (icon:IsShown()) then
            tinsert(visibleFrames, icon);
        end
    end

    ProcessIcon(sic.readyCheckIcon);
    ProcessIcon(sic.summonIcon);
    ProcessIcon(sic.resurrectIcon);
    ProcessIcon(sic.phasingIcon);
    ProcessIcon(sic.lfgIcon);

    if (#visibleFrames == 0) then
        --no frames visible, we just move the status text in the middle
        sic.statusText:ClearAllPoints();
        PixelUtil.SetPoint(sic.statusText, "CENTER", sic, "CENTER", 0, 0);
    else
        local iconSize = Settings.Frames.StatusIconSize;
        local totalWidth = #visibleFrames * iconSize;
        PixelUtil.SetPoint(visibleFrames[1], "BOTTOMLEFT", sic, "BOTTOMLEFT", (sic:GetWidth() / 2) - (totalWidth / 2), 0);
        PixelUtil.SetSize(visibleFrames[1], iconSize, iconSize);
        for i=2,#visibleFrames do
            PixelUtil.SetPoint(visibleFrames[i], "TOPLEFT", visibleFrames[i - 1], "TOPRIGHT", 0, 0);
            PixelUtil.SetSize(visibleFrames[i], iconSize, iconSize);
        end
        --since we displayed an icon we need to move the statusText up
        sic.statusText:ClearAllPoints();
        PixelUtil.SetPoint(sic.statusText, "TOP", sic, "TOP", 0, 0);
    end
end

function UnitFrame.CreateAuraDisplays(self)
    --somewhat special aura frame
    UnitFrame.CreateSpecialClassDisplay(self);
    --continue with 'normal aura displays'
    if (self.auraGroups == nil) then
        self.auraGroups = {};
    else
        for _, group in ipairs(self.auraGroups) do
            AuraGroup.Recycle(group);
        end
        wipe(self.auraGroups);
    end
    local s = Settings.DefensiveBuff;
    local defensives = AuraGroup.new(self, self.unit, AuraGroup.Type.DefensiveBuff, s.iconCount, s.iconWidth, s.iconHeight, s.iconSpacing, s.iconZoom);
    AuraGroup.SetReverseOrder(defensives, true);
    defensives:Show();
    tinsert(self.auraGroups, defensives);

    s = Settings.BossAuras;
    local auraGroupBossAuras = AuraGroup.new(self, self.unit, AuraGroup.Type.BossAura, s.iconCount, s.iconWidth, s.iconHeight, s.iconSpacing, s.iconZoom);
    auraGroupBossAuras:Show();
    tinsert(self.auraGroups, auraGroupBossAuras);

    s = Settings.DispellableDebuffs;
    local auraGroupDispellable = AuraGroup.new(self, self.unit, AuraGroup.Type.DispellableDebuff, s.iconCount, s.iconWidth, s.iconHeight, s.iconSpacing, s.iconZoom);
    auraGroupDispellable:Show();
    tinsert(self.auraGroups, auraGroupDispellable);

    s = Settings.OtherDebuffs;
    local auraGroupUndispellable = AuraGroup.new(self, self.unit, AuraGroup.Type.UndispellableDebuff, s.iconCount, s.iconWidth, s.iconHeight, s.iconSpacing, s.iconZoom);
    auraGroupUndispellable:Show();
    tinsert(self.auraGroups, auraGroupUndispellable);
    
    PixelUtil.SetPoint(defensives, "BOTTOMRIGHT", self, "BOTTOMRIGHT", -_padding, _padding);
    PixelUtil.SetPoint(auraGroupBossAuras, "CENTER", self, "CENTER", 0, 0);
    PixelUtil.SetPoint(auraGroupUndispellable, "BOTTOMLEFT", self, "BOTTOMLEFT", _padding, _padding);
    PixelUtil.SetPoint(auraGroupDispellable, "BOTTOMLEFT", auraGroupUndispellable, "TOPLEFT", 0, 1);
end

function UnitFrame.SetAttribute(self, name, value)
    self:SetAttribute(name, value);
    if (not self.myAttributeList) then self.myAttributeList = {}; end
    self.myAttributeList[name] = value;
end

function UnitFrame.RemoveMyAttributes(self)
    if self.myAttributeList == nil then return; end
    for k, _ in pairs(self.myAttributeList) do
        UnitFrame.SetAttribute(self, k, nil);
    end
end

function UnitFrame.SetupCastBindings(self)
    local bindings = _p.CastBindings.GetBindingsForSpec();
    for i, v in ipairs(bindings) do
        local prefix = "";
        if (v.alt) then prefix = prefix .. "alt-"; end
        if (v.ctrl) then prefix = prefix .. "ctrl-"; end
        if (v.shift) then prefix = prefix .. "shift-" end

        local suffix = v.button;
        if (v.type == "spell") then
            UnitFrame.SetAttribute(self, prefix .. v.type .. suffix, v.value);
        elseif (v.type == "target") then
        elseif (v.type == "togglemenu") then
        end
        UnitFrame.SetAttribute(self, prefix .. "type" .. suffix, v.type);
    end
end

function UnitFrame.SetUnit(self, unit)
    if InCombatLockdown() then error("Cannot call this in combat. You need to delay triggered updates til combat ends.") end;
    UnitFrame.RemoveMyAttributes(self);
    self.statusIconContainer.readyCheckIcon.readyCheckStatus = nil;
    self.statusIconContainer.readyCheckIcon.readyCheckDecay = nil;
    self.displayUnit = unit;
    self.unit = unit;
    UnitFrame.SetAttribute(self, "unit", unit);
    UnitFrame.RegisterUnitEvents(self)
    UnitFrame.SetupCastBindings(self);
    for _, group in ipairs(self.auraGroups) do
        AuraGroup.SetUnit(group, unit);
    end
    RegisterUnitWatch(self);
    UnitFrame.UpdateAll(self);
end

function UnitFrame.RegisterEvents(self)
    self:SetScript("OnEvent", UnitFrame.OnEvent);
    self:SetScript("OnUpdate", UnitFrame.OnUpdate);

    self:RegisterForClicks("AnyDown");
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("GROUP_ROSTER_UPDATE");
    self:RegisterEvent("PLAYER_ROLES_ASSIGNED");
    self:RegisterEvent("PLAYER_TARGET_CHANGED");
    self:RegisterEvent("READY_CHECK");
	self:RegisterEvent("READY_CHECK_FINISHED");
end

function UnitFrame.RegisterUnitEvents(self)
    local unit = self.unit;
	local displayUnit;
	if ( unit ~= self.displayUnit ) then
		displayUnit = self.displayUnit;
    end
    self:RegisterUnitEvent("UNIT_HEALTH", unit, displayUnit);
    --TODO: remove when prepatch hits
    if (not _p.isRunningShadowlands) then --if it's not shadowlands yet
        self:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", unit, displayUnit);
    end
    self:RegisterUnitEvent("UNIT_FLAGS", unit, displayUnit);
    self:RegisterUnitEvent("UNIT_PHASE", unit, displayUnit);
    self:RegisterUnitEvent("UNIT_MAXHEALTH", unit, displayUnit);
    self:RegisterUnitEvent("UNIT_NAME_UPDATE", unit, displayUnit);
    self:RegisterUnitEvent("UNIT_CONNECTION", unit, displayUnit);
    self:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", unit, displayUnit);
    self:RegisterUnitEvent("UNIT_HEAL_PREDICTION", unit, displayUnit);
    self:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", unit, displayUnit);
    self:RegisterUnitEvent("UNIT_AURA", unit, displayUnit);
    self:RegisterUnitEvent("PLAYER_FLAGS_CHANGED", unit, displayUnit);
    self:RegisterUnitEvent("UNIT_THREAT_SITUATION_UPDATE", unit, displayUnit);
    self:RegisterUnitEvent("INCOMING_RESURRECT_CHANGED", unit, displayUnit);
    self:RegisterUnitEvent("READY_CHECK_CONFIRM", unit, displayUnit);
    self:RegisterUnitEvent("INCOMING_SUMMON_CHANGED", unit, displayUnit);
end

function UnitFrame.OnEvent(self, event, ...)
    local arg1, arg2, arg3, arg4 = ...;
    if (event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE") then
        UnitFrame.UpdateAll(self);
    elseif (event == "PLAYER_TARGET_CHANGED") then
        UnitFrame.UpdateMaxHealth(self);
        UnitFrame.UpdateHealth(self);
        UnitFrame.UpdateHealthColor(self);
        UnitFrame.UpdateHealthBarExtraInfo(self);
        UnitFrame.UpdateName(self);
        UnitFrame.UpdateTargetHighlight(self);
    elseif (event == "PLAYER_ROLES_ASSIGNED") then
        UnitFrame.UpdateRoleIcon(self);
    elseif (event == "READY_CHECK") then
        UnitFrame.UpdateReadyCheckStatus(self);
    elseif (event == "READY_CHECK_FINISHED") then
        UnitFrame.FinishReadyCheck(self);
    else
        local eventUnit = arg1;
        if (eventUnit == self.unit or eventUnit == self.displayUnit) then
            if (event == "UNIT_HEALTH") then
                UnitFrame.UpdateHealth(self);
                UnitFrame.UpdateStatusText(self);
                UnitFrame.UpdateHealthBarExtraInfo(self)
            elseif (event == "UNIT_MAXHEALTH") then
                UnitFrame.UpdateMaxHealth(self);
                UnitFrame.UpdateHealth(self);
                UnitFrame.UpdateHealthBarExtraInfo(self);
            elseif (event == "UNIT_ABSORB_AMOUNT_CHANGED" or event == "UNIT_HEAL_PREDICTION" or event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED") then
                UnitFrame.UpdateHealthBarExtraInfo(self);
            elseif (event == "UNIT_NAME_UPDATE") then
                UnitFrame.UpdateName(self);
                UnitFrame.UpdateHealthColor(self);
            elseif (event == "UNIT_CONNECTION") then
                UnitFrame.UpdateStatusText(self);
                UnitFrame.UpdateHealthColor(self);
            elseif (event == "UNIT_AURA") then
                UnitFrame.UpdateAuras(self);
            elseif (event == "PLAYER_FLAGS_CHANGED") then
                UnitFrame.UpdateStatusText(self);
            elseif (event == "UNIT_PHASE" or event == "UNIT_FLAGS") then
                self.statusIconContainer.disableLayouting = true;
                UnitFrame.UpdatePhasingStatus(self);
                UnitFrame.UpdateLFGStatus(self);
                self.statusIconContainer.disableLayouting = false;
                UnitFrame.LayoutStatusIcons(self);
            elseif (event == "UNIT_THREAT_SITUATION_UPDATE") then
                UnitFrame.UpdateAggroHighlight(self);
            elseif (event == "INCOMING_RESURRECT_CHANGED") then
                UnitFrame.UpdateRezStatus(self);
            elseif (event == "INCOMING_SUMMON_CHANGED") then
                UnitFrame.UpdateSummonStatus(self);
            elseif (event == "READY_CHECK_CONFIRM") then
                UnitFrame.UpdateReadyCheckStatus(self);
            end
        end
    end
end

function UnitFrame.UpdateAll(self)
    if (UnitExists(self.displayUnit)) then
        UnitFrame.UpdateName(self);
        UnitFrame.UpdateStatusText(self);
        UnitFrame.UpdateHealthColor(self);
        UnitFrame.UpdateMaxHealth(self);
        UnitFrame.UpdateHealth(self);
        UnitFrame.UpdateHealthBarExtraInfo(self);
        UnitFrame.UpdateInRange(self);
        UnitFrame.UpdateRoleIcon(self);
        UnitFrame.UpdateTargetHighlight(self);
        UnitFrame.UpdateAggroHighlight(self);
        UnitFrame.UpdateAuras(self);

        self.statusIconContainer.disableLayouting = true;
        UnitFrame.UpdateSummonStatus(self);
        UnitFrame.UpdateLFGStatus(self);
        UnitFrame.UpdatePhasingStatus(self);
        UnitFrame.UpdateReadyCheckStatus(self);
        UnitFrame.UpdateRezStatus(self);
        self.statusIconContainer.disableLayouting = false;
        UnitFrame.LayoutStatusIcons(self);
    end
end

function UnitFrame.UpdateDistance(self)
	local distance, checkedDistance = UnitDistanceSquared(frame.displayUnit);

	if (checkedDistance == true) then
		local inDistance = distance < DISTANCE_THRESHOLD_SQUARED;
		if (inDistance ~= self.inDistance) then
			self.inDistance = inDistance;
            UnitFrame.UpdateLFGStatus(self);
            UnitFrame.UpdatePhasingStatus(self);
		end
	end
end

function UnitFrame.UpdateSummonStatus(self)
    local icon = self.statusIconContainer.summonIcon;
    if C_IncomingSummon.HasIncomingSummon(self.unit) then
        local status = C_IncomingSummon.IncomingSummonStatus(self.unit);
        if(status == Enum.SummonStatus.Pending) then
            icon:SetAtlas("Raid-Icon-SummonPending");
        elseif( status == Enum.SummonStatus.Accepted ) then
            icon:SetAtlas("Raid-Icon-SummonAccepted");
        elseif( status == Enum.SummonStatus.Declined ) then
            icon:SetAtlas("Raid-Icon-SummonDeclined");
        end
        icon:Show();
    else
        icon:Hide();
    end
end

function UnitFrame.UpdateLFGStatus(self)
    local icon = self.statusIconContainer.lfgIcon;
    if UnitInOtherParty(self.unit) then
        if (not icon:IsVisible()) then
            icon:Show();
            UnitFrame.LayoutStatusIcons(self);
        end
    else
        if (icon:IsVisible()) then
            icon:Hide();
            UnitFrame.LayoutStatusIcons(self);
        end
    end
end

function UnitFrame.UpdatePhasingStatus(self)
    local icon = self.statusIconContainer.phasingIcon;
    if self.inDistance and UnitPhaseReason(self.unit) then
        if (not icon:IsVisible()) then
            icon:Show();
            UnitFrame.LayoutStatusIcons(self);
        end
    else
        if (icon:IsVisible()) then
            icon:Hide();
            UnitFrame.LayoutStatusIcons(self);
        end
    end
end

function UnitFrame.UpdateRezStatus(self)
    local icon = self.statusIconContainer.resurrectIcon;
    if UnitHasIncomingResurrection(self.unit) then
        if (not icon:IsVisible()) then
            icon:Show();
            UnitFrame.LayoutStatusIcons(self);
        end
    else
        if (icon:IsVisible()) then
            icon:Hide();
            UnitFrame.LayoutStatusIcons(self);
        end
    end
end

function UnitFrame.UpdateReadyCheckStatus(self)
    local icon = self.statusIconContainer.readyCheckIcon;
    if icon.readyCheckDecay and GetReadyCheckTimeLeft() <= 0 then
        return;
    end
    local readyCheckStatus = GetReadyCheckStatus(self.unit);
    icon.readyCheckStatus = readyCheckStatus;
    local show = false;
    if (readyCheckStatus == "ready") then
		icon:SetTexture(READY_CHECK_READY_TEXTURE);
		show = true;
	elseif (readyCheckStatus == "notready") then
		icon:SetTexture(READY_CHECK_NOT_READY_TEXTURE);
		show = true;
	elseif (readyCheckStatus == "waiting") then
		icon:SetTexture(READY_CHECK_WAITING_TEXTURE);
		show = true;
    end
    if (show) then
        if (not icon:IsVisible()) then
            icon:Show();
            UnitFrame.LayoutStatusIcons(self);
        end
    else
        if (icon:IsVisible()) then
            icon:Hide();
            UnitFrame.LayoutStatusIcons(self);
        end
    end
end

function UnitFrame.FinishReadyCheck(self)
    if (self:IsVisible()) then
        local icon = self.statusIconContainer.readyCheckIcon;
		icon.readyCheckDecay = CUF_READY_CHECK_DECAY_TIME;

		if (icon.readyCheckStatus == "waiting") then	--If you haven't responded, you are not ready.
            icon:SetTexture(READY_CHECK_NOT_READY_TEXTURE);
            if (not icon:IsVisible()) then
                icon:Show();
                UnitFrame.LayoutStatusIcons(self);
            end
		end
	else
		UnitFrame.UpdateReadyCheckStatus(self);
	end
end

function UnitFrame.CheckReadyCheckDecay(self, elapsed)
    local icon = self.statusIconContainer.readyCheckIcon;
	if (icon.readyCheckDecay) then
		if (icon.readyCheckDecay > 0) then
			icon.readyCheckDecay = icon.readyCheckDecay - elapsed;
		else
			icon.readyCheckDecay = nil;
			UnitFrame.UpdateReadyCheckStatus(self);
		end
	end
end

function UnitFrame.UpdateAggroHighlight(self)
    local status = UnitThreatSituation(self.displayUnit);
	if (status and status > 0) then
		self.aggroHighlight:SetVertexColor(GetThreatStatusColor(status));
		self.aggroHighlight:Show();
	else
		self.aggroHighlight:Hide();
	end
end

function UnitFrame.UpdateTargetHighlight(self)
    if (UnitIsUnit(self.unit, "target")) then
        self.targetHighlight:Show();
    else
        self.targetHighlight:Hide();
    end
end

function UnitFrame.UpdateRoleIcon(self)
    
    local raidID = UnitInRaid(self.unit);
    if (UnitInVehicle(self.unit) and UnitHasVehicleUI(self.unit)) then
        UnitFrame.SetRoleIcon(self, "Interface\\Vehicles\\UI-Vehicles-Raid-Icon", 0, 1, 0, 1);
	elseif (raidID and select(10, GetRaidRosterInfo(raidID))) then
		local role = select(10, GetRaidRosterInfo(raidID));
        UnitFrame.SetRoleIcon(self, "Interface\\GroupFrame\\UI-Group-"..role.."Icon", 0, 1, 0, 1);
	else
		local role = UnitGroupRolesAssigned(self.unit);
		if (role == "TANK" or role == "HEALER" or role == "DAMAGER") then
            UnitFrame.SetRoleIcon(self, "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES", GetTexCoordsForRoleSmallCircle(role));
		else
			self.roleIcon:Hide();
			PixelUtil.SetSize(self.roleIcon, 1, Settings.Frames.RoleIconSize);
		end
	end
end

function UnitFrame.SetRoleIcon(self, texture, ...)
    local roleIconSize = Settings.Frames.RoleIconSize;
    self.roleIcon:SetTexture(texture);
    self.roleIcon:SetTexCoord(...);
    self.roleIcon:Show();
    PixelUtil.SetSize(self.roleIcon, roleIconSize, roleIconSize);
end

function UnitFrame.UpdateStatusText(self)
    local text = self.statusIconContainer.statusText;
    if not UnitIsConnected(self.unit) then
        text:SetText("Offline");
        text:Show();
    elseif UnitIsDeadOrGhost(self.unit) then
        text:SetText("Dead");
        text:Show();
    elseif not InCombatLockdown() and UnitIsAFK(self.unit) then
        text:SetText("AFK");
        text:Show();
    elseif not InCombatLockdown() and UnitIsDND(self.unit) then
        text:SetText("DND");
        text:Show();
    else
        text:Hide();
    end
end

local function ProjectNumberRange(value, oldMin, oldMax, newMin, newMax)
   return (((value - oldMin) * (newMax - newMin)) / (oldMax - oldMin)) + newMin; 
end

function UnitFrame.UpdateHealth(self)
    if (UnitIsDeadOrGhost(self.displayUnit)) then 
        --otherwise looks weird when somebody is a ghost
        self.healthBar:SetValue(0);
    else
        UnitFrame.SetHealth(self, UnitHealth(self.displayUnit));
    end
end

function UnitFrame.SetHealth(self, health)
    local hb = self.healthBar;
    hb:SetValue(health);
    if (Settings.Frames.BlendToDangerColors) then
        local blendRatio = Settings.Frames.BlendToDangerColorsRatio;
        local blendMinimum = Settings.Frames.BlendToDangerColorsMinimum;
        local blendMaximum = Settings.Frames.BlendToDangerColorsMaximum;
        local _, maxValue = hb:GetMinMaxValues();
        if (maxValue == 0) then
            hb.texture:SetAlpha(1);
            hb.overlay:SetAlpha(0);
            return;
        end
        local ratio = hb:GetValue() / maxValue;
        if (ratio >= blendMaximum) then
            hb.texture:SetAlpha(1);
            hb.overlay:SetAlpha(0);
        elseif (ratio >= blendRatio) then
            local lratio = ProjectNumberRange(ratio, blendRatio, blendMaximum, 0, 1);
            hb.texture:SetAlpha(lratio);
            hb.overlay:SetVertexColor(1, 1, 0, 1 - lratio);
        elseif (ratio <= blendMinimum) then
            hb.texture:SetAlpha(0);
            hb.overlay:SetVertexColor(1, 0, 0, 1);
        elseif (ratio < blendRatio) then
            local lratio = ProjectNumberRange(ratio, blendMinimum, blendRatio, 0, 1);
            hb.overlay:SetVertexColor(1, lratio, 0, 1);
            hb.texture:SetAlpha(0);
        end
        
        hb.overlay:Show();
    else
        hb.overlay:Hide();
    end
end

function UnitFrame.UpdateMaxHealth(self)
    local maxHealth = UnitHealthMax(self.displayUnit);
    self.healthBar:SetMinMaxValues(0, maxHealth);
end

function UnitFrame.UpdateHealthBarExtraInfo(self)
    local _, maxHealth = self.healthBar:GetMinMaxValues();
    if (maxHealth <= 0) then
		return;
	end
    local currentHealth = max(0, self.healthBar:GetValue());
    if (currentHealth == 0) then
        self.healPrediction:Hide();
        self.totalAbsorb:Hide();
        self.healAbsorb:Hide();
    else
        local incomingHeal = UnitGetIncomingHeals(self.displayUnit) or 0;
        if (incomingHeal == nil) then incomingHeal = 0; end --can happen during a duel, unit is in party but not friendly
        local absorb = UnitGetTotalAbsorbs(self.displayUnit) or 0;
        local healAbsorb = UnitGetTotalHealAbsorbs(self.displayUnit) or 0;
        UnitFrame.SetHealthBarExtraInfo(self, currentHealth, maxHealth, incomingHeal, absorb, healAbsorb);
    end
end

function UnitFrame.SetHealthBarExtraInfo(self, currentHealth, maxHealth, incomingHeal, absorb, healAbsorb)
    local totalWidth = self.healthBar:GetWidth();
    if (currentHealth == maxHealth) then
        self.totalAbsorb:Hide();
        self.healPrediction:Hide();
    else
        local remainingEmptyHealth = maxHealth - currentHealth;
        remainingEmptyHealth, nextAnchorFrame, overAmount = UnitFrame.ProcessHealthBarExtraInfoBar(self.healPrediction, incomingHeal, self.healthBar:GetStatusBarTexture(), remainingEmptyHealth, maxHealth, totalWidth);
        if (overAmount > 0) then
            --overcapped heal prediction
        end
        remainingEmptyHealth, nextAnchorFrame, overAmount = UnitFrame.ProcessHealthBarExtraInfoBar(self.totalAbsorb, absorb, nextAnchorFrame, remainingEmptyHealth, maxHealth, totalWidth);
        if (overAmount > 0) then
            --overcapped absorbs
        end
    end
    if (healAbsorb == 0) then
        self.healAbsorb:Hide();
    else
        if (healAbsorb > currentHealth) then
            healAbsorb = currentHealth;
        end
        local healAbsorbWidth = (healAbsorb / maxHealth) * totalWidth;
        PixelUtil.SetWidth(self.healAbsorb, healAbsorbWidth);
        self.healAbsorb:Show();
    end
end

function UnitFrame.ProcessHealthBarExtraInfoBar(texture, amount, previousFrame, remainingEmptyHealth, maxLife, barWidth)
    local overAmount = 0;
    if (amount == 0 or remainingEmptyHealth == 0) then
        texture:Hide();
        return remainingEmptyHealth, previousFrame, amount;
    elseif (amount > remainingEmptyHealth) then
        overAmount = amount - remainingEmptyHealth;
        amount = remainingEmptyHealth;
        remainingEmptyHealth = 0;
    else
        remainingEmptyHealth = remainingEmptyHealth - amount;
    end
    
    local width = (amount / maxLife) * barWidth;
    texture:SetPoint("TOPLEFT", previousFrame, "TOPRIGHT", 0, 0);
    texture:SetPoint("BOTTOMLEFT", previousFrame, "BOTTOMRIGHT", 0, 0);
    texture:SetWidth(width);
    texture:Show();
    return remainingEmptyHealth, texture, overAmount;
end

function UnitFrame.UpdateName(self)
    local name = GetUnitName(self.displayUnit, Settings.Frames.DisplayServerNames);
    self.name:SetText(name);
end

function UnitFrame.IsTapDenied(self)
	return not UnitPlayerControlled(self.unit) and UnitIsTapDenied(self.unit);
end

function UnitFrame.UpdateHealthColor(self)
	local r, g, b;
	if (not UnitIsConnected(self.unit) ) then
		--Color it gray
		r, g, b = 0.5, 0.5, 0.5;
	else
        --Try to color it by class.
        local _, englishClass = UnitClass(self.unit);
        local classColor = RAID_CLASS_COLORS[englishClass];
        if ((UnitIsPlayer(self.unit) or UnitTreatAsPlayerForDisplay(self.unit)) and classColor) then
            -- Use class colors for players if class color option is turned on
            r, g, b = classColor.r, classColor.g, classColor.b;
        elseif (UnitFrame.IsTapDenied(self)) then
            -- Use grey if not a player and can't get tap on unit
            r, g, b = 0.9, 0.9, 0.9;
        elseif (not UnitIsPlayer(self.unit) and UnitIsFriend("player", self.unit)) then
            r, g, b = UnitSelectionColor(self.unit, true);
        else
            r, g, b = 1.0, 0.0, 0.0;
        end
    end
    UnitFrame.SetHealthColor(self, r, g, b);
end

function UnitFrame.SetHealthColor(self, r, g, b)
    if (r ~= self.healthBar.r or g ~= self.healthBar.g or b ~= self.healthBar.b) then
		self.healthBar:SetStatusBarColor(r, g, b);
		self.healthBar.r, self.healthBar.g, self.healthBar.b = r, g, b;
	end
end

function UnitFrame.UpdateInRange(self)
    local time = GetTime();
    if (self.lastRangeCheckAt == nil or time - self.lastRangeCheckAt > Settings.Frames.RangeCheckThrottleSeconds) then
        self.lastRangeCheckAt = time;
        if (self.displayUnit == "player") then --UnitInRange always return false, false for the player
            self:SetAlpha(1);
        else
            local inRange, checkedRange = UnitInRange(self.displayUnit);
            if (checkedRange and not inRange) then
                self:SetAlpha(Settings.Frames.OutOfRangeAlpha);
            else
                self:SetAlpha(1);
            end
        end
    end
end

function UnitFrame.OnUpdate(self, elapsed)
    UnitFrame.UpdateInRange(self);
    UnitFrame.CheckReadyCheckDecay(self, elapsed);
end

function UnitFrame.UpdateAuras(self)
    AuraManager.LoadUnitAuras(self.displayUnit);
    UnitFrame.UpdateSpecialClassDisplay(self);
    for _, group in ipairs(self.auraGroups) do
        AuraGroup.Update(group);
    end
end

function UnitFrame.UpdateSpecialClassDisplay(self)
    if (self.specialClassDisplays == nil) then return; end
    for _, frame in ipairs(self.specialClassDisplays) do
        AuraFrame.UpdateFromPinnedAura(frame);
    end
end

function UnitFrame.CreateSpecialClassDisplay(self, requiredDisplays)
    if (requiredDisplays == nil) then
        requiredDisplays = SettingsUtil.GetSpecialClassDisplays();
    end

    if (self.specialClassDisplays == nil) then
        self.specialClassDisplays = {};
    else
        for _, frame in ipairs(self.specialClassDisplays) do
            AuraFrame.Recycle(frame);
        end
        wipe(self.specialClassDisplays);
    end

    if (requiredDisplays == nil) then return; end

    local lastFrame = nil;
    for spellId, details in pairs(requiredDisplays) do
        if (details.enabled == true) then
            local settings = Settings.SpecialClassDisplay;
            local newFrame = AuraFrame.new(self, settings.iconWidth, settings.iconHeight, settings.iconZoom);
            AuraFrame.SetColoringMode(newFrame, AuraFrame.ColoringMode.Custom, 0.25, 0.25, 0.25);
            AuraFrame.SetPinnedAuraWithId(newFrame, self.unit, details.spellId, details.debuff, details.onlyByPlayer);
            if (lastFrame == nil) then
                PixelUtil.SetPoint(newFrame, "TOPRIGHT", self, "TOPRIGHT", -_padding, -_padding);
            else
                PixelUtil.SetPoint(newFrame, "TOPRIGHT", lastFrame, "TOPLEFT", -1, 0);
            end
            tinsert(self.specialClassDisplays, newFrame);
            lastFrame = newFrame;
        end
    end
end

function UnitFrame.CreateSpecialClassDisplays()
    local requiredDisplays = SettingsUtil.GetSpecialClassDisplays();
    if (requiredDisplays == nil) then return end
    for name, frame in pairs(_unitFrames) do
        UnitFrame.CreateSpecialClassDisplay(frame, requiredDisplays);
    end
end

function UnitFrame.UpdateAllCastBindings()
    for name, frame in pairs(_unitFrames) do
        UnitFrame.SetupCastBindings(frame);
    end
end

function UnitFrame.PlayerInfoChanged()
    UnitFrame.CreateSpecialClassDisplays();
    UnitFrame.UpdateAllCastBindings();
end
