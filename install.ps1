# install.ps1 - Instalador definitivo de OptiWin
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
# 5. VERIFICAR PYTHON (MÉTODO CORREGIDO)
# ============================================================
Write-Host "[INFO] Verificando Python..." -ForegroundColor Cyan

# Probar si Python existe en el sistema
try {
    $pythonTest = & python -c "print('ok')" 2>&1
    if ($pythonTest -match "ok") {
        $pythonVersion = & python --version 2>&1
        Write-Host "[OK] Python detectado: $pythonVersion" -ForegroundColor Green
    } else {
        throw "Python no encontrado"
    }
} catch {
    Write-Host "[INFO] Python no está instalado. Instalando automáticamente..." -ForegroundColor Yellow
    
    # Descargar Python desde python.org
    $pythonUrl = "https://www.python.org/ftp/python/3.12.4/python-3.12.4-amd64.exe"
    $installerPath = "$env:TEMP\python-installer.exe"
    
    Write-Host "[INFO] Descargando Python desde python.org..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $pythonUrl -OutFile $installerPath
    
    Write-Host "[INFO] Instalando Python (esto puede tomar varios minutos)..." -ForegroundColor Cyan
    Write-Host "[INFO] Por favor, esperá sin cerrar esta ventana..." -ForegroundColor Yellow
    
    # Instalación silenciosa
    $installArgs = "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0"
    $process = Start-Process -FilePath $installerPath -ArgumentList $installArgs -Wait -PassThru
    
    # Eliminar el instalador
    Remove-Item $installerPath -Force
    
    # Actualizar PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    
    # Verificar que se haya instalado
    try {
        $pythonTest = & python -c "print('ok')" 2>&1
        if ($pythonTest -match "ok") {
            Write-Host "[OK] Python instalado correctamente." -ForegroundColor Green
        } else {
            throw "Fallo la instalación"
        }
    } catch {
        Write-Host "[ERR] No se pudo instalar Python automáticamente." -ForegroundColor Red
        Write-Host "Descargalo manualmente desde python.org" -ForegroundColor Yellow
        Write-Host "Y volvé a ejecutar este script." -ForegroundColor Yellow
        Read-Host "Presioná ENTER para salir"
        exit
    }
}

# 6. Verificar pip
try {
    $pipTest = & pip --version 2>&1
    if ($pipTest -match "pip") {
        Write-Host "[OK] Pip detectado" -ForegroundColor Green
    } else {
        throw "Pip no encontrado"
    }
} catch {
    Write-Host "[INFO] Instalando pip..." -ForegroundColor Yellow
    & python -m ensurepip --upgrade
    Write-Host "[OK] Pip instalado" -ForegroundColor Green
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

# 10. Ejecutar OptiWin automáticamente
Start-Process "python" -ArgumentList "$installDir\OptiWin.py"

Write-Host "[OK] OptiWin se está ejecutando." -ForegroundColor Green
Write-Host ""
Read-Host "Presioná ENTER para cerrar este instalador"
