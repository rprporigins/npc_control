
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
            elif method == 'PUT':
                response = requests.put(url, json=data, headers=headers)
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

    def test_spawn_npc(self, gang, quantity=1, formation="circle", health=100, armor=0, accuracy=50, 
                      friendly_player_ids="", friendly_jobs="", vec3_input=""):
        """Test spawning NPCs with advanced options"""
        print(f"\n=== Testing Spawn NPC ({gang}, qty: {quantity}) ===")
        data = {
            "gang": gang,
            "position": self.test_position,
            "quantity": quantity,
            "formation": formation,
            "health": health,
            "armor": armor,
            "accuracy": accuracy,
            "friendly_player_ids": friendly_player_ids,
            "friendly_jobs": friendly_jobs,
            "vec3_input": vec3_input
        }
        
        success, response = self.run_test(
            f"Spawn {quantity} {gang} NPCs with advanced options",
            "POST",
            "npc/spawn",
            200,
            data=data
        )
        
        if success:
            print(f"Successfully spawned {len(response)} NPCs")
            # Verify the advanced options were applied
            if len(response) > 0:
                npc = response[0]
                print(f"Health: {npc.get('health')} (Expected: {health})")
                print(f"Armor: {npc.get('armor')} (Expected: {armor})")
                print(f"Accuracy: {npc.get('accuracy')} (Expected: {accuracy})")
                
                # Check friendly IDs and jobs
                if friendly_player_ids:
                    expected_ids = [id.strip() for id in friendly_player_ids.split(",") if id.strip()]
                    actual_ids = npc.get('friendly_player_ids', [])
                    print(f"Friendly Player IDs: {actual_ids} (Expected: {expected_ids})")
                    if set(expected_ids) == set(actual_ids):
                        print("✅ Friendly player IDs match")
                    else:
                        print("❌ Friendly player IDs don't match")
                
                if friendly_jobs:
                    expected_jobs = [job.strip() for job in friendly_jobs.split(",") if job.strip()]
                    actual_jobs = npc.get('friendly_jobs', [])
                    print(f"Friendly Jobs: {actual_jobs} (Expected: {expected_jobs})")
                    if set(expected_jobs) == set(actual_jobs):
                        print("✅ Friendly jobs match")
                    else:
                        print("❌ Friendly jobs don't match")
                
                # Check if vec3 was parsed correctly
                if vec3_input:
                    print(f"Position: {npc.get('position')} (From vec3: {vec3_input})")
            
            self.spawned_npcs.extend([npc["id"] for npc in response])
            if quantity > 1:
                # Store the group ID for later testing
                group_id = response[0].get("group_id")
                if group_id:
                    self.spawned_groups.append(group_id)
                    print(f"Group ID: {group_id}")
        
        return success, response

    def test_spawn_npc_with_invalid_values(self):
        """Test spawning NPCs with invalid values to check validation"""
        print("\n=== Testing Spawn NPC Validation ===")
        
        # Test with invalid health
        data_invalid_health = {
            "gang": "ballas",
            "position": self.test_position,
            "health": 300  # Above max (200)
        }
        
        success, response = self.run_test(
            "Spawn NPC with invalid health (300)",
            "POST",
            "npc/spawn",
            400,  # Expecting a 400 Bad Request
            data=data_invalid_health
        )
        
        # Test with invalid armor
        data_invalid_armor = {
            "gang": "ballas",
            "position": self.test_position,
            "armor": 150  # Above max (100)
        }
        
        success, response = self.run_test(
            "Spawn NPC with invalid armor (150)",
            "POST",
            "npc/spawn",
            400,  # Expecting a 400 Bad Request
            data=data_invalid_armor
        )
        
        # Test with invalid accuracy
        data_invalid_accuracy = {
            "gang": "ballas",
            "position": self.test_position,
            "accuracy": 150  # Above max (100)
        }
        
        success, response = self.run_test(
            "Spawn NPC with invalid accuracy (150)",
            "POST",
            "npc/spawn",
            400,  # Expecting a 400 Bad Request
            data=data_invalid_accuracy
        )
        
        return True  # Return True as we expect these tests to fail with 400

    def test_vec3_parser(self):
        """Test the vec3 parser with different formats"""
        print("\n=== Testing vec3 Parser ===")
        
        # Test standard vec3 format
        vec3_standard = "vec3(-100.5, 200.3, 30.1)"
        success, response = self.test_spawn_npc("ballas", vec3_input=vec3_standard)
        if success and len(response) > 0:
            position = response[0].get('position', {})
            expected = {"x": -100.5, "y": 200.3, "z": 30.1}
            if (position.get('x') == expected['x'] and 
                position.get('y') == expected['y'] and 
                position.get('z') == expected['z']):
                print(f"✅ vec3 standard format parsed correctly: {position}")
            else:
                print(f"❌ vec3 standard format parsed incorrectly: {position}, expected: {expected}")
        
        # Test array format
        vec3_array = "[-277.7, -997.36, 24.94]"
        success, response = self.test_spawn_npc("ballas", vec3_input=vec3_array)
        if success and len(response) > 0:
            position = response[0].get('position', {})
            expected = {"x": -277.7, "y": -997.36, "z": 24.94}
            if (abs(position.get('x') - expected['x']) < 0.01 and 
                abs(position.get('y') - expected['y']) < 0.01 and 
                abs(position.get('z') - expected['z']) < 0.01):
                print(f"✅ vec3 array format parsed correctly: {position}")
            else:
                print(f"❌ vec3 array format parsed incorrectly: {position}, expected: {expected}")
        
        # Test simple comma format
        vec3_simple = "-277.7, -997.36, 24.94"
        success, response = self.test_spawn_npc("ballas", vec3_input=vec3_simple)
        if success and len(response) > 0:
            position = response[0].get('position', {})
            expected = {"x": -277.7, "y": -997.36, "z": 24.94}
            if (abs(position.get('x') - expected['x']) < 0.01 and 
                abs(position.get('y') - expected['y']) < 0.01 and 
                abs(position.get('z') - expected['z']) < 0.01):
                print(f"✅ vec3 simple format parsed correctly: {position}")
            else:
                print(f"❌ vec3 simple format parsed incorrectly: {position}, expected: {expected}")
        
        return True

    def test_update_npc(self, npc_id, health=None, armor=None, accuracy=None, 
                       friendly_player_ids=None, friendly_jobs=None, weapon=None):
        """Test updating an NPC"""
        print(f"\n=== Testing Update NPC ({npc_id}) ===")
        
        # Prepare update data
        update_data = {}
        if health is not None:
            update_data["health"] = health
        if armor is not None:
            update_data["armor"] = armor
        if accuracy is not None:
            update_data["accuracy"] = accuracy
        if friendly_player_ids is not None:
            update_data["friendly_player_ids"] = friendly_player_ids
        if friendly_jobs is not None:
            update_data["friendly_jobs"] = friendly_jobs
        if weapon is not None:
            update_data["weapon"] = weapon
        
        success, response = self.run_test(
            f"Update NPC {npc_id}",
            "PUT",
            f"npcs/{npc_id}",
            200,
            data=update_data
        )
        
        if success:
            print("NPC updated successfully")
            # Verify the updates were applied
            if health is not None:
                print(f"Health: {response.get('health')} (Expected: {health})")
            if armor is not None:
                print(f"Armor: {response.get('armor')} (Expected: {armor})")
            if accuracy is not None:
                print(f"Accuracy: {response.get('accuracy')} (Expected: {accuracy})")
            if weapon is not None:
                print(f"Weapon: {response.get('weapon')} (Expected: {weapon})")
            
            # Check friendly IDs and jobs
            if friendly_player_ids is not None:
                expected_ids = [id.strip() for id in friendly_player_ids.split(",") if id.strip()]
                actual_ids = response.get('friendly_player_ids', [])
                print(f"Friendly Player IDs: {actual_ids} (Expected: {expected_ids})")
                if set(expected_ids) == set(actual_ids):
                    print("✅ Updated friendly player IDs match")
                else:
                    print("❌ Updated friendly player IDs don't match")
            
            if friendly_jobs is not None:
                expected_jobs = [job.strip() for job in friendly_jobs.split(",") if job.strip()]
                actual_jobs = response.get('friendly_jobs', [])
                print(f"Friendly Jobs: {actual_jobs} (Expected: {expected_jobs})")
                if set(expected_jobs) == set(actual_jobs):
                    print("✅ Updated friendly jobs match")
                else:
                    print("❌ Updated friendly jobs don't match")
        
        return success, response

    def test_update_npc_with_invalid_values(self, npc_id):
        """Test updating an NPC with invalid values"""
        print(f"\n=== Testing Update NPC Validation ({npc_id}) ===")
        
        # Test with invalid health
        update_data_invalid_health = {
            "health": 300  # Above max (200)
        }
        
        success, response = self.run_test(
            "Update NPC with invalid health (300)",
            "PUT",
            f"npcs/{npc_id}",
            400,  # Expecting a 400 Bad Request
            data=update_data_invalid_health
        )
        
        # Test with invalid armor
        update_data_invalid_armor = {
            "armor": 150  # Above max (100)
        }
        
        success, response = self.run_test(
            "Update NPC with invalid armor (150)",
            "PUT",
            f"npcs/{npc_id}",
            400,  # Expecting a 400 Bad Request
            data=update_data_invalid_armor
        )
        
        # Test with invalid accuracy
        update_data_invalid_accuracy = {
            "accuracy": 150  # Above max (100)
        }
        
        success, response = self.run_test(
            "Update NPC with invalid accuracy (150)",
            "PUT",
            f"npcs/{npc_id}",
            400,  # Expecting a 400 Bad Request
            data=update_data_invalid_accuracy
        )
        
        return True  # Return True as we expect these tests to fail with 400

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

    # First, clear any existing NPCs
    tester.test_clear_npcs()
    
    print("\n=== TESTING NEW FEATURES ===")
    
    # Test 1: Test vec3 parser with different formats
    print("\n🔍 FEATURE TEST: vec3 Parser")
    tester.test_vec3_parser()
    
    # Test 2: Test spawning NPCs with advanced options
    print("\n🔍 FEATURE TEST: Advanced NPC Configuration")
    success, response = tester.test_spawn_npc(
        gang="ballas",
        quantity=1,
        health=150,
        armor=75,
        accuracy=85,
        friendly_player_ids="1, 5, 12, 25, 30",
        friendly_jobs="police, ems, mechanic, government"
    )
    
    # Test 3: Test validation of invalid values
    print("\n🔍 FEATURE TEST: Validation of Invalid Values")
    tester.test_spawn_npc_with_invalid_values()
    
    # Test 4: Test NPC editing
    print("\n🔍 FEATURE TEST: NPC Editing")
    if success and len(response) > 0:
        npc_id = response[0]["id"]
        
        # Test updating an NPC
        tester.test_update_npc(
            npc_id=npc_id,
            health=120,
            armor=50,
            accuracy=70,
            friendly_player_ids="2, 7, 15",
            friendly_jobs="police, mechanic"
        )
        
        # Test validation of invalid update values
        tester.test_update_npc_with_invalid_values(npc_id)
    
    # Test getting NPCs to verify changes
    npcs_success, npcs = tester.test_get_npcs()
    
    # Test stats
    stats_success = tester.test_get_stats()
    
    # Clean up - clear all NPCs
    tester.test_clear_npcs()
    
    # Print results
    print(f"\n📊 Tests passed: {tester.tests_passed}/{tester.tests_run}")
    return 0 if tester.tests_passed == tester.tests_run else 1

if __name__ == "__main__":
    sys.exit(main())
