#!/bin/bash
# Tulongen Deploy Script
# Usage: cd ~/tulongen.apk && bash deploy/deploy.sh

set -e

git reset --hard
git pull

VERSION=$(date +%Y%m%d%H%M%S)

# Copy APK
cp deploy/tulongen-latest.apk /var/www/tulongen/apk/tulongen.apk

# Update version in index.html and copy
sed "s/tulongen\.apk?v=[0-9]*/tulongen.apk?v=$VERSION/g" deploy/index.html > /var/www/tulongen/index.html

echo "Done! v=$VERSION"
