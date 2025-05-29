-- NUI Callbacks for Admin Panel

-- Handle NUI callbacks
RegisterNUICallback('spawnFromPanel', function(data, cb)
    TriggerServerEvent('gang_npc:spawnFromPanel', data)
    cb('ok')
end)

RegisterNUICallback('deleteFromPanel', function(data, cb)
    TriggerServerEvent('gang_npc:deleteFromPanel', data.npcId)
    cb('ok')
end)

RegisterNUICallback('updateFromPanel', function(data, cb)
    TriggerServerEvent('gang_npc:updateFromPanel', data.npcId, data.updateData)
    cb('ok')
end)

RegisterNUICallback('clearAllNPCs', function(data, cb)
    TriggerServerEvent('gang_npc:clearAllNPCs')
    cb('ok')
end)

RegisterNUICallback('refreshData', function(data, cb)
    TriggerServerEvent('gang_npc:openAdminPanel')
    cb('ok')
end)

RegisterNUICallback('closePanel', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Event to close NUI
RegisterNetEvent('gang_npc:closeAdminPanel')
AddEventHandler('gang_npc:closeAdminPanel', function()
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'closePanel'
    })
end)
