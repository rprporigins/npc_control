-- ox_target integration for NPCs

local QBCore = exports['qb-core']:GetCoreObject()

-- Initialize target system
CreateThread(function()
    if not lib.checkDependency('ox_target') then
        print('[Gang NPC Manager] ox_target não encontrado! Sistema de targeting desabilitado.')
        return
    end
    
    print('[Gang NPC Manager] Sistema de targeting ox_target iniciado!')
    SetupNPCTargets()
end)

function SetupNPCTargets()
    -- This would be called to add targeting to spawned NPCs
    -- For demo purposes, we'll set up a generic target for NPC peds
    
    exports.ox_target:addGlobalPed({
        {
            name = 'gang_npc_control',
            icon = Config.Target.Icon,
            label = Config.Target.Label,
            distance = Config.Target.Distance,
            canInteract = function(entity, distance, coords, name, bone)
                return IsNPCControllable(entity)
            end,
            onSelect = function(data)
                local entity = data.entity
                local npcId = GetNPCIdFromEntity(entity)
                if npcId then
                    OpenNPCQuickMenu(npcId, entity)
                end
            end
        }
    })
end

function IsNPCControllable(entity)
    -- Check if the entity is a controllable NPC
    -- This would involve checking if the NPC is in our system
    if not DoesEntityExist(entity) or not IsPedAPlayer(entity) == false then
        return false
    end
    
    -- Additional checks could be added here
    -- For now, we'll assume all non-player peds could be NPCs
    return true
end

function GetNPCIdFromEntity(entity)
    -- This would need to be implemented to get NPC ID from entity
    -- Could use entity handles, decorators, or other methods
    -- For demo, we'll return a placeholder
    return "demo_npc_" .. tostring(entity)
end

function OpenNPCQuickMenu(npcId, entity)
    local PlayerData = QBCore.Functions.GetPlayerData()
    local playerId = PlayerData.citizenid or GetPlayerServerId(PlayerId())
    
    -- Quick action menu for direct NPC interaction
    local options = {
        {
            title = '🎮 Controle Rápido',
            description = 'NPC ID: ' .. npcId:sub(1, 8),
            disabled = true
        },
        {
            title = '🚶 Seguir-me',
            description = 'NPC vai seguir você',
            icon = 'fas fa-walking',
            onSelect = function()
                ExecuteQuickCommand(npcId, 'follow')
            end
        },
        {
            title = '🛑 Parar',
            description = 'NPC para no local',
            icon = 'fas fa-stop',
            onSelect = function()
                ExecuteQuickCommand(npcId, 'stay')
            end
        },
        {
            title = '🛡️ Guardar Aqui',
            description = 'NPC defende esta posição',
            icon = 'fas fa-shield',
            onSelect = function()
                ExecuteQuickCommand(npcId, 'guard')
            end
        },
        {
            title = '☮️ Pacífico',
            description = 'NPC não ataca ninguém',
            icon = 'fas fa-peace',
            onSelect = function()
                ExecuteQuickCommand(npcId, 'peaceful')
            end
        },
        {
            title = '⚔️ Combate',
            description = 'NPC me defende',
            icon = 'fas fa-sword',
            onSelect = function()
                ExecuteQuickCommand(npcId, 'combat')
            end
        }
    }
    
    lib.registerContext({
        id = 'npc_quick_menu',
        title = '⚡ Controle Rápido',
        position = 'top-left',
        options = options
    })
    
    lib.showContext('npc_quick_menu')
end

function ExecuteQuickCommand(npcId, command)
    local PlayerData = QBCore.Functions.GetPlayerData()
    local playerId = PlayerData.citizenid or GetPlayerServerId(PlayerId())
    
    local commandData = {
        npc_id = npcId,
        command = command,
        issued_by = playerId
    }
    
    -- Add position for guard command
    if command == "guard" then
        local playerPed = PlayerPedId()
        local pos = GetEntityCoords(playerPed)
        commandData.position = {x = pos.x, y = pos.y, z = pos.z}
    end
    
    TriggerServerEvent('gang_npc:sendCommand', commandData)
    
    lib.notify({
        title = '⚡ Comando Rápido',
        description = 'Comando "' .. command .. '" enviado!',
        type = 'success',
        duration = 3000,
        position = 'top-right'
    })
end

-- Register command to add target to specific NPCs
RegisterCommand('npc_target_add', function(source, args, rawCommand)
    if not args[1] then
        lib.notify({
            title = 'Uso Incorreto',
            description = 'Use: /npc_target_add [entity_id]',
            type = 'error'
        })
        return
    end
    
    local entityId = tonumber(args[1])
    if entityId and DoesEntityExist(entityId) then
        AddTargetToNPC(entityId)
        lib.notify({
            title = 'Target Adicionado',
            description = 'Sistema de targeting adicionado ao NPC',
            type = 'success'
        })
    else
        lib.notify({
            title = 'Erro',
            description = 'Entity ID inválido',
            type = 'error'
        })
    end
end, false)

function AddTargetToNPC(entityId)
    -- Add specific targeting to an NPC entity
    exports.ox_target:addLocalEntity(entityId, {
        {
            name = 'gang_npc_specific_' .. entityId,
            icon = 'fas fa-cog',
            label = 'Controlar NPC',
            distance = 3.0,
            onSelect = function(data)
                local npcId = GetNPCIdFromEntity(data.entity)
                OpenNPCQuickMenu(npcId, data.entity)
            end
        }
    })
end

-- Event to add targets to newly spawned NPCs
RegisterNetEvent('gang_npc:npcSpawned', function(npcData, entityId)
    if entityId and DoesEntityExist(entityId) then
        AddTargetToNPC(entityId)
        
        if Config.Debug then
            print('[Gang NPC Manager] Target adicionado ao NPC: ' .. npcData.id)
        end
    end
end)

-- Event to remove targets from deleted NPCs
RegisterNetEvent('gang_npc:npcDeleted', function(npcId, entityId)
    if entityId then
        exports.ox_target:removeLocalEntity(entityId, 'gang_npc_specific_' .. entityId)
        
        if Config.Debug then
            print('[Gang NPC Manager] Target removido do NPC: ' .. npcId)
        end
    end
end)

-- Utility function to highlight nearby controllable NPCs
RegisterCommand('npc_highlight', function()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    -- Get all peds in area
    local peds = GetGamePool('CPed')
    local count = 0
    
    for _, ped in pairs(peds) do
        if DoesEntityExist(ped) and not IsPedAPlayer(ped) then
            local pedCoords = GetEntityCoords(ped)
            local distance = #(coords - pedCoords)
            
            if distance <= Config.NPC.MaxDistance then
                -- Add temporary highlight
                SetEntityDrawOutlineColor(255, 255, 0, 255)
                SetEntityDrawOutline(ped, true)
                count = count + 1
                
                -- Remove highlight after 5 seconds
                CreateThread(function()
                    Wait(5000)
                    SetEntityDrawOutline(ped, false)
                end)
            end
        end
    end
    
    lib.notify({
        title = 'NPCs Destacados',
        description = count .. ' NPCs próximos destacados por 5 segundos',
        type = 'info',
        duration = 5000
    })
end, false)

-- Admin command to show all NPC targets in area
RegisterCommand('npc_show_targets', function()
    if not IsPlayerAceAllowed(PlayerId(), Config.Permissions.AdminGroup) then
        lib.notify({
            title = 'Sem Permissão',
            description = 'Você não tem permissão para usar este comando',
            type = 'error'
        })
        return
    end
    
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    -- This would show all NPCs in the area with their IDs and status
    TriggerServerEvent('gang_npc:getAreaNPCs', coords, Config.NPC.MaxDistance)
end, false)

-- Handle area NPCs response
RegisterNetEvent('gang_npc:areaNPCsResponse', function(npcs)
    if #npcs == 0 then
        lib.notify({
            title = 'Nenhum NPC Encontrado',
            description = 'Não há NPCs na área',
            type = 'info'
        })
        return
    end
    
    local options = {}
    
    table.insert(options, {
        title = '📍 NPCs na Área (' .. #npcs .. ')',
        description = 'NPCs encontrados em um raio de ' .. Config.NPC.MaxDistance .. 'm',
        disabled = true
    })
    
    for _, npc in pairs(npcs) do
        table.insert(options, {
            title = '🎯 ' .. npc.gang:upper() .. ' - ' .. npc.id:sub(1, 8),
            description = 'Estado: ' .. npc.state .. ' | Distância: ' .. math.floor(npc.distance) .. 'm',
            icon = 'fas fa-crosshairs',
            onSelect = function()
                -- Teleport to NPC or open control menu
                SetEntityCoords(PlayerPedId(), npc.position.x, npc.position.y, npc.position.z)
                lib.notify({
                    title = 'Teletransportado',
                    description = 'Você foi teletransportado para o NPC',
                    type = 'success'
                })
            end
        })
    end
    
    lib.registerContext({
        id = 'area_npcs_menu',
        title = '📍 NPCs na Área',
        position = 'top-left',
        options = options
    })
    
    lib.showContext('area_npcs_menu')
end)
