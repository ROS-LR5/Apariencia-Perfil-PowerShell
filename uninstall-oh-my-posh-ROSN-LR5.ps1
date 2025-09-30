# uninstall-oh-my-posh-ROSN-LR5.ps1
# Autor: ROSN-LR5
# Versión: 4.5
# Requisitos: PowerShell 7.x. Ejecuta como Administrador para borrar Program Files (opcional).
[CmdletBinding()]
param()

function Info($m){ Write-Host $m -ForegroundColor Cyan }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Err($m){ Write-Host $m -ForegroundColor Red }

Write-Host "🧹 Iniciando desinstalación y limpieza Oh My Posh..." -ForegroundColor Red

$ProfilePath = $PROFILE
$BackupPath  = "$ProfilePath.backup"

# 1) Restaurar perfil desde backup
if (Test-Path $BackupPath) {
    try {
        Copy-Item -Path $BackupPath -Destination $ProfilePath -Force
        Remove-Item -Path $BackupPath -Force -ErrorAction SilentlyContinue
        Ok "✅ Perfil restaurado desde backup: $BackupPath -> $ProfilePath"
    } catch {
        Warn "⚠️ Error restaurando perfil desde backup."
        Write-Host "        $_"
    }
} else {
    Warn "⚠️ No se encontró backup del perfil: $BackupPath"
}

# 2) Eliminar carpeta de temas
$Themes = Join-Path $env:USERPROFILE "oh-my-posh-themes"
if (Test-Path $Themes) {
    try { Remove-Item -Recurse -Force -Path $Themes; Ok "🗑️ Carpeta de temas borrada: $Themes" } catch { Warn "⚠️ Error borrando carpeta de temas."; Write-Host "        $_" }
} else { Info "ℹ️ No existe carpeta de temas: $Themes" }

# 3) Eliminar archivo .poshtheme
$themeStore = Join-Path $env:USERPROFILE ".poshtheme"
if (Test-Path $themeStore) {
    try { Remove-Item -Force -Path $themeStore; Ok "🗑️ Archivo .poshtheme eliminado: $themeStore" } catch { Warn "⚠️ Error eliminando .poshtheme."; Write-Host "        $_" }
} else { Info "ℹ️ No existe archivo .poshtheme" }

# 4) Quitar bloque persistente del perfil (robusto)
try {
    if (Test-Path $ProfilePath) {
        $content = Get-Content -Path $ProfilePath -Raw -ErrorAction SilentlyContinue
        if ([string]::IsNullOrEmpty($content)) {
            Info "ℹ️ Perfil vacío o no legible: $ProfilePath"
        } else {
            $startToken = '# ===== Oh My Posh Persistent Configuration ====='
            $endToken   = '# ===== end persistent config ====='
            $pattern = [System.Text.RegularExpressions.Regex]::Escape($startToken) + '.*?' + [System.Text.RegularExpressions.Regex]::Escape($endToken)
            $newContent = [System.Text.RegularExpressions.Regex]::Replace($content, $pattern, '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
            if ($newContent -ne $content) {
                Set-Content -Path $ProfilePath -Value $newContent -Force
                Ok "✅ Bloque persistente eliminado del perfil: $ProfilePath"
            } else {
                Info "ℹ️ No se encontró bloque persistente en el perfil."
            }
            # eliminar guidance block si existe
            $guideStart = '# ===== Windows Terminal and Fonts guidance ====='
            $guideEnd   = '# ===== end guidance ====='
            $pattern2 = [System.Text.RegularExpressions.Regex]::Escape($guideStart) + '.*?' + [System.Text.RegularExpressions.Regex]::Escape($guideEnd)
            $newContent2 = [System.Text.RegularExpressions.Regex]::Replace($newContent, $pattern2, '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
            if ($newContent2 -ne $newContent) { Set-Content -Path $ProfilePath -Value $newContent2 -Force; Ok "✅ Guidance block eliminado del perfil." }
        }
    } else {
        Warn "⚠️ Perfil no encontrado en: $ProfilePath"
    }
} catch {
    Warn "⚠️ Error al procesar el perfil."; Write-Host "        $_"
}

# 5) Eliminar binarios en rutas comunes
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
        try { Remove-Item -Recurse -Force -Path $d; Ok ("🗑️ Eliminado: " + $d) } catch { Warn "⚠️ Error borrando $d"; Write-Host "        $_" }
    }
}

# 6) Limpiar PATH de usuario de entradas que añadimos
try {
    $regName = "PATH"
    $currentUserPath = [Environment]::GetEnvironmentVariable($regName, "User")
    if (-not [string]::IsNullOrEmpty($currentUserPath)) {
        $toRemove = @(
            (Join-Path $localApp "Programs\oh-my-posh\bin"),
            "C:\Tools\oh-my-posh\bin",
            "C:\Tools\oh-my-posh"
        ) | Where-Object { $_ -and $currentUserPath -like "*$_*" }

        if ($toRemove.Count -gt 0) {
            $newPath = $currentUserPath
            foreach ($r in $toRemove) { $newPath = $newPath -replace [regex]::Escape($r), "" }
            $newPath = ($newPath -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join ';'
            [Environment]::SetEnvironmentVariable($regName, $newPath, "User")
            Ok "✅ Entradas relacionadas eliminadas del PATH de usuario."
        } else {
            Info "ℹ️ No se detectaron entradas de PATH de usuario para remover."
        }
    }
} catch {
    Warn "⚠️ Error actualizando PATH de usuario: $_"
}

# 7) Intentar desinstalar via winget si corresponde
if (Get-Command winget -ErrorAction SilentlyContinue) {
    try { winget uninstall JanDeDobbeleer.OhMyPosh -e; Ok "📦 Intentada desinstalación via winget." } catch { Warn "⚠️ winget no pudo desinstalar automáticamente."; Write-Host "        $_" }
} else {
    Info "ℹ️ winget no disponible. Comprueba 'Agregar o quitar programas' si aún aparece."
}

Ok "`n🧽 Limpieza finalizada. Reinicia PowerShell o la terminal para aplicar cambios."
