---@class ModUs
local ModUs = select(2, ...)
ModUs.blackMarket = {}

---@class BlackMarket
local B = ModUs.blackMarket

local GetHotItem = C_BlackMarket.GetHotItem
local GetNumItems = C_BlackMarket.GetNumItems
local GetItemInfoByIndex = C_BlackMarket.GetItemInfoByIndex
local GetItemInfoInstant = C_Item.GetItemInfoInstant

-- AUCTION_TIME_LEFT0          完成！
-- AUCTION_TIME_LEFT0_DETAIL   拍卖已结束。
-- AUCTION_TIME_LEFT1          短
-- AUCTION_TIME_LEFT1_DETAIL   少于30分钟
-- AUCTION_TIME_LEFT2          中
-- AUCTION_TIME_LEFT2_DETAIL   30分钟到2小时
-- AUCTION_TIME_LEFT3          长
-- AUCTION_TIME_LEFT3_DETAIL   2小时到12小时
-- AUCTION_TIME_LEFT4          非常长
-- AUCTION_TIME_LEFT4_DETAIL   大于12小时

function B.UpdateBlackMarket()
    wipe(MU_BlackMarket)

    local numItems = GetNumItems()
    if not numItems or numItems == 0 then
        return
    end

    for i = 1, numItems do
        local name, texture, quantity, itemType, usable, level, levelType, sellerName, minBid, minIncrement, currBid, youHaveHighBid, numBids, timeLeft, link, marketID, quality = GetItemInfoByIndex(i)
        local itemID, _, _, _, _, classID, subclassID = GetItemInfoInstant(link)

        tinsert(MU_BlackMarket, {
            itemID = itemID,
            classID = classID,
            subclassID = subclassID,
            itemName = name,
            itemIcon = texture,
            itemType = itemType,
            itemQuality = quality,
            numBids = numBids,
            currentBid = currBid,
            timeLeft = timeLeft,
        })
    end
end