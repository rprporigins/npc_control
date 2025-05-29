--[[
    Gang NPC Manager Fixes Test Script
    
    This script specifically tests the critical fixes implemented in the Gang NPC Manager.
    It validates each of the fixes mentioned in the review request.
    
    Run this script in the FiveM console with: `exec gang_npc_manager_fixes_test.lua`
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

-- Fix 1: Admin Permission System
tests.checkAdminPermissionFix = function()
    local commands = LoadResourceFile(GetCurrentResourceName(), 'server/commands.lua')
    
    if not commands then
        logTest("Admin Permission Fix", false, "Could not load commands.lua")
        return
    end
    
    local adminCommands = {
        {'spawnnpc', 'RegisterCommand%(\'spawnnpc\'.-end, true%)'},
        {'clearnpcs', 'RegisterCommand%(\'clearnpcs\'.-end, true%)'},
        {'npcstats', 'RegisterCommand%(\'npcstats\'.-end, true%)'}
    }
    
    local failedCommands = {}
    
    for _, cmdData in ipairs(adminCommands) do
        local cmdName, pattern = cmdData[1], cmdData[2]
        if not commands:find(pattern) then
            table.insert(failedCommands, cmdName)
        end
    end
    
    if #failedCommands > 0 then
        logTest("Admin Permission Fix", false, "Commands missing 'true' flag: " .. table.concat(failedCommands, ", "))
    else
        logTest("Admin Permission Fix", true)
    end
end

-- Fix 2: Player ID Consistency
tests.checkPlayerIdConsistencyFix = function()
    local serverFiles = {
        'server/commands.lua',
        'server/npc_manager.lua'
    }
    
    local inconsistencies = {}
    local citizenidUsage = 0
    
    for _, filePath in ipairs(serverFiles) do
        local fileContent = LoadResourceFile(GetCurrentResourceName(), filePath)
        
        if not fileContent then
            table.insert(inconsistencies, "Could not load " .. filePath)
            goto continue
        end
        
        -- Count Player.PlayerData.citizenid usage
        local count = select(2, fileContent:gsub("Player%.PlayerData%.citizenid", ""))
        citizenidUsage = citizenidUsage + count
        
        -- Check for fallbacks or alternative ID methods
        local fallbackPatterns = {
            "Player%.PlayerData%.cid",
            "Player%.PlayerData%.identifier",
            "Player%.identifier",
            "GetPlayerIdentifier"
        }
        
        for _, pattern in ipairs(fallbackPatterns) do
            local fallbackCount = select(2, fileContent:gsub(pattern, ""))
            if fallbackCount > 0 then
                table.insert(inconsistencies, filePath .. ": Found " .. fallbackCount .. " instances of " .. pattern)
            end
        end
        
        ::continue::
    end
    
    if #inconsistencies > 0 then
        logTest("Player ID Consistency Fix", false, table.concat(inconsistencies, ", "))
    elseif citizenidUsage == 0 then
        logTest("Player ID Consistency Fix", false, "No usage of Player.PlayerData.citizenid found")
    else
        logTest("Player ID Consistency Fix", true)
    end
end

-- Fix 3: Decorator Registration
tests.checkDecoratorRegistrationFix = function()
    local clientMain = LoadResourceFile(GetCurrentResourceName(), 'client/main.lua')
    
    if not clientMain then
        logTest("Decorator Registration Fix", false, "Could not load client/main.lua")
        return
    end
    
    -- Check if RegisterDecorators is called in initialization
    local initCheck = clientMain:find("CreateThread.-RegisterDecorators%(%)")
    
    if not initCheck then
        logTest("Decorator Registration Fix", false, "RegisterDecorators not called in initialization")
        return
    end
    
    -- Check if decorators are registered before use
    local registerFunc = clientMain:find("function RegisterDecorators%(%).-end")
    
    if not registerFunc then
        logTest("Decorator Registration Fix", false, "RegisterDecorators function not found")
        return
    end
    
    -- Check for proper decorator registration
    local requiredDecorators = {
        "DecorRegister%('gang_npc', 2%)",
        "DecorRegister%('gang_npc_id', 1%)"
    }
    
    local missingRegistrations = {}
    for _, pattern in ipairs(requiredDecorators) do
        if not clientMain:find(pattern) then
            table.insert(missingRegistrations, pattern:gsub("DecorRegister%%%(", ""):gsub("%%", ""):gsub("'", ""))
        end
    end
    
    if #missingRegistrations > 0 then
        logTest("Decorator Registration Fix", false, "Missing decorator registrations: " .. table.concat(missingRegistrations, ", "))
    else
        logTest("Decorator Registration Fix", true)
    end
end

-- Fix 4: Quick Menu Target System
tests.checkTargetSystemFix = function()
    local clientMain = LoadResourceFile(GetCurrentResourceName(), 'client/main.lua')
    
    if not clientMain then
        logTest("Target System Fix", false, "Could not load client/main.lua")
        return
    end
    
    -- Check for single decorator usage in canInteract
    local singleDecorCheck = clientMain:find("return DecorExistOn%(entity, 'gang_npc'%) and DecorGetInt%(entity, 'gang_npc'%) == 1")
    
    if not singleDecorCheck then
        logTest("Target System Fix", false, "Single decorator check not found in canInteract")
        return
    end
    
    -- Check for NPC ID retrieval in OpenNPCQuickMenu
    local idRetrievalCheck = clientMain:find("if DecorExistOn%(entity, 'gang_npc_id'%) then.-npcId = DecorGetString%(entity, 'gang_npc_id'%)")
    
    if not idRetrievalCheck then
        logTest("Target System Fix", false, "NPC ID retrieval not found in OpenNPCQuickMenu")
        return
    }
    
    logTest("Target System Fix", true)
end

-- Fix 5: Raycast System
tests.checkRaycastSystemFix = function()
    local clientMain = LoadResourceFile(GetCurrentResourceName(), 'client/main.lua')
    
    if not clientMain then
        logTest("Raycast System Fix", false, "Could not load client/main.lua")
        return
    end
    
    -- Check for improved GetTargetPlayer function
    local raycastCheck = clientMain:find("function GetTargetPlayer%(%)")
    
    if not raycastCheck then
        logTest("Raycast System Fix", false, "GetTargetPlayer function not found")
        return
    end
    
    -- Check for proper raycast implementation
    local raycastImplementation = clientMain:find("StartShapeTestRay.-GetShapeTestResult")
    
    if not raycastImplementation then
        logTest("Raycast System Fix", false, "Proper raycast implementation not found")
        return
    end
    
    -- Check for player detection
    local playerDetection = clientMain:find("IsPedAPlayer%(entityHit%)")
    
    if not playerDetection then
        logTest("Raycast System Fix", false, "Player detection not found in raycast")
        return
    end
    
    logTest("Raycast System Fix", true)
end

-- Fix 6: State Management
tests.checkStateManagementFix = function()
    local npcManager = LoadResourceFile(GetCurrentResourceName(), 'server/npc_manager.lua')
    
    if not npcManager then
        logTest("State Management Fix", false, "Could not load npc_manager.lua")
        return
    end
    
    -- Check for improved ApplyNPCState function
    local applyStateCheck = npcManager:find("function NPCManager%.ApplyNPCState")
    
    if not applyStateCheck then
        logTest("State Management Fix", false, "ApplyNPCState function not found")
        return
    end
    
    -- Check for entity validation
    local entityValidation = npcManager:find("if not npcInfo or not DoesEntityExist%(npcInfo%.entity%)")
    
    if not entityValidation then
        logTest("State Management Fix", false, "Entity validation not found in ApplyNPCState")
        return
    end
    
    -- Check for state update
    local stateUpdate = npcManager:find("npcInfo%.data%.state = state")
    
    if not stateUpdate then
        logTest("State Management Fix", false, "State update not found in ApplyNPCState")
        return
    end
    
    logTest("State Management Fix", true)
end

-- Fix 7: Database Functions
tests.checkDatabaseFunctionsFix = function()
    local database = LoadResourceFile(GetCurrentResourceName(), 'server/database.lua')
    
    if not database then
        logTest("Database Functions Fix", false, "Could not load database.lua")
        return
    end
    
    -- Check for JSON functions
    local jsonFunctions = {
        "JSONCreate",
        "JSONGet",
        "JSONGetAll",
        "JSONUpdate",
        "JSONDelete"
    }
    
    local missingFunctions = {}
    for _, func in ipairs(jsonFunctions) do
        if not database:find("Database%." .. func) then
            table.insert(missingFunctions, func)
        end
    end
    
    if #missingFunctions > 0 then
        logTest("Database Functions Fix", false, "Missing JSON functions: " .. table.concat(missingFunctions, ", "))
        return
    end
    
    -- Check for JSONUpdate implementation
    local jsonUpdateCheck = database:find("function Database%.JSONUpdate")
    
    if not jsonUpdateCheck then
        logTest("Database Functions Fix", false, "JSONUpdate function not implemented")
        return
    end
    
    -- Check for JSONDelete implementation
    local jsonDeleteCheck = database:find("function Database%.JSONDelete")
    
    if not jsonDeleteCheck then
        logTest("Database Functions Fix", false, "JSONDelete function not implemented")
        return
    end
    
    logTest("Database Functions Fix", true)
end

-- Fix 8: Entity Cleanup
tests.checkEntityCleanupFix = function()
    local npcManager = LoadResourceFile(GetCurrentResourceName(), 'server/npc_manager.lua')
    
    if not npcManager then
        logTest("Entity Cleanup Fix", false, "Could not load npc_manager.lua")
        return
    end
    
    -- Check for validation in DeleteNPC
    local validationCheck = npcManager:find("function NPCManager%.DeleteNPC.-if DoesEntityExist%(npcInfo%.entity%)")
    
    if not validationCheck then
        logTest("Entity Cleanup Fix", false, "Entity validation not found in DeleteNPC")
        return
    end
    
    -- Check for proper entity deletion
    local deletionCheck = npcManager:find("DeleteEntity%(npcInfo%.entity%)")
    
    if not deletionCheck then
        logTest("Entity Cleanup Fix", false, "Entity deletion not found in DeleteNPC")
        return
    end
    
    -- Check for cleanup from active NPCs
    local cleanupCheck = npcManager:find("NPCManager%.ActiveNPCs%[npcId%] = nil")
    
    if not cleanupCheck then
        logTest("Entity Cleanup Fix", false, "Cleanup from ActiveNPCs not found in DeleteNPC")
        return
    end
    
    logTest("Entity Cleanup Fix", true)
end

-- Run all tests
Citizen.CreateThread(function()
    -- Wait for resource to initialize
    Citizen.Wait(2000)
    
    print("^3=== Gang NPC Manager Fixes Test Suite ===^7")
    print("^3Running tests for specific fixes...^7")
    
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
    SaveResourceFile(GetCurrentResourceName(), "fixes_test_results.txt", testOutput, -1)
    print("^3Test results saved to fixes_test_results.txt^7")
end)

print("^3Gang NPC Manager fixes test script loaded. Tests will run automatically.^7")
