-- Chat commands and server events

-- Initialize commands
CreateThread(function()
    Utils.Debug('Server commands initialized')
end)

-- Admin Commands
RegisterCommand('spawnnpc', function(source, args, rawCommand)
    if not IsPlayerAceAllowed(source, Config.Permissions.AdminGroup) then
        Utils.Notify(source, 'Sem Permissão', 'Você não tem permissão para usar este comando', 'error')
        return
    end
    
    if #args < 2 then
        Utils.Notify(source, 'Uso', 'Uso: /spawnnpc [gang] [quantidade] [modelo]', 'warning')
        return
    end
    
    local gang = args[1]
    local quantity = tonumber(args[2]) or 1
    local model = args[3]
    
    if not Utils.IsValidGang(gang) then
        Utils.Notify(source, 'Erro', 'Gangue inválida: ' .. gang, 'error')
        return
    end
    
    if quantity < 1 or quantity > Config.NPC.MaxControllableNPCs then
        Utils.Notify(source, 'Erro', 'Quantidade deve ser entre 1 e ' .. Config.NPC.MaxControllableNPCs, 'error')
        return
    end
    
    local Player = QBCore.Functions.GetPlayer(source)
    local playerPed = GetPlayerPed(source)
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    
    local spawnData = {
        gang = gang,
        model = model,
        quantity = quantity,
        position = {x = coords.x + 2.0, y = coords.y, z = coords.z},
        heading = heading,
        formation = 'circle',
        spawned_by = Player.PlayerData.citizenid,
        owner_ids = Player.PlayerData.citizenid
    }
    
    NPCManager.SpawnNPCs(spawnData, function(success, npcs)
        if success and npcs then
            Utils.Notify(source, 'Sucesso', #npcs .. ' NPCs da gangue ' .. gang .. ' spawnados!', 'success')
        else
            Utils.Notify(source, 'Erro', 'Falha ao spawnar NPCs', 'error')
        end
    end)
end, true)

RegisterCommand('clearnpcs', function(source, args, rawCommand)
    if not IsPlayerAceAllowed(source, Config.Permissions.AdminGroup) then
        Utils.Notify(source, 'Sem Permissão', 'Você não tem permissão para usar este comando', 'error')
        return
    end
    
    local count = 0
    for npcId, _ in pairs(NPCManager.ActiveNPCs) do
        NPCManager.DeleteNPC(npcId)
        count = count + 1
    end
    
    Utils.Notify(source, 'Sucesso', count .. ' NPCs removidos!', 'success')
end, true)

RegisterCommand('npcstats', function(source, args, rawCommand)
    if not IsPlayerAceAllowed(source, Config.Permissions.AdminGroup) then
        Utils.Notify(source, 'Sem Permissão', 'Você não tem permissão para usar este comando', 'error')
        return
    end
    
    local totalNPCs = 0
    local gangCounts = {}
    
    for npcId, npcInfo in pairs(NPCManager.ActiveNPCs) do
        totalNPCs = totalNPCs + 1
        local gang = npcInfo.data.gang
        gangCounts[gang] = (gangCounts[gang] or 0) + 1
    end
    
    local message = string.format('📊 NPCs Ativos: %d\n', totalNPCs)
    for gang, count in pairs(gangCounts) do
        local gangConfig = Utils.GetGangConfig(gang)
        message = message .. string.format('• %s: %d\n', gangConfig.name, count)
    end
    
    TriggerClientEvent('chat:addMessage', source, {
        color = {0, 255, 255},
        multiline = true,
        args = {'Gang NPC Stats', message}
    })
end, true)

-- Player Commands
RegisterCommand('mynpcs', function(source, args, rawCommand)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local playerId = Player.PlayerData.citizenid
    
    NPCManager.GetPlayerNPCs(playerId, function(npcs)
        if #npcs == 0 then
            Utils.Notify(source, 'Info', 'Você não possui NPCs para controlar', 'info')
            return
        end
        
        local message = string.format('👥 Seus NPCs (%d):\n', #npcs)
        for _, npcData in ipairs(npcs) do
            local npc = npcData.npc
            local level = npcData.permission_level
            local gangConfig = Utils.GetGangConfig(npc.gang)
            message = message .. string.format('• %s (%s) - %s\n', 
                gangConfig.name, npc.id:sub(1, 8), level)
        end
        
        TriggerClientEvent('chat:addMessage', source, {
            color = {0, 255, 0},
            multiline = true,
            args = {'Meus NPCs', message}
        })
    end)
end, false)

-- Server Events
RegisterServerEvent('gang_npc:requestPlayerData')
AddEventHandler('gang_npc:requestPlayerData', function()
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local playerId = Player.PlayerData.citizenid
    
    NPCManager.GetPlayerNPCs(playerId, function(npcs)
        -- Get player groups (to be implemented)
        local groups = {} -- GroupManager.GetPlayerGroups(playerId)
        
        TriggerClientEvent('gang_npc:receivePlayerData', source, {
            npcs = npcs,
            groups = groups
        })
    end)
end)

RegisterServerEvent('gang_npc:sendCommand')
AddEventHandler('gang_npc:sendCommand', function(commandData)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    commandData.issued_by = Player.PlayerData.citizenid
    
    NPCManager.SendCommand(commandData, function(success, message)
        TriggerClientEvent('gang_npc:commandResponse', source, {
            success = success,
            message = message
        })
    end)
end)

RegisterServerEvent('gang_npc:openAdminPanel')
AddEventHandler('gang_npc:openAdminPanel', function()
    local source = source
    
    if not IsPlayerAceAllowed(source, Config.Permissions.AdminGroup) then
        Utils.Notify(source, 'Sem Permissão', 'Você não tem permissão para acessar o painel admin', 'error')
        return
    end
    
    -- Get all data for admin panel
    Database.GetAllNPCs(function(npcs)
        Database.GetAllGroups(function(groups)
            local stats = {
                total_npcs = #npcs,
                total_groups = #groups,
                gang_distribution = {},
                active_players = #GetPlayers()
            }
            
            -- Calculate gang distribution
            for _, npc in ipairs(npcs) do
                stats.gang_distribution[npc.gang] = (stats.gang_distribution[npc.gang] or 0) + 1
            end
            
            TriggerClientEvent('gang_npc:openAdminPanel', source, {
                npcs = npcs,
                groups = groups,
                stats = stats,
                gangs = Config.Gangs
            })
        end)
    end)
end)

RegisterServerEvent('gang_npc:spawnFromPanel')
AddEventHandler('gang_npc:spawnFromPanel', function(spawnData)
    local source = source
    
    if not IsPlayerAceAllowed(source, Config.Permissions.AdminGroup) then
        Utils.Notify(source, 'Sem Permissão', 'Você não tem permissão para spawnar NPCs', 'error')
        return
    end
    
    local Player = QBCore.Functions.GetPlayer(source)
    spawnData.spawned_by = Player.PlayerData.citizenid
    
    NPCManager.SpawnNPCs(spawnData, function(success, npcs)
        if success and npcs then
            Utils.Notify(source, 'Sucesso', #npcs .. ' NPCs spawnados via painel admin!', 'success')
            
            -- Refresh admin panel
            TriggerEvent('gang_npc:openAdminPanel', source)
        else
            Utils.Notify(source, 'Erro', 'Falha ao spawnar NPCs', 'error')
        end
    end)
end)

RegisterServerEvent('gang_npc:deleteFromPanel')
AddEventHandler('gang_npc:deleteFromPanel', function(npcId)
    local source = source
    
    if not IsPlayerAceAllowed(source, Config.Permissions.AdminGroup) then
        Utils.Notify(source, 'Sem Permissão', 'Você não tem permissão para deletar NPCs', 'error')
        return
    end
    
    NPCManager.DeleteNPC(npcId, function(success)
        if success then
            Utils.Notify(source, 'Sucesso', 'NPC removido com sucesso!', 'success')
        else
            Utils.Notify(source, 'Erro', 'Falha ao remover NPC', 'error')
        end
    end)
end)

RegisterServerEvent('gang_npc:updateFromPanel')
AddEventHandler('gang_npc:updateFromPanel', function(npcId, updateData)
    local source = source
    
    if not IsPlayerAceAllowed(source, Config.Permissions.AdminGroup) then
        Utils.Notify(source, 'Sem Permissão', 'Você não tem permissão para editar NPCs', 'error')
        return
    end
    
    Database.UpdateNPC(npcId, updateData, function(success)
        if success then
            Utils.Notify(source, 'Sucesso', 'NPC atualizado com sucesso!', 'success')
            
            -- Update active NPC if exists
            local npcInfo = NPCManager.ActiveNPCs[npcId]
            if npcInfo then
                -- Update entity properties
                local entity = npcInfo.entity
                if DoesEntityExist(entity) then
                    if updateData.health then
                        SetEntityHealth(entity, updateData.health)
                    end
                    if updateData.armor then
                        SetPedArmour(entity, updateData.armor)
                    end
                    if updateData.accuracy then
                        SetPedAccuracy(entity, updateData.accuracy)
                    end
                end
                
                -- Update stored data
                for key, value in pairs(updateData) do
                    npcInfo.data[key] = value
                end
            end
        else
            Utils.Notify(source, 'Erro', 'Falha ao atualizar NPC', 'error')
        end
    end)
end)

-- Callback for getting nearby NPCs
lib.callback.register('gang_npc:getNearbyNPCs', function(source, playerCoords, radius)
    local nearbyNPCs = {}
    
    for npcId, npcInfo in pairs(NPCManager.ActiveNPCs) do
        if DoesEntityExist(npcInfo.entity) then
            local npcCoords = GetEntityCoords(npcInfo.entity)
            local distance = Utils.GetDistance(playerCoords, {x = npcCoords.x, y = npcCoords.y, z = npcCoords.z})
            
            if distance <= radius then
                local npcData = npcInfo.data
                npcData.distance = distance
                npcData.entity = npcInfo.entity
                table.insert(nearbyNPCs, npcData)
            end
        end
    end
    
    return nearbyNPCs
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        -- Save all NPC data before stopping
        for npcId, npcInfo in pairs(NPCManager.ActiveNPCs) do
            if DoesEntityExist(npcInfo.entity) then
                local coords = GetEntityCoords(npcInfo.entity)
                local heading = GetEntityHeading(npcInfo.entity)
                
                Database.UpdateNPC(npcId, {
                    position = {x = coords.x, y = coords.y, z = coords.z},
                    heading = heading,
                    health = GetEntityHealth(npcInfo.entity),
                    armor = GetPedArmour(npcInfo.entity)
                })
            end
        end
        
        Utils.Debug('Resource stopped, NPC data saved')
    end
end)
