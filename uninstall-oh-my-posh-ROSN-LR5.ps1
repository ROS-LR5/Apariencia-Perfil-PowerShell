# uninstall-oh-my-posh-ROSN-LR5-fixed.ps1
# Versión: 3.2.3 (correcciones)
[CmdletBinding()]
param()

function Write-Info($m){ Write-Host $m -ForegroundColor Cyan }
function Write-Warn($m){ Write-Host $m -ForegroundColor Yellow }
function Write-Ok($m){ Write-Host $m -ForegroundColor Green }
function Write-Err($m){ Write-Host $m -ForegroundColor Red }

Write-Host "🧹 Iniciando desinstalación y limpieza Oh My Posh..." -ForegroundColor Red

$ProfilePath = $PROFILE
$BackupPath = "$ProfilePath.backup"

# 1) Restaurar perfil desde backup (si existe)
if (Test-Path $BackupPath) {
    try {
        Copy-Item -Path $BackupPath -Destination $ProfilePath -Force
        Remove-Item -Path $BackupPath -Force -ErrorAction SilentlyContinue
        Write-Ok "✅ Perfil restaurado desde backup: $BackupPath -> $ProfilePath"
    } catch {
        Write-Warn "⚠️ Error restaurando perfil desde backup."
        Write-Host "        $_"
    }
} else {
    Write-Warn "⚠️ No se encontró backup del perfil en: $BackupPath"
}

# 2) Eliminar carpeta de temas en el perfil de usuario
$Themes = Join-Path $env:USERPROFILE "oh-my-posh-themes"
if (Test-Path $Themes) {
    try {
        Remove-Item -Recurse -Force -Path $Themes
        Write-Ok "🗑️ Carpeta de temas borrada: $Themes"
    } catch {
        Write-Warn "⚠️ Error borrando carpeta de temas."
        Write-Host "        $_"
    }
} else {
    Write-Info "ℹ️ No existe carpeta de temas: $Themes"
}

# 3) Eliminar archivo de tema persistente
$themeStore = Join-Path $env:USERPROFILE ".poshtheme"
if (Test-Path $themeStore) {
    try {
        Remove-Item -Force -Path $themeStore
        Write-Ok "🗑️ Archivo .poshtheme eliminado: $themeStore"
    } catch {
        Write-Warn "⚠️ Error eliminando .poshtheme."
        Write-Host "        $_"
    }
} else {
    Write-Info "ℹ️ No existe archivo .poshtheme"
}

# 4) Eliminar bloque persistente del perfil (operación robusta)
try {
    if (Test-Path $ProfilePath) {
        $content = Get-Content -Path $ProfilePath -Raw -ErrorAction SilentlyContinue
        if ([string]::IsNullOrEmpty($content)) {
            Write-Info "ℹ️ Perfil vacío o no legible: $ProfilePath"
        } else {
            $startToken = '# ===== Oh My Posh Persistent Configuration ====='
            $endToken   = '# ===== end persistent config ====='
            $pattern = [System.Text.RegularExpressions.Regex]::Escape($startToken) + '.*?' + [System.Text.RegularExpressions.Regex]::Escape($endToken)
            $newContent = [System.Text.RegularExpressions.Regex]::Replace($content, $pattern, '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
            if ($newContent -ne $content) {
                Set-Content -Path $ProfilePath -Value $newContent -Force
                Write-Ok "✅ Bloque persistente eliminado del perfil: $ProfilePath"
            } else {
                Write-Info "ℹ️ No se encontró bloque persistente en el perfil."
            }
        }
    } else {
        Write-Warn "⚠️ Perfil no encontrado en: $ProfilePath"
    }
} catch {
    Write-Warn "⚠️ Error al procesar el perfil."
    Write-Host "        $_"
}

# 5) Eliminar binarios instalados en rutas comunes (LOCALAPPDATA o ProgramFiles)
$localApp = [Environment]::GetFolderPath("LocalApplicationData")
$progFiles = [Environment]::GetFolderPath("ProgramFiles")

$possibleDirs = @(
    Join-Path $localApp "Programs\oh-my-posh",
    Join-Path $progFiles "oh-my-posh",
    Join-Path $progFiles "oh-my-posh\bin",
    Join-Path $localApp "Programs\oh-my-posh\bin",
    "C:\Tools\oh-my-posh",
    "C:\oh-my-posh"
)

foreach ($d in $possibleDirs) {
    if ([string]::IsNullOrWhiteSpace($d)) { continue }
    if (Test-Path $d) {
        try {
            Remove-Item -Recurse -Force -Path $d
            Write-Ok ("🗑️ Eliminado: " + $d)
        } catch {
            Write-Warn "⚠️ Error borrando ruta. Ver detalles:"
            Write-Host "        $d"
            Write-Host "        $_"
        }
    }
}

# 6) Intentar desinstalar con winget si está instalado
if (Get-Command winget -ErrorAction SilentlyContinue) {
    try {
        Write-Info "📦 Intentando desinstalación vía winget..."
        winget uninstall JanDeDobbeleer.OhMyPosh -e
        Write-Ok "✅ Intentada desinstalación vía winget (verifica en Agregar o quitar programas)."
    } catch {
        Write-Warn "⚠️ winget no pudo desinstalar automáticamente."
        Write-Host "        $_"
    }
} else {
    Write-Info "ℹ️ winget no disponible en este equipo. Verifica manualmente en 'Agregar o quitar programas'."
}

Write-Host "`n🧽 Proceso de limpieza finalizado. Reinicia PowerShell o la terminal para aplicar cambios." -ForegroundColor Green
