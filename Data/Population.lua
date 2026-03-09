---@class ModUs
local ModUs = select(2, ...)
ModUs.population = {}

---@class Population
local P = ModUs.population
local U = ModUs.utils

local issecretvalue = issecretvalue or function() return false end
local UnitIsPlayer = UnitIsPlayer
local UnitGUID = UnitGUID
local UnitClassBase = UnitClassBase
local UnitRace = UnitRace
local UnitNameUnmodified = UnitNameUnmodified

function P.SaveUnitData(unit)
    if InCombatLockdown() then return end
    if not UnitIsPlayer(unit) then return end

    local guid = UnitGUID(unit)
    if not guid or issecretvalue(guid) then return end

    local t = MU_Population
    if t[guid] then return end -- 每次登录只记录同一玩家一次

    local _, realm = UnitNameUnmodified(unit)
    realm = realm and U.RemoveRealmSuffix(realm) or U.GetNormalizedRealmName()
    if not realm or realm == "" then return end

    t[guid] = {
        classID = select(2, UnitClassBase(unit)),
        raceID = select(3, UnitRace(unit)),
        level = U.GetLevelRangeName(UnitLevel(unit)),
        faction = UnitFactionGroup(unit),
        gender = UnitSex(unit),
        normalizedRealm = realm,
        lastSeen = time(),
    }
end

function P.SaveGroupData()
    if not IsInGroup() then return end

    for i = 1, GetNumGroupMembers() do
        local unit = IsInRaid() and "raid" .. i or "party" .. i
        P.SaveUnitData(unit)
    end
end