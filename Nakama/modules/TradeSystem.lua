local nk = require("nakama")

function addItemToInventory(context, payload)
    local userID = context.user_id
    local itemData = nk.json_decode(payload)
    local itemID = nk.uuid_v4()

    local item = {
        id = itemID,
        name = itemData.name,
        type = itemData.type,
        rarity = itemData.rarity
    }

    local storageObject = {
        collection = "inventory",
        key = itemID,
        user_id = userID,
        value = item
    }

    nk.storage_write({storageObject})

    return nk.json_encode({itemID = itemID})
end

function getInventory(context, payload)
    local userID = context.user_id
    local data = nk.json_decode(payload)

    local results = nk.storage_list(data.id, "inventory", 100, nil)
    local inventory = {}

    for _, obj in ipairs(results) do
        table.insert(inventory, obj.value)
    end

    return nk.json_encode(inventory)
end

function createTradeOffer(context, payload)
    local userID = context.user_id
    local data = nk.json_decode(payload)
    local offerID = nk.uuid_v4()
    
    local tradeOffer = {
        offerid = offerID,
        senderid = userID,
        recieverid = data.recieverid,
        offerItems = data.offerItems,
        requestedItems = data.requestedItems,
        status = "pending"
    }

    local storageObject = {
        collection = "tradeOffers",
        key = offerID,
        user_id = data.recieverid,
        value = tradeOffer
    }

    nk.storage_write({storageObject})


    storageObject = {
        collection = "tradeOffers",
        key = offerID,
        user_id = userID,
        value = tradeOffer
    }

    nk.storage_write({storageObject})

    return nk.json_encode({ offerID = offerID })

end

function acceptTradeOffer(context, payload)
    local userID = context.user_id
    local data = nk.json_decode(payload)
    local offerID = data.offerID

    if not offerID then
        error("offer id is required")
    end

    local result = nk.storage_read({
        { collection = "tradeOffers", key = offerID, user_id = userID }
    })

    if #result == 0 then
        error("invalid trade offer or processed already.")
    end

    local tradeOffer = result[1].value
    local senderid = tradeOffer.senderid
    local recieverid = tradeOffer.recieverid

    if tradeOffer.status ~= "pending" then
        error("Trade offer is not pending.")
    end

    if tradeOffer.recieverid ~= userID then
        error("Trade offer cannot be accepted by sender")
    end

    local function transferItem(itemID, fromUserID, toUserID)
        nk.logger_info("Tranfer Item id: " .. tostring(itemID))
        nk.logger_info("From user id: " .. tostring(fromUserID))
        nk.logger_info("to user id: " .. tostring(toUserID))

        if not itemID or type(itemID) ~= "string" then
            error("Item id must be a valid string")
        end

        if not fromUserID or type(fromUserID) ~= "string" then
            error("From user id must be a valid string")
        end

        if not toUserID or type(toUserID) ~= "string" then
            error("To user id must be a valid string")
        end

        local itemResult = nk.storage_read({
            {collection = "inventory", key = itemID, user_id = fromUserID}
        })

        if #itemResult == 0 then
            error("Item not found in senders inventory")
        end

        local itemData = itemResult[1].value

        nk.storage_delete({
            {collection = "inventory", key = itemID, user_id = fromUserID}
        })

        local storageObject = {
            collection = "inventory",
            key = itemID,
            user_id = toUserID,
            value = itemData
        }

        nk.storage_write({storageObject})
        end

    for _, item in ipairs(tradeOffer.offerItems) do
        transferItem(item.id, senderid, recieverid)
    end

    for _, item in ipairs(tradeOffer.requestedItems) do
        transferItem(item.id, recieverid, senderid)
    end

    tradeOffer.status = "accepted"
    nk.storage_write({{collection = "tradeOffers", key = offerID, user_id = userID, value = tradeOffer}})

    nk.storage_write({{collection = "tradeOffers", key = offerID, user_id = tradeOffer.senderid, value = tradeOffer}})
    
    return nk.json_encode({result = "Trader Offer Accepted"})
end
 
function getTradeOffers(context, payload)
    local userID = context.user_id
    local data = nk.json_decode(payload)

    local results = nk.storage_list(userID, "tradeOffers", 100, nil)
    local tradeOffers = {}

    if results and #results > 0 then
        for _, obj in ipairs(results) do
            if obj.value.status == "pending" then
                table.insert(tradeOffers, obj.value)
            end
        end
    else
        nk.logger_info("No trade offers found for user: " .. userID)
    end
   

    return nk.json_encode(tradeOffers)
end

function cancelTradeOffer(context, payload)
    local userID = context.user_id
    local data = nk.json_decode(payload)
    local offerID = data.offerID

    if not offerID then
        error("offer id is required")
    end

    local result = nk.storage_read({
        { collection = "tradeOffers", key = offerID, user_id = userID }
    })

    if #result == 0 then
        error("invalid trade offer or processed already.")
    end

    local tradeOffer = result[1].value
    local senderid = tradeOffer.senderid
    local recieverid = tradeOffer.recieverid

    if tradeOffer.status ~= "pending" then
        error("Trade offer is not pending.")
    end

    tradeOffer.status = "canceled"
    nk.storage_write({{collection = "tradeOffers", key = offerID, user_id = userID, value = tradeOffer}})

    nk.storage_write({{collection = "tradeOffers", key = offerID, user_id = tradeOffer.recieverid, value = tradeOffer}})
    return nk.json_encode({result = "Trader Offer Canceled"})
end

nk.register_rpc(addItemToInventory, "addItemToInventory")
nk.register_rpc(getInventory, "getInventory")
nk.register_rpc(createTradeOffer, "createTradeOffer")
nk.register_rpc(acceptTradeOffer, "acceptTradeOffer")
nk.register_rpc(getTradeOffers, "getTradeOffers")
nk.register_rpc(cancelTradeOffer, "cancelTradeOffer")