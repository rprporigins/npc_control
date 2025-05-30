-- Gang NPC Manager Fixes Test
-- Comprehensive test script for the refactored Gang NPC Manager

local TestSuite = {}
local testResults = {}

-- Helper function to log test results
function TestSuite.LogResult(testName, passed, details)
    table.insert(testResults, {
        name = testName,
        passed = passed,
        details = details or ""
    })
    
    if passed then
        print("^2[PASS]^7 " .. testName)
        if details then
            print("       " .. details)
        end
    else
        print("^1[FAIL]^7 " .. testName)
        if details then
            print("       " .. details)
        end
    end
end

-- Test 1: Web Interface Removal
function TestSuite.TestWebInterfaceRemoval()
    local testName = "Web Interface Removal"
    local details = {}
    local allPassed = true
    
    -- Check fxmanifest.lua
    local fxmanifest = LoadResourceFile(GetCurrentResourceName(), "fxmanifest.lua")
    
    if not fxmanifest then
        table.insert(details, "Could not load fxmanifest.lua")
        TestSuite.LogResult(testName, false, table.concat(details, "\n"))
        return
    end
    
    -- Check if ui_page is commented out
    if not string.find(fxmanifest, "-- ui_page") then
        table.insert(details, "ui_page is not commented out in fxmanifest.lua")
        allPassed = false
    end
    
    -- Check if files section is commented out
    if not string.find(fxmanifest, "-- files") then
        table.insert(details, "files section is not commented out in fxmanifest.lua")
        allPassed = false
    end
    
    -- Check main.lua for SetNuiFocus calls
    local mainLua = LoadResourceFile(GetCurrentResourceName(), "client/main.lua")
    
    if not mainLua then
        table.insert(details, "Could not load client/main.lua")
        TestSuite.LogResult(testName, false, table.concat(details, "\n"))
        return
    end
    
    if string.find(mainLua, "SetNuiFocus") then
        table.insert(details, "SetNuiFocus calls still present in client/main.lua")
        allPassed = false
    end
    
    if allPassed then
        table.insert(details, "Web interface successfully removed")
    end
    
    TestSuite.LogResult(testName, allPassed, table.concat(details, "\n"))
end

-- Test 2: ox_lib Menu Implementation
function TestSuite.TestOxLibMenuImplementation()
    local testName = "ox_lib Menu Implementation"
    local details = {}
    local allPassed = true
    
    -- Check client/admin_menu.lua
    local adminMenuLua = LoadResourceFile(GetCurrentResourceName(), "client/admin_menu.lua")
    
    if not adminMenuLua then
        table.insert(details, "Could not load client/admin_menu.lua")
        TestSuite.LogResult(testName, false, table.concat(details, "\n"))
        return
    end
    
    -- Check for lib.registerContext usage
    if not string.find(adminMenuLua, "lib%.registerContext") then
        table.insert(details, "lib.registerContext not found in client/admin_menu.lua")
        allPassed = false
    end
    
    -- Check for lib.showContext usage
    if not string.find(adminMenuLua, "lib%.showContext") then
        table.insert(details, "lib.showContext not found in client/admin_menu.lua")
        allPassed = false
    end
    
    -- Check for lib.inputDialog usage
    if not string.find(adminMenuLua, "lib%.inputDialog") then
        table.insert(details, "lib.inputDialog not found in client/admin_menu.lua")
        allPassed = false
    end
    
    -- Check for lib.alertDialog usage
    if not string.find(adminMenuLua, "lib%.alertDialog") then
        table.insert(details, "lib.alertDialog not found in client/admin_menu.lua")
        allPassed = false
    end
    
    -- Count number of menus
    local menuCount = 0
    for _ in string.gmatch(adminMenuLua, "lib%.registerContext") do
        menuCount = menuCount + 1
    end
    
    table.insert(details, "Found " .. menuCount .. " menu registrations")
    
    if menuCount < 5 then
        table.insert(details, "Expected at least 5 menus, but found " .. menuCount)
        allPassed = false
    end
    
    if allPassed then
        table.insert(details, "ox_lib menu system successfully implemented")
    end
    
    TestSuite.LogResult(testName, allPassed, table.concat(details, "\n"))
end

-- Test 3: Admin Command
function TestSuite.TestAdminCommand()
    local testName = "Admin Command Implementation"
    local details = {}
    local allPassed = true
    
    -- Check server/admin_menu.lua
    local serverAdminMenuLua = LoadResourceFile(GetCurrentResourceName(), "server/admin_menu.lua")
    
    if not serverAdminMenuLua then
        table.insert(details, "Could not load server/admin_menu.lua")
        TestSuite.LogResult(testName, false, table.concat(details, "\n"))
        return
    end
    
    -- Check for command registration
    if not string.find(serverAdminMenuLua, "RegisterCommand%('npcadmin'") then
        table.insert(details, "npcadmin command not registered in server/admin_menu.lua")
        allPassed = false
    end
    
    -- Check for permission validation
    if not string.find(serverAdminMenuLua, "IsPlayerAceAllowed%(source, Config%.Permissions%.AdminGroup%)") then
        table.insert(details, "Admin permission check not found in server/admin_menu.lua")
        allPassed = false
    end
    
    -- Check for menu opening event
    if not string.find(serverAdminMenuLua, "TriggerClientEvent%('gang_npc:openAdminMenu'") then
        table.insert(details, "Menu opening event not found in server/admin_menu.lua")
        allPassed = false
    end
    
    if allPassed then
        table.insert(details, "Admin command successfully implemented")
    end
    
    TestSuite.LogResult(testName, allPassed, table.concat(details, "\n"))
end

-- Test 4: Menu Features
function TestSuite.TestMenuFeatures()
    local testName = "Menu Features"
    local details = {}
    local allPassed = true
    
    -- Check client/admin_menu.lua
    local adminMenuLua = LoadResourceFile(GetCurrentResourceName(), "client/admin_menu.lua")
    
    if not adminMenuLua then
        table.insert(details, "Could not load client/admin_menu.lua")
        TestSuite.LogResult(testName, false, table.concat(details, "\n"))
        return
    end
    
    -- Check for main menu sections
    local requiredSections = {
        "Dashboard",
        "Gerenciar NPCs",
        "Grupos",
        "Spawnar NPCs",
        "Ações Rápidas"
    }
    
    for _, section in ipairs(requiredSections) do
        if not string.find(adminMenuLua, section) then
            table.insert(details, "Required section '" .. section .. "' not found in admin menu")
            allPassed = false
        end
    end
    
    -- Check for dashboard features
    if not string.find(adminMenuLua, "OpenDashboard") then
        table.insert(details, "Dashboard function not found")
        allPassed = false
    end
    
    if not string.find(adminMenuLua, "Estatísticas Gerais") then
        table.insert(details, "Statistics section not found in dashboard")
        allPassed = false
    end
    
    if not string.find(adminMenuLua, "Distribuição por Gangue") then
        table.insert(details, "Gang distribution not found in dashboard")
        allPassed = false
    end
    
    -- Check for NPC management
    if not string.find(adminMenuLua, "OpenNPCsMenu") then
        table.insert(details, "NPC management function not found")
        allPassed = false
    end
    
    if not string.find(adminMenuLua, "OpenNPCActions") then
        table.insert(details, "NPC actions function not found")
        allPassed = false
    end
    
    -- Check for spawn system
    if not string.find(adminMenuLua, "OpenSpawnMenu") then
        table.insert(details, "Spawn menu function not found")
        allPassed = false
    end
    
    -- Check for quick actions
    if not string.find(adminMenuLua, "OpenQuickActions") then
        table.insert(details, "Quick actions function not found")
        allPassed = false
    end
    
    if not string.find(adminMenuLua, "ConfirmClearAll") then
        table.insert(details, "Clear all confirmation function not found")
        allPassed = false
    end
    
    if allPassed then
        table.insert(details, "All required menu features successfully implemented")
    end
    
    TestSuite.LogResult(testName, allPassed, table.concat(details, "\n"))
end

-- Test 5: F10 Menu Preservation
function TestSuite.TestF10MenuPreservation()
    local testName = "F10 Menu Preservation"
    local details = {}
    local allPassed = true
    
    -- Check client/main.lua
    local mainLua = LoadResourceFile(GetCurrentResourceName(), "client/main.lua")
    
    if not mainLua then
        table.insert(details, "Could not load client/main.lua")
        TestSuite.LogResult(testName, false, table.concat(details, "\n"))
        return
    end
    
    -- Check for F10 key mapping
    if not string.find(mainLua, "RegisterKeyMapping%('%+gang_npc_menu'") then
        table.insert(details, "F10 key mapping not found in client/main.lua")
        allPassed = false
    end
    
    -- Check for NPC control menu functions
    if not string.find(mainLua, "function OpenNPCControlMenu") then
        table.insert(details, "OpenNPCControlMenu function not found in client/main.lua")
        allPassed = false
    end
    
    if not string.find(mainLua, "function BuildNPCControlMenu") then
        table.insert(details, "BuildNPCControlMenu function not found in client/main.lua")
        allPassed = false
    end
    
    -- Check for menu sections
    local requiredSections = {
        "Meus NPCs",
        "Meus Grupos",
        "NPCs Próximos"
    }
    
    for _, section in ipairs(requiredSections) do
        if not string.find(mainLua, section) then
            table.insert(details, "Required section '" .. section .. "' not found in F10 menu")
            allPassed = false
        end
    end
    
    if allPassed then
        table.insert(details, "F10 menu successfully preserved")
    end
    
    TestSuite.LogResult(testName, allPassed, table.concat(details, "\n"))
end

-- Test 6: No ox_lib Errors
function TestSuite.TestNoOxLibErrors()
    local testName = "No ox_lib Errors"
    local details = {}
    local allPassed = true
    
    -- Check for proper initialization
    if not lib then
        table.insert(details, "ox_lib is not initialized")
        TestSuite.LogResult(testName, false, table.concat(details, "\n"))
        return
    end
    
    -- Test menu registration
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
        table.insert(details, "Error registering context menu: " .. tostring(error))
        allPassed = false
    end
    
    -- Check for proper imports in fxmanifest.lua
    local fxmanifest = LoadResourceFile(GetCurrentResourceName(), "fxmanifest.lua")
    
    if not fxmanifest then
        table.insert(details, "Could not load fxmanifest.lua")
        TestSuite.LogResult(testName, false, table.concat(details, "\n"))
        return
    end
    
    if not string.find(fxmanifest, "@ox_lib/init%.lua") then
        table.insert(details, "ox_lib initialization not found in fxmanifest.lua")
        allPassed = false
    end
    
    if allPassed then
        table.insert(details, "No ox_lib errors detected")
    end
    
    TestSuite.LogResult(testName, allPassed, table.concat(details, "\n"))
end

-- Test 7: Performance Expectations
function TestSuite.TestPerformanceExpectations()
    local testName = "Performance Expectations"
    local details = {}
    local allPassed = true
    
    -- Check for absence of web interface
    local fxmanifest = LoadResourceFile(GetCurrentResourceName(), "fxmanifest.lua")
    
    if not fxmanifest then
        table.insert(details, "Could not load fxmanifest.lua")
        TestSuite.LogResult(testName, false, table.concat(details, "\n"))
        return
    end
    
    if string.find(fxmanifest, "ui_page") and not string.find(fxmanifest, "-- ui_page") then
        table.insert(details, "Web interface still active, which could impact performance")
        allPassed = false
    end
    
    -- Check for native menu usage
    local adminMenuLua = LoadResourceFile(GetCurrentResourceName(), "client/admin_menu.lua")
    
    if not adminMenuLua then
        table.insert(details, "Could not load client/admin_menu.lua")
        TestSuite.LogResult(testName, false, table.concat(details, "\n"))
        return
    end
    
    if not string.find(adminMenuLua, "lib%.registerContext") or not string.find(adminMenuLua, "lib%.showContext") then
        table.insert(details, "Not using native menus, which could impact performance")
        allPassed = false
    end
    
    -- Check for NPC list limitation (performance optimization)
    if not string.find(adminMenuLua, "if i <= 20 then") then
        table.insert(details, "NPC list may not be limited, which could impact performance with many NPCs")
        allPassed = false
    end
    
    if allPassed then
        table.insert(details, "Performance optimizations successfully implemented")
    end
    
    TestSuite.LogResult(testName, allPassed, table.concat(details, "\n"))
end

-- Run all tests
function TestSuite.RunAllTests()
    print("^3======================================^7")
    print("^3  GANG NPC MANAGER REFACTORING TESTS  ^7")
    print("^3======================================^7")
    
    TestSuite.TestWebInterfaceRemoval()
    TestSuite.TestOxLibMenuImplementation()
    TestSuite.TestAdminCommand()
    TestSuite.TestMenuFeatures()
    TestSuite.TestF10MenuPreservation()
    TestSuite.TestNoOxLibErrors()
    TestSuite.TestPerformanceExpectations()
    
    -- Print summary
    local passCount = 0
    for _, result in ipairs(testResults) do
        if result.passed then
            passCount = passCount + 1
        end
    end
    
    print("^3======================================^7")
    print("^3  TEST SUMMARY: " .. passCount .. "/" .. #testResults .. " PASSED  ^7")
    print("^3======================================^7")
    
    if passCount == #testResults then
        print("^2All tests passed! The refactoring appears to be successful.^7")
    else
        print("^1Some tests failed. Please review the issues above.^7")
    end
    
    return testResults
end

-- Execute tests
return TestSuite.RunAllTests()
