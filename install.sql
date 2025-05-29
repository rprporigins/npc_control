-- Gang NPC Manager - Database Installation Script
-- Execute this SQL script in your MariaDB/MySQL database

-- Create NPCs table
CREATE TABLE IF NOT EXISTS gang_npc_npcs (
    id VARCHAR(50) PRIMARY KEY,
    gang VARCHAR(50) NOT NULL,
    model VARCHAR(100) NOT NULL,
    position JSON NOT NULL,
    heading FLOAT DEFAULT 0.0,
    health INT DEFAULT 100,
    armor INT DEFAULT 0,
    accuracy INT DEFAULT 50,
    weapon VARCHAR(100),
    state VARCHAR(50) DEFAULT 'idle',
    owners JSON,
    leaders JSON,
    friends JSON,
    enemies JSON,
    group_id VARCHAR(50),
    advanced_group_id VARCHAR(50),
    last_command VARCHAR(50),
    last_command_by VARCHAR(50),
    created_at BIGINT,
    last_updated BIGINT,
    INDEX idx_gang (gang),
    INDEX idx_group (group_id),
    INDEX idx_advanced_group (advanced_group_id),
    INDEX idx_created (created_at)
);

-- Create Advanced Groups table
CREATE TABLE IF NOT EXISTS gang_npc_groups (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    gang VARCHAR(50) NOT NULL,
    members JSON,
    auto_defend BOOLEAN DEFAULT TRUE,
    auto_attack_enemies BOOLEAN DEFAULT TRUE,
    patrol_area JSON,
    created_by VARCHAR(50),
    created_at BIGINT,
    last_updated BIGINT,
    INDEX idx_gang (gang),
    INDEX idx_created_by (created_by),
    INDEX idx_created (created_at)
);

-- Create Activity logs table
CREATE TABLE IF NOT EXISTS gang_npc_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    action VARCHAR(100) NOT NULL,
    player_id VARCHAR(50),
    npc_id VARCHAR(50),
    group_id VARCHAR(50),
    data JSON,
    timestamp BIGINT,
    INDEX idx_action (action),
    INDEX idx_player (player_id),
    INDEX idx_timestamp (timestamp)
);

-- Insert sample data (optional)
-- Sample advanced group
INSERT IGNORE INTO gang_npc_groups (id, name, description, gang, members, auto_defend, auto_attack_enemies, created_by, created_at, last_updated) VALUES 
('sample-ballas-group', 'Elite Ballas Squad', 'Grupo elite dos Ballas para missões especiais', 'ballas', 
'[{"type": "player_id", "value": "1", "role": "owner"}, {"type": "job", "value": "police", "role": "enemy"}]', 
TRUE, TRUE, 'system', UNIX_TIMESTAMP(), UNIX_TIMESTAMP());

-- Sample log entry
INSERT IGNORE INTO gang_npc_logs (action, player_id, data, timestamp) VALUES 
('system_initialized', 'system', '{"message": "Gang NPC Manager installed successfully"}', UNIX_TIMESTAMP());

-- Show tables created
SHOW TABLES LIKE 'gang_npc_%';

-- Show table structures
DESCRIBE gang_npc_npcs;
DESCRIBE gang_npc_groups;
DESCRIBE gang_npc_logs;

-- Success message
SELECT 'Gang NPC Manager database installed successfully!' as message;
