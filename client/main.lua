-- Client main script

local QBCore = exports['qb-core']:GetCoreObject()

-- Variables
local playerNPCs = {}
local playerGroups = {}
local nearbyNPCs = {}
local isMenuOpen = false
local lastCommandTime = 0

-- Initialize
CreateThread(function()
    Utils.Debug('Client initialized')
    
    -- Register decorators first
    RegisterDecorators()
    
    -- Register keybinds
    RegisterKeyBind()
    
    -- Setup target system
    if lib.checkDependency('ox_target') then
        SetupTargetSystem()
    end
    
    -- Start update loops
    StartUpdateLoops()
end)

-- Register decorators
function RegisterDecorators()
    DecorRegister('gang_npc', 2) -- Int type
    DecorRegister('gang_npc_id', 1) -- String type
    
    for gang in pairs(Config.Gangs) do
        DecorRegister('gang_npc_' .. gang, 5) -- Bool type
    end
    
    Utils.Debug('Decorators registered')
end

-- Register keybinds
function RegisterKeyBind()
    -- F10 - NPC Control Menu
    RegisterCommand('+gang_npc_menu', function()
        if not isMenuOpen then
            OpenNPCControlMenu()
        end
    end, false)
    
    RegisterCommand('-gang_npc_menu', function()
        -- Key release handler (empty)
    end, false)
    
    RegisterKeyMapping('+gang_npc_menu', 'Abrir Menu de Controle de NPCs', 'keyboard', 'F10')
    
    -- F9 - Admin Panel (for admins)
    RegisterCommand('+gang_npc_admin', function()
        TriggerServerEvent('gang_npc:openAdminPanel')
    end, false)
    
    RegisterCommand('-gang_npc_admin', function()
        -- Key release handler (empty)
    end, false)
    
    RegisterKeyMapping('+gang_npc_admin', 'Abrir Painel Administrativo', 'keyboard', 'F9')
    
    Utils.Debug('Keybinds registered')
end

-- Main NPC Control Menu
function OpenNPCControlMenu()
    if isMenuOpen then return end
    
    isMenuOpen = true
    
    -- Request player data from server
    TriggerServerEvent('gang_npc:requestPlayerData')
end

-- Build and show NPC control menu
function BuildNPCControlMenu(data)
    local npcs = data.npcs or {}
    local groups = data.groups or {}
    
    local options = {}
    
    -- Header
    table.insert(options, {
        title = '🎮 Gang NPC Manager',
        description = 'Sistema de Controle de NPCs',
        disabled = true
    })
    
    -- My NPCs section
    if #npcs > 0 then
        table.insert(options, {
            title = '👤 Meus NPCs (' .. #npcs .. ')',
            description = 'NPCs que você pode controlar',
            disabled = true
        })
        
        for _, npcData in ipairs(npcs) do
            local npc = npcData.npc
            local permissionLevel = npcData.permission_level
            local gangConfig = Utils.GetGangConfig(npc.gang)
            
            table.insert(options, {
                title = '🎯 ' .. gangConfig.name .. ' - ' .. npc.id:sub(1, 8),
                description = string.format('Estado: %s | Nível: %s | Vida: %d%%', 
                    Config.States[npc.state] or npc.state, 
                    permissionLevel, 
                    npc.health or 100),
                icon = 'fas fa-user',
                iconColor = gangConfig.color,
                onSelect = function()
                    OpenNPCCommandMenu(npc, permissionLevel)
                end
            })
        end
    end
    
    -- My Groups section
    if #groups > 0 then
        table.insert(options, {
            title = '👥 Meus Grupos (' .. #groups .. ')',
            description = 'Grupos que você pode controlar',
            disabled = true
        })
        
        for _, groupData in ipairs(groups) do
            local group = groupData.group
            local permissionLevel = groupData.permission_level
            local gangConfig = Utils.GetGangConfig(group.gang)
            
            table.insert(options, {
                title = '🎯 ' .. group.name,
                description = string.format('Gangue: %s | Nível: %s', 
                    gangConfig.name, permissionLevel),
                icon = 'fas fa-users',
                iconColor = gangConfig.color,
                onSelect = function()
                    OpenGroupCommandMenu(group, permissionLevel)
                end
            })
        end
    end
    
    -- Get nearby NPCs and add to menu
    lib.callback('gang_npc:getNearbyNPCs', false, function(nearby)
        if nearby and #nearby > 0 then
            table.insert(options, {
                title = '📍 NPCs Próximos (' .. #nearby .. ')',
                description = 'NPCs no raio de ' .. Config.NPC.MaxDistance .. 'm',
                disabled = true
            })
            
            for _, npc in ipairs(nearby) do
                local gangConfig = Utils.GetGangConfig(npc.gang)
                table.insert(options, {
                    title = '👁️ ' .. gangConfig.name .. ' - ' .. npc.id:sub(1, 8),
                    description = string.format('Distância: %.1fm | Estado: %s', 
                        npc.distance, Config.States[npc.state] or npc.state),
                    icon = 'fas fa-eye',
                    onSelect = function()
                        TryInteractWithNearbyNPC(npc.id)
                    end
                })
            end
        end
        
        -- Add message if no options exist
        if #options <= 1 then
            table.insert(options, {
                title = '❌ Nenhum NPC Disponível',
                description = 'Você não possui NPCs para controlar',
                disabled = true
            })
        end
        
        -- Add refresh option
        table.insert(options, {
            title = '🔄 Atualizar Lista',
            description = 'Recarregar lista de NPCs',
            icon = 'fas fa-sync',
            onSelect = function()
                isMenuOpen = false
                OpenNPCControlMenu()
            end
        })
        
        -- Show menu with proper cleanup
        lib.registerContext({
            id = 'gang_npc_main_menu',
            title = '🎮 Gang NPC Manager',
            position = 'top-left',
            onExit = function()
                isMenuOpen = false
            end,
            options = options
        })
        
        lib.showContext('gang_npc_main_menu')
    end, GetEntityCoords(PlayerPedId()), Config.NPC.MaxDistance or 50.0)
end

-- NPC Command Menu
function OpenNPCCommandMenu(npc, permissionLevel)
    local options = {}
    
    -- NPC Info header
    local gangConfig = Utils.GetGangConfig(npc.gang)
    table.insert(options, {
        title = '📊 ' .. gangConfig.name,
        description = string.format('ID: %s | Vida: %d | Armadura: %d | Mira: %d%%', 
            npc.id:sub(1, 8), npc.health or 100, npc.armor or 0, npc.accuracy or 50),
        disabled = true
    })
    
    -- Add commands based on permission level
    for commandId, commandConfig in pairs(Config.Commands) do
        local canUse = true
        
        -- Check permission requirements
        if commandConfig.permission == 'owner' and permissionLevel ~= 'owner' then
            canUse = false
        elseif commandConfig.permission == 'leader' and 
               permissionLevel ~= 'owner' and permissionLevel ~= 'leader' then
            canUse = false
        end
        
        if canUse then
            table.insert(options, {
                title = commandConfig.label,
                description = commandConfig.description,
                icon = 'fas fa-chevron-right',
                onSelect = function()
                    ExecuteNPCCommand(npc.id, commandId)
                end
            })
        end
    end
    
    -- Back button
    table.insert(options, {
        title = '🔙 Voltar',
        description = 'Voltar ao menu principal',
        icon = 'fas fa-arrow-left',
        onSelect = function()
            OpenNPCControlMenu()
        end
    })
    
    lib.registerContext({
        id = 'gang_npc_command_menu',
        title = '🎮 Comandos - ' .. gangConfig.name,
        position = 'top-left',
        onExit = function()
            isMenuOpen = false
        end,
        options = options
    })
    
    lib.showContext('gang_npc_command_menu')
end

-- Group Command Menu
function OpenGroupCommandMenu(group, permissionLevel)
    local options = {}
    
    -- Group Info header
    local gangConfig = Utils.GetGangConfig(group.gang)
    table.insert(options, {
        title = '📊 ' .. group.name,
        description = string.format('Gangue: %s | Membros: %d', 
            gangConfig.name, #(group.members or {})),
        disabled = true
    })
    
    -- Group commands
    local groupCommands = {
        {id = 'follow', label = '🚶 Todos Seguir', description = 'Todos NPCs do grupo seguem você'},
        {id = 'stay', label = '🛑 Todos Parar', description = 'Todos NPCs param'},
        {id = 'peaceful', label = '☮️ Modo Pacífico', description = 'Grupo em modo pacífico'},
        {id = 'combat', label = '⚔️ Modo Combate', description = 'Grupo em modo combate'},
        {id = 'guard', label = '🛡️ Guardar Área', description = 'Grupo defende área atual'}
    }
    
    for _, command in ipairs(groupCommands) do
        table.insert(options, {
            title = command.label,
            description = command.description,
            icon = 'fas fa-chevron-right',
            onSelect = function()
                ExecuteGroupCommand(group.id, command.id)
            end
        })
    end
    
    -- Back button
    table.insert(options, {
        title = '🔙 Voltar',
        description = 'Voltar ao menu principal',
        icon = 'fas fa-arrow-left',
        onSelect = function()
            OpenNPCControlMenu()
        end
    })
    
    lib.registerContext({
        id = 'gang_npc_group_menu',
        title = '🎮 Grupo - ' .. group.name,
        position = 'top-left',
        onExit = function()
            isMenuOpen = false
        end,
        options = options
    })
    
    lib.showContext('gang_npc_group_menu')
end

-- Execute NPC command
function ExecuteNPCCommand(npcId, command)
    if GetGameTimer() - lastCommandTime < Config.NPC.CommandCooldown then
        Utils.Notify('Comando em Cooldown', 'Aguarde antes de enviar outro comando', 'warning')
        return
    end
    
    local commandData = {
        npc_id = npcId,
        command = command
    }
    
    -- Add extra data based on command
    if command == 'guard' then
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        commandData.position = {x = coords.x, y = coords.y, z = coords.z}
    elseif command == 'attack' then
        -- Get target via raycast
        local target = GetTargetPlayer()
        if target then
            commandData.target_id = tostring(target)
        else
            Utils.Notify('Erro no Comando', 'Nenhum alvo selecionado para atacar', 'error')
            return
        end
    end
    
    TriggerServerEvent('gang_npc:sendCommand', commandData)
    lastCommandTime = GetGameTimer()
    
    Utils.Notify('Comando Enviado', 'Comando "' .. command .. '" enviado para NPC', 'success')
end

-- Execute group command
function ExecuteGroupCommand(groupId, command)
    local commandData = {
        group_id = groupId,
        command = command
    }
    
    -- Add extra data based on command
    if command == 'guard' then
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        commandData.position = {x = coords.x, y = coords.y, z = coords.z}
    end
    
    TriggerServerEvent('gang_npc:sendGroupCommand', commandData)
    
    Utils.Notify('Comando de Grupo', 'Comando "' .. command .. '" enviado para grupo', 'success')
end

-- Get target player via improved raycast
function GetTargetPlayer()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local direction = GetEntityForwardVector(playerPed)
    local endCoords = coords + direction * 15.0
    
    -- Use flag 12 for player detection (players + NPCs)
    local rayHandle = StartShapeTestRay(coords.x, coords.y, coords.z + 0.5, endCoords.x, endCoords.y, endCoords.z, 12, playerPed, 0)
    local retval, hit, hitCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHandle)
    
    if hit and entityHit > 0 then
        -- Check if it's a player
        if IsPedAPlayer(entityHit) then
            local targetPlayer = NetworkGetPlayerIndexFromPed(entityHit)
            if targetPlayer ~= -1 and targetPlayer ~= PlayerId() then
                local serverId = GetPlayerServerId(targetPlayer)
                if serverId and serverId > 0 then
                    return serverId
                end
            end
        end
    end
    
    return nil
end

-- Try to interact with nearby NPC
function TryInteractWithNearbyNPC(npcId)
    Utils.Notify('Interação', 'Tentando interagir com NPC próximo', 'info')
    -- This could open a limited interaction menu
end

-- Setup target system
function SetupTargetSystem()
    exports.ox_target:addGlobalPed({
        {
            name = 'gang_npc_interact',
            icon = Config.Target.Icon,
            label = Config.Target.Label,
            distance = Config.Target.Distance,
            canInteract = function(entity, distance, coords, name, bone)
                return DecorExistOn(entity, 'gang_npc') and DecorGetInt(entity, 'gang_npc') == 1
            end,
            onSelect = function(data)
                OpenNPCQuickMenu(data.entity)
            end
        }
    })
    
    Utils.Debug('Target system initialized')
end

-- Quick menu for direct NPC interaction
function OpenNPCQuickMenu(entity)
    if not DoesEntityExist(entity) then return end
    
    -- Get NPC ID from decorator
    local npcId = nil
    if DecorExistOn(entity, 'gang_npc_id') then
        npcId = DecorGetString(entity, 'gang_npc_id')
    end
    
    if not npcId then
        Utils.Notify('Erro', 'NPC não identificado', 'error')
        return
    end
    
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
                ExecuteNPCCommand(npcId, 'follow')
                lib.hideContext()
            end
        },
        {
            title = '🛑 Parar',
            description = 'NPC para no local',
            icon = 'fas fa-stop',
            onSelect = function()
                ExecuteNPCCommand(npcId, 'stay')
                lib.hideContext()
            end
        },
        {
            title = '🛡️ Guardar Aqui',
            description = 'NPC defende esta posição',
            icon = 'fas fa-shield',
            onSelect = function()
                ExecuteNPCCommand(npcId, 'guard')
                lib.hideContext()
            end
        },
        {
            title = '☮️ Pacífico',
            description = 'NPC não ataca ninguém',
            icon = 'fas fa-peace',
            onSelect = function()
                ExecuteNPCCommand(npcId, 'peaceful')
                lib.hideContext()
            end
        },
        {
            title = '⚔️ Combate',
            description = 'NPC me defende',
            icon = 'fas fa-sword',
            onSelect = function()
                ExecuteNPCCommand(npcId, 'combat')
                lib.hideContext()
            end
        }
    }
    
    lib.registerContext({
        id = 'gang_npc_quick_menu',
        title = '⚡ Controle Rápido',
        position = 'top-left',
        onExit = function()
            -- Quick menu doesn't affect main menu state
        end,
        options = options
    })
    
    lib.showContext('gang_npc_quick_menu')
end

-- Start update loops
function StartUpdateLoops()
    -- Update player data periodically
    CreateThread(function()
        while true do
            Wait(30000) -- Every 30 seconds
            
            if not isMenuOpen then
                TriggerServerEvent('gang_npc:requestPlayerData')
            end
        end
    end)
end

-- Event handlers
RegisterNetEvent('gang_npc:receivePlayerData')
AddEventHandler('gang_npc:receivePlayerData', function(data)
    playerNPCs = data.npcs or {}
    playerGroups = data.groups or {}
    
    if isMenuOpen then
        BuildNPCControlMenu(data)
    end
end)

RegisterNetEvent('gang_npc:commandResponse')
AddEventHandler('gang_npc:commandResponse', function(response)
    if response.success then
        Utils.Notify('Comando Executado', response.message, 'success')
    else
        Utils.Notify('Erro no Comando', response.message, 'error')
    end
end)

RegisterNetEvent('gang_npc:notify')
AddEventHandler('gang_npc:notify', function(notifyData)
    Utils.Notify(notifyData.title, notifyData.description, notifyData.type, notifyData.duration)
end)

RegisterNetEvent('gang_npc:npcSpawned')
AddEventHandler('gang_npc:npcSpawned', function(npcData, entity)
    Utils.Debug('NPC spawned:', npcData.id, 'Entity:', entity)
end)

RegisterNetEvent('gang_npc:npcDeleted')
AddEventHandler('gang_npc:npcDeleted', function(npcId, entity)
    Utils.Debug('NPC deleted:', npcId)
end)

RegisterNetEvent('gang_npc:openAdminPanel')
AddEventHandler('gang_npc:openAdminPanel', function(data)
    -- Open NUI admin panel
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'openAdminPanel',
        data = data
    })
end)

-- Close menu handler
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if isMenuOpen then
            lib.hideContext()
            isMenuOpen = false
        end
    end
end)

-- Menu state management
CreateThread(function()
    while true do
        Wait(100)
        
        if isMenuOpen and not lib.getOpenContextMenu() then
            isMenuOpen = false
        end
    end
end)

-- Exports
exports('GetPlayerNPCs', function()
    return playerNPCs
end)

exports('GetPlayerGroups', function()
    return playerGroups
end)

exports('SendNPCCommand', function(npcId, command)
    ExecuteNPCCommand(npcId, command)
end)
