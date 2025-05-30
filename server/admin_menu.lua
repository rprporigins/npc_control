-- Admin Menu System using ox_lib
-- Substitui completamente a interface web problemática

local AdminMenu = {}
local currentData = {}

-- Comando para abrir menu admin
RegisterCommand('npcadmin', function(source, args, rawCommand)
    if not IsPlayerAceAllowed(source, Config.Permissions.AdminGroup) then
        Utils.Notify(source, 'Sem Permissão', 'Você não tem permissão para acessar o painel admin', 'error')
        return
    end
    
    -- Carregar dados e abrir menu
    AdminMenu.LoadData(source, function(data)
        currentData = data
        TriggerClientEvent('gang_npc:openAdminMenu', source, data)
    end)
end, true)

-- Função para carregar todos os dados necessários
function AdminMenu.LoadData(source, callback)
    Database.GetAllNPCs(function(npcs)
        Database.GetAllGroups(function(groups)
            local stats = {
                total_npcs = #npcs,
                total_groups = #groups,
                gang_distribution = {},
                active_players = #GetPlayers()
            }
            
            -- Calcular distribuição por gangue
            for _, npc in ipairs(npcs) do
                stats.gang_distribution[npc.gang] = (stats.gang_distribution[npc.gang] or 0) + 1
            end
            
            local data = {
                npcs = npcs,
                groups = groups,
                stats = stats,
                gangs = Config.Gangs
            }
            
            if callback then callback(data) end
        end)
    end)
end

-- Event handlers para ações do menu
RegisterServerEvent('gang_npc:adminSpawnNPCs')
AddEventHandler('gang_npc:adminSpawnNPCs', function(spawnData)
    local source = source
    
    if not IsPlayerAceAllowed(source, Config.Permissions.AdminGroup) then
        Utils.Notify(source, 'Sem Permissão', 'Você não tem permissão para spawnar NPCs', 'error')
        return
    end
    
    local Player = QBCore.Functions.GetPlayer(source)
    spawnData.spawned_by = Player.PlayerData.citizenid
    
    NPCManager.SpawnNPCs(spawnData, function(success, npcs)
        if success and npcs then
            Utils.Notify(source, 'Sucesso', #npcs .. ' NPCs spawnados com sucesso!', 'success')
        else
            Utils.Notify(source, 'Erro', 'Falha ao spawnar NPCs', 'error')
        end
    end)
end)

RegisterServerEvent('gang_npc:adminDeleteNPC')
AddEventHandler('gang_npc:adminDeleteNPC', function(npcId)
    local source = source
    
    if not IsPlayerAceAllowed(source, Config.Permissions.AdminGroup) then
        Utils.Notify(source, 'Sem Permissão', 'Você não tem permissão para deletar NPCs', 'error')
        return
    end
    
    NPCManager.DeleteNPC(npcId, function(success)
        if success then
            Utils.Notify(source, 'Sucesso', 'NPC removido com sucesso!', 'success')
        else
            Utils.Notify(source, 'Erro', 'Falha ao remover NPC', 'error')
        end
    end)
end)

RegisterServerEvent('gang_npc:adminUpdateNPC')
AddEventHandler('gang_npc:adminUpdateNPC', function(npcId, updateData)
    local source = source
    
    if not IsPlayerAceAllowed(source, Config.Permissions.AdminGroup) then
        Utils.Notify(source, 'Sem Permissão', 'Você não tem permissão para editar NPCs', 'error')
        return
    end
    
    Database.UpdateNPC(npcId, updateData, function(success)
        if success then
            Utils.Notify(source, 'Sucesso', 'NPC atualizado com sucesso!', 'success')
            
            -- Atualizar NPC ativo se existir
            local npcInfo = NPCManager.ActiveNPCs[npcId]
            if npcInfo then
                local entity = npcInfo.entity
                if DoesEntityExist(entity) then
                    if updateData.health then
                        SetEntityHealth(entity, updateData.health)
                    end
                    if updateData.armor then
                        SetPedArmour(entity, updateData.armor)
                    end
                    if updateData.accuracy then
                        SetPedAccuracy(entity, updateData.accuracy)
                    end
                end
                
                -- Atualizar dados armazenados
                for key, value in pairs(updateData) do
                    npcInfo.data[key] = value
                end
            end
        else
            Utils.Notify(source, 'Erro', 'Falha ao atualizar NPC', 'error')
        end
    end)
end)

RegisterServerEvent('gang_npc:adminBulkDelete')
AddEventHandler('gang_npc:adminBulkDelete', function(npcIds)
    local source = source
    
    if not IsPlayerAceAllowed(source, Config.Permissions.AdminGroup) then
        Utils.Notify(source, 'Sem Permissão', 'Você não tem permissão para deletar NPCs', 'error')
        return
    end
    
    local deleted = 0
    for _, npcId in ipairs(npcIds) do
        NPCManager.DeleteNPC(npcId, function(success)
            if success then
                deleted = deleted + 1
            end
        end)
    end
    
    Utils.Notify(source, 'Sucesso', deleted .. ' NPCs removidos!', 'success')
end)

RegisterServerEvent('gang_npc:adminClearAllNPCs')
AddEventHandler('gang_npc:adminClearAllNPCs', function()
    local source = source
    
    if not IsPlayerAceAllowed(source, Config.Permissions.AdminGroup) then
        Utils.Notify(source, 'Sem Permissão', 'Você não tem permissão para limpar NPCs', 'error')
        return
    end
    
    local count = 0
    for npcId, _ in pairs(NPCManager.ActiveNPCs) do
        NPCManager.DeleteNPC(npcId)
        count = count + 1
    end
    
    Utils.Notify(source, 'Sucesso', count .. ' NPCs removidos!', 'success')
end)

-- Callback para obter dados atualizados
lib.callback.register('gang_npc:getAdminData', function(source)
    if not IsPlayerAceAllowed(source, Config.Permissions.AdminGroup) then
        return nil
    end
    
    local npcs = {}
    local groups = {}
    
    -- Obter NPCs do database
    Database.GetAllNPCs(function(npcData)
        npcs = npcData
    end)
    
    -- Obter grupos do database
    Database.GetAllGroups(function(groupData)
        groups = groupData
    end)
    
    -- Calcular estatísticas
    local stats = {
        total_npcs = #npcs,
        total_groups = #groups,
        gang_distribution = {},
        active_players = #GetPlayers()
    }
    
    for _, npc in ipairs(npcs) do
        stats.gang_distribution[npc.gang] = (stats.gang_distribution[npc.gang] or 0) + 1
    end
    
    return {
        npcs = npcs,
        groups = groups,
        stats = stats,
        gangs = Config.Gangs
    }
end)