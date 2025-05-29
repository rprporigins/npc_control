Config = {}

-- Database Configuration
Config.Database = {
    UseMySQL = true, -- true para MySQL, false para JSON file
    TablePrefix = 'gang_npc_' -- Prefixo das tabelas
}

-- Gang Configurations
Config.Gangs = {
    ['ballas'] = {
        name = 'Ballas',
        color = '#800080',
        models = {'g_m_y_ballaseast_01', 'g_m_y_ballasorig_01', 'g_m_y_ballasouth_01'},
        weapons = {'WEAPON_PISTOL', 'WEAPON_MICROSMG', 'WEAPON_MACHETE', 'WEAPON_PUMPSHOTGUN'},
        defaultHealth = 100,
        defaultArmor = 0
    },
    ['grove_street'] = {
        name = 'Grove Street Families',
        color = '#00FF00',
        models = {'g_m_y_famca_01', 'g_m_y_famdnf_01', 'g_m_y_famfor_01'},
        weapons = {'WEAPON_PISTOL', 'WEAPON_SMG', 'WEAPON_KNIFE', 'WEAPON_ASSAULTRIFLE'},
        defaultHealth = 100,
        defaultArmor = 0
    },
    ['vagos'] = {
        name = 'Los Santos Vagos',
        color = '#FFFF00',
        models = {'g_m_y_mexgang_01', 'g_m_y_mexgoon_01'},
        weapons = {'WEAPON_PISTOL', 'WEAPON_MICROSMG', 'WEAPON_SAWNOFFSHOTGUN'},
        defaultHealth = 100,
        defaultArmor = 0
    },
    ['lost_mc'] = {
        name = 'Lost MC',
        color = '#FF0000',
        models = {'g_m_y_lost_01', 'g_m_y_lost_02', 'g_m_y_lost_03'},
        weapons = {'WEAPON_PISTOL', 'WEAPON_SAWNOFFSHOTGUN', 'WEAPON_KNIFE', 'WEAPON_SMG'},
        defaultHealth = 100,
        defaultArmor = 0
    },
    ['triads'] = {
        name = 'Triads',
        color = '#0000FF',
        models = {'g_m_m_chigoon_01', 'g_m_m_chigoon_02', 'g_m_m_chiboss_01'},
        weapons = {'WEAPON_PISTOL', 'WEAPON_MICROSMG', 'WEAPON_SWITCHBLADE', 'WEAPON_COMBATPISTOL'},
        defaultHealth = 100,
        defaultArmor = 0
    },
    ['armenian_mafia'] = {
        name = 'Armenian Mafia',
        color = '#4B0082',
        models = {'g_m_m_armboss_01', 'g_m_m_armgoon_01', 'g_m_m_armlieut_01'},
        weapons = {'WEAPON_PISTOL', 'WEAPON_SMG', 'WEAPON_COMBATPISTOL', 'WEAPON_ASSAULTRIFLE'},
        defaultHealth = 100,
        defaultArmor = 0
    }
}

-- Keybinds
Config.Keys = {
    NPCMenu = 'F10', -- Menu de controle de NPCs
    AdminMenu = 'F9', -- Menu administrativo
    InteractionKey = 'E'
}

-- NPC Settings
Config.NPC = {
    MaxDistance = 50.0, -- Distância máxima para controlar NPCs
    FollowDistance = 3.0, -- Distância que NPCs seguem o player
    GuardRadius = 10.0, -- Raio de patrulha quando guardando
    CommandCooldown = 1000, -- Cooldown entre comandos (ms)
    MaxControllableNPCs = 20, -- Máximo de NPCs que um player pode controlar
    RespawnOnDeath = true, -- Respawnar NPC ao morrer
    SaveInterval = 30000, -- Salvar dados a cada 30 segundos
    CleanupTime = 300000 -- Limpar NPCs inativos após 5 minutos
}

-- Formations
Config.Formations = {
    ['circle'] = {
        name = 'Círculo',
        spacing = 2.0
    },
    ['line'] = {
        name = 'Linha',
        spacing = 2.0
    },
    ['square'] = {
        name = 'Quadrado',
        spacing = 2.0
    },
    ['scattered'] = {
        name = 'Espalhado',
        radius = 5.0
    }
}

-- Commands
Config.Commands = {
    ['follow'] = {
        label = '🚶 Seguir-me',
        description = 'NPC vai seguir você',
        permission = 'friendly'
    },
    ['stay'] = {
        label = '🛑 Parar',
        description = 'NPC para no local atual',
        permission = 'friendly'
    },
    ['guard'] = {
        label = '🛡️ Guardar Posição',
        description = 'NPC defende posição atual',
        permission = 'leader'
    },
    ['peaceful'] = {
        label = '☮️ Pacífico',
        description = 'NPC não ataca ninguém',
        permission = 'leader'
    },
    ['combat'] = {
        label = '⚔️ Em Combate',
        description = 'NPC me defende e ataca inimigos',
        permission = 'leader'
    },
    ['attack'] = {
        label = '🎯 Atacar Alvo',
        description = 'NPC ataca alvo selecionado',
        permission = 'owner'
    },
    ['patrol'] = {
        label = '👮 Patrulhar',
        description = 'NPC patrulha área',
        permission = 'leader'
    }
}

-- Permissions
Config.Permissions = {
    AdminGroup = 'group.admin',
    ModeratorGroup = 'group.moderator',
    Hierarchy = {
        'owner',     -- Controle total
        'leader',    -- Pode comandar grupos
        'friendly',  -- NPCs protegem
        'neutral',   -- Ignoram
        'enemy'      -- NPCs atacam
    }
}

-- Target Settings (ox_target)
Config.Target = {
    Distance = 3.0,
    Icon = 'fas fa-user-friends',
    Label = 'Controlar NPC'
}

-- Debug
Config.Debug = false

-- Notifications
Config.Notifications = {
    Duration = 5000,
    Position = 'top-right'
}

-- Blips
Config.Blips = {
    NPCs = {
        Enabled = false, -- Não mostrar blips por padrão (muito poluído)
        Sprite = 1,
        Color = 1,
        Scale = 0.6
    },
    Groups = {
        Enabled = true,
        Sprite = 2,
        Color = 2,
        Scale = 0.8
    }
}

-- States
Config.States = {
    ['idle'] = 'Parado',
    ['following'] = 'Seguindo',
    ['attacking'] = 'Atacando',
    ['defending'] = 'Defendendo',
    ['guarding'] = 'Guardando',
    ['peaceful'] = 'Pacífico',
    ['combat'] = 'Combate',
    ['patrol'] = 'Patrulhando',
    ['dead'] = 'Morto'
}

-- Default spawn settings
Config.DefaultSpawn = {
    health = 100,
    armor = 0,
    accuracy = 50,
    heading = 0.0,
    formation = 'circle'
}

-- Economy (opcional - para sistemas de recompensa)
Config.Economy = {
    Enabled = false,
    SpawnCost = 1000, -- Custo para spawnar NPC
    CommandCost = 50, -- Custo por comando
    Currency = 'bank' -- 'cash' ou 'bank'
}
