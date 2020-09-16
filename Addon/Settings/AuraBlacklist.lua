local ADDON_NAME, _p = ...;

_p.AuraBlacklist = {
    [600] = true,       --Exhaustion (Hero/BL/Drums Debuff)
    [6788] = true,      --Weakened Soul
    [206151] = true,    --Challenger's Burden
    [319346] = true,    --Infinity's Toll

    --###### Hero/BL ######
    [57724] = true,     --Sated
    [57723] = true,     --Exhaustion

    --####### Toys ########
    [188409] = true,    --Felflame Campfire
    [195776] = true,    --Moonfeather Fever
}