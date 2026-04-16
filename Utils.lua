---@class ModUs
local ModUs = select(2, ...)
ModUs.utils = {}
---@class Utils
local U = ModUs.utils

ModUs.isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
ModUs.isVanilla = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
ModUs.isTBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
ModUs.isWrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
ModUs.isCata = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC
ModUs.isMists = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC

---------------------------------------------------------------------
-- client version map
---------------------------------------------------------------------
function U.GetClientMappingVersion(wowProjectID)
    wowProjectID = wowProjectID or WOW_PROJECT_ID
    if wowProjectID == WOW_PROJECT_MAINLINE then
        return 0 -- 正式服 retail
    elseif wowProjectID == WOW_PROJECT_CLASSIC then
        return 1 -- 经典怀旧服 classic_era
    elseif wowProjectID == WOW_PROJECT_MISTS_CLASSIC then
        return 2 -- 怀旧服 classic
    elseif wowProjectID == WOW_PROJECT_WRATH_CLASSIC then
        return 3 -- 时光服 classic_titan
    elseif wowProjectID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
        return 4 -- 周年服 anniversary
    end
end

---------------------------------------------------------------------
-- flavor level ranges
---------------------------------------------------------------------
-- wow_master.modus_level_segment_config
function U.GetFlavorLevelRanges()
    if ModUs.isRetail then -- 正式服
        return {
            low = {1, 20},
            medium = {21, 79},
            high = {80, 89},
            max = 90,
        }
    elseif ModUs.isVanilla then -- 经典怀旧服
        return {
            low = {1, 20},
            medium = {21, 49},
            high = {50, 59},
            max = 60,
        }
    elseif ModUs.isMists then -- 怀旧服
        return {
            low = {1, 20},
            medium = {21, 79},
            high = {80, 89},
            max = 90,
        }
    elseif ModUs.isWrath then -- 时光服
        return {
            low = {1, 20},
            medium = {21, 69},
            high = {70, 79},
            max = 80,
        }
    elseif ModUs.isTBC then -- 周年服
        return {
            low = {1, 20},
            medium = {21, 59},
            high = {60, 69},
            max = 70,
        }
    end
end

function U.GetLevelRangeName(level)
    local ranges = U.GetFlavorLevelRanges()
    if level >= ranges.low[1] and level <= ranges.low[2] then
        return "low"
    elseif level >= ranges.medium[1] and level <= ranges.medium[2] then
        return "medium"
    elseif level >= ranges.high[1] and level <= ranges.high[2] then
        return "high"
    elseif level == ranges.max then
        return "max"
    end
end

---------------------------------------------------------------------
-- color hex
---------------------------------------------------------------------
function U.GetColorHex(colorObj)
    if colorObj then
        return "#" .. colorObj:GenerateHexColor():sub(3)
    end
end

---------------------------------------------------------------------
-- realm
---------------------------------------------------------------------
local function RemoveSuffix(realmName)
    if realmName and realmName:find("^时光[VI]+") then
        return realmName:match("^时光[VI]+")
    end
    return realmName
end
U.RemoveRealmSuffix = RemoveSuffix

function U.GetRealmName()
    return RemoveSuffix(GetRealmName())
end

function U.GetNormalizedRealmName()
    return RemoveSuffix(GetNormalizedRealmName())
end

---------------------------------------------------------------------
-- battle tag
---------------------------------------------------------------------
local md5 = LibStub("AF_MD5")
function U.GetBattleTag()
    local bTag = select(2, BNGetInfo())
    if bTag then
        return md5.sumhexa(bTag), bTag
    end
end

---------------------------------------------------------------------
-- name
---------------------------------------------------------------------
local issecretvalue = issecretvalue or function() return false end

function U.UnitFullName(unit)
    if not unit or not UnitIsPlayer(unit) then return end

    local name, realm = UnitNameUnmodified(unit)
    if issecretvalue(name) or not name or name == "" then return end

    if not realm then realm = GetNormalizedRealmName() end
    if not realm or realm == "" then return end

    realm = RemoveSuffix(realm)

    return name .. "-" .. realm
end

---------------------------------------------------------------------
-- date
---------------------------------------------------------------------
-- Convert a date specification into a standardized YYYY-MM-DD string.
-- Examples:
--     U.FormatDate("2026-2-7") --> "2026-02-07"
--     U.FormatDate("26-2-7")   --> "2026-02-07"
--     U.FormatDate(26,2,7)     --> "2026-02-07"
function U.FormatDate(a, b, c)
    if not a then
        return
    end

    local y, m, d
    if type(a) == "number" then
        y, m, d = a, b, c
    elseif type(a) == "string" then
        y, m, d = a:match("^(%d+)%D(%d+)%D(%d+)$")
    end

    if not y or not m or not d then
        -- couldn't parse; return original
        return a
    end

    y = tonumber(y)
    m = tonumber(m)
    d = tonumber(d)
    if not y or not m or not d then
        return a
    end

    if y < 100 then
        y = y + 2000
    end
    return string.format("%04d-%02d-%02d", y, m, d)
end

---------------------------------------------------------------------
-- max level
---------------------------------------------------------------------
function U.GetMaxLevel()
    -- Upon initial login, this will return the result of GetMaxLevelForExpansionLevel(0) (currently 30)
    -- until sometime between PLAYER_ENTERING_WORLD and when a SHOW_SUBSCRIPTION_INTERSTITIAL would fire for a lapsed subscription
    -- but then provides the correct value through subsequent logins and reloads on the same server.
    if ModUs.isRetail then
        return 90
    elseif ModUs.isMists then
        return 90
    elseif ModUs.isCata then
        return 85
    elseif ModUs.isWrath then
        return 80
    elseif ModUs.isVanilla then
        return 60
    end
end

---------------------------------------------------------------------
-- class id
---------------------------------------------------------------------
local classFileToID = {
    WARRIOR = 1,
    PALADIN = 2,
    HUNTER = 3,
    ROGUE = 4,
    PRIEST = 5,
    DEATHKNIGHT = 6,
    SHAMAN = 7,
    MAGE = 8,
    WARLOCK = 9,
    MONK = 10,
    DRUID = 11,
    DEMONHUNTER = 12,
    EVOKER = 13,
}

local localizedClassToID = {}

do
    local localizedClass
    if FillLocalizedClassList then
        localizedClass = {}
        FillLocalizedClassList(localizedClass)
    else
        localizedClass = LocalizedClassList()
    end

    for classFile, classID in next, localizedClass do
        local localizedClass = localizedClass[classFile]
        if localizedClass then
            localizedClassToID[localizedClass] = classID
        end
    end
end

function U.GetClassID(class)
    return classFileToID[class] or localizedClassToID[class]
end