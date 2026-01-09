#!/bin/bash
# Tulongen Deploy Script
# Usage: cd ~/tulongen.apk && bash deploy/deploy.sh

set -e

echo "=== Tulongen Deploy ==="

# 1. Update repo
echo "[1/4] Updating repo..."
git reset --hard
git pull

# 2. Generate version timestamp
VERSION=$(date +%Y%m%d%H%M%S)
echo "[2/4] Version: $VERSION"

# 3. Copy APK with new name (bypass cache)
echo "[3/4] Copying APK..."
rm -f /var/www/tulongen/apk/*.apk
cp deploy/tulongen-latest.apk "/var/www/tulongen/apk/tulongen-${VERSION}.apk"

# 4. Update index.html with new APK filename
echo "[4/4] Updating index.html..."
sed "s|/apk/tulongen-[^\"]*\.apk|/apk/tulongen-${VERSION}.apk|g" deploy/index.html > /var/www/tulongen/index.html

# Show result
echo ""
echo "=== Deploy Complete ==="
echo "APK: /var/www/tulongen/apk/tulongen-${VERSION}.apk"
echo "URL: https://tulongen.raf.my.id/apk/tulongen-${VERSION}.apk"
ls -la /var/www/tulongen/apk/
md5sum /var/www/tulongen/apk/*.apk
