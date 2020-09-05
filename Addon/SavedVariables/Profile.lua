local ADDON_NAME, _p = ...;

_p.Profile = {};
local Profile = _p.Profile;

local function NewWrapper()
    return setmetatable({ 
            _settings = {},
            _propertyChangedListeners = {},
            OnPropertyChanged = function(self, key)
                for callback, _ in pairs(self._propertyChangedListeners) do
                    callback(key);
                end
            end,
            RegisterPropertyChanged = function(self, callback)
                self._propertyChangedListeners[callback] = true;
            end,
            UnregisterPropertyChanged = function(self, callback)
                self._propertyChangedListeners[callback] = nil;
            end,
            GetRawEntries = function(self)
                return self._settings;
            end,
        }, {
            __index = function(self, key)
                return self._settings[key];
            end,
            __newindex = function(self, key, value)
                if (type(value) == "table") then
                    error("Cannot assign tables to settings!");
                end
                self._settings[key] = value;
                print("__newindex", key, value);
                self:OnPropertyChanged(key);
            end,
        }
    );
end

local function CreateWrapper(settings)
    local objType = type(settings);
    if (objType == 'table') then
        local wrapper = NewWrapper();
        for key, value in pairs(settings) do
            wrapper._settings[key] = CreateWrapper(value);
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
    return CreateWrapper(svars);
end
