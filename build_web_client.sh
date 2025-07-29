#!/bin/bash

# BookSphere Web Client Build Script
# Builds the Flutter web client for deployment

set -e

echo "🌐 Building BookSphere Web Client..."
echo "===================================="

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed"
    echo "📋 Installing Flutter..."
    
    # Download Flutter
    wget -O flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz
    tar xf flutter.tar.xz
    export PATH="$PWD/flutter/bin:$PATH"
    
    # Add to PATH permanently
    echo 'export PATH="$PWD/flutter/bin:$PATH"' >> ~/.bashrc
    
    # Accept licenses
    flutter doctor --android-licenses
fi

# Navigate to client directory
cd client

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Build for web
echo "🔨 Building web application..."
flutter build web --release --web-renderer html

# Create deployment ready structure
echo "📁 Preparing deployment structure..."
mkdir -p ../web-deploy
cp -r build/web/* ../web-deploy/

# Create Nginx configuration
echo "⚙️ Creating web-specific Nginx config..."
cat > ../web-deploy/nginx.conf << EOF
server {
    listen 80;
    server_name _;
    root /var/www/bookphere;
    index index.html;
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy strict-origin-when-cross-origin;
    
    # Flutter web specific
    location / {
        try_files \$uri \$uri/ /index.html;
        expires 1h;
        add_header Cache-Control "public, no-cache, must-revalidate";
    }
    
    # Static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # API proxy (adjust server_ip as needed)
    location /api/ {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # WebSocket proxy
    location /socket.io/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
    }
}
EOF

# Create deployment script
cat > ../deploy_web_to_server.sh << 'EOF'
#!/bin/bash

# Deploy web client to Ubuntu server
# Usage: ./deploy_web_to_server.sh [server_ip] [ssh_user]

SERVER_IP=${1:-localhost}
SSH_USER=${2:-ubuntu}

echo "🚀 Deploying web client to server..."

if [ "$SERVER_IP" != "localhost" ]; then
    # Remote deployment
    echo "📤 Uploading to $SERVER_IP..."
    rsync -avz --delete web-deploy/ $SSH_USER@$SERVER_IP:/tmp/bookphere-web/
    
    ssh $SSH_USER@$SERVER_IP << 'ENDSSH'
        # Move files to web directory
        sudo rm -rf /var/www/bookphere/*
        sudo cp -r /tmp/bookphere-web/* /var/www/bookphere/
        sudo chown -R www-data:www-data /var/www/bookphere
        sudo chmod -R 755 /var/www/bookphere
        
        # Update Nginx if needed
        if [ -f /tmp/bookphere-web/nginx.conf ]; then
            sudo cp /tmp/bookphere-web/nginx.conf /etc/nginx/sites-available/bookphere
            sudo nginx -t && sudo systemctl reload nginx
        fi
        
        # Cleanup
        rm -rf /tmp/bookphere-web
ENDSSH
else
    # Local deployment
    echo "📁 Deploying locally..."
    sudo cp -r web-deploy/* /var/www/bookphere/
    sudo chown -R www-data:www-data /var/www/bookphere
    sudo chmod -R 755 /var/www/bookphere
fi

echo "✅ Web client deployed successfully!"
EOF

chmod +x ../deploy_web_to_server.sh

echo ""
echo "✅ Web Client Build Complete!"
echo "============================="
echo ""
echo "📁 Built files: ../web-deploy/"
echo "🚀 Deploy script: ../deploy_web_to_server.sh"
echo ""
echo "📋 To deploy:"
echo "   Local:  ./deploy_web_to_server.sh"
echo "   Remote: ./deploy_web_to_server.sh SERVER_IP SSH_USER"
echo ""