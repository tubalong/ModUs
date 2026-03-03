---@class ModUs
local ModUs = select(2, ...)
ModUs.account = {}

---@class Account
local A = ModUs.account
local U = ModUs.utils

---------------------------------------------------------------------
-- mounts
---------------------------------------------------------------------
local GetMounts

local function GetMounts()
    local mounts = ""
    local numMounts = 0
    for _, id in next, C_MountJournal.GetMountIDs() do
        local isCollected = select(11, C_MountJournal.GetMountInfoByID(id))
        if isCollected then
            numMounts = numMounts + 1
            if mounts == "" then
                mounts = id
            else
                mounts = mounts .. "," .. id
            end
        end
    end
    return mounts, numMounts
end

---------------------------------------------------------------------
-- pets TODO:
---------------------------------------------------------------------
local function GetPets()
    return nil
end

---------------------------------------------------------------------
-- titles TODO:
---------------------------------------------------------------------
local function GetTitles()
    return nil
end

---------------------------------------------------------------------
-- achievements (not available in Vanilla)
---------------------------------------------------------------------
local function GetAchievements()
    -- TODO:
    return nil
end

local function GetLatestAchievements()
    local t = {}
    for _, achievementID in pairs({GetLatestCompletedAchievements()}) do
        local id, name, points, completed, month, day, year, desc, _, icon, _, isGuild = GetAchievementInfo(achievementID)
        tinsert(t, {
            id = id,
            name = name,
            icon = icon,
            points = points,
            date = U.FormatDate(year, month, day), -- normalize to YYYY-MM-DD
        })
    end
    return t
end

function A.UpdateAchievements()
    local t = MU_Account
    t.achievements = GetAchievements()
    t.latestAchievements = GetLatestAchievements()
    t.achievementPoints = GetTotalAchievementPoints()
end

---------------------------------------------------------------------
-- trading post
---------------------------------------------------------------------
if ModUs.isRetail then
    local GetCurrencyAmount = C_PerksProgram.GetCurrencyAmount

    function A.UpdateTradingPostCurrency()
        MU_Account.tradingPost.currencyAmount = GetCurrencyAmount()
    end

    local GetVendorItemInfo = C_PerksProgram.GetVendorItemInfo
    local GetAvailableVendorItemIDs = C_PerksProgram.GetAvailableVendorItemIDs
    local knownItems = {}

    function A.UpdateTradingPostKnownItems()
        for _, id in next, GetAvailableVendorItemIDs() do
            local known = GetVendorItemInfo(id).purchased
            if known then
                knownItems[id] = true
            else
                knownItems[id] = nil
            end
        end
    end

    function A.SaveTradingPostKnownItems()
        local result = {}
        for id in next, knownItems do
            tinsert(result, id)
        end
        MU_Account.tradingPost.knownItems = table.concat(result, ",")
    end
else
    function A.UpdateTradingPostCurrency()
        -- do nothing
    end

    function A.UpdateTradingPostKnownItems()
        -- do nothing
    end

    function A.SaveTradingPostKnownItems()
        -- do nothing
    end
end

---------------------------------------------------------------------
-- update data
---------------------------------------------------------------------
function A.UpdateData()
    local t = MU_Account

    t.battleTag = U.GetBattleTag()
    t.isTrial = IsTrialAccount()
    t.mounts, t.numMounts = GetMounts()
    t.pets = GetPets()
    t.titles = GetTitles()
    t.achievements = GetAchievements()
    t.latestAchievements = GetLatestAchievements()
    t.achievementPoints = GetTotalAchievementPoints()

    t.tradingPost = {}
    A.UpdateTradingPostCurrency()
end