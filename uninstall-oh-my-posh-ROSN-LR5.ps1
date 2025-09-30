# uninstall-oh-my-posh-ROSN-LR5.ps1
# Autor: ROSN-LR5 (mejora)
# Versión: 3.2

Write-Host "🧹 Desinstalando Oh My Posh y limpiando..." -ForegroundColor Red

$ProfilePath = $PROFILE
$BackupPath = "$ProfilePath.backup"

# Restaurar perfil desde backup
if (Test-Path $BackupPath) {
    try {
        Copy-Item -Path $BackupPath -Destination $ProfilePath -Force
        Remove-Item -Path $BackupPath -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Perfil restaurado desde backup."
    } catch {
        Write-Host "⚠️ Error restaurando backup: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️ No se encontró backup del perfil." -ForegroundColor Yellow
}

# Eliminar carpeta de temas
$Themes = Join-Path $env:USERPROFILE "oh-my-posh-themes"
if (Test-Path $Themes) {
    try { Remove-Item -Recurse -Force -Path $Themes; Write-Host "🗑️ Carpeta de temas borrada: $Themes" } catch { Write-Host "⚠️ Error borrando temas: $_" -ForegroundColor Yellow }
} else { Write-Host "ℹ️ No existe carpeta de temas local." -ForegroundColor Cyan }

# Eliminar .poshtheme
$themeStore = Join-Path $env:USERPROFILE ".poshtheme"
if (Test-Path $themeStore) { Remove-Item $themeStore -Force -ErrorAction SilentlyContinue; Write-Host "🗑️ Archivo .poshtheme eliminado." } else { Write-Host "ℹ️ No existe archivo .poshtheme." -ForegroundColor Cyan }

# Intentar remover bin instalado en ProgramFiles o LOCALAPPDATA
$possibleDirs = @(
    Join-Path $env:ProgramFiles "oh-my-posh\bin",
    Join-Path $env:LOCALAPPDATA "Programs\oh-my-posh\bin",
    Join-Path $env:LOCALAPPDATA "Programs\oh-my-posh"
)
foreach ($d in $possibleDirs) {
    if (Test-Path $d) {
        try { Remove-Item -Recurse -Force -Path $d; Write-Host "🗑️ Eliminado: $d" } catch { Write-Host "⚠️ Error borrando $d: $_" -ForegroundColor Yellow }
    }
}

# Desinstalar via winget si disponible
if (Get-Command winget -ErrorAction SilentlyContinue) {
    try {
        winget uninstall JanDeDobbeleer.OhMyPosh -e
        Write-Host "📦 Intentada desinstalación via winget."
    } catch { Write-Host "⚠️ winget no pudo desinstalar automáticamente: $_" -ForegroundColor Yellow }
} else {
    Write-Host "ℹ️ winget no disponible. Comprueba en 'Agregar o quitar programas' para desinstalar si es necesario." -ForegroundColor Cyan
}

Write-Host "`n🧽 Limpieza finalizada. Reinicia la terminal para aplicar cambios." -ForegroundColor Green
