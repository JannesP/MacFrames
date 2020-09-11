local ADDON_NAME, _p = ...;
local Addon = _p.Addon;
local FrameUtil = _p.FrameUtil;
local ConfigurationFrameTab = _p.ConfigurationFrameTab;
local Constants = _p.Constants;

_p.ConfigurationFrame = {};
local ConfigurationFrame = _p.ConfigurationFrame;
local ConfigurationOptions = _p.ConfigurationOptions;

local _borderClearance = Constants.TooltipBorderClearance;
local _frameName = "MacFramesConfigurationFrame";
local _frame;
local _activeTab;

local function CreateTextButton(parent, nameSuffix, text, onClickHandler)
    local b = CreateFrame("Button", parent:GetName() .. "Button" .. nameSuffix, parent, "UIPanelButtonTemplate");
    b:SetText(text);
    b:SetWidth(b.Text:GetWidth() + 10);
    b:SetScript("OnClick", onClickHandler);
    return b;
end

local function CreateBottomBar(self)
    local frame = CreateFrame("Frame", _frameName .. "BottomBar", self, BackdropTemplateMixin and "BackdropTemplate");
    frame:SetBackdrop(BACKDROP_TOOLTIP_0_16);
    frame:ClearAllPoints();

    frame.children = {};
    tinsert(frame.children, CreateTextButton(frame, "TestRaid", "Toggle Test Mode: Raid", function () Addon.ToggleTestMode(Addon.TestMode.Raid); end));
    tinsert(frame.children, CreateTextButton(frame, "TestParty", "Toggle Test Mode: Party", function () Addon.ToggleTestMode(Addon.TestMode.Party); end));

    tinsert(frame.children, CreateTextButton(frame, "ToggleAnchors", "Toggle Anchors", function () Addon.ToggleAnchors(); end));
    return frame;
end

local function CreateTabSelector(parent)
    local frame = CreateFrame("Frame", nil, parent);
    
end

local function LayoutBottomBar(self)
    local bar = self.bottomBar;
    local lastFrame = bar.children[1];
    bar:SetHeight(lastFrame:GetHeight() + _borderClearance * 2);
    lastFrame:ClearAllPoints();
    lastFrame:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", _borderClearance, _borderClearance);
    for i=2, #bar.children do
        local curr = bar.children[i];
        curr:ClearAllPoints();
        curr:SetPoint("BOTTOMLEFT", lastFrame, "BOTTOMRIGHT", 0, 0);
        lastFrame = curr;
    end
    
end

local function CreateTabSelector(self)
    local frameName = _frameName .. "TabSelector";
    local frame = CreateFrame("Frame", frameName, self, BackdropTemplateMixin and "BackdropTemplate");
    frame:SetBackdrop(BACKDROP_TOOLTIP_0_16);
    self.tabs = {};
    local count = 1;
    local lastButton = nil;
    for _, category in ipairs(ConfigurationOptions.Categories) do
        local tab = ConfigurationFrameTab.Create(frame, category);
        local selectButton = CreateFrame("CheckButton", frameName .. "TabSelector" .. count, frame, "OptionsListButtonTemplate");
        self.tabs[selectButton] = tab;
        selectButton.highlight = selectButton:GetHighlightTexture();
        selectButton.highlight:SetVertexColor(.196, .388, .8);
        selectButton:SetText(category.Name);
        selectButton:ClearAllPoints();
        if (lastButton == nil) then
            selectButton:SetPoint("TOPLEFT", frame, "TOPLEFT", _borderClearance, -_borderClearance);
            selectButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -_borderClearance, -_borderClearance);
            ConfigurationFrame.SetActiveTab(self, selectButton);
        else
            selectButton:SetPoint("TOPLEFT", lastButton, "BOTTOMLEFT", 0, -1);
            selectButton:SetPoint("TOPRIGHT", lastButton, "BOTTOMRIGHT", 0, -1);
        end
        selectButton:SetScript("OnClick", function(thisTab) ConfigurationFrame.SetActiveTab(self, thisTab) end);
        lastButton = selectButton;
    end
    return frame;
end

function ConfigurationFrame.SetActiveTab(self, tabButton)
    if (_frame.tabHost.content ~= nil) then
        _frame.tabHost.content:Hide();
        _frame.tabHost.content:ClearAllPoints();
    end
    for button, _ in pairs(_frame.tabs) do
       button.highlight:SetVertexColor(.196, .388, .8);
       button:UnlockHighlight();
    end

    local tab = self.tabs[tabButton];
    _frame.tabHost.content = tab;
    tabButton.highlight:SetVertexColor(1, 1, 0);
    tabButton:LockHighlight()
    tab:SetPoint("TOPLEFT", _frame.tabHost, "TOPLEFT", _borderClearance, -_borderClearance);
    tab:SetPoint("BOTTOMRIGHT", _frame.tabHost, "BOTTOMRIGHT", -_borderClearance, _borderClearance);
    tab:Show();
    ConfigurationFrameTab.Layout(tab);
end

function ConfigurationFrame.Show(parent)
    if _frame == nil then
        _frame = CreateFrame("Frame", _frameName, parent, BackdropTemplateMixin and "BackdropTemplate");

        _frame.bottomBar = CreateBottomBar(_frame);
        _frame.bottomBar:SetPoint("BOTTOMLEFT", _frame, "BOTTOMLEFT", 0, 0);
        _frame.bottomBar:SetPoint("BOTTOMRIGHT", _frame, "BOTTOMRIGHT", 0, 0);

        _frame.tabHost = CreateFrame("Frame", _frameName .. "TabHost", _frame, BackdropTemplateMixin and "BackdropTemplate");
        _frame.tabHost:SetBackdrop(BACKDROP_TOOLTIP_0_16);

        _frame.tabSelector = CreateTabSelector(_frame);
        _frame.tabSelector:ClearAllPoints();
        _frame.tabSelector:SetPoint("TOPLEFT", _frame, "TOPLEFT", 0, 0);
        _frame.tabSelector:SetPoint("BOTTOMLEFT", _frame.bottomBar, "TOPLEFT", 0, 0);
        _frame.tabSelector:SetWidth(150);

        _frame.tabHost:SetPoint("TOPLEFT", _frame.tabSelector, "TOPRIGHT", 0, 0);
        _frame.tabHost:SetPoint("BOTTOMRIGHT", _frame.bottomBar, "TOPRIGHT", 0, 0);
    else
        _frame:SetParent(parent);
    end
    _frame:SetScript("OnSizeChanged", ConfigurationFrame.Layout);
    ConfigurationFrame.Layout(_frame, _frame:GetSize());
    return _frame;
end

function ConfigurationFrame.Layout(self, width, height)
    LayoutBottomBar(self);
end