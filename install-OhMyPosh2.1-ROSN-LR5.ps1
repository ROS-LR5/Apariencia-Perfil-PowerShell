# install-oh-my-posh-ROSN-LR5.ps1
# Autor: ROSN-LR5
# Versión: 4.0
# Requisitos: PowerShell 7.x. Ejecutar como Administrador para instalación en Program Files (opcional).
[CmdletBinding()]
param([switch]$UserScope)

function Info($m){ Write-Host $m -ForegroundColor Cyan }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Err($m){ Write-Host $m -ForegroundColor Red }

Info "R O S N - L R 5"
Ok "🚀 Iniciando instalación Oh My Posh (persistente)..."

# 1) Preparar perfil y backup
$ProfilePath = $PROFILE
$ProfileDir = Split-Path -Parent $ProfilePath
if (-not (Test-Path $ProfileDir)) { New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null }
if (-not (Test-Path $ProfilePath)) { New-Item -ItemType File -Path $ProfilePath -Force | Out-Null }

$BackupPath = "$ProfilePath.backup"
if (-not (Test-Path $BackupPath)) {
    Copy-Item -Path $ProfilePath -Destination $BackupPath -Force
    Ok "✅ Backup del perfil creado en: $BackupPath"
} else {
    Info "ℹ️ Backup ya existe en: $BackupPath"
}

# 2) Intentar instalación oficial via winget o instalador remoto
$installed = $false
$hasWinget = (Get-Command winget -ErrorAction SilentlyContinue) -ne $null

if ($hasWinget) {
    Info "🔧 Intentando instalar/actualizar Oh My Posh via winget..."
    try {
        if ($UserScope) {
            winget install JanDeDobbeleer.OhMyPosh --source winget --scope user --accept-source-agreements --accept-package-agreements --silent
        } else {
            winget install JanDeDobbeleer.OhMyPosh --source winget --scope machine --accept-source-agreements --accept-package-agreements --silent
        }
        Start-Sleep -Seconds 2
        if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) { $installed = $true; Ok "✅ Oh My Posh instalado via winget." } else { Warn "⚠️ Winget no dejó el comando disponible en la sesión actual." }
    } catch {
        Warn "⚠️ Winget falló: $_"
    }
} else {
    Info "ℹ️ winget no disponible, realizaré fallback."
}

# 3) Fallback: descargar release oficial (zip) y extraer a ruta controlada
if (-not $installed) {
    Info "⬇️ Descargando binario oficial desde GitHub Releases (fallback)..."
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
            # añadir a PATH de sesión
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

# 4) Persistir ruta al PATH de usuario para nuevas sesiones
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
    Err "❌ oh-my-posh no pudo instalarse. Revisa permisos o instala manualmente."
}

# 5) Instalar fuente recomendada Meslo (intentar via oh-my-posh, fallback descarga directa)
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
        Ok "✅ Fuentes Meslo instaladas (system 폴더). Configura tu terminal para usar 'MesloLGM Nerd Font'."
        return $true
    } catch {
        Warn "⚠️ Falta instalar fuentes automáticamente: $_"
        return $false
    }
}

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    try {
        oh-my-posh font install meslo | Out-Null
        Ok "✅ oh-my-posh intentó instalar Meslo."
    } catch {
        Warn "⚠️ oh-my-posh no pudo instalar fuentes automáticamente, intento descarga directa..."
        Install-Meslo | Out-Null
    }
} else {
    Warn "ℹ️ Omitting font install: oh-my-posh no disponible en esta sesión."
}

# 6) Descargar temas oficiales a carpeta del usuario
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

# 7) Añadir bloque persistente al perfil (Set-PoshTheme + restauración)
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
if (Test-Path (Join-Path $env:USERPROFILE ".poshtheme")) {
    $last = Get-Content (Join-Path $env:USERPROFILE ".poshtheme") -ErrorAction SilentlyContinue
    if ($last) { Set-PoshTheme $last }
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

Ok "`n🎉 Instalación finalizada."
Info "Recarga el perfil ahora con: . $PROFILE  o cierra y vuelve a abrir PowerShell/Windows Terminal."
Info "Aplica un tema manual: Set-PoshTheme 'tokyo' o oh-my-posh init pwsh --config '$CustomThemesPath\tokyo.json' | Invoke-Expression"
