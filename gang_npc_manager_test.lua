--[[
    Gang NPC Manager Test Script
    
    This script tests the critical functionality of the Gang NPC Manager resource.
    It validates the recent fixes and ensures all components work correctly.
    
    Run this script in the FiveM console with: `exec gang_npc_manager_test.lua`
]]

local tests = {}
local testResults = {passed = 0, failed = 0, total = 0}
local testOutput = ""

-- Helper function to log test results
local function logTest(name, result, details)
    testResults.total = testResults.total + 1
    
    if result then
        testResults.passed = testResults.passed + 1
        testOutput = testOutput .. "[✓] PASS: " .. name .. "\n"
    else
        testResults.failed = testResults.failed + 1
        testOutput = testOutput .. "[✗] FAIL: " .. name .. " - " .. (details or "No details") .. "\n"
    end
    
    -- Print immediately for real-time feedback
    if result then
        print("^2[✓] PASS: " .. name .. "^7")
    else
        print("^1[✗] FAIL: " .. name .. " - " .. (details or "No details") .. "^7")
    end
end

-- Test 1: Dependency Check
tests.checkDependencies = function()
    local requiredDependencies = {'ox_lib', 'ox_target', 'oxmysql', 'qb-core'}
    local missingDeps = {}
    
    -- Check manifest dependencies
    local manifestPath = GetResourcePath(GetCurrentResourceName()) .. '/fxmanifest.lua'
    local manifest = LoadResourceFile(GetCurrentResourceName(), 'fxmanifest.lua')
    
    if not manifest then
        logTest("Dependency Check", false, "Could not load fxmanifest.lua")
        return
    end
    
    for _, dep in ipairs(requiredDependencies) do
        if not manifest:find("'" .. dep .. "'") and not manifest:find('"' .. dep .. '"') then
            table.insert(missingDeps, dep)
        end
    end
    
    if #missingDeps > 0 then
        logTest("Dependency Check", false, "Missing dependencies: " .. table.concat(missingDeps, ", "))
    else
        logTest("Dependency Check", true)
    end
end

-- Test 2: Admin Permission System
tests.checkAdminPermissions = function()
    -- Check if admin commands use 'true' for admin permission
    local commandsPath = GetResourcePath(GetCurrentResourceName()) .. '/server/commands.lua'
    local commands = LoadResourceFile(GetCurrentResourceName(), 'server/commands.lua')
    
    if not commands then
        logTest("Admin Permission System", false, "Could not load commands.lua")
        return
    end
    
    local adminCommands = {
        "RegisterCommand%('spawnnpc'",
        "RegisterCommand%('clearnpcs'",
        "RegisterCommand%('npcstats'"
    }
    
    local allCorrect = true
    local incorrectCommands = {}
    
    for _, cmdPattern in ipairs(adminCommands) do
        -- Find the command registration
        local cmdStart, cmdEnd = commands:find(cmdPattern .. ".-end, true%)")
        
        if not cmdStart then
            allCorrect = false
            table.insert(incorrectCommands, cmdPattern:gsub("RegisterCommand%%%('" , ""):gsub("'", ""))
        end
    end
    
    if allCorrect then
        logTest("Admin Permission System", true)
    else
        logTest("Admin Permission System", false, "Commands missing 'true' flag: " .. table.concat(incorrectCommands, ", "))
    end
end

-- Test 3: Player ID Consistency
tests.checkPlayerIdConsistency = function()
    local serverFiles = {
        'server/commands.lua',
        'server/npc_manager.lua'
    }
    
    local inconsistencies = {}
    
    for _, filePath in ipairs(serverFiles) do
        local fileContent = LoadResourceFile(GetCurrentResourceName(), filePath)
        
        if not fileContent then
            table.insert(inconsistencies, "Could not load " .. filePath)
            goto continue
        end
        
        -- Check for Player.PlayerData.citizenid usage
        local citizenidCount = select(2, fileContent:gsub("Player%.PlayerData%.citizenid", ""))
        
        -- Check for fallbacks or alternative ID methods
        local fallbackPatterns = {
            "Player%.PlayerData%.cid",
            "Player%.PlayerData%.identifier",
            "Player%.identifier",
            "GetPlayerIdentifier"
        }
        
        for _, pattern in ipairs(fallbackPatterns) do
            local count = select(2, fileContent:gsub(pattern, ""))
            if count > 0 then
                table.insert(inconsistencies, filePath .. ": Found " .. count .. " instances of " .. pattern)
            end
        end
        
        ::continue::
    end
    
    if #inconsistencies > 0 then
        logTest("Player ID Consistency", false, table.concat(inconsistencies, ", "))
    else
        logTest("Player ID Consistency", true)
    end
end

-- Test 4: Decorator Registration
tests.checkDecoratorRegistration = function()
    local clientMain = LoadResourceFile(GetCurrentResourceName(), 'client/main.lua')
    
    if not clientMain then
        logTest("Decorator Registration", false, "Could not load client/main.lua")
        return
    end
    
    -- Check if decorators are registered before use
    local registerFirst = clientMain:find("RegisterDecorators%(%)")
    local decorUse = clientMain:find("DecorExistOn")
    
    if registerFirst and decorUse and registerFirst < decorUse then
        logTest("Decorator Registration", true)
    else
        logTest("Decorator Registration", false, "Decorators not properly registered before use")
    end
    
    -- Check if all required decorators are registered
    local requiredDecorators = {
        "gang_npc",
        "gang_npc_id"
    }
    
    local missingDecorators = {}
    for _, decorator in ipairs(requiredDecorators) do
        if not clientMain:find("DecorRegister%(['\"]" .. decorator .. "['\"]") then
            table.insert(missingDecorators, decorator)
        end
    end
    
    if #missingDecorators > 0 then
        logTest("Decorator Registration - Required Decorators", false, "Missing decorators: " .. table.concat(missingDecorators, ", "))
    else
        logTest("Decorator Registration - Required Decorators", true)
    end
end

-- Test 5: Database Functions
tests.checkDatabaseFunctions = function()
    local database = LoadResourceFile(GetCurrentResourceName(), 'server/database.lua')
    
    if not database then
        logTest("Database Functions", false, "Could not load database.lua")
        return
    end
    
    -- Check for JSON fallback functions
    local requiredJSONFunctions = {
        "JSONCreate",
        "JSONGet",
        "JSONGetAll",
        "JSONUpdate",
        "JSONDelete"
    }
    
    local missingFunctions = {}
    for _, func in ipairs(requiredJSONFunctions) do
        if not database:find("Database%." .. func) then
            table.insert(missingFunctions, func)
        end
    end
    
    if #missingFunctions > 0 then
        logTest("Database JSON Functions", false, "Missing functions: " .. table.concat(missingFunctions, ", "))
    else
        logTest("Database JSON Functions", true)
    end
    
    -- Check MySQL functions
    local requiredMySQLFunctions = {
        "InitMySQL",
        "CreateNPC",
        "GetNPC",
        "GetAllNPCs",
        "UpdateNPC",
        "DeleteNPC"
    }
    
    missingFunctions = {}
    for _, func in ipairs(requiredMySQLFunctions) do
        if not database:find("Database%." .. func) then
            table.insert(missingFunctions, func)
        end
    end
    
    if #missingFunctions > 0 then
        logTest("Database MySQL Functions", false, "Missing functions: " .. table.concat(missingFunctions, ", "))
    else
        logTest("Database MySQL Functions", true)
    end
end

-- Test 6: NPC Spawning
tests.checkNPCSpawning = function()
    local npcManager = LoadResourceFile(GetCurrentResourceName(), 'server/npc_manager.lua')
    
    if not npcManager then
        logTest("NPC Spawning", false, "Could not load npc_manager.lua")
        return
    end
    
    -- Check for decorator setting in SpawnNPCEntity
    local decoratorCheck = npcManager:find("DecorSetInt%(ped, 'gang_npc'")
    local idDecoratorCheck = npcManager:find("DecorSetString%(ped, 'gang_npc_id'")
    
    if decoratorCheck and idDecoratorCheck then
        logTest("NPC Spawning - Decorators", true)
    else
        logTest("NPC Spawning - Decorators", false, "Missing decorator setting in SpawnNPCEntity")
    end
    
    -- Check for proper decorator registration check
    local registrationCheck = npcManager:find("DecorIsRegisteredAsType")
    
    if registrationCheck then
        logTest("NPC Spawning - Decorator Registration Check", true)
    else
        logTest("NPC Spawning - Decorator Registration Check", false, "Missing decorator registration check")
    end
}

-- Test 7: Command System
tests.checkCommandSystem = function()
    local npcManager = LoadResourceFile(GetCurrentResourceName(), 'server/npc_manager.lua')
    
    if not npcManager then
        logTest("Command System", false, "Could not load npc_manager.lua")
        return
    end
    
    -- Check for command to state mapping
    local stateMapCheck = npcManager:find("local stateMap = {")
    
    if stateMapCheck then
        logTest("Command System - State Mapping", true)
    else
        logTest("Command System - State Mapping", false, "Missing state mapping in SendCommand")
    end
    
    -- Check for permission validation
    local permissionCheck = npcManager:find("local hasPermission = Utils%.HasPermission")
    
    if permissionCheck then
        logTest("Command System - Permission Check", true)
    else
        logTest("Command System - Permission Check", false, "Missing permission validation in SendCommand")
    end
}

-- Test 8: State Management
tests.checkStateManagement = function()
    local npcManager = LoadResourceFile(GetCurrentResourceName(), 'server/npc_manager.lua')
    
    if not npcManager then
        logTest("State Management", false, "Could not load npc_manager.lua")
        return
    }
    
    -- Check for state application function
    local applyStateCheck = npcManager:find("function NPCManager%.ApplyNPCState")
    
    if applyStateCheck then
        logTest("State Management - Apply State Function", true)
    else
        logTest("State Management - Apply State Function", false, "Missing ApplyNPCState function")
    end
    
    -- Check for entity validation in ApplyNPCState
    local entityValidationCheck = npcManager:find("if not npcInfo or not DoesEntityExist%(npcInfo%.entity%)")
    
    if entityValidationCheck then
        logTest("State Management - Entity Validation", true)
    else
        logTest("State Management - Entity Validation", false, "Missing entity validation in ApplyNPCState")
    end
}

-- Test 9: Target System
tests.checkTargetSystem = function()
    local clientMain = LoadResourceFile(GetCurrentResourceName(), 'client/main.lua')
    
    if not clientMain then
        logTest("Target System", false, "Could not load client/main.lua")
        return
    end
    
    -- Check for ox_target integration
    local targetCheck = clientMain:find("exports%.ox_target:addGlobalPed")
    
    if targetCheck then
        logTest("Target System - ox_target Integration", true)
    else
        logTest("Target System - ox_target Integration", false, "Missing ox_target integration")
    end
    
    -- Check for decorator usage in canInteract
    local decoratorCheck = clientMain:find("DecorExistOn%(entity, 'gang_npc'%) and DecorGetInt%(entity, 'gang_npc'%) == 1")
    
    if decoratorCheck then
        logTest("Target System - Decorator Check", true)
    else
        logTest("Target System - Decorator Check", false, "Missing decorator check in canInteract")
    end
}

-- Test 10: Entity Cleanup
tests.checkEntityCleanup = function()
    local npcManager = LoadResourceFile(GetCurrentResourceName(), 'server/npc_manager.lua')
    
    if not npcManager then
        logTest("Entity Cleanup", false, "Could not load npc_manager.lua")
        return
    end
    
    -- Check for entity validation in DeleteNPC
    local validationCheck = npcManager:find("if DoesEntityExist%(npcInfo%.entity%)")
    
    if validationCheck then
        logTest("Entity Cleanup - Validation", true)
    else
        logTest("Entity Cleanup - Validation", false, "Missing entity validation in DeleteNPC")
    end
    
    -- Check for cleanup routine
    local cleanupCheck = npcManager:find("function NPCManager%.StartCleanup")
    
    if cleanupCheck then
        logTest("Entity Cleanup - Routine", true)
    else
        logTest("Entity Cleanup - Routine", false, "Missing cleanup routine")
    end
}

-- Run all tests
Citizen.CreateThread(function()
    -- Wait for resource to initialize
    Citizen.Wait(2000)
    
    print("^3=== Gang NPC Manager Test Suite ===^7")
    print("^3Running tests...^7")
    
    for name, testFunc in pairs(tests) do
        testFunc()
        Citizen.Wait(100) -- Small delay between tests
    end
    
    -- Print summary
    print("\n^3=== Test Summary ===^7")
    print("^3Total tests: ^7" .. testResults.total)
    print("^2Passed: ^7" .. testResults.passed)
    print("^1Failed: ^7" .. testResults.failed)
    
    -- Save results to file
    SaveResourceFile(GetCurrentResourceName(), "test_results.txt", testOutput, -1)
    print("^3Test results saved to test_results.txt^7")
end)

print("^3Gang NPC Manager test script loaded. Tests will run automatically.^7")
