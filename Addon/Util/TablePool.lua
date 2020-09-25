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

_p.TablePool = {};
local TablePool = _p.TablePool;

function TablePool.Create(resetFunc)
    local pool = setmetatable({}, { __index = TablePool });
    pool.resetFunc = resetFunc;
    pool.tablePool = {};
    return pool;
end

function TablePool:Take()
    local result;
    local pool = self.tablePool;
    local poolSize = #pool;
    if (poolSize == 0) then
        result = {};
    else
        result = pool[poolSize];
        pool[poolSize] = nil;
    end
    self.resetFunc(result);
    return result;
end

function TablePool:Put(table)
    self.tablePool[#self.tablePool + 1] = table;
end