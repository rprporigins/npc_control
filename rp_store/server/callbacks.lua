-- store_callbacks.lua
-- Server-side Lua script for FiveM to handle Ox-Lib callbacks for rprp_store_items
local storeItems = require('server.db')
-- Register callback to create a new item
lib.callback.register('rp_store:server:createItem', function(source, data)
    -- Optional: Add permission check (e.g., for admins only)
    -- if not IsPlayerAceAllowed(source, 'rprp_store.admin') then
    --     return {success = false, error = 'Insufficient permissions'}
    -- end
    print(json.encode(data))
    -- Validate input data (storeItems.Create already validates, but can add more here if needed)
    if not data or not data.itemHash then
        return {success = false, error = 'Invalid input data'}
    end

    -- Call storeItems.Create
    local result = storeItems.Create({
        itemHash = data.itemHash,
        itemDesc = data.itemDesc,
        priceR = data.priceR,
        priceC = data.priceC,
        imgUrl = data.imgUrl,
        info = data.info,
        category = data.category,
        perma = data.perma
    })

    return result -- {success, itemHash or error}
end)

-- Register callback to get an item by itemHash
lib.callback.register('rp_store:server:getItem', function(source, itemHash)
    -- Optional: Add permission check if needed
    -- if not IsPlayerAceAllowed(source, 'rprp_store.view') then
    --     return {success = false, error = 'Insufficient permissions'}
    -- end

    if not itemHash or type(itemHash) ~= 'string' then
        return {success = false, error = 'Invalid itemHash'}
    end

    -- Call storeItems.Get
    local result = storeItems.Get(itemHash)

    return result -- {success, item or error}
end)

-- Register callback to get all items
lib.callback.register('rp_store:server:getAllItems', function(source)
    -- Optional: Add permission check if needed
    -- if not IsPlayerAceAllowed(source, 'rprp_store.view') then
    --     return {success = false, error = 'Insufficient permissions'}
    -- end

    -- Call storeItems.GetAll
    local result = storeItems.GetAll()
    print('result', result)

    return result -- {success, items or error}
end)