#!/bin/bash
# Gang NPC Manager - Setup Script
# This script creates necessary directories and files for the resource

echo "🔧 Gang NPC Manager - Setup Script"
echo "=================================="

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
RESOURCE_DIR="$SCRIPT_DIR"

echo "📁 Resource directory: $RESOURCE_DIR"

# Create data directory
DATA_DIR="$RESOURCE_DIR/data"
if [ ! -d "$DATA_DIR" ]; then
    echo "📁 Creating data directory..."
    mkdir -p "$DATA_DIR"
    
    if [ $? -eq 0 ]; then
        echo "✅ Data directory created successfully"
    else
        echo "❌ Failed to create data directory"
        exit 1
    fi
else
    echo "✅ Data directory already exists"
fi

# Create JSON files if they don't exist
JSON_FILES=("npcs.json" "groups.json" "logs.json")

for file in "${JSON_FILES[@]}"; do
    FILE_PATH="$DATA_DIR/$file"
    if [ ! -f "$FILE_PATH" ]; then
        echo "📄 Creating $file..."
        echo "[]" > "$FILE_PATH"
        
        if [ $? -eq 0 ]; then
            echo "✅ $file created successfully"
        else
            echo "❌ Failed to create $file"
        fi
    else
        echo "✅ $file already exists"
    fi
done

# Set permissions
echo "🔐 Setting permissions..."
chmod -R 755 "$DATA_DIR"

if [ $? -eq 0 ]; then
    echo "✅ Permissions set successfully"
else
    echo "❌ Failed to set permissions"
fi

echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "📋 Summary:"
echo "   - Data directory: $DATA_DIR"
echo "   - JSON files: ${JSON_FILES[*]}"
echo "   - Permissions: 755"
echo ""
echo "🚀 Your Gang NPC Manager resource is ready to use!"