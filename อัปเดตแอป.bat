@echo off
chcp 65001 >nul
cd /d "%~dp0"
title Habit Tracker - อัปเดต
echo.
echo   กำลังสร้างแอปเวอร์ชันใหม่ รอสัก 1-2 นาที...
echo.
call flutter build web --release
if errorlevel 1 (
  echo.
  echo   [X] สร้างไม่สำเร็จ ดูข้อความผิดพลาดด้านบน
  pause
  exit /b 1
)
echo.
echo   [OK] เสร็จแล้ว กำลังเปิดแอป
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "_serve.ps1"
if errorlevel 1 pause
