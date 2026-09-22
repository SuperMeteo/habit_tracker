$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

. (Join-Path $PSScriptRoot '_keys.ps1')

Write-Host ''
Write-Host '  =========================================================='
Write-Host '     Habit Tracker - โหมดออนไลน์ (มีระบบสมาชิก)'
Write-Host '  =========================================================='
Write-Host ''
Write-Host "     เซิร์ฟเวอร์: $SUPABASE_URL"
Write-Host ''
Write-Host '     กำลังสร้างแอป... ใช้เวลาประมาณ 1 นาที'
Write-Host ''

& (Join-Path $PSScriptRoot '_build_web.ps1')

if ($LASTEXITCODE -ne 0) {
  Write-Host ''
  Write-Host '  [X] สร้างแอปไม่สำเร็จ - ดูข้อความผิดพลาดข้างบน'
  Read-Host '  กด Enter เพื่อปิด'
  exit 1
}

Write-Host ''
Write-Host '  [OK] สร้างเสร็จแล้ว - กำลังเปิดแอป'
Write-Host ''

& (Join-Path $PSScriptRoot '_serve.ps1')
