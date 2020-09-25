local ADDON_NAME, _p = ...;

_p.Profile = {};
local Profile = _p.Profile;

local NewWrapper;
do
    local function Wrapper_OnPropertyChanged(self, key)
        for callback, _ in pairs(self._propertyChangedListeners) do
            callback(key);
        end
    end
    local function Wrapper_RegisterPropertyChanged(self, callback)
        self._propertyChangedListeners[callback] = true;
    end
    local function Wrapper_UnregisterPropertyChanged(self, callback)
        self._propertyChangedListeners[callback] = nil;
    end
    local function Wrapper_RegisterAllPropertyChanged(self, callback)
        self:RegisterPropertyChanged(callback);
        for _, setting in pairs(self._settings) do
            if (type(setting) == "table") then
                setting:RegisterAllPropertyChanged(callback);
            end
        end
    end
    local function Wrapper_UnregisterAllPropertyChanged(self, callback)
        self:UnregisterPropertyChanged(callback);
        for _, setting in pairs(self._settings) do
            if (type(setting) == "table") then
                setting:UnregisterAllPropertyChanged(callback);
            end
        end
    end
    local function Wrapper_GetRawEntries(self)
        return self._settings;
    end
    local function Wrapper_Metatable__index(self, key)
        local result = self._settings[key];
        if (result == nil) then
            local default = self._defaults[key];
            if (default ~= nil and type(default) ~= 'table') then
                _p.Log("Loading default ("..key.."): "..tostring(default));
                self._settings[key] = default;
                result = default;
            end
        end
        return result;
    end
    local function Wrapper_Metatable__newindex(self, key, value)
        if (type(value) == "table") then
            error("Cannot assign tables to settings!");
        end
        if (InCombatLockdown()) then
            error("Cannot change settings in combat!");
        end
        if (self._settings[key] ~= value) then
            self._settings[key] = value;
            self:OnPropertyChanged(key);
        end
    end
    NewWrapper = function(defaults)
        return setmetatable({
                _defaults = defaults,
                _settings = {},
                _propertyChangedListeners = {},
                OnPropertyChanged = Wrapper_OnPropertyChanged,
                RegisterPropertyChanged = Wrapper_RegisterPropertyChanged,
                UnregisterPropertyChanged = Wrapper_UnregisterPropertyChanged,
                RegisterAllPropertyChanged = Wrapper_RegisterAllPropertyChanged,
                UnregisterAllPropertyChanged = Wrapper_UnregisterAllPropertyChanged,
                GetRawEntries = Wrapper_GetRawEntries,
            }, {
                __index = Wrapper_Metatable__index,
                __newindex = Wrapper_Metatable__newindex,
            }
        );
    end
end

local function CreateWrapper(settings, defaults)
    if (type(settings) == 'table') then
        local wrapper = NewWrapper(defaults);
        for key, value in pairs(settings) do
            wrapper._settings[key] = CreateWrapper(value, defaults[key]);
        end
        return wrapper;
    else
        return settings;
    end
end

function Profile.GetSVars(self)
    if (type(self) == 'table') then
        local unwrapped = {};
        for key, value in pairs(self._settings) do
            unwrapped[key] = Profile.GetSVars(value);
        end
        return unwrapped;
    else
        return self;
    end
end

function Profile.LoadDefault()
    return Profile.Load(_p.DefaultProfileSettings);
end

function Profile.Load(svars)
    return CreateWrapper(svars, _p.DefaultProfileSettings);
end
