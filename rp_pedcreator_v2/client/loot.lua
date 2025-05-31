CreateThread(function()
    exports.sleepless_interact:addGlobalModel({
        models = Config.peds['survive'],
        options = {
            {
                name = "pedzone_",
                label = "Vasculhar",
                distance = 1.5,
                icon = "fa-light fa-hand", -- Example simple FA icon name
                onSelect = function(data)
                    TaskTurnPedToFaceEntity(PlayerPedId(), data.entity, 1500)
                    Wait(1500)

                    exports['xsound']:PlayUrlPos('looting', './sounds/looting.ogg', 0.3,
                        GetEntityCoords(data.entity))

                    if lib.progressCircle({
                            duration = math.random(6000, 8000),
                            useWhileDead = false,
                            canCancel = true,
                            allowRagdoll = false,
                            allowCuffed = false,
                            allowFalling = false,
                            disable = {
                                car = true,
                            },
                            anim = {
                                scenario = 'CODE_HUMAN_MEDIC_TEND_TO_DEAD',
                            },
                        }) then
                        if Entity(data.entity).state.looted then return end

                        exports['xsound']:Destroy('looting')
                        local model = GetEntityModel(data.entity)
                        local netId = NetworkGetNetworkIdFromEntity(data.entity)

                        TriggerServerEvent("rp_surviveloots:server:lootnpc", netId, model)
                        exports.sleepless_interact:removeEntity(data.entity)
                    else
                        exports['xsound']:Destroy('looting')
                        exports.qbx_core:Notify('Cancelado', 'error')
                    end
                end,
                renderDistance = 2.5,
                activeDistance = 2.0,
                cooldown = 1500,
                canInteract = function(pEntity)
                    return IsEntityDead(pEntity) and not Entity(pEntity).state.looted
                end
            }
        },
    })
end)
