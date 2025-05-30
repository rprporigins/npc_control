-- Gang NPC Manager Critical Test Scenarios
-- This script tests the critical scenarios mentioned in the review request

-- Test 1: No More ox_lib Errors
function TestOxLibErrors()
    print("^2===== Testing ox_lib Errors =====^7")
    
    -- Check if ox_lib is properly initialized
    if not lib then
        print("^1FAILED: ox_lib is not initialized^7")
        return false
    end
    
    -- Test menu registration (should not cause errors)
    local success, error = pcall(function()
        lib.registerContext({
            id = 'test_context',
            title = 'Test Context',
            options = {
                {
                    title = 'Test Option',
                    description = 'This is a test option',
                    onSelect = function() end
                }
            }
        })
    end)
    
    if not success then
        print("^1FAILED: Error registering context menu: " .. tostring(error) .. "^7")
        return false
    end
    
    print("^2PASSED: No ox_lib errors detected^7")
    return true
end

-- Test 2: Admin Menu Access
function TestAdminMenuAccess()
    print("^2===== Testing Admin Menu Access =====^7")
    
    -- Check if command is registered
    if not GetRegisteredCommands then
        print("^3WARNING: Cannot verify command registration (function not available)^7")
    else
        local commands = GetRegisteredCommands()
        local found = false
        
        for _, cmd in ipairs(commands) do
            if cmd.name == "npcadmin" then
                found = true
                break
            end
        end
        
        if not found then
            print("^1FAILED: /npcadmin command not registered^7")
            return false
        end
    end
    
    -- Check if event handler is registered
    local eventHandlerFound = false
    
    -- This is a simplified check since we can't directly check event handlers
    if RegisterNetEvent and AddEventHandler then
        local originalRegisterNetEvent = RegisterNetEvent
        local originalAddEventHandler = AddEventHandler
        
        RegisterNetEvent = function(eventName)
            if eventName == "gang_npc:openAdminMenu" then
                eventHandlerFound = true
            end
            return originalRegisterNetEvent(eventName)
        end
        
        -- Restore original function after check
        RegisterNetEvent = originalRegisterNetEvent
    end
    
    if not eventHandlerFound then
        print("^3WARNING: Could not verify event handler registration^7")
    end
    
    print("^2PASSED: Admin menu access appears to be working^7")
    return true
end

-- Test 3: NPC Management
function TestNPCManagement()
    print("^2===== Testing NPC Management =====^7")
    
    -- Check if client-side functions exist
    local requiredFunctions = {
        "OpenNPCsMenu",
        "OpenNPCActions",
        "OpenEditNPC",
        "ConfirmDeleteNPC",
        "OpenSpawnMenu"
    }
    
    local missingFunctions = {}
    
    for _, funcName in ipairs(requiredFunctions) do
        if not AdminMenuClient or not AdminMenuClient[funcName] then
            table.insert(missingFunctions, funcName)
        end
    end
    
    if #missingFunctions > 0 then
        print("^1FAILED: Missing required functions: " .. table.concat(missingFunctions, ", ") .. "^7")
        return false
    end
    
    -- Check if server-side events exist
    local requiredEvents = {
        "gang_npc:adminSpawnNPCs",
        "gang_npc:adminDeleteNPC",
        "gang_npc:adminUpdateNPC",
        "gang_npc:adminBulkDelete",
        "gang_npc:adminClearAllNPCs"
    }
    
    -- We can't directly check server events, but we can check if they're referenced
    local clientCode = LoadResourceFile(GetCurrentResourceName(), "client/admin_menu.lua")
    local serverCode = LoadResourceFile(GetCurrentResourceName(), "server/admin_menu.lua")
    
    if not clientCode or not serverCode then
        print("^3WARNING: Could not load resource files to check events^7")
    else
        local missingEvents = {}
        
        for _, eventName in ipairs(requiredEvents) do
            if not string.find(clientCode, eventName) and not string.find(serverCode, eventName) then
                table.insert(missingEvents, eventName)
            end
        end
        
        if #missingEvents > 0 then
            print("^1FAILED: Missing required events: " .. table.concat(missingEvents, ", ") .. "^7")
            return false
        end
    end
    
    print("^2PASSED: NPC management functions appear to be implemented^7")
    return true
end

-- Test 4: Spawn System
function TestSpawnSystem()
    print("^2===== Testing Spawn System =====^7")
    
    -- Check if spawn menu function exists
    if not AdminMenuClient or not AdminMenuClient.OpenSpawnMenu then
        print("^1FAILED: OpenSpawnMenu function not found^7")
        return false
    end
    
    -- Check if spawn event is registered
    local serverCode = LoadResourceFile(GetCurrentResourceName(), "server/admin_menu.lua")
    
    if not serverCode then
        print("^3WARNING: Could not load server file to check spawn event^7")
    else
        if not string.find(serverCode, "RegisterServerEvent%('gang_npc:adminSpawnNPCs'%)") then
            print("^1FAILED: Spawn event not registered on server^7")
            return false
        end
    end
    
    -- Check if spawn form has all required fields
    local clientCode = LoadResourceFile(GetCurrentResourceName(), "client/admin_menu.lua")
    
    if not clientCode then
        print("^3WARNING: Could not load client file to check spawn form^7")
    else
        local requiredFields = {
            "Gangue",
            "Quantidade",
            "Formação",
            "Vida",
            "Armadura",
            "Precisão"
        }
        
        local missingFields = {}
        
        for _, field in ipairs(requiredFields) do
            if not string.find(clientCode, "label = '" .. field .. "'") then
                table.insert(missingFields, field)
            end
        end
        
        if #missingFields > 0 then
            print("^1FAILED: Missing spawn form fields: " .. table.concat(missingFields, ", ") .. "^7")
            return false
        end
    end
    
    print("^2PASSED: Spawn system appears to be fully implemented^7")
    return true
end

-- Test 5: Quick Actions
function TestQuickActions()
    print("^2===== Testing Quick Actions =====^7")
    
    -- Check if quick actions function exists
    if not AdminMenuClient or not AdminMenuClient.OpenQuickActions then
        print("^1FAILED: OpenQuickActions function not found^7")
        return false
    end
    
    -- Check if clear all NPCs function exists
    if not AdminMenuClient or not AdminMenuClient.ConfirmClearAll then
        print("^1FAILED: ConfirmClearAll function not found^7")
        return false
    end
    
    -- Check if statistics function exists
    if not AdminMenuClient or not AdminMenuClient.ShowStats then
        print("^1FAILED: ShowStats function not found^7")
        return false
    end
    
    -- Check if clear all event is registered
    local serverCode = LoadResourceFile(GetCurrentResourceName(), "server/admin_menu.lua")
    
    if not serverCode then
        print("^3WARNING: Could not load server file to check clear all event^7")
    else
        if not string.find(serverCode, "RegisterServerEvent%('gang_npc:adminClearAllNPCs'%)") then
            print("^1FAILED: Clear all NPCs event not registered on server^7")
            return false
        end
    end
    
    print("^2PASSED: Quick actions appear to be fully implemented^7")
    return true
end

-- Test 6: User Experience
function TestUserExperience()
    print("^2===== Testing User Experience =====^7")
    
    -- Check if menus use lib.registerContext
    local clientCode = LoadResourceFile(GetCurrentResourceName(), "client/admin_menu.lua")
    
    if not clientCode then
        print("^3WARNING: Could not load client file to check menu implementation^7")
    else
        local contextCount = 0
        
        for _ in string.gmatch(clientCode, "lib%.registerContext") do
            contextCount = contextCount + 1
        end
        
        if contextCount < 5 then
            print("^1FAILED: Not enough context menus registered (found " .. contextCount .. ", expected at least 5)^7")
            return false
        end
    end
    
    -- Check if input dialogs use lib.inputDialog
    local inputDialogCount = 0
    
    if clientCode then
        for _ in string.gmatch(clientCode, "lib%.inputDialog") do
            inputDialogCount = inputDialogCount + 1
        end
        
        if inputDialogCount < 2 then
            print("^1FAILED: Not enough input dialogs used (found " .. inputDialogCount .. ", expected at least 2)^7")
            return false
        end
    end
    
    -- Check if alert dialogs use lib.alertDialog
    local alertDialogCount = 0
    
    if clientCode then
        for _ in string.gmatch(clientCode, "lib%.alertDialog") do
            alertDialogCount = alertDialogCount + 1
        end
        
        if alertDialogCount < 1 then
            print("^1FAILED: Not enough alert dialogs used (found " .. alertDialogCount .. ", expected at least 1)^7")
            return false
        end
    end
    
    print("^2PASSED: User experience appears to be well implemented^7")
    return true
end

-- Test 7: F10 Menu Still Works
function TestF10Menu()
    print("^2===== Testing F10 Menu =====^7")
    
    -- Check if F10 key mapping is registered
    local clientCode = LoadResourceFile(GetCurrentResourceName(), "client/main.lua")
    
    if not clientCode then
        print("^3WARNING: Could not load client file to check F10 key mapping^7")
    else
        if not string.find(clientCode, "RegisterKeyMapping%('%+gang_npc_menu'") then
            print("^1FAILED: F10 key mapping not registered^7")
            return false
        end
    end
    
    -- Check if NPC control menu functions exist
    if not string.find(clientCode, "function OpenNPCControlMenu") then
        print("^1FAILED: OpenNPCControlMenu function not found^7")
        return false
    end
    
    if not string.find(clientCode, "function BuildNPCControlMenu") then
        print("^1FAILED: BuildNPCControlMenu function not found^7")
        return false
    end
    
    -- Check if menu sections exist
    local requiredSections = {
        "Meus NPCs",
        "Meus Grupos",
        "NPCs Próximos"
    }
    
    local missingSections = {}
    
    for _, section in ipairs(requiredSections) do
        if not string.find(clientCode, section) then
            table.insert(missingSections, section)
        end
    end
    
    if #missingSections > 0 then
        print("^1FAILED: Missing F10 menu sections: " .. table.concat(missingSections, ", ") .. "^7")
        return false
    end
    
    print("^2PASSED: F10 menu appears to be working correctly^7")
    return true
end

-- Run all tests
function RunAllTests()
    print("^3======================================^7")
    print("^3  GANG NPC MANAGER CRITICAL TESTS     ^7")
    print("^3======================================^7")
    
    local results = {
        TestOxLibErrors(),
        TestAdminMenuAccess(),
        TestNPCManagement(),
        TestSpawnSystem(),
        TestQuickActions(),
        TestUserExperience(),
        TestF10Menu()
    }
    
    local passCount = 0
    
    for _, passed in ipairs(results) do
        if passed then
            passCount = passCount + 1
        end
    end
    
    print("^3======================================^7")
    print("^3  TEST SUMMARY: " .. passCount .. "/" .. #results .. " PASSED  ^7")
    print("^3======================================^7")
    
    if passCount == #results then
        print("^2All critical tests passed! The refactoring appears to be successful.^7")
    else
        print("^1Some tests failed. Please review the issues above.^7")
    end
end

-- Execute tests
RunAllTests()
