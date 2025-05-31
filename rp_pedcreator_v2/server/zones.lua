local playerZones = {}

local function addPlayerToZone(playerId, zoneId)
    local zone = Regions[zoneId]

    if not zone then return end

    zone:addPlayer(playerId)
    if not playerZones[playerId] then
        playerZones[playerId] = {}
    end

    playerZones[playerId][zoneId] = true

    zone:requestSpawnEntities(playerId)
end

local function removePlayerFromZone(playerId, zoneId)
    local zone = Regions[zoneId]

    if not zone then return end

    zone:removePlayer(playerId)

    if playerZones[playerId]?[zoneId] then
        playerZones[playerId][zoneId] = nil
    end

    if zone:isEmpty() then
        zone:requestDespawnEntities(playerId)
    end
end

RegisterNetEvent("rp_pedcreator:server:playerEnterZone", function(zoneId)
    local _source = source

    while not Loaded do
        Wait(100)
    end

    addPlayerToZone(_source, zoneId)
end)

RegisterNetEvent("rp_pedcreator:server:playerLeaveZone", function(zoneId)
    local _source = source

    while not Loaded do
        Wait(100)
    end

    removePlayerFromZone(_source, zoneId)
end)

AddEventHandler('qbx_core:Server:PlayerLeft', function(playerId)
    if playerZones[playerId] then
        for zoneName, _ in pairs(playerZones[playerId]) do
            removePlayerFromZone(playerId, zoneName)
        end

        playerZones[playerId] = nil
    end
end)

RegisterNetEvent("rp_pedcreator:server:registerNpc", function(regionId, pedId, netId)
    while not Loaded do
        Wait(100)
    end

    local zone = Regions[regionId]

    if not zone then return end

    local ped = zone:getPed(pedId)

    ped:assignNetId(netId)

    Peds[netId] = ped
end)

RegisterNetEvent("rp_creator:server:NpcKilled", function(netId)
    local _source = source
    local ped = Peds[netId]

    if not ped then return end

    ped:setDead()

    local entity = NetworkGetEntityFromNetworkId(netId)

    local model = GetEntityModel(entity)

    -- if Config.ExpForPed[model] then
    --     exports.rp_leveling:addExp(_source, "assassination", Config.ExpForPed[model])
    -- end
end)
