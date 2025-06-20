-- client.lua
-- Client-side Lua script for FiveM to handle NUI communication and server callbacks for the store interface
local function sendReactMessage(action, data)
    SendNuiMessage(
        json.encode({
            action = action,
            data = data,
        })
    )
end

-- NUI callback to get all items
RegisterNUICallback('rp_store:client:getAllItems', function(data, cb)
    -- Call server callback to get all items
    lib.callback('rp_store:server:getAllItems', false, function(result)        
        -- Transform result to match IItem interface
        local transformedResult = {
            success = result.success,
            error = result.error
        }
        
        if result.success and result.items then
            local transformedItems = {}
            for i, item in ipairs(result.items) do
                -- Validate category to ItemType
                local validType = item.category
                if validType ~= "car" and validType ~= "truck" and validType ~= "bike" and validType ~= "weapon" then
                    print("Invalid item type for " .. item.itemHash .. ": " .. tostring(validType))
                    validType = "car" -- Fallback to "car"
                end
                
                transformedItems[i] = {
                    id = item.itemHash,
                    name = item.itemDesc,
                    priceR = item.priceR,
                    priceC = item.priceC,
                    imgUrl = item.imgUrl,
                    info = item.info or "",
                    type = validType,
                    perma = item.perma
                }
            end
            transformedResult.items = transformedItems
        end
        
        -- Send transformed result to NUI
        sendReactMessage('rp_store:setItems', transformedResult)
        cb('ok')
    end)
end)

-- NUI callback to get a single item by itemHash
RegisterNUICallback('rp_store:client:getItem', function(data, cb)
    if not data.itemHash then
        SendNUIMessage({
            action = 'error',
            data = 'Missing itemHash'
        })
        cb('error')
        return
    end

    -- Call server callback to get item
    lib.callback('rp_store:server:getItem', false, function(result)
        -- Send result to NUI
        SendNUIMessage({
            action = 'setItem',
            data = result
        })
        cb('ok')
    end, data.itemHash)
end)

-- NUI callback to create a new item
RegisterNUICallback('rp_store:client:createItem', function(data, cb)
    -- format fields to match IItem interface
    local newData = {
        itemHash = data.id,
        itemDesc = data.name,
        priceR = data.priceR,
        priceC = data.priceC or 0, -- Default to 0 if not provided
        imgUrl = data.imgUrl,
        info = data.info or "", -- Default to empty string if not provided
        category = data.type or "car", -- Default to "car" if not provided
        perma = data.perma or false -- Default to false if not provided
    }
    -- Call server callback to create item
    print('Creating item with data:', json.encode(newData))
    lib.callback('rp_store:server:createItem', false, function(result)
        print(json.encode(result))
        -- Send result to NUI
        SendNUIMessage({
            action = 'createItemResult',
            data = result
        })
        cb('ok')
    end, newData)
end)