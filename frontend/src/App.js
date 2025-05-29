import React, { useState, useEffect } from 'react';
import './App.css';
import axios from 'axios';

const BACKEND_URL = process.env.REACT_APP_BACKEND_URL;
const API = `${BACKEND_URL}/api`;

// Gang configurations (cores e nomes)
const GANG_COLORS = {
  ballas: '#800080',
  grove_street: '#00FF00',
  vagos: '#FFFF00',
  lost_mc: '#FF0000',
  triads: '#0000FF',
  armenian_mafia: '#4B0082'
};

const GANG_NAMES = {
  ballas: 'Ballas',
  grove_street: 'Grove Street Families',
  vagos: 'Los Santos Vagos',
  lost_mc: 'Lost MC',
  triads: 'Triads',
  armenian_mafia: 'Armenian Mafia'
};

const FORMATIONS = {
  circle: 'Círculo',
  line: 'Linha',
  square: 'Quadrado',
  scattered: 'Espalhado'
};

const COMMANDS = {
  follow: 'Seguir',
  stay: 'Parar',
  attack: 'Atacar',
  defend: 'Defender'
};

function App() {
  const [activeTab, setActiveTab] = useState('spawn');
  const [gangConfigs, setGangConfigs] = useState({});
  const [npcs, setNpcs] = useState([]);
  const [groups, setGroups] = useState([]);
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(false);

  // Spawn form state
  const [spawnForm, setSpawnForm] = useState({
    gang: 'ballas',
    model: '',
    quantity: 1,
    formation: 'circle',
    position: { x: 0, y: 0, z: 0 },
    weapon: ''
  });

  // Command form state
  const [commandForm, setCommandForm] = useState({
    npc_id: '',
    command: 'follow',
    target_id: '',
    position: { x: 0, y: 0, z: 0 }
  });

  useEffect(() => {
    loadGangConfigs();
    loadNPCs();
    loadGroups();
    loadStats();
  }, []);

  const loadGangConfigs = async () => {
    try {
      const response = await axios.get(`${API}/gangs`);
      setGangConfigs(response.data);
      if (response.data.ballas) {
        setSpawnForm(prev => ({
          ...prev,
          model: response.data.ballas.models[0],
          weapon: response.data.ballas.weapons[0]
        }));
      }
    } catch (error) {
      console.error('Erro ao carregar configurações das gangues:', error);
    }
  };

  const loadNPCs = async () => {
    try {
      const response = await axios.get(`${API}/npcs`);
      setNpcs(response.data);
    } catch (error) {
      console.error('Erro ao carregar NPCs:', error);
    }
  };

  const loadGroups = async () => {
    try {
      const response = await axios.get(`${API}/groups`);
      setGroups(response.data);
    } catch (error) {
      console.error('Erro ao carregar grupos:', error);
    }
  };

  const loadStats = async () => {
    try {
      const response = await axios.get(`${API}/stats`);
      setStats(response.data);
    } catch (error) {
      console.error('Erro ao carregar estatísticas:', error);
    }
  };

  const handleSpawnNPCs = async (e) => {
    e.preventDefault();
    setLoading(true);
    
    try {
      const response = await axios.post(`${API}/npc/spawn`, spawnForm);
      console.log(`${response.data.length} NPCs spawnados com sucesso!`);
      await loadNPCs();
      await loadGroups();
      await loadStats();
    } catch (error) {
      console.error('Erro ao spawnar NPCs:', error);
      alert('Erro ao spawnar NPCs: ' + error.response?.data?.detail);
    } finally {
      setLoading(false);
    }
  };

  const handleSendCommand = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      await axios.post(`${API}/npc/command`, commandForm);
      console.log('Comando enviado com sucesso!');
      await loadNPCs();
    } catch (error) {
      console.error('Erro ao enviar comando:', error);
      alert('Erro ao enviar comando: ' + error.response?.data?.detail);
    } finally {
      setLoading(false);
    }
  };

  const handleClearAllNPCs = async () => {
    if (window.confirm('Tem certeza que deseja remover TODOS os NPCs?')) {
      setLoading(true);
      try {
        const response = await axios.delete(`${API}/npcs/clear`);
        console.log('Todos os NPCs foram removidos!', response.data.message);
        alert(`✅ ${response.data.message}`);
        // Força a atualização de todos os dados
        await Promise.all([loadNPCs(), loadGroups(), loadStats()]);
      } catch (error) {
        console.error('Erro ao limpar NPCs:', error);
        alert('❌ Erro ao limpar NPCs: ' + error.response?.data?.detail);
      } finally {
        setLoading(false);
      }
    }
  };

  const handleDeleteNPC = async (npcId) => {
    if (window.confirm('Tem certeza que deseja remover este NPC?')) {
      try {
        await axios.delete(`${API}/npc/${npcId}`);
        console.log('NPC removido com sucesso!');
        await loadNPCs();
        await loadStats();
      } catch (error) {
        console.error('Erro ao remover NPC:', error);
      }
    }
  };

  const handleDeleteGroup = async (groupId) => {
    if (window.confirm('Tem certeza que deseja remover este grupo?')) {
      try {
        await axios.delete(`${API}/group/${groupId}`);
        console.log('Grupo removido com sucesso!');
        await loadNPCs();
        await loadGroups();
        await loadStats();
      } catch (error) {
        console.error('Erro ao remover grupo:', error);
      }
    }
  };

  const handleGangChange = (gang) => {
    const config = gangConfigs[gang];
    if (config) {
      setSpawnForm(prev => ({
        ...prev,
        gang,
        model: config.models[0],
        weapon: config.weapons[0]
      }));
    }
  };

  return (
    <div className="min-h-screen bg-gray-900 text-white">
      {/* Header */}
      <div className="bg-gray-800 border-b border-gray-700 p-4">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <div className="w-10 h-10 bg-purple-600 rounded-lg flex items-center justify-center">
              <span className="text-xl font-bold">🎮</span>
            </div>
            <div>
              <h1 className="text-2xl font-bold">Gang NPC Manager</h1>
              <p className="text-gray-400">Sistema de Gerenciamento de NPCs para FiveM</p>
            </div>
          </div>
          
          {/* Stats Display */}
          {stats && (
            <div className="flex space-x-6 text-sm">
              <div className="text-center">
                <div className="text-2xl font-bold text-blue-400">{stats.total_npcs}</div>
                <div className="text-gray-400">NPCs Ativos</div>
              </div>
              <div className="text-center">
                <div className="text-2xl font-bold text-green-400">{stats.active_groups}</div>
                <div className="text-gray-400">Grupos</div>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Navigation Tabs */}
      <div className="bg-gray-800 border-b border-gray-700">
        <div className="max-w-7xl mx-auto">
          <nav className="flex space-x-8">
            {[
              { id: 'spawn', name: 'Spawnar NPCs', icon: '➕' },
              { id: 'manage', name: 'Gerenciar NPCs', icon: '⚙️' },
              { id: 'groups', name: 'Grupos', icon: '👥' },
              { id: 'stats', name: 'Estatísticas', icon: '📊' }
            ].map(tab => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`px-6 py-4 border-b-2 font-medium text-sm transition-colors ${
                  activeTab === tab.id
                    ? 'border-purple-500 text-purple-400'
                    : 'border-transparent text-gray-400 hover:text-white hover:border-gray-300'
                }`}
              >
                <span className="mr-2">{tab.icon}</span>
                {tab.name}
              </button>
            ))}
          </nav>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto p-6">
        {/* Spawn Tab */}
        {activeTab === 'spawn' && (
          <div className="space-y-6">
            <div className="bg-gray-800 rounded-lg p-6">
              <h2 className="text-xl font-bold mb-6 flex items-center">
                <span className="mr-2">➕</span>
                Spawnar NPCs
              </h2>
              
              <form onSubmit={handleSpawnNPCs} className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  {/* Gang Selection */}
                  <div>
                    <label className="block text-sm font-medium mb-2">Gangue</label>
                    <div className="grid grid-cols-2 gap-2">
                      {Object.keys(GANG_NAMES).map(gang => (
                        <button
                          key={gang}
                          type="button"
                          onClick={() => handleGangChange(gang)}
                          className={`p-3 rounded-lg border-2 text-sm font-medium transition-all ${
                            spawnForm.gang === gang
                              ? 'border-purple-500 bg-purple-500/20'
                              : 'border-gray-600 hover:border-gray-500'
                          }`}
                          style={{ 
                            backgroundColor: spawnForm.gang === gang ? `${GANG_COLORS[gang]}20` : '',
                            borderColor: spawnForm.gang === gang ? GANG_COLORS[gang] : ''
                          }}
                        >
                          <div 
                            className="w-4 h-4 rounded-full mx-auto mb-1"
                            style={{ backgroundColor: GANG_COLORS[gang] }}
                          ></div>
                          {GANG_NAMES[gang]}
                        </button>
                      ))}
                    </div>
                  </div>

                  {/* Model Selection */}
                  <div>
                    <label className="block text-sm font-medium mb-2">Modelo</label>
                    <select
                      value={spawnForm.model}
                      onChange={(e) => setSpawnForm(prev => ({ ...prev, model: e.target.value }))}
                      className="w-full bg-gray-700 border border-gray-600 rounded-lg px-3 py-2"
                    >
                      {gangConfigs[spawnForm.gang]?.models?.map(model => (
                        <option key={model} value={model}>{model}</option>
                      ))}
                    </select>
                  </div>

                  {/* Quantity */}
                  <div>
                    <label className="block text-sm font-medium mb-2">Quantidade (1-20)</label>
                    <input
                      type="number"
                      min="1"
                      max="20"
                      value={spawnForm.quantity}
                      onChange={(e) => setSpawnForm(prev => ({ ...prev, quantity: parseInt(e.target.value) }))}
                      className="w-full bg-gray-700 border border-gray-600 rounded-lg px-3 py-2"
                    />
                  </div>

                  {/* Formation */}
                  <div>
                    <label className="block text-sm font-medium mb-2">Formação</label>
                    <select
                      value={spawnForm.formation}
                      onChange={(e) => setSpawnForm(prev => ({ ...prev, formation: e.target.value }))}
                      className="w-full bg-gray-700 border border-gray-600 rounded-lg px-3 py-2"
                    >
                      {Object.entries(FORMATIONS).map(([key, name]) => (
                        <option key={key} value={key}>{name}</option>
                      ))}
                    </select>
                  </div>

                  {/* Position */}
                  <div className="md:col-span-2">
                    <label className="block text-sm font-medium mb-2">Posição (X, Y, Z)</label>
                    <div className="grid grid-cols-3 gap-2">
                      <input
                        type="number"
                        placeholder="X"
                        value={spawnForm.position.x}
                        onChange={(e) => setSpawnForm(prev => ({
                          ...prev,
                          position: { ...prev.position, x: parseFloat(e.target.value) || 0 }
                        }))}
                        className="bg-gray-700 border border-gray-600 rounded-lg px-3 py-2"
                      />
                      <input
                        type="number"
                        placeholder="Y"
                        value={spawnForm.position.y}
                        onChange={(e) => setSpawnForm(prev => ({
                          ...prev,
                          position: { ...prev.position, y: parseFloat(e.target.value) || 0 }
                        }))}
                        className="bg-gray-700 border border-gray-600 rounded-lg px-3 py-2"
                      />
                      <input
                        type="number"
                        placeholder="Z"
                        value={spawnForm.position.z}
                        onChange={(e) => setSpawnForm(prev => ({
                          ...prev,
                          position: { ...prev.position, z: parseFloat(e.target.value) || 0 }
                        }))}
                        className="bg-gray-700 border border-gray-600 rounded-lg px-3 py-2"
                      />
                    </div>
                  </div>
                </div>

                <div className="flex justify-between items-center">
                  <button
                    type="button"
                    onClick={() => setSpawnForm({
                      gang: 'ballas',
                      model: gangConfigs.ballas?.models[0] || '',
                      quantity: 1,
                      formation: 'circle',
                      position: { x: 0, y: 0, z: 0 },
                      weapon: gangConfigs.ballas?.weapons[0] || ''
                    })}
                    className="px-4 py-2 bg-gray-600 hover:bg-gray-500 rounded-lg transition-colors"
                  >
                    Limpar Formulário
                  </button>
                  
                  <button
                    type="submit"
                    disabled={loading}
                    className="px-6 py-2 bg-purple-600 hover:bg-purple-500 disabled:bg-gray-600 rounded-lg transition-colors font-medium"
                  >
                    {loading ? 'Spawnando...' : `Spawnar ${spawnForm.quantity} NPC${spawnForm.quantity > 1 ? 's' : ''}`}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* Manage Tab */}
        {activeTab === 'manage' && (
          <div className="space-y-6">
            <div className="bg-gray-800 rounded-lg p-6">
              <div className="flex justify-between items-center mb-6">
                <h2 className="text-xl font-bold flex items-center">
                  <span className="mr-2">⚙️</span>
                  Gerenciar NPCs ({npcs.length})
                </h2>
                <button
                  onClick={handleClearAllNPCs}
                  disabled={loading || npcs.length === 0}
                  className="px-4 py-2 bg-red-600 hover:bg-red-500 disabled:bg-gray-600 rounded-lg transition-colors"
                >
                  Limpar Todos
                </button>
              </div>

              {/* Command Form */}
              <div className="mb-6 p-4 bg-gray-700 rounded-lg">
                <h3 className="text-lg font-medium mb-4">Enviar Comando</h3>
                <form onSubmit={handleSendCommand} className="grid grid-cols-1 md:grid-cols-4 gap-4">
                  <select
                    value={commandForm.npc_id}
                    onChange={(e) => setCommandForm(prev => ({ ...prev, npc_id: e.target.value }))}
                    className="bg-gray-600 border border-gray-500 rounded-lg px-3 py-2"
                  >
                    <option value="">Selecionar NPC</option>
                    {npcs.map(npc => (
                      <option key={npc.id} value={npc.id}>
                        {GANG_NAMES[npc.gang]} - {npc.id.substring(0, 8)}
                      </option>
                    ))}
                  </select>
                  
                  <select
                    value={commandForm.command}
                    onChange={(e) => setCommandForm(prev => ({ ...prev, command: e.target.value }))}
                    className="bg-gray-600 border border-gray-500 rounded-lg px-3 py-2"
                  >
                    {Object.entries(COMMANDS).map(([key, name]) => (
                      <option key={key} value={key}>{name}</option>
                    ))}
                  </select>
                  
                  <button
                    type="submit"
                    disabled={loading || !commandForm.npc_id}
                    className="px-4 py-2 bg-blue-600 hover:bg-blue-500 disabled:bg-gray-600 rounded-lg transition-colors"
                  >
                    Enviar
                  </button>
                </form>
              </div>

              {/* NPCs List */}
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {npcs.map(npc => (
                  <div key={npc.id} className="bg-gray-700 rounded-lg p-4">
                    <div className="flex justify-between items-start mb-3">
                      <div>
                        <div className="flex items-center space-x-2 mb-1">
                          <div 
                            className="w-3 h-3 rounded-full"
                            style={{ backgroundColor: GANG_COLORS[npc.gang] }}
                          ></div>
                          <span className="font-medium">{GANG_NAMES[npc.gang]}</span>
                        </div>
                        <div className="text-sm text-gray-400">ID: {npc.id.substring(0, 8)}</div>
                        <div className="text-sm text-gray-400">Modelo: {npc.model}</div>
                      </div>
                      <button
                        onClick={() => handleDeleteNPC(npc.id)}
                        className="text-red-400 hover:text-red-300 transition-colors"
                        title="Remover NPC"
                      >
                        🗑️
                      </button>
                    </div>
                    
                    <div className="space-y-2 text-sm">
                      <div className="flex justify-between">
                        <span>Estado:</span>
                        <span className={`font-medium ${
                          npc.state === 'idle' ? 'text-gray-400' :
                          npc.state === 'following' ? 'text-blue-400' :
                          npc.state === 'attacking' ? 'text-red-400' :
                          'text-green-400'
                        }`}>
                          {npc.state.toUpperCase()}
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span>Vida:</span>
                        <span className="text-green-400">{npc.health}%</span>
                      </div>
                      <div className="flex justify-between">
                        <span>Arma:</span>
                        <span className="text-yellow-400">{npc.weapon || 'Nenhuma'}</span>
                      </div>
                      {npc.group_id && (
                        <div className="flex justify-between">
                          <span>Grupo:</span>
                          <span className="text-purple-400">{npc.group_id.substring(0, 8)}</span>
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>

              {npcs.length === 0 && (
                <div className="text-center py-12 text-gray-400">
                  <div className="text-4xl mb-4">🚫</div>
                  <p className="text-lg">Nenhum NPC ativo</p>
                  <p className="text-sm">Use a aba "Spawnar NPCs" para criar novos NPCs</p>
                </div>
              )}
            </div>
          </div>
        )}

        {/* Groups Tab */}
        {activeTab === 'groups' && (
          <div className="space-y-6">
            <div className="bg-gray-800 rounded-lg p-6">
              <h2 className="text-xl font-bold mb-6 flex items-center">
                <span className="mr-2">👥</span>
                Grupos Ativos ({groups.length})
              </h2>

              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {groups.map(group => (
                  <div key={group._id} className="bg-gray-700 rounded-lg p-4">
                    <div className="flex justify-between items-start mb-3">
                      <div>
                        <div className="flex items-center space-x-2 mb-1">
                          <div 
                            className="w-3 h-3 rounded-full"
                            style={{ backgroundColor: GANG_COLORS[group.gang] }}
                          ></div>
                          <span className="font-medium">{GANG_NAMES[group.gang]}</span>
                        </div>
                        <div className="text-sm text-gray-400">ID: {group._id.substring(0, 8)}</div>
                      </div>
                      <button
                        onClick={() => handleDeleteGroup(group._id)}
                        className="text-red-400 hover:text-red-300 transition-colors"
                        title="Remover Grupo"
                      >
                        🗑️
                      </button>
                    </div>
                    
                    <div className="space-y-2 text-sm">
                      <div className="flex justify-between">
                        <span>NPCs:</span>
                        <span className="font-medium text-blue-400">{group.count}</span>
                      </div>
                      <div className="flex justify-between">
                        <span>Criado:</span>
                        <span className="text-gray-400">
                          {new Date(group.created_at).toLocaleTimeString('pt-BR')}
                        </span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>

              {groups.length === 0 && (
                <div className="text-center py-12 text-gray-400">
                  <div className="text-4xl mb-4">👥</div>
                  <p className="text-lg">Nenhum grupo ativo</p>
                  <p className="text-sm">Spawne múltiplos NPCs para criar grupos</p>
                </div>
              )}
            </div>
          </div>
        )}

        {/* Stats Tab */}
        {activeTab === 'stats' && stats && (
          <div className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
              <div className="bg-gray-800 rounded-lg p-6">
                <div className="flex items-center">
                  <div className="p-3 bg-blue-500 rounded-lg">
                    <span className="text-2xl">👤</span>
                  </div>
                  <div className="ml-4">
                    <p className="text-sm text-gray-400">NPCs Ativos</p>
                    <p className="text-2xl font-bold">{stats.total_npcs}</p>
                  </div>
                </div>
              </div>

              <div className="bg-gray-800 rounded-lg p-6">
                <div className="flex items-center">
                  <div className="p-3 bg-green-500 rounded-lg">
                    <span className="text-2xl">👥</span>
                  </div>
                  <div className="ml-4">
                    <p className="text-sm text-gray-400">Grupos</p>
                    <p className="text-2xl font-bold">{stats.active_groups}</p>
                  </div>
                </div>
              </div>

              <div className="bg-gray-800 rounded-lg p-6">
                <div className="flex items-center">
                  <div className="p-3 bg-purple-500 rounded-lg">
                    <span className="text-2xl">🎯</span>
                  </div>
                  <div className="ml-4">
                    <p className="text-sm text-gray-400">Gangues Ativas</p>
                    <p className="text-2xl font-bold">{Object.keys(stats.gang_distribution).length}</p>
                  </div>
                </div>
              </div>

              <div className="bg-gray-800 rounded-lg p-6">
                <div className="flex items-center">
                  <div className="p-3 bg-yellow-500 rounded-lg">
                    <span className="text-2xl">⚡</span>
                  </div>
                  <div className="ml-4">
                    <p className="text-sm text-gray-400">Status</p>
                    <p className="text-lg font-bold text-green-400">Online</p>
                  </div>
                </div>
              </div>
            </div>

            {/* Gang Distribution */}
            <div className="bg-gray-800 rounded-lg p-6">
              <h3 className="text-lg font-bold mb-4">Distribuição por Gangue</h3>
              <div className="space-y-3">
                {Object.entries(stats.gang_distribution).map(([gang, count]) => (
                  <div key={gang} className="flex items-center justify-between">
                    <div className="flex items-center space-x-3">
                      <div 
                        className="w-4 h-4 rounded-full"
                        style={{ backgroundColor: GANG_COLORS[gang] }}
                      ></div>
                      <span>{GANG_NAMES[gang]}</span>
                    </div>
                    <div className="flex items-center space-x-2">
                      <div className="w-32 bg-gray-700 rounded-full h-2">
                        <div 
                          className="h-2 rounded-full"
                          style={{ 
                            backgroundColor: GANG_COLORS[gang],
                            width: `${(count / stats.total_npcs) * 100}%`
                          }}
                        ></div>
                      </div>
                      <span className="text-sm font-medium w-8 text-right">{count}</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

export default App;
