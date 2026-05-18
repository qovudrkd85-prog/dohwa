@echo off
title Groupware Debug Chrome - port 9222
echo ============================================
echo   Groupware Chrome (remote debugging 9222)
echo ============================================
echo.
echo [1/4] Closing all Chrome...
taskkill /F /IM chrome.exe /T >nul 2>&1
timeout /t 3 /nobreak >nul

echo [2/4] Finding Chrome...
set "CHROME="
for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe" /ve 2^>nul ^| find "REG_SZ"') do set "CHROME=%%b"
if not defined CHROME for /f "tokens=2*" %%a in ('reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe" /ve 2^>nul ^| find "REG_SZ"') do set "CHROME=%%b"

if not defined CHROME (
  echo.
  echo [ERROR] Chrome not found in registry.
  echo Please tell Claude the chrome.exe location.
  echo.
  pause
  exit /b
)

echo       Found: %CHROME%
echo [3/4] Launching debug Chrome...
start "" "%CHROME%" --remote-debugging-port=9222 --user-data-dir="C:\Users\user\chrome-debug-profile" "https://gw.dohwa.co.kr/ekp/view/login/userLogin"
timeout /t 3 /nobreak >nul

echo [4/4] Done.
echo.
echo --------------------------------------------
echo  1. Log in to groupware in the Chrome window
echo  2. Address bar: 127.0.0.1:9222/json/version
echo     If JSON text appears = SUCCESS
echo  3. Tell Claude: done
echo --------------------------------------------
echo.
pause
