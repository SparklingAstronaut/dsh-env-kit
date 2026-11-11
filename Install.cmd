@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Install-DSHKit.ps1" %*
echo.
pause
