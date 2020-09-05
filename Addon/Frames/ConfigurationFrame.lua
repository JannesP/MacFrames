local ADDON_NAME, _p = ...;
local Addon = _p.Addon;
local FrameUtil = _p.FrameUtil;

_p.ConfigurationFrame = {};
local ConfigurationFrame = _p.ConfigurationFrame;

local _frameName = "MacFramesConfigurationFrame";
local _frame;

local function CreateTextButton(parent, nameSuffix, text, onClickHandler)
    local b = CreateFrame("Button", parent:GetName() .. "Button" .. nameSuffix, parent, "UIPanelButtonTemplate");
    b:SetText(text);
    b:SetWidth(b.Text:GetWidth() + 10);
    b:SetScript("OnClick", onClickHandler);
    return b;
end

local function CreateBottomBar(self)
    local frame = CreateFrame("Frame", _frameName .. "BottomBar", self);
    frame:ClearAllPoints();
    frame:SetHeight(30);

    frame.children = {};
    tinsert(frame.children, CreateTextButton(frame, "TestRaid", "Toggle Test Mode: Raid", function () Addon.ToggleTestMode(Addon.TestMode.Raid); end));
    tinsert(frame.children, CreateTextButton(frame, "TestParty", "Toggle Test Mode: Party", function () Addon.ToggleTestMode(Addon.TestMode.Party); end));

    tinsert(frame.children, CreateTextButton(frame, "ToggleAnchors", "Toggle Anchors", function () Addon.ToggleAnchors(); end));
    return frame;
end

local function LayoutFrame(self)

end

local function LayoutBottomBar(self)
    local bar = self.bottomBar;
    local lastFrame = bar.children[1];
    local heightToBe = lastFrame:GetHeight();
    lastFrame:ClearAllPoints();
    lastFrame:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0);
    for i=2, #bar.children do
        local curr = bar.children[i];
        curr:ClearAllPoints();
        curr:SetPoint("BOTTOMLEFT", lastFrame, "BOTTOMRIGHT", 0, 0);
        lastFrame = curr;
        heightToBe = lastFrame:GetHeight();
    end
    bar:SetHeight(heightToBe);
end

function ConfigurationFrame.Show(parent)
    if _frame == nil then
        _frame = CreateFrame("Frame", _frameName, parent, BackdropTemplateMixin and "BackdropTemplate");
        _p.PixelUtil.ColorFrame(_frame, 1, 1, 1, 0.3);

        _frame.bottomBar = CreateBottomBar(_frame);
        _frame.bottomBar:SetPoint("BOTTOMLEFT", _frame, "BOTTOMLEFT", 0, 0);
        _frame.bottomBar:SetPoint("BOTTOMRIGHT", _frame, "BOTTOMRIGHT", 0, 0);
        _p.PixelUtil.ColorFrame(_frame.bottomBar, 1, 0, 0, 0.3);
    else
        _frame:SetParent(parent);
    end
    _frame:SetScript("OnSizeChanged", ConfigurationFrame.Layout);
    ConfigurationFrame.Layout(_frame, _frame:GetSize());
    return _frame;
end

function ConfigurationFrame.Layout(self, width, height)
    LayoutFrame(self);
    LayoutBottomBar(self);
end