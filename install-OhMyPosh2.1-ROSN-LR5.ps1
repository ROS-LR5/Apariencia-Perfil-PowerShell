# install-oh-my-posh-ROSN-LR5.ps1
# Autor: ROSN-LR5
# Versión: 4.5
# Requisitos: PowerShell 7.x. Ejecuta como Administrador para instalación system-wide (opcional).
[CmdletBinding()]
param([switch]$UserScope)

function Info($m){ Write-Host $m -ForegroundColor Cyan }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Err($m){ Write-Host $m -ForegroundColor Red }

Info "R O S N - L R 5"
Ok "🚀 Iniciando instalación Oh My Posh (persistente)..."

# ---------------- Prepare profile & backup ----------------
$ProfilePath = $PROFILE
$ProfileDir  = Split-Path -Parent $ProfilePath
if (-not (Test-Path $ProfileDir)) { New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null }
if (-not (Test-Path $ProfilePath)) { New-Item -ItemType File -Path $ProfilePath -Force | Out-Null }

$BackupPath = "$ProfilePath.backup"
if (-not (Test-Path $BackupPath)) {
    Copy-Item -Path $ProfilePath -Destination $BackupPath -Force
    Ok "✅ Backup del perfil creado en: $BackupPath"
} else {
    Info "ℹ️ Backup ya existe en: $BackupPath"
}

# ---------------- Official installer via winget ----------------
$installed = $false
$hasWinget  = (Get-Command winget -ErrorAction SilentlyContinue) -ne $null

if ($hasWinget) {
    Info "🔧 Intentando instalar/actualizar Oh My Posh via winget..."
    try {
        if ($UserScope) {
            winget install JanDeDobbeleer.OhMyPosh --source winget --scope user --force --accept-source-agreements --accept-package-agreements
        } else {
            winget install JanDeDobbeleer.OhMyPosh --source winget --scope machine --force --accept-source-agreements --accept-package-agreements
        }
        Start-Sleep -Seconds 2
        if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) { $installed = $true; Ok "✅ Oh My Posh instalado via winget." } else { Warn "⚠️ Winget completó pero el comando no está disponible en la sesión actual. Reinicia la terminal." }
    } catch {
        Warn "⚠️ Winget falló o no puede instalar en este sistema: $_"
    }
} else {
    Info "ℹ️ winget no disponible, lanzar fallback."
}

# ---------------- Fallback: download release zip and extract ----------------
if (-not $installed) {
    Info "⬇️ Fallback: descargando binario oficial desde GitHub Releases..."
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
        Ok "✅ Binario extraído en: $BinDir"

        $exe = Get-ChildItem -Path $BinDir -Filter *.exe -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($exe) {
            Copy-Item -Path $exe.FullName -Destination (Join-Path $BinDir "oh-my-posh.exe") -Force
            if ($env:Path -notlike "*$BinDir*") { $env:Path = "$env:Path;$BinDir" }
            Ok "✅ oh-my-posh preparado en esta sesión: $BinDir\oh-my-posh.exe"
            $installed = $true
        } else {
            Warn "⚠️ No se encontró ejecutable dentro del zip extraído."
        }
    } catch {
        Err "❌ Fallback falló: $_"
    }
}

# ---------------- Ensure PATH persistent for user ----------------
if ($installed) {
    $binToPersist = if (Test-Path (Join-Path $env:LOCALAPPDATA "Programs\oh-my-posh\bin")) { Join-Path $env:LOCALAPPDATA "Programs\oh-my-posh\bin" } elseif (Test-Path $BinDir) { $BinDir } else { $null }
    if ($binToPersist) {
        $regName = "PATH"
        $currentUserPath = [Environment]::GetEnvironmentVariable($regName, "User")
        if ($currentUserPath -notlike "*$binToPersist*") {
            $newPath = if ([string]::IsNullOrEmpty($currentUserPath)) { $binToPersist } else { "$currentUserPath;$binToPersist" }
            [Environment]::SetEnvironmentVariable($regName, $newPath.TrimEnd(';'), "User")
            Ok "✅ PATH de usuario actualizado con: $binToPersist"
            if ($env:Path -notlike "*$binToPersist*") { $env:Path = "$env:Path;$binToPersist" }
        } else {
            Info "ℹ️ El PATH de usuario ya contiene la ruta: $binToPersist"
        }
    }
} else {
    Err "❌ oh-my-posh no pudo instalarse. Revisa permisos o instala manualmente desde https://ohmyposh.dev"
}

# ---------------- Fonts: attempt via CLI, fallback download ----------------
function Install-Meslo {
    try {
        $mesloZip = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
        $tmpZip = Join-Path $env:TEMP "meslo_nerd.zip"
        Invoke-WebRequest -Uri $mesloZip -OutFile $tmpZip -UseBasicParsing -ErrorAction Stop
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $extractDir = Join-Path $env:TEMP "meslo_nerd_fonts"
        if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue }
        [System.IO.Compression.ZipFile]::ExtractToDirectory($tmpZip, $extractDir)
        Remove-Item $tmpZip -Force -ErrorAction SilentlyContinue
        $ttfs = Get-ChildItem -Path $extractDir -Filter *.ttf -Recurse -File -ErrorAction SilentlyContinue
        if ($ttfs.Count -eq 0) { Warn "⚠️ No se encontraron TTFs al extraer Meslo."; return $false }
        foreach ($f in $ttfs) {
            $dest = Join-Path $env:WINDIR "Fonts\$($f.Name)"
            Copy-Item -Path $f.FullName -Destination $dest -Force
        }
        Ok "✅ Fuentes Meslo instaladas. Configura tu terminal para usar 'MesloLGM Nerd Font' o similar."
        return $true
    } catch {
        Warn "⚠️ No se pudo instalar Meslo automáticamente: $_"
        return $false
    }
}

Info "ℹ️ Oh My Posh incluye una utilidad CLI para seleccionar e instalar Nerd Fonts."
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    try {
        oh-my-posh font install | Out-Null
        Ok "✅ Se lanzó el selector de fuentes (elige 'Meslo' si quieres Meslo LGM NF)."
    } catch {
        Warn "⚠️ El selector de fuentes no pudo ejecutarse automáticamente, intentando instalar Meslo directamente..."
        try { oh-my-posh font install meslo | Out-Null; Ok "✅ oh-my-posh instaló Meslo via CLI." } catch { Install-Meslo | Out-Null }
    }
} else {
    Warn "ℹ️ Omitting font install via oh-my-posh: oh-my-posh no disponible en esta sesión. Intentando descarga directa..."
    Install-Meslo | Out-Null
}

# ---------------- Download official themes to user's folder ----------------
$CustomThemesPath = Join-Path $env:USERPROFILE "oh-my-posh-themes"
if (-not (Test-Path $CustomThemesPath)) { New-Item -ItemType Directory -Path $CustomThemesPath -Force | Out-Null }

$themes = @(
    "M365Princess","agnoster","atomic","cert","clean-detailed",
    "cloud-native-azure","jonnychipz","kushal","stelbent.minimal",
    "tokyo","glowsticks","paradox","jandedobbeleer",
    "powerlevel10k_rainbow","minimal","ys"
)

Info "⬇️ Descargando temas desde GitHub (raw)..."
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
            Ok "✅ Tema descargado: $theme -> $out"
            $downloaded = $true
            break
        } catch { }
    }
    if (-not $downloaded) { Warn "⚠️ No se pudo descargar el tema: $theme" }
}
Ok "🎨 Temas disponibles en: $CustomThemesPath"

# ---------------- Insert persistent block into profile ----------------
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

function Set-PoshConfig {
    param([Parameter(Mandatory=$true)][string]$config)
    # config accepts: theme name (without extension), local path, or URL
    if ($config -match '^(https?://)') {
        $cfgRef = $config
    } elseif (Test-Path $config) {
        $cfgRef = (Resolve-Path $config).ProviderPath
    } else {
        # try user themes folder (name without extension)
        $candidate = Join-Path $env:USERPROFILE "oh-my-posh-themes\$config.omp.json"
        if (Test-Path $candidate) { $cfgRef = $candidate } else { $cfgRef = $config }
    }

    if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) { Write-Host "❌ oh-my-posh no disponible en PATH." -ForegroundColor Red; return }

    try {
        $init = & oh-my-posh init pwsh --config "$cfgRef"
        Invoke-Expression $init
        Set-Content -Path (Join-Path $env:USERPROFILE ".poshtheme") -Value $config -Force
        Write-Host "✅ Config aplicado y guardado: $config" -ForegroundColor Green
    } catch {
        try {
            oh-my-posh init pwsh --config "$cfgRef" --eval | Invoke-Expression
            Set-Content -Path (Join-Path $env:USERPROFILE ".poshtheme") -Value $config -Force
            Write-Host "✅ Config aplicado con --eval y guardado: $config" -ForegroundColor Green
        } catch {
            Write-Host "❌ Error aplicando config: $_" -ForegroundColor Red
        }
    }
}

function Export-PoshConfig {
    param(
        [Parameter(Mandatory=$true)][string]$source,  # name, local path or config reference
        [Parameter(Mandatory=$true)][string]$output   # output path (.json/.yaml/.toml)
    )
    if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) { Write-Host "❌ oh-my-posh no disponible." -ForegroundColor Red; return }
    try {
        oh-my-posh config export --config $source --output $output
        Write-Host "✅ Exportado: $output" -ForegroundColor Green
    } catch {
        Write-Host "❌ Error exportando config: $_" -ForegroundColor Red
    }
}

# Restore last applied theme/config at startup
if (Test-Path (Join-Path $env:USERPROFILE ".poshtheme")) {
    $last = Get-Content (Join-Path $env:USERPROFILE ".poshtheme") -ErrorAction SilentlyContinue
    if ($last) { 
        try { Set-PoshConfig $last } catch { Set-PoshTheme $last }
    }
}
# ===== end persistent config =====
'@

$profileContent = Get-Content -Path $ProfilePath -Raw -ErrorAction SilentlyContinue
if ($profileContent -notlike "*Oh My Posh Persistent Configuration*") {
    Add-Content -Path $ProfilePath -Value "`n$ConfigBlock"
    Ok "✅ Perfil actualizado con configuración persistente: $ProfilePath"
} else {
    Info "ℹ️ Perfil ya contiene configuración persistente."
}

# ---------------- Windows Terminal & Nerd Font guidance (added to profile as comment) ----------------
$terminalGuidance = @'
# ===== Windows Terminal and Fonts guidance =====
# Prefer Windows Terminal for the best experience.
# Ensure a Nerd Font is selected in Windows Terminal profile (e.g., "MesloLGM Nerd Font").
# To set the font in settings.json add under profiles.defaults:
# {
#   "profiles": {
#     "defaults": {
#       "font": { "face": "MesloLGM Nerd Font" }
#     }
#   }
# }
# If oh-my-posh isn't recognized after installation, restart the terminal.
# If antivirus blocks updates, consider adding an exclusion for the executable.
# Get full path to executable with: (Get-Command oh-my-posh).Source
# Use oh-my-posh get shell to detect current shell.
# To create profile if missing: New-Item -Path $PROFILE -Type File -Force
# To bypass execution policy temporarily: Set-ExecutionPolicy Bypass -Scope Process -Force
# ===== end guidance =====
'@

if ($profileContent -notlike "*Windows Terminal and Fonts guidance*") {
    Add-Content -Path $ProfilePath -Value "`n$terminalGuidance"
}

Ok "`n🎉 Instalación finalizada."
Info "Recarga el perfil con: . $PROFILE  o cierra/abre la terminal para aplicar cambios persistentes."
Info "Para cambiar el prompt ahora puedes usar:"
Info "  Set-PoshTheme 'tokyo'                 # tema local en oh-my-posh-themes"
Info "  Set-PoshConfig 'tokyo'                # nombre, local path o URL (intenta aplicar como config)"
Info "  Set-PoshConfig 'C:/path/mytheme.json' # ruta local"
Info "  Set-PoshConfig 'https://...'          # URL remota"
Info "Para exportar una config editable:"
Info "  Export-PoshConfig -source jandedobbeleer -output $env:USERPROFILE\mytheme.omp.json"
Warn "Si el AV bloquea oh-my-posh, crea una exclusión apuntando al ejecutable indicado por: (Get-Command oh-my-posh).Source"
Warn "Si usas WSL, sigue la guía de instalación para Linux en https://ohmyposh.dev/docs/installation/linux"
