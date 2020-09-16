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