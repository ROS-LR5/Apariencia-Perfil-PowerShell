# uninstall-oh-my-posh.ps1
# Reestablece todo como estaba antes

Write-Host "`n🧹 Desinstalando Oh My Posh..."

# Restaurar perfil original si existe
$BackupPath = "$PROFILE.backup"
if (Test-Path $BackupPath) {
    Copy-Item -Path $BackupPath -Destination $PROFILE -Force
    Write-Host "✅ Perfil restaurado desde el backup."
}

# Borrar temas descargados
$CustomThemesPath = "$env:USERPROFILE\oh-my-posh-themes"
if (Test-Path $CustomThemesPath) {
    Remove-Item -Recurse -Force -Path $CustomThemesPath
    Write-Host "🗑️ Carpetas de temas borradas."
}

# Desinstalar Oh My Posh via winget
winget uninstall JanDeDobbeleer.OhMyPosh -e

Write-Host "`n🧽 Oh My Posh desinstalado completamente."
Write-Host "💡 Cierra y vuelve a abrir PowerShell para aplicar los cambios."
