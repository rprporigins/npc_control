-- NUI Callbacks for Admin Panel

-- Close panel
RegisterNUICallback('closePanel', function(data, cb)
    Utils.Debug('NUI: Closing admin panel')
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Spawn NPCs from panel
RegisterNUICallback('spawnNPCs', function(data, cb)
    local source = source
    Utils.Debug('NUI: Spawn NPCs request:', json.encode(data))
    
    TriggerServerEvent('gang_npc:spawnFromPanel', data)
    cb('ok')
end)

-- Delete NPC
RegisterNUICallback('deleteNPC', function(data, cb)
    local source = source
    Utils.Debug('NUI: Delete NPC request:', data.npcId)
    
    TriggerServerEvent('gang_npc:deleteFromPanel', data.npcId)
    cb('ok')
end)

-- Update NPC
RegisterNUICallback('updateNPC', function(data, cb)
    local source = source
    Utils.Debug('NUI: Update NPC request:', data.npcId, json.encode(data.updateData))
    
    TriggerServerEvent('gang_npc:updateFromPanel', data.npcId, data.updateData)
    cb('ok')
end)

-- Bulk delete NPCs
RegisterNUICallback('bulkDeleteNPCs', function(data, cb)
    local source = source
    Utils.Debug('NUI: Bulk delete NPCs:', json.encode(data.npcIds))
    
    for _, npcId in ipairs(data.npcIds) do
        TriggerServerEvent('gang_npc:deleteFromPanel', npcId)
    end
    cb('ok')
end)

-- Refresh data
RegisterNUICallback('refreshData', function(data, cb)
    local source = source
    Utils.Debug('NUI: Refresh data request')
    
    TriggerServerEvent('gang_npc:openAdminPanel')
    cb('ok')
end)

-- Create group
RegisterNUICallback('createGroup', function(data, cb)
    local source = source
    Utils.Debug('NUI: Create group request:', json.encode(data))
    
    -- TODO: Implement group creation
    cb('ok')
end)

-- Delete group
RegisterNUICallback('deleteGroup', function(data, cb)
    local source = source
    Utils.Debug('NUI: Delete group request:', data.groupId)
    
    -- TODO: Implement group deletion
    cb('ok')
end)

-- Update settings
RegisterNUICallback('updateSettings', function(data, cb)
    local source = source
    Utils.Debug('NUI: Update settings request:', json.encode(data))
    
    -- TODO: Implement settings update
    cb('ok')
end)
