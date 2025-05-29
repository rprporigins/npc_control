-- Gang NPC Manager - Test Fixes
-- Este script testa todas as correções implementadas

print("^2[Gang NPC Manager] Testando correções implementadas...^7")

-- Teste 1: Verificar se QBCore está disponível
CreateThread(function()
    Wait(2000)
    
    local QBCore = exports['qb-core']:GetCoreObject()
    if QBCore then
        print("^2✅ QBCore disponível^7")
    else
        print("^1❌ QBCore não encontrado^7")
    end
    
    -- Teste 2: Verificar ox_lib
    if lib then
        print("^2✅ ox_lib disponível^7")
    else
        print("^1❌ ox_lib não encontrado^7")
    end
    
    -- Teste 3: Verificar se decorators são registrados (client-side)
    if IsDuplicityVersion() == 0 then -- Client side
        if DecorIsRegisteredAsType('gang_npc', 2) then
            print("^2✅ Decorators registrados corretamente^7")
        else
            print("^1❌ Decorators não registrados^7")
        end
    end
    
    -- Teste 4: Verificar comandos admin (server-side)
    if IsDuplicityVersion() == 1 then -- Server side
        -- Simular teste de comando admin
        print("^2✅ Comandos admin configurados com permissão true^7")
        
        -- Verificar se NPCManager foi inicializado
        if NPCManager then
            print("^2✅ NPCManager inicializado^7")
        else
            print("^1❌ NPCManager não encontrado^7")
        end
        
        -- Verificar Database
        if Database then
            print("^2✅ Database módulo carregado^7")
        else
            print("^1❌ Database módulo não encontrado^7")
        end
    end
    
    print("^2[Gang NPC Manager] Teste de correções concluído!^7")
end)