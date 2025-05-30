-- Client-side Admin Menu using ox_lib
-- Sistema completo de menus administrativos

local AdminMenuClient = {}
local adminData = {}

-- Event para abrir menu admin
RegisterNetEvent('gang_npc:openAdminMenu')
AddEventHandler('gang_npc:openAdminMenu', function(data)
    adminData = data
    AdminMenuClient.OpenMainMenu()
end)

-- Menu principal do admin
function AdminMenuClient.OpenMainMenu()
    local options = {
        {
            title = '📊 Dashboard',
            description = string.format('NPCs: %d | Grupos: %d | Players: %d', 
                adminData.stats.total_npcs, adminData.stats.total_groups, adminData.stats.active_players),
            icon = 'fas fa-tachometer-alt',
            onSelect = function()
                AdminMenuClient.OpenDashboard()
            end
        },
        {
            title = '🤖 Gerenciar NPCs',
            description = 'Visualizar, editar e deletar NPCs',
            icon = 'fas fa-robot',
            onSelect = function()
                AdminMenuClient.OpenNPCsMenu()
            end
        },
        {
            title = '👥 Grupos',
            description = 'Gerenciar grupos de NPCs',
            icon = 'fas fa-users',
            onSelect = function()
                AdminMenuClient.OpenGroupsMenu()
            end
        },
        {
            title = '🚀 Spawnar NPCs',
            description = 'Criar novos NPCs',
            icon = 'fas fa-plus-circle',
            onSelect = function()
                AdminMenuClient.OpenSpawnMenu()
            end
        },
        {
            title = '⚡ Ações Rápidas',
            description = 'Comandos administrativos rápidos',
            icon = 'fas fa-bolt',
            onSelect = function()
                AdminMenuClient.OpenQuickActions()
            end
        },
        {
            title = '🔄 Atualizar Dados',
            description = 'Recarregar informações',
            icon = 'fas fa-sync',
            onSelect = function()
                AdminMenuClient.RefreshData()
            end
        }
    }

    lib.registerContext({
        id = 'gang_npc_admin_main',
        title = '🎮 Gang NPC Manager - Admin',
        options = options
    })

    lib.showContext('gang_npc_admin_main')
end

-- Dashboard com estatísticas
function AdminMenuClient.OpenDashboard()
    local options = {
        {
            title = '📈 Estatísticas Gerais',
            description = 'Visão geral do sistema',
            disabled = true
        },
        {
            title = string.format('🤖 NPCs Ativos: %d', adminData.stats.total_npcs),
            description = 'Total de NPCs no servidor',
            disabled = true
        },
        {
            title = string.format('👥 Grupos: %d', adminData.stats.total_groups),
            description = 'Total de grupos criados',
            disabled = true
        },
        {
            title = string.format('🎮 Players Online: %d', adminData.stats.active_players),
            description = 'Jogadores conectados',
            disabled = true
        }
    }

    -- Adicionar distribuição por gangue
    if adminData.stats.gang_distribution then
        table.insert(options, {
            title = '🏴 Distribuição por Gangue',
            description = 'NPCs por gangue',
            disabled = true
        })

        for gangId, count in pairs(adminData.stats.gang_distribution) do
            local gangConfig = adminData.gangs[gangId]
            if gangConfig then
                table.insert(options, {
                    title = string.format('  • %s: %d NPCs', gangConfig.name, count),
                    description = string.format('Cor: %s', gangConfig.color),
                    disabled = true
                })
            end
        end
    end

    table.insert(options, {
        title = '🔙 Voltar',
        description = 'Voltar ao menu principal',
        icon = 'fas fa-arrow-left',
        onSelect = function()
            AdminMenuClient.OpenMainMenu()
        end
    })

    lib.registerContext({
        id = 'gang_npc_admin_dashboard',
        title = '📊 Dashboard',
        options = options
    })

    lib.showContext('gang_npc_admin_dashboard')
end

-- Menu de NPCs
function AdminMenuClient.OpenNPCsMenu()
    local options = {
        {
            title = string.format('📋 NPCs Disponíveis (%d)', #adminData.npcs),
            description = 'Lista de todos os NPCs',
            disabled = true
        }
    }

    if #adminData.npcs == 0 then
        table.insert(options, {
            title = '❌ Nenhum NPC encontrado',
            description = 'Não há NPCs para mostrar',
            disabled = true
        })
    else
        for i, npc in ipairs(adminData.npcs) do
            if i <= 20 then -- Limitar a 20 para performance
                local gangConfig = adminData.gangs[npc.gang]
                local gangName = gangConfig and gangConfig.name or npc.gang
                
                table.insert(options, {
                    title = string.format('🎯 %s - %s', gangName, npc.id:sub(1, 8)),
                    description = string.format('Estado: %s | Vida: %d%% | Modelo: %s', 
                        npc.state or 'idle', npc.health or 100, npc.model),
                    onSelect = function()
                        AdminMenuClient.OpenNPCActions(npc)
                    end
                })
            end
        end

        if #adminData.npcs > 20 then
            table.insert(options, {
                title = string.format('... e mais %d NPCs', #adminData.npcs - 20),
                description = 'Use filtros ou comandos para gerenciar mais NPCs',
                disabled = true
            })
        end
    end

    table.insert(options, {
        title = '🗑️ Deletar Todos os NPCs',
        description = 'ATENÇÃO: Remove todos os NPCs',
        icon = 'fas fa-trash',
        onSelect = function()
            AdminMenuClient.ConfirmClearAll()
        end
    })

    table.insert(options, {
        title = '🔙 Voltar',
        description = 'Voltar ao menu principal',
        icon = 'fas fa-arrow-left',
        onSelect = function()
            AdminMenuClient.OpenMainMenu()
        end
    })

    lib.registerContext({
        id = 'gang_npc_admin_npcs',
        title = '🤖 Gerenciar NPCs',
        options = options
    })

    lib.showContext('gang_npc_admin_npcs')
end

-- Ações para NPC específico
function AdminMenuClient.OpenNPCActions(npc)
    local gangConfig = adminData.gangs[npc.gang]
    local gangName = gangConfig and gangConfig.name or npc.gang

    local options = {
        {
            title = string.format('🎯 %s', gangName),
            description = string.format('ID: %s | Modelo: %s', npc.id:sub(1, 8), npc.model),
            disabled = true
        },
        {
            title = '✏️ Editar NPC',
            description = 'Modificar propriedades do NPC',
            icon = 'fas fa-edit',
            onSelect = function()
                AdminMenuClient.OpenEditNPC(npc)
            end
        },
        {
            title = '📍 Teleportar para NPC',
            description = 'Ir até a localização do NPC',
            icon = 'fas fa-map-marker-alt',
            onSelect = function()
                if npc.position then
                    SetEntityCoords(PlayerPedId(), npc.position.x, npc.position.y, npc.position.z, false, false, false, true)
                    Utils.Notify('Teleporte', 'Teleportado para o NPC!', 'success')
                end
            end
        },
        {
            title = '🗑️ Deletar NPC',
            description = 'Remover este NPC permanentemente',
            icon = 'fas fa-trash',
            onSelect = function()
                AdminMenuClient.ConfirmDeleteNPC(npc)
            end
        },
        {
            title = '🔙 Voltar',
            description = 'Voltar à lista de NPCs',
            icon = 'fas fa-arrow-left',
            onSelect = function()
                AdminMenuClient.OpenNPCsMenu()
            end
        }
    }

    lib.registerContext({
        id = 'gang_npc_admin_npc_actions',
        title = string.format('🎯 %s', gangName),
        options = options
    })

    lib.showContext('gang_npc_admin_npc_actions')
end

-- Editar NPC
function AdminMenuClient.OpenEditNPC(npc)
    local input = lib.inputDialog('✏️ Editar NPC', {
        {type = 'number', label = 'Vida', description = 'Vida do NPC (1-200)', default = npc.health or 100, min = 1, max = 200, required = true},
        {type = 'number', label = 'Armadura', description = 'Armadura do NPC (0-100)', default = npc.armor or 0, min = 0, max = 100},
        {type = 'number', label = 'Precisão', description = 'Precisão do NPC (0-100)', default = npc.accuracy or 50, min = 0, max = 100},
        {
            type = 'select', 
            label = 'Estado', 
            description = 'Estado atual do NPC',
            default = npc.state or 'idle',
            options = {
                {value = 'idle', label = 'Idle'},
                {value = 'following', label = 'Seguindo'},
                {value = 'guarding', label = 'Guardando'},
                {value = 'peaceful', label = 'Pacífico'},
                {value = 'combat', label = 'Combate'}
            }
        }
    })

    if input then
        local updateData = {
            health = input[1],
            armor = input[2],
            accuracy = input[3],
            state = input[4]
        }

        TriggerServerEvent('gang_npc:adminUpdateNPC', npc.id, updateData)
        Utils.Notify('Edição', 'Dados do NPC atualizados!', 'success')
    end
end

-- Atualizar dados
function AdminMenuClient.RefreshData()
    TriggerServerEvent('gang_npc:requestAdminData')
end

-- Adicionar após a última função
RegisterNetEvent('gang_npc:receiveAdminData')
AddEventHandler('gang_npc:receiveAdminData', function(data)
    if data then
        adminData = data
        Utils.Notify('Atualização', 'Dados atualizados com sucesso!', 'success')
        AdminMenuClient.OpenMainMenu()
    else
        Utils.Notify('Erro', 'Falha ao atualizar dados', 'error')
    end
end)

-- Confirmar deleção de NPC
function AdminMenuClient.ConfirmDeleteNPC(npc)
    local alert = lib.alertDialog({
        header = '⚠️ Confirmar Deleção',
        content = string.format('Tem certeza que deseja deletar o NPC %s?\n\nEsta ação não pode ser desfeita.', npc.id:sub(1, 8)),
        centered = true,
        cancel = true
    })

    if alert == 'confirm' then
        TriggerServerEvent('gang_npc:adminDeleteNPC', npc.id)
        Utils.Notify('Deleção', 'NPC removido com sucesso!', 'success')
    end
end

-- Menu de spawn
function AdminMenuClient.OpenSpawnMenu()
    -- Criar lista de gangues para seleção
    local gangOptions = {}
    for gangId, gangData in pairs(adminData.gangs) do
        table.insert(gangOptions, {
            value = gangId,
            label = gangData.name
        })
    end

    local input = lib.inputDialog('🚀 Spawnar NPCs', {
        {
            type = 'select',
            label = 'Gangue',
            description = 'Selecione a gangue do NPC',
            options = gangOptions,
            required = true
        },
        {type = 'number', label = 'Quantidade', description = 'Número de NPCs (1-20)', default = 1, min = 1, max = 20, required = true},
        {
            type = 'select',
            label = 'Formação',
            description = 'Como os NPCs serão posicionados',
            default = 'circle',
            options = {
                {value = 'circle', label = 'Círculo'},
                {value = 'line', label = 'Linha'},
                {value = 'square', label = 'Quadrado'},
                {value = 'scattered', label = 'Espalhado'}
            }
        },
        {type = 'number', label = 'Vida', description = 'Vida dos NPCs (1-200)', default = 100, min = 1, max = 200},
        {type = 'number', label = 'Armadura', description = 'Armadura dos NPCs (0-100)', default = 0, min = 0, max = 100},
        {type = 'number', label = 'Precisão', description = 'Precisão dos NPCs (0-100)', default = 50, min = 0, max = 100}
    })

    if input then
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)

        local spawnData = {
            gang = input[1],
            quantity = input[2],
            formation = input[3],
            health = input[4],
            armor = input[5],
            accuracy = input[6],
            position = {x = coords.x + 2.0, y = coords.y, z = coords.z},
            heading = heading
        }

        TriggerServerEvent('gang_npc:adminSpawnNPCs', spawnData)
    end
end

-- Menu de grupos
function AdminMenuClient.OpenGroupsMenu()
    local options = {
        {
            title = string.format('👥 Grupos Disponíveis (%d)', #adminData.groups),
            description = 'Lista de todos os grupos',
            disabled = true
        }
    }

    if #adminData.groups == 0 then
        table.insert(options, {
            title = '❌ Nenhum grupo encontrado',
            description = 'Não há grupos para mostrar',
            disabled = true
        })
    else
        for _, group in ipairs(adminData.groups) do
            local gangConfig = adminData.gangs[group.gang]
            local gangName = gangConfig and gangConfig.name or group.gang
            
            table.insert(options, {
                title = string.format('👥 %s', group.name),
                description = string.format('Gangue: %s | Membros: %d', gangName, #(group.members or {})),
                onSelect = function()
                    AdminMenuClient.OpenGroupActions(group)
                end
            })
        end
    end

    table.insert(options, {
        title = '🔙 Voltar',
        description = 'Voltar ao menu principal',
        icon = 'fas fa-arrow-left',
        onSelect = function()
            AdminMenuClient.OpenMainMenu()
        end
    })

    lib.registerContext({
        id = 'gang_npc_admin_groups',
        title = '👥 Grupos',
        options = options
    })

    lib.showContext('gang_npc_admin_groups')
end

-- Ações de grupo
function AdminMenuClient.OpenGroupActions(group)
    local options = {
        {
            title = string.format('👥 %s', group.name),
            description = string.format('Membros: %d | Auto Defesa: %s', 
                #(group.members or {}), group.auto_defend and 'Sim' or 'Não'),
            disabled = true
        },
        {
            title = '🔙 Voltar',
            description = 'Voltar à lista de grupos',
            icon = 'fas fa-arrow-left',
            onSelect = function()
                AdminMenuClient.OpenGroupsMenu()
            end
        }
    }

    lib.registerContext({
        id = 'gang_npc_admin_group_actions',
        title = string.format('👥 %s', group.name),
        options = options
    })

    lib.showContext('gang_npc_admin_group_actions')
end

-- Ações rápidas
function AdminMenuClient.OpenQuickActions()
    local options = {
        {
            title = '⚡ Ações Administrativas',
            description = 'Comandos rápidos para administradores',
            disabled = true
        },
        {
            title = '🗑️ Limpar Todos os NPCs',
            description = 'Remove todos os NPCs do servidor',
            icon = 'fas fa-trash',
            onSelect = function()
                AdminMenuClient.ConfirmClearAll()
            end
        },
        {
            title = '📊 Mostrar Estatísticas',
            description = 'Exibir estatísticas no chat',
            icon = 'fas fa-chart-bar',
            onSelect = function()
                AdminMenuClient.ShowStats()
            end
        },
        {
            title = '🔄 Recarregar Resource',
            description = 'Reiniciar o Gang NPC Manager',
            icon = 'fas fa-sync',
            onSelect = function()
                ExecuteCommand('restart gang_npc_manager')
            end
        },
        {
            title = '🔙 Voltar',
            description = 'Voltar ao menu principal',
            icon = 'fas fa-arrow-left',
            onSelect = function()
                AdminMenuClient.OpenMainMenu()
            end
        }
    }

    lib.registerContext({
        id = 'gang_npc_admin_quick',
        title = '⚡ Ações Rápidas',
        options = options
    })

    lib.showContext('gang_npc_admin_quick')
end

-- Confirmar limpeza geral
function AdminMenuClient.ConfirmClearAll()
    local alert = lib.alertDialog({
        header = '⚠️ ATENÇÃO - Ação Irreversível',
        content = string.format('Tem certeza que deseja deletar TODOS os %d NPCs?\n\nEsta ação NÃO PODE ser desfeita!', adminData.stats.total_npcs),
        centered = true,
        cancel = true
    })

    if alert == 'confirm' then
        TriggerServerEvent('gang_npc:adminClearAllNPCs')
    end
end

-- Mostrar estatísticas
function AdminMenuClient.ShowStats()
    local message = string.format('📊 Gang NPC Manager - Estatísticas\n\n')
    message = message .. string.format('🤖 NPCs Ativos: %d\n', adminData.stats.total_npcs)
    message = message .. string.format('👥 Grupos: %d\n', adminData.stats.total_groups)
    message = message .. string.format('🎮 Players Online: %d\n\n', adminData.stats.active_players)
    
    if adminData.stats.gang_distribution then
        message = message .. '🏴 Distribuição por Gangue:\n'
        for gangId, count in pairs(adminData.stats.gang_distribution) do
            local gangConfig = adminData.gangs[gangId]
            if gangConfig then
                message = message .. string.format('  • %s: %d NPCs\n', gangConfig.name, count)
            end
        end
    end

    TriggerEvent('chat:addMessage', {
        color = {0, 255, 255},
        multiline = true,
        args = {'Gang NPC Stats', message}
    })
end

-- Exportar funções
AdminMenuClient = AdminMenuClient
