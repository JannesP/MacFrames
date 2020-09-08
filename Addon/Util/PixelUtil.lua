local ADDON_NAME, _p = ...;

_p.PixelUtil = {
    GetIconZoomTransform = function(zoom)
        return 0 + zoom, 0 + zoom, 0 + zoom, 1 - zoom, 1 - zoom, 0 + zoom, 1 - zoom, 1 - zoom;
    end,
}