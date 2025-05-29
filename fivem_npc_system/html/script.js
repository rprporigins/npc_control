// Gang NPC Manager - Admin Panel JavaScript

let currentData = {
    npcs: [],
    groups: [],
    stats: {},
    gangs: {}
};

let selectedGang = 'ballas';
let editingNPC = null;

// Initialize
document.addEventListener('DOMContentLoaded', function() {
    initializeEventListeners();
    initializeTabs();
});

// Event Listeners
function initializeEventListeners() {
    // Tab navigation
    document.querySelectorAll('.nav-tab').forEach(tab => {
        tab.addEventListener('click', function() {
            switchTab(this.dataset.tab);
        });
    });

    // Form submissions
    document.getElementById('spawn-form').addEventListener('submit', handleSpawnSubmit);
    
    // Search functionality
    document.getElementById('npc-search').addEventListener('input', filterNPCs);

    // Escape key to close
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            closePanel();
        }
    });
}

// Initialize tabs
function initializeTabs() {
    // Show first tab by default
    switchTab('spawn');
}

// Switch between tabs
function switchTab(tabName) {
    // Remove active class from all tabs and content
    document.querySelectorAll('.nav-tab').forEach(tab => tab.classList.remove('active'));
    document.querySelectorAll('.tab-content').forEach(content => content.classList.remove('active'));

    // Add active class to selected tab and content
    document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');
    document.getElementById(`${tabName}-tab`).classList.add('active');
}

// Update admin panel data
function updatePanelData(data) {
    currentData = data;
    updateNPCList();
    updateGroupsList();
    updateStats();
}

// NUI Message Handler
window.addEventListener('message', function(event) {
    const data = event.data;

    switch(data.type) {
        case 'openAdminPanel':
            openAdminPanel(data.data);
            break;
        case 'updateData':
            updatePanelData(data.data);
            break;
        case 'showNotification':
            showNotification(data.message, data.type);
            break;
    }
});

// Open admin panel with data
function openAdminPanel(data) {
    currentData = data;
    
    // Show container
    document.getElementById('container').classList.remove('hidden');
    
    // Update all sections
    updateGangSelector();
    updateNPCList();
    updateGroupsList();
    updateStats();
    
    // Set default values
    resetSpawnForm();
}

// Update gang selector
function updateGangSelector() {
    const selector = document.getElementById('gang-selector');
    selector.innerHTML = '';

    Object.entries(currentData.gangs).forEach(([gangId, gangConfig]) => {
        const option = document.createElement('div');
        option.className = `gang-option ${gangId === selectedGang ? 'selected' : ''}`;
        option.dataset.gang = gangId;
        option.innerHTML = `
            <div class="gang-color" style="background-color: ${gangConfig.color}"></div>
            <div class="gang-name">${gangConfig.name}</div>
        `;
        
        option.addEventListener('click', function() {
            selectGang(gangId);
        });
        
        selector.appendChild(option);
    });
}

// Select gang
function selectGang(gangId) {
    selectedGang = gangId;
    
    // Update visual selection
    document.querySelectorAll('.gang-option').forEach(option => {
        option.classList.remove('selected');
    });
    document.querySelector(`[data-gang="${gangId}"]`).classList.add('selected');
    
    // Update model and weapon dropdowns
    updateModelOptions();
    updateWeaponOptions();
}

// Update model dropdown based on selected gang
function updateModelOptions() {
    const modelSelect = document.getElementById('model');
    const gangConfig = currentData.gangs[selectedGang];
    
    modelSelect.innerHTML = '<option value="">Selecione um modelo</option>';
    
    if (gangConfig && gangConfig.models) {
        gangConfig.models.forEach(model => {
            const option = document.createElement('option');
            option.value = model;
            option.textContent = model;
            modelSelect.appendChild(option);
        });
        
        // Select first model by default
        if (gangConfig.models.length > 0) {
            modelSelect.value = gangConfig.models[0];
        }
    }
}

// Update weapon dropdown based on selected gang
function updateWeaponOptions() {
    const weaponSelect = document.getElementById('weapon');
    const gangConfig = currentData.gangs[selectedGang];
    
    weaponSelect.innerHTML = '<option value="">Selecione uma arma</option>';
    
    if (gangConfig && gangConfig.weapons) {
        gangConfig.weapons.forEach(weapon => {
            const option = document.createElement('option');
            option.value = weapon;
            option.textContent = weapon;
            weaponSelect.appendChild(option);
        });
        
        // Select first weapon by default
        if (gangConfig.weapons.length > 0) {
            weaponSelect.value = gangConfig.weapons[0];
        }
    }
}

// Extract vec3 coordinates
function extractVec3() {
    const input = document.getElementById('vec3-input').value.trim();
    
    if (!input) {
        showNotification('Digite um vec3 válido', 'error');
        return;
    }
    
    // Extract numbers from vec3 string
    const numbers = input.match(/-?\d+\.?\d*/g);
    
    if (numbers && numbers.length >= 3) {
        document.getElementById('pos-x').value = parseFloat(numbers[0]);
        document.getElementById('pos-y').value = parseFloat(numbers[1]);
        document.getElementById('pos-z').value = parseFloat(numbers[2]);
        
        showNotification('Coordenadas extraídas com sucesso!', 'success');
    } else {
        showNotification('Formato vec3 inválido', 'error');
    }
}

// Handle spawn form submission
function handleSpawnSubmit(e) {
    e.preventDefault();
    
    const formData = new FormData(e.target);
    const spawnData = {
        gang: selectedGang,
        model: formData.get('model'),
        weapon: formData.get('weapon'),
        quantity: parseInt(formData.get('quantity')),
        formation: formData.get('formation'),
        health: parseInt(formData.get('health')),
        armor: parseInt(formData.get('armor')),
        accuracy: parseInt(formData.get('accuracy')),
        position: {
            x: parseFloat(formData.get('pos_x')),
            y: parseFloat(formData.get('pos_y')),
            z: parseFloat(formData.get('pos_z'))
        },
        owner_ids: formData.get('owner_ids'),
        leader_ids: formData.get('leader_ids'),
        friend_ids: formData.get('friend_ids'),
        vec3_input: formData.get('vec3_input')
    };
    
    // Validate required fields
    if (!spawnData.model || !spawnData.weapon) {
        showNotification('Selecione modelo e arma', 'error');
        return;
    }
    
    if (spawnData.quantity < 1 || spawnData.quantity > 20) {
        showNotification('Quantidade deve ser entre 1 e 20', 'error');
        return;
    }
    
    // Send to FiveM
    showLoading(true);
    sendNUIMessage('spawnFromPanel', spawnData);
}

// Update NPC list
function updateNPCList() {
    const grid = document.getElementById('npc-grid');
    grid.innerHTML = '';

    if (!currentData.npcs || currentData.npcs.length === 0) {
        grid.innerHTML = `
            <div style="grid-column: 1 / -1; text-align: center; color: #9ca3af; padding: 40px;">
                <i class="fas fa-robot" style="font-size: 48px; margin-bottom: 20px; opacity: 0.5;"></i>
                <p>Nenhum NPC ativo</p>
            </div>
        `;
        return;
    }

    currentData.npcs.forEach(npc => {
        const gangConfig = currentData.gangs[npc.gang];
        if (!gangConfig) return;

        const card = document.createElement('div');
        card.className = 'npc-card';
        card.innerHTML = `
            <div class="npc-header">
                <div class="npc-title">
                    <div class="npc-gang-color" style="background-color: ${gangConfig.color}"></div>
                    <span>${gangConfig.name}</span>
                </div>
                <div class="npc-actions">
                    <button class="action-btn edit" onclick="editNPC('${npc.id}')">
                        <i class="fas fa-edit"></i>
                    </button>
                    <button class="action-btn delete" onclick="deleteNPC('${npc.id}')">
                        <i class="fas fa-trash"></i>
                    </button>
                </div>
            </div>
            <div class="npc-info">
                <div class="npc-info-item">
                    <span class="npc-info-label">ID:</span>
                    <span class="npc-info-value">${npc.id.substring(0, 8)}</span>
                </div>
                <div class="npc-info-item">
                    <span class="npc-info-label">Estado:</span>
                    <span class="npc-info-value">${npc.state || 'idle'}</span>
                </div>
                <div class="npc-info-item">
                    <span class="npc-info-label">Vida:</span>
                    <span class="npc-info-value">${npc.health || 100}</span>
                </div>
                <div class="npc-info-item">
                    <span class="npc-info-label">Armadura:</span>
                    <span class="npc-info-value">${npc.armor || 0}</span>
                </div>
                <div class="npc-info-item">
                    <span class="npc-info-label">Precisão:</span>
                    <span class="npc-info-value">${npc.accuracy || 50}%</span>
                </div>
                <div class="npc-info-item">
                    <span class="npc-info-label">Arma:</span>
                    <span class="npc-info-value">${npc.weapon || 'N/A'}</span>
                </div>
            </div>
        `;
        
        grid.appendChild(card);
    });
}

// Filter NPCs based on search
function filterNPCs() {
    const searchTerm = document.getElementById('npc-search').value.toLowerCase();
    const cards = document.querySelectorAll('.npc-card');
    
    cards.forEach(card => {
        const text = card.textContent.toLowerCase();
        if (text.includes(searchTerm)) {
            card.style.display = 'block';
        } else {
            card.style.display = 'none';
        }
    });
}

// Edit NPC
function editNPC(npcId) {
    const npc = currentData.npcs.find(n => n.id === npcId);
    if (!npc) return;
    
    editingNPC = npc;
    
    // Populate edit form
    document.getElementById('edit-health').value = npc.health || 100;
    document.getElementById('edit-armor').value = npc.armor || 0;
    document.getElementById('edit-accuracy').value = npc.accuracy || 50;
    document.getElementById('edit-owners').value = (npc.owners || []).join(', ');
    document.getElementById('edit-leaders').value = (npc.leaders || []).join(', ');
    
    // Update weapon options for edit form
    updateEditWeaponOptions(npc.gang);
    document.getElementById('edit-weapon').value = npc.weapon || '';
    
    // Show modal
    document.getElementById('edit-modal').classList.remove('hidden');
}

// Update weapon options in edit form
function updateEditWeaponOptions(gang) {
    const weaponSelect = document.getElementById('edit-weapon');
    const gangConfig = currentData.gangs[gang];
    
    weaponSelect.innerHTML = '<option value="">Selecione uma arma</option>';
    
    if (gangConfig && gangConfig.weapons) {
        gangConfig.weapons.forEach(weapon => {
            const option = document.createElement('option');
            option.value = weapon;
            option.textContent = weapon;
            weaponSelect.appendChild(option);
        });
    }
}

// Save NPC edit
function saveNPCEdit() {
    if (!editingNPC) return;
    
    const updateData = {
        health: parseInt(document.getElementById('edit-health').value),
        armor: parseInt(document.getElementById('edit-armor').value),
        accuracy: parseInt(document.getElementById('edit-accuracy').value),
        weapon: document.getElementById('edit-weapon').value,
        owners: document.getElementById('edit-owners').value.split(',').map(s => s.trim()).filter(s => s),
        leaders: document.getElementById('edit-leaders').value.split(',').map(s => s.trim()).filter(s => s)
    };
    
    // Send to FiveM
    showLoading(true);
    sendNUIMessage('updateFromPanel', { npcId: editingNPC.id, updateData });
}

// Delete NPC
function deleteNPC(npcId) {
    if (!confirm('Tem certeza que deseja deletar este NPC?')) return;
    
    showLoading(true);
    sendNUIMessage('deleteFromPanel', { npcId });
}

// Clear all NPCs
function clearAllNPCs() {
    if (!confirm('Tem certeza que deseja deletar TODOS os NPCs?')) return;
    
    showLoading(true);
    sendNUIMessage('clearAllNPCs', {});
}

// Refresh NPCs
function refreshNPCs() {
    showLoading(true);
    sendNUIMessage('refreshData', {});
}

// Update groups list
function updateGroupsList() {
    const grid = document.getElementById('groups-grid');
    grid.innerHTML = '';

    if (!currentData.groups || currentData.groups.length === 0) {
        grid.innerHTML = `
            <div style="text-align: center; color: #9ca3af; padding: 40px;">
                <i class="fas fa-users" style="font-size: 48px; margin-bottom: 20px; opacity: 0.5;"></i>
                <p>Nenhum grupo criado</p>
            </div>
        `;
        return;
    }

    // Groups implementation would go here
    grid.innerHTML = '<p style="color: #9ca3af;">Sistema de grupos em desenvolvimento...</p>';
}

// Update statistics
function updateStats() {
    if (!currentData.stats) return;
    
    // Update header stats
    document.getElementById('total-npcs').textContent = currentData.stats.total_npcs || 0;
    document.getElementById('total-groups').textContent = currentData.stats.total_groups || 0;
    
    // Update detailed stats
    document.getElementById('stats-total-npcs').textContent = currentData.stats.total_npcs || 0;
    document.getElementById('stats-total-groups').textContent = currentData.stats.total_groups || 0;
    document.getElementById('stats-active-players').textContent = currentData.stats.active_players || 0;
    document.getElementById('stats-gang-count').textContent = Object.keys(currentData.stats.gang_distribution || {}).length;
    
    // Update gang distribution bars
    updateGangBars();
}

// Update gang distribution bars
function updateGangBars() {
    const barsContainer = document.getElementById('gang-bars');
    barsContainer.innerHTML = '';
    
    const distribution = currentData.stats.gang_distribution || {};
    const total = currentData.stats.total_npcs || 1;
    
    Object.entries(distribution).forEach(([gang, count]) => {
        const gangConfig = currentData.gangs[gang];
        if (!gangConfig) return;
        
        const percentage = (count / total) * 100;
        
        const bar = document.createElement('div');
        bar.className = 'gang-bar';
        bar.innerHTML = `
            <div class="gang-bar-label">
                <div class="gang-bar-color" style="background-color: ${gangConfig.color}"></div>
                <span>${gangConfig.name}</span>
            </div>
            <div class="gang-bar-progress">
                <div class="gang-bar-fill" style="width: ${percentage}%; background-color: ${gangConfig.color}"></div>
            </div>
            <div class="gang-bar-count">${count}</div>
        `;
        
        barsContainer.appendChild(bar);
    });
}

// Send NUI message to FiveM
function sendNUIMessage(action, data) {
    fetch(`https://${GetParentResourceName()}/${action}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(data)
    }).then(() => {
        showLoading(false);
    }).catch(() => {
        showLoading(false);
        showNotification('Erro na comunicação com o servidor', 'error');
    });
}

// Close edit modal
function closeEditModal() {
    document.getElementById('edit-modal').classList.add('hidden');
    editingNPC = null;
}

// Clear spawn form
function clearForm() {
    document.getElementById('spawn-form').reset();
    resetSpawnForm();
}

// Reset spawn form to defaults
function resetSpawnForm() {
    selectedGang = 'ballas';
    selectGang(selectedGang);
    
    // Set default values
    document.getElementById('quantity').value = 1;
    document.getElementById('formation').value = 'circle';
    document.getElementById('health').value = 100;
    document.getElementById('armor').value = 0;
    document.getElementById('accuracy').value = 50;
    document.getElementById('pos-x').value = 0;
    document.getElementById('pos-y').value = 0;
    document.getElementById('pos-z').value = 0;
}

// Show/hide loading
function showLoading(show) {
    const loading = document.getElementById('loading');
    if (show) {
        loading.classList.remove('hidden');
    } else {
        loading.classList.add('hidden');
    }
}

// Show notification
function showNotification(message, type = 'info') {
    // This would integrate with FiveM's notification system
    console.log(`[${type.toUpperCase()}] ${message}`);
}

// Close panel
function closePanel() {
    document.getElementById('container').classList.add('hidden');
    sendNUIMessage('closePanel', {});
}

// Utility function to get parent resource name
function GetParentResourceName() {
    return window.location.hostname === '' ? 'gang_npc_manager' : window.location.hostname;
}

// Export functions for global access
window.extractVec3 = extractVec3;
window.clearForm = clearForm;
window.editNPC = editNPC;
window.deleteNPC = deleteNPC;
window.clearAllNPCs = clearAllNPCs;
window.refreshNPCs = refreshNPCs;
window.closeEditModal = closeEditModal;
window.saveNPCEdit = saveNPCEdit;
window.closePanel = closePanel;