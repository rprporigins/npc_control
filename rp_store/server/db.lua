local StoreItems = {}

-- Create a new item
-- @param data table: {itemHash, itemDesc, priceR, priceC, imgUrl, info, category, perma}
-- @return table: {success, itemHash or error}
function StoreItems.Create(data)    
    -- Validate required fields
    if not data.itemHash then
        return { success = false, error = "Missing itemHash" }
    end
    if not data.itemDesc then
        return { success = false, error = "Missing itemDesc" }
    end
    if data.priceR == nil then -- Allow 0
        return { success = false, error = "Missing priceR" }
    end
    if data.priceC == nil then -- Allow 0
        return { success = false, error = "Missing priceC" }
    end
    if data.imgUrl == nil then -- Allow empty string
        return { success = false, error = "Missing imgUrl" }
    end
    if not data.category then
        return { success = false, error = "Missing category" }
    end
    if data.perma == nil then
        return { success = false, error = "Missing perma" }
    end

    local query = [[
        INSERT INTO rprp_store_items (itemHash, itemDesc, priceR, priceC, imgUrl, info, category, perma)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]]
    local params = {
        data.itemHash,
        data.itemDesc,
        data.priceR,
        data.priceC or 0,
        data.imgUrl or "", -- Ensure empty string if nil
        data.info or nil, -- Handle optional info
        data.category,
        data.perma and 1 or 0 -- Convert Lua boolean to SQL 0/1
    }

    local success, err = pcall(function()
        exports.oxmysql:executeSync(query, params)
    end)

    if success then
        print('Item created successfully:', data.itemHash)
        return { success = true, itemHash = data.itemHash }
    else
        print('Database error:', tostring(err))
        return { success = false, error = "Failed to create item: " .. tostring(err) }
    end
end
-- Delete an item by itemHash
-- @param itemHash string: The unique identifier of the item
-- @return table: {success, error}
function StoreItems.Delete(itemHash)
    if not itemHash then
        return {success = false, error = "itemHash is required"}
    end

    local query = [[
        DELETE FROM rprp_store_items WHERE itemHash = ?
    ]]
    local params = {itemHash}

    local success, err = pcall(function()
        exports.oxmysql:executeSync(query, params)
    end)

    if success then
        return {success = true}
    else
        return {success = false, error = "Failed to delete item: " .. tostring(err)}
    end
end

-- Update an item by itemHash
-- @param itemHash string: The unique identifier of the item
-- @param data table: Fields to update {itemDesc, priceR, priceC, imgUrl, info, category, perma}
-- @return table: {success, error}
function StoreItems.Update(itemHash, data)
    if not itemHash or not data then
        return {success = false, error = "itemHash and data are required"}
    end

    -- Build dynamic SET clause for non-nil fields
    local setClauses = {}
    local params = {}
    if data.itemDesc then
        table.insert(setClauses, "itemDesc = ?")
        table.insert(params, data.itemDesc)
    end
    if data.priceR then
        table.insert(setClauses, "priceR = ?")
        table.insert(params, data.priceR)
    end
    if data.priceC then
        table.insert(setClauses, "priceC = ?")
        table.insert(params, data.priceC)
    end
    if data.imgUrl then
        table.insert(setClauses, "imgUrl = ?")
        table.insert(params, data.imgUrl)
    end
    if data.info ~= nil then -- Explicitly handle nil to allow clearing info
        table.insert(setClauses, "info = ?")
        table.insert(params, data.info)
    end
    if data.category then
        table.insert(setClauses, "category = ?")
        table.insert(params, data.category)
    end
    if data.perma ~= nil then
        table.insert(setClauses, "perma = ?")
        table.insert(params, data.perma and 1 or 0)
    end

    if #setClauses == 0 then
        return {success = false, error = "No fields to update"}
    end

    table.insert(params, itemHash) -- Add itemHash for WHERE clause
    local query = [[
        UPDATE rprp_store_items
        SET ]] .. table.concat(setClauses, ", ") .. [[
        WHERE itemHash = ?
    ]]

    local success, err = pcall(function()
        exports.oxmysql:executeSync(query, params)
    end)

    if success then
        return {success = true}
    else
        return {success = false, error = "Failed to update item: " .. tostring(err)}
    end
end

-- Get an item by itemHash
-- @param itemHash string: The unique identifier of the item
-- @return table: {success, item or error}
function StoreItems.Get(itemHash)
    if not itemHash then
        return {success = false, error = "itemHash is required"}
    end

    local query = [[
        SELECT itemHash, itemDesc, priceR, priceC, imgUrl, info, category, perma, created_at, updated_at
        FROM rprp_store_items
        WHERE itemHash = ?
    ]]
    local params = {itemHash}

    local success, result = pcall(function()
        return exports.oxmysql:singleSync(query, params)
    end)

    if success and result then
        -- Convert SQL 0/1 to Lua boolean
        result.perma = result.perma == 1
        return {success = true, item = result}
    elseif success then
        return {success = false, error = "Item not found"}
    else
        return {success = false, error = "Failed to retrieve item: " .. tostring(result)}
    end
end

-- Get all items
-- @return table: {success, items or error}
function StoreItems.GetAll()
    local query = [[
        SELECT itemHash, itemDesc, priceR, priceC, imgUrl, info, category, perma, created_at, updated_at
        FROM rprp_store_items
    ]]

    local success, results = pcall(function()
        return exports.oxmysql:fetchSync(query)
    end)

    print('results', json.encode(results))

    if success then
        -- Convert SQL 0/1 to Lua boolean for each item
        for _, item in ipairs(results) do
            item.perma = item.perma == 1
        end
        return {success = true, items = results}
    else
        return {success = false, error = "Failed to retrieve items: " .. tostring(results)}
    end
end

return StoreItems