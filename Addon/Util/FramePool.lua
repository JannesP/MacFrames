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