@echo off
REM 도화 자동 브리핑 - Windows 작업 스케줄러 등록 (1회 실행)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0register_tasks.ps1"
echo.
pause
