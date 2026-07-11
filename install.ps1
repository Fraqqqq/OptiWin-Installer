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

# ============================================
# VERIFICAR E INSTALAR PYTHON AUTOMÁTICAMENTE
# ============================================
Write-Host "[INFO] Verificando Python..." -ForegroundColor Cyan

# Intentar obtener la versión de Python
$pythonVersion = & python --version 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARN] Python no está instalado." -ForegroundColor Yellow
    Write-Host "[INFO] Instalando Python automáticamente..." -ForegroundColor Cyan
    
    # Descargar el instalador de Python desde la web oficial
    $pythonInstallerUrl = "https://www.python.org/ftp/python/3.12.4/python-3.12.4-amd64.exe"
    $installerPath = "$env:TEMP\python-installer.exe"
    
    Write-Host "[INFO] Descargando Python desde python.org..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $pythonInstallerUrl -OutFile $installerPath
    
    Write-Host "[INFO] Instalando Python (esto puede tomar unos minutos)..." -ForegroundColor Cyan
    Start-Process -FilePath $installerPath -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0" -Wait
    
    # Eliminar el instalador
    Remove-Item $installerPath -Force
    
    # Actualizar la variable de entorno PATH para que reconozca Python sin reiniciar
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    
    Write-Host "[OK] Python instalado correctamente." -ForegroundColor Green
} else {
    Write-Host "[OK] Python detectado: $pythonVersion" -ForegroundColor Green
}

# Verificar pip
$pipVersion = & pip --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARN] Pip no encontrado. Instalando pip..." -ForegroundColor Yellow
    & python -m ensurepip --upgrade
    Write-Host "[OK] Pip instalado" -ForegroundColor Green
} else {
    Write-Host "[OK] Pip detectado" -ForegroundColor Green
}

# Instalar dependencias
Write-Host "[INFO] Instalando dependencias de Python..." -ForegroundColor Cyan
Set-Location $installDir
& python -m pip install --upgrade pip
& pip install -r requirements.txt
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
