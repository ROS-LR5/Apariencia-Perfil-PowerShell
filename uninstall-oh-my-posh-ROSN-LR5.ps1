# uninstall-oh-my-posh-persist.ps1

Write-Host "🧹 Desinstalando Oh My Posh con limpieza completa..." -ForegroundColor Red

# Restaurar perfil original
$ProfilePath = $PROFILE
$BackupPath = "$ProfilePath.backup"

if (Test-Path $BackupPath) {
    Copy-Item -Path $BackupPath -Destination $ProfilePath -Force
    Remove-Item -Path $BackupPath -Force -ErrorAction SilentlyContinue
    Write-Host "✅ Perfil restaurado desde backup."
} else {
    Write-Host "⚠️ No se encontró backup del perfil."
}

# Borrar carpeta de temas
$Themes = "$env:USERPROFILE\oh-my-posh-themes"
if (Test-Path $Themes) {
    Remove-Item -Recurse -Force -Path $Themes
    Write-Host "🗑️ Carpetas de temas borradas."
}

# Borrar archivo de tema persistente
$themeStore = "$env:USERPROFILE\.poshtheme"
if (Test-Path $themeStore) {
    Remove-Item $themeStore -Force
    Write-Host "🗑️ Archivo de tema persistente eliminado."
}

# Desinstalar Oh My Posh
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "📦 Desinstalando Oh My Posh..."
    winget uninstall JanDeDobbeleer.OhMyPosh -e
    Write-Host "✅ Desinstalación realizada."
} else {
    Write-Host "⚠️ Winget no disponible para desinstalar automáticamente."
}

Write-Host "`n🧽 Proceso de limpieza finalizado. Reinicia PowerShell para aplicar.”
