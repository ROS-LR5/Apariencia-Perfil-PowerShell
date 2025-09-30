# uninstall-oh-my-posh-ROSN-LR5.ps1

Write-Host "🧹 Desinstalando Oh My Posh..." -ForegroundColor Red

# Restaurar perfil
$ProfilePath = $PROFILE
$BackupPath = "$ProfilePath.backup"

if (Test-Path $BackupPath) {
    Copy-Item -Path $BackupPath -Destination $ProfilePath -Force
    Remove-Item -Path $BackupPath -Force -ErrorAction SilentlyContinue
    Write-Host "✅ Perfil restaurado desde el backup."
} else {
    Write-Host "⚠️ No se encontró backup del perfil."
}

# Eliminar temas
$ThemesPath = "$env:USERPROFILE\oh-my-posh-themes"
if (Test-Path $ThemesPath) {
    Remove-Item -Recurse -Force -Path $ThemesPath
    Write-Host "🗑️ Carpetas de temas borradas."
}

# Eliminar archivo de configuración persistente
$themeStore = "$env:USERPROFILE\.poshtheme"
if (Test-Path $themeStore) {
    Remove-Item $themeStore -Force
    Write-Host "🗑️ Archivo de tema actual eliminado."
}

# Desinstalar con winget
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "📦 Desinstalando Oh My Posh..."
    winget uninstall JanDeDobbeleer.OhMyPosh -e
    Write-Host "✅ Desinstalación realizada con éxito"
} else {
    Write-Host "⚠️ Winget no encontrado. No se pudo desinstalar automáticamente."
}

Write-Host "`n🧽 Oh My Posh desinstalado completamente."
Write-Host "💡 Cierra y vuelve a abrir PowerShell para aplicar los cambios."
