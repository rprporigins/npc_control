Config = {}

-- API Configuration
Config.API = {
    BaseURL = "http://localhost:8001/api", -- URL da API
    Timeout = 5000 -- Timeout em ms
}

-- Keybinds
Config.Keys = {
    NPCMenu = 'F10', -- Tecla para abrir menu de controle de NPCs
    RadialMenu = 'F9', -- Tecla para menu radial (admin)
    InteractionKey = 'E' -- Tecla de interação
}

-- Menu Configuration
Config.Menu = {
    Title = "🎮 Gang NPC Manager",
    Subtitle = "Sistema de Controle de NPCs",
    Position = "top-left"
}

-- NPC Control Settings
Config.NPC = {
    MaxDistance = 50.0, -- Distância máxima para controlar NPCs
    FollowDistance = 3.0, -- Distância que NPCs seguem o player
    GuardRadius = 10.0, -- Raio de patrulha quando guardando
    CommandCooldown = 1000, -- Cooldown entre comandos (ms)
    MaxControllableNPCs = 10 -- Máximo de NPCs que um player pode controlar
}

-- Target Settings (ox_target)
Config.Target = {
    Distance = 3.0, -- Distância máxima para interação
    Icon = "fas fa-user-friends",
    Label = "Controlar NPC"
}

-- Gang Colors (for UI)
Config.GangColors = {
    ballas = "#800080",
    grove_street = "#00FF00",
    vagos = "#FFFF00",
    lost_mc = "#FF0000",
    triads = "#0000FF",
    armenian_mafia = "#4B0082"
}

-- Command List
Config.Commands = {
    {id = "follow", label = "🚶 Seguir-me", description = "NPC vai seguir você"},
    {id = "stay", label = "🛑 Parar", description = "NPC para no local atual"},
    {id = "guard", label = "🛡️ Guardar Posição", description = "NPC defende posição atual"},
    {id = "peaceful", label = "☮️ Pacífico", description = "NPC não ataca ninguém"},
    {id = "combat", label = "⚔️ Em Combate", description = "NPC me defende e ataca inimigos"},
    {id = "attack", label = "🎯 Atacar Alvo", description = "NPC ataca alvo selecionado"},
    {id = "patrol", label = "👮 Patrulhar", description = "NPC patrulha área"}
}

-- Permissions
Config.Permissions = {
    AdminGroup = "group.admin", -- Grupo de admin (ACE Permissions)
    ModeratorGroup = "group.moderator", -- Grupo de moderador
    AllowedJobs = {"police", "sheriff", "government"} -- Jobs que podem usar comandos básicos
}

-- Debug
Config.Debug = false -- Ativar logs de debug

-- Notifications
Config.Notifications = {
    Duration = 5000, -- Duração das notificações (ms)
    Position = "top-right",
    Icons = {
        success = "✅",
        error = "❌",
        info = "ℹ️",
        warning = "⚠️"
    }
}

-- Blips (for admin)
Config.Blips = {
    NPCs = {
        Enabled = true,
        Sprite = 1,
        Color = 1,
        Scale = 0.8,
        Name = "NPC Gang"
    },
    Groups = {
        Enabled = true,
        Sprite = 2,
        Color = 2,
        Scale = 1.0,
        Name = "Grupo NPC"
    }
}
