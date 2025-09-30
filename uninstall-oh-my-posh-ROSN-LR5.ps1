# uninstall-oh-my-posh-persist-ROSN-LR5.ps1
# Autor: ROSN-LR5 (mejora)
# Version: 3.1

Write-Host "🧹 Iniciando desinstalacion y limpieza Oh My Posh..." -ForegroundColor Red

$ProfilePath = $PROFILE
$BackupPath = "$ProfilePath.backup"

# Restaurar perfil desde backup si existe
if (Test-Path $BackupPath) {
    try {
        Copy-Item -Path $BackupPath -Destination $ProfilePath -Force
        Remove-Item -Path $BackupPath -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Perfil restaurado desde backup."
    } catch {
        Write-Host "⚠️ Fallo al restaurar perfil: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️ No se encontró backup del perfil." -ForegroundColor Yellow
}

# Eliminar carpeta local de temas
$Themes = Join-Path $env:USERPROFILE "oh-my-posh-themes"
if (Test-Path $Themes) {
    try {
        Remove-Item -Recurse -Force -Path $Themes
        Write-Host "🗑️ Carpeta de temas borrada: $Themes"
    } catch {
        Write-Host "⚠️ Error borrando carpeta de temas: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "ℹ️ No existe carpeta de temas local."
}

# Eliminar archivo de tema persistente
$themeStore = Join-Path $env:USERPROFILE ".poshtheme"
if (Test-Path $themeStore) {
    Remove-Item $themeStore -Force -ErrorAction SilentlyContinue
    Write-Host "🗑️ Archivo .poshtheme eliminado."
} else {
    Write-Host "ℹ️ No existe archivo .poshtheme."
}

# Eliminar bloque de configuración persistente del perfil (intento seguro)
try {
    $content = Get-Content -Path $ProfilePath -Raw
    $startToken = "# ===== Oh My Posh Persistent Configuration ====="
    if ($content -like "*$startToken*") {
        # remover desde startToken hasta "end persistent config" (simple)
        $pattern = [regex]::Escape($startToken) + "(.|\n)*?# ===== end persistent config ====="
        $new = [regex]::Replace($content, $pattern, "", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        Set-Content -Path $ProfilePath -Value $new -Force
        Write-Host "✅ Bloque persistente eliminado del perfil."
    } else {
        Write-Host "ℹ️ No se encontró bloque persistente en el perfil."
    }
} catch {
    Write-Host "⚠️ Error procesando el perfil: $_" -ForegroundColor Yellow
}

# Desinstalar via winget si disponible
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "📦 Desinstalando Oh My Posh via winget..."
    winget uninstall JanDeDobbeleer.OhMyPosh -e
    Write-Host "✅ Desinstalacion intentada via winget."
} else {
    Write-Host "⚠️ winget no disponible. Desinstala Oh My Posh manualmente si lo deseas." -ForegroundColor Yellow
}

Write-Host "`n🧽 Limpieza finalizada. Reinicia PowerShell o la terminal para ver cambios." -ForegroundColor Green
