# Deploy TULONGEN APK ke Server Linux

## Prasyarat
- Server Linux (Ubuntu/Debian)
- SSH access ke server
- Domain yang sudah pointing ke server

## Konfigurasi

Edit file `deploy.sh` dan ubah:
```bash
SERVER_USER="root"           # Username SSH
SERVER_HOST="your-server.com" # IP atau domain server
SERVER_PATH="/var/www/tulongen"
DOMAIN="download.tulongen.id" # Domain untuk download
VERSION="1.0.0"              # Versi APK
```

## Cara Pakai

### 1. Setup Server (Pertama Kali)
```bash
chmod +x deploy.sh
./deploy.sh setup
```
Ini akan:
- Install Nginx
- Buat direktori `/var/www/tulongen`
- Setup Nginx config
- Buat landing page

### 2. Deploy APK
```bash
./deploy.sh deploy
```
Ini akan:
- Build APK release
- Upload ke server
- APK tersedia di `http://domain/download`

### 3. Command Lainnya
```bash
./deploy.sh build   # Build APK saja
./deploy.sh upload  # Upload saja (tanpa build)
```

## Struktur di Server
```
/var/www/tulongen/
├── index.html              # Landing page
└── apk/
    ├── tulongen-v1.0.0.apk # APK dengan versi
    └── tulongen-latest.apk # Symlink ke versi terbaru
```

## URL Download
- Landing page: `http://domain/`
- Direct download: `http://domain/download`
- APK spesifik: `http://domain/apk/tulongen-v1.0.0.apk`

## SSL (Opsional)
Untuk HTTPS, install Certbot:
```bash
apt install certbot python3-certbot-nginx
certbot --nginx -d download.tulongen.id
```
