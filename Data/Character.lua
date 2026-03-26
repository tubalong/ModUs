---@class ModUs
local ModUs = select(2, ...)
ModUs.character = {}

---@class Character
local C = ModUs.character
local U = ModUs.utils

local GetProfessions = GetProfessions
local GetProfessionInfo = GetProfessionInfo
local tconcat = table.concat

---------------------------------------------------------------------
-- profession names
---------------------------------------------------------------------
local porfNames = {
    -- [129] = "first_aid",
    [164] = "blacksmithing", -- 锻造
    [165] = "leatherworking", -- 制皮
    [171] = "alchemy", -- 炼金术
    [182] = "herbalism", -- 草药学
    -- [184] = "cooking",
    [186] = "mining", -- 采矿
    [197] = "tailoring", -- 裁缝
    [202] = "engineering", -- 工程学
    [333] = "enchanting", -- 附魔
    -- [356] = "fishing",
    [393] = "skinning", -- 剥皮
    [755] = "jewelcrafting", -- 珠宝加工
    [773] = "inscription", -- 铭文
    -- [794] = "archaeology"
}

---------------------------------------------------------------------
-- profession
---------------------------------------------------------------------
local function GetProfessionStr()
    if not (GetProfessions and GetProfessionInfo) then
        -- TODO: WotLK: GetNumSkillLines & GetSkillLineInfo
        return nil
    end

    local prof1, prof2 = GetProfessions()
    local professions = {}
    local _, skillLevel, skillLine

    if prof1 then
        -- name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier, specializationIndex, specializationOffset
        _, _, skillLevel, _, _, _, skillLine = GetProfessionInfo(prof1)
        if porfNames[skillLine] then
            tinsert(professions, porfNames[skillLine] .. "=" .. skillLevel)
        end
    end

    if prof2 then
        _, _, skillLevel, _, _, _, skillLine = GetProfessionInfo(prof2)
        if porfNames[skillLine] then
            tinsert(professions, porfNames[skillLine] .. "=" .. skillLevel)
        end
    end

    return tconcat(professions, "/")
end

---------------------------------------------------------------------
-- talents
---------------------------------------------------------------------
local GetTalentStr

if ModUs.isRetail then
    -- Blizzard_ClassTalentImportExport.lua
    local bitWidthHeaderVersion = 8
    local bitWidthSpecID = 16
    local bitWidthRanksPurchased = 6

    local function WriteLoadoutHeader(exportStream, serializationVersion, specID, treeHash)
        exportStream:AddValue(bitWidthHeaderVersion, serializationVersion)
        exportStream:AddValue(bitWidthSpecID, specID)
        -- treeHash is a 128bit hash, passed as an array of 16, 8-bit values
        for i, hashVal in ipairs(treeHash) do
            exportStream:AddValue(8, hashVal)
        end
    end

    local function GetActiveEntryIndex(treeNode)
        for i, entryID in ipairs(treeNode.entryIDs) do
            if(entryID == treeNode.activeEntry.entryID) then
                return i
            end
        end
        return 0
    end


    local function WriteLoadoutContent(exportStream, configID, treeID)
        local treeNodes = C_Traits.GetTreeNodes(treeID)
        for i, treeNodeID in ipairs(treeNodes) do
            local treeNode = C_Traits.GetNodeInfo(configID, treeNodeID)

            local isNodeGranted = treeNode.activeRank - treeNode.ranksPurchased > 0
            local isNodePurchased = treeNode.ranksPurchased > 0
            local isNodeSelected = isNodeGranted or isNodePurchased
            local isPartiallyRanked = treeNode.ranksPurchased ~= treeNode.maxRanks
            local isChoiceNode = treeNode.type == Enum.TraitNodeType.Selection or treeNode.type == Enum.TraitNodeType.SubTreeSelection

            exportStream:AddValue(1, isNodeSelected and 1 or 0)
            if(isNodeSelected) then
                exportStream:AddValue(1, isNodePurchased and 1 or 0)

                if isNodePurchased then
                    exportStream:AddValue(1, isPartiallyRanked and 1 or 0)
                    if(isPartiallyRanked) then
                        exportStream:AddValue(bitWidthRanksPurchased, treeNode.ranksPurchased)
                    end

                    exportStream:AddValue(1, isChoiceNode and 1 or 0)
                    if(isChoiceNode) then
                        local entryIndex = GetActiveEntryIndex(treeNode)
                        if(entryIndex <= 0 or entryIndex > 4) then
                            error("Error exporting tree node " .. treeNode.ID .. ". The active choice node entry index (" .. entryIndex .. ") is out of bounds. ")
                        end
                        -- store entry index as zero-index
                        exportStream:AddValue(2, entryIndex - 1)
                    end
                end
            end
        end
    end

    local function GetTalentsByID(specID, configID)
        if not configID then return end
        local exportStream = ExportUtil.MakeExportDataStream()
        local configInfo = C_Traits.GetConfigInfo(configID)
        local treeID = configInfo.treeIDs[1]
        local treeHash = C_Traits.GetTreeHash(treeID)
        local serializationVersion = C_Traits.GetLoadoutSerializationVersion()
        WriteLoadoutHeader(exportStream, serializationVersion, specID, treeHash)
        WriteLoadoutContent(exportStream, configID, treeID)
        return exportStream:GetExportString()
    end

    GetTalentStr = function()
        local specID = PlayerUtil.GetCurrentSpecID()

        -- active
        local activeConfigID = C_ClassTalents.GetActiveConfigID()
        return GetTalentsByID(specID, activeConfigID)

        -- all
        -- local configs = C_ClassTalents.GetConfigIDsBySpecID(specID)
        -- for _, configID in pairs(configs) do
        --     GetTalentsByID(specID, configID)
        -- end
    end

else
    GetTalentStr = function()
        -- TODO:
        return nil
    end
end

function C.UpdateTalents()
    MU_Character.talents = GetTalentStr()
end

---------------------------------------------------------------------
-- Equipments
---------------------------------------------------------------------
-- https://warcraft.wiki.gg/wiki/InventorySlotId
local INV_SLOT_NAME = {
    [INVSLOT_HEAD] = "head",
    [INVSLOT_NECK] = "neck",
    [INVSLOT_SHOULDER] = "shoulders",
    [INVSLOT_BODY] = "shirt",
    [INVSLOT_CHEST] = "chest",
    [INVSLOT_WAIST] = "waist",
    [INVSLOT_LEGS] = "legs",
    [INVSLOT_FEET] = "feet",
    [INVSLOT_WRIST] = "wrist",
    [INVSLOT_HAND] = "hands",
    [INVSLOT_FINGER1] = "finger1",
    [INVSLOT_FINGER2] = "finger2",
    [INVSLOT_TRINKET1] = "trinket1",
    [INVSLOT_TRINKET2] = "trinket2",
    [INVSLOT_BACK] = "back",
    [INVSLOT_MAINHAND] = "main_hand",
    [INVSLOT_OFFHAND] = "off_hand",
    [INVSLOT_TABARD] = "tabard",
}

if ModUs.isVanilla or ModUs.isWrath then
    INV_SLOT_NAME[INVSLOT_AMMO] = "ammo"
    INV_SLOT_NAME[INVSLOT_RANGED] = "ranged"
end

local GetInventoryItemLink = GetInventoryItemLink
local GetItemName = C_Item.GetItemName
local GetItemCraftedQualityByItemInfo = C_TradeSkillUI and C_TradeSkillUI.GetItemCraftedQualityByItemInfo
local GetItemStats = GetItemStats or C_Item.GetItemStats
local GetDetailedItemLevelInfo = GetDetailedItemLevelInfo or C_Item.GetDetailedItemLevelInfo

local ID_INDEX = 1
local ENCHANT_INDEX = 2
local GEM_INDEX_START, GEM_INDEX_END = 3, 6
local SUFFIX_INDEX = 7
-- local SPEC_INDEX = 10
local CONTEXT_INDEX = 12
local BONUS_INDEX = 13
local CRAFTING_STAT_1 = Enum.ItemModification.ChangeModifiedCraftingStat_1
local CRAFTING_STAT_2 = Enum.ItemModification.ChangeModifiedCraftingStat_2

local function FillItemInfo(item, t)
    item:ContinueOnItemLoad(function()
        t.name = item:GetItemName()
        t.icon = item:GetItemIcon()
        t.quality = item:GetItemQuality()
    end)
end

local function ExtractEquipmentData(slot)
    local data = {}
    local link = GetInventoryItemLink("player", slot)

    if link then
        -- print(string.gsub(link, "\124", "\124\124"))
        -- print(string.match(link, "item[%-?%d:]+"))

        local str = strmatch(link, "|Hitem:(.+)|h.+|h")
        -- local str, name = strmatch(link, "|Hitem:(.+)|h%[([^|]+).*%]|h")
        -- data.name = strtrim(name) -- not always available

        local t = {strsplit(":", str)}
        for k, v in pairs(t) do
            if v == "" then
                t[k] = nil
            else
                t[k] = tonumber(v)
            end
        end

        -- slot
        data.slot = INV_SLOT_NAME[slot]

        -- id
        data.id = t[ID_INDEX]

        -- enchant
        data.enchant = t[ENCHANT_INDEX]

        -- gems
        local gems = {}
        for k = GEM_INDEX_START, GEM_INDEX_END do
            if t[k] then
                tinsert(gems, t[k])
            end
        end
        data.gems = tconcat(gems, ",")

        -- suffix
        data.suffix = t[SUFFIX_INDEX]

        -- context (source)
        data.context = t[CONTEXT_INDEX]

        -- bonuses
        local bonuses = {}
        local numBonusIDs = t[BONUS_INDEX]
        if numBonusIDs then
            local bonusIndex = BONUS_INDEX + 1
            for i = 1, numBonusIDs do
                tinsert(bonuses, t[bonusIndex])
                bonusIndex = bonusIndex + 1
            end
        end
        data.bonuses = tconcat(bonuses, ",")

        -- modifiers
        data.modifiers = {}
        local modifierIndex = BONUS_INDEX + (numBonusIDs or 0) + 1
        local numModifiers = t[modifierIndex]
        if numModifiers then
            local modifierKeyIndex = modifierIndex + 1
            for i = 1, numModifiers do
                data.modifiers[t[modifierKeyIndex]] = t[modifierKeyIndex + 1]
                modifierKeyIndex = modifierKeyIndex + 2
            end
        end

        -- simc
        data.simc = data.slot .. "=,id=" .. data.id
        if data.enchant then
            data.simc = data.simc .. ",enchant_id=" .. data.enchant
        end
        if #gems ~= 0 then
            data.simc = data.simc .. ",gem_id=" .. tconcat(gems, "/")
        end
        if #bonuses ~= 0 then
            data.simc = data.simc .. ",bonus_id=" .. tconcat(bonuses, "/")
        end

        if ModUs.isRetail then
            -- craftedStats
            local craftedStats = {}
            if data.modifiers[CRAFTING_STAT_1] then
                tinsert(craftedStats, data.modifiers[CRAFTING_STAT_1])
            end
            if data.modifiers[CRAFTING_STAT_2] then
                tinsert(craftedStats, data.modifiers[CRAFTING_STAT_2])
            end
            data.craftedStats = tconcat(craftedStats, ",")

            -- crafted quality
            data.craftedQuality = GetItemCraftedQualityByItemInfo(link)

            -- simc
            if #craftedStats ~= 0 then
                data.simc = data.simc .. ",crafted_stats=" .. tconcat(craftedStats, "/")
            end
            if data.craftedQuality then
                data.simc = data.simc .. ",crafting_quality=" .. data.craftedQuality
            end
        end

        -- stats
        data.stats = GetItemStats(link)

        -- level
        data.level = GetDetailedItemLevelInfo(link)

        -- name, icon, quality
        FillItemInfo(Item:CreateFromEquipmentSlot(slot), data)

        if not data.level then
            return data, false
        end
    end

    return data, true
end

local function UpdateAllEquipmentSlots()
    local success
    for id in pairs(INV_SLOT_NAME) do
        MU_Character.equipments[INV_SLOT_NAME[id]], success = ExtractEquipmentData(id)
        if not success then
            C_Timer.After(5, function()
                C.UpdateEquipmentSlot(id)
            end)
        end
    end
end

function C.UpdateEquipmentSlot(slot)
    local success
    if INV_SLOT_NAME[slot] then
        MU_Character.equipments[INV_SLOT_NAME[slot]], success = ExtractEquipmentData(slot)
        if not success then
            C_Timer.After(5, function()
                C.UpdateEquipmentSlot(slot)
            end)
        end
    end
end

---------------------------------------------------------------------
-- saved instances
---------------------------------------------------------------------
local GetNumSavedInstances = GetNumSavedInstances
local GetSavedInstanceInfo = GetSavedInstanceInfo
local GetSavedInstanceEncounterInfo = GetSavedInstanceEncounterInfo

local function GetSavedInstances()
    local savedInstances = {}
    for i = 1, GetNumSavedInstances() do
        -- name, lockoutId, reset, difficultyId, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName, numEncounters, encounterProgress, extendDisabled, instanceId
        local name, lockoutId, reset, difficulty, locked, extended, _, _, _, difficultyName, numEncounters = GetSavedInstanceInfo(i)
        if name and (locked or extended) then
            -- instance
            local t = {
                name = name,
                difficulty = difficultyName,
                lockoutID = lockoutId,
                time = time() + reset,
            }

            -- bosses
            t.bosses = {}
            if numEncounters then
                for j = 1, numEncounters do
                    local bossName, _, isKilled = GetSavedInstanceEncounterInfo(i, j)
                    tinsert(t.bosses, {bossName, isKilled})
                end
            end

            tinsert(savedInstances, t)
        end
    end
    return savedInstances
end

function C.UpdateSavedInstances()
    MU_Character.savedInstances = GetSavedInstances()
end

---------------------------------------------------------------------
-- watched addons
---------------------------------------------------------------------
local GetAddOnMetadata = C_AddOns.GetAddOnMetadata
local IsAddOnLoaded = C_AddOns.IsAddOnLoaded

local WATCHED_ADDONS = {
    "ModUs",
    "BFInfinite",
}

function GetWatchedAddons()
    local data = {}

    for _, name in next, WATCHED_ADDONS do
        if IsAddOnLoaded(name) then
            local info = name .. "=" .. GetAddOnMetadata(name, "Version")
            tinsert(data, info)
        end
    end

    return tconcat(data, ";")
end

---------------------------------------------------------------------
-- update data
---------------------------------------------------------------------
function C.UpdateData()
    if ModUs.isRetail and C_ClassTrial.IsClassTrialCharacter() then
        return
    end

    local t = MU_Character

    t.battleTagMd5 = U.GetBattleTag()
    t.fullName = U.UnitFullName("player")
    t.realmID = GetRealmID()
    t.guid = UnitGUID("player")
    t.avgItemLevelEquipped = select(2, GetAverageItemLevel())
    t.faction = UnitFactionGroup("player")
    t.level = UnitLevel("player")
    t.gender = UnitSex("player")
    t.raceID = select(3, UnitRace("player"))
    t.classID = select(2, UnitClassBase("player"))
    t.money = GetMoney()
    if ModUs.isRetail or ModUs.isMists then
        t.specID = PlayerUtil.GetCurrentSpecID() -- GetSpecializationInfo(GetSpecialization())
    end
    t.titleID = GetCurrentTitle()
    t.gameVersion = GetBuildInfo()

    t.professions = GetProfessionStr()
    t.talents = GetTalentStr()
    t.savedInstances = GetSavedInstances()

    t.equipments = {}
    UpdateAllEquipmentSlots()

    if IsInGuild() then
        t.guildName = GetGuildInfo("player")
        t.guildName, t.guildRankName, t.guildRankIndex, t.guildRealm = GetGuildInfo("player")
        if t.guildRealm then
            t.guildRealm = U.RemoveRealmSuffix(t.guildRealm)
        else
            t.guildRealm = U.GetNormalizedRealmName()
        end
    end

    t.watchedAddons = GetWatchedAddons()
end