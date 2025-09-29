# Apariencia-Perfil-PowerShell
Apariencia Perfil PowerShell "OhMyPosh 2.1 - ROSN-LR5"
PowerShell Windows Terminal Customization Script

Este script de PowerShell automatiza la instalación y personalización de la terminal de Windows 11, incluyendo la instalación de Oh My Posh, una fuente compatible con iconos (Meslo LGM NF) y la configuración del perfil de PowerShell. Además, personaliza la apariencia de la Terminal de Windows con un esquema de colores y fuente específicos.

Requisitos

Windows 11 o versiones posteriores.

PowerShell versión 7 o superior.

winget (Windows Package Manager) debe estar instalado.

Privilegios de administrador para la instalación de fuentes.

Funcionalidades

Instala Oh My Posh: Herramienta para personalizar la apariencia de PowerShell y otras terminales.

Instala la fuente Meslo LGM NF: Una fuente compatible con iconos, necesaria para los temas y símbolos de Oh My Posh.

Configura el perfil de PowerShell: Se añaden configuraciones personalizadas a tu perfil de PowerShell para habilitar Oh My Posh y configurar alias y colores.

Configura la Terminal de Windows: Personaliza la Terminal de Windows con un esquema de colores y la fuente MesloLGM NF.

Instalación
Paso 1: Descargar el script

descarga el archivo .ps1 del script.

Paso 2: Ejecutar el script

Abre PowerShell como administrador (necesario para instalar las fuentes y hacer cambios en la configuración de la terminal).

Navega al directorio donde descargaste el script.

Ejecuta el script con el siguiente comando:

.\Install-TerminalCustomization.ps1


Si el script no se ejecuta, asegúrate de que el ExecutionPolicy de PowerShell permita la ejecución de scripts. Puedes cambiar la política temporalmente con:

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

Paso 3: Confirmación de instalación

Una vez ejecutado el script, se te indicará que la instalación fue exitosa. El script realizará lo siguiente:

Instalará Oh My Posh.

Instalará la fuente Meslo LGM NF.

Modificará el perfil de PowerShell para usar Oh My Posh.

Cambiará la configuración de la Terminal de Windows, incluyendo la fuente y el esquema de colores.

Revertir Cambios

Si necesitas revertir los cambios realizados por el script:

Restaurar la configuración de la Terminal de Windows: El script crea una copia de seguridad del archivo de configuración de la Terminal de Windows antes de modificarlo. El archivo de copia de seguridad se guarda en el mismo directorio con el sufijo .backup_[timestamp].

Eliminar cambios en el perfil de PowerShell: Si prefieres eliminar las configuraciones personalizadas de PowerShell, simplemente elimina las líneas agregadas al archivo de perfil, o restaura tu perfil original desde una copia de seguridad.

Notas

Personalización de la Terminal de Windows: Después de ejecutar el script, cierra y vuelve a abrir la Terminal de Windows para ver los cambios. Luego, selecciona 'PowerShell Personalizado' en la Terminal y ajusta la fuente a MesloLGM NF en la configuración de la Terminal.

Actualizaciones: Puedes actualizar Oh My Posh ejecutando el siguiente comando en PowerShell:

Update-Posh

Contribuciones

Si deseas contribuir a este proyecto, por favor abre un pull request o reporta problemas.
