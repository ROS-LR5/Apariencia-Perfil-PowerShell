# Script de instalación - ROSN-LR5
#Autor: ROSN-LR5
#Version:3.0
# Requisitos: Ejecutar como Administrador


$chars = "R O S N - L R 5".ToCharArray()
foreach ($c in $chars) {
    Write-Host $c -NoNewline -ForegroundColor Cyan
    Start-Sleep -Milliseconds 150
}
Write-Host
Start-Sleep -Milliseconds 300
Write-Host "🚀 Iniciando instalación de Oh My Posh..." -ForegroundColor Green

# --------------------------
# Verificar ejecución como Administrador
# --------------------------
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ Este script debe ejecutarse como administrador." -ForegroundColor Red
    exit
}

# --------------------------
# Preparar perfil
# --------------------------
$ProfilePath = $PROFILE
$ProfileDir = Split-Path -Parent $ProfilePath

if (-not (Test-Path $ProfileDir)) {
    New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
}
if (-not (Test-Path $ProfilePath)) {
    New-Item -ItemType File -Path $ProfilePath -Force | Out-Null
}

# --------------------------
# Backup del perfil
# --------------------------
$BackupPath = "$ProfilePath.backup"
if (-not (Test-Path $BackupPath)) {
    Copy-Item -Path $ProfilePath -Destination $BackupPath -Force
    Write-Host "✅ Backup del perfil creado en: $BackupPath"
} else {
    Write-Host "ℹ️ Ya existe un backup en: $BackupPath"
}

# --------------------------
# Instalar Oh My Posh
# --------------------------
Write-Host "`n🔧 Instalando Oh My Posh..."
winget install JanDeDobbeleer.OhMyPosh -s winget -e --accept-source-agreements --accept-package-agreements

# --------------------------
# Instalar fuentes necesarias
# --------------------------
Write-Host "`n🔤 Instalando Nerd Fonts (CascadiaCode y Meslo)..."
oh-my-posh font install CascadiaCode
oh-my-posh font install Meslo

# --------------------------
# Descargar temas personalizados
# --------------------------
$CustomThemesPath = "$env:USERPROFILE\oh-my-posh-themes"
New-Item -ItemType Directory -Path $CustomThemesPath -Force | Out-Null

$themes = @(
    "M365Princess", "agnoster", "atomic", "cert", "clean-detailed",
    "cloud-native-azure", "jonnychipz", "kushal", "stelbent.minimal",
    "tokyo", "glowsticks", "paradox", "jandedobbeleer", 
    "powerlevel10k_rainbow", "minimal", "ys"
)

foreach ($theme in $themes) {
    $url = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/$theme.omp.json"
    $out = "$CustomThemesPath\$theme.omp.json"
    try {
        Invoke-WebRequest -Uri $url -OutFile $out -ErrorAction Stop
        Write-Host "✅ Tema descargado: $theme"
    } catch {
        Write-Host "❌ No se pudo descargar el tema: $theme" -ForegroundColor Yellow
    }
}

Write-Host "`n🎨 Temas descargados en: $CustomThemesPath"

# --------------------------
# Agregar al perfil la configuración para mantener el tema
# --------------------------
$ConfigBlock = @"
# -------------------------------
# Configuración Oh My Posh (ROSN-LR5)
# -------------------------------
function Set-PoshTheme {
    param([string]`$theme)
    `$themePath = "`$env:USERPROFILE\oh-my-posh-themes\$theme.omp.json"
    if (Test-Path `$themePath) {
        `$prompt = & oh-my-posh init pwsh --config "`$themePath"
        Invoke-Expression `$prompt
        `$env:POSH_THEME = `$theme
        Set-Content -Path "`$env:USERPROFILE\.poshtheme" -Value `$theme
        Write-Host "✅ Tema aplicado: `$theme" -ForegroundColor Green
    } else {
        Write-Host "❌ Tema no encontrado: `$theme" -ForegroundColor Red
    }
}

# Restaurar último tema aplicado
if (Test-Path "`$env:USERPROFILE\.poshtheme") {
    `$lastTheme = Get-Content "`$env:USERPROFILE\.poshtheme"
    Set-PoshTheme `$lastTheme
} else {
    Set-PoshTheme "jandedobbeleer"
}
"@

Add-Content -Path $ProfilePath -Value "`n$ConfigBlock"
Write-Host "`n✅ Perfil actualizado. Tema inicial: jandedobbeleer"

# --------------------------
# Final
# --------------------------
Write-Host "`n🎉 Instalación completada. Cierra y vuelve a abrir PowerShell o ejecuta:"
Write-Host "`n    . `$PROFILE" -ForegroundColor Cyan
Write-Host "`nLuego puedes cambiar el tema con:"
Write-Host "`n    Set-PoshTheme 'tokyo'" -ForegroundColor Yellow
