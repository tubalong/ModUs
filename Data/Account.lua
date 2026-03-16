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
        tinsert(pets, id)
    end
    return tconcat(pets, ","), owned
end

---------------------------------------------------------------------
-- toys
---------------------------------------------------------------------
local SetAllExpansionTypeFilters = C_ToyBox.SetAllExpansionTypeFilters
local SetAllSourceTypeFilters = C_ToyBox.SetAllSourceTypeFilters
local SetCollectedShown = C_ToyBox.SetCollectedShown
local SetUncollectedShown = C_ToyBox.SetUncollectedShown
local GetUncollectedShown = C_ToyBox.GetUncollectedShown

local function GetToys()
    SetAllExpansionTypeFilters(true)
    SetAllSourceTypeFilters(true)
    SetCollectedShown(true)

    local uncollectedShown = GetUncollectedShown()
    SetUncollectedShown(false)

    local toys = {}
    local numToys = 0
    for i = 1, C_ToyBox.GetNumLearnedDisplayedToys() do
        local id = C_ToyBox.GetToyFromIndex(i)
        if id then
            numToys = numToys + 1
            tinsert(toys, id)
        end
    end

    -- restore
    SetUncollectedShown(uncollectedShown)

    return tconcat(toys, ","), numToys
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

    t.battleTagMd5, t.battleTag = U.GetBattleTag()
    t.isTrial = IsTrialAccount()
    t.mounts, t.numMounts = GetMounts()
    t.pets, t.numPets = GetPets()
    t.titles, t.numTitles = GetTitles()
    t.toys, t.numToys = GetToys()
    t.achievements = GetAchievements()
    t.latestAchievements = GetLatestAchievements()
    t.achievementPoints = GetTotalAchievementPoints()

    t.tradingPost = {}
    A.UpdateTradingPostCurrency()
end