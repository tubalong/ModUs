---@class ModUs
local ModUs = select(2, ...)
ModUs.account = {}

---@class Account
local A = ModUs.account
local U = ModUs.utils

local tinsert, tconcat = table.insert, table.concat

---------------------------------------------------------------------
-- mounts
---------------------------------------------------------------------
local GetMountIDs = C_MountJournal.GetMountIDs
local GetMountInfoByID = C_MountJournal.GetMountInfoByID

local function GetMounts()
    local mounts = {}
    local numMounts = 0
    for _, id in next, GetMountIDs() do
        local isCollected = select(11, GetMountInfoByID(id))
        if isCollected then
            numMounts = numMounts + 1
            tinsert(mounts, id)
        end
    end
    return tconcat(mounts, ","), numMounts
end

function A.UpdateMounts()
    local t = MU_Account
    t.mounts, t.numMounts = GetMounts()
end

---------------------------------------------------------------------
-- pets
---------------------------------------------------------------------
local GetNumPets = C_PetJournal.GetNumPets
local GetPetInfoByIndex = C_PetJournal.GetPetInfoByIndex
local GetOwnedPetIDs = C_PetJournal.GetOwnedPetIDs
local GetPetInfoByPetID = C_PetJournal.GetPetInfoByPetID

local function GetPets()
    local _, owned = GetNumPets()
    local pets = {}
    for _, guid in next, GetOwnedPetIDs() do
        local id = GetPetInfoByPetID(guid)
        if id then
            tinsert(pets, id)
        end
    end
    return tconcat(pets, ","), owned
end

function A.UpdatePets()
    local t = MU_Account
    t.pets, t.numPets = GetPets()
end

---------------------------------------------------------------------
-- toys
---------------------------------------------------------------------
local SetAllExpansionTypeFilters = C_ToyBox.SetAllExpansionTypeFilters
local SetAllSourceTypeFilters = C_ToyBox.SetAllSourceTypeFilters
local SetCollectedShown = C_ToyBox.SetCollectedShown
local SetUncollectedShown = C_ToyBox.SetUncollectedShown
local GetUncollectedShown = C_ToyBox.GetUncollectedShown
local GetNumLearnedDisplayedToys = C_ToyBox.GetNumLearnedDisplayedToys
local GetToyFromIndex = C_ToyBox.GetToyFromIndex

local function GetToys()
    SetAllExpansionTypeFilters(true)
    SetAllSourceTypeFilters(true)
    SetCollectedShown(true)

    local uncollectedShown = GetUncollectedShown()
    SetUncollectedShown(false)

    local toys = {}
    local numToys = 0
    for i = 1, GetNumLearnedDisplayedToys() do
        local id = GetToyFromIndex(i)
        if id and id ~= -1 then
            numToys = numToys + 1
            tinsert(toys, id)
        end
    end

    -- restore
    SetUncollectedShown(uncollectedShown)

    return tconcat(toys, ","), numToys
end

function A.UpdateToys()
    local t = MU_Account
    t.toys, t.numToys = GetToys()
end

---------------------------------------------------------------------
-- titles
---------------------------------------------------------------------
local GetNumTitles = GetNumTitles
local IsTitleKnown = IsTitleKnown

local function GetTitles()
    local titles = {}
    local numTitles = 0
    for i = 1, GetNumTitles() do
        if IsTitleKnown(i) then
            numTitles = numTitles + 1
            tinsert(titles, i)
        end
    end
    return tconcat(titles, ","), numTitles
end

---------------------------------------------------------------------
-- achievements (not available in Vanilla)
---------------------------------------------------------------------
local GetTotalAchievementPoints = GetTotalAchievementPoints
local GetLatestCompletedAchievements = GetLatestCompletedAchievements
local GetAchievementInfo = GetAchievementInfo
local GetCategoryList = GetCategoryList
local GetCategoryNumAchievements = GetCategoryNumAchievements

local function GetAchievements()
    local result = {}
    local list = GetCategoryList()
    for _, id in next, list do
        local name, parentID = GetCategoryInfo(id)
        -- 光辉事迹 81
        -- 绝版 15234
        if id == 81 or parentID == 81 or id == 15234 or parentID == 15234 then
            -- print("Found category: " .. name .. " (id: " .. id .. ")")
            local achievements = {}
            for i = 1, GetCategoryNumAchievements(id) do
                local id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe, earnedBy, isStatistic = GetAchievementInfo(id, i)
                if completed then
                    tinsert(achievements, id)
                end
            end
            tinsert(result, {category = id, achievements = tconcat(achievements, ",")})
        end
    end
    return result
end

local function GetLatestAchievements()
    local t = {}
    for _, achievementID in pairs({GetLatestCompletedAchievements()}) do
        local id, name, points, completed, month, day, year, desc, _, icon, rewardText, isGuild = GetAchievementInfo(achievementID)
        tinsert(t, {
            id = id,
            name = name,
            icon = icon,
            points = points,
            reward = rewardText,
            date = U.FormatDate(year, month, day), -- normalize to YYYY-MM-DD
        })
    end
    return t
end

function A.UpdateAchievements()
    local t = MU_Account

    t.achievementPoints = GetTotalAchievementPoints()

    if not t.achievementPoints then
        t.achievementPoints = 0
        t.latestAchievements = {}
        t.numFoSAchievements = 0
        t.numLegacyAchievements = 0
        return
    end

    local numFoSAchievements = 0
    local numLegacyAchievements = 0

    local list = GetCategoryList()
    for _, id in next, list do
        local name, parentID = GetCategoryInfo(id)
        if id == 81 or parentID == 81 then
            -- 光辉事迹 81
            local _, completed = GetCategoryNumAchievements(id)
            numFoSAchievements = numFoSAchievements + completed
        elseif id == 15234 or parentID == 15234 then
            -- 绝版 15234
            local _, completed = GetCategoryNumAchievements(id)
            numLegacyAchievements = numLegacyAchievements + completed
        end
    end

    t.numFoSAchievements = numFoSAchievements
    t.numLegacyAchievements = numLegacyAchievements
    t.latestAchievements = GetLatestAchievements()
end

---------------------------------------------------------------------
-- trading post
---------------------------------------------------------------------
if ModUs.isRetail then
    local GetCurrencyAmount = C_PerksProgram.GetCurrencyAmount

    function A.UpdateTradingPostCurrency()
        MU_Account.tradingPostCurrency = GetCurrencyAmount()
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

        -- save
        local result = {}
        for id in next, knownItems do
            tinsert(result, id)
        end
        MU_Account.tradingPostItems = table.concat(result, ",")
        -- print("Updated trading post known items: " .. MU_Account.tradingPostItems)
    end
else
    function A.UpdateTradingPostCurrency()
        -- do nothing
    end

    function A.UpdateTradingPostKnownItems()
        -- do nothing
    end
end

---------------------------------------------------------------------
-- update data
---------------------------------------------------------------------
function A.UpdateData()
    local t = MU_Account

    t.battleTagMd5, t.battleTag = U.GetBattleTag()
    t.isTrial = IsTrialAccount()
    t.titles, t.numTitles = GetTitles()
    -- A.UpdatePets()
    -- A.UpdateToys()
    A.UpdateMounts()
    -- t.achievements = GetAchievements()
    A.UpdateAchievements()

    A.UpdateTradingPostCurrency()
    A.UpdateTradingPostKnownItems()
end