#!/bin/bash

# TULONGEN APK Deploy Script
# Deploy APK ke server Linux dengan Nginx

set -e

# ============ KONFIGURASI ============
APP_NAME="tulongen"
VERSION="1.2.0"
SERVER_USER="root"
SERVER_HOST="172.17.2.3"
SERVER_PATH="/var/www/tulongen"
APK_SOURCE="build/app/outputs/flutter-apk/app-release.apk"
DOMAIN="172.17.2.3"

# ============ WARNA OUTPUT ============
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ============ BUILD APK ============
build_apk() {
    log_info "Building release APK..."
    flutter build apk --release
    
    if [ ! -f "$APK_SOURCE" ]; then
        log_error "APK tidak ditemukan!"
        exit 1
    fi
    
    log_info "APK berhasil dibuild: $APK_SOURCE"
}

# ============ UPLOAD KE SERVER ============
upload_apk() {
    log_info "Uploading APK ke server..."
    
    # Buat direktori di server
    ssh ${SERVER_USER}@${SERVER_HOST} "mkdir -p ${SERVER_PATH}/apk"
    
    # Upload APK dengan nama versi
    scp "$APK_SOURCE" "${SERVER_USER}@${SERVER_HOST}:${SERVER_PATH}/apk/${APP_NAME}-v${VERSION}.apk"
    
    # Buat symlink untuk latest
    ssh ${SERVER_USER}@${SERVER_HOST} "cd ${SERVER_PATH}/apk && ln -sf ${APP_NAME}-v${VERSION}.apk ${APP_NAME}-latest.apk"
    
    log_info "APK berhasil diupload!"
}

# ============ SETUP SERVER (PERTAMA KALI) ============
setup_server() {
    log_info "Setting up server..."
    
    ssh ${SERVER_USER}@${SERVER_HOST} << 'ENDSSH'
        # Install Nginx jika belum ada
        if ! command -v nginx &> /dev/null; then
            apt update && apt install -y nginx
        fi
        
        # Buat direktori
        mkdir -p /var/www/tulongen/apk
        
        # Set permissions
        chown -R www-data:www-data /var/www/tulongen
        chmod -R 755 /var/www/tulongen
ENDSSH
    
    log_info "Server setup selesai!"
}

# ============ SETUP NGINX CONFIG ============
setup_nginx() {
    log_info "Setting up Nginx config..."
    
    ssh ${SERVER_USER}@${SERVER_HOST} << ENDSSH
cat > /etc/nginx/sites-available/tulongen << 'EOF'
server {
    listen 80;
    server_name ${DOMAIN};
    root /var/www/tulongen;
    
    # Download page
    location / {
        index index.html;
    }
    
    # APK files
    location /apk/ {
        alias /var/www/tulongen/apk/;
        autoindex off;
        
        # Force download
        add_header Content-Disposition 'attachment';
        add_header Content-Type 'application/vnd.android.package-archive';
    }
    
    # Direct download link
    location /download {
        return 302 /apk/tulongen-latest.apk;
    }
}
EOF

    ln -sf /etc/nginx/sites-available/tulongen /etc/nginx/sites-enabled/
    nginx -t && systemctl reload nginx
ENDSSH
    
    log_info "Nginx config selesai!"
}

# ============ BUAT LANDING PAGE ============
create_landing_page() {
    log_info "Uploading landing page..."
    
    # Upload landing page dari file lokal
    scp "deploy/index.html" "${SERVER_USER}@${SERVER_HOST}:${SERVER_PATH}/index.html"
    
    log_info "Landing page berhasil diupload!"
}

# ============ MAIN ============
case "$1" in
    build)
        build_apk
        ;;
    upload)
        upload_apk
        ;;
    setup)
        setup_server
        setup_nginx
        create_landing_page
        ;;
    deploy)
        build_apk
        upload_apk
        log_info "Deploy selesai! APK tersedia di: http://${DOMAIN}/download"
        ;;
    *)
        echo "Usage: $0 {build|upload|setup|deploy}"
        echo ""
        echo "Commands:"
        echo "  setup   - Setup server pertama kali (nginx, direktori)"
        echo "  build   - Build APK release"
        echo "  upload  - Upload APK ke server"
        echo "  deploy  - Build + Upload (full deploy)"
        exit 1
        ;;
esac
