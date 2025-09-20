#!/bin/bash

# AutoFix Pro Deployment Script for Digital Ocean
# This script sets up and deploys the application on a fresh droplet

set -e  # Exit on any error

echo "🚀 Starting AutoFix Pro deployment..."

# Update system packages
echo "📦 Updating system packages..."
apt update && apt upgrade -y

# Install required packages
echo "🔧 Installing required packages..."
apt install -y curl git nginx python3 python3-pip python3-venv nodejs npm

# Install PM2 for process management
echo "📋 Installing PM2..."
npm install -g pm2

# Create application directory
APP_DIR="/var/www/autofix-pro"
echo "📁 Setting up application directory: $APP_DIR"
mkdir -p $APP_DIR
cd $APP_DIR

# Clone or update repository
if [ -d ".git" ]; then
    echo "🔄 Updating existing repository..."
    git pull origin main
else
    echo "📥 Cloning repository..."
    git clone https://github.com/cmishler108/autofix-pro-digital-ocean-code.git .
fi

# Setup Frontend (Next.js)
echo "🎨 Setting up frontend..."
cd fr
npm ci
npm run build

# Configure PM2 for frontend
echo "⚙️ Configuring PM2 for frontend..."
pm2 delete autofix-pro-frontend 2>/dev/null || true
pm2 start npm --name "autofix-pro-frontend" -- start
pm2 save

# Setup Backend (Django)
echo "🐍 Setting up backend..."
cd ../DoneEZ/DoneEZ

if [ -f "requirements.txt" ]; then
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    
    # Run migrations
    python manage.py migrate
    
    # Collect static files
    python manage.py collectstatic --noinput
    
    # Configure PM2 for backend
    echo "⚙️ Configuring PM2 for backend..."
    pm2 delete autofix-pro-backend 2>/dev/null || true
    pm2 start --name "autofix-pro-backend" --interpreter python3 manage.py -- runserver 0.0.0.0:8000
    pm2 save
fi

# Configure Nginx
echo "🌐 Configuring Nginx..."
cat > /etc/nginx/sites-available/autofix-pro << 'EOF'
server {
    listen 80;
    server_name 104.236.4.217;

    # Frontend (Next.js)
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Backend API (Django)
    location /api/ {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Static files
    location /static/ {
        alias /var/www/autofix-pro/DoneEZ/DoneEZ/static/;
    }
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/autofix-pro /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test and restart Nginx
nginx -t && systemctl restart nginx

# Setup PM2 startup
pm2 startup
pm2 save

# Setup firewall
echo "🔒 Configuring firewall..."
ufw allow ssh
ufw allow 'Nginx Full'
ufw --force enable

echo "✅ Deployment completed successfully!"
echo "🌐 Your application should be accessible at: http://104.236.4.217"
echo "📊 Monitor processes with: pm2 status"
echo "📝 View logs with: pm2 logs"