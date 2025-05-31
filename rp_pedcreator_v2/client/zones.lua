local StoreLocations = Config.spawnlocation

local zones = {}

local function onExitZone(zone)
    TriggerServerEvent("rp_pedcreator:server:playerLeaveZone", zone.key)

    -- CurrentStore    = nil
    -- TillStates      = {
    --     primary = eTillState.none,
    --     secondary = eTillState.none
    -- }
    -- ShopkeeperNetId = nil
    -- ShopkeeperState = eShopkeeperState.none
end

local function onEnterZone(zone)
    lib.print.info("ENTERED ZONE ", zone.key)
    TriggerServerEvent("rp_pedcreator:server:playerEnterZone", zone.key)

    -- CreateTillTargets()
end

local function createZone(id, data)
    zones[id] = lib.points.new({
        key = id,
        coords = data.coords,
        distance = data.radius,
        onEnter = function(self) onEnterZone(self) end,
        onExit = function(self) onExitZone(self) end
    })
end

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    Wait(1000)

    for index, data in pairs(StoreLocations) do
        createZone(index, data)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for _, zone in pairs(zones) do
        zone:remove()
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    if LocalPlayer.state.isLoggedIn then
        Wait(1000)

        for index, data in pairs(StoreLocations) do
            createZone(index, data)
        end
    end
end)
