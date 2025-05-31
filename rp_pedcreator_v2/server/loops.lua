CreateThread(function()
    while not Loaded do Wait(1000) end

    while true do
        for _, region in pairs(Regions) do
            region:update()
        end

        Wait(3 * 60 * 1000)
    end
end)
