# Gang NPC Manager v2.0 - FiveM Resource

Sistema completo de gerenciamento de NPCs para servidores FiveM, desenvolvido 100% em Lua nativo.

## 🎮 Características

- **Sistema 100% Lua** - Roda nativamente no FiveM
- **Interface NUI** - Painel administrativo moderno
- **ox_lib Menu** - Menu de controle para players (F10)
- **ox_target** - Interação direta com NPCs
- **MySQL/MariaDB** - Banco de dados robusto
- **6 Gangues** - Ballas, Grove Street, Vagos, Lost MC, Triads, Armenian Mafia
- **Sistema de Permissões** - owners/leaders/friends/enemies
- **Comandos Avançados** - follow, stay, guard, attack, peaceful, combat

## 📋 Dependências

```lua
dependencies {
    'ox_lib',      -- Menu e notificações
    'ox_target',   -- Sistema de targeting
    'oxmysql'      -- Banco de dados MySQL
}
```

## 🔧 Instalação

### 1. Banco de Dados
Execute o arquivo `install.sql` no seu banco MariaDB/MySQL:
```bash
mysql -u username -p database_name < install.sql
```

### 2. Configuração do Banco
Configure a conexão MySQL no seu `server.cfg`:
```cfg
set mysql_connection_string "mysql://username:password@localhost/database_name"
```

### 3. Instalação do Resource
1. Copie a pasta `fivem_npc_system` para `resources/`
2. Adicione no `server.cfg`:
```cfg
ensure gang_npc_manager
```

### 4. Permissões ACE
Configure permissões de admin no `server.cfg`:
```cfg
add_ace group.admin gang_npc allow
add_principal identifier.steam:SEU_STEAM_ID group.admin
```

## ⌨️ Controles

### Para Players:
- **F10** - Menu de controle de NPCs
- **Clique direito** (ox_target) - Interação direta com NPCs

### Para Admins:
- **F9** - Painel administrativo (NUI)
- **/spawnnpc [gang] [quantidade]** - Spawn via comando
- **/clearnpcs** - Limpar todos NPCs
- **/npcstats** - Estatísticas do servidor

## 🎯 Gangues Disponíveis

| Gangue | Cor | Modelos | Armas |
|--------|-----|---------|-------|
| **Ballas** | Roxo | 3 modelos | Pistol, MicroSMG, Machete, Shotgun |
| **Grove Street** | Verde | 3 modelos | Pistol, SMG, Knife, Assault Rifle |
| **Vagos** | Amarelo | 2 modelos | Pistol, MicroSMG, Sawnoff |
| **Lost MC** | Vermelho | 3 modelos | Pistol, Sawnoff, Knife, SMG |
| **Triads** | Azul | 3 modelos | Pistol, MicroSMG, Switchblade |
| **Armenian Mafia** | Índigo | 3 modelos | Pistol, SMG, Combat Pistol |

## ⚔️ Comandos de NPCs

| Comando | Descrição | Permissão |
|---------|-----------|-----------|
| **Follow** | NPC segue o player | friendly |
| **Stay** | NPC para no local | friendly |
| **Guard** | NPC defende posição | leader |
| **Peaceful** | NPC não ataca ninguém | leader |
| **Combat** | NPC em modo combate | leader |
| **Attack** | NPC ataca alvo específico | owner |

## 👥 Sistema de Permissões

### Hierarquia (do maior para menor poder):
1. **Owner** - Controle total, pode usar comando attack
2. **Leader** - Pode comandar grupos, usar guard/combat
3. **Friendly** - NPCs protegem, comandos básicos
4. **Neutral** - Ignoram uns aos outros
5. **Enemy** - NPCs atacam automaticamente

### Configuração:
```lua
-- No spawn ou edição de NPCs
owners = {"1", "5", "12"}     -- IDs dos donos
leaders = {"25", "30"}        -- IDs dos líderes  
friends = {"100", "200"}      -- IDs dos amigos
enemies = {"police", "ems"}   -- Jobs inimigos
```

## 🎨 Interface NUI (F9)

### Abas Disponíveis:
1. **Spawnar NPCs** - Formulário completo de spawn
2. **Gerenciar NPCs** - Lista e edição de NPCs
3. **Grupos** - Sistema de grupos avançados
4. **Estatísticas** - Dashboard com métricas

### Funcionalidades:
- ✅ Spawn com formações (círculo, linha, quadrado, espalhado)
- ✅ Parser vec3 inteligente
- ✅ Configuração de vida, armadura, precisão
- ✅ Sistema de ownership completo
- ✅ Edição de NPCs sem reiniciar
- ✅ Busca e filtros
- ✅ Estatísticas em tempo real

## 📁 Estrutura do Resource

```
fivem_npc_system/
├── fxmanifest.lua          # Manifesto do resource
├── config.lua              # Configurações gerais
├── install.sql             # Script de instalação do banco
├── shared/
│   └── utils.lua           # Funções utilitárias
├── server/
│   ├── database.lua        # Sistema de banco de dados
│   ├── npc_manager.lua     # Gerenciador de NPCs
│   └── commands.lua        # Comandos e eventos
├── client/
│   ├── main.lua           # Cliente principal
│   ├── nui_callbacks.lua  # Callbacks da interface NUI
│   └── target.lua         # Sistema ox_target (opcional)
└── html/
    ├── index.html         # Interface NUI
    ├── style.css          # Estilos da interface
    └── script.js          # JavaScript da interface
```

## ⚙️ Configuração

### config.lua - Principais opções:
```lua
Config.NPC = {
    MaxDistance = 50.0,              -- Distância máxima de controle
    MaxControllableNPCs = 20,        -- Máximo de NPCs por player
    SaveInterval = 30000,            -- Intervalo de salvamento (ms)
    CleanupTime = 300000             -- Limpeza de NPCs inativos (ms)
}

Config.Database = {
    UseMySQL = true,                 -- true para MySQL, false para JSON
    TablePrefix = 'gang_npc_'        -- Prefixo das tabelas
}
```

## 🐛 Solução de Problemas

### NPCs não aparecem:
1. Verifique se o banco está conectado
2. Confirme se as tabelas foram criadas
3. Verifique logs do console (`F8`)

### Menu não abre:
1. Confirme se ox_lib está instalado
2. Verifique se a tecla F10 não conflita
3. Teste com `/mynpcs` no chat

### Permissões:
1. Confirme ACE permissions no server.cfg
2. Teste com outro admin
3. Verifique identifier do Steam

## 📊 Exportações

```lua
-- Obter NPCs do player
local npcs = exports['gang_npc_manager']:GetPlayerNPCs()

-- Obter grupos do player
local groups = exports['gang_npc_manager']:GetPlayerGroups()

-- Enviar comando para NPC
exports['gang_npc_manager']:SendNPCCommand(npcId, 'follow')

-- Spawnar NPC programaticamente
local entity = exports['gang_npc_manager']:SpawnNPC(npcData)
```

## 🔄 Atualizações

Para atualizar o resource:
1. Faça backup do banco de dados
2. Substitua os arquivos
3. Execute `refresh` no console
4. Reinicie o resource: `restart gang_npc_manager`

## 📞 Suporte

- **GitHub Issues**: Para reportar bugs
- **Discord**: Para suporte da comunidade
- **Documentação**: Verifique este README

## 🎉 Créditos

- **Desenvolvido para FiveM**
- **Usa ox_lib e ox_target**
- **Compatible com QBCore**
- **MySQL/MariaDB support**

---

**Gang NPC Manager v2.0** - Sistema profissional para servidores FiveM
