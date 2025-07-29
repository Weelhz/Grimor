#!/bin/bash

# BookSphere Android APK Builder
# Builds the Flutter Android app with complete installer package

set -e

echo "📱 Building BookSphere Android APK..."
echo "====================================="

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed"
    echo "📋 Installing Flutter..."
    
    # Download and install Flutter
    wget -O flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz
    tar xf flutter.tar.xz
    export PATH="$PWD/flutter/bin:$PATH"
    echo 'export PATH="$PWD/flutter/bin:$PATH"' >> ~/.bashrc
fi

# Check for Java/Android SDK
if ! flutter doctor | grep -q "Android toolchain"; then
    echo "📋 Setting up Android development environment..."
    
    # Install OpenJDK 11
    sudo apt update
    sudo apt install -y openjdk-11-jdk
    
    # Download Android SDK
    wget -O android-sdk.zip https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip
    unzip android-sdk.zip -d android-sdk
    export ANDROID_HOME=$PWD/android-sdk
    export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
    export PATH=$ANDROID_HOME/platform-tools:$PATH
    
    # Accept licenses
    yes | sdkmanager --licenses
    sdkmanager "platform-tools" "platforms;android-30" "build-tools;30.0.3"
fi

# Navigate to client directory
cd client

# Configure Android signing
echo "🔐 Setting up Android signing..."
if [ ! -f android/key.properties ]; then
    # Generate keystore
    keytool -genkey -v -keystore android/app/bookphere-release-key.keystore \
        -alias bookphere -keyalg RSA -keysize 2048 -validity 10000 \
        -storepass bookphere123 -keypass bookphere123 \
        -dname "CN=BookSphere, OU=BookSphere, O=BookSphere, L=City, S=State, C=US"
    
    # Create key.properties
    cat > android/key.properties << EOF
storePassword=bookphere123
keyPassword=bookphere123
keyAlias=bookphere
storeFile=bookphere-release-key.keystore
EOF
fi

# Update android/app/build.gradle for signing
echo "⚙️ Configuring build settings..."
if ! grep -q "signingConfigs" android/app/build.gradle; then
    # Backup original
    cp android/app/build.gradle android/app/build.gradle.backup
    
    # Add signing configuration
    sed -i '/android {/a\
    def keystoreProperties = new Properties()\
    def keystorePropertiesFile = rootProject.file("key.properties")\
    if (keystorePropertiesFile.exists()) {\
        keystoreProperties.load(new FileInputStream(keystorePropertiesFile))\
    }\
    \
    signingConfigs {\
        release {\
            keyAlias keystoreProperties["keyAlias"]\
            keyPassword keystoreProperties["keyPassword"]\
            storeFile keystoreProperties["storeFile"] ? file(keystoreProperties["storeFile"]) : null\
            storePassword keystoreProperties["storePassword"]\
        }\
    }' android/app/build.gradle
    
    # Update buildTypes
    sed -i '/buildTypes {/,/}/ {
        /release {/,/}/ {
            /signingConfig/d
            /}/i\            signingConfig signingConfigs.release
        }
    }' android/app/build.gradle
fi

# Update app permissions and configuration
echo "📋 Updating Android manifest..."
cat > android/app/src/main/AndroidManifest.xml << 'EOF'
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.bookphere.app">
    
    <!-- Internet permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <!-- File permissions -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
    
    <!-- Audio permissions -->
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    
    <application
        android:label="BookSphere"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true"
        android:requestLegacyExternalStorage="true">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme" />
              
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
EOF

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Build APK
echo "🔨 Building release APK..."
flutter build apk --release --split-per-abi

# Create distribution package
echo "📁 Creating Android distribution package..."
DIST_DIR="../android-dist"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# Copy APKs
cp build/app/outputs/flutter-apk/*.apk "$DIST_DIR/"

# Create installation guide
cat > "$DIST_DIR/INSTALL_ANDROID.md" << 'EOF'
# BookSphere Android Installation Guide

## Installation Steps

### Method 1: Direct APK Installation (Recommended)
1. **Download APK**: Get the appropriate APK for your device:
   - `app-arm64-v8a-release.apk` - For most modern Android devices (64-bit ARM)
   - `app-armeabi-v7a-release.apk` - For older Android devices (32-bit ARM)
   - `app-x86_64-release.apk` - For Android emulators/x86 devices

2. **Enable Unknown Sources**:
   - Go to Settings > Security
   - Enable "Unknown Sources" or "Install from Unknown Sources"
   - Or go to Settings > Apps > Special Access > Install Unknown Apps

3. **Install APK**:
   - Transfer APK to your Android device
   - Tap the APK file in your file manager
   - Follow installation prompts
   - Grant necessary permissions

### Method 2: ADB Installation (For Developers)
```bash
# Connect device via USB with Developer Options enabled
adb install app-arm64-v8a-release.apk
```

## Configuration

### Server Connection
1. Open BookSphere app
2. Go to Settings
3. Configure server URL (default: http://localhost:3000)
4. Test connection

### Permissions Required
- **Internet**: For server communication
- **Storage**: For downloading and caching books
- **Audio**: For mood-based sound effects

## Features
- ✅ Offline reading support
- ✅ Automatic synchronization when online
- ✅ Mood-based audio-visual experience
- ✅ Multi-format support (PDF, EPUB, TXT)
- ✅ Cloud storage integration
- ✅ Reading progress tracking

## Troubleshooting

### Installation Issues
- **"App not installed"**: Check available storage space
- **"Parse error"**: Download correct APK for your device architecture
- **"Blocked by Play Protect"**: Temporarily disable Play Protect

### Connection Issues
- Check server URL in app settings
- Ensure server is running and accessible
- Verify network connectivity
- Check firewall settings

### Performance Issues
- Clear app cache: Settings > Apps > BookSphere > Storage > Clear Cache
- Restart the app
- Free up device storage space

## Device Requirements
- Android 5.0 (API level 21) or higher
- 100MB free storage space
- Internet connection for synchronization
- Recommended: 2GB RAM or more

## Support
- Check app settings for server configuration
- Verify server is running before reporting issues
- For technical support, contact your system administrator

## Security Note
This APK is signed with a debug certificate. For production deployment,
ensure proper code signing and security measures are in place.
EOF

# Create server connection test script
cat > "$DIST_DIR/test_connection.sh" << 'EOF'
#!/bin/bash

# BookSphere Android Server Connection Test
echo "📱 Testing BookSphere Server Connection..."

SERVER_URL=${1:-"http://localhost:3000"}

echo "Testing connection to: $SERVER_URL"

# Test basic connectivity
if curl -s --connect-timeout 5 "$SERVER_URL/api/health" > /dev/null; then
    echo "✅ Server is reachable"
else
    echo "❌ Server is not reachable"
    echo "📋 Troubleshooting steps:"
    echo "   1. Check if server is running"
    echo "   2. Verify server URL and port"
    echo "   3. Check firewall settings"
    echo "   4. Test from same network"
fi

# Test API endpoint
API_RESPONSE=$(curl -s "$SERVER_URL/api/health" 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "✅ API endpoint responding"
    echo "Response: $API_RESPONSE"
else
    echo "❌ API endpoint not responding"
fi

# Test WebSocket (basic check)
if command -v wscat &> /dev/null; then
    echo "Testing WebSocket connection..."
    timeout 5s wscat -c "$SERVER_URL/socket.io/?EIO=4&transport=websocket" --close || echo "⚠️ WebSocket test incomplete (install wscat for full test)"
else
    echo "⚠️ WebSocket test skipped (wscat not available)"
fi

echo "📋 Use this information to configure the Android app"
EOF

chmod +x "$DIST_DIR/test_connection.sh"

# Create device compatibility checker
cat > "$DIST_DIR/check_device.sh" << 'EOF'
#!/bin/bash

# Android Device Compatibility Checker
echo "📱 BookSphere Android Device Compatibility Check"
echo "================================================"

if command -v adb &> /dev/null && adb devices | grep -q "device"; then
    echo "📋 Connected Device Information:"
    
    # Get device info
    DEVICE_MODEL=$(adb shell getprop ro.product.model 2>/dev/null)
    ANDROID_VERSION=$(adb shell getprop ro.build.version.release 2>/dev/null)
    API_LEVEL=$(adb shell getprop ro.build.version.sdk 2>/dev/null)
    ABI=$(adb shell getprop ro.product.cpu.abi 2>/dev/null)
    
    echo "   Model: $DEVICE_MODEL"
    echo "   Android: $ANDROID_VERSION (API $API_LEVEL)"
    echo "   Architecture: $ABI"
    
    # Check compatibility
    if [ "$API_LEVEL" -ge 21 ]; then
        echo "✅ Android version compatible"
    else
        echo "❌ Android version too old (requires API 21+)"
    fi
    
    # Recommend APK
    echo ""
    echo "📦 Recommended APK:"
    case "$ABI" in
        "arm64-v8a") echo "   Use: app-arm64-v8a-release.apk" ;;
        "armeabi-v7a") echo "   Use: app-armeabi-v7a-release.apk" ;;
        "x86_64") echo "   Use: app-x86_64-release.apk" ;;
        *) echo "   Use: app-arm64-v8a-release.apk (universal fallback)" ;;
    esac
    
else
    echo "❌ No Android device connected via ADB"
    echo "📋 Manual compatibility check:"
    echo "   1. Check Android version (requires 5.0+)"
    echo "   2. Check device architecture in Settings > About Phone"
    echo "   3. Ensure at least 100MB free storage"
fi
EOF

chmod +x "$DIST_DIR/check_device.sh"

echo ""
echo "✅ Android APK Build Complete!"
echo "=============================="
echo ""
echo "📁 Distribution package: $DIST_DIR"
echo "📱 APK files:"
for apk in "$DIST_DIR"/*.apk; do
    if [ -f "$apk" ]; then
        echo "   $(basename "$apk")"
    fi
done
echo ""
echo "📋 Installation files:"
echo "   📖 INSTALL_ANDROID.md - Complete installation guide"
echo "   🔧 test_connection.sh - Server connection testing"
echo "   📱 check_device.sh - Device compatibility checker"
echo ""
echo "🚀 To deploy:"
echo "   1. Share the entire android-dist folder"
echo "   2. Users follow INSTALL_ANDROID.md"
echo "   3. Install appropriate APK for device architecture"
echo ""