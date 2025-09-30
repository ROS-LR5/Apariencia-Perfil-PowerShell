# install-oh-my-posh-ROSN-LR5.ps1
# Autor: ROSN-LR5 (entrega)
# Versión: 3.3
# Requisitos: PowerShell 7.x. Ejecuta como Administrador si deseas instalación system-wide.

[CmdletBinding()]
param(
    [switch]$UserScope    # usar -UserScope para instalación por usuario (no requiere admin)
)

function Write-Info($m){ Write-Host $m -ForegroundColor Cyan }
function Write-Warn($m){ Write-Host $m -ForegroundColor Yellow }
function Write-Ok($m){ Write-Host $m -ForegroundColor Green }
function Write-Err($m){ Write-Host $m -ForegroundColor Red }

Write-Info "R O S N - L R 5"
Write-Ok "🚀 Iniciando instalación Oh My Posh (persistente)..."

# ---------- Perfil y backup ----------
$ProfilePath = $PROFILE
$ProfileDir = Split-Path -Parent $ProfilePath
if (-not (Test-Path $ProfileDir)) { New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null }
if (-not (Test-Path $ProfilePath)) { New-Item -ItemType File -Path $ProfilePath -Force | Out-Null }

$BackupPath = "$ProfilePath.backup"
if (-not (Test-Path $BackupPath)) {
    Copy-Item -Path $ProfilePath -Destination $BackupPath -Force
    Write-Ok "✅ Backup creado en: $BackupPath"
} else {
    Write-Info "ℹ️ Backup ya existe en: $BackupPath"
}

# ---------- Intento de instalación oficial (winget -> install.ps1) ----------
$installed = $false
$hasWinget = (Get-Command winget -ErrorAction SilentlyContinue) -ne $null

if ($hasWinget) {
    Write-Info "🔧 Intentando instalar/actualizar via winget..."
    try {
        if ($UserScope) {
            winget install JanDeDobbeleer.OhMyPosh --source winget --scope user --accept-source-agreements --accept-package-agreements --silent
        } else {
            winget install JanDeDobbeleer.OhMyPosh --source winget --scope machine --accept-source-agreements --accept-package-agreements --silent
        }
        Start-Sleep -Seconds 2
        if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) { $installed = $true; Write-Ok "✅ Oh My Posh instalado via winget." }
        else { Write-Warn "⚠️ Winget no dejó el comando disponible en la sesión actual." }
    } catch {
        Write-Warn "⚠️ Winget instaló falló o no pudo completar: $_"
    }
} else {
    Write-Info "ℹ️ winget no disponible en este sistema, intentaré fallback."
}

# ---------- Fallback: descargar binario oficial (zip) ----------
if (-not $installed) {
    Write-Info "⬇️ Fallback: descargando binario oficial desde GitHub Releases..."
    $InstallRoot = if ($UserScope) { Join-Path $env:LOCALAPPDATA "Programs\oh-my-posh" } else { "C:\Tools\oh-my-posh" }
    $BinDir = Join-Path $InstallRoot "bin"
    if (-not (Test-Path $BinDir)) { New-Item -ItemType Directory -Path $BinDir -Force | Out-Null }

    $zipUrl = "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-windows-amd64.zip"
    $tmp = Join-Path $env:TEMP "posh-windows-amd64.zip"

    try {
        Invoke-WebRequest -Uri $zipUrl -OutFile $tmp -UseBasicParsing -ErrorAction Stop
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($tmp, $BinDir, $true)
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
        Write-Ok "✅ Binario extraído en: $BinDir"

        $exe = Get-ChildItem -Path $BinDir -Filter *.exe -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($exe) {
            Copy-Item -Path $exe.FullName -Destination (Join-Path $BinDir "oh-my-posh.exe") -Force
            $env:Path = "$env:Path;$BinDir"
            Write-Ok "✅ oh-my-posh preparado en esta sesión: $BinDir\oh-my-posh.exe"
            $installed = $true
        } else {
            Write-Warn "⚠️ No se encontró ejecutable dentro del zip."
        }
    } catch {
        Write-Err "❌ Fallback falló: $_"
    }
}

# ---------- Asegurar PATH persistente de usuario ----------
if ($installed) {
    $binToPersist = if ($installed -and (Test-Path (Join-Path $env:LOCALAPPDATA "Programs\oh-my-posh\bin"))) { Join-Path $env:LOCALAPPDATA "Programs\oh-my-posh\bin" } elseif (Test-Path $BinDir) { $BinDir } else { $null }
    if ($binToPersist) {
        $regName = "PATH"
        $currentUserPath = [Environment]::GetEnvironmentVariable($regName, "User")
        if ($currentUserPath -notlike "*$binToPersist*") {
            $newPath = if ([string]::IsNullOrEmpty($currentUserPath)) { $binToPersist } else { "$currentUserPath;$binToPersist" }
            [Environment]::SetEnvironmentVariable($regName, $newPath.TrimEnd(';'), "User")
            Write-Ok "✅ PATH de usuario actualizado (persistente) con: $binToPersist"
            # aplicar a la sesión actual también
            if ($env:Path -notlike "*$binToPersist*") { $env:Path = "$env:Path;$binToPersist" }
        } else {
            Write-Info "ℹ️ El PATH de usuario ya contiene la ruta: $binToPersist"
        }
    }
} else {
    Write-Warn "⚠️ oh-my-posh no pudo instalarse. Revisa permisos o instala manualmente desde https://ohmyposh.dev"
}

# ---------- Instalar fuentes (Meslo / Nerd) ----------
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    Write-Info "🔤 Intentando instalar Meslo Nerd Font via oh-my-posh..."
    try {
        oh-my-posh font install meslo | Out-Null
        Write-Ok "✅ oh-my-posh intentó instalar Meslo (si fue posible)."
    } catch {
        Write-Warn "⚠️ oh-my-posh no pudo instalar fuentes automáticamente. Puedes instalar Meslo manualmente."
    }
} else {
    Write-Warn "ℹ️ Omitting font install: oh-my-posh no disponible."
}

# ---------- Descargar temas locales ----------
$CustomThemesPath = Join-Path $env:USERPROFILE "oh-my-posh-themes"
if (-not (Test-Path $CustomThemesPath)) { New-Item -ItemType Directory -Path $CustomThemesPath -Force | Out-Null }

$themes = @(
    "M365Princess","agnoster","atomic","cert","clean-detailed",
    "cloud-native-azure","jonnychipz","kushal","stelbent.minimal",
    "tokyo","glowsticks","paradox","jandedobbeleer",
    "powerlevel10k_rainbow","minimal","ys"
)

Write-Info "⬇️ Descargando temas desde GitHub (raw)..."
foreach ($theme in $themes) {
    $candidates = @(
        "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/$theme.omp.json",
        "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/$theme.omp.yaml",
        "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/$theme.omp.yml",
        "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/$theme.json",
        "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/$theme.yaml",
        "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/$theme.yml"
    )
    $downloaded = $false
    foreach ($url in $candidates) {
        $ext = [IO.Path]::GetExtension($url)
        $out = Join-Path $CustomThemesPath "$theme$ext"
        try {
            Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing -ErrorAction Stop
            Write-Ok "✅ Tema descargado: $theme -> $out"
            $downloaded = $true
            break
        } catch { }
    }
    if (-not $downloaded) { Write-Warn "⚠️ No se pudo descargar el tema: $theme" }
}

Write-Ok "🎨 Temas disponibles en: $CustomThemesPath"

# ---------- Bloque persistente para el perfil ----------
$ConfigBlock = @'
# ===== Oh My Posh Persistent Configuration =====
function Set-PoshTheme {
    param([Parameter(Mandatory=$true)][string]$theme)
    $homeThemes = Join-Path $env:USERPROFILE "oh-my-posh-themes"
    $paths = @(
        Join-Path $homeThemes "$theme.omp.json",
        Join-Path $homeThemes "$theme.omp.yaml",
        Join-Path $homeThemes "$theme.omp.yml",
        Join-Path $homeThemes "$theme.json",
        Join-Path $homeThemes "$theme.yaml",
        Join-Path $homeThemes "$theme.yml"
    ) | Where-Object { Test-Path $_ }
    if ($paths.Count -eq 0) { Write-Host "❌ Tema no encontrado: $theme" -ForegroundColor Red; return }
    $themePath = $paths[0]
    if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) { Write-Host "❌ oh-my-posh no disponible en PATH." -ForegroundColor Red; return }
    try {
        $init = & oh-my-posh init pwsh --config "$themePath"
        Invoke-Expression $init
    } catch {
        oh-my-posh init pwsh --config "$themePath" --eval | Invoke-Expression
    }
    $env:POSH_THEME = $theme
    Set-Content -Path (Join-Path $env:USERPROFILE ".poshtheme") -Value $theme -Force
    Write-Host "✅ Tema aplicado y guardado: $theme" -ForegroundColor Green
}
# Restaurar al iniciar si existe .poshtheme
if (Test-Path (Join-Path $env:USERPROFILE ".poshtheme")) {
    $last = Get-Content (Join-Path $env:USERPROFILE ".poshtheme") -ErrorAction SilentlyContinue
    if ($last) { Set-PoshTheme $last }
}
# ===== end persistent config =====
'@

$profileContent = Get-Content -Path $ProfilePath -Raw -ErrorAction SilentlyContinue
if ($profileContent -notlike "*Oh My Posh Persistent Configuration*") {
    Add-Content -Path $ProfilePath -Value "`n$ConfigBlock"
    Write-Ok "✅ Perfil actualizado con configuración persistente: $ProfilePath"
} else {
    Write-Info "ℹ️ Perfil ya contiene configuración persistente. No se agregó duplicado."
}

Write-Ok "`n🎉 Instalación finalizada."
Write-Info "Recarga el perfil con: . $PROFILE  o cierra/abre la terminal para aplicar cambios persistentes."
Write-Info "Aplica un tema manualmente: Set-PoshTheme 'tokyo' o oh-my-posh init pwsh --config '$CustomThemesPath\tokyo.json' | Invoke-Expression"
