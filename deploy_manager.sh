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
    if [ -f "package.json" ]; then
        npm run build
    else
        echo "❌ Server package.json not found"
        cd ..
        exit 1
    fi
    
    # Copy updated files
    if [ -d "dist" ]; then
        sudo cp -r dist/* /opt/bookphere/dist/
        sudo chown -R bookuser:bookuser /opt/bookphere/dist
    else
        echo "❌ Build failed - dist directory not found"
        cd ..
        exit 1
    fi
    
    # Restart server
    if command -v pm2 &> /dev/null; then
        sudo -u bookuser pm2 restart bookphere-server
    else
        echo "⚠️ PM2 not found - please restart server manually"
    fi
    
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
    
    if [ -f "build_windows_exe.bat" ]; then
        if command -v cmd.exe &> /dev/null; then
            # Running on Windows (WSL or Git Bash)
            cmd.exe /c build_windows_exe.bat
        elif command -v wine &> /dev/null; then
            # Running on Linux with Wine
            wine cmd /c build_windows_exe.bat
        else
            echo "❌ Windows build requires Windows environment or Wine"
            echo "📋 Run build_windows_exe.bat on Windows system"
            exit 1
        fi
    else
        echo "❌ Windows build script not found"
        exit 1
    fi
}

# Function to test all components
test_all_components() {
    echo "🧪 Testing All Components..."
    
    # Test server build
    echo "Testing server build..."
    if [ -d "server" ] && [ -f "server/package.json" ]; then
        cd server
        if npm run build; then
            echo "✅ Server builds successfully"
        else
            echo "❌ Server build failed"
        fi
        cd ..
    else
        echo "❌ Server directory or package.json not found"
    fi
    
    # Test web client build
    echo "Testing web client build..."
    if [ -d "client" ] && [ -f "client/pubspec.yaml" ]; then
        cd client
        if command -v flutter &> /dev/null; then
            if flutter pub get && flutter analyze; then
                echo "✅ Web client analysis passed"
            else
                echo "❌ Web client analysis failed"
            fi
        else
            echo "⚠️ Flutter not available - skipping client tests"
        fi
        cd ..
    else
        echo "❌ Client directory or pubspec.yaml not found"
    fi
    
    # Test database connection if available
    if [ -n "$DATABASE_URL" ]; then
        echo "Testing database connection..."
        if [ -d "server" ]; then
            cd server
            if command -v node &> /dev/null; then
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
                " 2>/dev/null || echo "❌ Database connection test failed"
            else
                echo "❌ Node.js not available for database test"
            fi
            cd ..
        fi
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
    if command -v curl &> /dev/null; then
        if curl -s --connect-timeout 5 "$server_url/api/health" > /dev/null 2>&1; then
            echo "✅ Server is responding"
            
            # Get detailed health info
            response=$(curl -s "$server_url/api/health" 2>/dev/null)
            if [ -n "$response" ]; then
                echo "Health response: $response"
            fi
        else
            echo "❌ Server is not responding"
            echo "📋 Troubleshooting:"
            echo "   1. Check if server is running"
            echo "   2. Verify URL and port"
            echo "   3. Check firewall settings"
        fi
    else
        echo "❌ curl not available - cannot test server health"
    fi
    
    # Test WebSocket if wscat is available
    if command -v wscat &> /dev/null; then
        echo "Testing WebSocket..."
        if timeout 5s wscat -c "$server_url/socket.io/?EIO=4&transport=websocket" --close 2>/dev/null; then
            echo "✅ WebSocket connection successful"
        else
            echo "⚠️ WebSocket test incomplete or failed"
        fi
    else
        echo "⚠️ wscat not available - skipping WebSocket test"
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
    
    # Clean server node_modules if requested
    if [ -d "server/node_modules" ]; then
        read -p "Clean server node_modules? (y/N): " clean_node_modules
        if [ "$clean_node_modules" = "y" ] || [ "$clean_node_modules" = "Y" ]; then
            rm -rf server/node_modules
            echo "✅ Server node_modules cleaned"
        fi
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
    if command -v flutter &> /dev/null && [ -d "client" ]; then
        cd client
        if flutter clean > /dev/null 2>&1; then
            echo "✅ Flutter cache cleaned"
        else
            echo "⚠️ Flutter clean failed"
        fi
        cd ..
    fi
    
    echo "✅ All builds cleaned"
}

# Main script execution
main() {
    # Check prerequisites with error handling
    if ! check_prerequisites; then
        echo "❌ Prerequisites check failed"
        exit 1
    fi
    
    while true; do
        show_menu
        read -p "Enter your choice [0-9]: " choice
        echo ""
        
        case $choice in
            1) deploy_ubuntu_server || echo "❌ Ubuntu server deployment failed" ;;
            2) update_ubuntu_server || echo "❌ Ubuntu server update failed" ;;
            3) build_web_client || echo "❌ Web client build failed" ;;
            4) deploy_web_to_server || echo "❌ Web deployment failed" ;;
            5) build_android_apk || echo "❌ Android APK build failed" ;;
            6) build_windows_exe || echo "❌ Windows EXE build failed" ;;
            7) test_all_components || echo "❌ Component testing failed" ;;
            8) check_server_health || echo "❌ Health check failed" ;;
            9) clean_all_builds || echo "❌ Build cleanup failed" ;;
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