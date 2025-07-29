#!/bin/bash

# BookSphere Ubuntu Server Deployment Script
# This script sets up the complete server environment on Ubuntu

set -e

echo "🚀 BookSphere Ubuntu Server Deployment Starting..."
echo "================================================="

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please do not run this script as root"
    exit 1
fi

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Node.js 18 LTS
echo "📦 Installing Node.js 18 LTS..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PostgreSQL
echo "📦 Installing PostgreSQL..."
sudo apt install -y postgresql postgresql-contrib

# Install PM2 for process management
echo "📦 Installing PM2..."
sudo npm install -g pm2

# Install Nginx
echo "📦 Installing Nginx..."
sudo apt install -y nginx

# Install Git (if not present)
echo "📦 Installing Git..."
sudo apt install -y git

# Create app user
echo "👤 Creating app user..."
sudo useradd -m -s /bin/bash bookuser || echo "User already exists"

# Create application directory
echo "📁 Setting up application directory..."
sudo mkdir -p /opt/bookphere
sudo chown bookuser:bookuser /opt/bookphere

# Setup PostgreSQL database
echo "🗄️ Setting up PostgreSQL..."
sudo -u postgres psql -c "CREATE USER bookuser WITH PASSWORD 'bookphere123';" || echo "User exists"
sudo -u postgres psql -c "CREATE DATABASE bookphere OWNER bookuser;" || echo "Database exists"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE bookphere TO bookuser;"

# Copy server files
echo "📋 Copying server files..."
sudo cp -r ./server/* /opt/bookphere/
sudo chown -R bookuser:bookuser /opt/bookphere

# Install dependencies
echo "📦 Installing server dependencies..."
cd /opt/bookphere
sudo -u bookuser npm install

# Build server
echo "🔨 Building server..."
sudo -u bookuser npm run build

# Create environment file
echo "⚙️ Creating environment configuration..."
sudo -u bookuser cat > /opt/bookphere/.env << EOF
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://bookuser:bookphere123@localhost:5432/bookphere
JWT_SECRET=$(openssl rand -hex 32)
JWT_REFRESH_SECRET=$(openssl rand -hex 32)
JWT_ACCESS_EXPIRY=15m
JWT_REFRESH_EXPIRY=7d
CORS_ORIGIN=*
RATE_LIMIT_WINDOW=900000
RATE_LIMIT_MAX=100
UPLOAD_PATH=/opt/bookphere/uploads
SIGNED_URL_EXPIRY=120
EOF

# Create uploads directory
echo "📁 Creating uploads directory..."
sudo -u bookuser mkdir -p /opt/bookphere/uploads/{books,music,backgrounds,temp}

# Setup PM2 ecosystem
echo "⚙️ Setting up PM2 ecosystem..."
sudo -u bookuser cat > /opt/bookphere/ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'bookphere-server',
    script: './dist/server.js',
    cwd: '/opt/bookphere',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: '/var/log/bookphere/error.log',
    out_file: '/var/log/bookphere/access.log',
    log_file: '/var/log/bookphere/combined.log',
    time: true,
    max_memory_restart: '1G',
    restart_delay: 5000
  }]
};
EOF

# Create log directory
echo "📝 Setting up logging..."
sudo mkdir -p /var/log/bookphere
sudo chown bookuser:bookuser /var/log/bookphere

# Setup Nginx configuration
echo "🌐 Configuring Nginx..."
sudo cat > /etc/nginx/sites-available/bookphere << EOF
server {
    listen 80;
    server_name _;
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    
    # Client upload size
    client_max_body_size 100M;
    
    # API routes
    location /api/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # WebSocket routes
    location /socket.io/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Serve static files (web client)
    location / {
        root /var/www/bookphere;
        try_files \$uri \$uri/ /index.html;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # File uploads
    location /uploads/ {
        alias /opt/bookphere/uploads/;
        expires 1d;
    }
}
EOF

# Enable site
sudo ln -sf /etc/nginx/sites-available/bookphere /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# Create web directory
sudo mkdir -p /var/www/bookphere
sudo chown www-data:www-data /var/www/bookphere

# Setup firewall
echo "🔒 Configuring firewall..."
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

# Start services
echo "🚀 Starting services..."
sudo systemctl enable nginx
sudo systemctl start nginx
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Start PM2
sudo -u bookuser pm2 start /opt/bookphere/ecosystem.config.js
sudo -u bookuser pm2 save
sudo -u bookuser pm2 startup

# Create systemd service for PM2
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u bookuser --hp /home/bookuser

echo ""
echo "✅ Ubuntu Server Deployment Complete!"
echo "======================================"
echo ""
echo "🌐 Server is running on port 80"
echo "📊 Monitor with: sudo -u bookuser pm2 monit"
echo "📝 Logs: sudo -u bookuser pm2 logs"
echo "🔄 Restart: sudo -u bookuser pm2 restart bookphere-server"
echo ""
echo "📋 Next Steps:"
echo "1. Deploy web client to /var/www/bookphere"
echo "2. Configure SSL certificate (Let's Encrypt recommended)"
echo "3. Set up monitoring and backups"
echo ""
echo "🔗 Access your application at: http://your-server-ip"
echo ""