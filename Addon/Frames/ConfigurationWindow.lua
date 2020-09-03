local ADDON_NAME, _p = ...;
local L = _p.L;

_p.ConfigurationWindow = {};
local ConfigurationWindow = _p.ConfigurationWindow;

local ConfigurationFrame = _p.ConfigurationFrame;

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
        closeButton:SetScript("OnClick", function() ConfigurationWindow.Close() end);
        return closeButtonFrame;
    end
    local function CreateHeading(parent)
        local headerFrame = CreateFrame("Frame", nil, parent, BackdropTemplateMixin and "BackdropTemplate");
        headerFrame:SetBackdrop(_backdropSettings);

        headerFrame.text = headerFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
        headerFrame.text:SetAllPoints();
        headerFrame.text:SetText(L["MacFrames Config"]);
        headerFrame:SetSize(headerFrame.text:GetWidth() * 1.3, 30);
        return headerFrame;
    end
    function ConfigurationWindow.Open()
        if (_window == nil) then
            _window = CreateFrame("Frame", "MacFramesConfigurationWindow", UIParent, BackdropTemplateMixin and "BackdropTemplate");
            _window:SetBackdrop(_backdropSettings);
            tinsert(UISpecialFrames, _window:GetName());
            _window:SetScript("OnShow", function () PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN); end);
            _window:SetScript("OnHide", function () PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE); end);

            _window.closeButton = CreateCloseButton(_window);
            _window.closeButton:SetPoint("CENTER", _window, "TOPRIGHT", -30, 0);

            _window.heading = CreateHeading(_window);
            _window.heading:ClearAllPoints();
            _window.heading:SetPoint("BOTTOM", _window, "TOP", 0, -10);

            _window:SetClampedToScreen(true);
            _window:SetMovable(true);
            _window:EnableMouse(true);
            _window.heading:SetMovable(true);
            _window.heading:EnableMouse(true);
            _window.heading:SetScript("OnMouseDown", function(self, button) 
                print("OnMouseDown");
                if (button == "LeftButton" and not _window.isMoving) then
                    _window:StartMoving();
                    _window.isMoving = true;
                end
            end);
            _window.heading:SetScript("OnMouseUp", function(self, button) 
                if (_window.isMoving) then
                    _window:StopMovingOrSizing();
                    _window.isMoving = false;
                end
            end);

            _window.resizer = CreateFrame("Button", nil, _window);
            _window.resizer:SetSize(15, 15);
            _window.resizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up");
            _window.resizer:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down");
            _window.resizer:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight");
            _window.resizer:ClearAllPoints();
            _window.resizer:SetPoint("BOTTOMRIGHT", _window, "BOTTOMRIGHT", -5, 5);
            _window:SetResizable(true);
            _window:SetMinResize(300, 200);
            _window:SetMaxResize(1000, 800);
            _window.resizer:SetScript("OnMouseDown", function(self, button) 
                if (button == "LeftButton" and not _window.isMoving) then
                    _window:StartSizing();
                    _window.isMoving = true;
                end
            end);
            _window.resizer:SetScript("OnMouseUp", function(self, button) 
                if (_window.isMoving) then
                    _window:StopMovingOrSizing();
                    _window.isMoving = false;
                end
            end);

            _window.configFrame = ConfigurationFrame.new(_window);
            _window.configFrame:SetPoint("TOPLEFT", _window, "TOPLEFT",  10, -10);
            _window.configFrame:SetPoint("BOTTOMRIGHT", _window, "BOTTOMRIGHT",  -10, 10);
        end
        _window:SetSize(600, 450);
        _window:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
        _window:Show();
    end
end

function ConfigurationWindow.Close()
    if (_window == nil) then
        error("Window not yet created.");
    end
    _window:Hide();
end


function ConfigurationWindow.Toggle()
    if (_window == nil or _window:IsVisible() == false) then
        ConfigurationWindow.Open();
    else
        ConfigurationWindow.Close();
    end
end