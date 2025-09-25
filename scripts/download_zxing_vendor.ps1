Param(
    [string]$DestPath = "$PSScriptRoot\..\web\vendor\zxing\index.min.js",
    [string]$SourceUrl = 'https://unpkg.com/@zxing/library@0.19.1/umd/index.min.js'
)

Write-Host "Downloading ZXing UMD to: $DestPath"

function ExitWith($msg){ Write-Host $msg -ForegroundColor Red; exit 1 }

if (-not (Get-Command Invoke-WebRequest -ErrorAction SilentlyContinue)) {
    Write-Host "Invoke-WebRequest not available. This script requires PowerShell with Invoke-WebRequest." -ForegroundColor Red
    exit 1
}

$destDir = Split-Path $DestPath -Parent
if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }

if (Test-Path $DestPath) {
    $bak = "$DestPath.bak"
    Write-Host "Existing file found. Backing up to $bak"
    Copy-Item $DestPath $bak -Force
}

Write-Host "Fetching $SourceUrl ..."
try{
    Invoke-WebRequest -Uri $SourceUrl -OutFile $DestPath -UseBasicParsing -ErrorAction Stop
} catch {
    Write-Host "Download failed from $SourceUrl: $_" -ForegroundColor Yellow
    Write-Host "Trying jsdelivr CDN..."
    $alt = 'https://cdn.jsdelivr.net/npm/@zxing/library@0.19.1/umd/index.min.js'
    try{
        Invoke-WebRequest -Uri $alt -OutFile $DestPath -UseBasicParsing -ErrorAction Stop
    } catch {
        ExitWith "Both downloads failed. Please download the file manually from https://github.com/zxing-js/library/releases and place it at $DestPath"
    }
}

if ((Get-Item $DestPath).Length -lt 1024) {
    Write-Host "Downloaded file is unexpectedly small (<1KB). Check the file: $DestPath" -ForegroundColor Yellow
} else {
    Write-Host "Downloaded ZXing UMD to $DestPath" -ForegroundColor Green
}

Write-Host "Done. You can now build the web app or run the emulator and test the scanner." -ForegroundColor Cyan
