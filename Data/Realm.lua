---@class ModUs
local ModUs = select(2, ...)
ModUs.realm = {}

---@class Realm
local R = ModUs.realm
local U = ModUs.utils

function R.UpdateData()
    local connectedRealms = GetAutoCompleteRealms()
    if #connectedRealms == 0 then
        tinsert(connectedRealms, GetNormalizedRealmName())
    end
    for i, realm in next, connectedRealms do
        connectedRealms[i] = U.RemoveRealmSuffix(realm)
    end

    MU_Realm = {
        id = GetRealmID(), -- 服务器ID
        name = U.GetRealmName(), -- 服务器名
        normalizedName = U.GetNormalizedRealmName(), -- 标准化服务器名
        connectedRealms = table.concat(connectedRealms, ","), -- 大服务器（标准化）
    }
end