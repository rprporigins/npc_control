-- NPC Management System

NPCManager = {}
NPCManager.ActiveNPCs = {} -- [npcId] = {entity, data}
NPCManager.PlayerNPCs = {} -- [citizenid] = {npcIds}

-- Initialize NPC Manager
function NPCManager.Init()
    Utils.Debug('NPCManager initialized')
    
    -- Load existing NPCs from database
    NPCManager.LoadExistingNPCs()
    
    -- Start periodic save
    NPCManager.StartPeriodicSave()
    
    -- Start cleanup routine
    NPCManager.StartCleanup()
end

-- Load existing NPCs from database
function NPCManager.LoadExistingNPCs()
    Database.GetAllNPCs(function(npcs)
        Utils.Debug('Loading', #npcs, 'NPCs from database')
        
        for _, npcData in ipairs(npcs) do
            NPCManager.SpawnNPCEntity(npcData)
        end
    end)
end

-- Spawn NPC entity in world
function NPCManager.SpawnNPCEntity(npcData)
    local model = GetHashKey(npcData.model)
    
    if not IsModelValid(model) then
        Utils.Debug('Invalid model:', npcData.model)
        return false
    end
    
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 100 do
        Wait(100)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(model) then
        Utils.Debug('Failed to load model:', npcData.model)
        return false
    end
    
    local ped = CreatePed(4, model, npcData.position.x, npcData.position.y, npcData.position.z, npcData.heading or 0.0, true, true)
    
    if not DoesEntityExist(ped) then
        Utils.Debug('Failed to create NPC entity for:', npcData.id)
        return false
    end
    
    -- Configure NPC
    SetPedMaxHealth(ped, npcData.health or 100)
    SetEntityHealth(ped, npcData.health or 100)
    SetPedArmour(ped, npcData.armor or 0)
    SetPedAccuracy(ped, npcData.accuracy or 50)
    
    -- Set weapon
    if npcData.weapon then
        GiveWeaponToPed(ped, GetHashKey(npcData.weapon), 250, false, true)
    end
    
    -- Make NPC a bit more durable
    SetEntityInvincible(ped, false) -- Allow damage for realism
    SetPedCanRagdoll(ped, true)
    SetPedFleeAttributes(ped, 0, false) -- Don't flee
    SetPedCombatAttributes(ped, 46, true) -- Always fight
    
    -- Store NPC data (decorators will be set client-side)
    NPCManager.ActiveNPCs[npcData.id] = {
        entity = ped,
        data = npcData,
        lastUpdate = GetGameTimer()
    }
    
    -- Track player ownership
    NPCManager.UpdatePlayerTracking(npcData)
    
    -- Apply current state
    NPCManager.ApplyNPCState(npcData.id, npcData.state or 'idle')
    
    Utils.Debug('Spawned NPC:', npcData.id, 'Entity:', ped)
    
    -- Trigger client events to set decorators
    TriggerClientEvent('gang_npc:npcSpawned', -1, npcData, ped)
    TriggerClientEvent('gang_npc:setNPCDecorators', -1, ped, npcData.id, npcData.gang)
    
    return ped
end

-- Update player tracking
function NPCManager.UpdatePlayerTracking(npcData)
    local allPlayers = {}
    
    -- Add owners
    if npcData.owners then
        for _, playerId in ipairs(npcData.owners) do
            table.insert(allPlayers, playerId)
        end
    end
    
    -- Add leaders
    if npcData.leaders then
        for _, playerId in ipairs(npcData.leaders) do
            table.insert(allPlayers, playerId)
        end
    end
    
    -- Add friends
    if npcData.friends then
        for _, playerId in ipairs(npcData.friends) do
            table.insert(allPlayers, playerId)
        end
    end
    
    -- Update tracking
    for _, playerId in ipairs(allPlayers) do
        if not NPCManager.PlayerNPCs[playerId] then
            NPCManager.PlayerNPCs[playerId] = {}
        end
        
        local found = false
        for _, npcId in ipairs(NPCManager.PlayerNPCs[playerId]) do
            if npcId == npcData.id then
                found = true
                break
            end
        end
        
        if not found then
            table.insert(NPCManager.PlayerNPCs[playerId], npcData.id)
        end
    end
end

-- Spawn multiple NPCs
function NPCManager.SpawnNPCs(spawnData, callback)
    local spawned = {}
    local gangConfig = Utils.GetGangConfig(spawnData.gang)
    
    if not gangConfig then
        if callback then callback(false, 'Invalid gang') end
        return
    end
    
    -- Validate model
    local model = spawnData.model or gangConfig.models[1]
    if not Utils.IsValidModelForGang(model, spawnData.gang) then
        if callback then callback(false, 'Invalid model for gang') end
        return
    end
    
    -- Validate weapon
    local weapon = spawnData.weapon or gangConfig.weapons[1]
    if not Utils.IsValidWeaponForGang(weapon, spawnData.gang) then
        if callback then callback(false, 'Invalid weapon for gang') end
        return
    end
    
    -- Parse position from vec3 if provided
    local position = spawnData.position
    if spawnData.vec3_input then
        local parsedPos = Utils.ParseVec3(spawnData.vec3_input)
        if parsedPos then
            position = parsedPos
        end
    end
    
    if not position then
        position = {x = 0, y = 0, z = 0}
    end
    
    -- Generate group ID for multiple spawns
    local groupId = nil
    if spawnData.quantity > 1 then
        groupId = Utils.GenerateId()
    end
    
    local completed = 0
    local total = spawnData.quantity or 1
    
    for i = 0, total - 1 do
        local npcPosition = Utils.CalculateFormationPosition(position, i, spawnData.formation or 'circle', total)
        
        local npcData = {
            id = Utils.GenerateId(),
            gang = spawnData.gang,
            model = model,
            position = npcPosition,
            heading = spawnData.heading or 0.0,
            health = spawnData.health or gangConfig.defaultHealth,
            armor = spawnData.armor or gangConfig.defaultArmor,
            accuracy = spawnData.accuracy or 50,
            weapon = weapon,
            state = 'idle',
            owners = Utils.ParseCommaSeparated(spawnData.owner_ids or ''),
            leaders = Utils.ParseCommaSeparated(spawnData.leader_ids or ''),
            friends = Utils.ParseCommaSeparated(spawnData.friend_ids or ''),
            enemies = Utils.ParseCommaSeparated(spawnData.enemy_ids or ''),
            group_id = groupId,
            advanced_group_id = spawnData.advanced_group_id,
            created_at = os.time(),
            last_updated = os.time()
        }
        
        -- Save to database
        Database.CreateNPC(npcData, function(success)
            if success then
                -- Spawn entity
                local entity = NPCManager.SpawnNPCEntity(npcData)
                if entity then
                    table.insert(spawned, npcData)
                    
                    -- Log action
                    Database.CreateLog({
                        action = 'npc_spawned',
                        player_id = spawnData.spawned_by or 'system',
                        npc_id = npcData.id,
                        group_id = groupId,
                        data = {gang = spawnData.gang, model = model}
                    })
                end
            end
            
            completed = completed + 1
            if completed >= total and callback then
                callback(#spawned > 0, spawned)
            end
        end)
    end
end

-- Delete NPC
function NPCManager.DeleteNPC(npcId, callback)
    local npcInfo = NPCManager.ActiveNPCs[npcId]
    
    if npcInfo then
        -- Delete entity if it exists
        if DoesEntityExist(npcInfo.entity) then
            DeleteEntity(npcInfo.entity)
            Utils.Debug('Deleted NPC entity:', npcInfo.entity)
        end
        
        -- Remove from active NPCs
        NPCManager.ActiveNPCs[npcId] = nil
        
        -- Remove from player tracking
        for playerId, npcList in pairs(NPCManager.PlayerNPCs) do
            for i, id in ipairs(npcList) do
                if id == npcId then
                    table.remove(npcList, i)
                    break
                end
            end
        end
        
        -- Trigger client event
        TriggerClientEvent('gang_npc:npcDeleted', -1, npcId, npcInfo.entity)
    end
    
    -- Delete from database
    Database.DeleteNPC(npcId, function(success)
        if callback then callback(success) end
        
        if success then
            Database.CreateLog({
                action = 'npc_deleted',
                npc_id = npcId
            })
        end
    end)
end

-- Apply state to NPC
function NPCManager.ApplyNPCState(npcId, state, extraData)
    local npcInfo = NPCManager.ActiveNPCs[npcId]
    if not npcInfo or not DoesEntityExist(npcInfo.entity) then
        Utils.Debug('Cannot apply state - NPC not found or entity does not exist:', npcId)
        return false
    end
    
    local ped = npcInfo.entity
    
    -- Clear current tasks
    ClearPedTasks(ped)
    
    if state == 'idle' then
        -- Just stand around
        TaskStandStill(ped, -1)
        
    elseif state == 'following' then
        -- Follow target (usually the commander)
        if extraData and extraData.target_player then
            local targetSource = extraData.target_player
            local targetPed = GetPlayerPed(targetSource)
            if DoesEntityExist(targetPed) then
                TaskFollowToOffsetOfEntity(ped, targetPed, 0.0, -3.0, 0.0, 5.0, -1, 3.0, true)
                Utils.Debug('NPC', npcId, 'following player', targetSource)
            end
        end
        
    elseif state == 'guarding' then
        -- Guard a specific position
        if extraData and extraData.guard_position then
            local pos = extraData.guard_position
            TaskGuardCurrentPosition(ped, 15.0, 15.0, true)
        else
            -- Guard current position
            TaskGuardCurrentPosition(ped, 15.0, 15.0, true)
        end
        
    elseif state == 'peaceful' then
        -- Non-aggressive mode
        SetPedCombatAbility(ped, 0)
        SetPedFleeAttributes(ped, 0, true)
        SetPedCombatAttributes(ped, 46, false)
        
    elseif state == 'combat' then
        -- Aggressive mode
        SetPedCombatAbility(ped, 100)
        SetPedCombatAttributes(ped, 46, true)
        SetPedCombatAttributes(ped, 5, true)
        SetPedFleeAttributes(ped, 0, false)
        
    elseif state == 'attacking' then
        -- Attack specific target
        if extraData and extraData.target_player then
            local targetSource = extraData.target_player
            local targetPed = GetPlayerPed(targetSource)
            if DoesEntityExist(targetPed) then
                TaskCombatPed(ped, targetPed, 0, 16)
                Utils.Debug('NPC', npcId, 'attacking player', targetSource)
            end
        end
    end
    
    -- Update data
    npcInfo.data.state = state
    npcInfo.lastUpdate = GetGameTimer()
    
    Utils.Debug('Applied state', state, 'to NPC', npcId)
    return true
end

-- Send command to NPC
function NPCManager.SendCommand(commandData, callback)
    local npcId = commandData.npc_id
    local command = commandData.command
    local issuedBy = commandData.issued_by
    
    -- Get NPC data
    local npcInfo = NPCManager.ActiveNPCs[npcId]
    if not npcInfo then
        if callback then callback(false, 'NPC not found') end
        return
    end
    
    -- Check permissions
    local hasPermission = Utils.HasPermission(issuedBy, Config.Commands[command].permission, npcInfo.data)
    if not hasPermission then
        if callback then callback(false, 'No permission') end
        return
    end
    
    -- Prepare extra data based on command
    local extraData = {}
    
    if command == 'follow' then
        -- Find the source ID from citizenid
        local targetSource = nil
        for _, playerId in pairs(GetPlayers()) do
            local Player = QBCore.Functions.GetPlayer(tonumber(playerId))
            if Player and Player.PlayerData.citizenid == issuedBy then
                targetSource = tonumber(playerId)
                break
            end
        end
        if targetSource then
            extraData.target_player = targetSource
        end
    elseif command == 'guard' then
        extraData.guard_position = commandData.position
    elseif command == 'attack' then
        if commandData.target_id then
            extraData.target_player = tonumber(commandData.target_id)
        end
    end
    
    -- Apply command (map command to state)
    local stateMap = {
        follow = 'following',
        stay = 'idle',
        guard = 'guarding',
        peaceful = 'peaceful',
        combat = 'combat',
        attack = 'attacking',
        patrol = 'patrol'
    }
    
    local newState = stateMap[command] or command
    local success = NPCManager.ApplyNPCState(npcId, newState, extraData)
    
    if success then
        -- Update database
        Database.UpdateNPC(npcId, {
            state = newState,
            last_command = command,
            last_command_by = issuedBy
        })
        
        -- Log action
        Database.CreateLog({
            action = 'npc_command',
            player_id = issuedBy,
            npc_id = npcId,
            data = {command = command}
        })
        
        if callback then callback(true, 'Command executed successfully') end
    else
        if callback then callback(false, 'Failed to apply command') end
    end
end

-- Get player NPCs
function NPCManager.GetPlayerNPCs(playerId, callback)
    Database.GetPlayerNPCs(playerId, function(npcs)
        local result = {}
        
        for _, npc in ipairs(npcs) do
            local permissionLevel = Utils.GetPermissionLevel(playerId, npc)
            if permissionLevel ~= 'none' then
                table.insert(result, {
                    npc = npc,
                    permission_level = permissionLevel
                })
            end
        end
        
        if callback then callback(result) end
    end)
end

-- Start periodic save
function NPCManager.StartPeriodicSave()
    CreateThread(function()
        while true do
            Wait(Config.NPC.SaveInterval)
            
            local savedCount = 0
            for npcId, npcInfo in pairs(NPCManager.ActiveNPCs) do
                if DoesEntityExist(npcInfo.entity) then
                    -- Update position
                    local coords = GetEntityCoords(npcInfo.entity)
                    local heading = GetEntityHeading(npcInfo.entity)
                    
                    Database.UpdateNPC(npcId, {
                        position = {x = coords.x, y = coords.y, z = coords.z},
                        heading = heading,
                        health = GetEntityHealth(npcInfo.entity),
                        armor = GetPedArmour(npcInfo.entity)
                    })
                    savedCount = savedCount + 1
                else
                    -- NPC entity was deleted, remove from active list
                    NPCManager.ActiveNPCs[npcId] = nil
                end
            end
            
            if savedCount > 0 then
                Utils.Debug('Periodic save completed for', savedCount, 'NPCs')
            end
        end
    end)
end

-- Start cleanup routine
function NPCManager.StartCleanup()
    CreateThread(function()
        while true do
            Wait(Config.NPC.CleanupTime)
            
            local currentTime = GetGameTimer()
            local cleaned = 0
            
            for npcId, npcInfo in pairs(NPCManager.ActiveNPCs) do
                -- Check if NPC has been inactive
                if currentTime - npcInfo.lastUpdate > Config.NPC.CleanupTime then
                    if not DoesEntityExist(npcInfo.entity) then
                        NPCManager.ActiveNPCs[npcId] = nil
                        cleaned = cleaned + 1
                    end
                end
            end
            
            if cleaned > 0 then
                Utils.Debug('Cleaned up', cleaned, 'inactive NPCs')
            end
        end
    end)
end

-- Initialize
CreateThread(function()
    Wait(2000) -- Wait for database
    NPCManager.Init()
end)