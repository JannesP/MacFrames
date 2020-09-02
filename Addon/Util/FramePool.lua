local ADDON_NAME, _p = ...;

_p.FramePool = {};
function _p.FramePool:Put(frame)
    frame:UnregisterAllEvents();
    frame:Hide();
    frame:SetParent(nil);
    frame:ClearAllPoints();
    tinsert(self.pool, frame);
end
function _p.FramePool:Take()
    return tremove(self.pool);
end
_p.FramePool.new = function()
    local result = {
        pool = {},
    };
    setmetatable(result, { __index = _p.FramePool });
    return result;
end