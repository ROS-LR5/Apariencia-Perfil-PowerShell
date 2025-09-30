# uninstall-oh-my-posh-ROSN-LR5.ps1 para PowerShell 7.5

Write-Host "🧹 Desinstalando Oh My Posh..." -ForegroundColor Red

# Restaurar perfil
$ProfilePath = $PROFILE
$BackupPath = "$ProfilePath.backup"

if (Test-Path $BackupPath) {
    Copy-Item -Path $BackupPath -Destination $ProfilePath -Force
    Remove-Item -Path $BackupPath -Force
    Write-Host "✅ Perfil restaurado."
} else {
    Write-Host "⚠️ No se encontró backup del perfil original."
}

# Eliminar carpeta de temas
$Themes = "$env:USERPROFILE\oh-my-posh-themes"
if (Test-Path $Themes) {
    Remove-Item -Recurse -Force -Path $Themes
    Write-Host "🗑️ Carpetas de temas eliminadas."
}

# Eliminar .poshtheme
$ThemeStore = "$env:USERPROFILE\.poshtheme"
if (Test-Path $ThemeStore) {
    Remove-Item $ThemeStore -Force
    Write-Host "🗑️ Configuración persistente de tema eliminada."
}

# Desinstalar OMP
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "📦 Desinstalando Oh My Posh con winget..."
    winget uninstall JanDeDobbeleer.OhMyPosh -e
    Write-Host "✅ Oh My Posh eliminado con éxito."
} else {
    Write-Host "⚠️ Winget no disponible. Desinstala manualmente si es necesario."
}

Write-Host "`n🧽 Todo desinstalado. Reinicia PowerShell para ver los cambios."
