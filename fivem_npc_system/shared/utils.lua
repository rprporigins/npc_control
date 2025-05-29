-- Shared utility functions

Utils = {}

-- Generate unique ID
function Utils.GenerateId()
    return string.format('%s-%s', os.time(), math.random(10000, 99999))
end

-- Calculate formation positions
function Utils.CalculateFormationPosition(centerPos, index, formation, total)
    local positions = {}
    
    if formation == 'circle' then
        local angle = (2 * math.pi * index) / total
        local radius = Config.Formations.circle.spacing
        return {
            x = centerPos.x + radius * math.cos(angle),
            y = centerPos.y + radius * math.sin(angle),
            z = centerPos.z
        }
    elseif formation == 'line' then
        local spacing = Config.Formations.line.spacing
        return {
            x = centerPos.x + (index - total/2) * spacing,
            y = centerPos.y,
            z = centerPos.z
        }
    elseif formation == 'square' then
        local side = math.ceil(math.sqrt(total))
        local row = math.floor(index / side)
        local col = index % side
        local spacing = Config.Formations.square.spacing
        return {
            x = centerPos.x + (col - side/2) * spacing,
            y = centerPos.y + (row - side/2) * spacing,
            z = centerPos.z
        }
    elseif formation == 'scattered' then
        local radius = Config.Formations.scattered.radius
        return {
            x = centerPos.x + math.random(-radius * 100, radius * 100) / 100,
            y = centerPos.y + math.random(-radius * 100, radius * 100) / 100,
            z = centerPos.z
        }
    end
    
    return centerPos
end

-- Parse vec3 input
function Utils.ParseVec3(input)
    if not input or input == '' then
        return nil
    end
    
    -- Remove vec3() wrapper if present
    input = input:gsub('vec3%(', ''):gsub('%)', '')
    
    -- Extract numbers
    local numbers = {}
    for num in input:gmatch('%-?%d+%.?%d*') do
        table.insert(numbers, tonumber(num))
    end
    
    if #numbers >= 3 then
        return {
            x = numbers[1],
            y = numbers[2],
            z = numbers[3]
        }
    end
    
    return nil
end

-- Parse comma separated string
function Utils.ParseCommaSeparated(input)
    if not input or input == '' then
        return {}
    end
    
    local result = {}
    for item in input:gmatch('([^,]+)') do
        table.insert(result, item:match('^%s*(.-)%s*$')) -- trim whitespace
    end
    
    return result
end

-- Check if player has permission
function Utils.HasPermission(playerId, requiredLevel, npcData)
    if not npcData then return false end
    
    local playerIdStr = tostring(playerId)
    
    -- Check ownership levels
    if npcData.owners then
        for _, ownerId in pairs(npcData.owners) do
            if tostring(ownerId) == playerIdStr then
                return true -- Owner has all permissions
            end
        end
    end
    
    if npcData.leaders then
        for _, leaderId in pairs(npcData.leaders) do
            if tostring(leaderId) == playerIdStr then
                if requiredLevel == 'owner' then
                    return false
                else
                    return true -- Leader has most permissions
                end
            end
        end
    end
    
    if npcData.friends then
        for _, friendId in pairs(npcData.friends) do
            if tostring(friendId) == playerIdStr then
                if requiredLevel == 'friendly' then
                    return true
                else
                    return false -- Friends have limited permissions
                end
            end
        end
    end
    
    return false
end

-- Get permission level
function Utils.GetPermissionLevel(playerId, npcData)
    if not npcData then return 'none' end
    
    local playerIdStr = tostring(playerId)
    
    if npcData.owners then
        for _, ownerId in pairs(npcData.owners) do
            if tostring(ownerId) == playerIdStr then
                return 'owner'
            end
        end
    end
    
    if npcData.leaders then
        for _, leaderId in pairs(npcData.leaders) do
            if tostring(leaderId) == playerIdStr then
                return 'leader'
            end
        end
    end
    
    if npcData.friends then
        for _, friendId in pairs(npcData.friends) do
            if tostring(friendId) == playerIdStr then
                return 'friendly'
            end
        end
    end
    
    return 'none'
end

-- Get gang configuration
function Utils.GetGangConfig(gangName)
    return Config.Gangs[gangName]
end

-- Validate gang
function Utils.IsValidGang(gangName)
    return Config.Gangs[gangName] ~= nil
end

-- Validate model for gang
function Utils.IsValidModelForGang(model, gangName)
    local gangConfig = Config.Gangs[gangName]
    if not gangConfig then return false end
    
    for _, validModel in pairs(gangConfig.models) do
        if validModel == model then
            return true
        end
    end
    
    return false
end

-- Validate weapon for gang
function Utils.IsValidWeaponForGang(weapon, gangName)
    local gangConfig = Config.Gangs[gangName]
    if not gangConfig then return false end
    
    for _, validWeapon in pairs(gangConfig.weapons) do
        if validWeapon == weapon then
            return true
        end
    end
    
    return false
end

-- Get distance between positions
function Utils.GetDistance(pos1, pos2)
    return math.sqrt(
        (pos1.x - pos2.x)^2 + 
        (pos1.y - pos2.y)^2 + 
        (pos1.z - pos2.z)^2
    )
end

-- Create notification
function Utils.Notify(source, title, message, type, duration)
    if IsDuplicityVersion() then
        -- Server side
        TriggerClientEvent('gang_npc:notify', source, {
            title = title,
            description = message,
            type = type or 'info',
            duration = duration or Config.Notifications.Duration
        })
    else
        -- Client side
        lib.notify({
            title = title,
            description = message,
            type = type or 'info',
            duration = duration or Config.Notifications.Duration,
            position = Config.Notifications.Position
        })
    end
end

-- Debug print
function Utils.Debug(...)
    if Config.Debug then
        print('[Gang NPC Manager]', ...)
    end
end

-- Format time
function Utils.FormatTime(timestamp)
    return os.date('%Y-%m-%d %H:%M:%S', timestamp)
end

-- Serialize table to JSON
function Utils.TableToJson(t)
    return json.encode(t)
end

-- Deserialize JSON to table
function Utils.JsonToTable(str)
    return json.decode(str)
end
