@echo off
setlocal enabledelayedexpansion

REM BookSphere Windows Desktop Application Builder
REM Builds the Flutter desktop app for Windows

echo 🖥️ Building BookSphere Windows Desktop App...
echo ===============================================

REM Check if Flutter is installed
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Flutter is not installed
    echo 📋 Please install Flutter first:
    echo    1. Download from: https://docs.flutter.dev/get-started/install/windows
    echo    2. Extract to C:\flutter
    echo    3. Add C:\flutter\bin to PATH
    echo    4. Run 'flutter doctor' to complete setup
    pause
    exit /b 1
)

REM Navigate to client directory
cd client
if errorlevel 1 (
    echo ❌ Client directory not found
    pause
    exit /b 1
)

REM Enable Windows desktop
echo 📦 Enabling Windows desktop support...
flutter config --enable-windows-desktop

REM Get dependencies
echo 📦 Getting Flutter dependencies...
flutter pub get

REM Clean previous builds
echo 🧹 Cleaning previous builds...
flutter clean
flutter pub get

REM Build for Windows
echo 🔨 Building Windows desktop application...
flutter build windows --release

REM Check if build was successful
if not exist "build\windows\x64\runner\Release\book_sphere.exe" (
    echo ❌ Build failed - executable not found
    pause
    exit /b 1
)

REM Create distribution folder
echo 📁 Creating distribution package...
set DIST_DIR=..\windows-dist
if exist "%DIST_DIR%" rmdir /s /q "%DIST_DIR%"
mkdir "%DIST_DIR%"

REM Copy all necessary files
xcopy "build\windows\x64\runner\Release\*" "%DIST_DIR%\" /E /I /Y

REM Create installer script
echo ⚙️ Creating installer script...
(
echo @echo off
echo setlocal
echo.
echo echo 🚀 BookSphere Windows Installer
echo echo ===============================
echo.
echo REM Create installation directory
echo set INSTALL_DIR=C:\Program Files\BookSphere
echo if not exist "%%INSTALL_DIR%%" mkdir "%%INSTALL_DIR%%"
echo.
echo REM Copy files
echo xcopy "*.exe" "%%INSTALL_DIR%%\" /Y
echo xcopy "*.dll" "%%INSTALL_DIR%%\" /Y
echo if exist "data" xcopy "data\*" "%%INSTALL_DIR%%\data\" /E /I /Y
echo.
echo REM Create desktop shortcut
echo set DESKTOP=%%USERPROFILE%%\Desktop
echo echo Set WshShell = WScript.CreateObject("WScript.Shell"^) ^> temp_shortcut.vbs
echo echo Set Shortcut = WshShell.CreateShortcut("%%DESKTOP%%\BookSphere.lnk"^) ^>^> temp_shortcut.vbs
echo echo Shortcut.TargetPath = "%%INSTALL_DIR%%\book_sphere.exe" ^>^> temp_shortcut.vbs
echo echo Shortcut.WorkingDirectory = "%%INSTALL_DIR%%" ^>^> temp_shortcut.vbs
echo echo Shortcut.IconLocation = "%%INSTALL_DIR%%\book_sphere.exe,0" ^>^> temp_shortcut.vbs
echo echo Shortcut.Description = "BookSphere - Immersive Reading Experience" ^>^> temp_shortcut.vbs
echo echo Shortcut.Save ^>^> temp_shortcut.vbs
echo cscript temp_shortcut.vbs
echo del temp_shortcut.vbs
echo.
echo REM Create start menu entry
echo set STARTMENU=%%APPDATA%%\Microsoft\Windows\Start Menu\Programs
echo if not exist "%%STARTMENU%%\BookSphere" mkdir "%%STARTMENU%%\BookSphere"
echo echo Set WshShell = WScript.CreateObject("WScript.Shell"^) ^> temp_start.vbs
echo echo Set Shortcut = WshShell.CreateShortcut("%%STARTMENU%%\BookSphere\BookSphere.lnk"^) ^>^> temp_start.vbs
echo echo Shortcut.TargetPath = "%%INSTALL_DIR%%\book_sphere.exe" ^>^> temp_start.vbs
echo echo Shortcut.WorkingDirectory = "%%INSTALL_DIR%%" ^>^> temp_start.vbs
echo echo Shortcut.IconLocation = "%%INSTALL_DIR%%\book_sphere.exe,0" ^>^> temp_start.vbs
echo echo Shortcut.Description = "BookSphere - Immersive Reading Experience" ^>^> temp_start.vbs
echo echo Shortcut.Save ^>^> temp_start.vbs
echo cscript temp_start.vbs
echo del temp_start.vbs
echo.
echo echo ✅ BookSphere installed successfully!
echo echo 🚀 You can now launch it from Desktop or Start Menu
echo echo.
echo pause
) > "%DIST_DIR%\install.bat"

REM Create configuration file
echo ⚙️ Creating configuration file...
(
echo {
echo   "server_url": "http://localhost:3000",
echo   "websocket_url": "ws://localhost:3000",
echo   "app_name": "BookSphere",
echo   "version": "1.0.0",
echo   "auto_connect": true,
echo   "offline_mode": true,
echo   "cache_size_mb": 500
echo }
) > "%DIST_DIR%\config.json"

REM Create README
echo 📋 Creating README...
(
echo BookSphere Windows Desktop Application
echo =====================================
echo.
echo Installation:
echo 1. Run install.bat as Administrator
echo 2. Follow the installation prompts
echo 3. Launch from Desktop or Start Menu
echo.
echo Configuration:
echo - Edit config.json to change server settings
echo - Default server: http://localhost:3000
echo.
echo Requirements:
echo - Windows 10 version 1903 or higher
echo - Visual C++ Redistributable ^(included^)
echo.
echo Support:
echo - Check server connection in config.json
echo - Ensure server is running before launching app
echo - For issues, check Windows Event Viewer
echo.
echo Features:
echo - Offline reading support
echo - Automatic synchronization
echo - Mood-based audio-visual experience
echo - Multi-format book support ^(PDF, EPUB, TXT^)
echo.
) > "%DIST_DIR%\README.txt"

REM Create uninstaller
echo ⚙️ Creating uninstaller...
(
echo @echo off
echo setlocal
echo.
echo echo 🗑️ BookSphere Uninstaller
echo echo =========================
echo.
echo set /p CONFIRM="Are you sure you want to uninstall BookSphere? (Y/N): "
echo if /i "%%CONFIRM%%" neq "Y" goto :cancel
echo.
echo REM Remove installation directory
echo set INSTALL_DIR=C:\Program Files\BookSphere
echo if exist "%%INSTALL_DIR%%" (
echo     echo Removing application files...
echo     rmdir /s /q "%%INSTALL_DIR%%"
echo ^)
echo.
echo REM Remove desktop shortcut
echo set DESKTOP=%%USERPROFILE%%\Desktop
echo if exist "%%DESKTOP%%\BookSphere.lnk" del "%%DESKTOP%%\BookSphere.lnk"
echo.
echo REM Remove start menu entry
echo set STARTMENU=%%APPDATA%%\Microsoft\Windows\Start Menu\Programs\BookSphere
echo if exist "%%STARTMENU%%" rmdir /s /q "%%STARTMENU%%"
echo.
echo echo ✅ BookSphere uninstalled successfully!
echo goto :end
echo.
echo :cancel
echo echo Uninstallation cancelled.
echo.
echo :end
echo pause
) > "%DIST_DIR%\uninstall.bat"

REM Create launcher with server detection
echo ⚙️ Creating smart launcher...
(
echo @echo off
echo setlocal
echo.
echo echo 🚀 Starting BookSphere...
echo echo ========================
echo.
echo REM Check if config exists
echo if not exist "config.json" (
echo     echo ❌ Configuration file not found
echo     echo Creating default configuration...
echo     (
echo         echo {
echo         echo   "server_url": "http://localhost:3000",
echo         echo   "websocket_url": "ws://localhost:3000",
echo         echo   "auto_connect": true,
echo         echo   "offline_mode": true
echo         echo }
echo     ^) ^> config.json
echo ^)
echo.
echo REM Try to ping server
echo ping -n 1 localhost ^>nul 2^>^&1
echo if errorlevel 1 (
echo     echo ⚠️ Server not reachable - starting in offline mode
echo ^) else (
echo     echo ✅ Server connection available
echo ^)
echo.
echo REM Launch application
echo start "" "book_sphere.exe"
echo.
echo REM Wait a moment then close this window
echo timeout /t 3 /nobreak ^>nul
) > "%DIST_DIR%\BookSphere.bat"

echo ""
echo ✅ Windows Desktop Build Complete!
echo ==================================
echo ""
echo 📁 Distribution package: %DIST_DIR%
echo 📦 Main executable: %DIST_DIR%\book_sphere.exe
echo ⚙️ Installer: %DIST_DIR%\install.bat
echo 🚀 Launcher: %DIST_DIR%\BookSphere.bat
echo ""
echo 📋 To distribute:
echo    1. Zip the entire %DIST_DIR% folder
echo    2. Share with users
echo    3. Users run install.bat as Administrator
echo ""
echo 🔧 Manual installation:
echo    1. Copy all files to desired location
echo    2. Run BookSphere.bat to launch
echo    3. Edit config.json for server settings
echo ""

pause