local StoreLocations = Config.spawnlocation

-- Sets the playerdata
CreateThread(function()
    AddRelationshipGroup("PLAYER")
    AddRelationshipGroup("npcguards")
    SetRelationshipBetweenGroups(0, `npcguards`, `npcguards`)
    SetRelationshipBetweenGroups(4, `npcguards`, `PLAYER`)
    SetRelationshipBetweenGroups(4, `PLAYER`, `npcguards`)
end)

lib.onCache('ped', function(ped)
    SetPedRelationshipGroupHash(ped, `PLAYER`)
end)


local function spawnPed(regionId, state, coords)
    local config = Config.spawnlocation[regionId]

    math.randomseed(GetGameTimer())
    
    local model = nil

    if config.policequest then
        local random = math.random(1,#Config.policepeds)
        model = Config.policepeds[config.dificuldade]
    else
        model = Config.pedmodel[config.dificuldade]
    end

    RequestModel(model)
    while not HasModelLoaded(model) do Citizen.Wait(1) end

    -- Find ground position before spawning
    local groundFound, groundZ = false, 0.0

    -- Try to get ground Z coordinate
    groundFound, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, true)

    -- If we can't find ground, adjust search parameters
    if not groundFound then
        -- Try from a higher position (in case we're under the map)
        groundFound, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 100.0, true)

        -- If still not found, try checking if the position is inside an interior
        if not groundFound then
            local interior = GetInteriorAtCoords(coords.x, coords.y, coords.z)
            if interior ~= 0 then
                -- Inside building, find a nearby outside position
                local offset = 5.0
                local attempts = 0
                local maxAttempts = 5

                while attempts < maxAttempts do
                    local angle = math.random() * math.pi * 2
                    local newX = coords.x + math.cos(angle) * offset
                    local newY = coords.y + math.sin(angle) * offset

                    groundFound, groundZ = GetGroundZFor_3dCoord(newX, newY, coords.z, true)

                    if groundFound then
                        coords = { x = newX, y = newY, z = groundZ }
                        break
                    end

                    offset = offset + 5.0
                    attempts = attempts + 1
                end
            end
        else
            -- Update coords with found ground Z
            coords = vector3(coords.x, coords.y, groundZ)
        end
    else
        -- Update coords with found ground Z
        coords = vector3(coords.x, coords.y, groundZ)
    end

    -- Validate position is clear (no buildings or objects)
    local isPositionClear = not IsPositionOccupied(coords.x, coords.y, coords.z, 1.0, false, true, true, false, false, 0,
        false)

    -- If position is not clear, try to find nearby clear position
    if not isPositionClear or not groundFound then
        local foundSafeSpot = false
        local safeCoords = { x = coords.x, y = coords.y, z = coords.z }
        local radius = 2.0
        local maxRadius = 20.0

        while not foundSafeSpot and radius <= maxRadius do
            local angle = math.random() * math.pi * 2
            local testX = coords.x + math.cos(angle) * radius
            local testY = coords.y + math.sin(angle) * radius

            local found, testZ = GetGroundZFor_3dCoord(testX, testY, coords.z, true)

            if found then
                local clear = not IsPositionOccupied(testX, testY, testZ, 1.0, false, true, true, false, false, 0, false)

                if clear then
                    safeCoords = { x = testX, y = testY, z = testZ }
                    foundSafeSpot = true
                    break
                end
            end

            radius = radius + 2.0
        end

        if foundSafeSpot then
            coords = safeCoords
        else
            -- If we still can't find a good spot, try one last method
            local rayHandle = StartShapeTestRay(coords.x, coords.y, coords.z + 100.0, coords.x, coords.y,
                coords.z - 100.0, 1, 0, 0)
            local _, hit, endCoords, _, _ = GetShapeTestResult(rayHandle)

            if hit == 1 then
                coords.z = endCoords.z + 1.0 -- Add a small offset to ensure the ped is above ground
            end
        end
    end

    heading = math.random(0, 359) + .0

    local ped_spawn = CreatePed(28, model, coords.x, coords.y, coords.z, heading, true, false)
    SetModelAsNoLongerNeeded(model)
    SetEntityMaxHealth(ped_spawn, 1000)
    NetworkRegisterEntityAsNetworked(ped_spawn)
    local netId = NetworkGetNetworkIdFromEntity(ped_spawn)
    SetNetworkIdExistsOnAllMachines(netId, true)
    SetNetworkIdCanMigrate(netId, true)
    SetPedRandomComponentVariation(ped_spawn, 0)
    SetPedRandomProps(ped_spawn)

    if Config.armour[config.dificuldade] then
        SetPedArmour(ped_spawn, Config.armour[config.dificuldade])
    end

    SetEntityMaxHealth(ped_spawn, Config.vida[config.dificuldade])
    SetPedMaxHealth(ped_spawn, Config.vida[config.dificuldade])
    SetEntityHealth(ped_spawn, Config.vida[config.dificuldade])
    SetPedDiesWhenInjured(ped_spawn, false)
    SetPedSuffersCriticalHits(ped_spawn, false)
    SetPedCanRagdoll(ped_spawn, false)
    SetPedCombatAttributes(ped_spawn, 46, true) -- Impede que o ped fuja de combate
    SetPedFleeAttributes(ped_spawn, 0, false)   -- Impede que o ped fuja
    SetPedShootRate(ped_spawn, 600)
    if Config.weapon[config.dificuldade] then
        GiveWeaponToPed(ped_spawn, Config.weapon[config.dificuldade], 255, false, false)
        SetCurrentPedWeapon(ped_spawn, Config.weapon[config.dificuldade], true)
    end

    -- Place entity on ground in case our Z coord is still slightly off
    PlaceObjectOnGroundProperly(ped_spawn)

    Wait(500)
    TaskWanderStandard(ped_spawn, 10.0, 10)
    --TaskStandGuard(ped_spawn , coords.x ,coords.y , coords.z , heading , 'WORLD_HUMAN_GUARD_STAND')

    SetPedSeeingRange(ped_spawn, 80.0)
    SetPedAccuracy(ped_spawn, 30)
    TaskGuardCurrentPosition(ped_spawn, 25.0, 25.0, 1)
    SetPedRelationshipGroupHash(ped_spawn, `npcguards`)

    return ped_spawn
end

RegisterNetEvent("rp_pedcreator:client:spawnNpc", function(regionId, pedId, state, coords)
    lib.print.info("SPAWNING NPC", regionId, pedId, state, coords)

    local ped = spawnPed(regionId, state, coords)

    NetworkRegisterEntityAsNetworked(ped)

    local netId = lib.waitFor(function()
        if DoesEntityExist(ped) then
            NetworkRegisterEntityAsNetworked(ped)
            local net = PedToNet(ped)

            if net > 0 then return net end
        end
    end, '', 20000)

    SetNetworkIdAlwaysExistsForPlayer(netId, cache.playerId, true)
    SetNetworkIdCanMigrate(netId, true)

    if not netId then return end

    TriggerServerEvent("rp_pedcreator:server:registerNpc", regionId, pedId, netId)
end)


AddEventHandler('entityDamaged', function(victim, attacker, weapon, _)
    if IsEntityDead(victim) and attacker == cache.ped then
        for _, v in ipairs(Config.peds['survive']) do
            if GetHashKey(v) == GetEntityModel(victim) then
                TriggerServerEvent("rp_creator:server:NpcKilled", PedToNet(victim))
                break
            end
        end
    end
end)
