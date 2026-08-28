---@class ModUs
local ModUs = select(2, ...)

---@class ModUs
---@field utils Utils
---@field info Info
---@field realm Realm
---@field character Character
---@field account Account
---@field guild Guild
---@field population Population
---@field token Token
---@field blackMarket BlackMarket

local I = ModUs.info
local U = ModUs.utils
local R = ModUs.realm
local C = ModUs.character
local A = ModUs.account
local G = ModUs.guild
local P = ModUs.population
local T = ModUs.token
local B = ModUs.blackMarket

---------------------------------------------------------------------
-- event handler
---------------------------------------------------------------------
local handler = CreateFrame("Frame")
handler:RegisterEvent("ADDON_LOADED")
handler:SetScript("OnEvent", function(self, event, ...)
    self[event](self, ...)
end)

---------------------------------------------------------------------
-- ADDON_LOADED
---------------------------------------------------------------------
function handler:ADDON_LOADED(name)
    if name == "ModUs" then
        self:UnregisterEvent("ADDON_LOADED")

        self:RegisterEvent("PLAYER_LOGIN")
        self:RegisterEvent("PLAYER_LOGOUT")
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        self:RegisterEvent("PLAYER_TARGET_CHANGED")
        self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
        self:RegisterEvent("UPDATE_INSTANCE_INFO")
        if C_BlackMarket then
            self:RegisterEvent("BLACK_MARKET_ITEM_UPDATE")
        end

        -- 清除旧数据
        MU_InfoA = nil
        MU_InfoC = nil
        MU_Realm = nil
        MU_Character = {}
        MU_Account = {}
        MU_Guild = {}
        MU_Population = {}
        MU_Token = {}
        MU_BlackMarket = {}

        -- token
        if C_WowTokenPublic.GetCommerceSystemStatus() then
            T.StartTokenTimer()
        end
    end
end

---------------------------------------------------------------------
-- PLAYER_LOGIN
---------------------------------------------------------------------
function handler:PLAYER_LOGIN()
    -- info
    I.UpdateData()
    -- realm
    R.UpdateData()
end

---------------------------------------------------------------------
-- PLAYER_LOGOUT
---------------------------------------------------------------------
function handler:PLAYER_LOGOUT()
    -- whole data update time
    I.RefreshUpdateTime()
end

---------------------------------------------------------------------
-- PLAYER_REGEN_ENABLED
---------------------------------------------------------------------
local retries = {}
function handler:PLAYER_REGEN_ENABLED()
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")

    for func, value in next, retries do
        func(self, value)
    end

    wipe(retries)
end

---------------------------------------------------------------------
-- PLAYER_ENTERING_WORLD
---------------------------------------------------------------------
function handler:PLAYER_ENTERING_WORLD()
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")

    if InCombatLockdown() then
        retries[self.PLAYER_ENTERING_WORLD] = true
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end

    retries[self.PLAYER_ENTERING_WORLD] = nil

    -- account
    A.UpdateData()

    -- guild
    if IsInGuild() then
        C_Timer.After(5, function()
            C_GuildInfo.GuildRoster()
        end)
    end

    -- population
    P.SaveUnitData("player")
    if IsInGroup() then
        handler:GROUP_ROSTER_UPDATE()
    end

    self:RegisterEvent("GUILD_ROSTER_UPDATE")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    self:RegisterEvent("ACHIEVEMENT_EARNED")
    self:RegisterEvent("FIRST_FRAME_RENDERED")

    if ModUs.isRetail then
        self:RegisterEvent("TRAIT_CONFIG_UPDATED")
        self:RegisterEvent("PERKS_PROGRAM_CURRENCY_REFRESH")
        self:RegisterEvent("PERKS_PROGRAM_DATA_REFRESH")
        self:RegisterEvent("PERKS_PROGRAM_PURCHASE_SUCCESS")
        self:RegisterEvent("PERKS_PROGRAM_REFUND_SUCCESS")
    else
        -- TODO:
    end
end

---------------------------------------------------------------------
-- PLAYER_EQUIPMENT_CHANGED
---------------------------------------------------------------------
function handler:PLAYER_EQUIPMENT_CHANGED(slot)
    C.UpdateEquipmentSlot(slot)
end

---------------------------------------------------------------------
-- UPDATE_INSTANCE_INFO
---------------------------------------------------------------------
function handler:UPDATE_INSTANCE_INFO()
    C.UpdateSavedInstances()
end

---------------------------------------------------------------------
-- talents changed
---------------------------------------------------------------------
function handler:TRAIT_CONFIG_UPDATED()
    C.UpdateTalents()
end

---------------------------------------------------------------------
-- ACHIEVEMENT_EARNED
---------------------------------------------------------------------
function handler:ACHIEVEMENT_EARNED(achievementID)
    A.UpdateAchievements()
end

---------------------------------------------------------------------
-- trading post
---------------------------------------------------------------------
function handler:PERKS_PROGRAM_CURRENCY_REFRESH()
    A.UpdateTradingPostCurrency()
end

function handler:PERKS_PROGRAM_DATA_REFRESH()
    A.UpdateTradingPostKnownItems()
end

handler.PERKS_PROGRAM_PURCHASE_SUCCESS = handler.PERKS_PROGRAM_DATA_REFRESH
handler.PERKS_PROGRAM_REFUND_SUCCESS = handler.PERKS_PROGRAM_DATA_REFRESH

---------------------------------------------------------------------
-- GUILD_ROSTER_UPDATE
---------------------------------------------------------------------
function handler:GUILD_ROSTER_UPDATE()
    if InCombatLockdown() then
        retries[self.GUILD_ROSTER_UPDATE] = true
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end

    retries[self.GUILD_ROSTER_UPDATE] = nil

    G.UpdateData()
    MU_Character.guildName = GetGuildInfo("player")
end

---------------------------------------------------------------------
-- PLAYER_TARGET_CHANGED
---------------------------------------------------------------------
function handler:PLAYER_TARGET_CHANGED()
    P.SaveUnitData("target")
end

---------------------------------------------------------------------
-- UPDATE_MOUSEOVER_UNIT
---------------------------------------------------------------------
function handler:UPDATE_MOUSEOVER_UNIT()
    P.SaveUnitData("mouseover")
end

---------------------------------------------------------------------
-- GROUP_ROSTER_UPDATE
---------------------------------------------------------------------
local timer
function handler:GROUP_ROSTER_UPDATE(immediate)
    if timer then
        timer:Cancel()
        timer = nil
    end

    if immediate then
        if InCombatLockdown() then
            retries[self.GROUP_ROSTER_UPDATE] = true
            handler:RegisterEvent("PLAYER_REGEN_ENABLED")
            return
        end
        retries[self.GROUP_ROSTER_UPDATE] = nil
        handler:UnregisterEvent("GROUP_ROSTER_UPDATE")

        P.SaveGroupData()

    else
        timer = C_Timer.NewTimer(5, function()
            timer = nil
            handler:GROUP_ROSTER_UPDATE(true)
        end)
    end
end

---------------------------------------------------------------------
-- pet
---------------------------------------------------------------------
function handler:NEW_PET_ADDED()
    handler:UnregisterEvent("NEW_PET_ADDED")
    A.UpdatePets()
end

---------------------------------------------------------------------
-- toy
---------------------------------------------------------------------
function handler:NEW_TOY_ADDED()
    handler:UnregisterEvent("NEW_TOY_ADDED")
    A.UpdateToys()
end

---------------------------------------------------------------------
-- mount
---------------------------------------------------------------------
function handler:NEW_MOUNT_ADDED()
    handler:UnregisterEvent("NEW_MOUNT_ADDED")
    A.UpdateMounts()
end

---------------------------------------------------------------------
-- FIRST_FRAME_RENDERED
---------------------------------------------------------------------
function handler:FIRST_FRAME_RENDERED()
    handler:UnregisterEvent("FIRST_FRAME_RENDERED")

    self:RegisterEvent("NEW_PET_ADDED")
    self:RegisterEvent("NEW_TOY_ADDED")
    self:RegisterEvent("NEW_MOUNT_ADDED")

    C_Timer.After(1, function()
        C.UpdateData()
        A.UpdatePets()
        A.UpdateToys()
    end)
end

---------------------------------------------------------------------
-- BLACK_MARKET_ITEM_UPDATE
---------------------------------------------------------------------
local timer2
function handler:BLACK_MARKET_ITEM_UPDATE()
    if timer2 then
        timer2:Cancel()
        timer2 = nil
    end

    timer2 = C_Timer.NewTimer(1, function()
        timer2 = nil
        B.UpdateBlackMarket()
    end)
end