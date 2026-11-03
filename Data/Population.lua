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
local UnitLevel = UnitLevel
local UnitSex = UnitSex
local UnitNameUnmodified = UnitNameUnmodified
local UnitFactionGroup = UnitFactionGroup

---------------------------------------------------------------------
-- 保存玩家基本信息
---------------------------------------------------------------------
function P.SaveUnitData(unit)
    if InCombatLockdown() then return end
    if not UnitIsPlayer(unit) then return end

    local guid = UnitGUID(unit)
    if not guid or issecretvalue(guid) then return end
    P.UpdatePopulationStats(guid)

    local t = MU_Population
    if t[guid] then return end -- 每次登录只记录同一玩家一次

    local _, realm = UnitNameUnmodified(unit)
    realm = realm and U.RemoveRealmSuffix(realm) or U.GetNormalizedRealmName()
    if not realm or realm == "" then return end

    local result = {
        classID = select(2, UnitClassBase(unit)),
        raceID = select(3, UnitRace(unit)),
        level = UnitLevel(unit),
        faction = UnitFactionGroup(unit),
        gender = UnitSex(unit),
        normalizedRealm = realm,
        lastSeen = time(),
    }

    -- 检查数据是否完整有效
    for _, v in next, result do
        if issecretvalue(v) or not v or v == "" or v == 0 then
            return
        end
    end

    t[guid] = result
end

---------------------------------------------------------------------
-- 保存小队/团队成员信息
---------------------------------------------------------------------
function P.SaveGroupData()
    if not IsInGroup() then return end

    for i = 1, GetNumGroupMembers() do
        local unit = IsInRaid() and "raid" .. i or "party" .. i
        P.SaveUnitData(unit)
    end
end

---------------------------------------------------------------------
-- 更新今日人口统计状态
---------------------------------------------------------------------
local lastPopulationUpdate = GetServerTime()
local playerGUID

local function GetPopulationStats(day)
    local t = MU_PopulationStats[day]
    if not t then
        t = {
            activeSeconds = 0,
            uniquePlayers = 0,
            seenPlayers = {},
        }
        MU_PopulationStats[day] = t
    end
    return t
end

local function AddSeenPlayer(t, guid)
    if guid and not t.seenPlayers[guid] then
        t.seenPlayers[guid] = true
        t.uniquePlayers = t.uniquePlayers + 1
    end
end

function P.UpdatePopulationStats(guid)
    local now = GetServerTime()

    if not playerGUID then
        local currentPlayerGUID = UnitGUID("player")
        if not issecretvalue(currentPlayerGUID) and currentPlayerGUID then
            playerGUID = currentPlayerGUID
        end
    end

    while lastPopulationUpdate < now do
        local intervalEnd = math.min(now, U.GetNextDay(lastPopulationUpdate))
        local day = U.GetServerDate(lastPopulationUpdate)
        local t = GetPopulationStats(day)
        t.activeSeconds = t.activeSeconds + intervalEnd - lastPopulationUpdate
        AddSeenPlayer(t, playerGUID)
        lastPopulationUpdate = intervalEnd
    end

    lastPopulationUpdate = now
    local t = GetPopulationStats(U.GetServerDate(now))
    AddSeenPlayer(t, playerGUID)
    AddSeenPlayer(t, guid)
end

function P.SchedulePopulationUpdate()
    local now = GetServerTime()
    C_Timer.After(U.GetNextDay(now) - now, function()
        P.UpdatePopulationStats()
        P.SchedulePopulationUpdate()
    end)
end

function P.CompactPopulationStats()
    if not MU_CollectorID or type(MU_POPULATION_UPLOADED_ACK[MU_CollectorID]) ~= "string" then return end

    local today = U.GetCurrentDate()
    for day, t in next, MU_PopulationStats do
        if day < today and U.IsDateUploaded(MU_POPULATION_UPLOADED_ACK[MU_CollectorID], day) then
            MU_PopulationStats[day] = nil
        end
    end
end