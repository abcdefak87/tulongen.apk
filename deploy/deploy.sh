#!/bin/bash
# Tulongen Deploy Script
# Server: root@unnetserver
# Domain: https://tulongen.raf.my.id/

cd ~/tulongen.apk
git pull
cp tolong_menolong/deploy/tulongen-latest.apk /var/www/tulongen/apk/
cp tolong_menolong/deploy/index.html /var/www/tulongen/
echo "Done! APK & landing page updated."
