local ADDON_NAME, _p = ...;

_p.ConfigurationFrame = {};
local ConfigurationFrame = _p.ConfigurationFrame;

local _frame;

function ConfigurationFrame.new(parent)
    if _frame ~= nil then
        error("Cannot create two ConfigurationFrames.");
    end
    if (not _p.isRunningShadowlands) then --if it's not shadowlands yet
        _frame = CreateFrame("Frame", "MacFramesConfigurationFrame", parent)
    else
        _frame = CreateFrame("Frame", "MacFramesConfigurationFrame", parent, "BackdropTemplate")
    end
    local tex = _frame:CreateTexture();
    tex:SetAllPoints();
    return _frame;
end