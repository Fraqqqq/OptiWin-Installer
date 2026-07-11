# install.ps1 - Instalador mejorado de OptiWin
Write-Host "═══════════════════════════════════════════" -ForegroundColor Green
Write-Host "    OptiWin - Optimizador de Windows" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════" -ForegroundColor Green
Write-Host ""

# 1. Verificar permisos de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ERR] Este script debe ejecutarse como administrador." -ForegroundColor Red
    Write-Host "Reiniciando PowerShell como administrador..." -ForegroundColor Yellow
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# 2. Configuración
$repoOwner = "Fraqqqq"
$repoName = "OptiWin"
$scriptUrl = "https://raw.githubusercontent.com/$repoOwner/$repoName/main/OptiWin.py"
$requirementsUrl = "https://raw.githubusercontent.com/$repoOwner/$repoName/main/requirements.txt"
$installDir = "$env:USERPROFILE\OptiWin"

Write-Host "[INFO] Instalando OptiWin..." -ForegroundColor Cyan

# 3. Crear directorio de instalación
New-Item -ItemType Directory -Path $installDir -Force | Out-Null
Write-Host "[OK] Directorio creado: $installDir" -ForegroundColor Green

# 4. Descargar archivos
Write-Host "[INFO] Descargando OptiWin.py..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $scriptUrl -OutFile "$installDir\OptiWin.py"
Write-Host "[OK] Script descargado" -ForegroundColor Green

Write-Host "[INFO] Descargando requirements.txt..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $requirementsUrl -OutFile "$installDir\requirements.txt"
Write-Host "[OK] requirements.txt descargado" -ForegroundColor Green

# ============================================================
# 5. VERIFICAR E INSTALAR PYTHON DE FORMA ROBUSTA
# ============================================================
Write-Host "[INFO] Verificando Python..." -ForegroundColor Cyan

# Intentar obtener la versión de Python
$pythonVersion = & python --version 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARN] Python no está instalado." -ForegroundColor Yellow
    Write-Host "[INFO] Instalando Python desde la Microsoft Store..." -ForegroundColor Cyan
    
    # Abrir la página de Python en la Microsoft Store
    Start-Process "ms-windows-store://pdp/?productid=9PJPW5LDXLZ5"
    Write-Host ""
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host "ATENCION: Se abrió la Microsoft Store." -ForegroundColor Yellow
    Write-Host "1. Hacé clic en INSTALAR (o en OBTENER)." -ForegroundColor Yellow
    Write-Host "2. Esperá a que termine la instalación." -ForegroundColor Yellow
    Write-Host "3. CERRÁ la Store y VOLVÉ A ESTA VENTANA." -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Presioná ENTER cuando hayas terminado de instalar Python"

    # Verificar nuevamente después de la instalación
    $pythonVersion = & python --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "[ERR] No se detectó Python después de la instalación." -ForegroundColor Red
        Write-Host "Por favor, instalalo manualmente desde python.org" -ForegroundColor Red
        Read-Host "Presioná ENTER para salir"
        exit
    }
}

Write-Host "[OK] Python detectado: $pythonVersion" -ForegroundColor Green

# 6. Verificar e instalar pip
$pipVersion = & pip --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARN] Pip no encontrado. Instalando..." -ForegroundColor Yellow
    & python -m ensurepip --upgrade
    Write-Host "[OK] Pip instalado" -ForegroundColor Green
} else {
    Write-Host "[OK] Pip detectado" -ForegroundColor Green
}

# 7. Instalar dependencias
Write-Host "[INFO] Instalando dependencias de Python..." -ForegroundColor Cyan
Set-Location $installDir
& python -m pip install --upgrade pip
& pip install -r requirements.txt
Write-Host "[OK] Dependencias instaladas" -ForegroundColor Green

# 8. Crear acceso directo en el escritorio
$desktop = [Environment]::GetFolderPath("Desktop")
$shortcutPath = "$desktop\OptiWin.lnk"
$wscript = New-Object -ComObject WScript.Shell
$shortcut = $wscript.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "python"
$shortcut.Arguments = "$installDir\OptiWin.py"
$shortcut.WorkingDirectory = $installDir
$shortcut.Save()
Write-Host "[OK] Acceso directo creado en el escritorio" -ForegroundColor Green

# 9. Resumen final
Write-Host ""
Write-Host "═══════════════════════════════════════════" -ForegroundColor Green
Write-Host "[OK] Instalación completada con éxito!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "OptiWin se instaló correctamente." -ForegroundColor White
Write-Host "Abriendo la aplicación..." -ForegroundColor Cyan

# 10. Ejecutar OptiWin automáticamente al finalizar
Start-Process "python" -ArgumentList "$installDir\OptiWin.py"

Write-Host "[OK] OptiWin se está ejecutando." -ForegroundColor Green
Write-Host "Si ves una ventana negra, esperá unos segundos." -ForegroundColor White
Write-Host ""
Read-Host "Presioná ENTER para cerrar este instalador"
