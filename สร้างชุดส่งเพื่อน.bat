@echo off
chcp 65001 >nul
setlocal EnableExtensions
cd /d "%~dp0"
title Habit Tracker - สร้างชุดส่งเพื่อน

set "OUT=dist\HabitTracker"
set "ZIP=dist\HabitTracker.zip"

echo.
echo ==========================================================
echo    สร้างชุดแอปสำหรับส่งให้เพื่อนเปิดบนคอม
echo ==========================================================
echo.
echo   ผลลัพธ์: ไฟล์ %ZIP%
echo   เพื่อนแตกไฟล์แล้วกด เปิดแอป.bat ได้เลย ไม่ต้องลงโปรแกรมอะไร
echo.

if /i "%~1"=="/skipbuild" (
  echo   [ข้าม] ไม่ build ใหม่ ใช้ไฟล์เดิมใน build\web
) else (
  echo   [1/4] กำลัง build เวอร์ชันเว็บ รอสัก 1-2 นาที...
  powershell -NoProfile -ExecutionPolicy Bypass -File "_build_web.ps1"
  if errorlevel 1 (
    echo   [X] build ไม่สำเร็จ ดูข้อความผิดพลาดด้านบน
    pause
    exit /b 1
  )
)

if not exist "build\web\index.html" (
  echo   [X] ไม่พบไฟล์ใน build\web
  pause
  exit /b 1
)

echo   [2/4] กำลังจัดโฟลเดอร์...
if exist "%OUT%" rmdir /s /q "%OUT%"
mkdir "%OUT%\web"
xcopy "build\web" "%OUT%\web" /e /i /q /y >nul
copy /y "_serve.ps1" "%OUT%\" >nul
copy /y "เปิดแอป.bat" "%OUT%\" >nul

echo   [3/4] กำลังเขียนใบแนะนำ...
> "%OUT%\อ่านก่อน.txt" (
  echo Habit Tracker - แอปติดตามพฤติกรรมประจำวัน
  echo.
  echo วิธีเปิด
  echo   1. กดไฟล์  เปิดแอป.bat
  echo   2. แอปจะเด้งขึ้นมาเอง ใช้งานได้เลย
  echo.
  echo ปิดแอป = ปิดหน้าต่างสีดำ
  echo.
  echo อยากได้ไอคอนบนเดสก์ท็อป
  echo   ตอนแอปเปิดอยู่ กดเมนู ... ของเบราว์เซอร์ แล้วเลือก ติดตั้ง Habit Tracker
  echo.
  echo หมายเหตุ
  echo   - ไม่ต้องลงโปรแกรมอะไรเพิ่ม ใช้ PowerShell ที่มีอยู่แล้วใน Windows
  echo   - ถ้าไม่สมัครสมาชิก ข้อมูลจะอยู่ในเครื่องนี้เท่านั้น
  echo   - สมัครสมาชิกแล้วข้อมูลจะซิงก์ขึ้นคลาวด์ และแข่งอันดับกับเพื่อนได้
  echo   - ถ้าล้างข้อมูลเบราว์เซอร์ ข้อมูลในแอปจะหายไปด้วย
  echo   - เวอร์ชันบนคอมไม่มีการแจ้งเตือน ถ้าต้องการแจ้งเตือนให้ใช้ไฟล์ APK บนมือถือ Android
)

echo   [4/4] กำลังบีบไฟล์...
if exist "%ZIP%" del /q "%ZIP%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Compress-Archive -Path 'dist\HabitTracker\*' -DestinationPath 'dist\HabitTracker.zip' -Force"
if errorlevel 1 (
  echo   [X] บีบไฟล์ไม่สำเร็จ แต่โฟลเดอร์ %OUT% ใช้ได้ ส่งทั้งโฟลเดอร์แทนได้
  pause
  exit /b 1
)

echo.
echo ==========================================================
echo    เสร็จแล้ว
echo ==========================================================
echo.
echo   ไฟล์พร้อมส่ง: %CD%\%ZIP%
echo   ส่งทางไลน์ / Google Drive / แฟลชไดรฟ์ ได้เลย
echo.
pause
exit /b 0
