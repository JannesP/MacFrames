--[[
-- MacFrames - WoW Raid and Party Frames <https://github.com/JannesP/MacFrames>
--Copyright (C) 2020  Jannes Peters
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
local FrameUtil = _p.FrameUtil;
local PlayerInfo = _p.PlayerInfo;
local PopupDisplays = _p.PopupDisplays;

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
        local closeButtonFrame = CreateFrame("Frame", nil, parent, "BackdropTemplate");
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
        local headerFrame = CreateFrame("Frame", nil, parent, "BackdropTemplate");
        headerFrame:SetBackdrop(_backdropSettings);

        headerFrame.text = FrameUtil.CreateText(headerFrame, L["MacFrames Options"], "ARTWORK");
        headerFrame.text:ClearAllPoints();
        headerFrame.text:SetPoint("CENTER", headerFrame, "CENTER");
        FrameUtil.WidthByText(headerFrame, headerFrame.text);
        headerFrame:SetHeight(30);
        return headerFrame;
    end
    function SettingsWindow.Open()
        if (PlayerInfo.specId == nil) then
            PopupDisplays.ShowGenericMessage("MacFrames currently doesn't support characters without a specialization.\nI kinda forgot about fresh characters. Please consider using the default frames until you are able to select a specialization.\nSorry :(");
            return;
        end
        if (not InCombatLockdown()) then
            if (_window == nil) then
                _window = CreateFrame("Frame", "MacFramesSettingsWindow", UIParent, "BackdropTemplate");
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

                FrameUtil.ConfigureDragDropHost(_window.heading, _window, nil, true);

                FrameUtil.AddResizer(_window, _window);
                _window:SetMinResize(600, 300);
                _window:SetMaxResize(1000, 800);
                _window:EnableMouse(true);

                _window:SetSize(750, 500);
                _window:SetPoint("CENTER", UIParent, "CENTER", 0, 0);

                _window.configFrame = SettingsFrame.Show(_window);
                _window.configFrame:SetPoint("TOPLEFT", _window, "TOPLEFT",  10, -10);
                _window.configFrame:SetPoint("BOTTOMRIGHT", _window, "BOTTOMRIGHT",  -10, 10);
            end
            _window:Show();
        else
            _p.UserChatMessage(L["Cannot open settings in combat."]);
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