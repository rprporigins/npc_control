// Gang NPC Manager - Modern Admin Panel JavaScript

class GangNPCManager {
    constructor() {
        this.data = {
            npcs: [],
            groups: [],
            gangs: {},
            stats: {}
        };
        
        this.currentTab = 'dashboard';
        this.selectedNPCs = new Set();
        
        this.init();
    }

    init() {
        console.log('🎮 Gang NPC Manager Admin Panel Initialized');
        
        // Setup event listeners
        this.setupEventListeners();
        
        // Setup NUI message handler
        this.setupNUIHandler();
        
        // Initialize tabs
        this.initializeTabs();
        
        console.log('✅ Admin Panel Ready');
    }

    setupEventListeners() {
        // Close panel
        document.getElementById('close-panel').addEventListener('click', () => {
            this.closePanel();
        });

        // Tab navigation
        document.querySelectorAll('.nav-item').forEach(item => {
            item.addEventListener('click', (e) => {
                const tab = e.currentTarget.getAttribute('data-tab');
                this.switchTab(tab);
            });
        });

        // Spawn form
        const spawnForm = document.getElementById('spawn-form');
        if (spawnForm) {
            spawnForm.addEventListener('submit', (e) => {
                e.preventDefault();
                this.handleSpawnNPCs();
            });
        }

        // Gang selection change
        const spawnGangSelect = document.getElementById('spawn-gang');
        if (spawnGangSelect) {
            spawnGangSelect.addEventListener('change', (e) => {
                this.updateModelsAndWeapons(e.target.value);
            });
        }

        // Bulk actions
        const bulkDeleteBtn = document.getElementById('bulk-delete');
        if (bulkDeleteBtn) {
            bulkDeleteBtn.addEventListener('click', () => {
                this.handleBulkDelete();
            });
        }

        // Select all NPCs
        const selectAllCheckbox = document.getElementById('select-all-npcs');
        if (selectAllCheckbox) {
            selectAllCheckbox.addEventListener('change', (e) => {
                this.handleSelectAllNPCs(e.target.checked);
            });
        }

        // Refresh buttons
        const refreshBtn = document.getElementById('refresh-npcs');
        if (refreshBtn) {
            refreshBtn.addEventListener('click', () => {
                this.refreshData();
            });
        }

        // Modal handlers
        this.setupModalHandlers();

        // Escape key to close
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                this.closePanel();
            }
        });
    }

    setupNUIHandler() {
        window.addEventListener('message', (event) => {
            const data = event.data;
            
            switch (data.type) {
                case 'openAdminPanel':
                    console.log('📊 Opening admin panel with data:', data.data);
                    this.loadData(data.data);
                    this.showPanel();
                    break;
                    
                case 'updateData':
                    console.log('🔄 Updating panel data');
                    this.loadData(data.data);
                    this.refreshCurrentTab();
                    break;
                    
                case 'notification':
                    this.showNotification(data.message, data.type || 'info');
                    break;
                    
                default:
                    console.log('🔍 Unknown NUI message type:', data.type);
            }
        });
    }

    setupModalHandlers() {
        // Modal overlay click to close
        const modalOverlay = document.getElementById('modal-overlay');
        if (modalOverlay) {
            modalOverlay.addEventListener('click', (e) => {
                if (e.target === modalOverlay) {
                    this.closeModal();
                }
            });
        }

        // Modal close buttons
        document.querySelectorAll('.modal-close, .modal-cancel').forEach(btn => {
            btn.addEventListener('click', () => {
                this.closeModal();
            });
        });

        // Save NPC edit
        const saveEditBtn = document.getElementById('save-npc-edit');
        if (saveEditBtn) {
            saveEditBtn.addEventListener('click', () => {
                this.saveNPCEdit();
            });
        }
    }

    initializeTabs() {
        // Show dashboard by default
        this.switchTab('dashboard');
    }

    loadData(data) {
        console.log('📂 Loading data into admin panel:', data);
        
        this.data = {
            npcs: data.npcs || [],
            groups: data.groups || [],
            gangs: data.gangs || {},
            stats: data.stats || {}
        };

        // Update header stats
        this.updateHeaderStats();
        
        // Populate gang options
        this.populateGangOptions();
        
        // Refresh current tab
        this.refreshCurrentTab();
    }

    updateHeaderStats() {
        const stats = this.data.stats;
        
        document.getElementById('total-npcs').textContent = stats.total_npcs || 0;
        document.getElementById('total-groups').textContent = stats.total_groups || 0;
        document.getElementById('active-players').textContent = stats.active_players || 0;
        
        // Dashboard stats
        document.getElementById('dash-total-npcs').textContent = stats.total_npcs || 0;
        document.getElementById('dash-total-groups').textContent = stats.total_groups || 0;
        document.getElementById('dash-active-players').textContent = stats.active_players || 0;
    }

    populateGangOptions() {
        const spawnGangSelect = document.getElementById('spawn-gang');
        if (!spawnGangSelect) return;

        // Clear existing options (except first)
        while (spawnGangSelect.children.length > 1) {
            spawnGangSelect.removeChild(spawnGangSelect.lastChild);
        }

        // Add gang options
        Object.entries(this.data.gangs).forEach(([gangId, gangData]) => {
            const option = document.createElement('option');
            option.value = gangId;
            option.textContent = gangData.name;
            spawnGangSelect.appendChild(option);
        });
    }

    updateModelsAndWeapons(gangId) {
        const gangData = this.data.gangs[gangId];
        if (!gangData) return;

        // Update models
        const modelSelect = document.getElementById('spawn-model');
        if (modelSelect) {
            // Clear existing options (except first)
            while (modelSelect.children.length > 1) {
                modelSelect.removeChild(modelSelect.lastChild);
            }

            gangData.models.forEach(model => {
                const option = document.createElement('option');
                option.value = model;
                option.textContent = model;
                modelSelect.appendChild(option);
            });
        }

        // Update weapons
        const weaponSelect = document.getElementById('spawn-weapon');
        if (weaponSelect) {
            // Clear existing options (except first)
            while (weaponSelect.children.length > 1) {
                weaponSelect.removeChild(weaponSelect.lastChild);
            }

            gangData.weapons.forEach(weapon => {
                const option = document.createElement('option');
                option.value = weapon;
                option.textContent = weapon.replace('WEAPON_', '');
                weaponSelect.appendChild(option);
            });
        }
    }

    switchTab(tabName) {
        console.log('📑 Switching to tab:', tabName);
        
        // Update navigation
        document.querySelectorAll('.nav-item').forEach(item => {
            item.classList.remove('active');
        });
        document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');

        // Update content
        document.querySelectorAll('.tab-content').forEach(content => {
            content.classList.remove('active');
        });
        document.getElementById(`${tabName}-tab`).classList.add('active');

        this.currentTab = tabName;
        this.refreshCurrentTab();
    }

    refreshCurrentTab() {
        switch (this.currentTab) {
            case 'dashboard':
                this.renderDashboard();
                break;
            case 'npcs':
                this.renderNPCsTable();
                break;
            case 'groups':
                this.renderGroupsGrid();
                break;
            case 'spawn':
                // Form is static, no need to refresh
                break;
            case 'settings':
                this.renderSettings();
                break;
        }
    }

    renderDashboard() {
        console.log('📊 Rendering dashboard');
        
        // Render gang distribution
        this.renderGangDistribution();
        
        // Render recent activity
        this.renderRecentActivity();
    }

    renderGangDistribution() {
        const container = document.getElementById('gang-distribution');
        if (!container) return;

        container.innerHTML = '';

        const distribution = this.data.stats.gang_distribution || {};
        
        Object.entries(distribution).forEach(([gangId, count]) => {
            const gangData = this.data.gangs[gangId];
            if (!gangData) return;

            const gangItem = document.createElement('div');
            gangItem.className = 'gang-item';
            
            gangItem.innerHTML = `
                <div class="gang-info">
                    <div class="gang-color" style="background-color: ${gangData.color}"></div>
                    <span class="gang-name">${gangData.name}</span>
                </div>
                <span class="gang-count">${count}</span>
            `;
            
            container.appendChild(gangItem);
        });

        if (Object.keys(distribution).length === 0) {
            container.innerHTML = '<p style="color: var(--text-muted); text-align: center;">Nenhum NPC ativo</p>';
        }
    }

    renderRecentActivity() {
        const container = document.getElementById('recent-activity');
        if (!container) return;

        // Mock recent activity for now
        const activities = [
            { action: 'NPC Spawned', details: 'Ballas NPC criado por Admin', time: '2 min atrás', icon: 'fas fa-plus', color: 'var(--success-color)' },
            { action: 'Group Created', details: 'Novo grupo "Patrol Alpha"', time: '5 min atrás', icon: 'fas fa-users', color: 'var(--primary-color)' },
            { action: 'NPC Deleted', details: 'Vagos NPC removido', time: '10 min atrás', icon: 'fas fa-trash', color: 'var(--danger-color)' }
        ];

        container.innerHTML = '';

        activities.forEach(activity => {
            const activityItem = document.createElement('div');
            activityItem.className = 'activity-item';
            
            activityItem.innerHTML = `
                <div class="activity-icon" style="background-color: ${activity.color}">
                    <i class="${activity.icon}"></i>
                </div>
                <div class="activity-content">
                    <div class="activity-action">${activity.action}</div>
                    <div class="activity-details">${activity.details}</div>
                </div>
                <div class="activity-time">${activity.time}</div>
            `;
            
            container.appendChild(activityItem);
        });
    }

    renderNPCsTable() {
        console.log('🤖 Rendering NPCs table');
        
        const tbody = document.getElementById('npcs-tbody');
        if (!tbody) return;

        tbody.innerHTML = '';

        this.data.npcs.forEach(npc => {
            const row = document.createElement('tr');
            row.innerHTML = `
                <td>
                    <input type="checkbox" class="npc-checkbox" data-npc-id="${npc.id}">
                </td>
                <td>
                    <span title="${npc.id}">${npc.id.substring(0, 8)}...</span>
                </td>
                <td>
                    <div style="display: flex; align-items: center; gap: 0.5rem;">
                        <div class="gang-color" style="background-color: ${this.data.gangs[npc.gang]?.color || '#666'}; width: 12px; height: 12px; border-radius: 50%;"></div>
                        ${this.data.gangs[npc.gang]?.name || npc.gang}
                    </div>
                </td>
                <td>${npc.model}</td>
                <td><span class="status-badge status-${npc.state}">${npc.state}</span></td>
                <td>
                    <div style="display: flex; align-items: center; gap: 0.5rem;">
                        <div style="background: var(--success-color); height: 4px; width: ${(npc.health || 100)}%; border-radius: 2px;"></div>
                        <span>${npc.health || 100}%</span>
                    </div>
                </td>
                <td>
                    <span title="X: ${npc.position?.x || 0}, Y: ${npc.position?.y || 0}, Z: ${npc.position?.z || 0}">
                        ${Math.round(npc.position?.x || 0)}, ${Math.round(npc.position?.y || 0)}
                    </span>
                </td>
                <td>
                    <div style="display: flex; gap: 0.25rem;">
                        <button class="btn-secondary" style="padding: 0.25rem 0.5rem; font-size: 0.75rem;" onclick="gangNPCManager.editNPC('${npc.id}')">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn-danger" style="padding: 0.25rem 0.5rem; font-size: 0.75rem;" onclick="gangNPCManager.deleteNPC('${npc.id}')">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </td>
            `;
            
            tbody.appendChild(row);
        });

        // Add checkbox listeners
        document.querySelectorAll('.npc-checkbox').forEach(checkbox => {
            checkbox.addEventListener('change', (e) => {
                const npcId = e.target.getAttribute('data-npc-id');
                if (e.target.checked) {
                    this.selectedNPCs.add(npcId);
                } else {
                    this.selectedNPCs.delete(npcId);
                }
                this.updateBulkActions();
            });
        });

        if (this.data.npcs.length === 0) {
            tbody.innerHTML = '<tr><td colspan="8" style="text-align: center; color: var(--text-muted);">Nenhum NPC encontrado</td></tr>';
        }
    }

    renderGroupsGrid() {
        console.log('👥 Rendering groups grid');
        
        const container = document.getElementById('groups-grid');
        if (!container) return;

        container.innerHTML = '';

        this.data.groups.forEach(group => {
            const groupCard = document.createElement('div');
            groupCard.className = 'group-card';
            
            groupCard.innerHTML = `
                <div class="group-header">
                    <div>
                        <div class="group-name">${group.name}</div>
                        <div class="group-gang">${this.data.gangs[group.gang]?.name || group.gang}</div>
                    </div>
                    <div class="group-actions">
                        <button class="btn-secondary" style="padding: 0.25rem 0.5rem; font-size: 0.75rem;" onclick="gangNPCManager.editGroup('${group.id}')">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn-danger" style="padding: 0.25rem 0.5rem; font-size: 0.75rem;" onclick="gangNPCManager.deleteGroup('${group.id}')">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </div>
                <div class="group-stats">
                    <div class="group-stat">
                        <div class="group-stat-value">${group.members?.length || 0}</div>
                        <div class="group-stat-label">Membros</div>
                    </div>
                    <div class="group-stat">
                        <div class="group-stat-value">${group.auto_defend ? 'Sim' : 'Não'}</div>
                        <div class="group-stat-label">Auto Defesa</div>
                    </div>
                </div>
            `;
            
            container.appendChild(groupCard);
        });

        if (this.data.groups.length === 0) {
            container.innerHTML = '<p style="color: var(--text-muted); text-align: center; grid-column: 1 / -1;">Nenhum grupo encontrado</p>';
        }
    }

    renderSettings() {
        console.log('⚙️ Rendering settings');
        // Settings are mostly static form elements
    }

    handleSpawnNPCs() {
        console.log('🚀 Handling spawn NPCs');
        
        const formData = new FormData(document.getElementById('spawn-form'));
        const spawnData = {};
        
        // Collect form data
        for (let [key, value] of formData.entries()) {
            spawnData[key.replace('spawn-', '')] = value;
        }

        // Collect additional data
        spawnData.gang = document.getElementById('spawn-gang').value;
        spawnData.quantity = parseInt(document.getElementById('spawn-quantity').value) || 1;
        spawnData.formation = document.getElementById('spawn-formation').value;
        spawnData.model = document.getElementById('spawn-model').value;
        spawnData.weapon = document.getElementById('spawn-weapon').value;
        spawnData.health = parseInt(document.getElementById('spawn-health').value) || 100;
        spawnData.armor = parseInt(document.getElementById('spawn-armor').value) || 0;
        spawnData.accuracy = parseInt(document.getElementById('spawn-accuracy').value) || 50;
        
        // Parse position if provided
        const positionInput = document.getElementById('spawn-position').value.trim();
        if (positionInput) {
            spawnData.vec3_input = positionInput;
        }

        // Parse IDs
        const ownersInput = document.getElementById('spawn-owners').value.trim();
        if (ownersInput) {
            spawnData.owner_ids = ownersInput;
        }

        console.log('📊 Spawn data:', spawnData);

        // Validate required fields
        if (!spawnData.gang) {
            this.showNotification('Selecione uma gangue', 'error');
            return;
        }

        // Send to game
        this.sendNUIMessage('spawnNPCs', spawnData);
        
        // Show loading state
        this.showNotification('Spawnando NPCs...', 'info');
    }

    handleBulkDelete() {
        if (this.selectedNPCs.size === 0) {
            this.showNotification('Selecione NPCs para deletar', 'warning');
            return;
        }

        if (confirm(`Deletar ${this.selectedNPCs.size} NPCs selecionados?`)) {
            const npcIds = Array.from(this.selectedNPCs);
            this.sendNUIMessage('bulkDeleteNPCs', { npcIds });
            this.selectedNPCs.clear();
            this.updateBulkActions();
        }
    }

    handleSelectAllNPCs(checked) {
        document.querySelectorAll('.npc-checkbox').forEach(checkbox => {
            checkbox.checked = checked;
            const npcId = checkbox.getAttribute('data-npc-id');
            if (checked) {
                this.selectedNPCs.add(npcId);
            } else {
                this.selectedNPCs.delete(npcId);
            }
        });
        this.updateBulkActions();
    }

    updateBulkActions() {
        const bulkDeleteBtn = document.getElementById('bulk-delete');
        if (bulkDeleteBtn) {
            bulkDeleteBtn.disabled = this.selectedNPCs.size === 0;
            bulkDeleteBtn.textContent = `Deletar Selecionados (${this.selectedNPCs.size})`;
        }
    }

    editNPC(npcId) {
        console.log('✏️ Editing NPC:', npcId);
        
        const npc = this.data.npcs.find(n => n.id === npcId);
        if (!npc) return;

        // Populate edit form
        document.getElementById('edit-health').value = npc.health || 100;
        document.getElementById('edit-armor').value = npc.armor || 0;
        document.getElementById('edit-accuracy').value = npc.accuracy || 50;
        document.getElementById('edit-state').value = npc.state || 'idle';

        // Store current NPC ID
        this.currentEditNPC = npcId;

        // Show modal
        this.showModal('edit-npc-modal');
    }

    saveNPCEdit() {
        if (!this.currentEditNPC) return;

        const updateData = {
            health: parseInt(document.getElementById('edit-health').value),
            armor: parseInt(document.getElementById('edit-armor').value),
            accuracy: parseInt(document.getElementById('edit-accuracy').value),
            state: document.getElementById('edit-state').value
        };

        console.log('💾 Saving NPC edit:', this.currentEditNPC, updateData);

        this.sendNUIMessage('updateNPC', {
            npcId: this.currentEditNPC,
            updateData: updateData
        });

        this.closeModal();
        this.currentEditNPC = null;
    }

    deleteNPC(npcId) {
        if (confirm('Deletar este NPC?')) {
            console.log('🗑️ Deleting NPC:', npcId);
            this.sendNUIMessage('deleteNPC', { npcId });
        }
    }

    editGroup(groupId) {
        console.log('✏️ Editing group:', groupId);
        // TODO: Implement group editing
    }

    deleteGroup(groupId) {
        if (confirm('Deletar este grupo?')) {
            console.log('🗑️ Deleting group:', groupId);
            this.sendNUIMessage('deleteGroup', { groupId });
        }
    }

    showModal(modalId) {
        const overlay = document.getElementById('modal-overlay');
        const modal = document.getElementById(modalId);
        
        if (overlay && modal) {
            overlay.classList.add('active');
        }
    }

    closeModal() {
        const overlay = document.getElementById('modal-overlay');
        if (overlay) {
            overlay.classList.remove('active');
        }
    }

    refreshData() {
        console.log('🔄 Refreshing data');
        this.sendNUIMessage('refreshData', {});
    }

    showPanel() {
        document.body.style.display = 'block';
    }

    closePanel() {
        console.log('❌ Closing admin panel');
        this.sendNUIMessage('closePanel', {});
        document.body.style.display = 'none';
    }

    sendNUIMessage(action, data) {
        console.log('📤 Sending NUI message:', action, data);
        
        // Send message to FiveM NUI system
        fetch(`https://${GetParentResourceName()}/${action}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(data)
        }).catch(err => {
            console.error('❌ Failed to send NUI message:', err);
        });
    }

    showNotification(message, type = 'info') {
        console.log(`📢 Notification [${type}]: ${message}`);
        
        // Create notification element
        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.style.cssText = `
            position: fixed;
            top: 1rem;
            right: 1rem;
            padding: 1rem 1.5rem;
            border-radius: 0.5rem;
            color: white;
            font-weight: 500;
            z-index: 9999;
            opacity: 0;
            transform: translateX(100%);
            transition: all 0.3s ease;
        `;
        
        // Set background based on type
        const colors = {
            info: 'var(--primary-color)',
            success: 'var(--success-color)',
            warning: 'var(--warning-color)',
            error: 'var(--danger-color)'
        };
        notification.style.background = colors[type] || colors.info;
        
        notification.textContent = message;
        document.body.appendChild(notification);
        
        // Animate in
        setTimeout(() => {
            notification.style.opacity = '1';
            notification.style.transform = 'translateX(0)';
        }, 100);
        
        // Remove after 3 seconds
        setTimeout(() => {
            notification.style.opacity = '0';
            notification.style.transform = 'translateX(100%)';
            setTimeout(() => {
                if (notification.parentNode) {
                    notification.parentNode.removeChild(notification);
                }
            }, 300);
        }, 3000);
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.gangNPCManager = new GangNPCManager();
});

// Expose functions globally for onclick handlers
window.gangNPCManager = null;