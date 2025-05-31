-- QBCore = exports['qb-core']:GetCoreObject()

-- lib.addCommand('pedcreator', {
--     help = 'comando criador de cenarios',
--     restricted = 'group.admin'
-- }, function(source, args)
--     TriggerClientEvent('pedcreator:client:menucreator', source)
-- end)

-- local peds = {}
-- RegisterNetEvent('pedcreator:server:registerzone', function(cenario)
--     while #peds < cenario.ped_quant do
--         ---- principal
--         local pos = cenario.coords
--         ---- positionped
--         local posX = pos.x + math.random(-cenario.radius, cenario.radius)
--         local posY = pos.y + math.random(-cenario.radius, cenario.radius)
--         local posZ = pos.z + 2
--         local heading = math.random(0, 359) + .0

--         --local ground, posZ = GetGroundZFor_3dCoord(posX + .0, posY + .0, Z, 1)

--         local typeped = Config.peds[cenario.pedstype][math.random(1, 4)]
--         --[[RequestModel(typeped)

--             while not HasModelLoaded(typeped) do
--                 Wait(1)
--             end]]

--         ---- createped
--         local ped = CreatePed(26, typeped, posX, posY, posZ, heading, true, false)
--         SetModelAsNoLongerNeeded(typeped)
--         local ped_net = NetworkGetNetworkIdFromEntity(ped)
--         SetPedRandomComponentVariation(ped, 0)
--         SetPedRandomProps(ped)
--         --SetEntityAsMissionEntity(ped)
--         --SetEntityVisible(ped, true)
--         --SetPedAccuracy(ped, cenario.ped_dificuldade)
--         SetPedArmour(ped, 0)
--         --SetPedCanSwitchWeapon(ped, true)
--         --SetPedDropsWeaponsWhenDead(ped, false)
--         --SetPedFleeAttributes(ped, 0, false)
--         GiveWeaponToPed(ped, `WEAPON_PISTOL`, 255, false, false)
--         SetCurrentPedWeapon(ped, `WEAPON_PISTOL`, true)
--         table.insert(peds, ped_net)
--         Wait(10)
--     end

--     TriggerClientEvent('pedcreator:client:zoneallserver', -1, peds, cenario)
-- end)

-- RegisterNetEvent('pedclient:server:deletepeds', function()
--     for k, v in ipairs(peds) do
--         local entity = NetworkGetEntityFromNetworkId(v)
--         ClearPedTasks(entity)
--         DeleteEntity(entity)
--     end
--     peds = {}
--     TriggerClientEvent('pedcreator:client:deleteentity', -1, peds_registrado)
-- end)

-- lib.callback.register('pedcreator:callback:permission', function(source)
--     local src = source
--     local Player = QBCore.Functions.GetPlayer(src)
--     local permission = QBCore.Config.Server.PermissionList[Player.PlayerData.steam]?.permission or false

--     return permission
-- end)

---------------------
---------------------
---------------------

-- local gang_spawn = {}
-- local onzone = {}
-- for _, location in pairs(Config.spawnlocation) do
--     gang_spawn[location.label] = {}
--     onzone[location.label] = {}
-- end

-- lib.callback.register('pedcreator:server:existente', function(source, locationLabel)
--     local citizenid = nil
--     for chave, value in pairs(onzone[locationLabel]) do
--         if value then
--             local player = QBCore.Functions.GetPlayerByCitizenId(value)

--             if player then
--                 citizenid = value
--                 break
--             else
--                 onzone[locationLabel][value] = nil
--             end
--         end
--     end

--     return gang_spawn[locationLabel], citizenid
-- end)

-- RegisterNetEvent('pedcreator:server:pedcriado', function(netsids, location)
--     for k, v in pairs(netsids) do
--         local bicho = {
--             netid = v,
--             location = location,
--             time = os.time()
--         }
--         table.insert(gang_spawn[location], bicho)
--     end
-- end)

-- RegisterNetEvent('pedcreator:server:ownerzone', function(locationLabel)
--     local Player = QBCore.Functions.GetPlayer(source)
--     local citizenid = Player.PlayerData.citizenid

--     if onzone[locationLabel][citizenid] == nil then
--         onzone[locationLabel][citizenid] = citizenid
--     else
--         print('ja registrado')
--     end
-- end)

-- RegisterNetEvent('pedcreator:server:offzone', function(locationLabel)
--     local Player = QBCore.Functions.GetPlayer(source)
--     if not Player then return end
--     local citizenid = Player.PlayerData.citizenid
--     onzone[locationLabel][citizenid] = nil
-- end)
