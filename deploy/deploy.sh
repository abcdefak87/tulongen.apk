#!/bin/bash
# Deploy script for Tulongen APK
# Run this on the server: bash deploy.sh

set -e

echo "=== TULONGEN DEPLOY SCRIPT ==="
echo ""

# Variables
REPO_DIR="$HOME/tulongen.apk"
WEB_DIR="/var/www/tulongen"
APK_SOURCE="$REPO_DIR/deploy/tulongen-latest.apk"
APK_DEST="$WEB_DIR/apk/tulongen-latest.apk"
INDEX_SOURCE="$REPO_DIR/deploy/index.html"
INDEX_DEST="$WEB_DIR/index.html"

# Step 1: Pull latest from GitHub
echo "[1/4] Pulling latest from GitHub..."
cd "$REPO_DIR"
git pull

# Step 2: Copy APK
echo "[2/4] Copying APK..."
if [ -f "$APK_SOURCE" ]; then
    cp "$APK_SOURCE" "$APK_DEST"
    echo "      APK copied: $(ls -lh $APK_DEST | awk '{print $5}')"
else
    echo "      ERROR: APK not found at $APK_SOURCE"
    exit 1
fi

# Step 3: Copy landing page
echo "[3/4] Copying landing page..."
if [ -f "$INDEX_SOURCE" ]; then
    cp "$INDEX_SOURCE" "$INDEX_DEST"
    echo "      index.html copied"
else
    echo "      WARNING: index.html not found"
fi

# Step 4: Set permissions
echo "[4/4] Setting permissions..."
chmod 644 "$APK_DEST"
chmod 644 "$INDEX_DEST" 2>/dev/null || true

echo ""
echo "=== DEPLOY COMPLETE ==="
echo "APK: $APK_DEST"
echo "Web: $INDEX_DEST"
echo ""
echo "Test: https://tulongen.raf.my.id/"
