$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch { }

$root = $null
foreach ($candidate in @((Join-Path $PSScriptRoot 'build\web'), (Join-Path $PSScriptRoot 'web'))) {
    $hasIndex = Test-Path (Join-Path $candidate 'index.html')
    $hasBuilt = (Test-Path (Join-Path $candidate 'flutter_bootstrap.js')) -or (Test-Path (Join-Path $candidate 'main.dart.js'))
    if ($hasIndex -and $hasBuilt) {
        $root = (Resolve-Path $candidate).Path
        break
    }
}

if (-not $root) {
    Write-Host ''
    Write-Host '  [X] ไม่พบไฟล์แอป'
    Write-Host '      ถ้าเป็นเครื่องที่ใช้พัฒนา ให้กดไฟล์  อัปเดตแอป.bat  ก่อน 1 ครั้ง'
    Write-Host ''
    Read-Host '  กด Enter เพื่อปิด'
    exit 1
}

$mime = @{
    '.html' = 'text/html; charset=utf-8'
    '.htm'  = 'text/html; charset=utf-8'
    '.js'   = 'text/javascript'
    '.mjs'  = 'text/javascript'
    '.css'  = 'text/css'
    '.json' = 'application/json'
    '.wasm' = 'application/wasm'
    '.png'  = 'image/png'
    '.jpg'  = 'image/jpeg'
    '.jpeg' = 'image/jpeg'
    '.gif'  = 'image/gif'
    '.svg'  = 'image/svg+xml'
    '.ico'  = 'image/x-icon'
    '.ttf'  = 'font/ttf'
    '.otf'  = 'font/otf'
    '.woff' = 'font/woff'
    '.woff2' = 'font/woff2'
    '.txt'  = 'text/plain; charset=utf-8'
    '.map'  = 'application/json'
}

$listener = $null
$port = 0
foreach ($candidatePort in 8000..8050) {
    try {
        $try = New-Object System.Net.HttpListener
        $try.Prefixes.Add("http://localhost:$candidatePort/")
        $try.Start()
        $listener = $try
        $port = $candidatePort
        break
    } catch {
        if ($try) { try { $try.Close() } catch { } }
    }
}

if (-not $listener) {
    Write-Host ''
    Write-Host '  [X] เปิดเซิร์ฟเวอร์ไม่ได้ พอร์ต 8000-8050 ถูกใช้หมด'
    Read-Host '  กด Enter เพื่อปิด'
    exit 1
}

$url = "http://localhost:$port/"

$browser = $null
$candidates = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "$env:LocalAppData\Google\Chrome\Application\chrome.exe",
    "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
)
foreach ($candidate in $candidates) {
    if (Test-Path $candidate) { $browser = $candidate; break }
}

Write-Host ''
Write-Host '  ==================================================='
Write-Host '     Habit Tracker'
Write-Host '  ==================================================='
Write-Host ''
Write-Host "     แอปเปิดอยู่ที่  $url"
Write-Host ''
Write-Host '     * ปิดแอป = ปิดหน้าต่างสีดำนี้'
Write-Host '     * ถ้าแอปไม่เด้งขึ้นมา ให้ก๊อป URL ข้างบนไปเปิดในเบราว์เซอร์'
Write-Host '     * อยากได้ไอคอนบนเดสก์ท็อป: ในเบราว์เซอร์กดเมนู ... แล้วเลือก'
Write-Host '       "ติดตั้ง Habit Tracker" (Install)'
Write-Host ''

try {
    if ($browser) {
        Start-Process -FilePath $browser -ArgumentList "--app=$url"
    } else {
        Start-Process $url
    }
} catch {
    Write-Host '     (เปิดเบราว์เซอร์อัตโนมัติไม่ได้ ให้ก๊อป URL ไปเปิดเอง)'
}

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $requestPath = [Uri]::UnescapeDataString($context.Request.Url.AbsolutePath)
        if ($requestPath -eq '/') { $requestPath = '/index.html' }

        $file = Join-Path $root ($requestPath.TrimStart('/').Replace('/', '\'))
        $file = [IO.Path]::GetFullPath($file)
        $response = $context.Response

        if (-not $file.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) {
            $file = Join-Path $root 'index.html'
        }
        if (-not (Test-Path $file -PathType Leaf)) {
            if ([IO.Path]::GetExtension($file)) {
                Write-Host ("  [404] " + $requestPath)
                $response.StatusCode = 404
                $response.ContentType = 'text/plain; charset=utf-8'
                $missing = [Text.Encoding]::UTF8.GetBytes("ไม่พบไฟล์ $requestPath")
                $response.ContentLength64 = $missing.Length
                $response.OutputStream.Write($missing, 0, $missing.Length)
                $response.OutputStream.Close()
                continue
            }
            $file = Join-Path $root 'index.html'
        }

        $extension = [IO.Path]::GetExtension($file).ToLower()
        $response.ContentType = if ($mime.ContainsKey($extension)) { $mime[$extension] } else { 'application/octet-stream' }
        $response.Headers.Add('Cross-Origin-Opener-Policy', 'same-origin')
        $response.Headers.Add('Cross-Origin-Embedder-Policy', 'require-corp')
        $response.Headers.Add('Cache-Control', 'no-store')

        $bytes = [IO.File]::ReadAllBytes($file)
        $response.ContentLength64 = $bytes.Length
        $response.OutputStream.Write($bytes, 0, $bytes.Length)
        $response.OutputStream.Close()
    } catch {
        continue
    }
}
