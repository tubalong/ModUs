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

local I = ModUs.info
local U = ModUs.utils
local R = ModUs.realm
local C = ModUs.character
local A = ModUs.account
local G = ModUs.guild
local P = ModUs.population
local T = ModUs.token

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

        -- 清除旧数据
        MU_Info = nil
        MU_Realm = nil
        MU_Charater = {}
        MU_Account = {}
        MU_Guild = {}
        MU_Population = {}
        MU_Token = {}

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
    I.RefreshUpdateTime()
    -- trading post known items
    A.SaveTradingPostKnownItems()
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

    -- character
    C.UpdateData()

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
    self:RegisterEvent("UPDATE_INSTANCE_INFO")
    self:RegisterEvent("ACHIEVEMENT_EARNED")

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
end

---------------------------------------------------------------------
-- PLAYER_TARGET_CHANGED
---------------------------------------------------------------------
function handler:PLAYER_TARGET_CHANGED()
    P.SaveUnitData("target")
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
            frame:RegisterEvent("PLAYER_REGEN_ENABLED")
            return
        end
        retries[self.GROUP_ROSTER_UPDATE] = nil
        frame:UnregisterEvent("GROUP_ROSTER_UPDATE")

        P.SaveGroupData()

    else -- 5秒内队伍成员没变化才进行遍历操作
        timer = C_Timer.NewTimer(5, function()
            timer = nil
            frame:GROUP_ROSTER_UPDATE(true)
        end)
    end
end