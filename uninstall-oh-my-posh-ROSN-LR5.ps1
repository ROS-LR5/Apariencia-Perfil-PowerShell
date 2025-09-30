# uninstall-oh-my-posh-ROSN-LR5.ps1
# Autor: ROSN-LR5 (entrega)
# Versión: 3.3
# Requisitos: PowerShell 7.x. Ejecuta como Administrador para borrar Program Files y entradas de sistema.

[CmdletBinding()]
param()

function Write-Info($m){ Write-Host $m -ForegroundColor Cyan }
function Write-Warn($m){ Write-Host $m -ForegroundColor Yellow }
function Write-Ok($m){ Write-Host $m -ForegroundColor Green }
function Write-Err($m){ Write-Host $m -ForegroundColor Red }

Write-Host "🧹 Iniciando desinstalación y limpieza Oh My Posh..." -ForegroundColor Red

$ProfilePath = $PROFILE
$BackupPath = "$ProfilePath.backup"

# 1) Restaurar perfil desde backup
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
    Write-Warn "⚠️ No se encontró backup del perfil: $BackupPath"
}

# 2) Eliminar carpeta de temas
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

# 3) Eliminar archivo .poshtheme
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

# 4) Eliminar bloque persistente del perfil (robusto)
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
        try {
            Remove-Item -Recurse -Force -Path $d
            Write-Ok ("🗑️ Eliminado: " + $d)
        } catch {
            Write-Warn "⚠️ Error borrando $d"
            Write-Host "        $_"
        }
    }
}

# 6) Eliminar PATH de usuario si contiene ruta instalada por este script (opcional)
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
            Write-Ok "✅ Se removieron entradas de PATH de usuario relacionadas."
        } else {
            Write-Info "ℹ️ No se detectaron entradas de PATH de usuario para remover."
        }
    }
} catch {
    Write-Warn "⚠️ Error actualizando PATH de usuario: $_"
}

# 7) Intentar desinstalar via winget si está disponible
if (Get-Command winget -ErrorAction SilentlyContinue) {
    try {
        Write-Info "📦 Intentando desinstalación vía winget..."
        winget uninstall JanDeDobbeleer.OhMyPosh -e
        Write-Ok "✅ Intentada desinstalación vía winget."
    } catch {
        Write-Warn "⚠️ winget no pudo desinstalar automáticamente."
        Write-Host "        $_"
    }
} else {
    Write-Info "ℹ️ winget no disponible. Comprueba 'Agregar o quitar programas' si aún aparece."
}

Write-Ok "`n🧽 Limpieza finalizada. Reinicia PowerShell o la terminal para aplicar cambios."
