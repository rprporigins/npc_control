
import requests
import sys
import json
from datetime import datetime

class GangNPCManagerTester:
    def __init__(self, base_url="https://24262086-dc15-4d99-be5f-03c439209278.preview.emergentagent.com/api"):
        self.base_url = base_url
        self.tests_run = 0
        self.tests_passed = 0
        self.test_position = {"x": 100, "y": 200, "z": 30}
        self.spawned_npcs = []
        self.spawned_groups = []

    def run_test(self, name, method, endpoint, expected_status, data=None, params=None):
        """Run a single API test"""
        url = f"{self.base_url}/{endpoint}"
        headers = {'Content-Type': 'application/json'}

        self.tests_run += 1
        print(f"\n🔍 Testing {name}...")
        
        try:
            if method == 'GET':
                response = requests.get(url, headers=headers, params=params)
            elif method == 'POST':
                response = requests.post(url, json=data, headers=headers)
            elif method == 'DELETE':
                response = requests.delete(url, headers=headers)

            status_success = response.status_code == expected_status
            
            if status_success:
                self.tests_passed += 1
                print(f"✅ Passed - Status: {response.status_code}")
                try:
                    return True, response.json() if response.text else {}
                except json.JSONDecodeError:
                    return True, {}
            else:
                print(f"❌ Failed - Expected {expected_status}, got {response.status_code}")
                print(f"Response: {response.text}")
                return False, {}

        except Exception as e:
            print(f"❌ Failed - Error: {str(e)}")
            return False, {}

    def test_api_status(self):
        """Test API status endpoint"""
        print("\n=== Testing API Status ===")
        success, response = self.run_test(
            "API Status",
            "GET",
            "",
            200
        )
        if success:
            print(f"API Status: {response.get('status', 'unknown')}")
            print(f"API Version: {response.get('version', 'unknown')}")
        return success

    def test_get_gangs(self):
        """Test getting gang configurations"""
        print("\n=== Testing Get Gangs ===")
        success, response = self.run_test(
            "Get Gangs",
            "GET",
            "gangs",
            200
        )
        if success:
            gang_count = len(response)
            print(f"Retrieved {gang_count} gangs")
            if gang_count == 6:
                print("✅ Correct number of gangs (6)")
                # Check if all expected gangs are present
                expected_gangs = ["ballas", "grove_street", "vagos", "lost_mc", "triads", "armenian_mafia"]
                all_present = all(gang in response for gang in expected_gangs)
                if all_present:
                    print("✅ All expected gangs are present")
                else:
                    print("❌ Some expected gangs are missing")
                    print(f"Expected: {expected_gangs}")
                    print(f"Actual: {list(response.keys())}")
            else:
                print(f"❌ Expected 6 gangs, got {gang_count}")
        return success

    def test_spawn_npc(self, gang, quantity=1, formation="circle"):
        """Test spawning NPCs"""
        print(f"\n=== Testing Spawn NPC ({gang}, qty: {quantity}) ===")
        data = {
            "gang": gang,
            "position": self.test_position,
            "quantity": quantity,
            "formation": formation
        }
        
        success, response = self.run_test(
            f"Spawn {quantity} {gang} NPCs",
            "POST",
            "npc/spawn",
            200,
            data=data
        )
        
        if success:
            print(f"Successfully spawned {len(response)} NPCs")
            self.spawned_npcs.extend([npc["id"] for npc in response])
            if quantity > 1:
                # Store the group ID for later testing
                group_id = response[0].get("group_id")
                if group_id:
                    self.spawned_groups.append(group_id)
                    print(f"Group ID: {group_id}")
        
        return success, response

    def test_get_npcs(self):
        """Test getting all NPCs"""
        print("\n=== Testing Get NPCs ===")
        success, response = self.run_test(
            "Get All NPCs",
            "GET",
            "npcs",
            200
        )
        if success:
            print(f"Retrieved {len(response)} NPCs")
        return success, response

    def test_npc_command(self, npc_id, command="stay"):
        """Test sending command to an NPC"""
        print(f"\n=== Testing NPC Command ({command}) ===")
        data = {
            "npc_id": npc_id,
            "command": command
        }
        
        success, response = self.run_test(
            f"Send {command} command to NPC",
            "POST",
            "npc/command",
            200,
            data=data
        )
        
        if success:
            print(f"Command response: {response.get('message', '')}")
        
        return success

    def test_get_stats(self):
        """Test getting server stats"""
        print("\n=== Testing Get Stats ===")
        success, response = self.run_test(
            "Get Server Stats",
            "GET",
            "stats",
            200
        )
        if success:
            print(f"Total NPCs: {response.get('total_npcs', 0)}")
            print(f"Active Groups: {response.get('active_groups', 0)}")
            print(f"Gang Distribution: {response.get('gang_distribution', {})}")
        return success

    def test_clear_npcs(self):
        """Test clearing all NPCs"""
        print("\n=== Testing Clear NPCs ===")
        success, response = self.run_test(
            "Clear All NPCs",
            "DELETE",
            "npcs/clear",
            200
        )
        if success:
            print(f"Clear response: {response.get('message', '')}")
            self.spawned_npcs = []
            self.spawned_groups = []
        return success

def main():
    # Setup
    tester = GangNPCManagerTester()
    
    # Run tests
    api_status_ok = tester.test_api_status()
    if not api_status_ok:
        print("❌ API status check failed, stopping tests")
        return 1

    gangs_ok = tester.test_get_gangs()
    if not gangs_ok:
        print("❌ Get gangs test failed, stopping tests")
        return 1

    # Test spawning NPCs for different gangs
    gangs_to_test = ["ballas", "grove_street", "vagos", "lost_mc", "triads", "armenian_mafia"]
    formations_to_test = ["circle", "line", "square"]
    
    # First, clear any existing NPCs
    tester.test_clear_npcs()
    
    # Test spawning a single NPC for each gang
    for gang in gangs_to_test:
        spawn_success, _ = tester.test_spawn_npc(gang, quantity=1)
        if not spawn_success:
            print(f"❌ Failed to spawn {gang} NPC")
    
    # Test getting NPCs
    npcs_success, npcs = tester.test_get_npcs()
    if not npcs_success:
        print("❌ Get NPCs test failed")
    
    # Test NPC command if we have NPCs
    if npcs and len(npcs) > 0:
        command_success = tester.test_npc_command(npcs[0]["id"], "follow")
        if not command_success:
            print("❌ NPC command test failed")
    
    # Test stats
    stats_success = tester.test_get_stats()
    if not stats_success:
        print("❌ Get stats test failed")
    
    # Test spawning multiple NPCs with different formations
    for formation in formations_to_test:
        spawn_success, _ = tester.test_spawn_npc("ballas", quantity=5, formation=formation)
        if not spawn_success:
            print(f"❌ Failed to spawn NPCs with {formation} formation")
    
    # Test stats again after spawning more NPCs
    tester.test_get_stats()
    
    # Clean up - clear all NPCs
    tester.test_clear_npcs()
    
    # Final stats check
    tester.test_get_stats()
    
    # Print results
    print(f"\n📊 Tests passed: {tester.tests_passed}/{tester.tests_run}")
    return 0 if tester.tests_passed == tester.tests_run else 1

if __name__ == "__main__":
    sys.exit(main())
