@echo off
setlocal
cd /d "%~dp0"

:: 0. Sync dependencies (avoids stale plugin sources after pubspec changes)
echo [📥] flutter pub get...
call flutter pub get
if errorlevel 1 (
    echo [❌ ERROR] pub get failed.
    pause
    exit /b 1
)

:: 1. Ask the User for a Custom Name/Tag (Optional)
echo ----------------------------------------------------
set /p CUSTOM_TAG="Enter a Label for this build (e.g. Test, Final, V2) or hit Enter for date only: "
echo ----------------------------------------------------

:: 2. Generate the safe Batch ID (Total minutes since 2025-01-01)
:: This is always unique, always increasing, and safely under the 2.1 Billion limit!
for /f "tokens=*" %%a in ('powershell -Command "[int](([DateTime]::Now - [DateTime]'2025-01-01').TotalMinutes)"') do set TIMESTAMP=%%a

:: 3. Create the File Name
if "%CUSTOM_TAG%"=="" (
    set FINAL_NAME=AgriBuddy_%TIMESTAMP%.apk
) else (
    set FINAL_NAME=AgriBuddy_%CUSTOM_TAG%_%TIMESTAMP%.apk
)

echo.
echo [🚜 AgriBuddy] Starting Automated Build...
echo [📅 Batch ID ] %TIMESTAMP%
echo [📦 Filename ] %FINAL_NAME%
echo ----------------------------------------------------
echo.
echo Signing mode (Android only updates in-place if the NEW apk uses the
echo SAME certificate as the app already on the phone^):
echo   1 = RELEASE  - your upload-keystore ^(production / Drive if you always built release this way^)
echo   2 = DEBUG    - Flutter debug key ^(if the phone has the app from flutter run or a debug apk^)
echo.
set /p BUILD_MODE="Enter 1 or 2 [default 1]: "
if "%BUILD_MODE%"=="" set BUILD_MODE=1

set "OUT_APK=app-release.apk"
set "BUILD_FLAVOR=release"
if "%BUILD_MODE%"=="2" (
    set "OUT_APK=app-debug.apk"
    set "BUILD_FLAVOR=debug"
)

echo.
echo [🔐] Building %BUILD_FLAVOR% ...
echo ----------------------------------------------------

:: 4. Run the Build
if "%BUILD_MODE%"=="2" (
    call flutter build apk --debug --build-number=%TIMESTAMP%
) else (
    call flutter build apk --release --build-number=%TIMESTAMP%
)

:: 5. Success check
if %ERRORLEVEL% equ 0 (
    echo.
    echo ----------------------------------------------------
    echo [✅ SUCCESS] Build Complete!
    copy build\app\outputs\flutter-apk\%OUT_APK% "%FINAL_NAME%"
    echo [📑 Copied to] %FINAL_NAME%
) else (
    echo.
    echo [❌ ERROR] Build failed. Check the logs above.
)

pause
