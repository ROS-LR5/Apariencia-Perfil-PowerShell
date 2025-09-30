# install-OhMyPosh2.1-ROSN-LR5.ps1
# Autor: ROSN-LR5
# Ver. 2.1

# Descripción: Instala y configura Oh My Posh con varios temas y opción de revertir cambios.

$chars = "R O S N - L R 5".ToCharArray()
foreach ($c in $chars) {
    Write-Host $c -NoNewline -ForegroundColor Cyan
    Start-Sleep -Milliseconds 150
}
Write-Host     # salto de línea
Start-Sleep -Milliseconds 300
Write-Host "🚀 Iniciando instalación de Oh My Posh..." -ForegroundColor Green

# --------------------------
# Paso 1: Verificación de permisos
# --------------------------
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Por favor, ejecuta este script como Administrador." -ForegroundColor Red
    exit
}

# --------------------------
# Paso 2: Backup de perfil original
# --------------------------
$ProfilePath = $PROFILE
$BackupPath = "$PROFILE.backup"

if (-not (Test-Path $BackupPath)) {
    Copy-Item -Path $ProfilePath -Destination $BackupPath -Force -ErrorAction SilentlyContinue
    Write-Host "✅ Backup del perfil creado en: $BackupPath"
} else {
    Write-Host "ℹ️ Ya existe un backup en: $BackupPath"
}

# --------------------------
# Paso 3: Instalación de Oh My Posh
# --------------------------
Write-Host "`n🔧 Instalando Oh My Posh..."

winget install JanDeDobbeleer.OhMyPosh -s winget -e --accept-source-agreements --accept-package-agreements

# --------------------------
# Paso 4: Instalar Nerd Fonts
# --------------------------
Write-Host "`n🔤 Instalando Nerd Fonts (CascadiaCode)..."

oh-my-posh font install CascadiaCode

# --------------------------
# Paso 5: Crear carpeta de temas personalizados
# --------------------------
$ThemesPath = "$env:USERPROFILE\AppData\Local\Programs\oh-my-posh\themes"
$CustomThemesPath = "$env:USERPROFILE\oh-my-posh-themes"
New-Item -ItemType Directory -Path $CustomThemesPath -Force | Out-Null

# Lista de temas
$themes = @(
    "M365Princess",
    "agnoster",
    "atomic",
    "cert",
    "clean-detailed",
    "cloud-native-azure",
    "jonnychipz",
    "kushal",
    "stelbent.minimal",
    "tokyo",
    "glowsticks",
    "paradox",
    "jandedobbeleer",
    "powerlevel10k_rainbow",
    "minimal",
    "ys"
    #"default"  # Tema original
)

# Descargar temas
foreach ($theme in $themes) {
    $url = "https://github.com/JanDeDobbeleer/oh-my-posh/tree/main/themes/$theme.omp.json"
    $out = "$CustomThemesPath\$theme.omp.json"
    Invoke-WebRequest -Uri $url -OutFile $out -ErrorAction SilentlyContinue
}

Write-Host "`n🎨 Temas descargados en: $CustomThemesPath"

# --------------------------
# Paso 6: Agregar configuración al perfil
# --------------------------
$SetThemeFunction = @"
function Set-PoshTheme {
    param([string]`$theme)
    `$themePath = "`"$CustomThemesPath/\$theme.omp.json`""
    if (Test-Path \$themePath) {
        oh-my-posh init pwsh --config \$themePath | Invoke-Expression
        `$env:POSH_THEME = \$theme
        Write-Host "Tema aplicado: \$theme" -ForegroundColor Green
    } else {
        Write-Host "Tema no encontrado: \$theme" -ForegroundColor Red
    }
}
Set-PoshTheme "jandedobbeleer"
"@

# Agregar al perfil
Add-Content -Path $ProfilePath -Value "`n# Oh My Posh Configuration"
Add-Content -Path $ProfilePath -Value "Import-Module oh-my-posh"
Add-Content -Path $ProfilePath -Value $SetThemeFunction

Write-Host "`n✅ Perfil actualizado. Tema inicial: jandedobbeleer"

# --------------------------
# Paso 7: Final
# --------------------------
Write-Host "`n🎉 Instalación completada. Cierra y vuelve a abrir PowerShell o ejecuta:"
Write-Host "`n    . $PROFILE" -ForegroundColor Cyan
Write-Host "`nLuego puedes cambiar el tema con:"
Write-Host "`n    Set-PoshTheme 'tokyo'" -ForegroundColor Yellow
