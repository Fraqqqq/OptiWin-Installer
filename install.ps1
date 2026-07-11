# install.ps1 - Instalador de OptiWin
Write-Host "═══════════════════════════════════════════" -ForegroundColor Green
Write-Host "    OptiWin - Optimizador de Windows" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════" -ForegroundColor Green
Write-Host ""

# Verificar permisos de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ERR] Este script debe ejecutarse como administrador." -ForegroundColor Red
    Write-Host "Cerrando y abriendo PowerShell como administrador..." -ForegroundColor Yellow
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# Configuración
$repoOwner = "Fraqqqq"
$repoName = "OptiWin"
$scriptUrl = "https://raw.githubusercontent.com/$repoOwner/$repoName/main/OptiWin.py"
$installDir = "$env:USERPROFILE\OptiWin"

Write-Host "[INFO] Instalando OptiWin..." -ForegroundColor Cyan

# Crear directorio
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    Write-Host "[OK] Directorio creado: $installDir" -ForegroundColor Green
}

# Descargar el script
Write-Host "[INFO] Descargando OptiWin.py..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $scriptUrl -OutFile "$installDir\OptiWin.py"
Write-Host "[OK] Script descargado" -ForegroundColor Green

# Descargar requirements.txt
$requirementsUrl = "https://raw.githubusercontent.com/$repoOwner/$repoName/main/requirements.txt"
Write-Host "[INFO] Descargando requirements.txt..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $requirementsUrl -OutFile "$installDir\requirements.txt"
Write-Host "[OK] requirements.txt descargado" -ForegroundColor Green

# Verificar Python
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    Write-Host "[WARN] Python no esta instalado." -ForegroundColor Yellow
    Write-Host "[INFO] Instalando Python desde Microsoft Store..." -ForegroundColor Cyan
    Start-Process "ms-windows-store://pdp/?productid=9PJPW5LDXLZ5" -Wait
    Write-Host "[OK] Instala Python desde la Store y volve a ejecutar este script." -ForegroundColor Green
    Read-Host "Presiona Enter para salir"
    exit
}

# Instalar dependencias
Write-Host "[INFO] Instalando dependencias de Python..." -ForegroundColor Cyan
Set-Location $installDir
python -m pip install --upgrade pip
pip install -r requirements.txt
Write-Host "[OK] Dependencias instaladas" -ForegroundColor Green

# Crear acceso directo en el escritorio
$desktop = [Environment]::GetFolderPath("Desktop")
$shortcutPath = "$desktop\OptiWin.lnk"
$wscript = New-Object -ComObject WScript.Shell
$shortcut = $wscript.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "python"
$shortcut.Arguments = "$installDir\OptiWin.py"
$shortcut.WorkingDirectory = $installDir
$shortcut.Save()
Write-Host "[OK] Acceso directo creado en el escritorio" -ForegroundColor Green

Write-Host ""
Write-Host "═══════════════════════════════════════════" -ForegroundColor Green
Write-Host "[OK] Instalacion completada con exito!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Ejecuta OptiWin desde el acceso directo en tu escritorio." -ForegroundColor White
Write-Host ""
Read-Host "Presiona Enter para salir"
