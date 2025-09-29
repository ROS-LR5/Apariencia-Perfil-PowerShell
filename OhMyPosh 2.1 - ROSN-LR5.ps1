<#
.SYNOPSIS
    Instala Oh My Posh y personaliza la terminal de Windows 11
.DESCRIPTION
    Este script automatiza la instalación de Oh My Posh usando winget,
    instala una fuente compatible, configura el perfil de PowerShell
    y personaliza la apariencia de la terminal.
.NOTES
    Versión: 1.3
    Autor: ROSN-LR5
#>

# Verifica si el script está siendo ejecutado como administrador
function Ensure-Admin {
    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "Este script requiere privilegios de administrador para instalar la fuente." -ForegroundColor Red
        Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        exit
    }
}

# Verifica si un comando existe
function Test-CommandExists {
    param($command)
    return $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
}

# Instala Oh My Posh si no está instalado
function Install-OhMyPosh {
    if (-not (Test-CommandExists "winget")) {
        Write-Host "❌ winget no está instalado. Por favor instala Windows Package Manager (App Installer) desde la Microsoft Store." -ForegroundColor Red
        exit
    }
    Write-Host "`n=== Instalando Oh My Posh ===" -ForegroundColor Cyan
    winget install JanDeDobbeleer.OhMyPosh -s winget --accept-package-agreements --accept-source-agreements -ErrorAction Stop
}

# Preguntar al usuario si desea sobrescribir recursos existentes
function Prompt-Overwrite {
    param(
        [string]$ItemDescription,
        [string]$ItemPath,
        [ref]$GlobalAnswer
    )

    if ($GlobalAnswer.Value -ne "") {
        return $GlobalAnswer.Value
    }

    Write-Host "`n⚠️ Ya existe $ItemDescription en: $ItemPath"
    Write-Host "¿Deseas sobrescribirlo?"
    Write-Host "[s] Sí  | [sa] Sí a todo  | [n] No  | [na] No a todo"
    $resp = Read-Host "Selecciona una opción"

    switch ($resp.ToLower()) {
        "sa" {
            $GlobalAnswer.Value = "yes"
            return "yes"
        }
        "na" {
            $GlobalAnswer.Value = "no"
            return "no"
        }
        "s" { return "yes" }
        default { return "no" }
    }
}

# Instala la fuente Meslo LGM NF
function Install-Font {
    Write-Host "`n=== Instalando fuente Meslo LGM NF ===" -ForegroundColor Cyan
    $fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Meslo.zip"
    $tempDir = [System.IO.Path]::GetTempPath()
    $fontZip = Join-Path $tempDir "Meslo.zip"
    $fontDir = Join-Path $tempDir "MesloFonts"

    $overwriteFonts = ""
    if (Test-Path $fontZip -or Test-Path $fontDir) {
        $overwriteFonts = Prompt-Overwrite "las fuentes descargadas o extraídas" $fontDir ([ref]$global:overwriteFontsAnswer)
        if ($overwriteFonts -eq "no") {
            Write-Host "❌ Instalación de fuentes cancelada por el usuario." -ForegroundColor Yellow
            return
        }
    }

    # Descargar y extraer la fuente
    Invoke-WebRequest -Uri $fontUrl -OutFile $fontZip -ErrorAction Stop
    if (-not (Test-Path $fontDir)) { New-Item -ItemType Directory -Path $fontDir -Force | Out-Null }
    Expand-Archive -Path $fontZip -DestinationPath $fontDir -Force -ErrorAction Stop

    # Instalar las fuentes
    $shell = New-Object -ComObject Shell.Application
    $fontsFolder = $shell.Namespace(0x14)
    Get-ChildItem -Path $fontDir -Recurse -Include "*.ttf" | ForEach-Object {
        $fontPath = $_.FullName
        $fontsFolder.CopyHere($fontPath, 0x10)
    }
}

# Configura el perfil de PowerShell
function Configure-PowerShellProfile {
    Write-Host "`n=== Configurando el perfil de PowerShell ===" -ForegroundColor Cyan
    if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force }

    $ohMyPoshConfig = @"
# Oh My Posh setup
oh-my-posh init pwsh --config "`$env:POSH_THEMES_PATH\jandedobbeleer.omp.json"` | Invoke-Expression

# Aliases útiles
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name grep -Value Select-String

# Colores personalizados
`$Host.PrivateData.ErrorForegroundColor = "Red"
`$Host.PrivateData.ErrorBackgroundColor = "Black"
`$Host.PrivateData.WarningForegroundColor = "Yellow"
`$Host.PrivateData.WarningBackgroundColor = "Black"
`$Host.PrivateData.DebugForegroundColor = "Cyan"
`$Host.PrivateData.DebugBackgroundColor = "Black"

# Función para actualizar Oh My Posh
function Update-Posh {
    winget upgrade JanDeDobbeleer.OhMyPosh -s winget --accept-package-agreements --accept-source-agreements
    oh-my-posh font install
    Write-Host "Oh My Posh actualizado correctamente." -ForegroundColor Green
}
"@

    Set-Content -Path $PROFILE -Value $ohMyPoshConfig -Force
}

# Configura la Terminal de Windows
function Configure-WindowsTerminal {
    Write-Host "`n=== Configurando la Terminal de Windows ===" -ForegroundColor Cyan
    $terminalSettings = @"
{
    "profiles": {
        "defaults": {
            "font": {
                "face": "MesloLGL Nerd Font",
                "size": 15
            },
            "opacity": 85,
            "useAcrylic": true
        },
        "list": [
            {
                "commandline": "powershell.exe -NoExit",
                "guid": "{61c54bbd-c2c6-5271-96e7-009a87ff44bf}",
                "hidden": false,
                "name": "PowerShell Personalizado",
                "startingDirectory": "%USERPROFILE%"
            }
        ]
    },
    "schemes": [
        {
            "background": "#012456",
            "black": "#0C0C0C",
            "blue": "#0037DA",
            "brightBlack": "#767676",
            "brightBlue": "#3B78FF",
            "brightCyan": "#61D6D6",
            "brightGreen": "#16C60C",
            "brightPurple": "#B4009E",
            "brightRed": "#E74856",
            "brightWhite": "#F2F2F2",
            "brightYellow": "#F9F1A5",
            "cyan": "#3A96DD",
            "foreground": "#CCCCCC",
            "green": "#13A10E",
            "name": "Custom Blue",
            "purple": "#881798",
            "red": "#C50F1F",
            "white": "#CCCCCC",
            "yellow": "#C19C00"
        }
    ],
    "theme": "dark"
}
"@

    $terminalSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (Test-Path $terminalSettingsPath) {
        $backupPath = "$terminalSettingsPath.backup_$(Get-Date -Format 'yyyyMMddHHmmss')"
        Copy-Item -Path $terminalSettingsPath -Destination $backupPath -Force
        Write-Host "📝 Copia de seguridad creada: $backupPath" -ForegroundColor Yellow
    }

    Set-Content -Path $terminalSettingsPath -Value $terminalSettings -Force
}

# =========================
# 🚀 EJECUCIÓN PRINCIPAL
# =========================

Ensure-Admin
Install-OhMyPosh
Install-Font
Configure-PowerShellProfile
Configure-WindowsTerminal

Write-Host "`n=== ✅ Instalación completada ===" -ForegroundColor Green
Write-Host "1. Oh My Posh ha sido instalado correctamente."
Write-Host "2. La fuente Meslo LGM NF ha sido instalada (si fue necesario)."
Write-Host "3. El perfil de PowerShell ha sido configurado."
Write-Host "4. La Terminal de Windows ha sido
