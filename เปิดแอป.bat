@echo off
chcp 65001 >nul
cd /d "%~dp0"
set PYTHONUTF8=1
title Habit Tracker
python "_serve.py"
if errorlevel 9009 (
  echo.
  echo [!] Python not found - install from https://www.python.org/downloads/
  pause
)
