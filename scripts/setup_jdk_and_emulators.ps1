Param(
    [switch]$StartEmulators
)

Write-Host "=== Setup JDK (Temurin) and optionally start Firebase Emulators ==="

function ExitWith($msg, $code=1){
    Write-Host $msg -ForegroundColor Red
    exit $code
}

# Try to detect existing java
try{
    $jver = & java -version 2>&1 | Out-String
} catch {
    $jver = $null
}

if ($jver) {
    Write-Host "Java detected:" -ForegroundColor Cyan
    Write-Host $jver
} else {
    Write-Host "No Java runtime found in PATH." -ForegroundColor Yellow
}

function Install-Temurin {
    Write-Host "Trying to install Temurin (Adoptium) via winget..." -ForegroundColor Cyan
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "winget not found. Please install App Installer from Microsoft Store or install JDK manually: https://adoptium.net/" -ForegroundColor Yellow
        return $false
    }

    # Try recommended LTS (17)
    $pkg = 'EclipseAdoptium.Temurin.17'
    Write-Host "Installing $pkg via winget (requires admin privileges)..."
    try{
        winget install --id $pkg -e --accept-package-agreements --accept-source-agreements
        return $true
    } catch {
        Write-Host "winget install failed: $_" -ForegroundColor Yellow
        return $false
    }
}

if ($jver -and ($jver -match 'version "(?<maj>\d+)')) {
    $maj = [int]$Matches['maj']
    if ($maj -ge 11) {
        Write-Host "Java major version $maj is already installed and >=11. Skipping install." -ForegroundColor Green
    } else {
        Write-Host "Java major version $maj found (<11). Installing Temurin 17..." -ForegroundColor Yellow
        $ok = Install-Temurin
        if (-not $ok) { ExitWith "Automatic install failed. Please install a JDK 11+ manually from https://adoptium.net/" }
    }
} else {
    Write-Host "No usable Java detected. Installing Temurin 17..." -ForegroundColor Yellow
    $ok = Install-Temurin
    if (-not $ok) { ExitWith "Automatic install failed. Please install a JDK 11+ manually from https://adoptium.net/" }
}

# Try to find a JDK install location (Temurin typical path)
$possible = @(
    "$Env:ProgramFiles\Eclipse Adoptium\jdk-17*",
    "$Env:ProgramFiles\Eclipse Adoptium\jdk-11*",
    "$Env:ProgramFiles(x86)\Eclipse Adoptium\jdk-17*",
    "$Env:ProgramFiles\AdoptOpenJDK\jdk-17*",
    "$Env:ProgramFiles\Amazon Corretto\jdk-17*",
    "$Env:ProgramFiles\OpenJDK\*",
)

$found = $null
foreach ($p in $possible) {
    $dirs = Get-ChildItem -Path $p -Directory -ErrorAction SilentlyContinue
    if ($dirs) { $found = $dirs[0].FullName; break }
}

if (-not $found) {
    # fallback: try 'where java' and resolve parent
    $where = (& where.exe java) -join "`n"
    if ($where) {
        $where = $where.Split("`n")[0].Trim()
        $binDir = Split-Path $where -Parent
        $found = Split-Path $binDir -Parent
    }
}

if ($found) {
    Write-Host "Detected JDK path: $found" -ForegroundColor Green
    # Set JAVA_HOME for current user
    Write-Host "Setting JAVA_HOME (user) to $found"
    setx JAVA_HOME "$found" | Out-Null
    # Update PATH for current session
    $env:JAVA_HOME = $found
    $env:Path = "$found\bin;" + $env:Path
    Write-Host "JAVA_HOME set. Please restart your terminal windows to make it persistent system-wide." -ForegroundColor Green
} else {
    Write-Host "Could not auto-detect JDK install path. Please set JAVA_HOME manually if needed." -ForegroundColor Yellow
}

Write-Host "Verifying java -version..." -ForegroundColor Cyan
try{
    & java -version 2>&1 | Write-Host
} catch {
    Write-Host "java command still not working. You may need to restart your terminal or start a new PowerShell session." -ForegroundColor Red
}

if ($StartEmulators) {
    Write-Host "Starting Firebase Emulators (firestore, storage, auth)..." -ForegroundColor Cyan
    Push-Location -Path (Split-Path -Parent $MyInvocation.MyCommand.Definition)
    # Move to repo root (two levels up from scripts/)
    $repoRoot = Resolve-Path "..\.."
    Set-Location $repoRoot
    try{
        firebase emulators:start --only "firestore,storage,auth"
    } catch {
        Write-Host "Failed to start emulators: $_" -ForegroundColor Red
    }
    Pop-Location
} else {
    Write-Host "Done. To start emulators later run this script with -StartEmulators or run: firebase emulators:start --only \"firestore,storage,auth\"" -ForegroundColor Green
}
