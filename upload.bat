@echo off
title PIXEL RUNNER - GitHub Upload
color 0A

cd /d "%~dp0"

echo.
echo ================================
echo       PIXEL RUNNER UPLOAD
echo ================================
echo.

git --version >nul 2>&1
if errorlevel 1 (
    echo Git is not installed!
    pause
    exit /b 1
)

if not exist ".git" (
    git init
)

git branch -M main

git remote get-url origin >nul 2>&1
if errorlevel 1 (
    git remote add origin https://github.com/iafandiyev/PIXEL-RUNNER.git
) else (
    git remote set-url origin https://github.com/iafandiyev/PIXEL-RUNNER.git
)

git add .

git commit -m "Build PIXEL RUNNER iOS game"

git push -u origin main

echo.
echo ================================
echo       UPLOAD FINISHED
echo ================================
echo.
echo Open:
echo https://github.com/iafandiyev/PIXEL-RUNNER/actions
echo.
pause