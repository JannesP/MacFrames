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

_p.FrameUtil = {};
local FrameUtil = _p.FrameUtil;
local PixelPerfect = _p.PixelPerfect;


function FrameUtil.CreateText(frame, text, strata, font)
    --GameFontNormal, GameFontNormalSmall, GameFontNormalLarge
    local textFrame = frame:CreateFontString(nil, strata or "ARTWORK", font or "GameFontNormal");
    textFrame:SetText(text);
    return textFrame;
end

function FrameUtil.CreateFrameWithText(parent, name, text)
    local frame = CreateFrame("Frame", name, parent);
    frame.text = FrameUtil.CreateText(frame, text);
    frame.text:ClearAllPoints();
    PixelPerfect.SetPoint(frame.text, "CENTER", frame, "CENTER");
    return frame;
end

function FrameUtil.Pink(frame)
    return FrameUtil.CreateSolidTexture(frame, 1, 0.063, 0.94);
end

function FrameUtil.CreateSolidTexture(frame, ...)
    local tex = frame:CreateTexture();
    tex:SetColorTexture(...);
    tex:SetAllPoints();
    return tex;
end
do
    local function OnEnter(self)
        if (self.fuTooltip ~= nil) then
            GameTooltip:SetOwner(self.fuTooltip.anchorFrame or self, self.fuTooltip.anchor, self.fuTooltip.offsetX, self.fuTooltip.offsetY);
            GameTooltip:SetText(self.fuTooltip.text, unpack(self.fuTooltip.color));
            GameTooltip:Show();
        end
    end
    local function OnLeave(self)
        if (GameTooltip:IsOwned(self.fuTooltip.anchorFrame or self)) then
            GameTooltip:Hide();
        end
    end
    local function OnHide(self)
        if (GameTooltip:IsOwned(self.fuTooltip.anchorFrame or self)) then
            GameTooltip:Hide();
        end
    end
    function FrameUtil.CreateTextTooltip(frame, text, anchorFrame, anchor, offsetX, offsetY, ...)
        if (frame.fuTooltip == nil) then
            frame.fuTooltip = {};
            frame:HookScript("OnEnter", OnEnter);
            frame:HookScript("OnLeave", OnLeave);
            frame:HookScript("OnHide", OnHide);
        end
        frame.fuTooltip.color = { ... };
        frame.fuTooltip.text = text;
        frame.fuTooltip.anchorFrame = anchorFrame;
        frame.fuTooltip.anchor = anchor or "ANCHOR_RIGHT";
        frame.fuTooltip.offsetX = offsetX or 0;
        frame.fuTooltip.offsetY = offsetY or 0;
    end
end
do
    local FramePixelBorderMixin = {};
    function FramePixelBorderMixin:Resize(width)
        self.width = width;
        PixelPerfect.SetWidth(self.left, width);
        PixelPerfect.SetWidth(self.right, width);
        PixelPerfect.SetHeight(self.top, width);
        PixelPerfect.SetHeight(self.bottom, width);
    end
    function FramePixelBorderMixin:SetColor(...)
        self.left:SetColorTexture(...);
        self.top:SetColorTexture(...);
        self.right:SetColorTexture(...);
        self.bottom:SetColorTexture(...);
    end

    function FrameUtil.CreateSolidBorder(frame, width, ...)
        local borderFrames = CreateFromMixins({
            parent = frame,
            left = frame:CreateTexture(nil, "OVERLAY"),
            top = frame:CreateTexture(nil, "OVERLAY"),
            right = frame:CreateTexture(nil, "OVERLAY"),
            bottom = frame:CreateTexture(nil, "OVERLAY"),
        }, FramePixelBorderMixin);
        borderFrames:Resize(width);
        borderFrames:SetColor(...);

        PixelPerfect.SetPoint(borderFrames.left, "TOPLEFT", frame, "TOPLEFT");
        PixelPerfect.SetPoint(borderFrames.left, "BOTTOMLEFT", frame, "BOTTOMLEFT");

        PixelPerfect.SetPoint(borderFrames.top, "TOPLEFT", frame, "TOPLEFT");
        PixelPerfect.SetPoint(borderFrames.top, "TOPRIGHT", frame, "TOPRIGHT");

        PixelPerfect.SetPoint(borderFrames.right, "TOPRIGHT", frame, "TOPRIGHT");
        PixelPerfect.SetPoint(borderFrames.right, "BOTTOMRIGHT", frame, "BOTTOMRIGHT");

        PixelPerfect.SetPoint(borderFrames.bottom, "BOTTOMLEFT", frame, "BOTTOMLEFT");
        PixelPerfect.SetPoint(borderFrames.bottom, "BOTTOMRIGHT", frame, "BOTTOMRIGHT");
        return borderFrames;
    end
end

do
    local function Frame_MoveUp(self)
        local parent = self:GetParent();
        FrameUtil.MoveFrame(parent.frameToMove, 0, 1);
        if (parent.onFinishDragDrop) then
            parent.onFinishDragDrop(parent, parent.frameToMove);
        end
    end
    local function Frame_MoveLeft(self)
        local parent = self:GetParent();
        FrameUtil.MoveFrame(parent.frameToMove, -1, 0);
        if (parent.onFinishDragDrop) then
            parent.onFinishDragDrop(parent, parent.frameToMove);
        end
    end
    local function Frame_MoveRight(self)
        local parent = self:GetParent();
        FrameUtil.MoveFrame(parent.frameToMove, 1, 0);
        if (parent.onFinishDragDrop) then
            parent.onFinishDragDrop(parent, parent.frameToMove);
        end
    end
    local function Frame_MoveDown(self)
        local parent = self:GetParent();
        FrameUtil.MoveFrame(parent.frameToMove, 0, -1);
        if (parent.onFinishDragDrop) then
            parent.onFinishDragDrop(parent, parent.frameToMove);
        end
    end
    local function CbClampToScreen_Click(self)
        local checked = self:GetChecked();
        self.dragDropHost.frameToMove:SetClampedToScreen(checked);
        self.dragDropHost:SetClampedToScreen(checked);
    end
    function FrameUtil.CreateDragDropOverlay(frame, OnFinishDragDrop, clampToScreen)
        if (clampToScreen == nil) then
            clampToScreen = true;
        end
        local dragDropHost = FrameUtil.CreateFrameWithText(frame, frame:GetName() .. "DragDropOverlay", L["Drag Me!"]);
        dragDropHost:SetAllPoints();
        dragDropHost.texture = FrameUtil.CreateSolidTexture(dragDropHost, 0, 0, 0, 0.8);
        dragDropHost:SetFrameLevel(frame:GetFrameLevel() + 100);
        dragDropHost.borderFrames = FrameUtil.CreateSolidBorder(dragDropHost, 1, 1, 1, 1, 1);
        dragDropHost:Hide();
        FrameUtil.ConfigureDragDropHost(dragDropHost, frame, OnFinishDragDrop, clampToScreen);

        --[[
        local bUp = FrameUtil.CreateArrowButton(dragDropHost, "up");
        bUp:ClearAllPoints();
        PixelPerfect.SetPoint(bUp, "BOTTOM", dragDropHost.text, "TOP", 0, 0);
        PixelPerfect.SetSize(bUp, 24);
        bUp:SetScript("OnClick", Frame_MoveUp);

        local bLeft = FrameUtil.CreateArrowButton(dragDropHost, "left");
        bLeft:ClearAllPoints();
        PixelPerfect.SetPoint(bLeft, "RIGHT", dragDropHost.text, "LEFT", 0, 0);
        PixelPerfect.SetSize(bLeft, 24);
        bLeft:SetScript("OnClick", Frame_MoveLeft);

        local bRight = FrameUtil.CreateArrowButton(dragDropHost, "right");
        bRight:ClearAllPoints();
        PixelPerfect.SetPoint(bRight, "LEFT", dragDropHost.text, "RIGHT", 0, 0);
        PixelPerfect.SetSize(bRight, 24);
        bRight:SetScript("OnClick", Frame_MoveRight);

        local bDown = FrameUtil.CreateArrowButton(dragDropHost, "down");
        bDown:ClearAllPoints();
        PixelPerfect.SetPoint(bDown, "TOP", dragDropHost.text, "BOTTOM", 0, 0);
        PixelPerfect.SetSize(bDown, 24);
        bDown:SetScript("OnClick", Frame_MoveDown);
        ]]

        local cbClampToScreenFrame = CreateFrame("Frame", nil, dragDropHost);
        local cbClampToScreen = CreateFrame("CheckButton", nil, cbClampToScreenFrame, "SettingsCheckBoxTemplate");
        cbClampToScreen.dragDropHost = dragDropHost;
        cbClampToScreen:SetScript("OnClick", CbClampToScreen_Click);
        PixelPerfect.SetPoint(cbClampToScreen, "LEFT");
        cbClampToScreen:SetChecked(clampToScreen);

        cbClampToScreenFrame.text = FrameUtil.CreateText(cbClampToScreenFrame, L["Clamp"]);
        cbClampToScreenFrame.text:ClearAllPoints();
        PixelPerfect.SetPoint(cbClampToScreenFrame.text, "RIGHT");

        cbClampToScreenFrame:ClearAllPoints();
        PixelPerfect.SetHeight(cbClampToScreenFrame, math.max(cbClampToScreen:GetHeight(), cbClampToScreenFrame:GetHeight()));
        PixelPerfect.SetWidth(cbClampToScreenFrame, cbClampToScreen:GetWidth() + 4 + cbClampToScreenFrame.text:GetWidth());
        --PixelPerfect.SetPoint(cbClampToScreenFrame, "BOTTOM", bUp, "TOP", 0, -8);
        PixelPerfect.SetPoint(cbClampToScreenFrame, "CENTER", dragDropHost, "CENTER", 0, -25);
        return dragDropHost;
    end
end

function FrameUtil.MoveFrame(frame, x, y)
    if (frame:GetNumPoints() ~= 1) then
        error("This function only works with a single Anchor from SetPoint!");
    end
    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(1);
    PixelPerfect.SetPoint(frame, point, relativeTo, relativePoint, xOfs + x, yOfs + y);
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
    PixelPerfect.SetWidth(frame, text:GetWidth() + 20);
end

do
    local function DragDropHost_OnMouseDown(self, button)
        if (button == "LeftButton" and not self.isMoving) then
            local frameToMove = self.frameToMove;
            frameToMove:SetMovable(true);
            self:SetMovable(true);
            frameToMove:StartMoving();
            self.isMoving = true;
        end
    end
    local function DragDropHost_OnMouseUp(self, button)
        if (self.isMoving) then
            local frameToMove = self.frameToMove;
            frameToMove:StopMovingOrSizing();
            self.isMoving = false;
            self:SetMovable(false);
            frameToMove:SetMovable(false);
            if (self.onFinishDragDrop ~= nil) then
                self.onFinishDragDrop(self, frameToMove);
            end
        end
    end
    function FrameUtil.ConfigureDragDropHost(dragDropHost, frameToMove, OnFinishDragDrop, clampToScreen)
        if (clampToScreen == nil) then
            clampToScreen = true;
        end
        dragDropHost.frameToMove = frameToMove;
        dragDropHost.onFinishDragDrop = OnFinishDragDrop;
        frameToMove:SetClampedToScreen(clampToScreen);
        dragDropHost:SetClampedToScreen(clampToScreen);
        dragDropHost:EnableMouse(true);
        dragDropHost:SetScript("OnMouseDown", DragDropHost_OnMouseDown);
        dragDropHost:SetScript("OnMouseUp", DragDropHost_OnMouseUp);
    end
end
do
    local function Resizer_OnMouseDown(self, button)
        local frameToResize = self.frameToResize;
        if (button == "LeftButton" and not frameToResize.isResizing) then
            frameToResize:SetResizable(true);
            frameToResize:StartSizing();
            frameToResize.isResizing = true;
            if (self.onStartResize ~= nil) then
                self.onStartResize(self:GetParent(), frameToResize);
            end
        end
    end
    local function Resizer_OnMouseUp(self, button)
        local frameToResize = self.frameToResize;
        if (frameToResize.isResizing) then
            frameToResize:StopMovingOrSizing();
            frameToResize.isResizing = false;
            frameToResize:SetResizable(false);
            if (self.onFinishResize ~= nil) then
                self.onFinishResize(self:GetParent(), frameToResize);
            end
        end
    end
    function FrameUtil.AddResizer(frameToAttach, frameToResize, OnStartResize, OnFinishResize)
        local resizer = CreateFrame("Button", nil, frameToAttach);
        frameToAttach.resizer = resizer;
        PixelPerfect.SetSize(resizer, 15);
        resizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up");
        resizer:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down");
        resizer:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight");
        resizer:ClearAllPoints();
        PixelPerfect.SetPoint(resizer, "BOTTOMRIGHT", frameToAttach, "BOTTOMRIGHT", -5, 5);
        resizer:SetIgnoreParentAlpha(true);
        resizer:SetAlpha(1);
        resizer.frameToResize = frameToResize;
        resizer.onStartResize = OnStartResize;
        resizer.onFinishResize = OnFinishResize;
        resizer:SetScript("OnMouseDown", Resizer_OnMouseDown);
        resizer:SetScript("OnMouseUp", Resizer_OnMouseUp);
    end
end

function FrameUtil.CreateTextButton(parent, nameSuffix, text, onClickHandler)
    local b = CreateFrame("Button", nameSuffix and (parent:GetName() .. "Button" .. nameSuffix), parent, "UIPanelButtonTemplate");
    b:SetText(text);
    b:SetScript("OnClick", onClickHandler);
    FrameUtil.WidthByText(b, b.Text);
    return b;
end

function FrameUtil.ColorFrame(frame, ...)
    frame.debugTexture = frame:CreateTexture();
    frame.debugTexture:SetAllPoints();
    frame.debugTexture:SetColorTexture(...);
end

do
    local rows = {
        count = 0,
    };
    local function ClearRows()
        for i=1, rows.count do
            wipe(rows[i]);
        end
        rows.count = 0;
    end
    local function AddRow()
        local i = rows.count + 1;
        if (rows[i] == nil) then
            rows[i] = {};
        end
        rows.count = rows.count + 1;
    end
    local function AddInRow(i, element)
---@diagnostic disable-next-line: param-type-mismatch
        tinsert(rows[i], element);
    end
    local function GetRow(i)
        return rows[i];
    end
    local function CalcRowSize(row)
        local w, h = 0, 0;
        for i=1, #row do
            local eW, eH = row[i]:GetSize();
            w = w + eW;
            if (h < eH) then
                h = eH;
            end
        end
        return w, h;
    end
    local function AssignFramesToRows(horizontalSpace, children, minSpacing)
        local rowWidth, elementsInRow, rowIndex = 0, 0, 1;
        AddRow();
        for i=1, #children do
            local child = children[i];
            local cWidth = child:GetWidth();
                local rowUsedSpace = math.max(0, elementsInRow - 1) * minSpacing + rowWidth;
                if (rowUsedSpace + cWidth >= horizontalSpace) then
                    rowWidth = cWidth;
                    elementsInRow = 1;
                    AddRow();
                    rowIndex = rowIndex + 1;
                    AddInRow(rowIndex, child);
                else
                    AddInRow(rowIndex, child);
                    rowWidth = rowWidth + cWidth;
                    elementsInRow = elementsInRow + 1;
                end
        end
    end
    function FrameUtil.FlowChildren(frame, children, padding, minSpacing, widthOverride)
        ClearRows();
        local fWidth = widthOverride or frame:GetWidth();
        local horizontalSpace = fWidth - (padding * 2);
        AssignFramesToRows(horizontalSpace, children, minSpacing);
        local rowYOffset = padding;
        for i = 1, rows.count do
            local row = GetRow(i);
            if (i > 1) then
                rowYOffset = rowYOffset + minSpacing;
            end
            local rowWidth, rowHeight = CalcRowSize(row);
            local spacing = (horizontalSpace - rowWidth) / (#row + 1);
            local usedRowWidth = 0;
            for i=1, #row do
                local child = row[i];
                local xOffset = padding + usedRowWidth + (i * spacing);
                local yOffset = rowYOffset + (rowHeight  / 2) - (child:GetHeight() / 2);
                PixelPerfect.SetPoint(child, "TOPLEFT", frame, "TOPLEFT", xOffset, -yOffset);
                usedRowWidth = usedRowWidth + child:GetWidth();
            end
            rowYOffset = rowYOffset + rowHeight;
        end
        PixelPerfect.SetWidth(frame, fWidth);
        PixelPerfect.SetHeight(frame, rowYOffset + padding);
    end
end

do
    local function ScrollBarVisibility(self)
        if (self.isChangingScrollBarVisibility) then return end;
        self.isChangingScrollBarVisibility = true;
        if (self.content:GetHeight() > self:GetHeight()) then
            self.ScrollBar:Show();
            PixelPerfect.SetWidth(self.content, self:GetWidth() - self.ScrollBar:GetWidth());
        else
            PixelPerfect.SetWidth(self.content, self:GetWidth());
            self.ScrollBar:Hide();
        end
        self.isChangingScrollBarVisibility = false;
    end
    local function ScrollFrameOnSizeChanged(self, width, height)
        PixelPerfect.SetWidth(self.content, width or self:GetWidth());
        self:FullUpdate(ScrollBoxConstants.UpdateImmediately);
        ScrollBarVisibility(self);
    end
    local counter = 1;
    function FrameUtil.CreateVerticalScrollFrame(parent, child)
        local scroll = CreateFrame("Frame", ADDON_NAME.."_ScrollFrame"..counter, parent, "WowScrollBox");
        scroll.ScrollBar = CreateFrame("EventFrame", ADDON_NAME.."_ScrollFrame"..counter.."ScrollBar", parent, "MinimalScrollBar");
        local sbWidth = scroll.ScrollBar:GetWidth();

        child.scrollable = true;
        scroll.wheelPanScalar = 0.3;

        scroll.content = child;
        scroll.content:SetParent(scroll);
        PixelPerfect.SetWidth(scroll.content, scroll:GetWidth() - sbWidth);
        PixelPerfect.SetPoint(scroll.content, "TOPLEFT");
        PixelPerfect.SetPoint(scroll.content, "TOPRIGHT");

        PixelPerfect.SetPoint(scroll.ScrollBar, "TOPLEFT", scroll, "TOPRIGHT", -sbWidth, -sbWidth);
        PixelPerfect.SetPoint(scroll.ScrollBar, "BOTTOMLEFT", scroll, "BOTTOMRIGHT", -sbWidth, sbWidth);
        scroll.RefreshScrollBarVisibility = ScrollBarVisibility;

        ScrollUtil.InitScrollBoxWithScrollBar(scroll, scroll.ScrollBar, CreateScrollBoxLinearView());
        scroll:FullUpdate(ScrollBoxConstants.UpdateImmediately);

        scroll:SetScript("OnSizeChanged", ScrollFrameOnSizeChanged);
        scroll:SetScript("OnShow", function(self)
            ScrollBarVisibility(self);
        end);
        scroll:SetScript("OnHide", function(self)
            self.ScrollBar:Hide();
        end);
        counter = counter + 1;
        return scroll;
    end
end

function FrameUtil.GetIconZoomTransform(zoom)
    return 0 + zoom, 0 + zoom, 0 + zoom, 1 - zoom, 1 - zoom, 0 + zoom, 1 - zoom, 1 - zoom;
end

local _standardIconTransform = { FrameUtil.GetIconZoomTransform(0.1) };
function FrameUtil.GetStandardIconZoomTransform()
    return unpack(_standardIconTransform);
end

function FrameUtil.GridLayoutFromObjects(gridParent, gridDescriptor)
    if (gridParent.frameUtilGridData == nil) then
        gridParent.frameUtilGridData = {
            descriptor = gridDescriptor,
            headings = {},
        };
    end
    local gridFrame = gridParent[gridDescriptor.gridFramePropertyName];
    local totalWidth = gridFrame:GetWidth();
    if (totalWidth == 0) then return; end;
    local gridData = gridParent.frameUtilGridData;

    local rowItems = gridParent[gridDescriptor.childListPropertyName];
    local rowSpacing = gridDescriptor.rowSpacing;
    local columnSpacing = gridDescriptor.columnSpacing;
    local currentX = 0;
    local currentY = 0;

    local flexibleColumns = 0;
    local totalVisibleColumns = 0;
    local totalWidth = gridFrame:GetWidth();
    local freeWidth = totalWidth;
    for i=1, #gridDescriptor do
        local column = gridDescriptor[i];
        if (column.visible) then
            totalVisibleColumns = totalVisibleColumns + 1;
            if (column.width == "*") then
                flexibleColumns = flexibleColumns + 1;
            else
                freeWidth = freeWidth - column.width;
            end
        end
    end
    local flexibleWidth = (freeWidth - ((totalVisibleColumns - 1) * columnSpacing)) / flexibleColumns;
    local rowHeight = gridDescriptor.rowHeight;
    
    for i=1, #gridDescriptor do
        local descriptor = gridDescriptor[i];
        if (descriptor.visible) then
            if (currentX > 0) then  --add column spacing after the first row
                currentX = currentX + columnSpacing;
            end

            local columnWidth;
            if (descriptor.width == "*") then
                columnWidth = flexibleWidth;
            else
                columnWidth = descriptor.width;
            end

            currentY = 0;
            --create heading
            local heading = gridData.headings[i];
            if (gridData.headings[i] == nil) then
                heading = FrameUtil.CreateFrameWithText(gridFrame, nil, descriptor.heading);
                gridData.headings[i] = heading;
            else
                heading.text:SetText(descriptor.heading);
            end
            PixelPerfect.SetWidth(heading, columnWidth);
            PixelPerfect.SetHeight(heading, select(2, heading.text:GetFont()));
            heading:ClearAllPoints();
            PixelPerfect.SetPoint(heading, "TOPLEFT", gridFrame, "TOPLEFT", currentX, -currentY);
            currentY = currentY + heading:GetHeight() + rowSpacing;
            
            for i=1, #rowItems do
                if (currentY > 0) then
                    currentY = currentY + rowSpacing;
                end
                local rowItem = rowItems[i];
                local cell = rowItem[descriptor.cellFramePropertyName];
                cell:ClearAllPoints();
                PixelPerfect.SetSize(cell, columnWidth, rowHeight);
                PixelPerfect.SetPoint(cell, "TOPLEFT", gridFrame, "TOPLEFT", currentX, -currentY);
                currentY = currentY + rowHeight;
            end
            currentX = currentX + columnWidth;
        end
    end
    PixelPerfect.SetHeight(gridFrame, currentY);
end

function FrameUtil.CreateHorizontalSeperatorWithText(parent, text)
    local frame = CreateFrame("Frame", nil, parent);
    frame.leftLine = frame:CreateTexture();
    frame.rightLine = frame:CreateTexture();
    frame.text = FrameUtil.CreateText(frame, text, nil, "GameFontNormal");

    frame.leftLine:SetColorTexture(.4, .4, .4, 1);
    PixelPerfect.SetHeight(frame.leftLine, 2);

    frame.rightLine:SetColorTexture(.4, .4, .4, 1);
    PixelPerfect.SetHeight(frame.rightLine, 2);

    PixelPerfect.SetPoint(frame.text, "CENTER", frame, "CENTER");
    frame.text:SetJustifyH("CENTER");
    PixelPerfect.SetHeight(frame, select(2, frame.text:GetFont()));
    local p = 5;
    PixelPerfect.SetPoint(frame.leftLine, "LEFT", frame, "LEFT", p, 0);
    PixelPerfect.SetPoint(frame.leftLine, "RIGHT", frame.text, "LEFT", -p, 0);
    PixelPerfect.SetPoint(frame.rightLine, "LEFT", frame.text, "RIGHT", p, 0);
    PixelPerfect.SetPoint(frame.rightLine, "RIGHT", frame, "RIGHT", -p, 0);
    return frame;
end

function FrameUtil.StackVertical(container, children, spacing)
    spacing = spacing or 0;
    local usedHeight = 0;
    for i, child in ipairs(children) do
        PixelPerfect.SetPoint(child, "TOPLEFT", container, "TOPLEFT", 0, -usedHeight);
        usedHeight = usedHeight + child:GetHeight() + spacing;
    end
    return usedHeight - spacing;
end

function FrameUtil.StackHorizontal(container, children, spacing)
    spacing = spacing or 0;
    local usedWidth = 0;
    for i, child in ipairs(children) do
        PixelPerfect.SetPoint(child, "TOPLEFT", container, "TOPLEFT", usedWidth, 0);
        usedWidth = usedWidth + child:GetWidth();
    end
    return usedWidth;
end