#!/usr/bin/env python3
"""
Gang NPC Manager Test Suite

This script tests the Gang NPC Manager resource for FiveM/QBCore.
It validates the critical fixes and functionality of the resource.

Note: This is a simulation of the tests since we can't directly interact with FiveM from Python.
The actual tests would need to be run in the FiveM environment using the Lua test scripts.
"""

import os
import re
import sys
import json
from dataclasses import dataclass
from typing import List, Dict, Optional, Tuple, Any
from enum import Enum
import unittest


class TestResult(Enum):
    PASS = "PASS"
    FAIL = "FAIL"
    SKIP = "SKIP"


@dataclass
class TestCase:
    name: str
    description: str
    result: TestResult = TestResult.SKIP
    details: Optional[str] = None


class GangNPCManagerTester:
    """Test suite for Gang NPC Manager resource"""

    def __init__(self, resource_path: str = "/app"):
        self.resource_path = resource_path
        self.test_cases: List[TestCase] = []
        self.setup_test_cases()

    def setup_test_cases(self):
        """Define all test cases"""
        self.test_cases = [
            TestCase(
                name="admin_permission_system",
                description="Verify admin commands use 'true' for admin permission"
            ),
            TestCase(
                name="player_id_consistency",
                description="Verify Player.PlayerData.citizenid is used consistently"
            ),
            TestCase(
                name="decorator_registration",
                description="Verify decorators are registered before use"
            ),
            TestCase(
                name="quick_menu_target_system",
                description="Verify NPC ID detection using single decorator"
            ),
            TestCase(
                name="raycast_system",
                description="Verify enhanced GetTargetPlayer() function"
            ),
            TestCase(
                name="state_management",
                description="Verify improved NPC state application"
            ),
            TestCase(
                name="database_functions",
                description="Verify JSONUpdate/JSONDelete functions"
            ),
            TestCase(
                name="entity_cleanup",
                description="Verify proper validation in DeleteNPC function"
            ),
            TestCase(
                name="dependency_check",
                description="Verify fxmanifest.lua has proper dependencies"
            ),
            TestCase(
                name="nui_admin_panel",
                description="Verify HTML admin panel functionality"
            )
        ]

    def run_tests(self) -> None:
        """Run all test cases"""
        print("=== Gang NPC Manager Test Suite ===")
        print(f"Resource path: {self.resource_path}")
        print("Running tests...\n")

        for test_case in self.test_cases:
            method_name = f"test_{test_case.name}"
            if hasattr(self, method_name):
                try:
                    test_method = getattr(self, method_name)
                    result, details = test_method()
                    test_case.result = TestResult.PASS if result else TestResult.FAIL
                    test_case.details = details
                except Exception as e:
                    test_case.result = TestResult.FAIL
                    test_case.details = f"Exception: {str(e)}"
            
            self._print_test_result(test_case)

        self._print_summary()

    def _print_test_result(self, test_case: TestCase) -> None:
        """Print the result of a test case"""
        result_symbol = "✅" if test_case.result == TestResult.PASS else "❌"
        print(f"{result_symbol} {test_case.name}: {test_case.description}")
        if test_case.details:
            print(f"   Details: {test_case.details}")

    def _print_summary(self) -> None:
        """Print a summary of all test results"""
        total = len(self.test_cases)
        passed = sum(1 for tc in self.test_cases if tc.result == TestResult.PASS)
        failed = sum(1 for tc in self.test_cases if tc.result == TestResult.FAIL)
        skipped = sum(1 for tc in self.test_cases if tc.result == TestResult.SKIP)
        
        print("\n=== Test Summary ===")
        print(f"Total tests: {total}")
        print(f"Passed: {passed}")
        print(f"Failed: {failed}")
        print(f"Skipped: {skipped}")
        
        if failed == 0:
            print("\n✅ All tests passed!")
        else:
            print("\n❌ Some tests failed.")

    def _read_file(self, relative_path: str) -> Optional[str]:
        """Read a file from the resource directory"""
        file_path = os.path.join(self.resource_path, relative_path)
        try:
            with open(file_path, 'r') as f:
                return f.read()
        except Exception as e:
            print(f"Error reading file {file_path}: {e}")
            return None

    def test_admin_permission_system(self) -> Tuple[bool, str]:
        """Test if admin commands use 'true' for admin permission"""
        commands_lua = self._read_file("server/commands.lua")
        if not commands_lua:
            return False, "Could not read commands.lua"
        
        admin_commands = [
            r"RegisterCommand\('spawnnpc'.*end,\s*true\)",
            r"RegisterCommand\('clearnpcs'.*end,\s*true\)",
            r"RegisterCommand\('npcstats'.*end,\s*true\)"
        ]
        
        missing_commands = []
        for pattern in admin_commands:
            if not re.search(pattern, commands_lua, re.DOTALL):
                cmd_name = pattern.split("'")[1]
                missing_commands.append(cmd_name)
        
        if missing_commands:
            return False, f"Commands missing 'true' flag: {', '.join(missing_commands)}"
        
        return True, "All admin commands have proper permission flags"

    def test_player_id_consistency(self) -> Tuple[bool, str]:
        """Test if Player.PlayerData.citizenid is used consistently"""
        server_files = ["server/commands.lua", "server/npc_manager.lua"]
        
        inconsistencies = []
        citizenid_usage = 0
        
        for file_path in server_files:
            content = self._read_file(file_path)
            if not content:
                inconsistencies.append(f"Could not read {file_path}")
                continue
            
            # Count citizenid usage
            citizenid_count = len(re.findall(r"Player\.PlayerData\.citizenid", content))
            citizenid_usage += citizenid_count
            
            # Check for fallbacks
            fallback_patterns = [
                r"Player\.PlayerData\.cid",
                r"Player\.PlayerData\.identifier",
                r"Player\.identifier",
                r"GetPlayerIdentifier"
            ]
            
            for pattern in fallback_patterns:
                matches = re.findall(pattern, content)
                if matches:
                    inconsistencies.append(f"{file_path}: Found {len(matches)} instances of {pattern}")
        
        if inconsistencies:
            return False, "; ".join(inconsistencies)
        
        if citizenid_usage == 0:
            return False, "No usage of Player.PlayerData.citizenid found"
        
        return True, f"Found {citizenid_usage} consistent uses of Player.PlayerData.citizenid"

    def test_decorator_registration(self) -> Tuple[bool, str]:
        """Test if decorators are registered before use"""
        client_main = self._read_file("client/main.lua")
        if not client_main:
            return False, "Could not read client/main.lua"
        
        # Check if RegisterDecorators is called in initialization
        init_check = re.search(r"CreateThread.*RegisterDecorators\(\)", client_main, re.DOTALL)
        if not init_check:
            return False, "RegisterDecorators not called in initialization"
        
        # Check if decorators are registered
        register_func = re.search(r"function RegisterDecorators\(\).*end", client_main, re.DOTALL)
        if not register_func:
            return False, "RegisterDecorators function not found"
        
        # Check for required decorators
        required_decorators = [
            r"DecorRegister\('gang_npc', 2\)",
            r"DecorRegister\('gang_npc_id', 1\)"
        ]
        
        missing = []
        for pattern in required_decorators:
            if not re.search(pattern, client_main):
                missing.append(pattern.replace(r"DecorRegister\('", "").replace(r"', \d\)", ""))
        
        if missing:
            return False, f"Missing decorator registrations: {', '.join(missing)}"
        
        return True, "Decorators properly registered before use"

    def test_quick_menu_target_system(self) -> Tuple[bool, str]:
        """Test if target system uses single decorator for NPC identification"""
        client_main = self._read_file("client/main.lua")
        if not client_main:
            return False, "Could not read client/main.lua"
        
        # Check for single decorator check in canInteract
        single_decor_check = re.search(
            r"return DecorExistOn\(entity, 'gang_npc'\) and DecorGetInt\(entity, 'gang_npc'\) == 1",
            client_main
        )
        
        if not single_decor_check:
            return False, "Single decorator check not found in canInteract"
        
        # Check for NPC ID retrieval in OpenNPCQuickMenu
        id_retrieval = re.search(
            r"if DecorExistOn\(entity, 'gang_npc_id'\) then.*npcId = DecorGetString\(entity, 'gang_npc_id'\)",
            client_main,
            re.DOTALL
        )
        
        if not id_retrieval:
            return False, "NPC ID retrieval not found in OpenNPCQuickMenu"
        
        return True, "Target system correctly uses single decorator for identification"

    def test_raycast_system(self) -> Tuple[bool, str]:
        """Test if GetTargetPlayer function is enhanced"""
        client_main = self._read_file("client/main.lua")
        if not client_main:
            return False, "Could not read client/main.lua"
        
        # Check for GetTargetPlayer function
        get_target_func = re.search(r"function GetTargetPlayer\(\)", client_main)
        if not get_target_func:
            return False, "GetTargetPlayer function not found"
        
        # Check for proper raycast implementation
        raycast_impl = re.search(r"StartShapeTestRay.*GetShapeTestResult", client_main, re.DOTALL)
        if not raycast_impl:
            return False, "Proper raycast implementation not found"
        
        # Check for player detection
        player_detection = re.search(r"IsPedAPlayer\(entityHit\)", client_main)
        if not player_detection:
            return False, "Player detection not found in raycast"
        
        return True, "GetTargetPlayer function properly enhanced with raycast system"

    def test_state_management(self) -> Tuple[bool, str]:
        """Test if NPC state application is improved"""
        npc_manager = self._read_file("server/npc_manager.lua")
        if not npc_manager:
            return False, "Could not read server/npc_manager.lua"
        
        # Check for ApplyNPCState function
        apply_state_func = re.search(r"function NPCManager\.ApplyNPCState", npc_manager)
        if not apply_state_func:
            return False, "ApplyNPCState function not found"
        
        # Check for entity validation
        entity_validation = re.search(
            r"if not npcInfo or not DoesEntityExist\(npcInfo\.entity\)",
            npc_manager
        )
        
        if not entity_validation:
            return False, "Entity validation not found in ApplyNPCState"
        
        # Check for state update
        state_update = re.search(r"npcInfo\.data\.state = state", npc_manager)
        if not state_update:
            return False, "State update not found in ApplyNPCState"
        
        return True, "State management properly improved with validation and updates"

    def test_database_functions(self) -> Tuple[bool, str]:
        """Test if JSONUpdate/JSONDelete functions are implemented"""
        database = self._read_file("server/database.lua")
        if not database:
            return False, "Could not read server/database.lua"
        
        # Check for JSONUpdate function
        json_update = re.search(r"function Database\.JSONUpdate", database)
        if not json_update:
            return False, "JSONUpdate function not implemented"
        
        # Check for JSONDelete function
        json_delete = re.search(r"function Database\.JSONDelete", database)
        if not json_delete:
            return False, "JSONDelete function not implemented"
        
        # Check for proper implementation
        update_impl = re.search(r"function Database\.JSONUpdate.*for i, item in ipairs\(tableData\).*if item\.id == id then", database, re.DOTALL)
        delete_impl = re.search(r"function Database\.JSONDelete.*for i, item in ipairs\(tableData\).*if item\.id == id then.*table\.remove\(tableData, i\)", database, re.DOTALL)
        
        if not update_impl:
            return False, "JSONUpdate function not properly implemented"
        
        if not delete_impl:
            return False, "JSONDelete function not properly implemented"
        
        return True, "JSONUpdate and JSONDelete functions properly implemented"

    def test_entity_cleanup(self) -> Tuple[bool, str]:
        """Test if DeleteNPC function has proper validation"""
        npc_manager = self._read_file("server/npc_manager.lua")
        if not npc_manager:
            return False, "Could not read server/npc_manager.lua"
        
        # Check for validation in DeleteNPC
        validation_check = re.search(
            r"function NPCManager\.DeleteNPC.*if DoesEntityExist\(npcInfo\.entity\)",
            npc_manager,
            re.DOTALL
        )
        
        if not validation_check:
            return False, "Entity validation not found in DeleteNPC"
        
        # Check for proper entity deletion
        deletion_check = re.search(r"DeleteEntity\(npcInfo\.entity\)", npc_manager)
        if not deletion_check:
            return False, "Entity deletion not found in DeleteNPC"
        
        # Check for cleanup from active NPCs
        cleanup_check = re.search(r"NPCManager\.ActiveNPCs\[npcId\] = nil", npc_manager)
        if not cleanup_check:
            return False, "Cleanup from ActiveNPCs not found in DeleteNPC"
        
        return True, "DeleteNPC function has proper validation and cleanup"

    def test_dependency_check(self) -> Tuple[bool, str]:
        """Test if fxmanifest.lua has proper dependencies"""
        manifest = self._read_file("fxmanifest.lua")
        if not manifest:
            return False, "Could not read fxmanifest.lua"
        
        required_deps = ['ox_lib', 'ox_target', 'oxmysql', 'qb-core']
        missing_deps = []
        
        for dep in required_deps:
            if not re.search(f"['\"]({dep})['\"]", manifest):
                missing_deps.append(dep)
        
        if missing_deps:
            return False, f"Missing dependencies: {', '.join(missing_deps)}"
        
        return True, "All required dependencies present in fxmanifest.lua"

    def test_nui_admin_panel(self) -> Tuple[bool, str]:
        """Test if HTML admin panel is functional"""
        html_files = ["html/index.html", "html/script.js", "html/style.css"]
        missing_files = []
        
        for file_path in html_files:
            if not self._read_file(file_path):
                missing_files.append(file_path)
        
        if missing_files:
            return False, f"Missing NUI files: {', '.join(missing_files)}"
        
        # Check for NUI callbacks
        nui_callbacks = self._read_file("client/nui_callbacks.lua")
        if not nui_callbacks:
            return False, "Could not read client/nui_callbacks.lua"
        
        required_callbacks = [
            "spawnFromPanel",
            "deleteFromPanel",
            "updateFromPanel",
            "clearAllNPCs",
            "refreshData",
            "closePanel"
        ]
        
        missing_callbacks = []
        for callback in required_callbacks:
            if not re.search(f"RegisterNUICallback\\(['\"]({callback})['\"]", nui_callbacks):
                missing_callbacks.append(callback)
        
        if missing_callbacks:
            return False, f"Missing NUI callbacks: {', '.join(missing_callbacks)}"
        
        return True, "NUI admin panel is properly implemented with all required callbacks"


def main():
    """Main function to run the tests"""
    tester = GangNPCManagerTester()
    tester.run_tests()
    return 0


if __name__ == "__main__":
    sys.exit(main())
