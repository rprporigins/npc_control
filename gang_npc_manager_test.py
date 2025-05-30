
# Gang NPC Manager Test Script
# Tests the refactored system that uses ox_lib native menus instead of web interface

import unittest
import os
import sys
import time
from unittest.mock import MagicMock, patch

class GangNPCManagerTest(unittest.TestCase):
    """Test suite for the Gang NPC Manager refactoring"""
    
    def setUp(self):
        """Setup test environment"""
        print("\n=== Setting up Gang NPC Manager test ===")
        # Mock environment would be set up here in a real test
        
    def test_fxmanifest_changes(self):
        """Test that fxmanifest.lua has been properly updated"""
        print("\nTesting fxmanifest.lua changes...")
        
        with open('/app/fxmanifest.lua', 'r') as f:
            content = f.read()
            
        # Check that web UI is commented out
        self.assertIn('-- ui_page', content, "Web UI should be commented out in fxmanifest.lua")
        self.assertIn('-- files', content, "Files section should be commented out in fxmanifest.lua")
        
        # Check that admin_menu.lua files are included
        self.assertIn("'server/admin_menu.lua'", content, "server/admin_menu.lua should be included in fxmanifest.lua")
        self.assertIn("'client/admin_menu.lua'", content, "client/admin_menu.lua should be included in fxmanifest.lua")
        
        print("✅ fxmanifest.lua has been properly updated")
        
    def test_admin_menu_server(self):
        """Test server-side admin menu implementation"""
        print("\nTesting server-side admin menu implementation...")
        
        with open('/app/server/admin_menu.lua', 'r') as f:
            content = f.read()
            
        # Check for key components
        self.assertIn("RegisterCommand('npcadmin'", content, "Admin command should be registered")
        self.assertIn("IsPlayerAceAllowed(source, Config.Permissions.AdminGroup)", content, "Permission checking should be implemented")
        self.assertIn("AdminMenu.LoadData", content, "Data loading function should exist")
        self.assertIn("gang_npc:openAdminMenu", content, "Admin menu event should be triggered")
        
        # Check for event handlers
        self.assertIn("RegisterServerEvent('gang_npc:adminSpawnNPCs')", content, "Spawn NPCs event should be registered")
        self.assertIn("RegisterServerEvent('gang_npc:adminDeleteNPC')", content, "Delete NPC event should be registered")
        self.assertIn("RegisterServerEvent('gang_npc:adminUpdateNPC')", content, "Update NPC event should be registered")
        self.assertIn("RegisterServerEvent('gang_npc:adminClearAllNPCs')", content, "Clear all NPCs event should be registered")
        
        # Check for callback registration
        self.assertIn("lib.callback.register('gang_npc:getAdminData'", content, "Admin data callback should be registered")
        
        print("✅ Server-side admin menu implementation looks good")
        
    def test_admin_menu_client(self):
        """Test client-side admin menu implementation"""
        print("\nTesting client-side admin menu implementation...")
        
        with open('/app/client/admin_menu.lua', 'r') as f:
            content = f.read()
            
        # Check for key components
        self.assertIn("RegisterNetEvent('gang_npc:openAdminMenu')", content, "Admin menu event handler should exist")
        self.assertIn("AdminMenuClient.OpenMainMenu", content, "Main menu function should exist")
        
        # Check for lib.registerContext usage
        self.assertIn("lib.registerContext", content, "ox_lib context menu should be used")
        self.assertIn("lib.showContext", content, "ox_lib context menu should be shown")
        
        # Check for menu sections
        self.assertIn("Dashboard", content, "Dashboard section should exist")
        self.assertIn("Gerenciar NPCs", content, "NPC management section should exist")
        self.assertIn("Grupos", content, "Groups section should exist")
        self.assertIn("Spawnar NPCs", content, "Spawn NPCs section should exist")
        self.assertIn("Ações Rápidas", content, "Quick actions section should exist")
        
        # Check for input dialogs
        self.assertIn("lib.inputDialog", content, "ox_lib input dialog should be used")
        self.assertIn("lib.alertDialog", content, "ox_lib alert dialog should be used")
        
        print("✅ Client-side admin menu implementation looks good")
        
    def test_main_lua_changes(self):
        """Test changes to main.lua"""
        print("\nTesting main.lua changes...")
        
        with open('/app/client/main.lua', 'r') as f:
            content = f.read()
            
        # Check that NUI focus calls are removed
        self.assertNotIn("SetNuiFocus", content, "SetNuiFocus calls should be removed")
        
        # Check that F10 menu still works
        self.assertIn("RegisterKeyMapping('+gang_npc_menu', 'Abrir/Fechar Menu de Controle de NPCs', 'keyboard', 'F10')", 
                     content, "F10 key mapping should still exist")
        
        # Check that admin panel reference is updated
        self.assertIn("-- Removido - usando ox_lib menu agora", content, "Admin panel should be noted as removed")
        
        # Check for lib.showContext usage
        self.assertIn("lib.showContext", content, "ox_lib context menu should be used")
        
        print("✅ main.lua changes look good")
        
    def test_npcadmin_command(self):
        """Test the /npcadmin command implementation"""
        print("\nTesting /npcadmin command implementation...")
        
        with open('/app/server/admin_menu.lua', 'r') as f:
            server_content = f.read()
            
        # Check command registration
        self.assertIn("RegisterCommand('npcadmin'", server_content, "/npcadmin command should be registered")
        
        # Check permission validation
        self.assertIn("if not IsPlayerAceAllowed(source, Config.Permissions.AdminGroup)", 
                     server_content, "Command should check admin permissions")
        
        # Check data loading and menu opening
        self.assertIn("AdminMenu.LoadData", server_content, "Command should load data")
        self.assertIn("TriggerClientEvent('gang_npc:openAdminMenu'", 
                     server_content, "Command should trigger menu opening")
        
        print("✅ /npcadmin command implementation looks good")
        
    def test_menu_features(self):
        """Test comprehensive menu features"""
        print("\nTesting comprehensive menu features...")
        
        with open('/app/client/admin_menu.lua', 'r') as f:
            content = f.read()
            
        # Check dashboard features
        self.assertIn("OpenDashboard", content, "Dashboard function should exist")
        self.assertIn("Estatísticas Gerais", content, "Dashboard should show statistics")
        self.assertIn("Distribuição por Gangue", content, "Dashboard should show gang distribution")
        
        # Check NPC management
        self.assertIn("OpenNPCsMenu", content, "NPC management function should exist")
        self.assertIn("OpenNPCActions", content, "NPC actions function should exist")
        self.assertIn("OpenEditNPC", content, "Edit NPC function should exist")
        self.assertIn("ConfirmDeleteNPC", content, "Delete NPC confirmation should exist")
        
        # Check spawn system
        self.assertIn("OpenSpawnMenu", content, "Spawn menu function should exist")
        self.assertIn("type = 'select',\n            label = 'Gangue'", content, "Gang selection should exist")
        self.assertIn("type = 'select',\n            label = 'Formação'", content, "Formation selection should exist")
        
        # Check quick actions
        self.assertIn("OpenQuickActions", content, "Quick actions function should exist")
        self.assertIn("Limpar Todos os NPCs", content, "Clear all NPCs action should exist")
        self.assertIn("Mostrar Estatísticas", content, "Show statistics action should exist")
        self.assertIn("Recarregar Resource", content, "Resource restart action should exist")
        
        print("✅ Menu features look comprehensive and complete")
        
    def test_f10_menu_preservation(self):
        """Test that F10 NPC menu still works"""
        print("\nTesting F10 NPC menu preservation...")
        
        with open('/app/client/main.lua', 'r') as f:
            content = f.read()
            
        # Check F10 key mapping
        self.assertIn("RegisterKeyMapping('+gang_npc_menu'", content, "F10 key mapping should exist")
        
        # Check menu functions
        self.assertIn("OpenNPCControlMenu", content, "NPC control menu function should exist")
        self.assertIn("BuildNPCControlMenu", content, "Build NPC control menu function should exist")
        
        # Check menu content
        self.assertIn("Meus NPCs", content, "My NPCs section should exist")
        self.assertIn("Meus Grupos", content, "My Groups section should exist")
        self.assertIn("NPCs Próximos", content, "Nearby NPCs section should exist")
        
        print("✅ F10 NPC menu is preserved")
        
    def tearDown(self):
        """Clean up after tests"""
        print("\n=== Gang NPC Manager test completed ===")

if __name__ == "__main__":
    unittest.main()
