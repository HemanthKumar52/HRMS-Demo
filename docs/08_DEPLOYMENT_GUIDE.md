# PPULSE HRMS — Deployment Guide

## 1. Production Backend

### Server Requirements
- Ubuntu 22.04+ or any Linux with Python 3.12+
- 2 vCPUs, 4GB RAM minimum (face verification needs ~200MB for model)
- PostgreSQL 16 (local or managed)
- Nginx as reverse proxy
- SSL certificate (Let's Encrypt recommended)

### Deployment Steps

```bash
# 1. Clone and setup
git clone https://github.com/HemanthKumar52/HRMS-Demo.git
cd HRMS-Demo/ppulse_backend
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt gunicorn

# 2. Environment
cat > .env << 'EOF'
DEBUG=False
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(64))")
DATABASE_URL=postgres://ppulse_user:secure_password@localhost:5432/ppulse_db
ALLOWED_HOSTS=api.yourdomain.com
EOF

# 3. Database
python manage.py migrate
python manage.py createsuperuser
python manage.py collectstatic --noinput

# 4. Gunicorn (systemd service)
cat > /etc/systemd/system/ppulse.service << 'EOF'
[Unit]
Description=PPULSE API
After=network.target postgresql.service

[Service]
User=www-data
WorkingDirectory=/opt/ppulse/ppulse_backend
ExecStart=/opt/ppulse/venv/bin/gunicorn ppulse_backend.wsgi:application \
  --bind 127.0.0.1:8000 --workers 4 --timeout 120
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl enable ppulse && systemctl start ppulse

# 5. Nginx
cat > /etc/nginx/sites-available/ppulse << 'EOF'
server {
    listen 443 ssl;
    server_name api.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/api.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.yourdomain.com/privkey.pem;

    client_max_body_size 10M;

    location /static/ {
        alias /opt/ppulse/ppulse_backend/staticfiles/;
    }

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

ln -s /etc/nginx/sites-available/ppulse /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
```

## 2. Mobile Builds

### Android

```bash
# Release APK (direct install)
flutter build apk --release --dart-define=API_HOST=api.yourdomain.com --dart-define=API_PORT=443

# App Bundle (Google Play)
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS

```bash
# Archive for App Store
flutter build ipa --release

# Output: build/ios/ipa/PPULSE.ipa
# Upload via Xcode Organizer or Transporter app
```

## 3. Credentials for Delivery

Provide to the client:
- APK/IPA file
- API base URL
- Super admin credentials
- PostgreSQL connection string (if self-hosted)

---

**PPULSE Technologies**
