local QBCore = exports['qb-core']:GetCoreObject()
local activeNPCs = {} -- Store active NPCs with their entity handles
local playerNPCs = {} -- Track which NPCs belong to which players

-- HTTP Request function
function MakeAPIRequest(method, endpoint, data, callback)
    local url = Config.API.BaseURL .. endpoint
    
    PerformHttpRequest(url, function(statusCode, response, headers)
        if callback then
            local success = statusCode >= 200 and statusCode < 300
            local responseData = nil
            
            if response then
                responseData = json.decode(response)
            end
            
            callback(success, responseData, statusCode)
        end
    end, method, data and json.encode(data) or nil, {
        ['Content-Type'] = 'application/json'
    })
end

-- Initialize
CreateThread(function()
    print('[Gang NPC Manager] Servidor iniciado!')
    
    -- Load existing NPCs from API
    LoadExistingNPCs()
end)

function LoadExistingNPCs()
    MakeAPIRequest('GET', '/npcs', nil, function(success, data)
        if success and data then
            print('[Gang NPC Manager] Carregando ' .. #data .. ' NPCs existentes...')
            
            for _, npcData in pairs(data) do
                SpawnNPCEntity(npcData)
            end
        else
            print('[Gang NPC Manager] Erro ao carregar NPCs existentes')
        end
    end)
end

function SpawnNPCEntity(npcData)
    local model = GetHashKey(npcData.model)
    
    if not IsModelValid(model) then
        print('[Gang NPC Manager] Modelo inválido: ' .. npcData.model)
        return false
    end
    
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(100)
    end
    
    local ped = CreatePed(4, model, npcData.position.x, npcData.position.y, npcData.position.z, npcData.heading or 0.0, true, true)
    
    if DoesEntityExist(ped) then
        -- Configure NPC
        SetPedMaxHealth(ped, npcData.health)
        SetEntityHealth(ped, npcData.health)
        SetPedArmour(ped, npcData.armor)
        SetPedAccuracy(ped, npcData.accuracy)
        
        -- Set weapon if specified
        if npcData.weapon then
            GiveWeaponToPed(ped, GetHashKey(npcData.weapon), 250, false, true)
        end
        
        -- Make NPC invincible to prevent accidental damage
        SetEntityInvincible(ped, true)
        SetPedCanRagdoll(ped, false)
        
        -- Add to tracking
        activeNPCs[npcData.id] = {
            entity = ped,
            data = npcData,
            lastUpdate = GetGameTimer()
        }
        
        -- Track ownership
        for _, ownerId in pairs(npcData.owner_ids or {}) do
            if not playerNPCs[ownerId] then
                playerNPCs[ownerId] = {}
            end
            table.insert(playerNPCs[ownerId], npcData.id)
        end
        
        -- Trigger client event for targeting
        TriggerClientEvent('gang_npc:npcSpawned', -1, npcData, ped)
        
        if Config.Debug then
            print('[Gang NPC Manager] NPC spawnado: ' .. npcData.id .. ' (Entity: ' .. ped .. ')')
        end
        
        return ped
    else
        print('[Gang NPC Manager] Falha ao spawnar NPC: ' .. npcData.id)
        return false
    end
end

function DeleteNPCEntity(npcId)
    local npcInfo = activeNPCs[npcId]
    if npcInfo and DoesEntityExist(npcInfo.entity) then
        TriggerClientEvent('gang_npc:npcDeleted', -1, npcId, npcInfo.entity)
        DeleteEntity(npcInfo.entity)
        activeNPCs[npcId] = nil
        
        -- Remove from player tracking
        for playerId, npcs in pairs(playerNPCs) do
            for i, id in pairs(npcs) do
                if id == npcId then
                    table.remove(npcs, i)
                    break
                end
            end
        end
        
        if Config.Debug then
            print('[Gang NPC Manager] NPC deletado: ' .. npcId)
        end
        
        return true
    end
    
    return false
end

-- Commands
RegisterCommand('spawnnpc', function(source, args, rawCommand)
    if not IsPlayerAceAllowed(source, Config.Permissions.AdminGroup) then
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 0, 0},
            multiline = true,
            args = {"Sistema", "Você não tem permissão para usar este comando"}
        })
        return
    end
    
    if #args < 2 then
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 255, 0},
            multiline = true,
            args = {"Sistema", "Uso: /spawnnpc [gang] [quantidade]"}
        })
        return
    end
    
    local gang = args[1]
    local quantity = tonumber(args[2]) or 1
    local Player = QBCore.Functions.GetPlayer(source)
    local playerPed = GetPlayerPed(source)
    local coords = GetEntityCoords(playerPed)
    
    local spawnData = {
        gang = gang,
        quantity = quantity,
        position = {x = coords.x, y = coords.y, z = coords.z},
        owner_ids = Player.PlayerData.citizenid
    }
    
    MakeAPIRequest('POST', '/npc/spawn', spawnData, function(success, data)
        if success and data then
            for _, npcData in pairs(data) do
                SpawnNPCEntity(npcData)
            end
            
            TriggerClientEvent('chat:addMessage', source, {
                color = {0, 255, 0},
                multiline = true,
                args = {"Sistema", quantity .. " NPCs spawnados com sucesso!"}
            })
        else
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"Sistema", "Erro ao spawnar NPCs"}
            })
        end
    end)
end, false)

RegisterCommand('clearnpcs', function(source, args, rawCommand)
    if not IsPlayerAceAllowed(source, Config.Permissions.AdminGroup) then
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 0, 0},
            multiline = true,
            args = {"Sistema", "Você não tem permissão para usar este comando"}
        })
        return
    end
    
    -- Clear all NPCs
    for npcId, _ in pairs(activeNPCs) do
        DeleteNPCEntity(npcId)
    end
    
    MakeAPIRequest('DELETE', '/npcs/clear', nil, function(success, data)
        if success then
            TriggerClientEvent('chat:addMessage', source, {
                color = {0, 255, 0},
                multiline = true,
                args = {"Sistema", "Todos os NPCs foram removidos!"}
            })
        end
    end)
end, false)

-- Events
RegisterServerEvent('gang_npc:sendCommand', function(commandData)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then return end
    
    -- Validate command
    if not commandData.npc_id or not commandData.command then
        TriggerClientEvent('gang_npc:commandResponse', source, {
            success = false,
            message = "Dados de comando inválidos"
        })
        return
    end
    
    -- Make API request
    MakeAPIRequest('POST', '/npc/command', commandData, function(success, data)
        if success then
            -- Apply command to entity if exists
            local npcInfo = activeNPCs[commandData.npc_id]
            if npcInfo and DoesEntityExist(npcInfo.entity) then
                ApplyCommandToEntity(npcInfo.entity, commandData)
            end
            
            TriggerClientEvent('gang_npc:commandResponse', source, {
                success = true,
                message = data.message or "Comando executado com sucesso"
            })
        else
            TriggerClientEvent('gang_npc:commandResponse', source, {
                success = false,
                message = data and data.detail or "Erro ao executar comando"
            })
        end
    end)
end)

RegisterServerEvent('gang_npc:sendGroupCommand', function(commandData)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then return end
    
    MakeAPIRequest('POST', '/group/command', commandData, function(success, data)
        if success then
            TriggerClientEvent('gang_npc:commandResponse', source, {
                success = true,
                message = data.message or "Comando de grupo executado"
            })
        else
            TriggerClientEvent('gang_npc:commandResponse', source, {
                success = false,
                message = data and data.detail or "Erro ao executar comando de grupo"
            })
        end
    end)
end)

RegisterServerEvent('gang_npc:getAreaNPCs', function(coords, radius)
    local source = source
    local nearbyNPCs = {}
    
    for npcId, npcInfo in pairs(activeNPCs) do
        if DoesEntityExist(npcInfo.entity) then
            local npcCoords = GetEntityCoords(npcInfo.entity)
            local distance = #(vector3(coords.x, coords.y, coords.z) - npcCoords)
            
            if distance <= radius then
                local npcData = npcInfo.data
                npcData.distance = distance
                npcData.position = {x = npcCoords.x, y = npcCoords.y, z = npcCoords.z}
                table.insert(nearbyNPCs, npcData)
            end
        end
    end
    
    TriggerClientEvent('gang_npc:areaNPCsResponse', source, nearbyNPCs)
end)

function ApplyCommandToEntity(entity, commandData)
    local command = commandData.command
    
    if command == "follow" then
        -- Make NPC follow the player
        local playerId = commandData.issued_by
        -- Implementation would involve AI tasks
        
    elseif command == "stay" then
        -- Make NPC stay in place
        ClearPedTasks(entity)
        
    elseif command == "guard" then
        -- Make NPC guard a position
        if commandData.position then
            -- Set guarding behavior
        end
        
    elseif command == "peaceful" then
        -- Make NPC non-aggressive
        SetPedCombatAbility(entity, 0)
        
    elseif command == "combat" then
        -- Make NPC aggressive
        SetPedCombatAbility(entity, 100)
        
    end
    
    if Config.Debug then
        print('[Gang NPC Manager] Comando aplicado ao entity: ' .. command)
    end
end

-- Callbacks
lib.callback.register('gang_npc:getPlayerData', function(source, playerId)
    -- Get NPCs and groups for player
    MakeAPIRequest('GET', '/player/' .. playerId .. '/npcs', nil, function(success, npcs)
        if success then
            MakeAPIRequest('GET', '/player/' .. playerId .. '/groups', nil, function(groupSuccess, groups)
                local result = {
                    npcs = npcs or {},
                    groups = groups or {}
                }
                
                -- Return data to client
                TriggerClientEvent('gang_npc:playerDataResponse', source, result)
            end)
        else
            TriggerClientEvent('gang_npc:playerDataResponse', source, {npcs = {}, groups = {}})
        end
    end)
    
    return true
end)

-- Cleanup on player disconnect
AddEventHandler('playerDropped', function(reason)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    
    if Player and playerNPCs[Player.PlayerData.citizenid] then
        -- Optional: Could remove player's NPCs or transfer ownership
        if Config.Debug then
            print('[Gang NPC Manager] Player disconnected: ' .. Player.PlayerData.citizenid)
        end
    end
end)

-- Export functions
exports('GetActiveNPCs', function()
    return activeNPCs
end)

exports('GetPlayerNPCs', function(playerId)
    return playerNPCs[playerId] or {}
end)

exports('SpawnNPC', function(npcData)
    return SpawnNPCEntity(npcData)
end)

exports('DeleteNPC', function(npcId)
    return DeleteNPCEntity(npcId)
end)
