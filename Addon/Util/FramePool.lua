local ADDON_NAME, _p = ...;

_p.FramePool = {};
function _p.FramePool:Put(frame)
    frame:UnregisterAllEvents();
    frame:Hide();
    frame:SetParent(nil);
    frame:ClearAllPoints();
    self.pool[#self.pool + 1] = frame;
end
function _p.FramePool:Take()
    local pool, count = self.pool, #self.pool;
    if (count > 0) then
        local frame = pool[count];
        pool[count] = nil;
        return frame;
    end
    return nil;
end
function _p.FramePool:GetCount()
    return #self.pool;
end
_p.FramePool.new = function()
    local result = {
        pool = {},
    };
    setmetatable(result, { __index = _p.FramePool });
    return result;
end