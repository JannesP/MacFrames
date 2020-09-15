local ADDON_NAME, _p = ...;

--declaration of global API object
MacFrames = {
    tprint = _p.tprint,
    UnitFrames = _p.UnitFrames,
};

if (_p.isDebugMode) then
    MacFrames._p = _p;
    jf = MacFrames;
end