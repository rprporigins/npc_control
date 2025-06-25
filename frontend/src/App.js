import React, { useEffect, useRef, useState } from 'react';
import './App.css';

const GAME_CONFIG = {
  width: 1000,
  height: 700,
  gravity: 0.3,
  jumpPower: -12,
  playerSpeed: 4,
  fireRate: 100, // ms between shots
  xpPerLevel: 100,
  enemySpawnRate: 2000, // ms
  obstacleSpawnRate: 8000, // ms
};

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
      y: GAME_CONFIG.height - 100,
      vx: 0,
      vy: 0,
      width: 30,
      height: 30,
      hp: 100,
      maxHp: 100,
      grounded: false,
      canJump: true,
      damage: 20,
      fireRate: GAME_CONFIG.fireRate,
      lastShot: 0,
    },
    bullets: [],
    enemies: [],
    obstacles: [],
    explosions: [],
    particles: [],
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
    setGameStarted(true);
    gameLoop();
  };

  const resetGame = () => {
    const state = gameStateRef.current;
    state.player = {
      x: GAME_CONFIG.width / 2,
      y: GAME_CONFIG.height - 100,
      vx: 0,
      vy: 0,
      width: 30,
      height: 30,
      hp: 100,
      maxHp: 100,
      grounded: false,
      canJump: true,
      damage: 20,
      fireRate: GAME_CONFIG.fireRate,
      lastShot: 0,
    };
    state.bullets = [];
    state.enemies = [];
    state.obstacles = [];
    state.explosions = [];
    state.particles = [];
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

    // Update player
    updatePlayer(state);

    // Auto-shoot
    if (now - state.player.lastShot > state.player.fireRate) {
      shoot(state);
      state.player.lastShot = now;
    }

    // Spawn enemies
    if (now - state.lastEnemySpawn > GAME_CONFIG.enemySpawnRate / state.difficulty) {
      spawnEnemy(state);
      state.lastEnemySpawn = now;
    }

    // Spawn obstacles
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

    // Update enemies
    state.enemies.forEach(enemy => {
      enemy.y += enemy.speed * state.difficulty;
      enemy.x += Math.sin(enemy.y * 0.01) * 0.5; // Slight wave movement
    });

    // Update obstacles
    state.obstacles.forEach(obstacle => {
      obstacle.y += obstacle.speed;
    });

    // Remove off-screen entities
    state.enemies = state.enemies.filter(enemy => enemy.y < GAME_CONFIG.height + 50);
    state.obstacles = state.obstacles.filter(obstacle => obstacle.y < GAME_CONFIG.height + 50);

    // Collision detection
    checkCollisions(state);

    // Update particles and explosions
    updateParticles(state);

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
      player.vx = Math.max(player.vx - 0.5, -GAME_CONFIG.playerSpeed);
    } else if (keys['d'] || keys['arrowright']) {
      player.vx = Math.min(player.vx + 0.5, GAME_CONFIG.playerSpeed);
    } else {
      player.vx *= 0.8; // Friction
    }

    // Vertical movement
    if (keys['w'] || keys['arrowup']) {
      if (player.grounded || player.canJump) {
        player.vy = GAME_CONFIG.jumpPower;
        player.grounded = false;
        player.canJump = false;
      }
    }

    // Jump/fly with space
    if (keys[' ']) {
      player.vy = Math.max(player.vy - 0.8, GAME_CONFIG.jumpPower);
    }

    // Apply gravity
    player.vy += GAME_CONFIG.gravity;

    // Update position
    player.x += player.vx;
    player.y += player.vy;

    // Boundaries
    player.x = Math.max(0, Math.min(GAME_CONFIG.width - player.width, player.x));

    // Ground collision
    if (player.y >= GAME_CONFIG.height - player.height - 20) {
      player.y = GAME_CONFIG.height - player.height - 20;
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
    
    const speed = 8;
    const vx = (dx / distance) * speed;
    const vy = (dy / distance) * speed;

    state.bullets.push({
      x: player.x + player.width / 2,
      y: player.y + player.height / 2,
      vx: vx,
      vy: vy,
      width: 6,
      height: 6,
      damage: player.damage,
    });
  };

  const spawnEnemy = (state) => {
    const x = Math.random() * (GAME_CONFIG.width - 40);
    const enemy = {
      x: x,
      y: -40,
      width: 25 + Math.random() * 15,
      height: 25 + Math.random() * 15,
      speed: 1 + Math.random() * 2 + (state.difficulty * 0.5),
      hp: 30 + (state.level * 10),
      maxHp: 30 + (state.level * 10),
      damage: 10 + (state.level * 2),
      color: `hsl(${Math.random() * 360}, 100%, 60%)`, // Neon colors
    };
    state.enemies.push(enemy);
  };

  const spawnObstacle = (state) => {
    const x = Math.random() * (GAME_CONFIG.width - 60);
    const obstacle = {
      x: x,
      y: -60,
      width: 50 + Math.random() * 40,
      height: 50 + Math.random() * 40,
      speed: 3 + Math.random() * 2,
      damage: 50,
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

          // Create hit particle
          createParticles(state, enemy.x + enemy.width/2, enemy.y + enemy.height/2, enemy.color);

          if (enemy.hp <= 0) {
            // Enemy died
            state.enemies.splice(enemyIndex, 1);
            state.kills++;
            state.score += 10 + (state.level * 5);
            
            // Gain XP
            const xpGain = 10 + (state.level * 2);
            state.xp += xpGain;
            
            // Create explosion
            createExplosion(state, enemy.x + enemy.width/2, enemy.y + enemy.height/2);

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
        createParticles(state, player.x + player.width/2, player.y + player.height/2, '#ff4444');
        
        if (player.hp <= 0) {
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
        createParticles(state, player.x + player.width/2, player.y + player.height/2, '#ff8800');
        
        if (player.hp <= 0) {
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
      ctx.font = '48px monospace';
      ctx.textAlign = 'center';
      ctx.fillText('MAGO ROGUELIKE', GAME_CONFIG.width / 2, GAME_CONFIG.height / 2 - 50);
      ctx.font = '24px monospace';
      ctx.fillText('Clique para começar', GAME_CONFIG.width / 2, GAME_CONFIG.height / 2 + 20);
      ctx.fillText('WASD para mover, ESPAÇO para voar', GAME_CONFIG.width / 2, GAME_CONFIG.height / 2 + 60);
      return;
    }

    // Render player (wizard)
    const player = state.player;
    ctx.fillStyle = '#ff6b35';
    ctx.fillRect(player.x, player.y, player.width, player.height);
    
    // Player glow effect
    ctx.shadowColor = '#ff6b35';
    ctx.shadowBlur = 10;
    ctx.fillRect(player.x + 5, player.y + 5, player.width - 10, player.height - 10);
    ctx.shadowBlur = 0;

    // Render bullets
    state.bullets.forEach(bullet => {
      ctx.fillStyle = '#ffff00';
      ctx.shadowColor = '#ffff00';
      ctx.shadowBlur = 5;
      ctx.fillRect(bullet.x, bullet.y, bullet.width, bullet.height);
      ctx.shadowBlur = 0;
    });

    // Render enemies
    state.enemies.forEach(enemy => {
      ctx.fillStyle = enemy.color;
      ctx.shadowColor = enemy.color;
      ctx.shadowBlur = 8;
      ctx.fillRect(enemy.x, enemy.y, enemy.width, enemy.height);
      ctx.shadowBlur = 0;
      
      // Health bar
      const healthPercent = enemy.hp / enemy.maxHp;
      ctx.fillStyle = '#ff0000';
      ctx.fillRect(enemy.x, enemy.y - 8, enemy.width, 4);
      ctx.fillStyle = '#00ff00';
      ctx.fillRect(enemy.x, enemy.y - 8, enemy.width * healthPercent, 4);
    });

    // Render obstacles
    state.obstacles.forEach(obstacle => {
      ctx.fillStyle = '#888888';
      ctx.shadowColor = '#888888';
      ctx.shadowBlur = 5;
      ctx.fillRect(obstacle.x, obstacle.y, obstacle.width, obstacle.height);
      ctx.shadowBlur = 0;
    });

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
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.arc(explosion.x, explosion.y, explosion.radius, 0, Math.PI * 2);
      ctx.stroke();
    });

    // Render ground
    ctx.fillStyle = '#333333';
    ctx.fillRect(0, GAME_CONFIG.height - 20, GAME_CONFIG.width, 20);
  };

  return (
    <div className="game-container">
      <canvas
        ref={canvasRef}
        width={GAME_CONFIG.width}
        height={GAME_CONFIG.height}
        className="game-canvas"
      />
      
      {/* HUD */}
      {gameStarted && (
        <div className="hud">
          <div className="hud-top">
            <div className="health-bar">
              <div className="health-fill" style={{ width: `${(gameStats.hp / gameStats.maxHp) * 100}%` }} />
              <span className="health-text">{gameStats.hp}/{gameStats.maxHp}</span>
            </div>
            <div className="level-info">
              <span>Nível {gameStats.level}</span>
              <div className="xp-bar">
                <div className="xp-fill" style={{ width: `${(gameStats.xp / gameStats.xpToNext) * 100}%` }} />
              </div>
              <span>{gameStats.xp}/{gameStats.xpToNext} XP</span>
            </div>
            <div className="score">
              <span>Pontos: {gameStats.score}</span>
              <span>Kills: {gameStats.kills}</span>
            </div>
          </div>
        </div>
      )}

      {/* Power-up Selection */}
      {showPowerUpSelection && (
        <div className="power-up-selection">
          <div className="power-up-modal">
            <h2>Escolha um Power-up!</h2>
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
            <h2>Game Over!</h2>
            <p>Nível Final: {gameStats.level}</p>
            <p>Pontuação: {gameStats.score}</p>
            <p>Kills: {gameStats.kills}</p>
            <button onClick={() => { resetGame(); startGame(); }}>
              Jogar Novamente
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

export default App;