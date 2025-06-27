import React, { useEffect, useRef, useState } from 'react';
import './App.css';

const GAME_CONFIG = {
  width: 1920, // Full HD Width
  height: 1080, // Full HD Height
  gravity: 0.4,
  jumpPower: -12,
  flyPower: -0.5,
  playerSpeed: 8, // Velocidade maior para tela maior
  fireRate: 200,
  xpPerLevel: 100,
  enemySpawnRate: 400,
  obstacleSpawnRate: 3000,
  sideObstacleSpawnRate: 2000,
  pitSpawnRate: 4000,
  maxFlyHeight: 350, // Altura de voo maior
  continuousEnemySpawn: true,
};

// Background stars system
class StarField {
  constructor(width, height) {
    this.width = width;
    this.height = height;
    this.stars = [];
    this.initStars();
  }

  initStars() {
    for (let i = 0; i < 200; i++) {
      this.stars.push({
        x: Math.random() * this.width,
        y: Math.random() * this.height,
        z: Math.random() * 1000,
        prevZ: Math.random() * 1000,
        size: Math.random() * 2 + 1,
        brightness: Math.random()
      });
    }
  }

  update(speed = 5) {
    this.stars.forEach(star => {
      star.prevZ = star.z;
      star.z -= speed;
      
      if (star.z <= 0) {
        star.x = Math.random() * this.width;
        star.y = Math.random() * this.height;
        star.z = 1000;
        star.prevZ = 1000;
        star.brightness = Math.random();
      }
    });
  }

  render(ctx) {
    ctx.save();
    this.stars.forEach(star => {
      const x = (star.x - this.width / 2) * (200 / star.z) + this.width / 2;
      const y = (star.y - this.height / 2) * (200 / star.z) + this.height / 2;
      
      const prevX = (star.x - this.width / 2) * (200 / star.prevZ) + this.width / 2;
      const prevY = (star.y - this.height / 2) * (200 / star.prevZ) + this.height / 2;

      if (x >= 0 && x <= this.width && y >= 0 && y <= this.height) {
        const size = (1 - star.z / 1000) * star.size;
        const alpha = (1 - star.z / 1000) * star.brightness;
        
        ctx.strokeStyle = `rgba(255, 255, 255, ${alpha})`;
        ctx.lineWidth = size;
        ctx.beginPath();
        ctx.moveTo(prevX, prevY);
        ctx.lineTo(x, y);
        ctx.stroke();
      }
    });
    ctx.restore();
  }
}

// Sistema de partículas avançado
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
      shape: 'circle',
      behavior: 'normal'
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

      switch (config.behavior) {
        case 'fire':
          particle.vy = -Math.abs(particle.vy) - 2;
          particle.vx *= 0.5;
          particle.gravity = -0.05;
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
      particle.vx *= 0.98;
      particle.vy += particle.gravity;
      particle.x += particle.vx;
      particle.y += particle.vy;
      particle.life--;
      particle.rotation += particle.rotationSpeed;

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
      
      let alpha = 1;
      if (particle.fadeOut) {
        alpha = particle.life / particle.maxLife;
      }
      
      const color = this.hexToRgba(particle.color, alpha);
      ctx.fillStyle = color;
      ctx.strokeStyle = color;
      
      ctx.translate(particle.x, particle.y);
      ctx.rotate(particle.rotation);
      
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

// Sistema de ondas com duração fixa
class WaveManager {
  constructor() {
    this.currentWave = 0;
    this.enemiesInWave = 0;
    this.enemiesSpawned = 0;
    this.enemiesKilled = 0;
    this.waveActive = false;
    this.waveStartTime = 0;
    this.waveDuration = 30000; // 30 segundos por onda
    this.intermissionTime = 5000; // 5 segundos entre ondas
    this.nextWaveTime = 0;
    this.bossWave = false;
    this.continuousSpawnActive = true;
  }

  getWaveConfig(waveNumber) {
    const baseEnemies = 8; // Número base mais razoável
    const isBossWave = waveNumber % 5 === 0 && waveNumber > 0; // Boss a cada 5 ondas, garantido
    
    // Aumento mais controlado
    const enemyMultiplier = 1 + (waveNumber * 0.3);
    
    return {
      enemyCount: isBossWave ? 2 : Math.floor(baseEnemies * enemyMultiplier),
      enemyTypes: this.getEnemyTypesForWave(waveNumber),
      spawnRate: Math.max(800, 1500 - (waveNumber * 50)), // Spawn mais controlado
      enemyHealthMultiplier: 1 + (waveNumber * 0.1),
      enemySpeedMultiplier: 0.5 + (waveNumber * 0.1), // Velocidade escala com wave
      enemyDamageMultiplier: 1 + (waveNumber * 0.08),
      isBossWave,
      waveDuration: this.waveDuration,
      rewards: {
        xp: 30 * waveNumber,
        score: 80 * waveNumber,
        health: isBossWave ? 30 : 5
      }
    };
  }

  getEnemyTypesForWave(waveNumber) {
    const types = ['basic'];
    
    if (waveNumber >= 2) types.push('shooter'); // Shooters desde wave 2
    if (waveNumber >= 3) types.push('zigzag');
    if (waveNumber >= 5) types.push('tank');
    if (waveNumber >= 7) types.push('teleporter');
    
    if (waveNumber % 5 === 0 && waveNumber > 0) {
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
    this.continuousSpawnActive = true;
    
    return config;
  }

  canSpawnEnemy(currentTime) {
    if (!this.continuousSpawnActive) return false;
    
    // Parar spawn se a onda já durou muito tempo
    const waveTimeElapsed = currentTime - this.waveStartTime;
    if (waveTimeElapsed >= this.waveDuration) {
      this.completeWave();
      return false;
    }
    
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
    
    // Special handling for boss introduction
    if (type === 'boss' && !gameState.bossIntroduction.active) {
      // Start boss introduction sequence instead of spawning immediately
      this.startBossIntroduction(gameState, config);
      return null;
    }
    
    this.enemiesSpawned++;
    
    return this.createEnemyOfType(type, config, gameState);
  }

  createEnemyOfType(type, waveConfig, gameState) {
    const baseStats = {
      basic: { hp: 25, speed: 1.5, damage: 12, size: 1, emoji: '👹', color: '#22c55e' },
      zigzag: { hp: 30, speed: 1.8, damage: 15, size: 1, emoji: '🐍', color: '#3b82f6' },
      tank: { hp: 80, speed: 0.8, damage: 25, size: 1.5, emoji: '🛡️', color: '#6b7280' },
      shooter: { hp: 35, speed: 1.2, damage: 18, size: 1, emoji: '🏹', color: '#f97316' },
      teleporter: { hp: 40, speed: 2, damage: 20, size: 1, emoji: '👻', color: '#a855f7' },
      boss: { hp: 200, speed: 0.6, damage: 30, size: 2.5, emoji: '🐲', color: '#dc2626' }
    };
    
    const stats = baseStats[type];
    const player = gameState?.player || { x: GAME_CONFIG.width / 2 };
    
    let x, y;
    
    if (type === 'boss') {
      x = GAME_CONFIG.width / 2 - 50;
      y = -60 * stats.size;
    } else {
      // 20% chance de spawn lateral, 80% do topo
      if (Math.random() < 0.2) {
        const side = Math.random() < 0.5 ? 'left' : 'right';
        x = side === 'left' ? -40 : GAME_CONFIG.width + 40;
        y = Math.random() * (GAME_CONFIG.height * 0.6);
      } else {
        // Spawn mais próximo ao jogador
        const playerSide = player.x < GAME_CONFIG.width / 2 ? 'left' : 'right';
        if (playerSide === 'left') {
          x = Math.random() * (GAME_CONFIG.width * 0.7);
        } else {
          x = (GAME_CONFIG.width * 0.3) + Math.random() * (GAME_CONFIG.width * 0.7);
        }
        y = -60 * stats.size;
      }
    }
    
    return {
      x,
      y,
      width: 30 * stats.size,
      height: 30 * stats.size,
      speed: stats.speed * waveConfig.enemySpeedMultiplier,
      hp: Math.round(stats.hp * waveConfig.enemyHealthMultiplier), // Arredondar HP
      maxHp: Math.round(stats.hp * waveConfig.enemyHealthMultiplier),
      damage: Math.round(stats.damage * waveConfig.enemyDamageMultiplier), // Arredondar damage
      color: stats.color,
      emoji: stats.emoji,
      type,
      behavior: type,
      shootCooldown: type === 'shooter' ? 1200 : (type === 'boss' ? 800 : 0), // Cooldowns mais longos
      lastShot: 0,
      teleportCooldown: type === 'teleporter' ? 2500 : 0, // Menos teleporte
      lastTeleport: 0,
      zigzagPhase: 0,
      pursuitRange: 400,
      attackRange: 300,
      targetX: player.x,
      targetY: player.y,
      fromSide: x < 0 || x > GAME_CONFIG.width
    };
  }

  onEnemyKilled(enemy) {
    this.enemiesKilled++;
    // Continue spawning until time runs out
  }

  completeWave() {
    this.waveActive = false;
    this.continuousSpawnActive = false;
    this.nextWaveTime = Date.now() + this.intermissionTime;
    
    const config = this.getWaveConfig(this.currentWave);
    return config.rewards;
  }

  update(currentTime) {
    // Verificar se a onda deve terminar por tempo
    if (this.waveActive) {
      const waveTimeElapsed = currentTime - this.waveStartTime;
      if (waveTimeElapsed >= this.waveDuration) {
        this.completeWave();
      }
    }
    
    if (!this.waveActive && currentTime >= this.nextWaveTime) {
      return { startNewWave: true };
    }
    return { startNewWave: false };
  }

  getWaveStatus() {
    const now = Date.now();
    const waveTimeElapsed = this.waveActive ? now - this.waveStartTime : 0;
    const waveTimeRemaining = this.waveActive ? Math.max(0, this.waveDuration - waveTimeElapsed) : 0;
    
    return {
      wave: this.currentWave,
      active: this.waveActive,
      enemiesRemaining: Math.max(0, this.enemiesInWave - this.enemiesKilled),
      totalEnemies: this.enemiesInWave,
      isBossWave: this.bossWave,
      timeToNextWave: this.waveActive ? 0 : Math.max(0, this.nextWaveTime - now),
      waveTimeRemaining: Math.ceil(waveTimeRemaining / 1000), // Em segundos
      continuousSpawn: this.continuousSpawnActive
    };
  }

  startBossIntroduction(gameState, config) {
    const boss = this.createEnemyOfType('boss', config, gameState);
    
    // Position boss at center of screen for introduction
    boss.x = GAME_CONFIG.width / 2 - boss.width / 2;
    boss.y = GAME_CONFIG.height / 2 - boss.height / 2;
    boss.introStartTime = Date.now();
    boss.dynamicDifficultyStart = Date.now();
    
    gameState.bossIntroduction = {
      active: true,
      boss: boss,
      startTime: Date.now(),
      duration: 3000,
      scale: 0.1,
      targetScale: 1.0
    };
    
    // Pause continuous spawning during boss introduction
    this.continuousSpawnActive = false;
    
    // Boss introduction particles
    gameState.particleSystem.emit(boss.x + boss.width/2, boss.y + boss.height/2, {
      count: 50,
      colors: ['#dc2626', '#ffffff', '#ffff00', '#ff6600'],
      size: { min: 5, max: 15 },
      speed: 15,
      lifespan: 80,
      behavior: 'explosion',
      spread: Math.PI * 2
    });
  }
}

const POWER_UPS = {
  // TIER 1 - NÍVEIS 1-3 (Básicos)
  tier1_offensive: [
    { id: 'magic_damage_small', name: '+10% Dano Mágico', desc: 'Aumenta dano base em 10%', rarity: 'common', tier: 1 },
    { id: 'double_shot', name: 'Tiro Duplo', desc: 'Atira 2 projéteis simultaneamente', rarity: 'common', tier: 1 },
    { id: 'projectile_speed', name: '+15% Velocidade de Projétil', desc: 'Projéteis voam mais rápido', rarity: 'common', tier: 1 },
    { id: 'extra_projectile', name: '+1 Projétil', desc: 'Adiciona mais 1 projétil ao seu ataque', rarity: 'uncommon', tier: 1 },
  ],
  tier1_defensive: [
    { id: 'hp_boost_small', name: '+20 Vida Máxima', desc: 'Aumenta vida máxima', rarity: 'common', tier: 1 },
    { id: 'speed_boost_small', name: '+15% Velocidade', desc: 'Move mais rápido', rarity: 'common', tier: 1 },
    { id: 'damage_reduction_small', name: '+10% Resistência', desc: 'Reduz dano recebido', rarity: 'common', tier: 1 },
    { id: 'shield_small', name: '+2 Escudos', desc: 'Absorve próximos 2 ataques', rarity: 'uncommon', tier: 1 },
  ],
  
  // TIER 2 - NÍVEIS 4-7 (Intermediários)
  tier2_offensive: [
    { id: 'magic_damage_medium', name: '+15% Dano Mágico', desc: 'Aumenta dano base significativamente', rarity: 'uncommon', tier: 2 },
    { id: 'extra_projectile', name: '+1 Projétil', desc: 'Adiciona mais 1 projétil ao seu ataque', rarity: 'uncommon', tier: 2 },
    { id: 'pierce_shot', name: 'Perfuração', desc: 'Projéteis atravessam inimigos', rarity: 'uncommon', tier: 2 },
    { id: 'explosive_shot', name: 'Tiro Explosivo', desc: 'Projéteis explodem ao atingir', rarity: 'rare', tier: 2 },
    { id: 'fire_rate_small', name: '+10% Cadência', desc: 'Atira um pouco mais rápido', rarity: 'uncommon', tier: 2 },
  ],
  tier2_defensive: [
    { id: 'hp_boost_medium', name: '+30 Vida Máxima', desc: 'Grande aumento de vida', rarity: 'uncommon', tier: 2 },
    { id: 'speed_boost_medium', name: '+20% Velocidade', desc: 'Movimento muito mais rápido', rarity: 'uncommon', tier: 2 },
    { id: 'damage_reduction_medium', name: '+15% Resistência', desc: 'Boa redução de dano', rarity: 'uncommon', tier: 2 },
    { id: 'shield_medium', name: '+3 Escudos', desc: 'Absorve próximos 3 ataques', rarity: 'rare', tier: 2 },
    { id: 'hp_regen', name: 'Regeneração', desc: 'Recupera 2 vida a cada 8s', rarity: 'rare', tier: 2 },
  ],
  
  // TIER 3 - NÍVEIS 8+ (Avançados)
  tier3_offensive: [
    { id: 'magic_damage_large', name: '+25% Dano Mágico', desc: 'Enorme aumento de dano', rarity: 'rare', tier: 3 },
    { id: 'extra_projectile', name: '+1 Projétil', desc: 'Adiciona mais 1 projétil ao seu ataque', rarity: 'rare', tier: 3 },
    { id: 'chain_lightning', name: 'Raio em Cadeia', desc: 'Projéteis saltam entre inimigos próximos', rarity: 'rare', tier: 3 },
    { id: 'homing_missiles', name: 'Mísseis Teleguiados', desc: 'Projéteis perseguem inimigos', rarity: 'rare', tier: 3 },
    { id: 'fire_rate_medium', name: '+20% Cadência', desc: 'Atira muito mais rápido', rarity: 'rare', tier: 3 },
    { id: 'mega_damage', name: '+50% Dano Mágico', desc: 'Poder destrutivo extremo', rarity: 'legendary', tier: 3 },
  ],
  tier3_defensive: [
    { id: 'hp_boost_large', name: '+50 Vida Máxima', desc: 'Aumento massivo de vida', rarity: 'rare', tier: 3 },
    { id: 'speed_boost_large', name: '+30% Velocidade', desc: 'Velocidade extrema', rarity: 'rare', tier: 3 },
    { id: 'damage_reduction_large', name: '+25% Resistência', desc: 'Alta resistência a dano', rarity: 'rare', tier: 3 },
    { id: 'shield_large', name: '+5 Escudos', desc: 'Absorve próximos 5 ataques', rarity: 'legendary', tier: 3 },
    { id: 'dash_ability', name: 'Habilidade Dash', desc: 'Dash rápido com SHIFT', rarity: 'rare', tier: 3 },
  ]
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
      y: GAME_CONFIG.height - 200, // Ajustado para tela maior
      vx: 0,
      vy: 0,
      width: 40,
      height: 40,
      hp: 100,
      maxHp: 100,
      grounded: false,
      canJump: true,
      damage: 30,
      fireRate: GAME_CONFIG.fireRate,
      lastShot: 0,
      emoji: '🧙‍♂️',
      dashCooldown: 0,
      shield: 0,
      damageReduction: 0,
      projectileCount: 1,
      piercing: false,
      explosive: false,
      homing: false
    },
    bullets: [],
    enemies: [],
    enemyBullets: [],
    obstacles: [],
    sideObstacles: [],
    pits: [],
    explosions: [],
    particles: [],
    particleSystem: new ParticleSystem(),
    waveManager: new WaveManager(),
    starField: new StarField(GAME_CONFIG.width, GAME_CONFIG.height),
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
    lastSideObstacleSpawn: 0,
    lastPitSpawn: 0,
    powerUps: [],
    showPowerUpSelection: false,
    availablePowerUps: [],
    playerPowerUps: [],
    kills: 0,
    difficulty: 1,
    bossIntroduction: {
      active: false,
      boss: null,
      startTime: 0,
      duration: 3000, // 3 seconds introduction
      scale: 0.1,
      targetScale: 1.0
    },
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
    timeToNextWave: 0,
    continuousSpawn: false
  });

  const triggerScreenShake = (intensity = 10, duration = 300) => {
    const state = gameStateRef.current;
    state.screenShake.intensity = intensity;
    state.screenShake.duration = duration;
  };

  // IA dos inimigos MUITO mais agressiva
  const updateEnemyBehavior = (enemy, player, gameState) => {
    const now = Date.now();
    
    const dx = player.x - enemy.x;
    const dy = player.y - enemy.y;
    const distanceToPlayer = Math.sqrt(dx * dx + dy * dy);
    
    // Perseguir jogador SEMPRE agressivamente
    if (distanceToPlayer > 10) {
      const moveX = (dx / distanceToPlayer) * enemy.speed * 0.8;
      const moveY = (dy / distanceToPlayer) * enemy.speed * 0.3;
      enemy.x += moveX;
      enemy.y += moveY;
    }
    
    switch (enemy.behavior) {
      case 'basic':
        if (!enemy.fromSide) enemy.y += enemy.speed;
        // Movimento direto ao jogador
        if (Math.abs(dx) > 10) {
          enemy.x += (dx / Math.abs(dx)) * enemy.speed * 0.6;
        }
        break;
        
      case 'zigzag':
        if (!enemy.fromSide) enemy.y += enemy.speed;
        enemy.zigzagPhase += 0.25;
        enemy.x += Math.sin(enemy.zigzagPhase) * 3;
        // Perseguir
        if (Math.abs(dx) > 20) {
          enemy.x += (dx / Math.abs(dx)) * enemy.speed * 0.4;
        }
        break;
        
      case 'tank':
        if (!enemy.fromSide) enemy.y += enemy.speed;
        // Tank persegue diretamente
        if (Math.abs(dx) > 5) {
          enemy.x += (dx / Math.abs(dx)) * enemy.speed * 0.9;
        }
        break;
        
      case 'shooter':
        if (!enemy.fromSide) enemy.y += enemy.speed * 0.8;
        
        // Perseguir
        if (Math.abs(dx) > 15) {
          enemy.x += (dx / Math.abs(dx)) * enemy.speed * 0.5;
        }
        
        // ATIRAR SEMPRE que possível
        if (now - enemy.lastShot > enemy.shootCooldown && distanceToPlayer < enemy.attackRange) {
          const bulletSpeed = 7;
          const spread = 0.2;
          
          // Atira 3 projéteis
          for (let i = 0; i < 3; i++) {
            const angle = Math.atan2(dy, dx) + (i - 1) * spread;
            gameState.enemyBullets.push({
              x: enemy.x + enemy.width / 2,
              y: enemy.y + enemy.height,
              vx: Math.cos(angle) * bulletSpeed,
              vy: Math.sin(angle) * bulletSpeed,
              width: 10,
              height: 10,
              damage: enemy.damage * 0.5,
              color: '#ff4400',
              emoji: '🔥'
            });
          }
          enemy.lastShot = now;
        }
        break;
        
      case 'teleporter':
        if (!enemy.fromSide) enemy.y += enemy.speed;
        
        // Teleportar constantemente
        if (now - enemy.lastTeleport > enemy.teleportCooldown) {
          gameState.particleSystem.emit(enemy.x + enemy.width/2, enemy.y + enemy.height/2, {
            count: 12,
            colors: ['#a855f7', '#ffffff'],
            size: { min: 2, max: 5 },
            speed: 4,
            lifespan: 20,
            behavior: 'magic'
          });
          
          // Teleportar MUITO perto do jogador
          const teleportDistance = 50 + Math.random() * 40;
          const teleportAngle = Math.random() * Math.PI * 2;
          enemy.x = player.x + Math.cos(teleportAngle) * teleportDistance;
          enemy.y = player.y + Math.sin(teleportAngle) * teleportDistance;
          
          enemy.x = Math.max(0, Math.min(GAME_CONFIG.width - enemy.width, enemy.x));
          enemy.y = Math.max(0, Math.min(GAME_CONFIG.height - enemy.height, enemy.y));
          
          enemy.lastTeleport = now;
        }
        break;
        
      case 'boss':
        enemy.y = Math.min(enemy.y + enemy.speed, 100);
        
        // Dynamic difficulty - boss gets stronger over time
        if (enemy.dynamicDifficultyStart) {
          const timeAlive = now - enemy.dynamicDifficultyStart;
          const difficultyMultiplier = 1 + (timeAlive / 30000); // Increase 1% every 300ms
          
          // Increase damage over time
          enemy.baseDamage = enemy.baseDamage || enemy.damage;
          enemy.damage = Math.round(enemy.baseDamage * difficultyMultiplier);
          
          // Increase speed over time
          enemy.baseSpeed = enemy.baseSpeed || enemy.speed;
          enemy.speed = enemy.baseSpeed * Math.min(difficultyMultiplier, 2); // Cap at 2x speed
        }
        
        // Boss segue jogador agressivamente
        if (enemy.x < player.x - 20) {
          enemy.x += enemy.speed * 4;
        } else if (enemy.x > player.x + 20) {
          enemy.x -= enemy.speed * 4;
        }
        
        // Slower but more numerous projectiles
        const healthPercent = enemy.hp / enemy.maxHp;
        let shootInterval = 800; // Slower shooting rate
        
        if (healthPercent < 0.5) {
          shootInterval = 600; // Still slower but more frequent when hurt
        }
        
        if (now - enemy.lastShot > shootInterval) {
          // Multiple projectile patterns with slower speed
          const bulletSpeed = 4; // Slower bullets for dodging
          
          // Spread pattern - more projectiles but slower
          for (let i = -6; i <= 6; i++) {
            gameState.enemyBullets.push({
              x: enemy.x + enemy.width / 2,
              y: enemy.y + enemy.height,
              vx: i * 1.5,
              vy: bulletSpeed,
              width: 12,
              height: 12,
              damage: enemy.damage * 0.25, // Reduced damage per bullet
              color: '#dc2626',
              emoji: '💀'
            });
          }
          
          // Circular pattern
          for (let angle = 0; angle < Math.PI * 2; angle += Math.PI / 4) {
            gameState.enemyBullets.push({
              x: enemy.x + enemy.width / 2,
              y: enemy.y + enemy.height / 2,
              vx: Math.cos(angle) * bulletSpeed,
              vy: Math.sin(angle) * bulletSpeed,
              width: 10,
              height: 10,
              damage: enemy.damage * 0.2,
              color: '#dc2626',
              emoji: '🔥'
            });
          }
          
          // Targeted shot - slightly faster
          if (distanceToPlayer > 0) {
            gameState.enemyBullets.push({
              x: enemy.x + enemy.width / 2,
              y: enemy.y + enemy.height,
              vx: (dx / distanceToPlayer) * bulletSpeed * 1.5,
              vy: (dy / distanceToPlayer) * bulletSpeed * 1.5,
              width: 18,
              height: 18,
              damage: enemy.damage * 0.4,
              color: '#dc2626',
              emoji: '💥'
            });
          }
          
          enemy.lastShot = now;
        }
        break;
    }
    
    enemy.x = Math.max(0, Math.min(GAME_CONFIG.width - enemy.width, enemy.x));
  };

  const updateScreenShake = (state) => {
    if (state.screenShake.duration > 0) {
      state.screenShake.duration -= 16;
      const factor = state.screenShake.duration / 300;
      const intensity = state.screenShake.intensity * factor;
      
      state.screenShake.offsetX = (Math.random() - 0.5) * intensity;
      state.screenShake.offsetY = (Math.random() - 0.5) * intensity;
    } else {
      state.screenShake.offsetX = 0;
      state.screenShake.offsetY = 0;
    }
  };

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    ctx.imageSmoothingEnabled = false;

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
    
    const waveConfig = gameStateRef.current.waveManager.startNextWave();
    
    setGameStarted(true);
    gameLoop();
  };

  const resetGame = () => {
    const state = gameStateRef.current;
    state.player = {
      x: GAME_CONFIG.width / 2,
      y: GAME_CONFIG.height - 200, // Ajustado para tela maior
      vx: 0,
      vy: 0,
      width: 40,
      height: 40,
      hp: 100,
      maxHp: 100,
      grounded: false,
      canJump: true,
      damage: 30,
      fireRate: GAME_CONFIG.fireRate,
      lastShot: 0,
      emoji: '🧙‍♂️',
      dashCooldown: 0,
      shield: 0,
      damageReduction: 0,
      projectileCount: 1,
      piercing: false,
      explosive: false,
      homing: false
    };
    state.bullets = [];
    state.enemies = [];
    state.enemyBullets = [];
    state.obstacles = [];
    state.sideObstacles = [];
    state.pits = [];
    state.explosions = [];
    state.particles = [];
    state.particleSystem = new ParticleSystem();
    state.waveManager = new WaveManager();
    state.starField = new StarField(GAME_CONFIG.width, GAME_CONFIG.height);
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

    updateScreenShake(state);
    
    // Update boss introduction
    if (state.bossIntroduction.active) {
      const introTime = now - state.bossIntroduction.startTime;
      const progress = Math.min(introTime / state.bossIntroduction.duration, 1);
      
      // Animate boss scale
      state.bossIntroduction.scale = 0.1 + (0.9 * progress);
      
      // Complete introduction
      if (progress >= 1) {
        const boss = state.bossIntroduction.boss;
        boss.x = GAME_CONFIG.width / 2 - boss.width / 2;
        boss.y = 50; // Move to top after introduction
        state.enemies.push(boss);
        
        state.bossIntroduction.active = false;
        state.waveManager.continuousSpawnActive = true; // Resume spawning
        
        // Boss appearance screen shake
        triggerScreenShake(30, 500);
        
        // Final boss appearance particles
        state.particleSystem.emit(boss.x + boss.width/2, boss.y + boss.height/2, {
          count: 75,
          colors: ['#dc2626', '#ffffff', '#ffff00', '#ff6600'],
          size: { min: 8, max: 20 },
          speed: 20,
          lifespan: 100,
          behavior: 'explosion',
          spread: Math.PI * 2
        });
      }
    }
    
    // Update boss introduction
    if (state.bossIntroduction.active) {
      const introTime = now - state.bossIntroduction.startTime;
      const progress = Math.min(introTime / state.bossIntroduction.duration, 1);
      
      // Animate boss scale
      state.bossIntroduction.scale = 0.1 + (0.9 * progress);
      
      // Complete introduction
      if (progress >= 1) {
        const boss = state.bossIntroduction.boss;
        boss.x = GAME_CONFIG.width / 2 - boss.width / 2;
        boss.y = 50; // Move to top after introduction
        state.enemies.push(boss);
        
        state.bossIntroduction.active = false;
        state.waveManager.continuousSpawnActive = true; // Resume spawning
        
        // Boss appearance screen shake
        triggerScreenShake(30, 500);
        
        // Final boss appearance particles
        state.particleSystem.emit(boss.x + boss.width/2, boss.y + boss.height/2, {
          count: 75,
          colors: ['#dc2626', '#ffffff', '#ffff00', '#ff6600'],
          size: { min: 8, max: 20 },
          speed: 20,
          lifespan: 100,
          behavior: 'explosion',
          spread: Math.PI * 2
        });
      }
    }
    
    // Update starfield
    state.starField.update(8);

    const waveUpdate = state.waveManager.update(now);
    if (waveUpdate.startNewWave) {
      const waveConfig = state.waveManager.startNextWave();
    }

    updatePlayer(state);

    // Auto-shoot
    if (now - state.player.lastShot > state.player.fireRate) {
      shoot(state);
      state.player.lastShot = now;
    }

    // Spawn MUITOS inimigos
    const newEnemy = state.waveManager.spawnEnemy(state);
    if (newEnemy) {
      state.enemies.push(newEnemy);
    }

    // Spawn obstáculos frequentes
    if (now - state.lastObstacleSpawn > GAME_CONFIG.obstacleSpawnRate) {
      spawnObstacle(state);
      state.lastObstacleSpawn = now;
    }

    // Spawn obstáculos laterais
    if (now - state.lastSideObstacleSpawn > GAME_CONFIG.sideObstacleSpawnRate) {
      spawnSideObstacle(state);
      state.lastSideObstacleSpawn = now;
    }

    // Spawn pits
    if (now - state.lastPitSpawn > GAME_CONFIG.pitSpawnRate) {
      spawnPit(state);
      state.lastPitSpawn = now;
    }

    // Update bullets
    state.bullets = state.bullets.filter(bullet => {
      bullet.x += bullet.vx;
      bullet.y += bullet.vy;
      
      // Homing bullets
      if (bullet.homing && state.enemies.length > 0) {
        const closestEnemy = state.enemies.reduce((closest, enemy) => {
          const dist1 = Math.sqrt((bullet.x - enemy.x)**2 + (bullet.y - enemy.y)**2);
          const dist2 = Math.sqrt((bullet.x - closest.x)**2 + (bullet.y - closest.y)**2);
          return dist1 < dist2 ? enemy : closest;
        });
        
        const dx = closestEnemy.x - bullet.x;
        const dy = closestEnemy.y - bullet.y;
        const dist = Math.sqrt(dx*dx + dy*dy);
        const homingForce = 0.3;
        
        bullet.vx += (dx/dist) * homingForce;
        bullet.vy += (dy/dist) * homingForce;
      }
      
      return bullet.y > -50 && bullet.x > -50 && bullet.x < GAME_CONFIG.width + 50;
    });

    // Update enemy bullets
    state.enemyBullets = state.enemyBullets.filter(bullet => {
      bullet.x += bullet.vx;
      bullet.y += bullet.vy;
      return bullet.y < GAME_CONFIG.height + 50 && bullet.x > -50 && bullet.x < GAME_CONFIG.width + 50;
    });

    // Update enemies
    state.enemies.forEach(enemy => {
      updateEnemyBehavior(enemy, state.player, state);
    });

    // Update obstacles
    state.obstacles.forEach(obstacle => {
      obstacle.y += obstacle.speed;
    });

    // Update side obstacles
    state.sideObstacles.forEach(obstacle => {
      obstacle.x += obstacle.vx;
      obstacle.y += obstacle.vy;
    });

    // Update pits
    state.pits.forEach(pit => {
      pit.x += pit.speed;
    });

    // Remove off-screen entities
    state.enemies = state.enemies.filter(enemy => 
      enemy.y < GAME_CONFIG.height + 100 && 
      enemy.x > -100 && 
      enemy.x < GAME_CONFIG.width + 100
    );
    state.obstacles = state.obstacles.filter(obstacle => obstacle.y < GAME_CONFIG.height + 100);
    state.sideObstacles = state.sideObstacles.filter(obstacle => 
      obstacle.x > -200 && obstacle.x < GAME_CONFIG.width + 200
    );
    state.pits = state.pits.filter(pit => pit.x > -300);

    state.particleSystem.update();
    checkCollisions(state);
    updateParticles(state);

    setWaveStatus(state.waveManager.getWaveStatus());

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
    const now = Date.now();

    // Dash ability
    if (keys['shift'] && now - player.dashCooldown > 2000) {
      player.vx *= 3;
      player.dashCooldown = now;
      triggerScreenShake(5, 100);
    }

    // Horizontal movement
    if (keys['a'] || keys['arrowleft']) {
      player.vx = Math.max(player.vx - 0.8, -GAME_CONFIG.playerSpeed);
    } else if (keys['d'] || keys['arrowright']) {
      player.vx = Math.min(player.vx + 0.8, GAME_CONFIG.playerSpeed);
    } else {
      player.vx *= 0.88;
    }

    // Vertical movement
    if (keys['w'] || keys['arrowup']) {
      if (player.grounded || player.canJump) {
        player.vy = GAME_CONFIG.jumpPower;
        player.grounded = false;
        player.canJump = false;
      }
    }

    // Flying
    if (keys[' ']) {
      const maxFlyY = GAME_CONFIG.height - GAME_CONFIG.maxFlyHeight;
      if (player.y > maxFlyY) {
        player.vy += GAME_CONFIG.flyPower;
      }
    }

    player.vy += GAME_CONFIG.gravity;

    player.x += player.vx;
    player.y += player.vy;

    player.x = Math.max(0, Math.min(GAME_CONFIG.width - player.width, player.x));
    player.y = Math.max(0, player.y);

    // Ground collision
    if (player.y >= GAME_CONFIG.height - player.height - 60) { // Ajustado para tela maior
      player.y = GAME_CONFIG.height - player.height - 60;
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
    
    const speed = player.projectileSpeed || 12;
    const baseVx = (dx / distance) * speed;
    const baseVy = (dy / distance) * speed;

    // Multiple projectiles based on power-ups
    const projectileCount = player.projectileCount || 1;
    const spread = Math.PI / 8;

    for (let i = 0; i < projectileCount; i++) {
      const angle = (i - (projectileCount - 1) / 2) * spread / (projectileCount - 1 || 1);
      const vx = baseVx * Math.cos(angle) - baseVy * Math.sin(angle);
      const vy = baseVx * Math.sin(angle) + baseVx * Math.cos(angle);

      state.bullets.push({
        x: player.x + player.width / 2,
        y: player.y + player.height / 2,
        vx: vx,
        vy: vy,
        width: 8,
        height: 8,
        damage: player.damage,
        emoji: '⭐',
        piercing: player.piercing || false,
        explosive: player.explosive || false,
        homing: player.homing || false,
        chainLightning: player.chainLightning || false,
        chainCount: player.chainCount || 0,
        piercesLeft: player.piercingCount || (player.piercing ? 3 : 0)
      });
    }

    // Shooting particles
    state.particleSystem.emit(
      player.x + player.width / 2, 
      player.y + player.height / 2, 
      {
        count: 8,
        colors: ['#ffff00', '#ffa500', '#ffffff'],
        size: { min: 1, max: 4 },
        speed: 4,
        lifespan: 30,
        behavior: 'magic'
      }
    );
  };

  const spawnObstacle = (state) => {
    const x = Math.random() * (GAME_CONFIG.width - 150);
    const size = 100 + Math.random() * 80; // Muito maiores
    const obstacle = {
      x: x,
      y: -size,
      width: size,
      height: size,
      speed: 3 + Math.random() * 3,
      damage: 80,
      emoji: '🪨',
      hp: 5, // Mais resistentes
      maxHp: 5
    };
    state.obstacles.push(obstacle);
  };

  const spawnSideObstacle = (state) => {
    const side = Math.random() < 0.5 ? 'left' : 'right';
    const size = 60 + Math.random() * 40;
    const y = Math.random() * (GAME_CONFIG.height * 0.7);
    
    const obstacle = {
      x: side === 'left' ? -size : GAME_CONFIG.width,
      y: y,
      width: size,
      height: size,
      vx: side === 'left' ? 4 + Math.random() * 3 : -(4 + Math.random() * 3),
      vy: Math.random() * 2 - 1,
      damage: 60,
      emoji: '⚡',
      hp: 3,
      maxHp: 3
    };
    state.sideObstacles.push(obstacle);
  };

  const spawnPit = (state) => {
    const width = 180 + Math.random() * 120; // Buracos maiores para tela HD
    const pit = {
      x: GAME_CONFIG.width + 100, // Spawn mais longe para tela maior
      y: GAME_CONFIG.height - 60, // Ajustado para novo chão
      width: width,
      height: 60, // Altura do chão
      speed: -(4 + Math.random() * 3), // Velocidade ajustada para tela maior
      damage: 50,
      emoji: '🕳️'
    };
    state.pits.push(pit);
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
          
          enemy.hp -= bullet.damage;
          
          // Handle piercing
          if (bullet.piercing && bullet.piercesLeft > 0) {
            bullet.piercesLeft--;
          } else {
            state.bullets.splice(bulletIndex, 1);
          }

          // Chain Lightning effect
          if (bullet.chainLightning && bullet.chainCount > 0) {
            // Find nearby enemies for chain lightning
            const chainRange = 150;
            const nearbyEnemies = state.enemies.filter(nearbyEnemy => {
              if (nearbyEnemy === enemy) return false; // Don't chain to the same enemy
              const dist = Math.sqrt((nearbyEnemy.x - enemy.x)**2 + (nearbyEnemy.y - enemy.y)**2);
              return dist <= chainRange;
            });
            
            // Sort by distance and take up to chainCount enemies
            nearbyEnemies.sort((a, b) => {
              const distA = Math.sqrt((a.x - enemy.x)**2 + (a.y - enemy.y)**2);
              const distB = Math.sqrt((b.x - enemy.x)**2 + (b.y - enemy.y)**2);
              return distA - distB;
            });
            
            const chainTargets = nearbyEnemies.slice(0, bullet.chainCount);
            
            // Create chain lightning projectiles
            chainTargets.forEach(target => {
              const dx = target.x - enemy.x;
              const dy = target.y - enemy.y;
              const distance = Math.sqrt(dx * dx + dy * dy);
              const speed = bullet.vx * bullet.vx + bullet.vy * bullet.vy; // Maintain speed
              const chainVx = (dx / distance) * Math.sqrt(speed);
              const chainVy = (dy / distance) * Math.sqrt(speed);
              
              state.bullets.push({
                x: enemy.x + enemy.width / 2,
                y: enemy.y + enemy.height / 2,
                vx: chainVx,
                vy: chainVy,
                width: 6,
                height: 6,
                damage: Math.round(bullet.damage * 0.75), // Reduced damage for chain
                emoji: '⚡',
                piercing: false,
                explosive: false,
                homing: false,
                chainLightning: true,
                chainCount: bullet.chainCount - 1, // Reduce chain count
                piercesLeft: 0
              });
            });
            
            // Chain lightning visual effect
            if (chainTargets.length > 0) {
              state.particleSystem.emit(enemy.x + enemy.width/2, enemy.y + enemy.height/2, {
                count: 25,
                colors: ['#00ffff', '#ffffff', '#ffff00', '#0080ff'],
                size: { min: 2, max: 6 },
                speed: 12,
                lifespan: 30,
                behavior: 'magic'
              });
              
              triggerScreenShake(6, 150);
            }
          }

          // Chain Lightning effect
          if (bullet.chainLightning && bullet.chainCount > 0) {
            // Find nearby enemies for chain lightning
            const chainRange = 150;
            const nearbyEnemies = state.enemies.filter(nearbyEnemy => {
              if (nearbyEnemy === enemy) return false; // Don't chain to the same enemy
              const dist = Math.sqrt((nearbyEnemy.x - enemy.x)**2 + (nearbyEnemy.y - enemy.y)**2);
              return dist <= chainRange;
            });
            
            // Sort by distance and take up to chainCount enemies
            nearbyEnemies.sort((a, b) => {
              const distA = Math.sqrt((a.x - enemy.x)**2 + (a.y - enemy.y)**2);
              const distB = Math.sqrt((b.x - enemy.x)**2 + (b.y - enemy.y)**2);
              return distA - distB;
            });
            
            const chainTargets = nearbyEnemies.slice(0, bullet.chainCount);
            
            // Create chain lightning projectiles
            chainTargets.forEach(target => {
              const dx = target.x - enemy.x;
              const dy = target.y - enemy.y;
              const distance = Math.sqrt(dx * dx + dy * dy);
              const speed = bullet.vx * bullet.vx + bullet.vy * bullet.vy; // Maintain speed
              const chainVx = (dx / distance) * Math.sqrt(speed);
              const chainVy = (dy / distance) * Math.sqrt(speed);
              
              state.bullets.push({
                x: enemy.x + enemy.width / 2,
                y: enemy.y + enemy.height / 2,
                vx: chainVx,
                vy: chainVy,
                width: 6,
                height: 6,
                damage: Math.round(bullet.damage * 0.75), // Reduced damage for chain
                emoji: '⚡',
                piercing: false,
                explosive: false,
                homing: false,
                chainLightning: true,
                chainCount: bullet.chainCount - 1, // Reduce chain count
                piercesLeft: 0
              });
            });
            
            // Chain lightning visual effect
            if (chainTargets.length > 0) {
              state.particleSystem.emit(enemy.x + enemy.width/2, enemy.y + enemy.height/2, {
                count: 25,
                colors: ['#00ffff', '#ffffff', '#ffff00', '#0080ff'],
                size: { min: 2, max: 6 },
                speed: 12,
                lifespan: 30,
                behavior: 'magic'
              });
              
              triggerScreenShake(6, 150);
            }
          }

          // Explosion effect
          if (bullet.explosive) {
            state.particleSystem.emit(enemy.x + enemy.width/2, enemy.y + enemy.height/2, {
              count: 20,
              colors: ['#ff6600', '#ffaa00', '#ffffff'],
              size: { min: 3, max: 8 },
              speed: 8,
              lifespan: 35,
              behavior: 'explosion'
            });
            
            // Area damage
            state.enemies.forEach(nearbyEnemy => {
              const dist = Math.sqrt((nearbyEnemy.x - enemy.x)**2 + (nearbyEnemy.y - enemy.y)**2);
              if (dist < 80 && nearbyEnemy !== enemy) {
                nearbyEnemy.hp -= bullet.damage * 0.5;
              }
            });
          }

          state.particleSystem.emit(enemy.x + enemy.width/2, enemy.y + enemy.height/2, {
            count: 12,
            colors: [enemy.color, '#ffffff', '#ffff00'],
            size: { min: 2, max: 5 },
            speed: 6,
            lifespan: 25,
            behavior: 'explosion'
          });

          triggerScreenShake(4, 120);

          if (enemy.hp <= 0) {
            state.enemies.splice(enemyIndex, 1);
            state.kills++;
            state.score += 20 + (state.level * 10);
            
            state.waveManager.onEnemyKilled(enemy);
            
            const xpGain = 20 + (state.level * 5);
            state.xp += xpGain;
            
            // Death explosion
            state.particleSystem.emit(
              enemy.x + enemy.width/2, 
              enemy.y + enemy.height/2,
              {
                count: 40,
                colors: [enemy.color, '#ffffff', '#ffff00', '#ff6600'],
                size: { min: 3, max: 10 },
                speed: 12,
                lifespan: 50,
                behavior: 'explosion',
                spread: Math.PI * 2
              }
            );

            const shakeIntensity = enemy.type === 'boss' ? 25 : 12;
            triggerScreenShake(shakeIntensity, 300);

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
        
        let damage = enemy.damage;
        
        // Shield protection
        if (player.shield > 0) {
          player.shield--;
          damage = 0;
          state.particleSystem.emit(player.x + player.width/2, player.y + player.height/2, {
            count: 15,
            colors: ['#00aaff', '#ffffff'],
            size: { min: 3, max: 6 },
            speed: 5,
            lifespan: 25,
            behavior: 'magic'
          });
        } else {
          // Damage reduction
          damage *= (1 - (player.damageReduction || 0));
          player.hp -= damage;
          
          state.particleSystem.emit(player.x + player.width/2, player.y + player.height/2, {
            count: 25,
            colors: ['#ff4444', '#ffffff', '#ffaa00'],
            size: { min: 2, max: 8 },
            speed: 10,
            lifespan: 40,
            behavior: 'explosion'
          });

          triggerScreenShake(20, 300);
        }
        
        if (player.hp <= 0) {
          triggerScreenShake(40, 700);
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
        
        let damage = bullet.damage;
        
        if (player.shield > 0) {
          player.shield--;
          damage = 0;
        } else {
          damage *= (1 - (player.damageReduction || 0));
          player.hp -= damage;
        }
        
        state.enemyBullets.splice(bulletIndex, 1);
        
        state.particleSystem.emit(player.x + player.width/2, player.y + player.height/2, {
          count: 18,
          colors: ['#ff4444', '#ffffff'],
          size: { min: 2, max: 6 },
          speed: 8,
          lifespan: 35,
          behavior: 'explosion'
        });

        triggerScreenShake(18, 200);
        
        if (player.hp <= 0) {
          triggerScreenShake(40, 700);
          gameOver(state);
        }
      }
    });

    // Player vs Obstacle collisions (all types)
    [...state.obstacles, ...state.sideObstacles].forEach((obstacle, obstacleIndex) => {
      if (player.x < obstacle.x + obstacle.width &&
          player.x + player.width > obstacle.x &&
          player.y < obstacle.y + obstacle.height &&
          player.y + player.height > obstacle.y) {
        
        let damage = obstacle.damage;
        
        if (player.shield > 0) {
          player.shield--;
          damage = 0;
        } else {
          damage *= (1 - (player.damageReduction || 0));
          player.hp -= damage;
        }
        
        state.particleSystem.emit(player.x + player.width/2, player.y + player.height/2, {
          count: 30,
          colors: ['#888888', '#ffffff', '#ffaa00'],
          size: { min: 4, max: 10 },
          speed: 12,
          lifespan: 45,
          behavior: 'explosion'
        });

        triggerScreenShake(35, 500);
        
        if (player.hp <= 0) {
          triggerScreenShake(50, 800);
          gameOver(state);
        }
      }
    });

    // Player vs Pit collisions
    state.pits.forEach((pit, pitIndex) => {
      if (player.x < pit.x + pit.width &&
          player.x + player.width > pit.x &&
          player.y + player.height > pit.y) {
        
        // Caiu no buraco!
        player.hp -= pit.damage;
        
        state.particleSystem.emit(player.x + player.width/2, player.y + player.height/2, {
          count: 25,
          colors: ['#654321', '#ffffff'],
          size: { min: 3, max: 7 },
          speed: 6,
          lifespan: 30,
          behavior: 'explosion'
        });

        triggerScreenShake(25, 400);
        
        if (player.hp <= 0) {
          gameOver(state);
        }
      }
    });

    // Bullet vs Obstacle collisions
    state.bullets.forEach((bullet, bulletIndex) => {
      [...state.obstacles, ...state.sideObstacles].forEach((obstacle, obstacleIndex) => {
        if (bullet.x < obstacle.x + obstacle.width &&
            bullet.x + bullet.width > obstacle.x &&
            bullet.y < obstacle.y + obstacle.height &&
            bullet.y + bullet.height > obstacle.y) {
          
          obstacle.hp -= 1;
          
          if (!bullet.piercing) {
            state.bullets.splice(bulletIndex, 1);
          }

          state.particleSystem.emit(obstacle.x + obstacle.width/2, obstacle.y + obstacle.height/2, {
            count: 10,
            colors: ['#888888', '#ffffff'],
            size: { min: 2, max: 5 },
            speed: 5,
            lifespan: 25,
            behavior: 'explosion'
          });

          if (obstacle.hp <= 0) {
            if (state.obstacles.includes(obstacle)) {
              state.obstacles.splice(state.obstacles.indexOf(obstacle), 1);
            } else {
              state.sideObstacles.splice(state.sideObstacles.indexOf(obstacle), 1);
            }
            
            state.score += 10;
            
            state.particleSystem.emit(
              obstacle.x + obstacle.width/2, 
              obstacle.y + obstacle.height/2,
              {
                count: 30,
                colors: ['#888888', '#ffffff', '#ffaa00'],
                size: { min: 3, max: 8 },
                speed: 10,
                lifespan: 40,
                behavior: 'explosion',
                spread: Math.PI * 2
              }
            );

            triggerScreenShake(10, 250);
          }
        }
      });
    });

    // Enemy Bullet vs Obstacle collisions
    state.enemyBullets.forEach((bullet, bulletIndex) => {
      [...state.obstacles, ...state.sideObstacles].forEach((obstacle, obstacleIndex) => {
        if (bullet.x < obstacle.x + obstacle.width &&
            bullet.x + bullet.width > obstacle.x &&
            bullet.y < obstacle.y + obstacle.height &&
            bullet.y + bullet.height > obstacle.y) {
          
          state.enemyBullets.splice(bulletIndex, 1);

          state.particleSystem.emit(bullet.x, bullet.y, {
            count: 6,
            colors: ['#ff6600', '#ffffff'],
            size: { min: 1, max: 3 },
            speed: 4,
            lifespan: 18,
            behavior: 'explosion'
          });
        }
      });
    });
  };

  const updateParticles = (state) => {
    state.particles = state.particles.filter(particle => {
      particle.x += particle.vx;
      particle.y += particle.vy;
      particle.life--;
      particle.vx *= 0.98;
      particle.vy *= 0.98;
      return particle.life > 0;
    });

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
    state.difficulty = 1 + (state.level * 0.3);
    
    const powerUpChoices = generatePowerUpChoices();
    setAvailablePowerUps(powerUpChoices);
    setShowPowerUpSelection(true);
    state.gamePaused = true;
    state.showPowerUpSelection = true;
  };

  const generatePowerUpChoices = () => {
    const choices = [];
    const playerLevel = gameStateRef.current.level;
    
    // Determinar tier baseado no nível
    let availableTiers = [];
    if (playerLevel >= 8) {
      availableTiers = ['tier1', 'tier2', 'tier3'];
    } else if (playerLevel >= 4) {
      availableTiers = ['tier1', 'tier2'];
    } else {
      availableTiers = ['tier1'];
    }
    
    // Pegar power-ups dos tiers disponíveis
    let availablePowerUps = [];
    availableTiers.forEach(tier => {
      const offensive = POWER_UPS[`${tier}_offensive`] || [];
      const defensive = POWER_UPS[`${tier}_defensive`] || [];
      availablePowerUps = [...availablePowerUps, ...offensive, ...defensive];
    });
    
    // Filtrar power-ups já adquiridos múltiplas vezes (exceto os que podem stackar)
    const stackablePowerUps = ['extra_projectile', 'magic_damage_small', 'magic_damage_medium', 'magic_damage_large', 
                              'hp_boost_small', 'hp_boost_medium', 'hp_boost_large', 'shield_small', 'shield_medium', 'shield_large',
                              'damage_reduction_small', 'damage_reduction_medium', 'damage_reduction_large',
                              'speed_boost_small', 'speed_boost_medium', 'speed_boost_large'];
    
    const playerPowerUps = gameStateRef.current.playerPowerUps;
    availablePowerUps = availablePowerUps.filter(powerUp => {
      if (stackablePowerUps.includes(powerUp.id)) {
        return true; // Pode ser escolhido novamente
      }
      return !playerPowerUps.some(p => p.id === powerUp.id);
    });
    
    // Selecionar 3 power-ups aleatórios
    for (let i = 0; i < 3 && availablePowerUps.length > 0; i++) {
      const randomIndex = Math.floor(Math.random() * availablePowerUps.length);
      const selectedPowerUp = availablePowerUps[randomIndex];
      choices.push(selectedPowerUp);
      
      // Remover da lista se não for stackable
      if (!stackablePowerUps.includes(selectedPowerUp.id)) {
        availablePowerUps.splice(randomIndex, 1);
      }
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
      // Additive damage power-ups
      case 'magic_damage_small':
        player.damage = Math.round(player.damage * 1.1); // +10% dano
        break;
      case 'magic_damage_medium':
        player.damage = Math.round(player.damage * 1.15); // +15% dano
        break;
      case 'magic_damage_large':
        player.damage = Math.round(player.damage * 1.25); // +25% dano
        break;
      case 'mega_damage':
        player.damage = Math.round(player.damage * 1.5); // +50% dano
        break;
      
      // Additive projectile power-ups
      case 'double_shot':
        player.projectileCount = Math.max(player.projectileCount || 1, 2); // Ensure at least 2 shots
        break;
      case 'extra_projectile':
        player.projectileCount = (player.projectileCount || 1) + 1; // +1 projectile (additive)
        break;
      
      // Fire rate improvements
      case 'fire_rate_small':
        player.fireRate = Math.round(player.fireRate * 0.9); // 10% mais rápido
        break;
      case 'fire_rate_medium':
        player.fireRate = Math.round(player.fireRate * 0.8); // 20% mais rápido
        break;
      
      // Projectile speed
      case 'projectile_speed':
        player.projectileSpeed = (player.projectileSpeed || 12) * 1.15; // +15% velocidade
        break;
      
      // Special projectile effects
      case 'pierce_shot':
        player.piercing = true;
        player.piercingCount = (player.piercingCount || 0) + 2; // +2 piercing count
        break;
      case 'explosive_shot':
        player.explosive = true;
        player.explosionRadius = (player.explosionRadius || 0) + 60; // +60 raio da explosão
        break;
      case 'homing_missiles':
        player.homing = true;
        break;
      case 'chain_lightning':
        player.chainLightning = true;
        player.chainCount = (player.chainCount || 0) + 3; // +3 chain jumps
        break;
      
      // Additive health power-ups
      case 'hp_boost_small':
        player.maxHp = Math.round(player.maxHp + 20);
        player.hp = Math.round(player.hp + 20);
        break;
      case 'hp_boost_medium':
        player.maxHp = Math.round(player.maxHp + 30);
        player.hp = Math.round(player.hp + 30);
        break;
      case 'hp_boost_large':
        player.maxHp = Math.round(player.maxHp + 50);
        player.hp = Math.round(player.hp + 50);
        break;
      
      // Additive speed power-ups
      case 'speed_boost_small':
        GAME_CONFIG.playerSpeed = Math.round(GAME_CONFIG.playerSpeed * 1.15); // +15% velocidade
        break;
      case 'speed_boost_medium':
        GAME_CONFIG.playerSpeed = Math.round(GAME_CONFIG.playerSpeed * 1.2); // +20% velocidade
        break;
      case 'speed_boost_large':
        GAME_CONFIG.playerSpeed = Math.round(GAME_CONFIG.playerSpeed * 1.3); // +30% velocidade
        break;
      
      // Additive damage reduction
      case 'damage_reduction_small':
        player.damageReduction = Math.min((player.damageReduction || 0) + 0.1, 0.8); // +10%, máx 80%
        break;
      case 'damage_reduction_medium':
        player.damageReduction = Math.min((player.damageReduction || 0) + 0.15, 0.8); // +15%, máx 80%
        break;
      case 'damage_reduction_large':
        player.damageReduction = Math.min((player.damageReduction || 0) + 0.25, 0.8); // +25%, máx 80%
        break;
      
      // Additive shield power-ups
      case 'shield_small':
        player.shield = (player.shield || 0) + 2; // +2 escudos
        break;
      case 'shield_medium':
        player.shield = (player.shield || 0) + 3; // +3 escudos
        break;
      case 'shield_large':
        player.shield = (player.shield || 0) + 5; // +5 escudos
        break;
      
      // Health regeneration
      case 'hp_regen':
        player.hpRegenRate = (player.hpRegenRate || 0) + 2; // +2 HP por 8s
        player.lastHpRegen = Date.now();
        break;
      
      // Dash ability
      case 'dash_ability':
        player.hasDash = true;
        player.dashSpeed = (player.dashSpeed || 1) + 2; // +2 dash speed multiplier
        break;
      
      // Legacy power-ups for backward compatibility
      case 'magic_damage':
        player.damage = Math.round(player.damage * 1.2); // +20% dano
        break;
      case 'fire_rate_1':
        player.fireRate = Math.round(player.fireRate * 0.8); // 20% mais rápido
        break;
      case 'triple_shot':
        player.projectileCount = Math.max(player.projectileCount || 1, 3); // Ensure at least 3 shots
        break;
      case 'shotgun_blast':
        player.projectileCount = Math.max(player.projectileCount || 1, 5); // Ensure at least 5 shots
        break;
      case 'pierce_1':
        player.piercing = true;
        player.piercingCount = (player.piercingCount || 0) + 2; // +2 piercing
        break;
      case 'explosion_shot':
        player.explosive = true;
        player.explosionRadius = (player.explosionRadius || 0) + 60; // +60 raio
        break;
      case 'rapid_fire':
        player.fireRate = Math.round(player.fireRate * 0.5); // 50% mais rápido
        break;
      case 'max_hp_25':
        player.maxHp = Math.round(player.maxHp + 25);
        player.hp = Math.round(player.hp + 25);
        break;
      case 'max_hp_50':
        player.maxHp = Math.round(player.maxHp + 50);
        player.hp = Math.round(player.hp + 50);
        break;
      case 'speed_boost':
        GAME_CONFIG.playerSpeed = Math.round(GAME_CONFIG.playerSpeed * 1.25); // +25% velocidade
        break;
      case 'damage_reduction':
        player.damageReduction = Math.min((player.damageReduction || 0) + 0.2, 0.8); // +20%, máx 80%
        break;
      case 'shield':
        player.shield = (player.shield || 0) + 5; // +5 escudos
        break;
      case 'invincibility_frames':
        player.invincibilityFrames = true;
        player.invincibilityDuration = 1000; // 1s de invencibilidade após dano
        break;
      case 'residual_flame':
        player.burnEffect = true;
        player.burnDamage = Math.round(player.damage * 0.3); // 30% do dano como burn
        player.burnDuration = 3000; // 3s de burn
        break;
    }
    
    // Garantir que HP não passe do máximo
    player.hp = Math.min(player.hp, player.maxHp);
    
    // Visual feedback melhorado
    state.particleSystem.emit(
      player.x + player.width / 2,
      player.y + player.height / 2,
      {
        count: 30,
        colors: ['#ffd700', '#ffff00', '#ffffff', '#00ff00'],
        size: { min: 4, max: 12 },
        speed: 10,
        lifespan: 60,
        behavior: 'magic',
        spread: Math.PI * 2
      }
    );
    
    // Screen shake de evolução
    triggerScreenShake(8, 200);
  };

  const gameOver = (state) => {
    state.gameOver = true;
    state.gameStarted = false;
    setGameStarted(false);
  };

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
    ctx.fillStyle = '#000011';
    ctx.fillRect(0, 0, GAME_CONFIG.width, GAME_CONFIG.height);

    if (!state.gameStarted) {
      ctx.fillStyle = '#ffffff';
      ctx.font = '64px monospace';
      ctx.textAlign = 'center';
      ctx.fillText('🧙‍♂️ MAGO ROGUELIKE ⚡', GAME_CONFIG.width / 2, GAME_CONFIG.height / 2 - 80);
      ctx.font = '32px monospace';
      ctx.fillText('Clique para começar', GAME_CONFIG.width / 2, GAME_CONFIG.height / 2 + 20);
      ctx.font = '24px monospace';
      ctx.fillText('WASD para mover, ESPAÇO para voar, SHIFT para dash', GAME_CONFIG.width / 2, GAME_CONFIG.height / 2 + 80);
      return;
    }

    // Apply screen shake
    ctx.save();
    ctx.translate(state.screenShake.offsetX, state.screenShake.offsetY);

    // Render starfield background
    state.starField.render(ctx);

    // Render player
    const player = state.player;
    renderEmoji(ctx, player.emoji, player.x + player.width/2, player.y + player.height/2, 36);
    
    // Shield effect
    if (player.shield > 0) {
      ctx.strokeStyle = '#00aaff';
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.arc(player.x + player.width/2, player.y + player.height/2, 25, 0, Math.PI * 2);
      ctx.stroke();
    }

    // Render bullets
    state.bullets.forEach(bullet => {
      if (bullet.explosive) {
        ctx.shadowColor = '#ff6600';
        ctx.shadowBlur = 8;
      } else if (bullet.homing) {
        ctx.shadowColor = '#aa00ff';
        ctx.shadowBlur = 6;
      }
      
      renderEmoji(ctx, bullet.emoji, bullet.x + bullet.width/2, bullet.y + bullet.height/2, 18);
      ctx.shadowBlur = 0;
    });

    // Render enemy bullets
    state.enemyBullets.forEach(bullet => {
      if (bullet.emoji) {
        renderEmoji(ctx, bullet.emoji, bullet.x + bullet.width/2, bullet.y + bullet.height/2, 16);
      } else {
        ctx.fillStyle = bullet.color || '#ff4444';
        ctx.fillRect(bullet.x, bullet.y, bullet.width, bullet.height);
      }
    });

    // Render enemies
    state.enemies.forEach(enemy => {
      renderEmoji(ctx, enemy.emoji, enemy.x + enemy.width/2, enemy.y + enemy.height/2, 
                  enemy.type === 'boss' ? 54 : 32);
      
      // Health bar
      const healthPercent = enemy.hp / enemy.maxHp;
      const barWidth = enemy.width;
      const barHeight = 8;
      const barX = enemy.x;
      const barY = enemy.y - 15;
      
      ctx.fillStyle = '#ff0000';
      ctx.fillRect(barX, barY, barWidth, barHeight);
      ctx.fillStyle = '#00ff00';
      ctx.fillRect(barX, barY, barWidth * healthPercent, barHeight);
      
      if (enemy.type === 'boss') {
        ctx.fillStyle = '#ffffff';
        ctx.font = '18px monospace';
        ctx.textAlign = 'center';
        ctx.fillText('👑 BOSS 👑', enemy.x + enemy.width/2, enemy.y - 30);
      }
    });

    // Render obstacles
    state.obstacles.forEach(obstacle => {
      renderEmoji(ctx, obstacle.emoji, obstacle.x + obstacle.width/2, obstacle.y + obstacle.height/2, 48);
    });

    // Render side obstacles
    state.sideObstacles.forEach(obstacle => {
      renderEmoji(ctx, obstacle.emoji, obstacle.x + obstacle.width/2, obstacle.y + obstacle.height/2, 36);
    });

    // Render pits
    state.pits.forEach(pit => {
      renderEmoji(ctx, pit.emoji, pit.x + pit.width/2, pit.y + pit.height/2, 32);
    });

    // Render particle system
    state.particleSystem.render(ctx);

    // Render boss introduction
    if (state.bossIntroduction.active) {
      const boss = state.bossIntroduction.boss;
      const scale = state.bossIntroduction.scale;
      
      // Dark overlay for dramatic effect
      ctx.fillStyle = 'rgba(0, 0, 0, 0.7)';
      ctx.fillRect(0, 0, GAME_CONFIG.width, GAME_CONFIG.height);
      
      // Boss spotlight
      const gradient = ctx.createRadialGradient(
        boss.x + boss.width/2, boss.y + boss.height/2, 0,
        boss.x + boss.width/2, boss.y + boss.height/2, 200
      );
      gradient.addColorStop(0, 'rgba(255, 255, 255, 0.3)');
      gradient.addColorStop(1, 'rgba(255, 255, 255, 0)');
      ctx.fillStyle = gradient;
      ctx.fillRect(0, 0, GAME_CONFIG.width, GAME_CONFIG.height);
      
      // Render boss with scaling
      ctx.save();
      ctx.translate(boss.x + boss.width/2, boss.y + boss.height/2);
      ctx.scale(scale, scale);
      ctx.translate(-boss.width/2, -boss.height/2);
      
      renderEmoji(ctx, boss.emoji, boss.width/2, boss.height/2, 54 * scale);
      
      ctx.restore();
      
      // Boss introduction text
      ctx.fillStyle = '#ffffff';
      ctx.font = '48px monospace';
      ctx.textAlign = 'center';
      ctx.strokeStyle = '#000000';
      ctx.lineWidth = 3;
      ctx.strokeText('👑 BOSS APARECE! 👑', GAME_CONFIG.width / 2, GAME_CONFIG.height / 2 + 200);
      ctx.fillText('👑 BOSS APARECE! 👑', GAME_CONFIG.width / 2, GAME_CONFIG.height / 2 + 200);
      
      // Warning text
      ctx.font = '24px monospace';
      ctx.fillStyle = '#ff4444';
      ctx.strokeText('⚠️ PREPARE-SE PARA A BATALHA! ⚠️', GAME_CONFIG.width / 2, GAME_CONFIG.height / 2 + 250);
      ctx.fillText('⚠️ PREPARE-SE PARA A BATALHA! ⚠️', GAME_CONFIG.width / 2, GAME_CONFIG.height / 2 + 250);
    }

    // Render boss introduction
    if (state.bossIntroduction.active) {
      const boss = state.bossIntroduction.boss;
      const scale = state.bossIntroduction.scale;
      
      // Dark overlay for dramatic effect
      ctx.fillStyle = 'rgba(0, 0, 0, 0.7)';
      ctx.fillRect(0, 0, GAME_CONFIG.width, GAME_CONFIG.height);
      
      // Boss spotlight
      const gradient = ctx.createRadialGradient(
        boss.x + boss.width/2, boss.y + boss.height/2, 0,
        boss.x + boss.width/2, boss.y + boss.height/2, 200
      );
      gradient.addColorStop(0, 'rgba(255, 255, 255, 0.3)');
      gradient.addColorStop(1, 'rgba(255, 255, 255, 0)');
      ctx.fillStyle = gradient;
      ctx.fillRect(0, 0, GAME_CONFIG.width, GAME_CONFIG.height);
      
      // Render boss with scaling
      ctx.save();
      ctx.translate(boss.x + boss.width/2, boss.y + boss.height/2);
      ctx.scale(scale, scale);
      ctx.translate(-boss.width/2, -boss.height/2);
      
      renderEmoji(ctx, boss.emoji, boss.width/2, boss.height/2, 54 * scale);
      
      ctx.restore();
      
      // Boss introduction text
      ctx.fillStyle = '#ffffff';
      ctx.font = '48px monospace';
      ctx.textAlign = 'center';
      ctx.strokeStyle = '#000000';
      ctx.lineWidth = 3;
      ctx.strokeText('👑 BOSS APARECE! 👑', GAME_CONFIG.width / 2, GAME_CONFIG.height / 2 + 200);
      ctx.fillText('👑 BOSS APARECE! 👑', GAME_CONFIG.width / 2, GAME_CONFIG.height / 2 + 200);
      
      // Warning text
      ctx.font = '24px monospace';
      ctx.fillStyle = '#ff4444';
      ctx.strokeText('⚠️ PREPARE-SE PARA A BATALHA! ⚠️', GAME_CONFIG.width / 2, GAME_CONFIG.height / 2 + 250);
      ctx.fillText('⚠️ PREPARE-SE PARA A BATALHA! ⚠️', GAME_CONFIG.width / 2, GAME_CONFIG.height / 2 + 250);
    }

    // Render particles
    state.particles.forEach(particle => {
      const alpha = particle.life / particle.maxLife;
      ctx.fillStyle = particle.color + Math.floor(alpha * 255).toString(16).padStart(2, '0');
      ctx.fillRect(particle.x, particle.y, 4, 4);
    });

    // Render explosions
    state.explosions.forEach(explosion => {
      const alpha = explosion.life / explosion.maxLife;
      ctx.strokeStyle = `rgba(255, 255, 0, ${alpha})`;
      ctx.lineWidth = 5;
      ctx.beginPath();
      ctx.arc(explosion.x, explosion.y, explosion.radius, 0, Math.PI * 2);
      ctx.stroke();
    });

    // Render ground
    ctx.fillStyle = '#333333';
    ctx.fillRect(0, GAME_CONFIG.height - 60, GAME_CONFIG.width, 60); // Chão maior para tela HD

    ctx.restore();
  };

  const WaveDisplay = ({ waveStatus }) => {
    if (!waveStatus.active && waveStatus.timeToNextWave > 0) {
      const seconds = Math.ceil(waveStatus.timeToNextWave / 1000);
      return (
        <div className="wave-intermission">
          <h2>🎉 Onda {waveStatus.wave} Sobrevivida! 🎉</h2>
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
          <span>👹 Spawn Contínuo Ativo!</span>
          <span>💀 Kills: {gameStats.kills}</span>
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
      
      {gameStarted && (
        <div className="hud">
          <WaveDisplay waveStatus={waveStatus} />
          
          <div className="hud-bottom">
            <div className="health-section">
              <div className="health-bar">
                <div className="health-fill" style={{ width: `${(gameStats.hp / gameStats.maxHp) * 100}%` }} />
                <span className="health-text">❤️ {Math.round(gameStats.hp)}/{Math.round(gameStats.maxHp)}</span>
              </div>
              {gameStateRef.current.player.shield > 0 && (
                <div className="shield-display">🛡️ {gameStateRef.current.player.shield}</div>
              )}
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
              <span>🔥 Enemies: {gameStateRef.current.enemies.length}</span>
            </div>
          </div>
        </div>
      )}

      {showPowerUpSelection && (
        <div className="power-up-selection">
          <div className="power-up-modal">
            <h2>⚡ EVOLUÇÃO MÁGICA! ⚡</h2>
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

      {!gameStarted && gameStateRef.current.gameOver && (
        <div className="game-over">
          <div className="game-over-modal">
            <h2>⚡ GAME OVER! ⚡</h2>
            <p>Nível Final: {gameStats.level}</p>
            <p>Onda Final: {waveStatus.wave}</p>
            <p>Pontuação: {gameStats.score}</p>
            <p>Kills: {gameStats.kills}</p>
            <p>Inimigos Derrotados: {gameStats.kills}</p>
            <button onClick={() => { resetGame(); startGame(); }}>
              🔄 TENTAR NOVAMENTE
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

export default App;