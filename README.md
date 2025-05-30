# Gang NPC Manager v2.0.1

Sistema completo de gerenciamento de NPCs para gangues no FiveM.

## 🚀 Características

- Interface web moderna (F9)
- Menu ox_lib alternativo (/npcadmin)
- Sistema de permissões hierárquico
- Suporte MySQL e JSON
- Formações de spawn personalizadas
- Comandos de controle avançados

## 📋 Instalação

1. Extraia os arquivos na pasta resources
2. Execute o install.sql no seu banco (se usar MySQL)
3. Adicione ao server.cfg:
   ```
   ensure gang_npc_manager
   add_ace group.admin gang_npc.admin allow
   ```

## 🎮 Comandos

### Admin
- F9 ou /npcadmin - Painel administrativo
- /spawnnpc [gang] [qtd] [modelo] - Spawn rápido
- /clearnpcs - Limpar todos NPCs
- /npcstats - Estatísticas

### Players
- F10 - Menu de controle de NPCs
- /mynpcs - Listar seus NPCs

## 🔧 Dependências

### Obrigatórias
- qb-core
- ox_lib

### Opcionais
- ox_target (interação com NPCs)
- oxmysql (salvamento em MySQL)

## 📝 Configuração

Edite o `config.lua` para personalizar:
- Gangues disponíveis
- Modelos de NPCs
- Armas permitidas
- Formações de spawn
- Permissões

## 🐛 Suporte

Para suporte, verifique os logs do console ou execute:
```
exec gang_npc_manager/check_dependencies.lua
```
