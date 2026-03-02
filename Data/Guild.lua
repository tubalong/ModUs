---@class ModUs
local ModUs = select(2, ...)
ModUs.guild = {}

---@class Guild
local G = ModUs.guild
local U = ModUs.utils

-- [1, 20], [21, 79], [80, max), max
local MED_LEVEL = 80
local LOW_LEVEL = 20

---------------------------------------------------------------------
-- update data
---------------------------------------------------------------------
-- local lastUpdateTime = 0
local lastGuildUpdate
local isGuildScanned

function G.UpdateData()
    if not IsInGuild() then return end

    -- local now = time()
    -- if now - lastUpdateTime < 600 then
    --     return
    -- end
    -- lastUpdateTime = now

    local t = MU_Guild

    t.name, _, _, t.realm = GetGuildInfo("player")
    if t.realm then
        t.realm = U.RemoveRealmSuffix(t.realm)
    else
        t.realm = U.GetNormalizedRealmName()
    end

    t.faction = GetGuildFactionGroup() and "Horde" or "Alliance"
    t.achievementPoints = GetTotalAchievementPoints(true)

    -- num members (today)
    local online
    local day = date("%d")
    if lastGuildUpdate ~= day then
        t.numMembersOnline = 0
        lastGuildUpdate = day
    end
    t.numMembers, online = GetNumGuildMembers()
    t.numMembersOnline = max(t.numMembersOnline, online or 0)

    -- 公会仅需成功扫描一次
    if not isGuildScanned then
        MAX_LEVEL = U.GetMaxLevel()
        if not MAX_LEVEL then return end

        t.classesAtMaxLevel = {}
        -- t.raceDistribution = {}
        t.levelDistribution = {}

        for i = 1, t.numMembers do
            local name, _, _, level, _, _, _, _, _, _, classFile, _, _, _, _, _, guid = GetGuildRosterInfo(i)
            if level and classFile then
                local classID = tostring(U.GetClassID(classFile))

                -- GetPlayerInfoByGUID(guid) -- guid not always available

                if level == MAX_LEVEL then
                    t.classesAtMaxLevel[classID] = (t.classesAtMaxLevel[classID] or 0) + 1
                    t.levelDistribution.max = (t.levelDistribution.max or 0) + 1
                elseif level >= MED_LEVEL then
                    t.levelDistribution.high = (t.levelDistribution.high or 0) + 1
                elseif level > LOW_LEVEL then
                    t.levelDistribution.medium = (t.levelDistribution.medium or 0) + 1
                else
                    t.levelDistribution.low = (t.levelDistribution.low or 0) + 1
                end

                isGuildScanned = true
            else
                isGuildScanned = nil
                break
            end
        end
    end
end