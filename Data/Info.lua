---@class ModUs
local ModUs = select(2, ...)
ModUs.info = {}

---@class Info
local I = ModUs.info
local U = ModUs.utils

function I.UpdateData()
    MU_InfoA = {
        flavor = U.GetClientMappingVersion(),
        region = GetCVar("portal"),
        addonVersion = tonumber(C_AddOns.GetAddOnMetadata("ModUs", "Version"):sub(2)),
        -- updateTime = time(),
    }
    MU_InfoC = MU_InfoA
end

function I.RefreshUpdateTime()
    MU_InfoA.updateTime = time()
    MU_InfoC.updateTime = MU_InfoA.updateTime
end