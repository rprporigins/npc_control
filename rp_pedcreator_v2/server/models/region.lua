local Region = lib.class('Region')

function Region:constructor(id, dificuldade, radius, coords, maxPeds)
    self.dificuldade = dificuldade
    self.id = id
    self.radius = radius
    self.coords = coords
    self.maxPeds = maxPeds
    self.peds = {}
    self.playersInside = {}
    self.processingRegion = false
    self.pedsCreated = 0
end

function Region:canStart()
    return os.time() >= self.timeToStart
end

function Region:assignPed(ped)
    self.peds[ped.id] = ped
end

function Region:isPlayerInside(playerId)
    for index, pId in ipairs(self.playersInside) do
        if playerId == pId then
            return true, index
        end
    end

    return false
end

function Region:addPlayer(playerId)
    local playerIsInside = self:isPlayerInside(playerId)

    if not playerIsInside then
        table.insert(self.playersInside, playerId)
        return true
    end

    return false
end

function Region:removePlayer(playerId)
    local playerIsInside, index = self:isPlayerInside(playerId)

    if playerIsInside then
        table.remove(self.playersInside, index)
        return true
    end

    return false
end

function Region:getPlayersInside()
    return self.playersInside
end

function Region:getRandomPlayerInside()
    if #self.playersInside == 0 then return nil end

    local playerId = self.playersInside[math.random(1, #self.playersInside)]

    if not DoesPlayerExist(playerId) then
        self:removePlayer(playerId)
        return self:getRandomPlayerInside()
    end

    return playerId
end

function Region:isEmpty()
    local players = self:getPlayersInside()

    return #players <= 0
end

function Region:triggerClientEvent(event, ...)
    local players = self:getPlayersInside()

    if #players <= 0 then return end

    lib.triggerClientEvent(event, players, ...)
end

function Region:requestSpawnEntities()
    self:requestSpawnPeds()
end

function Region:requestDespawnEntities()
    self:requestDeletePeds()
end

function Region:requestSpawnPeds()
    if self.processingRegion or self:isEmpty() then
        return
    end

    self.processingRegion = true

    if self.pedsCreated >= self.maxPeds then
        self.processingRegion = false
        return
    end

    for _, ped in pairs(self.peds) do
        if ped:spawn() then
            self.pedsCreated += 1
            if self.pedsCreated >= self.maxPeds then
                break
            end
        end
    end

    self.processingRegion = false
end

function Region:requestDeletePeds()
    if self.processingRegion then
        return
    end

    self.processingRegion = true

    for _, ped in pairs(self.peds) do
        if ped:delete() then
            self.pedsCreated -= 1
        end
    end

    if self.pedsCreated <= 0 then
        self.pedsCreated = 0
    end

    self.processingRegion = false
end

function Region:getPed(id)
    return self.peds[id]
end

function Region:update()
    for i, playerId in ipairs(self.playersInside) do
        if not DoesPlayerExist(playerId) then
            table.remove(self.playersInside, i)
        end
    end

    local needsRespawn = false

    for _, ped in pairs(self.peds) do
        if ped:update() then
            self.pedsCreated -= 1
            if not needsRespawn then
                needsRespawn = true
            end

            if self.pedsCreated <= 0 then
                self.pedsCreated = 0
            end
        end
    end

    if needsRespawn then
        self:requestSpawnPeds()
    end
end

return Region
