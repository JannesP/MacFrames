local ADDON_NAME, _p = ...;

--declaration of global API object
JFrames = {
    tprint = _p.tprint,
    UnitFrames = _p.UnitFrames,
    Settings = _p.Settings,
};

if (_p.isDebugMode) then
    JFrames._p = _p;
    jf = JFrames;
end