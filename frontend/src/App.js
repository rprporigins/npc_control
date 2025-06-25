import React, { useEffect, useRef, useState } from 'react';
import './App.css';

const GAME_CONFIG = {
  width: 1400, // Tela maior
  height: 900, // Tela maior
  gravity: 0.4, // Gravidade balanceada
  jumpPower: -10, // Pulo um pouco mais alto
  flyPower: -0.4, // Voo muito limitado
  playerSpeed: 5,
  fireRate: 250, // Tiro um pouco mais rápido
  xpPerLevel: 100,
  enemySpawnRate: 1200, // Spawn mais rápido
  obstacleSpawnRate: 8000, // Obstáculos mais frequentes
  maxFlyHeight: 200, // Altura máxima de voo
};

// Sistema de partículas avançado com diferentes comportamentos
class ParticleSystem {
  constructor() {
    this.particles = [];
  }

  emit(x, y, options = {}) {
    const defaults = {
      count: 10,
      speed: 5,
      spread: Math.PI * 2,
      lifespan: 60,
      colors: ['#ffffff'],
      size: { min: 2, max: 4 },
      gravity: 0.1,
      fadeOut: true,
      shape: 'circle', // circle, square, star
      behavior: 'normal' // normal, fire, smoke, explosion, magic
    };

    const config = { ...defaults, ...options };

    for (let i = 0; i < config.count; i++) {
      const angle = config.spread === Math.PI * 2 
        ? Math.random() * Math.PI * 2 
        : -config.spread/2 + Math.random() * config.spread;
      
      const speed = config.speed * (0.5 + Math.random() * 0.5);
      const size = config.size.min + Math.random() * (config.size.max - config.size.min);
      const color = config.colors[Math.floor(Math.random() * config.colors.length)];

      const particle = {
        x,
        y,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
        size,
        baseSize: size,
        color,
        life: config.lifespan,
        maxLife: config.lifespan,
        gravity: config.gravity,
        fadeOut: config.fadeOut,
        shape: config.shape,
        behavior: config.behavior,
        rotation: Math.random() * Math.PI * 2,
        rotationSpeed: (Math.random() - 0.5) * 0.2
      };

      // Comportamentos especiais
      switch (config.behavior) {
        case 'fire':
          particle.vy = -Math.abs(particle.vy) - 2; // Sempre sobe
          particle.vx *= 0.5;
          particle.gravity = -0.05; // Sobe mais
          break;
        case 'smoke':
          particle.vy = -Math.abs(particle.vy) * 0.3;
          particle.size *= 2;
          particle.fadeOut = true;
          break;
        case 'explosion':
          particle.vx *= 2;
          particle.vy *= 2;
          particle.gravity = 0.3;
          break;
        case 'magic':
          particle.oscillate = Math.random() * Math.PI * 2;
          particle.oscillateSpeed = 0.1 + Math.random() * 0.1;
          break;
      }

      this.particles.push(particle);
    }
  }

  update() {
    this.particles = this.particles.filter(particle => {
      // Física básica
      particle.vx *= 0.98; // Fricção
      particle.vy += particle.gravity;
      particle.x += particle.vx;
      particle.y += particle.vy;
      particle.life--;
      particle.rotation += particle.rotationSpeed;

      // Comportamentos específicos
      switch (particle.behavior) {
        case 'fire':
          particle.vx += (Math.random() - 0.5) * 0.5;
          particle.size = particle.baseSize * (particle.life / particle.maxLife);
          break;
        case 'smoke':
          particle.size += 0.1;
          particle.vx += (Math.random() - 0.5) * 0.2;
          break;
        case 'magic':
          particle.oscillate += particle.oscillateSpeed;
          particle.x += Math.sin(particle.oscillate) * 0.5;
          particle.y += Math.cos(particle.oscillate) * 0.3;
          break;
      }

      return particle.life > 0;
    });
  }

  render(ctx) {
    this.particles.forEach(particle => {
      ctx.save();
      
      // Calcular alpha para fade out
      let alpha = 1;
      if (particle.fadeOut) {
        alpha = particle.life / particle.maxLife;
      }
      
      // Aplicar cor com alpha
      const color = this.hexToRgba(particle.color, alpha);
      ctx.fillStyle = color;
      ctx.strokeStyle = color;
      
      // Posicionar e rotacionar
      ctx.translate(particle.x, particle.y);
      ctx.rotate(particle.rotation);
      
      // Desenhar forma
      switch (particle.shape) {
        case 'circle':
          ctx.beginPath();
          ctx.arc(0, 0, particle.size, 0, Math.PI * 2);
          ctx.fill();
          break;
        case 'square':
          ctx.fillRect(-particle.size/2, -particle.size/2, particle.size, particle.size);
          break;
        case 'star':
          this.drawStar(ctx, 0, 0, 5, particle.size, particle.size/2);
          break;
      }
      
      // Efeito de brilho para partículas mágicas
      if (particle.behavior === 'magic' || particle.behavior === 'fire') {
        ctx.shadowBlur = particle.size * 2;
        ctx.shadowColor = particle.color;
        ctx.fill();
        ctx.shadowBlur = 0;
      }
      
      ctx.restore();
    });
  }

  drawStar(ctx, cx, cy, spikes, outerRadius, innerRadius) {
    let rot = Math.PI / 2 * 3;
    let x = cx;
    let y = cy;
    const step = Math.PI / spikes;

    ctx.beginPath();
    ctx.moveTo(cx, cy - outerRadius);
    
    for (let i = 0; i < spikes; i++) {
      x = cx + Math.cos(rot) * outerRadius;
      y = cy + Math.sin(rot) * outerRadius;
      ctx.lineTo(x, y);
      rot += step;

      x = cx + Math.cos(rot) * innerRadius;
      y = cy + Math.sin(rot) * innerRadius;
      ctx.lineTo(x, y);
      rot += step;
    }
    
    ctx.lineTo(cx, cy - outerRadius);
    ctx.closePath();
    ctx.fill();
  }

  hexToRgba(hex, alpha) {
    const r = parseInt(hex.slice(1, 3), 16);
    const g = parseInt(hex.slice(3, 5), 16);
    const b = parseInt(hex.slice(5, 7), 16);
    return `rgba(${r}, ${g}, ${b}, ${alpha})`;
  }
}

// Sistema de ondas progressivas
class WaveManager {
  constructor() {
    this.currentWave = 0;
    this.enemiesInWave = 0;
    this.enemiesSpawned = 0;
    this.enemiesKilled = 0;
    this.waveActive = false;
    this.waveStartTime = 0;
    this.intermissionTime = 5000; // 5 segundos entre ondas
    this.nextWaveTime = 0;
    this.bossWave = false;
  }

  getWaveConfig(waveNumber) {
    const baseEnemies = 5;
    const isBossWave = waveNumber % 5 === 0;
    
    return {
      enemyCount: isBossWave ? 1 : baseEnemies + (waveNumber * 2),
      enemyTypes: this.getEnemyTypesForWave(waveNumber),
      spawnRate: Math.max(800, 2500 - (waveNumber * 100)), // Spawn mais lento
      enemyHealthMultiplier: 1 + (waveNumber * 0.2),
      enemySpeedMultiplier: 1 + (waveNumber * 0.1),
      enemyDamageMultiplier: 1 + (waveNumber * 0.15),
      isBossWave,
      rewards: {
        xp: 50 * waveNumber,
        score: 100 * waveNumber,
        health: isBossWave ? 50 : 10
      }
    };
  }

  getEnemyTypesForWave(waveNumber) {
    const types = ['basic'];
    
    if (waveNumber >= 3) types.push('zigzag');
    if (waveNumber >= 5) types.push('shooter');
    if (waveNumber >= 8) types.push('tank');
    if (waveNumber >= 10) types.push('teleporter');
    
    // Boss waves
    if (waveNumber % 5 === 0) {
      return ['boss'];
    }
    
    return types;
  }

  startNextWave() {
    this.currentWave++;
    const config = this.getWaveConfig(this.currentWave);
    
    this.enemiesInWave = config.enemyCount;
    this.enemiesSpawned = 0;
    this.enemiesKilled = 0;
    this.waveActive = true;
    this.bossWave = config.isBossWave;
    this.waveStartTime = Date.now();
    
    return config;
  }

  canSpawnEnemy(currentTime) {
    if (!this.waveActive) return false;
    if (this.enemiesSpawned >= this.enemiesInWave) return false;
    
    const config = this.getWaveConfig(this.currentWave);
    const timeSinceStart = currentTime - this.waveStartTime;
    const expectedSpawns = Math.floor(timeSinceStart / config.spawnRate);
    
    return expectedSpawns > this.enemiesSpawned;
  }

  spawnEnemy(gameState) {
    if (!this.canSpawnEnemy(Date.now())) return null;
    
    const config = this.getWaveConfig(this.currentWave);
    const types = config.enemyTypes;
    const type = types[Math.floor(Math.random() * types.length)];
    
    this.enemiesSpawned++;
    
    return this.createEnemyOfType(type, config);
  }

  createEnemyOfType(type, waveConfig) {
    const baseStats = {
      basic: { hp: 30, speed: 1.5, damage: 10, size: 1, emoji: '👹', color: '#22c55e' },
      zigzag: { hp: 40, speed: 2, damage: 15, size: 1, emoji: '🐍', color: '#3b82f6' },
      tank: { hp: 100, speed: 0.8, damage: 30, size: 1.5, emoji: '🛡️', color: '#6b7280' },
      shooter: { hp: 50, speed: 1.2, damage: 20, size: 1, emoji: '🏹', color: '#f97316' },
      teleporter: { hp: 60, speed: 2.5, damage: 25, size: 1, emoji: '👻', color: '#a855f7' },
      boss: { hp: 500, speed: 0.5, damage: 50, size: 2.5, emoji: '🐲', color: '#dc2626' }
    };
    
    const stats = baseStats[type];
    const x = type === 'boss' 
      ? GAME_CONFIG.width / 2 - 50 
      : Math.random() * (GAME_CONFIG.width - 60);
    
    return {
      x,
      y: -60 * stats.size,
      width: 40 * stats.size,
      height: 40 * stats.size,
      speed: stats.speed * waveConfig.enemySpeedMultiplier,
      hp: stats.hp * waveConfig.enemyHealthMultiplier,
      maxHp: stats.hp * waveConfig.enemyHealthMultiplier,
      damage: stats.damage * waveConfig.enemyDamageMultiplier,
      color: stats.color,
      emoji: stats.emoji,
      type,
      behavior: type,
      // Propriedades específicas
      shootCooldown: type === 'shooter' || type === 'boss' ? 1500 : 0,
      lastShot: 0,
      teleportCooldown: type === 'teleporter' ? 3000 : 0,
      lastTeleport: 0,
      zigzagPhase: 0,
      pursuitRange: 300, // Alcance de perseguição
      attackRange: 200    // Alcance de ataque
    };
  }

  onEnemyKilled(enemy) {
    this.enemiesKilled++;
    
    if (this.enemiesKilled >= this.enemiesInWave) {
      this.completeWave();
    }
  }

  completeWave() {
    this.waveActive = false;
    this.nextWaveTime = Date.now() + this.intermissionTime;
    
    const config = this.getWaveConfig(this.currentWave);
    return config.rewards;
  }

  update(currentTime) {
    if (!this.waveActive && currentTime >= this.nextWaveTime && this.currentWave >= 0) {
      return { startNewWave: true };
    }
    return { startNewWave: false };
  }

  getWaveStatus() {
    return {
      wave: this.currentWave,
      active: this.waveActive,
      enemiesRemaining: this.enemiesInWave - this.enemiesKilled,
      totalEnemies: this.enemiesInWave,
      isBossWave: this.bossWave,
      timeToNextWave: this.waveActive ? 0 : Math.max(0, this.nextWaveTime - Date.now())
    };
  }
}

const POWER_UPS = {
  // OFENSIVOS
  common_offensive: [
    { id: 'residual_flame', name: 'Chama Residual', desc: 'Inimigos queimam por 2s ao serem atingidos', rarity: 'common' },
    { id: 'arcane_thorns', name: 'Espinhos Arcanos', desc: 'Acertos lançam pequenos estilhaços mágicos aleatórios', rarity: 'common' },
    { id: 'projectile_speed', name: 'Velocidade de Projétil +10%', desc: 'Magias viajam mais rápido', rarity: 'common' },
    { id: 'magic_damage', name: '+5% Dano Mágico', desc: 'Aumenta dano base', rarity: 'common' },
  ],
  uncommon_offensive: [
    { id: 'double_shot', name: 'Projétil Duplo (10%)', desc: '10% de chance de lançar um segundo projétil', rarity: 'uncommon' },
    { id: 'fire_rate_1', name: 'Cadência Acelerada I', desc: 'Reduz tempo entre disparos em 5%', rarity: 'uncommon' },
    { id: 'pierce_1', name: 'Perfuração I', desc: 'Magias atravessam 1 inimigo', rarity: 'uncommon' },
    { id: 'area_damage', name: 'Área de Dano +10%', desc: 'Aumenta área de explosão', rarity: 'uncommon' },
  ],
  rare_offensive: [
    { id: 'explosion_contact', name: 'Explosão de Contato', desc: 'Inimigos explodem ao morrer (dano em área)', rarity: 'rare' },
    { id: 'chain_lightning', name: 'Cadeia Elétrica', desc: 'Magias saltam para até 2 inimigos próximos', rarity: 'rare' },
    { id: 'homing_missiles', name: 'Mísseis Etéreos', desc: '15% de chance de lançar projéteis que perseguem', rarity: 'rare' },
    { id: 'fire_trail', name: 'Vazamento de Fogo', desc: 'Magias deixam rastro em chamas', rarity: 'rare' },
  ],
  epic_offensive: [
    { id: 'arcane_rain', name: 'Chuva Arcana', desc: 'Chance de disparar uma rajada de 5 magias em cone', rarity: 'epic' },
    { id: 'fire_rate_2', name: 'Cadência Acelerada II', desc: 'Reduz tempo entre disparos em 10%', rarity: 'epic' },
    { id: 'pierce_2', name: 'Perfuração II', desc: 'Magias atravessam 2 inimigos', rarity: 'epic' },
    { id: 'triple_shot', name: 'Projétil Triplo (5%)', desc: '5% chance de triplo disparo', rarity: 'epic' },
  ],
  legendary_offensive: [
    { id: 'apocalyptic_orb', name: 'Orbe Apocalíptico', desc: 'Projéteis grandes explodem em múltiplos mini-orbes', rarity: 'legendary' },
    { id: 'infinite_burst', name: 'Rajada Infinita', desc: 'Projéteis disparam em ondas contínuas por 2s a cada 20s', rarity: 'legendary' },
    { id: 'living_magic', name: 'Magia Viva', desc: 'Seus tiros se curvam automaticamente até atingir um alvo', rarity: 'legendary' },
    { id: 'stellar_pulse', name: 'Pulso Estelar', desc: 'A cada 20 projéteis, um é extremamente poderoso (+500% dano)', rarity: 'legendary' },
  ],
  // DEFENSIVOS
  common_defensive: [
    { id: 'max_hp_10', name: '+10 Vida Máxima', desc: 'Aumenta vida máxima', rarity: 'common' },
    { id: 'move_speed_5', name: '+5% Velocidade de Movimento', desc: 'Move mais rápido', rarity: 'common' },
    { id: 'hp_regen', name: 'Recuperação de 1 Vida a cada 10s', desc: 'Regeneração passiva', rarity: 'common' },
    { id: 'temp_barrier', name: 'Barreira Temporária (5%)', desc: 'Chance de bloquear dano', rarity: 'common' },
  ],
  uncommon_defensive: [
    { id: 'repulsor_field', name: 'Campo Repulsor', desc: 'Empurra inimigos ao chegar perto', rarity: 'uncommon' },
    { id: 'elemental_resist', name: '+15% Resistência a dano elemental', desc: 'Reduz dano elemental', rarity: 'uncommon' },
    { id: 'mirror_shield', name: 'Escudo Espelhado', desc: 'Reflete 1 projétil a cada 8s', rarity: 'uncommon' },
    { id: 'heal_on_kill', name: 'Cura ao Matar', desc: 'Recupera 1 de vida a cada 10 inimigos mortos', rarity: 'uncommon' },
  ],
  rare_defensive: [
    { id: 'max_hp_30', name: '+30 Vida Máxima', desc: 'Grande aumento de vida', rarity: 'rare' },
    { id: 'ghost_steps', name: 'Passos Fantasmas', desc: 'Atravessa inimigos sem colidir', rarity: 'rare' },
    { id: 'ethereal_armor', name: 'Armadura Etérea', desc: 'Reduz 20% do dano recebido', rarity: 'rare' },
    { id: 'active_barrier', name: 'Barreira Ativa', desc: 'Ganha escudo a cada 30 inimigos mortos', rarity: 'rare' },
  ],
  epic_defensive: [
    { id: 'brief_immortality', name: 'Imortalidade Breve', desc: 'Fica invulnerável por 2s ao chegar a 1 de vida (60s de recarga)', rarity: 'epic' },
    { id: 'slowness_aura', name: 'Aura de Lentidão', desc: 'Inimigos próximos têm movimento reduzido', rarity: 'epic' },
    { id: 'combat_heal', name: 'Cura de Combate', desc: 'Cura 3 de vida a cada elite derrotado', rarity: 'epic' },
    { id: 'dematerialize', name: 'Desmaterializar', desc: '5% de chance de ignorar completamente o dano', rarity: 'epic' },
  ],
  legendary_defensive: [
    { id: 'eternal_regen', name: 'Regeneração Eterna', desc: 'Recupera 1 de vida por segundo', rarity: 'legendary' },
    { id: 'temporal_domain', name: 'Domínio Temporal', desc: 'Inimigos desaceleram conforme se aproximam', rarity: 'legendary' },
    { id: 'total_reflection', name: 'Reflexão Total', desc: 'Projéteis inimigos têm 25% de chance de retornar ao lançador', rarity: 'legendary' },
    { id: 'resurgence', name: 'Ressurgência', desc: 'Ressuscita uma vez por run com 50% de vida', rarity: 'legendary' },
  ],
  // UTILITÁRIOS
  common_utility: [
    { id: 'exp_gain_10', name: '+10% Coleta de Exp', desc: 'Mais experiência por kill', rarity: 'common' },
    { id: 'levelup_speed_5', name: '+5% Velocidade de Level Up', desc: 'Level up mais rápido', rarity: 'common' },
    { id: 'move_speed_util_5', name: '+5% Velocidade de Movimento', desc: 'Movimento mais rápido', rarity: 'common' },
    { id: 'pickup_radius', name: '+5% Raio de Coleta de Itens', desc: 'Coleta itens de mais longe', rarity: 'common' },
  ],
  uncommon_utility: [
    { id: 'mystic_attraction', name: 'Atração Mística', desc: 'Itens de experiência voam até você', rarity: 'uncommon' },
    { id: 'exp_gain_15', name: '+15% Coleta de Exp', desc: 'Mais experiência por kill', rarity: 'uncommon' },
    { id: 'global_time', name: 'Tempo de Aumento Global', desc: 'Efeitos temporários duram 25% mais', rarity: 'uncommon' },
    { id: 'arcane_concentration_1', name: 'Concentração Arcana I', desc: '+5% chance de receber power-up raro', rarity: 'uncommon' },
  ],
};

const RARITY_COLORS = {
  common: '#22c55e',
  uncommon: '#3b82f6',
  rare: '#a855f7',
  epic: '#f97316',
  legendary: '#eab308'
};

function App() {
  const canvasRef = useRef(null);
  const gameStateRef = useRef({
    player: {
      x: GAME_CONFIG.width / 2,
      y: GAME_CONFIG.height - 150,
      vx: 0,
      vy: 0,
      width: 40,
      height: 40,
      hp: 100,
      maxHp: 100,
      grounded: false,
      canJump: true,
      damage: 25,
      fireRate: GAME_CONFIG.fireRate,
      lastShot: 0,
      emoji: '🧙‍♂️'
    },
    bullets: [],
    enemies: [],
    enemyBullets: [],
    obstacles: [],
    explosions: [],
    particles: [],
    particleSystem: new ParticleSystem(),
    waveManager: new WaveManager(),
    screenShake: {
      intensity: 0,
      duration: 0,
      offsetX: 0,
      offsetY: 0
    },
    mouse: { x: 0, y: 0 },
    keys: {},
    gameStarted: false,
    gamePaused: false,
    gameOver: false,
    level: 1,
    xp: 0,
    xpToNext: GAME_CONFIG.xpPerLevel,
    score: 0,
    lastEnemySpawn: 0,
    lastObstacleSpawn: 0,
    powerUps: [],
    showPowerUpSelection: false,
    availablePowerUps: [],
    playerPowerUps: [],
    kills: 0,
    difficulty: 1,
  });

  const [gameStarted, setGameStarted] = useState(false);
  const [showPowerUpSelection, setShowPowerUpSelection] = useState(false);
  const [availablePowerUps, setAvailablePowerUps] = useState([]);
  const [gameStats, setGameStats] = useState({
    level: 1,
    xp: 0,
    xpToNext: GAME_CONFIG.xpPerLevel,
    hp: 100,
    maxHp: 100,
    score: 0,
    kills: 0,
  });
  const [waveStatus, setWaveStatus] = useState({
    wave: 0,
    active: false,
    enemiesRemaining: 0,
    totalEnemies: 0,
    isBossWave: false,
    timeToNextWave: 0
  });

  // Função para ativar screen shake
  const triggerScreenShake = (intensity = 10, duration = 300) => {
    const state = gameStateRef.current;
    state.screenShake.intensity = intensity;
    state.screenShake.duration = duration;
  };

  // Implementação dos comportamentos dos inimigos MELHORADA
  const updateEnemyBehavior = (enemy, player, gameState) => {
    const now = Date.now();
    
    // Calcular distância para o jogador
    const dx = player.x - enemy.x;
    const dy = player.y - enemy.y;
    const distanceToPlayer = Math.sqrt(dx * dx + dy * dy);
    
    // Perseguir jogador se estiver no alcance
    if (distanceToPlayer < enemy.pursuitRange && enemy.type !== 'boss') {
      const moveX = (dx / distanceToPlayer) * enemy.speed * 0.3;
      enemy.x += moveX;
    }
    
    switch (enemy.behavior) {
      case 'basic':
        enemy.y += enemy.speed;
        // Perseguir jogador horizontalmente
        if (distanceToPlayer < enemy.pursuitRange) {
          enemy.x += (dx / distanceToPlayer) * enemy.speed * 0.5;
        }
        break;
        
      case 'zigzag':
        enemy.y += enemy.speed;
        enemy.zigzagPhase += 0.15;
        enemy.x += Math.sin(enemy.zigzagPhase) * 3;
        // Perseguir jogador
        if (distanceToPlayer < enemy.pursuitRange) {
          enemy.x += (dx / distanceToPlayer) * enemy.speed * 0.3;
        }
        break;
        
      case 'tank':
        enemy.y += enemy.speed;
        // Tank persegue mais agressivamente
        if (distanceToPlayer < enemy.pursuitRange) {
          enemy.x += (dx / distanceToPlayer) * enemy.speed * 0.7;
        }
        break;
        
      case 'shooter':
        enemy.y += enemy.speed * 0.6; // Move mais devagar
        
        // Perseguir e atirar no jogador
        if (distanceToPlayer < enemy.pursuitRange) {
          enemy.x += (dx / distanceToPlayer) * enemy.speed * 0.2;
        }
        
        if (now - enemy.lastShot > enemy.shootCooldown && distanceToPlayer < enemy.attackRange) {
          const bulletSpeed = 5;
          gameState.enemyBullets.push({
            x: enemy.x + enemy.width / 2,
            y: enemy.y + enemy.height,
            vx: (dx / distanceToPlayer) * bulletSpeed,
            vy: (dy / distanceToPlayer) * bulletSpeed,
            width: 8,
            height: 8,
            damage: enemy.damage * 0.7,
            color: '#ff6600',
            emoji: '🔥'
          });
          enemy.lastShot = now;
        }
        break;
        
      case 'teleporter':
        enemy.y += enemy.speed;
        
        // Perseguir agressivamente
        if (distanceToPlayer < enemy.pursuitRange) {
          enemy.x += (dx / distanceToPlayer) * enemy.speed * 0.8;
        }
        
        // Teleportar ocasionalmente
        if (now - enemy.lastTeleport > enemy.teleportCooldown) {
          // Efeito de teleporte
          gameState.particleSystem.emit(enemy.x + enemy.width/2, enemy.y + enemy.height/2, {
            count: 20,
            colors: ['#a855f7', '#ffffff'],
            size: { min: 2, max: 8 },
            speed: 6,
            lifespan: 30,
            behavior: 'magic'
          });
          
          // Teleportar próximo ao jogador
          const teleportDistance = 100 + Math.random() * 100;
          const teleportAngle = Math.random() * Math.PI * 2;
          enemy.x = player.x + Math.cos(teleportAngle) * teleportDistance;
          enemy.y = player.y + Math.sin(teleportAngle) * teleportDistance;
          
          // Manter dentro dos limites
          enemy.x = Math.max(0, Math.min(GAME_CONFIG.width - enemy.width, enemy.x));
          enemy.y = Math.max(0, Math.min(GAME_CONFIG.height - enemy.height, enemy.y));
          
          enemy.lastTeleport = now;
          
          // Efeito de chegada
          gameState.particleSystem.emit(enemy.x + enemy.width/2, enemy.y + enemy.height/2, {
            count: 20,
            colors: ['#a855f7', '#ffffff'],
            size: { min: 2, max: 8 },
            speed: 6,
            lifespan: 30,
            behavior: 'magic'
          });
        }
        break;
        
      case 'boss':
        // Movimento do boss - fica na parte superior
        enemy.y = Math.min(enemy.y + enemy.speed, 150);
        
        // Boss se move horizontalmente seguindo o jogador
        if (enemy.x < player.x - 50) {
          enemy.x += enemy.speed * 2;
        } else if (enemy.x > player.x + 50) {
          enemy.x -= enemy.speed * 2;
        }
        
        // Padrões de ataque do boss baseados na vida
        const healthPercent = enemy.hp / enemy.maxHp;
        let shootInterval = 1200;
        
        if (healthPercent < 0.33) {
          shootInterval = 400; // Fase final - muito rápido
        } else if (healthPercent < 0.66) {
          shootInterval = 700; // Fase intermediária
        }
        
        if (now - enemy.lastShot > shootInterval) {
          if (healthPercent > 0.66) {
            // Fase 1: Tiros em spread
            for (let i = -2; i <= 2; i++) {
              gameState.enemyBullets.push({
                x: enemy.x + enemy.width / 2,
                y: enemy.y + enemy.height,
                vx: i * 3,
                vy: 6,
                width: 12,
                height: 12,
                damage: enemy.damage * 0.4,
                color: '#dc2626',
                emoji: '💀'
              });
            }
          } else if (healthPercent > 0.33) {
            // Fase 2: Tiros direcionados
            const bulletSpeed = 7;
            gameState.enemyBullets.push({
              x: enemy.x + enemy.width / 2,
              y: enemy.y + enemy.height,
              vx: (dx / distanceToPlayer) * bulletSpeed,
              vy: (dy / distanceToPlayer) * bulletSpeed,
              width: 15,
              height: 15,
              damage: enemy.damage * 0.6,
              color: '#dc2626',
              emoji: '🔥'
            });
          } else {
            // Fase 3: Caos total - espiral + direcionado
            const angle = (now * 0.008) % (Math.PI * 2);
            for (let i = 0; i < 6; i++) {
              const a = angle + (i * Math.PI / 3);
              gameState.enemyBullets.push({
                x: enemy.x + enemy.width / 2,
                y: enemy.y + enemy.height / 2,
                vx: Math.cos(a) * 6,
                vy: Math.sin(a) * 6,
                width: 10,
                height: 10,
                damage: enemy.damage * 0.5,
                color: '#dc2626',
                emoji: '⚡'
              });
            }
          }
          enemy.lastShot = now;
        }
        break;
    }
    
    // Manter inimigos dentro dos limites
    enemy.x = Math.max(0, Math.min(GAME_CONFIG.width - enemy.width, enemy.x));
  };

  const updateScreenShake = (state) => {
    if (state.screenShake.duration > 0) {
      state.screenShake.duration -= 16; // Assumindo 60 FPS
      const factor = state.screenShake.duration / 300; // Normalizar
      const intensity = state.screenShake.intensity * factor;
      
      state.screenShake.offsetX = (Math.random() - 0.5) * intensity;
      state.screenShake.offsetY = (Math.random() - 0.5) * intensity;
    } else {
      state.screenShake.offsetX = 0;
      state.screenShake.offsetY = 0;
    }
  };

  // Game initialization
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    ctx.imageSmoothingEnabled = false; // Pixel art style

    // Event listeners
    const handleKeyDown = (e) => {
      gameStateRef.current.keys[e.key.toLowerCase()] = true;
      if (e.key === ' ') {
        e.preventDefault();
      }
    };

    const handleKeyUp = (e) => {
      gameStateRef.current.keys[e.key.toLowerCase()] = false;
    };

    const handleMouseMove = (e) => {
      const rect = canvas.getBoundingClientRect();
      gameStateRef.current.mouse.x = e.clientX - rect.left;
      gameStateRef.current.mouse.y = e.clientY - rect.top;
    };

    const handleClick = () => {
      if (!gameStateRef.current.gameStarted) {
        startGame();
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    window.addEventListener('keyup', handleKeyUp);
    canvas.addEventListener('mousemove', handleMouseMove);
    canvas.addEventListener('click', handleClick);

    return () => {
      window.removeEventListener('keydown', handleKeyDown);
      window.removeEventListener('keyup', handleKeyUp);
      canvas.removeEventListener('mousemove', handleMouseMove);
      canvas.removeEventListener('click', handleClick);
    };
  }, []);

  const startGame = () => {
    gameStateRef.current.gameStarted = true;
    gameStateRef.current.gameOver = false;
    gameStateRef.current.gamePaused = false;
    
    // Iniciar primeira onda
    const waveConfig = gameStateRef.current.waveManager.startNextWave();
    
    setGameStarted(true);
    gameLoop();
  };

  const resetGame = () => {
    const state = gameStateRef.current;
    state.player = {
      x: GAME_CONFIG.width / 2,
      y: GAME_CONFIG.height - 150,
      vx: 0,
      vy: 0,
      width: 40,
      height: 40,
      hp: 100,
      maxHp: 100,
      grounded: false,
      canJump: true,
      damage: 25,
      fireRate: GAME_CONFIG.fireRate,
      lastShot: 0,
      emoji: '🧙‍♂️'
    };
    state.bullets = [];
    state.enemies = [];
    state.enemyBullets = [];
    state.obstacles = [];
    state.explosions = [];
    state.particles = [];
    state.particleSystem = new ParticleSystem();
    state.waveManager = new WaveManager();
    state.screenShake = { intensity: 0, duration: 0, offsetX: 0, offsetY: 0 };
    state.level = 1;
    state.xp = 0;
    state.xpToNext = GAME_CONFIG.xpPerLevel;
    state.score = 0;
    state.kills = 0;
    state.difficulty = 1;
    state.playerPowerUps = [];
    setGameStats({
      level: 1,
      xp: 0,
      xpToNext: GAME_CONFIG.xpPerLevel,
      hp: 100,
      maxHp: 100,
      score: 0,
      kills: 0,
    });
  };

  const gameLoop = () => {
    const state = gameStateRef.current;
    if (!state.gameStarted || state.gameOver) return;

    if (!state.gamePaused && !state.showPowerUpSelection) {
      updateGame();
    }
    renderGame();
    requestAnimationFrame(gameLoop);
  };

  const updateGame = () => {
    const state = gameStateRef.current;
    const now = Date.now();

    // Update screen shake
    updateScreenShake(state);

    // Update wave manager
    const waveUpdate = state.waveManager.update(now);
    if (waveUpdate.startNewWave) {
      const waveConfig = state.waveManager.startNextWave();
    }

    // Update player
    updatePlayer(state);

    // Auto-shoot
    if (now - state.player.lastShot > state.player.fireRate) {
      shoot(state);
      state.player.lastShot = now;
    }

    // Spawn enemies via wave manager
    const newEnemy = state.waveManager.spawnEnemy(state);
    if (newEnemy) {
      state.enemies.push(newEnemy);
    }

    // Spawn obstacles occasionally
    if (now - state.lastObstacleSpawn > GAME_CONFIG.obstacleSpawnRate) {
      spawnObstacle(state);
      state.lastObstacleSpawn = now;
    }

    // Update bullets
    state.bullets = state.bullets.filter(bullet => {
      bullet.x += bullet.vx;
      bullet.y += bullet.vy;
      return bullet.y > 0 && bullet.x > 0 && bullet.x < GAME_CONFIG.width;
    });

    // Update enemy bullets
    state.enemyBullets = state.enemyBullets.filter(bullet => {
      bullet.x += bullet.vx;
      bullet.y += bullet.vy;
      return bullet.y < GAME_CONFIG.height && bullet.x > 0 && bullet.x < GAME_CONFIG.width;
    });

    // Update enemies with behaviors
    state.enemies.forEach(enemy => {
      updateEnemyBehavior(enemy, state.player, state);
    });

    // Update obstacles
    state.obstacles.forEach(obstacle => {
      obstacle.y += obstacle.speed;
    });

    // Remove off-screen entities
    state.enemies = state.enemies.filter(enemy => enemy.y < GAME_CONFIG.height + 100);
    state.obstacles = state.obstacles.filter(obstacle => obstacle.y < GAME_CONFIG.height + 100);

    // Update particle system
    state.particleSystem.update();

    // Collision detection
    checkCollisions(state);

    // Update particles and explosions
    updateParticles(state);

    // Update wave status
    setWaveStatus(state.waveManager.getWaveStatus());

    // Update stats
    setGameStats({
      level: state.level,
      xp: state.xp,
      xpToNext: state.xpToNext,
      hp: state.player.hp,
      maxHp: state.player.maxHp,
      score: state.score,
      kills: state.kills,
    });
  };

  const updatePlayer = (state) => {
    const player = state.player;
    const keys = state.keys;

    // Horizontal movement
    if (keys['a'] || keys['arrowleft']) {
      player.vx = Math.max(player.vx - 0.6, -GAME_CONFIG.playerSpeed);
    } else if (keys['d'] || keys['arrowright']) {
      player.vx = Math.min(player.vx + 0.6, GAME_CONFIG.playerSpeed);
    } else {
      player.vx *= 0.85; // Friction
    }

    // Vertical movement
    if (keys['w'] || keys['arrowup']) {
      if (player.grounded || player.canJump) {
        player.vy = GAME_CONFIG.jumpPower;
        player.grounded = false;
        player.canJump = false;
      }
    }

    // Jump/fly with space (mais controlado)
    if (keys[' ']) {
      player.vy = Math.max(player.vy - 0.6, GAME_CONFIG.jumpPower);
    }

    // Apply gravity
    player.vy += GAME_CONFIG.gravity;

    // Update position
    player.x += player.vx;
    player.y += player.vy;

    // Boundaries
    player.x = Math.max(0, Math.min(GAME_CONFIG.width - player.width, player.x));

    // Ground collision
    if (player.y >= GAME_CONFIG.height - player.height - 40) {
      player.y = GAME_CONFIG.height - player.height - 40;
      player.vy = 0;
      player.grounded = true;
      player.canJump = true;
    }
  };

  const shoot = (state) => {
    const player = state.player;
    const mouse = state.mouse;
    
    const dx = mouse.x - (player.x + player.width / 2);
    const dy = mouse.y - (player.y + player.height / 2);
    const distance = Math.sqrt(dx * dx + dy * dy);
    
    const speed = 10;
    const vx = (dx / distance) * speed;
    const vy = (dy / distance) * speed;

    state.bullets.push({
      x: player.x + player.width / 2,
      y: player.y + player.height / 2,
      vx: vx,
      vy: vy,
      width: 8,
      height: 8,
      damage: player.damage,
      emoji: '⭐'
    });

    // Partículas de tiro mágico
    state.particleSystem.emit(
      player.x + player.width / 2, 
      player.y + player.height / 2, 
      {
        count: 5,
        colors: ['#ffff00', '#ffa500', '#ffffff'],
        size: { min: 1, max: 3 },
        speed: 3,
        lifespan: 25,
        behavior: 'magic'
      }
    );
  };

  const spawnObstacle = (state) => {
    const x = Math.random() * (GAME_CONFIG.width - 80);
    const obstacle = {
      x: x,
      y: -80,
      width: 60 + Math.random() * 40,
      height: 60 + Math.random() * 40,
      speed: 4 + Math.random() * 3,
      damage: 60,
      emoji: '🪨'
    };
    state.obstacles.push(obstacle);
  };

  const checkCollisions = (state) => {
    const player = state.player;

    // Bullet vs Enemy collisions
    state.bullets.forEach((bullet, bulletIndex) => {
      state.enemies.forEach((enemy, enemyIndex) => {
        if (bullet.x < enemy.x + enemy.width &&
            bullet.x + bullet.width > enemy.x &&
            bullet.y < enemy.y + enemy.height &&
            bullet.y + bullet.height > enemy.y) {
          
          // Hit enemy
          enemy.hp -= bullet.damage;
          state.bullets.splice(bulletIndex, 1);

          // Hit particles
          state.particleSystem.emit(enemy.x + enemy.width/2, enemy.y + enemy.height/2, {
            count: 12,
            colors: [enemy.color, '#ffffff', '#ffff00'],
            size: { min: 2, max: 5 },
            speed: 6,
            lifespan: 25,
            behavior: 'explosion'
          });

          // Screen shake pequeno no hit
          triggerScreenShake(4, 120);

          if (enemy.hp <= 0) {
            // Enemy died
            state.enemies.splice(enemyIndex, 1);
            state.kills++;
            state.score += 15 + (state.level * 8);
            
            // Notify wave manager
            state.waveManager.onEnemyKilled(enemy);
            
            // Gain XP
            const xpGain = 15 + (state.level * 3);
            state.xp += xpGain;
            
            // Death explosion
            state.particleSystem.emit(
              enemy.x + enemy.width/2, 
              enemy.y + enemy.height/2,
              {
                count: 35,
                colors: [enemy.color, '#ffffff', '#ffff00', '#ff6600'],
                size: { min: 3, max: 8 },
                speed: 10,
                lifespan: 45,
                behavior: 'explosion',
                spread: Math.PI * 2
              }
            );

            // Screen shake médio na morte
            const shakeIntensity = enemy.type === 'boss' ? 20 : 10;
            triggerScreenShake(shakeIntensity, 250);

            // Level up check
            if (state.xp >= state.xpToNext) {
              levelUp(state);
            }
          }
        }
      });
    });

    // Player vs Enemy collisions
    state.enemies.forEach((enemy, enemyIndex) => {
      if (player.x < enemy.x + enemy.width &&
          player.x + player.width > enemy.x &&
          player.y < enemy.y + enemy.height &&
          player.y + player.height > enemy.y) {
        
        // Player hit by enemy
        player.hp -= enemy.damage;
        
        // Hit particles
        state.particleSystem.emit(player.x + player.width/2, player.y + player.height/2, {
          count: 20,
          colors: ['#ff4444', '#ffffff', '#ffaa00'],
          size: { min: 2, max: 6 },
          speed: 8,
          lifespan: 35,
          behavior: 'explosion'
        });

        // Screen shake forte no dano do player
        triggerScreenShake(18, 250);
        
        if (player.hp <= 0) {
          triggerScreenShake(35, 600);
          gameOver(state);
        }
      }
    });

    // Player vs Enemy Bullet collisions
    state.enemyBullets.forEach((bullet, bulletIndex) => {
      if (player.x < bullet.x + bullet.width &&
          player.x + player.width > bullet.x &&
          player.y < bullet.y + bullet.height &&
          player.y + player.height > bullet.y) {
        
        // Player hit by enemy bullet
        player.hp -= bullet.damage;
        state.enemyBullets.splice(bulletIndex, 1);
        
        // Hit particles
        state.particleSystem.emit(player.x + player.width/2, player.y + player.height/2, {
          count: 15,
          colors: ['#ff4444', '#ffffff'],
          size: { min: 2, max: 5 },
          speed: 6,
          lifespan: 30,
          behavior: 'explosion'
        });

        // Screen shake no dano
        triggerScreenShake(15, 180);
        
        if (player.hp <= 0) {
          triggerScreenShake(35, 600);
          gameOver(state);
        }
      }
    });

    // Player vs Obstacle collisions
    state.obstacles.forEach((obstacle, obstacleIndex) => {
      if (player.x < obstacle.x + obstacle.width &&
          player.x + player.width > obstacle.x &&
          player.y < obstacle.y + obstacle.height &&
          player.y + player.height > obstacle.y) {
        
        // Player hit by obstacle
        player.hp -= obstacle.damage;
        
        // Obstacle impact particles
        state.particleSystem.emit(player.x + player.width/2, player.y + player.height/2, {
          count: 25,
          colors: ['#888888', '#ffffff', '#ffaa00'],
          size: { min: 4, max: 8 },
          speed: 10,
          lifespan: 40,
          behavior: 'explosion'
        });

        // Screen shake muito forte por obstáculo
        triggerScreenShake(30, 450);
        
        if (player.hp <= 0) {
          triggerScreenShake(45, 700);
          gameOver(state);
        }
      }
    });
  };

  const createParticles = (state, x, y, color) => {
    for (let i = 0; i < 8; i++) {
      state.particles.push({
        x: x,
        y: y,
        vx: (Math.random() - 0.5) * 8,
        vy: (Math.random() - 0.5) * 8,
        life: 30,
        maxLife: 30,
        color: color,
      });
    }
  };

  const createExplosion = (state, x, y) => {
    state.explosions.push({
      x: x,
      y: y,
      radius: 0,
      maxRadius: 30,
      life: 20,
      maxLife: 20,
    });
  };

  const updateParticles = (state) => {
    // Update particles
    state.particles = state.particles.filter(particle => {
      particle.x += particle.vx;
      particle.y += particle.vy;
      particle.life--;
      particle.vx *= 0.98;
      particle.vy *= 0.98;
      return particle.life > 0;
    });

    // Update explosions
    state.explosions = state.explosions.filter(explosion => {
      explosion.radius = (explosion.maxRadius * (explosion.maxLife - explosion.life)) / explosion.maxLife;
      explosion.life--;
      return explosion.life > 0;
    });
  };

  const levelUp = (state) => {
    state.level++;
    state.xp = 0;
    state.xpToNext = GAME_CONFIG.xpPerLevel * state.level;
    state.difficulty = 1 + (state.level * 0.2);
    
    // Show power-up selection
    const powerUpChoices = generatePowerUpChoices();
    setAvailablePowerUps(powerUpChoices);
    setShowPowerUpSelection(true);
    state.gamePaused = true;
    state.showPowerUpSelection = true;
  };

  const generatePowerUpChoices = () => {
    const choices = [];
    const allPowerUps = Object.values(POWER_UPS).flat();
    
    // Weighted selection based on rarity
    const weights = {
      common: 50,
      uncommon: 25,
      rare: 15,
      epic: 8,
      legendary: 2
    };

    for (let i = 0; i < 3; i++) {
      const totalWeight = Object.values(weights).reduce((a, b) => a + b, 0);
      let random = Math.random() * totalWeight;
      let selectedRarity = 'common';
      
      for (const [rarity, weight] of Object.entries(weights)) {
        random -= weight;
        if (random <= 0) {
          selectedRarity = rarity;
          break;
        }
      }
      
      const rarityPowerUps = allPowerUps.filter(p => p.rarity === selectedRarity);
      const powerUp = rarityPowerUps[Math.floor(Math.random() * rarityPowerUps.length)];
      choices.push(powerUp);
    }
    
    return choices;
  };

  const selectPowerUp = (powerUp) => {
    const state = gameStateRef.current;
    state.playerPowerUps.push(powerUp);
    applyPowerUp(state, powerUp);
    
    setShowPowerUpSelection(false);
    state.gamePaused = false;
    state.showPowerUpSelection = false;
  };

  const applyPowerUp = (state, powerUp) => {
    const player = state.player;
    
    switch (powerUp.id) {
      case 'magic_damage':
        player.damage *= 1.05;
        break;
      case 'projectile_speed':
        break; // Applied in bullet creation
      case 'fire_rate_1':
        player.fireRate *= 0.95;
        break;
      case 'fire_rate_2':
        player.fireRate *= 0.90;
        break;
      case 'max_hp_10':
        player.maxHp += 10;
        player.hp += 10;
        break;
      case 'max_hp_30':
        player.maxHp += 30;
        player.hp += 30;
        break;
      case 'move_speed_5':
      case 'move_speed_util_5':
        // Applied in movement logic
        break;
      // Add more power-up effects as needed
    }
  };

  const gameOver = (state) => {
    state.gameOver = true;
    state.gameStarted = false;
    setGameStarted(false);
  };

  // Função para renderizar emoji
  const renderEmoji = (ctx, emoji, x, y, size) => {
    ctx.font = `${size}px Arial`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(emoji, x, y);
  };

  const renderGame = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    const state = gameStateRef.current;

    // Clear canvas
    ctx.fillStyle = '#000000';
    ctx.fillRect(0, 0, GAME_CONFIG.width, GAME_CONFIG.height);

    if (!state.gameStarted) {
      // Start screen
      ctx.fillStyle = '#ffffff';
      ctx.font = '64px monospace';
      ctx.textAlign = 'center';
      ctx.fillText('🧙‍♂️ MAGO ROGUELIKE ⚡', GAME_CONFIG.width / 2, GAME_CONFIG.height / 2 - 80);
      ctx.font = '32px monospace';
      ctx.fillText('Clique para começar', GAME_CONFIG.width / 2, GAME_CONFIG.height / 2 + 20);
      ctx.font = '24px monospace';
      ctx.fillText('WASD para mover, ESPAÇO para voar', GAME_CONFIG.width / 2, GAME_CONFIG.height / 2 + 80);
      return;
    }

    // Aplicar screen shake
    ctx.save();
    ctx.translate(state.screenShake.offsetX, state.screenShake.offsetY);

    // Render player (wizard emoji)
    const player = state.player;
    renderEmoji(ctx, player.emoji, player.x + player.width/2, player.y + player.height/2, 32);

    // Render bullets (star emojis)
    state.bullets.forEach(bullet => {
      renderEmoji(ctx, bullet.emoji, bullet.x + bullet.width/2, bullet.y + bullet.height/2, 16);
    });

    // Render enemy bullets
    state.enemyBullets.forEach(bullet => {
      if (bullet.emoji) {
        renderEmoji(ctx, bullet.emoji, bullet.x + bullet.width/2, bullet.y + bullet.height/2, 14);
      } else {
        ctx.fillStyle = bullet.color || '#ff4444';
        ctx.fillRect(bullet.x, bullet.y, bullet.width, bullet.height);
      }
    });

    // Render enemies (various emojis)
    state.enemies.forEach(enemy => {
      renderEmoji(ctx, enemy.emoji, enemy.x + enemy.width/2, enemy.y + enemy.height/2, 
                  enemy.type === 'boss' ? 48 : 28);
      
      // Health bar
      const healthPercent = enemy.hp / enemy.maxHp;
      const barWidth = enemy.width;
      const barHeight = 6;
      const barX = enemy.x;
      const barY = enemy.y - 12;
      
      ctx.fillStyle = '#ff0000';
      ctx.fillRect(barX, barY, barWidth, barHeight);
      ctx.fillStyle = '#00ff00';
      ctx.fillRect(barX, barY, barWidth * healthPercent, barHeight);
      
      // Boss indicator
      if (enemy.type === 'boss') {
        ctx.fillStyle = '#ffffff';
        ctx.font = '16px monospace';
        ctx.textAlign = 'center';
        ctx.fillText('👑 BOSS 👑', enemy.x + enemy.width/2, enemy.y - 25);
      }
    });

    // Render obstacles (rock emojis)
    state.obstacles.forEach(obstacle => {
      renderEmoji(ctx, obstacle.emoji, obstacle.x + obstacle.width/2, obstacle.y + obstacle.height/2, 36);
    });

    // Render particle system
    state.particleSystem.render(ctx);

    // Render particles
    state.particles.forEach(particle => {
      const alpha = particle.life / particle.maxLife;
      ctx.fillStyle = particle.color + Math.floor(alpha * 255).toString(16).padStart(2, '0');
      ctx.fillRect(particle.x, particle.y, 3, 3);
    });

    // Render explosions
    state.explosions.forEach(explosion => {
      const alpha = explosion.life / explosion.maxLife;
      ctx.strokeStyle = `rgba(255, 255, 0, ${alpha})`;
      ctx.lineWidth = 4;
      ctx.beginPath();
      ctx.arc(explosion.x, explosion.y, explosion.radius, 0, Math.PI * 2);
      ctx.stroke();
    });

    // Render ground
    ctx.fillStyle = '#333333';
    ctx.fillRect(0, GAME_CONFIG.height - 40, GAME_CONFIG.width, 40);

    // Restaurar contexto (remover screen shake)
    ctx.restore();
  };

  // Wave Display Component
  const WaveDisplay = ({ waveStatus }) => {
    if (!waveStatus.active && waveStatus.timeToNextWave > 0) {
      const seconds = Math.ceil(waveStatus.timeToNextWave / 1000);
      return (
        <div className="wave-intermission">
          <h2>🎉 Onda {waveStatus.wave} Completa! 🎉</h2>
          <p>Próxima onda em: {seconds}s</p>
          {waveStatus.wave % 5 === 4 && <p className="boss-warning">⚠️ BOSS CHEGANDO! ⚠️</p>}
        </div>
      );
    }
    
    if (waveStatus.active) {
      return (
        <div className="wave-info">
          <span>🌊 Onda {waveStatus.wave}</span>
          {waveStatus.isBossWave && <span className="boss-warning">👑 BOSS! 👑</span>}
          <span>👹 Inimigos: {waveStatus.enemiesRemaining}/{waveStatus.totalEnemies}</span>
        </div>
      );
    }
    
    return null;
  };

  return (
    <div className="game-container">
      <canvas
        ref={canvasRef}
        width={GAME_CONFIG.width}
        height={GAME_CONFIG.height}
        className="game-canvas"
      />
      
      {/* HUD na parte de baixo */}
      {gameStarted && (
        <div className="hud">
          {/* Wave Display no topo */}
          <WaveDisplay waveStatus={waveStatus} />
          
          {/* HUD principal embaixo */}
          <div className="hud-bottom">
            <div className="health-section">
              <div className="health-bar">
                <div className="health-fill" style={{ width: `${(gameStats.hp / gameStats.maxHp) * 100}%` }} />
                <span className="health-text">❤️ {gameStats.hp}/{gameStats.maxHp}</span>
              </div>
            </div>
            
            <div className="xp-section">
              <div className="level-info">
                <span>⭐ Nível {gameStats.level}</span>
                <div className="xp-bar">
                  <div className="xp-fill" style={{ width: `${(gameStats.xp / gameStats.xpToNext) * 100}%` }} />
                </div>
                <span>💫 {gameStats.xp}/{gameStats.xpToNext} XP</span>
              </div>
            </div>
            
            <div className="score-section">
              <span>🏆 Pontos: {gameStats.score}</span>
              <span>💀 Kills: {gameStats.kills}</span>
            </div>
          </div>
        </div>
      )}

      {/* Power-up Selection */}
      {showPowerUpSelection && (
        <div className="power-up-selection">
          <div className="power-up-modal">
            <h2>✨ Escolha um Power-up! ✨</h2>
            <div className="power-up-choices">
              {availablePowerUps.map((powerUp, index) => (
                <div
                  key={index}
                  className="power-up-choice"
                  style={{ borderColor: RARITY_COLORS[powerUp.rarity] }}
                  onClick={() => selectPowerUp(powerUp)}
                >
                  <div className="power-up-rarity" style={{ color: RARITY_COLORS[powerUp.rarity] }}>
                    {powerUp.rarity.toUpperCase()}
                  </div>
                  <div className="power-up-name">{powerUp.name}</div>
                  <div className="power-up-desc">{powerUp.desc}</div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Game Over */}
      {!gameStarted && gameStateRef.current.gameOver && (
        <div className="game-over">
          <div className="game-over-modal">
            <h2>💀 Game Over! 💀</h2>
            <p>Nível Final: {gameStats.level}</p>
            <p>Onda Final: {waveStatus.wave}</p>
            <p>Pontuação: {gameStats.score}</p>
            <p>Kills: {gameStats.kills}</p>
            <button onClick={() => { resetGame(); startGame(); }}>
              🔄 Jogar Novamente
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

export default App;