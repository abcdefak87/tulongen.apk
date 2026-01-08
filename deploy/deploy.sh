#!/bin/bash
# Tulongen Deploy Script
# Usage: cd ~/tulongen.apk && bash deploy/deploy.sh

git reset --hard
git pull
cp deploy/tulongen-latest.apk /var/www/tulongen/apk/
cp deploy/index.html /var/www/tulongen/
echo "Done!"
