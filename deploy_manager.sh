#!/bin/bash

# BookSphere Universal Deployment Manager
# Manages all deployment scenarios for different platforms

set -e

echo "🚀 BookSphere Universal Deployment Manager"
echo "=========================================="
echo ""

# Function to display menu
show_menu() {
    echo "📋 Select deployment option:"
    echo ""
    echo "🖥️  Server Deployments:"
    echo "   1) Ubuntu Server (Complete setup)"
    echo "   2) Ubuntu Server (Update only)"
    echo ""
    echo "🌐 Web Client:"
    echo "   3) Build Web Client"
    echo "   4) Deploy Web to Server"
    echo ""
    echo "📱 Mobile & Desktop:"
    echo "   5) Build Android APK"
    echo "   6) Build Windows EXE"
    echo ""
    echo "🔧 Utilities:"
    echo "   7) Test All Components"
    echo "   8) Server Health Check"
    echo "   9) Clean All Builds"
    echo ""
    echo "   0) Exit"
    echo ""
}

# Function to check prerequisites
check_prerequisites() {
    echo "🔍 Checking prerequisites..."
    
    # Check if we're in the right directory
    if [ ! -f "server/package.json" ] || [ ! -f "client/pubspec.yaml" ]; then
        echo "❌ Please run this script from the project root directory"
        exit 1
    fi
    
    echo "✅ Project structure verified"
}

# Function to deploy Ubuntu server
deploy_ubuntu_server() {
    echo "🖥️ Starting Ubuntu Server Deployment..."
    
    if [ ! -f "deploy_ubuntu_server.sh" ]; then
        echo "❌ Ubuntu deployment script not found"
        exit 1
    fi
    
    chmod +x deploy_ubuntu_server.sh
    ./deploy_ubuntu_server.sh
}

# Function to update Ubuntu server
update_ubuntu_server() {
    echo "🔄 Updating Ubuntu Server..."
    
    # Check if server is already deployed
    if [ ! -d "/opt/bookphere" ]; then
        echo "❌ Server not found. Run full deployment first."
        exit 1
    fi
    
    # Build and copy server
    cd server
    npm run build
    
    # Copy updated files
    sudo cp -r dist/* /opt/bookphere/dist/
    sudo chown -R bookuser:bookuser /opt/bookphere/dist
    
    # Restart server
    sudo -u bookuser pm2 restart bookphere-server
    
    echo "✅ Server updated successfully"
    cd ..
}

# Function to build web client
build_web_client() {
    echo "🌐 Building Web Client..."
    
    if [ ! -f "build_web_client.sh" ]; then
        echo "❌ Web build script not found"
        exit 1
    fi
    
    chmod +x build_web_client.sh
    ./build_web_client.sh
}

# Function to deploy web to server
deploy_web_to_server() {
    echo "🚀 Deploying Web Client to Server..."
    
    read -p "Server IP (localhost for local): " server_ip
    server_ip=${server_ip:-localhost}
    
    if [ "$server_ip" != "localhost" ]; then
        read -p "SSH Username: " ssh_user
        ssh_user=${ssh_user:-ubuntu}
    fi
    
    if [ -f "deploy_web_to_server.sh" ]; then
        chmod +x deploy_web_to_server.sh
        ./deploy_web_to_server.sh "$server_ip" "$ssh_user"
    else
        echo "❌ Web deployment script not found"
        exit 1
    fi
}

# Function to build Android APK
build_android_apk() {
    echo "📱 Building Android APK..."
    
    if [ ! -f "build_android_apk.sh" ]; then
        echo "❌ Android build script not found"
        exit 1
    fi
    
    chmod +x build_android_apk.sh
    ./build_android_apk.sh
}

# Function to build Windows EXE
build_windows_exe() {
    echo "🖥️ Building Windows EXE..."
    
    if command -v cmd.exe &> /dev/null; then
        # Running on Windows (WSL or Git Bash)
        cmd.exe /c build_windows_exe.bat
    else
        echo "❌ Windows build requires Windows environment"
        echo "📋 Run build_windows_exe.bat on Windows system"
        exit 1
    fi
}

# Function to test all components
test_all_components() {
    echo "🧪 Testing All Components..."
    
    # Test server build
    echo "Testing server build..."
    cd server
    npm run build
    echo "✅ Server builds successfully"
    cd ..
    
    # Test web client build
    echo "Testing web client build..."
    cd client
    if command -v flutter &> /dev/null; then
        flutter pub get
        flutter analyze
        echo "✅ Web client analysis passed"
    else
        echo "⚠️ Flutter not available - skipping client tests"
    fi
    cd ..
    
    # Test database connection if available
    if [ -n "$DATABASE_URL" ]; then
        echo "Testing database connection..."
        cd server
        node -e "
        const { Client } = require('pg');
        const client = new Client(process.env.DATABASE_URL);
        client.connect()
        .then(() => {
            console.log('✅ Database connection successful');
            return client.query('SELECT 1');
        })
        .then(() => client.end())
        .catch(err => {
            console.log('❌ Database connection failed:', err.message);
            process.exit(1);
        });
        "
        cd ..
    else
        echo "⚠️ DATABASE_URL not set - skipping database test"
    fi
    
    echo "✅ All component tests completed"
}

# Function to check server health
check_server_health() {
    echo "🏥 Server Health Check..."
    
    read -p "Server URL (http://localhost:3000): " server_url
    server_url=${server_url:-http://localhost:3000}
    
    # Test API health endpoint
    if curl -s --connect-timeout 5 "$server_url/api/health" > /dev/null; then
        echo "✅ Server is responding"
        
        # Get detailed health info
        response=$(curl -s "$server_url/api/health" 2>/dev/null)
        echo "Health response: $response"
    else
        echo "❌ Server is not responding"
        echo "📋 Troubleshooting:"
        echo "   1. Check if server is running"
        echo "   2. Verify URL and port"
        echo "   3. Check firewall settings"
    fi
    
    # Test WebSocket if wscat is available
    if command -v wscat &> /dev/null; then
        echo "Testing WebSocket..."
        timeout 5s wscat -c "$server_url/socket.io/?EIO=4&transport=websocket" --close 2>/dev/null || echo "⚠️ WebSocket test incomplete"
    fi
}

# Function to clean all builds
clean_all_builds() {
    echo "🧹 Cleaning All Builds..."
    
    # Clean server
    if [ -d "server/dist" ]; then
        rm -rf server/dist
        echo "✅ Server dist cleaned"
    fi
    
    # Clean web client
    if [ -d "client/build" ]; then
        rm -rf client/build
        echo "✅ Web client build cleaned"
    fi
    
    # Clean distribution folders
    for dir in web-deploy android-dist windows-dist; do
        if [ -d "$dir" ]; then
            rm -rf "$dir"
            echo "✅ $dir cleaned"
        fi
    done
    
    # Clean Flutter
    if command -v flutter &> /dev/null; then
        cd client
        flutter clean > /dev/null 2>&1
        echo "✅ Flutter cache cleaned"
        cd ..
    fi
    
    echo "✅ All builds cleaned"
}

# Main script execution
main() {
    check_prerequisites
    
    while true; do
        show_menu
        read -p "Enter your choice [0-9]: " choice
        echo ""
        
        case $choice in
            1) deploy_ubuntu_server ;;
            2) update_ubuntu_server ;;
            3) build_web_client ;;
            4) deploy_web_to_server ;;
            5) build_android_apk ;;
            6) build_windows_exe ;;
            7) test_all_components ;;
            8) check_server_health ;;
            9) clean_all_builds ;;
            0) echo "👋 Goodbye!"; exit 0 ;;
            *) echo "❌ Invalid option. Please try again." ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
        echo ""
    done
}

# Run main function
main