# scripts/run_device.ps1
#
# Build, installe et lance Murabbi sur le device Android connecte.
# Lit les credentials Supabase depuis .env.local > .env.cloud > .env.
#
# Usage:
#   .\scripts\run_device.ps1                  # debug + hot-reload
#   .\scripts\run_device.ps1 -Release         # release (perf / smoke test)
#   .\scripts\run_device.ps1 -Clean           # flutter clean avant build
#   .\scripts\run_device.ps1 -Device <id>     # device explicite (multi-device)
#   .\scripts\run_device.ps1 -BuildOnly       # build APK + install sans lancer
#
# Prerequis : flutter et adb dans le PATH, debogage USB active sur le device.

param(
    [switch]$Release,
    [switch]$Clean,
    [switch]$BuildOnly,
    [string]$Device = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# -- Helpers ------------------------------------------------------------------

function Read-EnvFile {
    param([string]$Path)
    $vars = @{}
    if (-not (Test-Path $Path)) { return $vars }
    Get-Content $Path | ForEach-Object {
        if ($_ -match '^\s*([A-Z_][A-Z0-9_]*)\s*=\s*(.+)\s*$') {
            $vars[$matches[1]] = $matches[2].Trim('"', "'")
        }
    }
    return $vars
}

function Write-Step { param([string]$Msg); Write-Host "" ; Write-Host ">> $Msg" -ForegroundColor Cyan }
function Write-Ok   { param([string]$Msg); Write-Host "   OK  $Msg" -ForegroundColor Green }
function Write-Fail { param([string]$Msg); Write-Host "   FAIL $Msg" -ForegroundColor Red }

# -- 1. Credentials Supabase (.env < .env.cloud < .env.local) ----------------

Write-Step "Chargement des credentials Supabase..."

$project_root = Join-Path $PSScriptRoot ".."
$env_vars = @{}
foreach ($file in @('.env', '.env.cloud', '.env.local')) {
    $loaded = Read-EnvFile (Join-Path $project_root $file)
    foreach ($k in $loaded.Keys) { $env_vars[$k] = $loaded[$k] }
}

$SUPABASE_URL      = $env_vars['SUPABASE_URL']
$SUPABASE_ANON_KEY = $env_vars['SUPABASE_ANON_KEY']

if (-not $SUPABASE_URL -or -not $SUPABASE_ANON_KEY) {
    Write-Fail "Credentials Supabase introuvables."
    Write-Host ""
    Write-Host "  Cree .env.local a la racine du projet avec :"
    Write-Host "    SUPABASE_URL=https://<ref>.supabase.co"
    Write-Host "    SUPABASE_ANON_KEY=<anon-key>"
    Write-Host ""
    Write-Host "  Fichiers recherches (par priorite) : .env.local > .env.cloud > .env"
    exit 1
}

$url_host = ([uri]$SUPABASE_URL).Host
Write-Ok "Credentials charges -- projet : $url_host"

# -- 2. Verification des outils -----------------------------------------------

Write-Step "Verification des outils..."

foreach ($tool in @('flutter', 'adb')) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-Fail "'$tool' introuvable dans le PATH."
        if ($tool -eq 'adb') {
            Write-Host "  Installe Android SDK Platform Tools et ajoute sdk/platform-tools au PATH"
        }
        exit 1
    }
}
Write-Ok "flutter et adb disponibles"

# -- 3. Device Android connecte -----------------------------------------------

Write-Step "Recherche du device Android..."

$adb_lines  = & adb devices 2>&1
$connected  = @($adb_lines | Where-Object { $_ -match "`tdevice$" })

if ($connected.Count -eq 0) {
    Write-Fail "Aucun device Android connecte."
    Write-Host ""
    Write-Host "  Branche ton telephone via USB"
    Write-Host "  Active 'Debogage USB' dans Options developpeur"
    Write-Host "  Accepte la demande d'autorisation sur le telephone"
    Write-Host ""
    Write-Host "  Sortie adb devices :"
    $adb_lines | ForEach-Object { Write-Host "    $_" }
    exit 1
}

if ($connected.Count -gt 1 -and -not $Device) {
    Write-Fail "Plusieurs devices detectes -- specifie -Device <id> :"
    $connected | ForEach-Object { Write-Host "    $_" }
    exit 1
}

$detected_id   = ($connected[0] -split "`t")[0].Trim()
$target_device = if ($Device) { $Device } else { $detected_id }
Write-Ok "Device : $target_device"

# -- 4. Flutter clean (optionnel) ---------------------------------------------

if ($Clean) {
    Write-Step "flutter clean + pub get..."
    Push-Location $project_root
    & flutter clean
    & flutter pub get
    Pop-Location
    Write-Ok "Clean termine"
}

# -- 5. Build / Run -----------------------------------------------------------

$dart_defines = @(
    "--dart-define=SUPABASE_URL=$SUPABASE_URL",
    "--dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"
)

$mode_flag  = if ($Release) { '--release' } else { '--debug' }
$mode_label = if ($Release) { 'release' } else { 'debug' }

Push-Location $project_root

if ($BuildOnly) {
    Write-Step "flutter build apk ($mode_label)..."

    & flutter build apk $mode_flag @dart_defines
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "flutter build apk a echoue."
        Pop-Location; exit $LASTEXITCODE
    }

    $apk = if ($Release) {
        'build/app/outputs/flutter-apk/app-release.apk'
    } else {
        'build/app/outputs/flutter-apk/app-debug.apk'
    }

    Write-Ok "APK : $apk"
    Write-Step "Installation sur $target_device..."

    & adb -s $target_device install -r $apk
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "adb install a echoue."
        Pop-Location; exit $LASTEXITCODE
    }
    Write-Ok "Installation reussie"

    Write-Step "Lancement de l'app..."
    & adb -s $target_device shell am start -n 'com.murabbi.mobile/.MainActivity'
    Write-Ok "App lancee"

} else {
    Write-Step "flutter run ($mode_label) sur $target_device..."
    Write-Host "  r = hot reload   R = hot restart   q = quitter" -ForegroundColor DarkGray

    & flutter run $mode_flag -d $target_device @dart_defines
    $exit_code = $LASTEXITCODE
    Pop-Location
    exit $exit_code
}

Pop-Location
