@echo off
title PrepMantra Admin Launcher
color 0A

echo.
echo  ========================================
echo   PrepMantra Admin Panel Launcher
echo  ========================================
echo.

:: ── Check if server already running on 5500 ──────────────────────
netstat -an 2>nul | find ":5500" >nul
if %errorlevel% == 0 (
    echo  [OK] Server already running on port 5500
    goto :open_browser
)

:: ── Find Python ───────────────────────────────────────────────────
set PYTHON_CMD=
where python >nul 2>&1  && set PYTHON_CMD=python
if "%PYTHON_CMD%"=="" (
    where py >nul 2>&1  && set PYTHON_CMD=py
)
if "%PYTHON_CMD%"=="" (
    where python3 >nul 2>&1 && set PYTHON_CMD=python3
)
if "%PYTHON_CMD%"=="" (
    echo  [ERROR] Python not found. Install from python.org
    pause
    exit /b 1
)

:: ── Start server in minimized background window ───────────────────
echo  [..] Starting HTTP server on port 5500...
start "PrepMantra-Server" /min cmd /c "%PYTHON_CMD% -m http.server 5500 --directory "D:\Projects\PrepMantra\backend""

:: ── Wait for server to be ready ───────────────────────────────────
timeout /t 2 /nobreak >nul

:open_browser
echo  [..] Opening admin panel in Chrome...

:: Try Chrome Program Files (64-bit)
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
    start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" --new-window "http://localhost:5500/admin.html"
    goto :done
)

:: Try Chrome Program Files (32-bit)
if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" (
    start "" "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" --new-window "http://localhost:5500/admin.html"
    goto :done
)

:: Try Chrome via LocalAppData (per-user install)
if exist "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe" (
    start "" "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe" --new-window "http://localhost:5500/admin.html"
    goto :done
)

:: Final fallback — default browser
echo  [WARN] Chrome not found. Opening in default browser...
start "" "http://localhost:5500/admin.html"

:done
echo  [OK] Done! Admin panel should open shortly.
echo.
exit
