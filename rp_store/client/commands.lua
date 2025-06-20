-- Handle server event to open the interface
RegisterNetEvent('rprp_store:openInterface')
AddEventHandler('rprp_store:openInterface', function()
    -- Send NUI message to show the interface
    SendNUIMessage({
        action = 'setVisible',
        data = true
    })

    -- Set NUI focus to allow keyboard input (e.g., Escape key)
    SetNuiFocus(true, true)
end)

-- Handle NUI callback to hide the frame (called when Escape is pressed)
RegisterNUICallback('hideFrame', function(data, cb)
    -- Hide the interface
    SendNUIMessage({
        action = 'setVisible',
        data = false
    })

    -- Remove NUI focus
    SetNuiFocus(false, false)

    cb('ok')
end)