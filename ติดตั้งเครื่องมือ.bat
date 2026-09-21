@echo off
chcp 65001 >nul
setlocal EnableExtensions
title ติดตั้งเครื่องมือสำหรับ Habit Tracker
set "FLUTTER_DIR=C:\flutter"
set "SKIPPED="
set "DRY="
if /i "%~1"=="/ทดลอง" set "DRY=1"
if /i "%~1"=="/dry" set "DRY=1"

echo.
echo ==========================================================
echo    ติดตั้งเครื่องมือสำหรับโปรเจกต์ Habit Tracker
echo ==========================================================
if defined DRY echo    *** โหมดทดลอง - แสดงขั้นตอนเฉย ๆ ไม่ติดตั้งอะไรจริง ***
echo.
echo   ชุดนี้สำหรับคนที่จะ "แก้โค้ดและรันบนเบราว์เซอร์"
echo   จะติดตั้งให้ 4 อย่าง (อันไหนมีอยู่แล้วจะข้าม)
echo     1. Git                  - ใช้ดึงโค้ดจาก GitHub
echo     2. Visual Studio Code   - โปรแกรมเขียนโค้ด
echo     3. Python               - ใช้เปิดแอปเวอร์ชันเว็บ
echo     4. Flutter SDK          - ตัวหลักที่ใช้สร้างแอป (ไฟล์ใหญ่ ~1 GB)
echo.
echo   ไม่ได้ลง Android Studio เพราะจำเป็นเฉพาะตอนสร้างไฟล์ APK
echo   หรือใช้ emulator เท่านั้น ถ้าจะทำสองอย่างนั้นค่อยลงเพิ่มทีหลัง
echo.
echo   * ใช้เวลาประมาณ 10-20 นาที ขึ้นกับความเร็วเน็ต
echo   * ระหว่างทางอาจมีหน้าต่างขออนุญาตของ Windows เด้งขึ้นมา ให้กด Yes
echo.
pause

echo.
echo ---------- ตรวจเครื่องมือติดตั้งของ Windows ----------
where winget >nul 2>&1
if errorlevel 1 (
  echo   [X] เครื่องนี้ไม่มีคำสั่ง winget
  echo       ให้เปิด Microsoft Store แล้วอัปเดต "App Installer" ก่อน
  echo       จากนั้นค่อยรันไฟล์นี้ใหม่
  echo.
  pause
  exit /b 1
)
echo   [OK] winget พร้อมใช้งาน

call :install_one "Git.Git" "Git"
call :install_one "Microsoft.VisualStudioCode" "Visual Studio Code"
call :install_one "Python.Python.3.12" "Python 3.12"

echo.
echo ---------- Flutter SDK ----------
if exist "%FLUTTER_DIR%\bin\flutter.bat" (
  echo   [ข้าม] มี Flutter อยู่แล้วที่ %FLUTTER_DIR%
) else (
  if defined DRY (
    echo   [ทดลอง] จะถามเซิร์ฟเวอร์ Flutter ว่า stable ล่าสุดคือเวอร์ชันอะไร
    echo   [ทดลอง] แล้วดาวน์โหลดไฟล์ zip มาแตกไว้ที่ %FLUTTER_DIR%
  ) else (
    echo   กำลังดาวน์โหลด Flutter รุ่น stable ล่าสุด...
    echo   ไฟล์ใหญ่ประมาณ 1 GB อาจใช้เวลาหลายนาที อย่าเพิ่งปิดหน้าต่างนี้
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $feed = Invoke-RestMethod 'https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json'; $rel = $feed.releases ^| Where-Object { $_.hash -eq $feed.current_release.stable } ^| Select-Object -First 1; $url = $feed.base_url + '/' + $rel.archive; $zip = Join-Path $env:TEMP 'flutter_stable.zip'; Write-Host ('   version: ' + $rel.version); Invoke-WebRequest -Uri $url -OutFile $zip; Write-Host '   extracting to C:\ ...'; Expand-Archive -Path $zip -DestinationPath 'C:\' -Force; Remove-Item $zip -Force"
    if errorlevel 1 (
      echo   [X] ดาวน์โหลดหรือแตกไฟล์ไม่สำเร็จ
      echo       ให้ดาวน์โหลดเองที่ https://docs.flutter.dev/get-started/install/windows
      echo       แล้วแตกไฟล์ไว้ที่ %FLUTTER_DIR%
      set "SKIPPED=1"
    ) else (
      echo   [OK] ติดตั้ง Flutter ที่ %FLUTTER_DIR%
    )
  )
)

echo.
echo ---------- ตั้งค่า PATH ----------
if defined DRY (
  echo   [ทดลอง] จะเพิ่ม C:\flutter\bin ลงใน PATH ของผู้ใช้ ถ้ายังไม่มี
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$p = [Environment]::GetEnvironmentVariable('Path','User'); if ($null -eq $p) { $p = '' }; if ($p -notlike '*C:\flutter\bin*') { [Environment]::SetEnvironmentVariable('Path', ($p.TrimEnd(';') + ';C:\flutter\bin').TrimStart(';'), 'User'); Write-Host '   [OK] added C:\flutter\bin to PATH' } else { Write-Host '   [skip] PATH already has C:\flutter\bin' }"
)

echo.
echo ---------- ไลบรารี Python สำหรับสร้างสไลด์ (ไม่บังคับ) ----------
if defined DRY (
  echo   [ทดลอง] จะสั่ง py -3 -m pip install python-pptx pillow
) else (
  where py >nul 2>&1
  if errorlevel 1 (
    echo   [ข้าม] ยังเรียก Python ไม่ได้ในหน้าต่างนี้
    echo          หลังรีสตาร์ตเครื่องแล้วค่อยสั่ง:  pip install python-pptx pillow
  ) else (
    py -3 -m pip install --quiet --disable-pip-version-check python-pptx pillow
    if errorlevel 1 (
      echo   [!] ติดตั้งไม่สำเร็จ ลองใหม่ภายหลังด้วย:  pip install python-pptx pillow
    ) else (
      echo   [OK] ติดตั้ง python-pptx และ pillow แล้ว
    )
  )
)

echo.
echo ==========================================================
echo    ติดตั้งเสร็จแล้ว - เหลืออีก 3 ขั้นที่ต้องทำเอง
echo ==========================================================
echo.
echo   1. รีสตาร์ตเครื่อง 1 ครั้ง เพื่อให้ค่า PATH มีผล
echo.
echo   2. เปิด Developer Mode ของ Windows
echo      กด Start - พิมพ์ "Developer settings" - เปิดสวิตช์ Developer Mode
echo      ถ้าไม่เปิด จะติดตั้งแพ็กเกจของ Flutter ไม่ได้
echo.
echo   3. เปิดโฟลเดอร์โปรเจกต์ใน PowerShell แล้วสั่งทีละบรรทัด
echo         flutter pub get
echo         dart run build_runner build --delete-conflicting-outputs
echo         flutter run -d chrome
echo.
if defined SKIPPED (
  echo   * มีบางขั้นที่ยังไม่สำเร็จ ดูข้อความ [X] ด้านบน
  echo     แก้ตามนั้นแล้วรันไฟล์นี้ซ้ำได้ ไม่เสียหาย
  echo.
)
echo   อยากสร้างไฟล์ APK หรือใช้ emulator ด้วย ต้องลง Android Studio เพิ่ม
echo   วิธีลงอยู่ในไฟล์ SETUP.md หัวข้อ 2.2
echo.
pause
exit /b 0

:install_one
echo.
echo ---------- %~2 ----------
if defined DRY (
  echo   [ทดลอง] จะสั่ง winget install --id %~1 --exact --silent
  exit /b 0
)
winget list --id %1 --exact >nul 2>&1
if not errorlevel 1 (
  echo   [ข้าม] ติดตั้งอยู่แล้ว
  exit /b 0
)
echo   กำลังติดตั้ง...
winget install --id %1 --exact --silent --accept-package-agreements --accept-source-agreements
if errorlevel 1 (
  echo   [X] ติดตั้งไม่สำเร็จ ลองติดตั้งเองภายหลัง
  set "SKIPPED=1"
) else (
  echo   [OK] เสร็จแล้ว
)
exit /b 0
