local ePedState = lib.load("server.models.pedState")

local Ped = lib.class("Ped")

function Ped:constructor(id, region, coords)
    self.id = id
    self.region = region
    self.coords = coords
    self.spawning = false
    self.spawned = false
    self.netId = nil
    self.state = ePedState.waiting
    self.busy = false
    self.finishedTime = nil
end

function Ped:getState()
    return self.state
end

function Ped:setDead()
    self:changeState(ePedState.dead)
end

function Ped:setLooted()
    self:changeState(ePedState.looted)
end

function Ped:changeState(state)
    if self.state == state or
        (self.state == ePedState.dead and state ~= ePedState.waiting) then
        return
    end

    self.state = state

    if self.netId then
        local entity = NetworkGetEntityFromNetworkId(self.netId)

        Entity(entity).state.npcState = state
    end

    if self.state == ePedState.dead or
        self.state == ePedState.looted
    then
        self.finishedTime = os.time()
    end
end

function Ped:isBusy()
    return self.busy
end

function Ped:assignNetId(netId)
    self.netId = netId
    self.spawning = false
    self.spawned = true

    local entity = NetworkGetEntityFromNetworkId(self.netId)

    Entity(entity).state.npcState = self.state
end

function Ped:spawn()
    if self.state ~= ePedState.waiting then
        return false
    end

    if self.spawning then
        return false
    end

    if self.spawned then
        return false
    end

    self.spawning = true
    self.finishedTime = os.time()

    SetTimeout(math.random(50, 400), function()
        local playerId = self.region:getRandomPlayerInside()
        if playerId then
            TriggerClientEvent("rp_pedcreator:client:spawnNpc", playerId, self.region.id, self.id, self.state,
                self.coords)
        end
    end)

    return true
end

function Ped:delete()
    if not self.spawned or not self.netId then
        return false
    end

    local pedEntity = NetworkGetEntityFromNetworkId(self.netId)

    if DoesEntityExist(pedEntity) then DeleteEntity(pedEntity) end

    self.netId = nil
    self.spawned = false
    self.spawning = false

    return true
end

function Ped:update()
    local currentTime = os.time()

    if self.netId ~= nil and self.state ~= ePedState.dead then
        local entity = NetworkGetEntityFromNetworkId(self.netId)
        if DoesEntityExist(entity) and GetPedSourceOfDeath(entity) ~= 0 then
            self:changeState(ePedState.dead)
        elseif not DoesEntityExist(entity) then
            self:changeState(ePedState.waiting)
        end
    end

    if
        self.state == ePedState.dead or
        self.state == ePedState.looted or
        self.spawning
    then
        local diffTime = currentTime - (self?.finishedTime or 0)

        if diffTime >= Config.TimeToResetPed then
            self:delete()
            self:changeState(ePedState.waiting)
            return true
        end
    end

    return false
end

return Ped
