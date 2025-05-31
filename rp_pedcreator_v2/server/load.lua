local StoreLocations = Config.spawnlocation
local Region = lib.load("server.models.region")
local Ped = lib.load("server.models.ped")

Regions = {}
Peds = {}
Loaded = false

CreateThread(function()
    for id, data in pairs(StoreLocations) do
        local region = Region:new(id, data.dificuldade, data.radius, coords, data.quantidade)

        for k, v in ipairs(data.coords_ped) do
            local ped = Ped:new(id .. k, region, v)

            region:assignPed(ped)
        end

        Regions[id] = region
    end

    Loaded = true
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for _, region in pairs(Regions) do
            region:requestDespawnEntities()
        end
    end
end)
