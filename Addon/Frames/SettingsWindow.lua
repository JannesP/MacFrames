local ADDON_NAME, _p = ...;
local L = _p.L;
local FrameUtil = _p.FrameUtil;

_p.SettingsWindow = {};
local SettingsWindow = _p.SettingsWindow;

local SettingsFrame = _p.SettingsFrame;

local _backdropSettings = {
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    edgeSize = 20,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
};
local _window;

do
    local function CreateCloseButton(parent)
        local closeButtonFrame = CreateFrame("Frame", nil, parent, BackdropTemplateMixin and "BackdropTemplate");
        closeButtonFrame:SetBackdrop(_backdropSettings);
        closeButtonFrame:SetSize(32, 32);

        local closeButton = CreateFrame("Button", nil, closeButtonFrame);
        closeButton:SetSize(30, 30);
        closeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up");
        closeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down");
        closeButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight");
        closeButton:RegisterForClicks("LeftButtonUp");
        closeButton:SetPoint("CENTER", closeButtonFrame, "CENTER");
        closeButton:SetScript("OnClick", SettingsWindow.Close);
        return closeButtonFrame;
    end
    local function CreateHeading(parent)
        local headerFrame = CreateFrame("Frame", nil, parent, BackdropTemplateMixin and "BackdropTemplate");
        headerFrame:SetBackdrop(_backdropSettings);

        headerFrame.text = FrameUtil.CreateText(headerFrame, L["MacFrames Options"], "ARTWORK");
        headerFrame.text:ClearAllPoints();
        headerFrame.text:SetPoint("CENTER", headerFrame, "CENTER");
        FrameUtil.WidthByText(headerFrame, headerFrame.text);
        headerFrame:SetHeight(30);
        return headerFrame;
    end
    function SettingsWindow.Open()
        if (not InCombatLockdown()) then
            if (_window == nil) then
                _window = CreateFrame("Frame", "MacFramesSettingsWindow", UIParent, BackdropTemplateMixin and "BackdropTemplate");
                _window:SetFrameStrata("HIGH");
                _window:SetBackdrop(_backdropSettings);
                tinsert(UISpecialFrames, _window:GetName());
                _window:SetScript("OnShow", function () PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN); end);
                _window:SetScript("OnHide", function () PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE); end);

                _window.closeButton = CreateCloseButton(_window);
                _window.closeButton:SetPoint("CENTER", _window, "TOPRIGHT", -30, 0);

                _window.heading = CreateHeading(_window);
                _window.heading:ClearAllPoints();
                _window.heading:SetPoint("BOTTOM", _window, "TOP", 0, -10);

                FrameUtil.ConfigureDragDropHost(_window.heading, _window);

                FrameUtil.AddResizer(_window, _window);
                _window:SetMinResize(462, 300);
                _window:SetMaxResize(1000, 800);

                _window:SetSize(600, 450);
                _window:SetPoint("CENTER", UIParent, "CENTER", 0, 0);

                _window.configFrame = SettingsFrame.Show(_window);
                _window.configFrame:SetPoint("TOPLEFT", _window, "TOPLEFT",  10, -10);
                _window.configFrame:SetPoint("BOTTOMRIGHT", _window, "BOTTOMRIGHT",  -10, 10);
            end
            _window:Show();
        end
    end
end

function SettingsWindow.Close()
    if (_window ~= nil) then
        _window:Hide();
    end
end


function SettingsWindow.Toggle()
    if (_window == nil or _window:IsVisible() == false) then
        SettingsWindow.Open();
    else
        SettingsWindow.Close();
    end
end