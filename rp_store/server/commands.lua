-- Register command to open the store interface
RegisterCommand('openstore', function(source, args, rawCommand)
    -- Optional: Add permission check (e.g., for admins or specific players)
    -- if not IsPlayerAceAllowed(source, 'rprp_store.open') then
    --     TriggerClientEvent('chat:addMessage', source, {
    --         color = {255, 0, 0},
    --         multiline = true,
    --         args = {'[Store]', 'You do not have permission to open the store.'}
    --     })
    --     return
    -- end

    -- Trigger client-side event to show the NUI
    TriggerClientEvent('rprp_store:openInterface', source)
end, true)