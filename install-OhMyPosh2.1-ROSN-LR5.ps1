# install-oh-my-posh-persist-ROSN-LR5.ps1
# Autor: ROSN-LR5 (mejora)
# Version: 3.1
# Requisitos: PowerShell 7.x. Ejecutar como Administrador para instalación system-wide (opcional).

[CmdletBinding()]
param(
    [switch]$UserScope  # si se pasa, instala en scope user (no requiere admin)
)


$chars = "R O S N - L R 5".ToCharArray()
foreach ($c in $chars) {
    Write-Host $c -NoNewline -ForegroundColor Cyan
    Start-Sleep -Milliseconds 100
}
Write-Host
Write-Host "🚀 Iniciando instalacion Oh My Posh (persistente)..." -ForegroundColor Green

# Verificar ejecutable winget (no es obligatorio, pero recomendado)
$hasWinget = (Get-Command winget -ErrorAction SilentlyContinue) -ne $null

# Si no es user scope, comprobar permisos admin
if (-not $UserScope) {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "⚠️ No eres administrador. Ejecuta con -UserScope para instalar solo en usuario o abre como Administrador." -ForegroundColor Yellow
    }
}

# Perfil y backup
$ProfilePath = $PROFILE
$ProfileDir = Split-Path -Parent $ProfilePath
if (-not (Test-Path $ProfileDir)) { New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null }
if (-not (Test-Path $ProfilePath)) { New-Item -ItemType File -Path $ProfilePath -Force | Out-Null }

$BackupPath = "$ProfilePath.backup"
if (-not (Test-Path $BackupPath)) {
    Copy-Item -Path $ProfilePath -Destination $BackupPath -Force
    Write-Host "✅ Backup creado en: $BackupPath"
} else {
    Write-Host "ℹ️ Backup ya existe en: $BackupPath"
}

# Instalar Oh My Posh con winget si está disponible, si no intentar scoop/choco o instruir
if ($hasWinget) {
    Write-Host "🔧 Instalando/actualizando Oh My Posh via winget..."
    if ($UserScope) {
        winget install JanDeDobbeleer.OhMyPosh --source winget --scope user --force --accept-source-agreements --accept-package-agreements
    } else {
        winget install JanDeDobbeleer.OhMyPosh --source winget --scope machine --force --accept-source-agreements --accept-package-agreements
    }
} else {
    Write-Host "⚠️ winget no disponible. Asegurate de instalar Oh My Posh manualmente o instalar winget. Visit: https://ohmyposh.dev/docs/installation/windows" -ForegroundColor Yellow
}

# Esperar a que oh-my-posh esté en PATH (revisar ruta típica)
$ohmypPath = "$env:LOCALAPPDATA\Programs\oh-my-posh\bin\oh-my-posh.exe"
if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    if (Test-Path $ohmypPath) {
        $env:Path += ";$env:LOCALAPPDATA\Programs\oh-my-posh\bin"
        Write-Host "🛠 Ruta de oh-my-posh añadida al PATH para esta sesión."
    } else {
        Write-Host "⚠️ oh-my-posh no encontrado en PATH. Si ya lo instalaste, reinicia la terminal o añade manualmente la ruta." -ForegroundColor Yellow
    }
}

# Instalar fuentes recomendadas (Meslo Nerd Font) usando oh-my-posh cli si disponible
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    Write-Host "🔤 Instalando Meslo Nerd Font (recomendado)..."
    try {
        oh-my-posh font install meslo | Out-Null
        Write-Host "✅ Meslo instalado (user or system según permisos). Configura tu terminal para usar 'MesloLGM Nerd Font'."
    } catch {
        Write-Host "⚠️ Falló instalación de fuente via oh-my-posh. Puedes instalar Meslo manualmente y configurar Windows Terminal." -ForegroundColor Yellow
    }
} else {
    Write-Host "ℹ️ omitting font install: oh-my-posh no disponible para instalar fuentes automaticamente." -ForegroundColor Yellow
}

# Carpeta de temas local
$CustomThemesPath = Join-Path $env:USERPROFILE "oh-my-posh-themes"
if (-not (Test-Path $CustomThemesPath)) { New-Item -ItemType Directory -Path $CustomThemesPath -Force | Out-Null }

# Lista de temas a descargar (agrega o elimina nombres según prefieras)
$themes = @(
    "M365Princess","agnoster","atomic","cert","clean-detailed",
    "cloud-native-azure","jonnychipz","kushal","stelbent.minimal",
    "tokyo","glowsticks","paradox","jandedobbeleer",
    "powerlevel10k_rainbow","minimal","ys"
)

Write-Host "⬇️ Descargando temas desde GitHub..."
foreach ($theme in $themes) {
    $candidates = @(
        "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/$theme.omp.json",
        "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/$theme.omp.yaml",
        "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/$theme.omp.yml"
    )
    $downloaded = $false
    foreach ($url in $candidates) {
        $ext = [IO.Path]::GetExtension($url)
        $out = Join-Path $CustomThemesPath "$theme$ext"
        try {
            Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing -ErrorAction Stop
            Write-Host "✅ Tema descargado: $theme -> $out"
            $downloaded = $true
            break
        } catch {
            # intentar siguiente candidato
        }
    }
    if (-not $downloaded) {
        Write-Host "⚠️ No se pudo descargar el tema: $theme" -ForegroundColor Yellow
    }
}

Write-Host "🎨 Temas disponibles en: $CustomThemesPath"

# Función Set-PoshTheme robusta y persistente
$ConfigBlock = @'
# ===== Oh My Posh Persistent Configuration =====
function Set-PoshTheme {
    param([Parameter(Mandatory=$true)][string]$theme)

    $homeThemes = Join-Path $env:USERPROFILE "oh-my-posh-themes"
    # buscar posibles extensiones .json .yaml .yml
    $paths = @(
        Join-Path $homeThemes "$theme.omp.json",
        Join-Path $homeThemes "$theme.omp.yaml",
        Join-Path $homeThemes "$theme.omp.yml"
    ) | Where-Object { Test-Path $_ }

    if ($paths.Count -eq 0) {
        Write-Host "❌ Tema no encontrado localmente: $theme" -ForegroundColor Red
        return
    }

    $themePath = $paths[0]

    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        # usar --config a la ruta local y evaluar init para pwsh
        $initCmd = "oh-my-posh init pwsh --config `"$themePath`""
        try {
            $prompt = & oh-my-posh init pwsh --config "$themePath"
            Invoke-Expression $prompt
        } catch {
            # fallback con eval si init falla
            oh-my-posh init pwsh --config "$themePath" --eval | Invoke-Expression
        }

        $env:POSH_THEME = $theme
        # persistir elección
        Set-Content -Path (Join-Path $env:USERPROFILE ".poshtheme") -Value $theme -Force
        Write-Host "✅ Tema aplicado y guardado: $theme" -ForegroundColor Green
    } else {
        Write-Host "❌ oh-my-posh no disponible. Asegura que esté instalado y en PATH." -ForegroundColor Red
    }
}

# Restaurar ultimo tema al iniciar
if (Test-Path (Join-Path $env:USERPROFILE ".poshtheme")) {
    $last = Get-Content (Join-Path $env:USERPROFILE ".poshtheme") -ErrorAction SilentlyContinue
    if ($last) { Set-PoshTheme $last }
}
# ===== end persistent config =====
'@

# Añadir bloque al perfil si no existe ya (evitar duplicados)
$profileContent = Get-Content -Path $ProfilePath -Raw -ErrorAction SilentlyContinue
if ($profileContent -notlike "*Oh My Posh Persistent Configuration*") {
    Add-Content -Path $ProfilePath -Value "`n$ConfigBlock"
    Write-Host "✅ Perfil actualizado con configuración persistente."
} else {
    Write-Host "ℹ️ Perfil ya contiene configuración persistente. No se agregó duplicado."
}

Write-Host "`n🎉 Instalacion finalizada. Reinicia PowerShell o recarga el perfil con:" -ForegroundColor Cyan
Write-Host "    . $PROFILE" -ForegroundColor Cyan
Write-Host "`nPara aplicar un tema manualmente:" -ForegroundColor Yellow
Write-Host "    Set-PoshTheme 'tokyo'"

# Sugerencias extras
Write-Host "`nConsejos: 1) Configura Windows Terminal para usar 'MesloLGM Nerd Font' o la Nerd Font que prefieras; 2) Activa live reload con 'oh-my-posh enable reload' para ver cambios sin reiniciar." -ForegroundColor Gray
