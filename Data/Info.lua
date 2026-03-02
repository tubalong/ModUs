---@class ModUs
local ModUs = select(2, ...)
ModUs.info = {}

---@class Info
local I = ModUs.info
local U = ModUs.utils

function I.UpdateData()
    MU_Info = {
        flavor = U.GetClientMappingVersion(),
        region = GetCVar("portal"),
        addonVersion = C_AddOns.GetAddOnMetadata("ModUs", "Version"),
        -- updateTime = time(),
    }
end

function I.RefreshUpdateTime()
    MU_Info.updateTime = time()
end