@echo off
chcp 65001 >nul
cd /d "%~dp0"
title Habit Tracker
powershell -NoProfile -ExecutionPolicy Bypass -File "_serve.ps1"
if errorlevel 1 pause
