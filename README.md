📋 Requisitos
Windows 10 u 11

PowerShell 5.1 o superior

winget habilitado

🗂️ Estructura del repositorio

Apariencia-Perfil-PowerShell/
├── install-OhMyPosh2.1-ROSN-LR5.ps1      # Script para instalar/configurar
├── uninstall-oh-my-posh-ROSN-LR5.ps1     # Script para desinstalar y revertir
└── README.md                              # Este documento

# 🖌️ Instalador de Oh My Posh para PowerShell (Windows)

Este repositorio facilita la **instalación, configuración, cambio de temas y desinstalación completa** en PowerShell, para que tengas una terminal bonita y personalizada sin complicaciones.

## 🚀 Instalación rápida

1. Abre PowerShell como **Administrador**.  
2. Ejecuta este comando para instalar todo automáticamente:

```powershell

irm https://raw.githubusercontent.com/ROSN-LR5/Apariencia-Perfil-PowerShell/main/install-OhMyPosh2.1-ROSN-LR5.ps1 | iex

⚠️ Es necesario tener winget. Si no lo tienes, instálalo desde la Microsoft Store usando “App Installer”.

🎨 Temas incluidos
El script descarga estos temas automáticamente:

java
Copiar código
M365Princess  
agnoster  
atomic  
cert  
clean-detailed  
cloud-native-azure  
jonnychipz  
kushal  
stelbent.minimal  
tokyo  
glowsticks  
paradox  
jandedobbeleer  
powerlevel10k_rainbow  
minimal  
ys  
default (tema clásico de PowerShell)

🎛️ Cambiar de tema
Puedes cambiar el tema con este comando:

powershell
Copiar código
Set-PoshTheme "NOMBRE_DEL_TEMA"

Ejemplo:

powershell
Copiar código
Set-PoshTheme "tokyo"
Los temas se instalan en la carpeta:

perl
Copiar código
$HOME\oh-my-posh-themes
💾 Respaldos
Antes de alterar tu perfil de PowerShell, el script crea un respaldo en:

bash
Copiar código
$PROFILE.backup
Así puedes volver fácilmente si algo no te gusta.

--------------------------------------------------------------------------------------------------
💣 Desinstalación total
Para regresar al estado original completo:

Abre PowerShell como Administrador.

Ejecuta:

powershell
Copiar código

irm https://raw.githubusercontent.com/ROSN-LR5/Apariencia-Perfil-PowerShell/main/uninstall-oh-my-posh-ROSN-LR5.ps1 | iex

Esto hará:

Restaurar tu perfil original ($PROFILE) desde el backup.

Eliminar los temas descargados.

Desinstalar Oh My Posh vía winget.


🤝 Contribuciones
¿Quieres mejorar algo o agregar funciones?
Haz fork del repositorio, modifica lo que quieras y envía un Pull Request. ¡Toda contribución es bienvenida!

✨ Créditos
Creado por ROSN‑LR5

Basado en Oh My Posh por Jan De Dobbeleer
