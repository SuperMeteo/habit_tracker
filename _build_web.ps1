$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$outDir = if ($args.Count -ge 1 -and $args[0]) { $args[0] } else { 'build\web' }

$flutter = (Get-Command flutter -ErrorAction SilentlyContinue)
if ($flutter) {
  $flutterPath = $flutter.Source
} elseif (Test-Path 'C:\flutter\bin\flutter.bat') {
  $flutterPath = 'C:\flutter\bin\flutter.bat'
} else {
  Write-Host ''
  Write-Host '  [X] หา Flutter ไม่เจอ - ลง Flutter ก่อนด้วย ติดตั้งเครื่องมือ.bat'
  exit 1
}

# ล้างโฟลเดอร์ผลลัพธ์เก่าก่อนเสมอ
# ถ้ามีของเก่าค้างอยู่ ขั้นคัดลอกฟอนต์จะถูกข้ามแบบเงียบ ๆ
# ผลคือไอคอนทุกตัวในแอปกลายเป็นกล่องสี่เหลี่ยม
if (Test-Path $outDir) {
  Remove-Item -Recurse -Force $outDir -ErrorAction SilentlyContinue
}

$keysFile = Join-Path $PSScriptRoot '_keys.ps1'
if (Test-Path $keysFile) {
  . $keysFile
}

if ($SUPABASE_URL -and $SUPABASE_ANON_KEY) {
  Write-Host ''
  Write-Host "  โหมดออนไลน์ - ต่อเซิร์ฟเวอร์ $SUPABASE_URL"
  Write-Host ''
  & $flutterPath build web --release -o $outDir `
    --dart-define=SUPABASE_URL=$SUPABASE_URL `
    --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
} else {
  Write-Host ''
  Write-Host '  [!] ไม่พบไฟล์ _keys.ps1 - จะสร้างเป็นเวอร์ชันออฟไลน์'
  Write-Host '      (ใช้บันทึกนิสัยได้ครบ แต่ไม่มีระบบสมาชิกและอันดับ)'
  Write-Host ''
  & $flutterPath build web --release -o $outDir
}

exit $LASTEXITCODE
