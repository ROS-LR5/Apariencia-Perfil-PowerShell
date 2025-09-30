# install-oh-my-posh-ROSN-LR5.ps1
# Autor: ROSN-LR5 (mejora)
# Versión: 3.2
# Requisitos: PowerShell 7.x. Ejecutar como Administrador para instalación system-wide (opcional).
[CmdletBinding()]
param([switch]$UserScope)

function Write-Info($m){ Write-Host $m -ForegroundColor Cyan }
function Write-Warn($m){ Write-Host $m -ForegroundColor Yellow }
function Write-Ok($m){ Write-Host $m -ForegroundColor Green }
function Write-Err($m){ Write-Host $m -ForegroundColor Red }

# Cabecera animada
$chars = "R O S N - L R 5".ToCharArray()
foreach ($c in $chars){ Write-Host $c -NoNewline -ForegroundColor Cyan; Start-Sleep -Milliseconds 90 }
Write-Host
Write-Ok "🚀 Iniciando instalación Oh My Posh (persistente)..."

# Perfil y backup
$ProfilePath = $PROFILE
$ProfileDir = Split-Path -Parent $ProfilePath
if (-not (Test-Path $ProfileDir)){ New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null }
if (-not (Test-Path $ProfilePath)){ New-Item -ItemType File -Path $ProfilePath -Force | Out-Null }

$BackupPath = "$ProfilePath.backup"
if (-not (Test-Path $BackupPath)) {
    Copy-Item -Path $ProfilePath -Destination $BackupPath -Force
    Write-Ok "✅ Backup creado en: $BackupPath"
} else {
    Write-Info "ℹ️ Backup ya existe en: $BackupPath"
}

# Intento principal: winget
$hasWinget = (Get-Command winget -ErrorAction SilentlyContinue) -ne $null
$installed = $false
if ($hasWinget) {
    Write-Info "🔧 Intentando instalar/actualizar Oh My Posh via winget..."
    try {
        if ($UserScope) {
            winget install JanDeDobbeleer.OhMyPosh --source winget --scope user --accept-source-agreements --accept-package-agreements --silent
        } else {
            winget install JanDeDobbeleer.OhMyPosh --source winget --scope machine --accept-source-agreements --accept-package-agreements --silent
        }
        Start-Sleep -Seconds 2
        if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) { $installed = $true; Write-Ok "✅ Oh My Posh instalado via winget." } else { Write-Warn "⚠️ Winget informó, pero el comando no está en PATH aún." }
    } catch {
        Write-Warn "⚠️ Winget instaló falló o no pudo completar: $_"
    }
} else {
    Write-Warn "⚠️ winget no disponible en este sistema."
}

# Fallback: descargar release oficial (zip) y descomprimir
if (-not $installed) {
    Write-Info "⬇️ Intentando fallback: descargar binario oficial desde GitHub Releases..."
    $destDir = if ($UserScope) { Join-Path $env:LOCALAPPDATA "Programs\oh-my-posh" } else { Join-Path $env:ProgramFiles "oh-my-posh" }
    $binDir = Join-Path $destDir "bin"
    if (-not (Test-Path $binDir)) { New-Item -ItemType Directory -Path $binDir -Force | Out-Null }

    # URL de descarga oficial (archivo de release precompilado para Windows amd64)
    $zipUrl = "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-windows-amd64.zip"
    $tmp = Join-Path $env:TEMP "posh-windows-amd64.zip"
    try {
        Invoke-WebRequest -Uri $zipUrl -OutFile $tmp -UseBasicParsing -ErrorAction Stop
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($tmp, $binDir, $true)
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
        Write-Ok "✅ Binario descargado y extraído en: $binDir"
        # Asegurar nombre ejecutable
        $exe = Get-ChildItem -Path $binDir -Filter "posh.exe","oh-my-posh.exe" -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $exe) {
            # buscar cualquier exe
            $exe = Get-ChildItem -Path $binDir -Filter *.exe -File | Select-Object -First 1
        }
        if ($exe) {
            # Crear symlink/archivo oh-my-posh.exe si no existe
            $targetExe = Join-Path $binDir "oh-my-posh.exe"
            if ($exe.FullName -ne $targetExe) {
                Copy-Item -Path $exe.FullName -Destination $targetExe -Force
            }
            # Añadir a PATH de sesión
            if ($env:Path -notlike "*$binDir*") { $env:Path = "$env:Path;$binDir" }
            Write-Ok "✅ oh-my-posh preparado en: $targetExe"
            $installed = $true
        } else {
            Write-Warn "⚠️ No se encontró ejecutable dentro del zip extraído."
        }
    } catch {
        Write-Err "❌ Fallback falló: $_"
    }
}

# Verificar comando ahora
if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    Write-Warn "⚠️ oh-my-posh aún no está disponible como comando. Añade manualmente la carpeta bin al PATH o reinicia la terminal."
} else {
    Write-Ok "✅ oh-my-posh disponible en esta sesión."
}

# Intentar instalar fuente Meslo Nerd si oh-my-posh disponible
function Install-MesloNerd {
    param($InstallDir)
    $fontName = "MesloLGS NF Regular.ttf"
    $fontUrlBase = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download"
    # Intentar descargar Meslo patched (zip) específico puede variar; usaremos Meslo patched zip
    $mesloZipUrl = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
    $tmpZip = Join-Path $env:TEMP "meslo_nerd.zip"
    try {
        Invoke-WebRequest -Uri $mesloZipUrl -OutFile $tmpZip -UseBasicParsing -ErrorAction Stop
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $extractDir = Join-Path $env:TEMP "meslo_nerd_fonts"
        if (Test-Path $extractDir){ Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue }
        [System.IO.Compression.ZipFile]::ExtractToDirectory($tmpZip, $extractDir)
        Remove-Item $tmpZip -Force -ErrorAction SilentlyContinue
        $ttfs = Get-ChildItem -Path $extractDir -Filter *.ttf -Recurse -File -ErrorAction SilentlyContinue
        if ($ttfs.Count -eq 0) { Write-Warn "⚠️ No se encontraron TTFs al extraer Meslo." ; return $false }
        foreach ($f in $ttfs) {
            $dest = Join-Path $env:WINDIR "Fonts\$($f.Name)"
            Copy-Item -Path $f.FullName -Destination $dest -Force
        }
        Write-Ok "✅ Fuentes Meslo Nerd instaladas en Windows Fonts. Configura tu terminal para usar MesloLGM Nerd Font."
        return $true
    } catch {
        Write-Warn "⚠️ No se pudo instalar Meslo automáticamente: $_"
        return $false
    }
}

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    Write-Info "🔤 Intentando instalar fuentes recomendadas vía oh-my-posh..."
    try {
        oh-my-posh font install meslo | Out-Null
        Write-Ok "✅ oh-my-posh instaló Meslo (si fue posible)."
    } catch {
        Write-Warn "⚠️ oh-my-posh no pudo instalar fuentes automáticamente, intentando descarga directa..."
        Install-MesloNerd
    }
} else {
    Write-Warn "ℹ️ Omitting font install: oh-my-posh no disponible."
}

# Descargar temas locales
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

# Bloque persistente para el perfil (Set-PoshTheme + restore)
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

    if ($paths.Count -eq 0) { Write-Host "❌ Tema no encontrado localmente: $theme" -ForegroundColor Red; return }

    $themePath = $paths[0]
    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        try {
            $init = & oh-my-posh init pwsh --config "$themePath"
            Invoke-Expression $init
        } catch {
            # fallback con eval si falla
            oh-my-posh init pwsh --config "$themePath" --eval | Invoke-Expression
        }
        $env:POSH_THEME = $theme
        Set-Content -Path (Join-Path $env:USERPROFILE ".poshtheme") -Value $theme -Force
        Write-Host "✅ Tema aplicado y guardado: $theme" -ForegroundColor Green
    } else {
        Write-Host "❌ oh-my-posh no disponible. Asegura que esté instalado y en PATH." -ForegroundColor Red
    }
}

# Restaurar último tema al iniciar
if (Test-Path (Join-Path $env:USERPROFILE ".poshtheme")) {
    $last = Get-Content (Join-Path $env:USERPROFILE ".poshtheme") -ErrorAction SilentlyContinue
    if ($last) { Set-PoshTheme $last }
}
# ===== end persistent config =====
'@

# Añadir al perfil si no existe
$profileContent = Get-Content -Path $ProfilePath -Raw -ErrorAction SilentlyContinue
if ($profileContent -notlike "*Oh My Posh Persistent Configuration*") {
    Add-Content -Path $ProfilePath -Value "`n$ConfigBlock"
    Write-Ok "✅ Perfil actualizado con configuración persistente."
} else {
    Write-Info "ℹ️ Perfil ya contiene configuración persistente."
}

Write-Ok "`n🎉 Instalación finalizada."
Write-Info "Reinicia PowerShell o recarga el perfil con:  . $PROFILE"
Write-Info "Aplica un tema manualmente: Set-PoshTheme 'tokyo'"
Write-Info "Configura tu terminal (Windows Terminal) para usar 'MesloLGM Nerd Font' o la Nerd Font instalada."
