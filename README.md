# 🧙‍♂️ Mago Roguelike - Jogo Web Completo

Um jogo roguelike épico desenvolvido em React com HTML5 Canvas, onde você controla um mago poderoso enfrentando ondas de inimigos!

## 🎮 [JOGAR AGORA](https://rprporigins.github.io/npc_control)

## 🚀 Funcionalidades

### ⚡ Mecânicas de Jogo
- **Sistema de Ondas Progressivas** - Enfrente ondas estruturadas de inimigos
- **5 Tipos de Inimigos Únicos**:
  - 🟢 **Basic** - Movimento simples descendente
  - 🔵 **Zigzag** - Movimento em padrão de onda
  - 🟠 **Shooter** - Atira projéteis no jogador
  - ⚫ **Tank** - Lento mas muito resistente
  - 🟣 **Teleporter** - Teleporta com efeitos mágicos
- **Bosses Épicos** - Chefes a cada 5 ondas com múltiplas fases de ataque
- **Sistema de Física Realista** - Gravidade, momentum e colisões precisas

### 🌟 Sistema de Power-ups
Power-ups organizados por raridade com efeitos únicos:
- 🟩 **Comuns** - Melhorias básicas (dano, vida, velocidade)
- 🟦 **Incomuns** - Habilidades intermediárias (perfuração, cadência)
- 🟪 **Raros** - Efeitos especiais (explosões, correntes elétricas)
- 🟧 **Épicos** - Poderes avançados (chuva arcana, tiro triplo)
- 🟨 **Lendários** - Habilidades únicas (magia viva, orbe apocalíptico)

### 💫 Efeitos Visuais
- **Sistema de Partículas Avançado** - Fire, smoke, explosion, magic
- **Screen Shake Dinâmico** - Feedback tátil baseado em intensidade de dano
- **Efeitos Neon** - Visual pixelado com cores vibrantes
- **Animações Fluidas** - 60 FPS com Canvas otimizado

## 🎯 Como Jogar

### Controles
- **WASD** - Mover o mago
- **ESPAÇO** - Pular/Voar brevemente
- **MOUSE** - Mirar (tiro automático na direção do cursor)
- **CLIQUE** - Iniciar jogo

### Objetivo
- Sobreviva às ondas de inimigos
- Colete XP matando inimigos
- Evolua escolhendo power-ups ao subir de nível
- Enfrente bosses épicos a cada 5 ondas
- Alcance a maior pontuação possível!

## 🛠️ Tecnologias Utilizadas

- **React 18** - Framework principal
- **HTML5 Canvas** - Renderização de jogo
- **JavaScript ES6+** - Lógica do jogo
- **CSS3** - Styling e animações
- **Canvas API** - Física e renderização

## 🏗️ Estrutura do Projeto

```
/
├── frontend/
│   ├── src/
│   │   ├── App.js          # Lógica principal do jogo
│   │   ├── App.css         # Estilos do jogo
│   │   ├── index.js        # Entry point
│   │   └── index.css       # Estilos globais
│   ├── public/
│   │   └── index.html      # HTML principal
│   └── package.json        # Dependências
├── index.html              # Landing page
└── README.md              # Este arquivo
```

## 🚀 Como Executar Localmente

### Pré-requisitos
- Node.js 16+
- npm ou yarn

### Instalação
```bash
# Clone o repositório
git clone https://github.com/rprporigins/npc_control.git
cd npc_control

# Instale as dependências
cd frontend
npm install

# Execute o jogo
npm start
```

O jogo estará disponível em `http://localhost:3000`

## 🌐 Deploy no GitHub Pages

### Opção 1: Deploy Manual
1. Faça build do projeto:
```bash
cd frontend
npm run build
```

2. Copie os arquivos da pasta `build/` para a raiz do repositório
3. Commit e push para o GitHub
4. Ative GitHub Pages nas configurações do repositório

### Opção 2: Deploy Automático
Adicione este workflow em `.github/workflows/deploy.yml`:

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Setup Node.js
      uses: actions/setup-node@v2
      with:
        node-version: '18'
        
    - name: Install dependencies
      run: |
        cd frontend
        npm install
        
    - name: Build
      run: |
        cd frontend
        npm run build
        
    - name: Deploy
      uses: peaceiris/actions-gh-pages@v3
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        publish_dir: ./frontend/build
```

## 🎨 Customização

### Modificar Dificuldade
Edite as constantes em `App.js`:
```javascript
const GAME_CONFIG = {
  enemySpawnRate: 2000,    // Velocidade de spawn
  fireRate: 100,           // Velocidade de tiro
  xpPerLevel: 100,         // XP necessário por nível
  // ...
};
```

### Adicionar Novos Power-ups
Adicione em `POWER_UPS` em `App.js` e implemente a lógica em `applyPowerUp()`.

### Modificar Tipos de Inimigos
Edite `createEnemyOfType()` e `updateEnemyBehavior()` para novos comportamentos.

## 🐛 Problemas Conhecidos

- Performance pode diminuir com muitas partículas ativas
- Alguns power-ups ainda precisam de implementação completa
- Boss AI pode ser melhorada

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📜 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## 👨‍💻 Desenvolvedor

Desenvolvido com ❤️ e muito café ☕

---

**⭐ Se você gostou do jogo, dê uma estrela no repositório!**

## 🎯 Próximas Funcionalidades

- [ ] Sistema de som com Web Audio API
- [ ] Diferentes tipos de magia (fogo, gelo, raio)
- [ ] Sistema de combo e multiplicadores
- [ ] Dash/dodge com cooldown
- [ ] Loja com moedas e upgrades permanentes
- [ ] Sistema de conquistas
- [ ] Leaderboard local
- [ ] Backgrounds parallax animados
- [ ] Save/load system

---

🎮 **[CLIQUE AQUI PARA JOGAR!](https://SEU_USUARIO.github.io/SEU_REPOSITORIO)**