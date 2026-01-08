#!/bin/bash
# Tulongen Deploy Script
# Usage: cd ~/tulongen.apk && bash deploy/deploy.sh

set -e

# Pull latest
git reset --hard
git pull

# Generate version string (YYYYMMDDHHMMSS)
VERSION=$(date +%Y%m%d%H%M%S)

# Copy APK with new name
cp deploy/tulongen-latest.apk /var/www/tulongen/apk/tulongen.apk

# Update index.html with new version to bypass Cloudflare cache
sed "s/?v=[0-9]*/?v=$VERSION/g" deploy/index.html > /var/www/tulongen/index.html

echo "Done! Version: $VERSION"
echo "URL: https://tulongen.raf.my.id/apk/tulongen.apk?v=$VERSION"
