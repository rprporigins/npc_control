-----------------------------------
-----------------------------------
-----------------------------------
-----------------------------------
-----------------------------------
-----------------------------------
RegisterNetEvent("rp_surviveloots:server:lootnpc", function(netid, model)
    local _source = source
    local model = tostring(model)
    if not Config.pedsloot[model] then
        lib.print.error("Failed to get Config.pedsloot for model", model)
        return TriggerClientEvent('QBCore:Notify', _source, 'Não tem nada aqui', 'error')
    end

    local quant = #Config.pedsloot[model]

    math.randomseed(os.time())

    local entity = NetworkGetEntityFromNetworkId(netid)
    local state = Entity(entity).state

    if not state.looted then
        state:set('looted', true, true)

        local ped = Peds[netid]

        if ped then ped:setLooted() end

        local retries = 0

        for i = 1, Config.quantloots do
            local index = math.random(1, quant)

            local itemQuantity = Config.pedsloot[model][index]
                .quant

            if itemQuantity < 1 then
                local chance = math.random(1, 100)

                if chance <= itemQuantity * 100 then
                    itemQuantity = 1
                else
                    itemQuantity = 0
                end
            end

            if itemQuantity >= 1 then
                exports.ox_inventory:AddItem(_source, Config.pedsloot[model][index].item, itemQuantity)
            else -- itemQuantity = 0
                i -= 1

                if i < 1 then i = 1 end

                retries += 1

                if retries >= 5 then break end
            end
        end

        --exports.rp_leveling:addExp(_source, "loot_body", 2)
    else
        TriggerClientEvent('QBCore:Notify', _source, 'Não tem nada aqui', 'error')
    end
end)

-----------------------------------
-----------------------------------
-----------------------------------
-----------------------------------
-----------------------------------
-----------------------------------

-- CreateThread(function()
--     while true do
--         -- print(json.encode(gang_spawn))

--         local time = os.time()

--         for _, location in pairs(Config.spawnlocation) do
--             for k, data in pairs(gang_spawn[location.label]) do
--                 if time >= data.time + 120 then
--                     local ped = NetworkGetEntityFromNetworkId(data.netid)

--                     if ped ~= 0 and DoesEntityExist(ped) then
--                         local vida = GetEntityHealth(ped)
--                         if k <= 3 then
--                             gang_spawn[location.label][k] = nil
--                             CreateThread(function()
--                                 Wait(5 * 60 * 1000)
--                                 if DoesEntityExist(ped) then
--                                     ClearPedTasks(ped)
--                                     DeleteEntity(ped)
--                                 end
--                             end)
--                         elseif vida <= 50 then
--                             gang_spawn[location.label][k] = nil
--                             CreateThread(function()
--                                 Wait(5 * 60 * 1000)
--                                 if DoesEntityExist(ped) then
--                                     ClearPedTasks(ped)
--                                     DeleteEntity(ped)
--                                 end
--                             end)
--                         end
--                     else
--                         gang_spawn[location.label][k] = nil
--                     end
--                 end
--             end
--         end

--         Wait(1 * 60 * 1000)
--     end
-- end)
