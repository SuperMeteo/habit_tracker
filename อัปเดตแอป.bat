@echo off
chcp 65001 >nul
cd /d "%~dp0"
set PYTHONUTF8=1
title Habit Tracker - update
echo.
echo   Building... please wait 1-2 minutes
echo.
call flutter build web
if errorlevel 1 (
  echo.
  echo   [X] Build failed - see message above
  pause
  exit /b 1
)
echo.
echo   [OK] Done - opening app
echo.
python "_serve.py"
