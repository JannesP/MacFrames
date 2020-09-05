local ADDON_NAME, _p = ...;
local L = _p.L;

_p.FrameUtil = {};
local FrameUtil = _p.FrameUtil;


function FrameUtil.CreateText(frame, text, strata)
    local textFrame = frame:CreateFontString(nil, strata or "ARTWORK", "GameFontNormalSmall");
    textFrame:SetText(text);
    return textFrame;
end

function FrameUtil.CreateFrameWithText(parent, name, text, backdrop)
    local frame = CreateFrame("Frame", name, parent, backdrop and BackdropTemplateMixin and "BackdropTemplate");
    if (backdrop ~= nil) then frame:SetBackdrop(backdrop); end
    frame.text = FrameUtil.CreateText(frame, text);
    frame.text:ClearAllPoints();
    frame.text:SetPoint("CENTER", frame, "CENTER");
    return frame;
end

function FrameUtil.CreateSolidTexture(frame, ...)
    local tex = frame:CreateTexture();
    tex:SetColorTexture(...);
    tex:SetAllPoints();
    return tex;
end

function FrameUtil.CreateSolidBorder(frame, ...)
    local borderFrames = {
        left = frame:CreateTexture(nil, "OVERLAY"),
        top = frame:CreateTexture(nil, "OVERLAY"),
        right = frame:CreateTexture(nil, "OVERLAY"),
        bottom = frame:CreateTexture(nil, "OVERLAY"),
    };
    borderFrames.left:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0);
    borderFrames.left:SetPoint("TOPRIGHT", frame, "TOPLEFT", 1, 0);
    borderFrames.left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0);
    borderFrames.left:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", 1, 0);

    borderFrames.top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0);
    borderFrames.top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0);
    borderFrames.top:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, -1);
    borderFrames.top:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, -1);

    borderFrames.right:SetPoint("TOPLEFT", frame, "TOPRIGHT", -1, 0);
    borderFrames.right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0);
    borderFrames.right:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", -1, 0);
    borderFrames.right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0);

    borderFrames.bottom:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, 1);
    borderFrames.bottom:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, 1);
    borderFrames.bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0);
    borderFrames.bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0);

    for _, border in pairs(borderFrames) do
        border:SetColorTexture(...);
    end

    return borderFrames;
end

function FrameUtil.CreateDragDropOverlay(frame, OnFinishDragDrop)
    local dragDropHost = FrameUtil.CreateFrameWithText(frame, frame:GetName() .. "DragDropOverlay", L["Drag Me!"]);
    dragDropHost:SetAllPoints();
    dragDropHost.texture = FrameUtil.CreateSolidTexture(dragDropHost, 0, 0, 0, 0.8);
    dragDropHost:SetFrameLevel(frame:GetFrameLevel() + 100);
    dragDropHost.borderFrames = FrameUtil.CreateSolidBorder(dragDropHost, 1, 1, 1, 1);
    dragDropHost:Hide();
    FrameUtil.ConfigureDragDropHost(dragDropHost, frame, OnFinishDragDrop);

    local bUp = FrameUtil.CreateArrowButton(dragDropHost, "up");
    bUp:ClearAllPoints();
    bUp:SetPoint("BOTTOM", dragDropHost.text, "TOP", 0, 0);
    bUp:SetSize(24, 24);
    bUp:SetScript("OnClick", function(self) FrameUtil.MoveFrame(frame, 0, 1) end);

    local bLeft = FrameUtil.CreateArrowButton(dragDropHost, "left");
    bLeft:ClearAllPoints();
    bLeft:SetPoint("RIGHT", dragDropHost.text, "LEFT", 0, 0);
    bLeft:SetSize(24, 24);
    bLeft:SetScript("OnClick", function(self) FrameUtil.MoveFrame(frame, -1, 0) end);

    local bRight = FrameUtil.CreateArrowButton(dragDropHost, "right");
    bRight:ClearAllPoints();
    bRight:SetPoint("LEFT", dragDropHost.text, "RIGHT", 0, 0);
    bRight:SetSize(24, 24);
    bRight:SetScript("OnClick", function(self) FrameUtil.MoveFrame(frame, 1, 0) end);

    local bDown = FrameUtil.CreateArrowButton(dragDropHost, "down");
    bDown:ClearAllPoints();
    bDown:SetPoint("TOP", dragDropHost.text, "BOTTOM", 0, 0);
    bDown:SetSize(24, 24);
    bDown:SetScript("OnClick", function(self) FrameUtil.MoveFrame(frame, 0, -1) end);
    
    return dragDropHost;
end

function FrameUtil.MoveFrame(frame, x, y)
    if (frame:GetNumPoints() ~= 1) then
        error("This function only works with a single Anchor from SetPoint!");
    end
    local pixelScale = PixelUtil.GetPixelToUIUnitFactor();
    x = x * pixelScale;
    y = y * pixelScale;
    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(1);
    frame:SetPoint(point, relativeTo, relativePoint, xOfs + x, yOfs + y);
end

function FrameUtil.CreateArrowButton(parent, direction)
    local button = CreateFrame("Button", nil, parent);
    button:SetNormalTexture("Interface\\Glues\\Common\\Glue-LeftArrow-Button-Up");
    button:SetPushedTexture("Interface\\Glues\\Common\\Glue-LeftArrow-Button-Down");
    button:SetHighlightTexture("Interface\\Glues\\Common\\Glue-LeftArrow-Button-Highlight");

    if (direction == "left") then
        --texture orientation
    elseif (direction == "up") then
        FrameUtil.RotateButtonTextures(button, -(math.pi / 2));
    elseif (direction == "right") then
        FrameUtil.RotateButtonTextures(button, math.pi);
    elseif (direction == "down") then
        FrameUtil.RotateButtonTextures(button, math.pi / 2);
    end 
    return button;
end

function FrameUtil.RotateButtonTextures(button, radians)
    button:GetNormalTexture():SetRotation(radians);
    button:GetPushedTexture():SetRotation(radians);
    button:GetHighlightTexture():SetRotation(radians);
end

function FrameUtil.WidthByText(frame, text)
    frame:SetWidth(text:GetWidth() + 20);
end

function FrameUtil.ConfigureDragDropHost(dragDropHost, frameToMove, OnFinishDragDrop)
    frameToMove:SetClampedToScreen(true);
    dragDropHost:SetClampedToScreen(true);
    dragDropHost:EnableMouse(true);
    dragDropHost:SetScript("OnMouseDown", function(self, button)
        if (button == "LeftButton" and not dragDropHost.isMoving) then
            frameToMove:SetMovable(true);
            dragDropHost:SetMovable(true);
            frameToMove:StartMoving();
            dragDropHost.isMoving = true;
        end
    end);
    dragDropHost:SetScript("OnMouseUp", function(self, button) 
        if (self.isMoving) then
            frameToMove:StopMovingOrSizing();
            self.isMoving = false;
            dragDropHost:SetMovable(false);
            frameToMove:SetMovable(false);
            if (OnFinishDragDrop ~= nil) then
                OnFinishDragDrop(dragDropHost, frameToMove);
            end
        end
    end);
end

do
    local function SetAnchorTopLeft(frame)
        frame.resizeOriginalPoints = {};
        for i=1, frame:GetNumPoints() do   
            tinsert(frame.resizeOriginalPoints, { frame:GetPoint(i) });
        end
        local left, bottom, width, height = frame:GetRect();
        frame:ClearAllPoints();
        frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", left, bottom + height);
    end
    local function RevertToOriginalAnchor(frame)
        frame:ClearAllPoints();
        for i, point in ipairs(frame.resizeOriginalPoints) do
            frame:SetPoint(point[1], point[2], point[3], point[4], point[5]);
        end
    end
    function ReanchorFrame(frame)
        local left, bottom, width, height = frame:GetRect();
        frame:ClearAllPoints();
        frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, bottom);
    end
    function FrameUtil.AddResizer(frameToAttach, frameToResize, OnStartResize, OnFinishResize)
        frameToAttach.resizer = CreateFrame("Button", nil, frameToAttach);
        frameToAttach.resizer:SetSize(15, 15);
        frameToAttach.resizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up");
        frameToAttach.resizer:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down");
        frameToAttach.resizer:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight");
        frameToAttach.resizer:ClearAllPoints();
        frameToAttach.resizer:SetPoint("BOTTOMRIGHT", frameToAttach, "BOTTOMRIGHT", -5, 5);
        frameToAttach.resizer:SetIgnoreParentAlpha(true);
        frameToAttach.resizer:SetAlpha(1);
        frameToAttach.resizer:SetScript("OnMouseDown", function(self, button) 
            if (button == "LeftButton" and not frameToResize.isResizing) then
                frameToResize:SetResizable(true);
                frameToResize:StartSizing();
                frameToResize.isResizing = true;
                if (OnStartResize ~= nil) then
                    OnStartResize(frameToAttach, frameToResize);
                end
            end
        end);
        frameToAttach.resizer:SetScript("OnMouseUp", function(self, button) 
            if (frameToResize.isResizing) then
                frameToResize:StopMovingOrSizing();
                frameToResize.isResizing = false;
                frameToResize:SetResizable(false);
                if (OnFinishResize ~= nil) then
                    OnFinishResize(frameToAttach, frameToResize);
                end
            end
        end);
    end
end

function FrameUtil.CreateTextButton(parent, nameSuffix, text, onClickHandler)
    local b = CreateFrame("Button", parent:GetName() .. "Button" .. nameSuffix, parent, "UIPanelButtonTemplate");
    b:SetText(text);
    b:SetScript("OnClick", onClickHandler);
    FrameUtil.WidthByText(b, b.Text);
    return b;
end