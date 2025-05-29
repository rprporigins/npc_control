local QBCore = exports['qb-core']:GetCoreObject()

-- Variables
local playerNPCs = {}
local playerGroups = {}
local nearbyNPCs = {}
local lastCommandTime = 0
local isMenuOpen = false

-- Initialize
CreateThread(function()
    lib.registerContext({
        id = 'npc_control_menu',
        title = Config.Menu.Title,
        position = Config.Menu.Position,
        options = {}
    })
    
    -- Register keybinds
    lib.registerKeyBind({
        name = 'npc_control_menu',
        description = 'Abrir Menu de Controle de NPCs',
        defaultKey = Config.Keys.NPCMenu,
        onPressed = function()
            if not isMenuOpen then
                OpenNPCControlMenu()
            end
        end,
    })
    
    if lib.checkDependency('ox_target') then
        SetupTargetSystem()
    end
    
    -- Start loops
    StartNPCUpdateLoop()
    StartProximityCheck()
end)

-- Functions
function OpenNPCControlMenu()
    local PlayerData = QBCore.Functions.GetPlayerData()
    local playerId = PlayerData.citizenid or GetPlayerServerId(PlayerId())
    
    -- Get player's NPCs and groups
    lib.callback('gang_npc:getPlayerData', false, function(data)
        if data and (data.npcs or data.groups) then
            BuildNPCControlMenu(data.npcs or {}, data.groups or {})
        else
            lib.notify({
                title = Config.Menu.Title,
                description = 'Você não possui NPCs para controlar',
                type = 'error',
                duration = Config.Notifications.Duration,
                position = Config.Notifications.Position
            })
        end
    end, playerId)
end

function BuildNPCControlMenu(npcs, groups)
    local options = {}
    
    -- Add NPCs section
    if #npcs > 0 then
        table.insert(options, {
            title = '👤 Meus NPCs (' .. #npcs .. ')',
            description = 'NPCs que você pode controlar',
            disabled = true
        })
        
        for _, npcData in pairs(npcs) do
            local npc = npcData.npc
            local permissionLevel = npcData.permission_level
            
            table.insert(options, {
                title = '🎯 ' .. GetGangName(npc.gang) .. ' - ' .. npc.id:sub(1, 8),
                description = 'Estado: ' .. npc.state .. ' | Nível: ' .. permissionLevel,
                icon = 'fas fa-user',
                iconColor = Config.GangColors[npc.gang],
                onSelect = function()
                    OpenNPCCommandMenu(npc, permissionLevel)
                end
            })
        end
    end
    
    -- Add Groups section
    if #groups > 0 then
        table.insert(options, {
            title = '👥 Meus Grupos (' .. #groups .. ')',
            description = 'Grupos que você pode controlar',
            disabled = true
        })
        
        for _, groupData in pairs(groups) do
            local group = groupData.group
            local permissionLevel = groupData.permission_level
            
            table.insert(options, {
                title = '🎯 ' .. group.name,
                description = 'Gangue: ' .. GetGangName(group.gang) .. ' | Nível: ' .. permissionLevel,
                icon = 'fas fa-users',
                iconColor = Config.GangColors[group.gang],
                onSelect = function()
                    OpenGroupCommandMenu(group, permissionLevel)
                end
            })
        end
    end
    
    -- Add nearby NPCs
    local nearby = GetNearbyNPCs()
    if #nearby > 0 then
        table.insert(options, {
            title = '📍 NPCs Próximos (' .. #nearby .. ')',
            description = 'NPCs no raio de ' .. Config.NPC.MaxDistance .. 'm',
            disabled = true
        })
        
        for _, npc in pairs(nearby) do
            table.insert(options, {
                title = '👁️ ' .. GetGangName(npc.gang) .. ' - ' .. npc.id:sub(1, 8),
                description = 'Distância: ' .. math.floor(npc.distance) .. 'm | Estado: ' .. npc.state,
                icon = 'fas fa-eye',
                onSelect = function()
                    -- Try to control if has permission
                    TryControlNearbyNPC(npc.id)
                end
            })
        end
    end
    
    if #options == 0 then
        table.insert(options, {
            title = '❌ Nenhum NPC Disponível',
            description = 'Você não possui NPCs para controlar',
            disabled = true
        })
    end
    
    lib.registerContext({
        id = 'npc_control_menu',
        title = Config.Menu.Title,
        position = Config.Menu.Position,
        options = options
    })
    
    lib.showContext('npc_control_menu')
    isMenuOpen = true
end

function OpenNPCCommandMenu(npc, permissionLevel)
    local options = {}
    
    -- Add NPC info
    table.insert(options, {
        title = '📊 Informações do NPC',
        description = 'ID: ' .. npc.id:sub(1, 8) .. ' | Vida: ' .. npc.health .. ' | Armadura: ' .. npc.armor,
        disabled = true
    })
    
    -- Add commands based on permission level
    for _, command in pairs(Config.Commands) do
        local canUse = true
        
        -- Check permission restrictions
        if command.id == "attack" and permissionLevel ~= "owner" then
            canUse = false
        end
        
        if canUse then
            table.insert(options, {
                title = command.label,
                description = command.description,
                icon = 'fas fa-chevron-right',
                onSelect = function()
                    ExecuteNPCCommand(npc.id, command.id)
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
        id = 'npc_command_menu',
        title = '🎮 Comandos - ' .. GetGangName(npc.gang),
        position = Config.Menu.Position,
        options = options
    })
    
    lib.showContext('npc_command_menu')
end

function OpenGroupCommandMenu(group, permissionLevel)
    local options = {}
    
    -- Add group info
    table.insert(options, {
        title = '📊 Informações do Grupo',
        description = 'Nome: ' .. group.name .. ' | Gangue: ' .. GetGangName(group.gang),
        disabled = true
    })
    
    -- Group commands
    local groupCommands = {
        {id = "follow", label = "🚶 Todos Seguir", description = "Todos NPCs do grupo seguem você"},
        {id = "stay", label = "🛑 Todos Parar", description = "Todos NPCs param"},
        {id = "peaceful", label = "☮️ Modo Pacífico", description = "Grupo em modo pacífico"},
        {id = "combat", label = "⚔️ Modo Combate", description = "Grupo em modo combate"}
    }
    
    for _, command in pairs(groupCommands) do
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
        id = 'group_command_menu',
        title = '🎮 Comandos - ' .. group.name,
        position = Config.Menu.Position,
        options = options
    })
    
    lib.showContext('group_command_menu')
end

function ExecuteNPCCommand(npcId, command)
    local PlayerData = QBCore.Functions.GetPlayerData()
    local playerId = PlayerData.citizenid or GetPlayerServerId(PlayerId())
    
    if GetGameTimer() - lastCommandTime < Config.NPC.CommandCooldown then
        lib.notify({
            title = 'Comando em Cooldown',
            description = 'Aguarde antes de enviar outro comando',
            type = 'warning',
            duration = Config.Notifications.Duration
        })
        return
    end
    
    local commandData = {
        npc_id = npcId,
        command = command,
        issued_by = playerId
    }
    
    -- Add position for certain commands
    if command == "guard" then
        local playerPed = PlayerPedId()
        local pos = GetEntityCoords(playerPed)
        commandData.position = {x = pos.x, y = pos.y, z = pos.z}
    elseif command == "attack" then
        -- Get target via raycast or selection
        local target = GetTargetPlayer()
        if target then
            commandData.target_id = tostring(target)
        else
            lib.notify({
                title = 'Erro no Comando',
                description = 'Nenhum alvo selecionado para atacar',
                type = 'error',
                duration = Config.Notifications.Duration
            })
            return
        end
    end
    
    TriggerServerEvent('gang_npc:sendCommand', commandData)
    lastCommandTime = GetGameTimer()
    
    lib.notify({
        title = 'Comando Enviado',
        description = 'Comando "' .. command .. '" enviado para NPC',
        type = 'success',
        duration = Config.Notifications.Duration
    })
end

function ExecuteGroupCommand(groupId, command)
    local PlayerData = QBCore.Functions.GetPlayerData()
    local playerId = PlayerData.citizenid or GetPlayerServerId(PlayerId())
    
    local commandData = {
        group_id = groupId,
        command = command,
        issued_by = playerId
    }
    
    TriggerServerEvent('gang_npc:sendGroupCommand', commandData)
    
    lib.notify({
        title = 'Comando de Grupo Enviado',
        description = 'Comando "' .. command .. '" enviado para grupo',
        type = 'success',
        duration = Config.Notifications.Duration
    })
end

function GetTargetPlayer()
    -- Raycast to get target
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    
    local endCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 10.0, 0.0)
    local rayHandle = StartShapeTestRay(coords.x, coords.y, coords.z, endCoords.x, endCoords.y, endCoords.z, 12, playerPed, 0)
    local retval, hit, hitCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHandle)
    
    if hit and entityHit > 0 then
        if IsPedAPlayer(entityHit) then
            local targetPlayer = NetworkGetPlayerIndexFromPed(entityHit)
            if targetPlayer ~= -1 then
                return GetPlayerServerId(targetPlayer)
            end
        end
    end
    
    return nil
end

function GetNearbyNPCs()
    -- This would be implemented to get NPCs in proximity
    -- For now, return empty array
    return {}
end

function StartNPCUpdateLoop()
    CreateThread(function()
        while true do
            -- Update NPC data every 5 seconds
            Wait(5000)
            
            local PlayerData = QBCore.Functions.GetPlayerData()
            if PlayerData and PlayerData.citizenid then
                lib.callback('gang_npc:getPlayerData', false, function(data)
                    if data then
                        playerNPCs = data.npcs or {}
                        playerGroups = data.groups or {}
                    end
                end, PlayerData.citizenid)
            end
        end
    end)
end

function StartProximityCheck()
    CreateThread(function()
        while true do
            Wait(2000)
            -- Check for nearby NPCs
            -- Implementation would involve checking entities around player
        end
    end)
end

function TryControlNearbyNPC(npcId)
    lib.notify({
        title = 'Funcionalidade em Desenvolvimento',
        description = 'Controle de NPCs próximos será implementado em breve',
        type = 'info',
        duration = Config.Notifications.Duration
    })
end

function GetGangName(gang)
    local gangNames = {
        ballas = "Ballas",
        grove_street = "Grove Street",
        vagos = "Vagos",
        lost_mc = "Lost MC",
        triads = "Triads",
        armenian_mafia = "Armenian Mafia"
    }
    return gangNames[gang] or gang
end

-- Event handlers
RegisterNetEvent('gang_npc:commandResponse', function(response)
    if response.success then
        lib.notify({
            title = 'Comando Executado',
            description = response.message,
            type = 'success',
            duration = Config.Notifications.Duration
        })
    else
        lib.notify({
            title = 'Erro no Comando',
            description = response.message,
            type = 'error',
            duration = Config.Notifications.Duration
        })
    end
end)

RegisterNetEvent('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print('[Gang NPC Manager] Cliente iniciado com sucesso!')
    end
end)

-- Exports
exports('GetPlayerNPCs', function()
    return playerNPCs
end)

exports('GetPlayerGroups', function()
    return playerGroups
end)

exports('SendNPCCommand', function(npcId, command, extraData)
    ExecuteNPCCommand(npcId, command)
end)

exports('GetNearbyNPCs', function()
    return GetNearbyNPCs()
end)
