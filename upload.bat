
@echo off
title PIXEL RUNNER Upload
cd /d "%~dp0"

git add .

git diff --cached --quiet
if %errorlevel%==0 (
    echo No new changes to commit.
) else (
    git commit -m "Fix PIXEL RUNNER iOS build"
)

git push origin main

echo.
echo Check GitHub Actions:
echo https://github.com/iafandiyev/PIXEL-RUNNER/actions
echo.
pause
