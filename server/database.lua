-- Database management system

Database = {}

-- Initialize database
function Database.Init()
    if Config.Database.UseMySQL then
        Database.InitMySQL()
    else
        Database.InitJSON()
    end
end

-- Initialize MySQL tables
function Database.InitMySQL()
    local queries = {
        -- NPCs table
        string.format([[
            CREATE TABLE IF NOT EXISTS %snpcs (
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
            )
        ]], Config.Database.TablePrefix),
        
        -- Advanced Groups table
        string.format([[
            CREATE TABLE IF NOT EXISTS %sgroups (
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
            )
        ]], Config.Database.TablePrefix),
        
        -- Activity logs table
        string.format([[
            CREATE TABLE IF NOT EXISTS %slogs (
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
            )
        ]], Config.Database.TablePrefix)
    }
    
    for _, query in ipairs(queries) do
        MySQL.query(query, {}, function(success)
            if not success then
                print('^1[Gang NPC Manager] Erro ao criar tabela: ' .. query:sub(1, 100) .. '...^7')
            end
        end)
    end
    
    Utils.Debug('MySQL database initialized')
end

-- Initialize JSON file system
function Database.InitJSON()
    -- Get resource path and create data directory
    local resourcePath = GetResourcePath(GetCurrentResourceName())
    local dataDir = resourcePath .. '/data/'
    
    -- Try to create data directory if it doesn't exist
    local success, err = pcall(function()
        os.execute('mkdir -p "' .. dataDir .. '"')
    end)
    
    if not success then
        Utils.Debug('Warning: Could not create data directory:', err)
        Utils.Debug('Please manually create the data folder in your resource directory')
    end
    
    -- Define file paths
    Database.JSONFiles = {
        npcs = dataDir .. 'npcs.json',
        groups = dataDir .. 'groups.json',
        logs = dataDir .. 'logs.json'
    }
    
    -- Check and create files if they don't exist
    for fileName, filePath in pairs(Database.JSONFiles) do
        local file = io.open(filePath, 'r')
        if not file then
            -- Create empty file with valid JSON array
            Utils.Debug('Creating missing JSON file:', fileName)
            file = io.open(filePath, 'w')
            if file then
                file:write('[]')
                file:close()
                Utils.Debug('Created JSON file: ' .. fileName)
            else
                Utils.Debug('ERROR: Could not create JSON file: ' .. fileName)
                Utils.Debug('Please ensure the data directory exists and has write permissions')
            end
        else
            file:close()
            Utils.Debug('JSON file exists: ' .. fileName)
        end
    end
    
    Utils.Debug('JSON database initialized with fallback support')
end

-- NPC CRUD operations
function Database.CreateNPC(npcData, callback)
    if Config.Database.UseMySQL then
        local query = string.format([[
            INSERT INTO %snpcs (
                id, gang, model, position, heading, health, armor, accuracy, weapon,
                state, owners, leaders, friends, enemies, group_id, advanced_group_id,
                created_at, last_updated
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]], Config.Database.TablePrefix)
        
        local params = {
            npcData.id,
            npcData.gang,
            npcData.model,
            json.encode(npcData.position),
            npcData.heading or 0.0,
            npcData.health or 100,
            npcData.armor or 0,
            npcData.accuracy or 50,
            npcData.weapon,
            npcData.state or 'idle',
            json.encode(npcData.owners or {}),
            json.encode(npcData.leaders or {}),
            json.encode(npcData.friends or {}),
            json.encode(npcData.enemies or {}),
            npcData.group_id,
            npcData.advanced_group_id,
            os.time(),
            os.time()
        }
        
        MySQL.insert(query, params, function(insertId)
            if callback then callback(insertId ~= nil) end
        end)
    else
        Database.JSONCreate('npcs', npcData, callback)
    end
end

function Database.GetNPC(npcId, callback)
    if Config.Database.UseMySQL then
        local query = string.format('SELECT * FROM %snpcs WHERE id = ?', Config.Database.TablePrefix)
        MySQL.single(query, {npcId}, function(result)
            if result then
                -- Parse JSON fields
                result.position = json.decode(result.position)
                result.owners = json.decode(result.owners or '[]')
                result.leaders = json.decode(result.leaders or '[]')
                result.friends = json.decode(result.friends or '[]')
                result.enemies = json.decode(result.enemies or '[]')
            end
            if callback then callback(result) end
        end)
    else
        Database.JSONGet('npcs', npcId, callback)
    end
end

function Database.GetAllNPCs(callback)
    if Config.Database.UseMySQL then
        local query = string.format('SELECT * FROM %snpcs ORDER BY created_at DESC', Config.Database.TablePrefix)
        MySQL.query(query, {}, function(results)
            if results then
                for _, npc in ipairs(results) do
                    npc.position = json.decode(npc.position)
                    npc.owners = json.decode(npc.owners or '[]')
                    npc.leaders = json.decode(npc.leaders or '[]')
                    npc.friends = json.decode(npc.friends or '[]')
                    npc.enemies = json.decode(npc.enemies or '[]')
                end
            end
            if callback then callback(results or {}) end
        end)
    else
        Database.JSONGetAll('npcs', callback)
    end
end

function Database.UpdateNPC(npcId, updateData, callback)
    if Config.Database.UseMySQL then
        local setParts = {}
        local params = {}
        
        for key, value in pairs(updateData) do
            if key == 'position' or key == 'owners' or key == 'leaders' or key == 'friends' or key == 'enemies' then
                table.insert(setParts, key .. ' = ?')
                table.insert(params, json.encode(value))
            else
                table.insert(setParts, key .. ' = ?')
                table.insert(params, value)
            end
        end
        
        -- Add last_updated
        table.insert(setParts, 'last_updated = ?')
        table.insert(params, os.time())
        
        -- Add WHERE clause parameter
        table.insert(params, npcId)
        
        local query = string.format('UPDATE %snpcs SET %s WHERE id = ?', 
            Config.Database.TablePrefix, table.concat(setParts, ', '))
        
        MySQL.update(query, params, function(affectedRows)
            if callback then callback(affectedRows > 0) end
        end)
    else
        Database.JSONUpdate('npcs', npcId, updateData, callback)
    end
end

function Database.DeleteNPC(npcId, callback)
    if Config.Database.UseMySQL then
        local query = string.format('DELETE FROM %snpcs WHERE id = ?', Config.Database.TablePrefix)
        MySQL.update(query, {npcId}, function(affectedRows)
            if callback then callback(affectedRows > 0) end
        end)
    else
        Database.JSONDelete('npcs', npcId, callback)
    end
end

function Database.GetPlayerNPCs(playerId, callback)
    if Config.Database.UseMySQL then
        local query = string.format([[
            SELECT * FROM %snpcs 
            WHERE JSON_CONTAINS(owners, JSON_QUOTE(?))
               OR JSON_CONTAINS(leaders, JSON_QUOTE(?))
               OR JSON_CONTAINS(friends, JSON_QUOTE(?))
            ORDER BY created_at DESC
        ]], Config.Database.TablePrefix)
        
        local playerIdStr = tostring(playerId)
        MySQL.query(query, {playerIdStr, playerIdStr, playerIdStr}, function(results)
            if results then
                for _, npc in ipairs(results) do
                    npc.position = json.decode(npc.position)
                    npc.owners = json.decode(npc.owners or '[]')
                    npc.leaders = json.decode(npc.leaders or '[]')
                    npc.friends = json.decode(npc.friends or '[]')
                    npc.enemies = json.decode(npc.enemies or '[]')
                end
            end
            if callback then callback(results or {}) end
        end)
    else
        Database.JSONGetPlayerItems('npcs', playerId, callback)
    end
end

-- Group CRUD operations
function Database.CreateGroup(groupData, callback)
    if Config.Database.UseMySQL then
        local query = string.format([[
            INSERT INTO %sgroups (
                id, name, description, gang, members, auto_defend, auto_attack_enemies,
                patrol_area, created_by, created_at, last_updated
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]], Config.Database.TablePrefix)
        
        local params = {
            groupData.id,
            groupData.name,
            groupData.description or '',
            groupData.gang,
            json.encode(groupData.members or {}),
            groupData.auto_defend or true,
            groupData.auto_attack_enemies or true,
            json.encode(groupData.patrol_area),
            groupData.created_by,
            os.time(),
            os.time()
        }
        
        MySQL.insert(query, params, function(insertId)
            if callback then callback(insertId ~= nil) end
        end)
    else
        Database.JSONCreate('groups', groupData, callback)
    end
end

function Database.GetAllGroups(callback)
    if Config.Database.UseMySQL then
        local query = string.format('SELECT * FROM %sgroups ORDER BY created_at DESC', Config.Database.TablePrefix)
        MySQL.query(query, {}, function(results)
            if results then
                for _, group in ipairs(results) do
                    group.members = json.decode(group.members or '[]')
                    group.patrol_area = json.decode(group.patrol_area or 'null')
                end
            end
            if callback then callback(results or {}) end
        end)
    else
        Database.JSONGetAll('groups', callback)
    end
end

-- Log operations
function Database.CreateLog(logData, callback)
    logData.timestamp = os.time()
    
    if Config.Database.UseMySQL then
        local query = string.format([[
            INSERT INTO %slogs (action, player_id, npc_id, group_id, data, timestamp)
            VALUES (?, ?, ?, ?, ?, ?)
        ]], Config.Database.TablePrefix)
        
        local params = {
            logData.action,
            logData.player_id,
            logData.npc_id,
            logData.group_id,
            json.encode(logData.data or {}),
            logData.timestamp
        }
        
        MySQL.insert(query, params, function(insertId)
            if callback then callback(insertId ~= nil) end
        end)
    else
        Database.JSONCreate('logs', logData, callback)
    end
end

-- JSON file operations (fallback)
function Database.JSONCreate(tableName, data, callback)
    local filePath = Database.JSONFiles[tableName]
    local file = io.open(filePath, 'r')
    if not file then
        if callback then callback(false) end
        return
    end
    
    local content = file:read('*all')
    file:close()
    
    local tableData = json.decode(content) or {}
    data.created_at = data.created_at or os.time()
    data.last_updated = os.time()
    
    table.insert(tableData, data)
    
    file = io.open(filePath, 'w')
    if file then
        file:write(json.encode(tableData))
        file:close()
        if callback then callback(true) end
    else
        if callback then callback(false) end
    end
end

function Database.JSONGet(tableName, id, callback)
    local filePath = Database.JSONFiles[tableName]
    local file = io.open(filePath, 'r')
    if not file then
        if callback then callback(nil) end
        return
    end
    
    local content = file:read('*all')
    file:close()
    
    local tableData = json.decode(content) or {}
    
    for _, item in ipairs(tableData) do
        if item.id == id then
            if callback then callback(item) end
            return
        end
    end
    
    if callback then callback(nil) end
end

function Database.JSONGetAll(tableName, callback)
    local filePath = Database.JSONFiles[tableName]
    local file = io.open(filePath, 'r')
    if not file then
        if callback then callback({}) end
        return
    end
    
    local content = file:read('*all')
    file:close()
    
    local tableData = json.decode(content) or {}
    if callback then callback(tableData) end
end

function Database.JSONUpdate(tableName, id, updateData, callback)
    local filePath = Database.JSONFiles[tableName]
    local file = io.open(filePath, 'r')
    if not file then
        if callback then callback(false) end
        return
    end
    
    local content = file:read('*all')
    file:close()
    
    local tableData = json.decode(content) or {}
    local found = false
    
    for i, item in ipairs(tableData) do
        if item.id == id then
            -- Update the item
            for key, value in pairs(updateData) do
                tableData[i][key] = value
            end
            tableData[i].last_updated = os.time()
            found = true
            break
        end
    end
    
    if found then
        file = io.open(filePath, 'w')
        if file then
            file:write(json.encode(tableData))
            file:close()
            if callback then callback(true) end
        else
            if callback then callback(false) end
        end
    else
        if callback then callback(false) end
    end
end

function Database.JSONDelete(tableName, id, callback)
    local filePath = Database.JSONFiles[tableName]
    local file = io.open(filePath, 'r')
    if not file then
        if callback then callback(false) end
        return
    end
    
    local content = file:read('*all')
    file:close()
    
    local tableData = json.decode(content) or {}
    local found = false
    
    for i, item in ipairs(tableData) do
        if item.id == id then
            table.remove(tableData, i)
            found = true
            break
        end
    end
    
    if found then
        file = io.open(filePath, 'w')
        if file then
            file:write(json.encode(tableData))
            file:close()
            if callback then callback(true) end
        else
            if callback then callback(false) end
        end
    else
        if callback then callback(false) end
    end
end

function Database.JSONGetPlayerItems(tableName, playerId, callback)
    Database.JSONGetAll(tableName, function(items)
        local result = {}
        local playerIdStr = tostring(playerId)
        
        for _, item in ipairs(items) do
            -- Check if player is in owners, leaders, or friends
            if item.owners then
                for _, ownerId in ipairs(item.owners) do
                    if tostring(ownerId) == playerIdStr then
                        table.insert(result, item)
                        goto continue
                    end
                end
            end
            if item.leaders then
                for _, leaderId in ipairs(item.leaders) do
                    if tostring(leaderId) == playerIdStr then
                        table.insert(result, item)
                        goto continue
                    end
                end
            end
            if item.friends then
                for _, friendId in ipairs(item.friends) do
                    if tostring(friendId) == playerIdStr then
                        table.insert(result, item)
                        goto continue
                    end
                end
            end
            ::continue::
        end
        
        if callback then callback(result) end
    end)
end

-- Initialize on resource start
CreateThread(function()
    Wait(1000) -- Wait for dependencies
    Database.Init()
end)