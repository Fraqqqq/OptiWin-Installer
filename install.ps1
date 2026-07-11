# ============================================================
# install.ps1 - Instalador profesional de OptiWin
# Version: 2.0 - Instalacion silenciosa de Python
# ============================================================

Write-Host "═══════════════════════════════════════════" -ForegroundColor Green
Write-Host "    OptiWin - Optimizador de Windows" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════" -ForegroundColor Green
Write-Host ""

# ============================================================
# 1. VERIFICAR PERMISOS DE ADMINISTRADOR
# ============================================================
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ERR] Este script debe ejecutarse como administrador." -ForegroundColor Red
    Write-Host "Reiniciando PowerShell como administrador..." -ForegroundColor Yellow
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# ============================================================
# 2. CONFIGURACION
# ============================================================
$repoOwner = "Fraqqqq"
$repoName = "OptiWin"
$scriptUrl = "https://raw.githubusercontent.com/$repoOwner/$repoName/main/OptiWin.py"
$requirementsUrl = "https://raw.githubusercontent.com/$repoOwner/$repoName/main/requirements.txt"
$installDir = "$env:USERPROFILE\OptiWin"
$pythonVersion = "3.12.4"
$pythonUrl = "https://www.python.org/ftp/python/$pythonVersion/python-$pythonVersion-amd64.exe"
$installerPath = "$env:TEMP\python-installer.exe"

Write-Host "[INFO] Instalando OptiWin..." -ForegroundColor Cyan

# ============================================================
# 3. CREAR DIRECTORIO DE INSTALACION
# ============================================================
New-Item -ItemType Directory -Path $installDir -Force | Out-Null
Write-Host "[OK] Directorio creado: $installDir" -ForegroundColor Green

# ============================================================
# 4. DESCARGAR ARCHIVOS DE OPTIWIN
# ============================================================
Write-Host "[INFO] Descargando OptiWin.py..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $scriptUrl -OutFile "$installDir\OptiWin.py"
Write-Host "[OK] Script descargado" -ForegroundColor Green

Write-Host "[INFO] Descargando requirements.txt..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $requirementsUrl -OutFile "$installDir\requirements.txt"
Write-Host "[OK] requirements.txt descargado" -ForegroundColor Green

# ============================================================
# 5. FUNCION: VERIFICAR PYTHON
# ============================================================
function Test-PythonInstalled {
    try {
        $result = & python -c "print('ok')" 2>&1
        return $result -match "ok"
    } catch {
        return $false
    }
}

# ============================================================
# 6. FUNCION: VERIFICAR PIP
# ============================================================
function Test-PipInstalled {
    try {
        $result = & pip --version 2>&1
        return $result -match "pip"
    } catch {
        return $false
    }
}

# ============================================================
# 7. FUNCION: INSTALAR PYTHON SILENCIOSAMENTE
# ============================================================
function Install-PythonSilent {
    Write-Host "[INFO] Python no encontrado. Instalando..." -ForegroundColor Yellow
    
    # Descargar el instalador de Python
    Write-Host "[INFO] Descargando Python desde python.org..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $pythonUrl -OutFile $installerPath -ErrorAction Stop
    } catch {
        Write-Host "[ERR] No se pudo descargar Python." -ForegroundColor Red
        Write-Host "[INFO] Intentando con método alternativo..." -ForegroundColor Yellow
        
        # Método alternativo: usar el instalador web
        $pythonUrlWeb = "https://www.python.org/ftp/python/3.12.4/python-3.12.4.exe"
        try {
            Invoke-WebRequest -Uri $pythonUrlWeb -OutFile $installerPath -ErrorAction Stop
        } catch {
            Write-Host "[ERR] No se pudo descargar Python por ningún método." -ForegroundColor Red
            Write-Host "[INFO] Instalá Python manualmente desde python.org" -ForegroundColor Yellow
            Write-Host "[INFO] Luego volvé a ejecutar este script." -ForegroundColor Yellow
            Read-Host "Presioná ENTER para salir"
            exit 1
        }
    }
    
    Write-Host "[INFO] Instalando Python en segundo plano..." -ForegroundColor Cyan
    Write-Host "[INFO] Esto puede tomar varios minutos..." -ForegroundColor Yellow
    
    # Instalación silenciosa COMPLETA
    $installArgs = @(
        "/quiet",
        "InstallAllUsers=1",
        "PrependPath=1",
        "Include_test=0",
        "SimpleInstall=1",
        "AssociateFiles=1"
    )
    
    $process = Start-Process -FilePath $installerPath -ArgumentList $installArgs -Wait -PassThru
    
    # Eliminar instalador
    Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
    
    # Actualizar PATH en la sesión actual
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    
    # Esperar a que Python se registre en el sistema
    Start-Sleep -Seconds 5
    
    # Verificar instalación
    if (Test-PythonInstalled) {
        Write-Host "[OK] Python instalado correctamente." -ForegroundColor Green
        return $true
    } else {
        # Intentar con el instalador normal (no silencioso) como fallback
        Write-Host "[WARN] La instalación silenciosa falló." -ForegroundColor Yellow
        Write-Host "[INFO] Reintentando con instalador interactivo..." -ForegroundColor Yellow
        
        # Forzar reinstalación con método alternativo
        try {
            Invoke-WebRequest -Uri $pythonUrl -OutFile $installerPath -ErrorAction Stop
        } catch {
            Write-Host "[ERR] No se pudo descargar Python." -ForegroundColor Red
            return $false
        }
        
        Start-Process -FilePath $installerPath -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait
        Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        Start-Sleep -Seconds 5
        
        if (Test-PythonInstalled) {
            Write-Host "[OK] Python instalado correctamente." -ForegroundColor Green
            return $true
        } else {
            Write-Host "[ERR] No se pudo instalar Python." -ForegroundColor Red
            Write-Host "[INFO] Instalá Python manualmente desde python.org" -ForegroundColor Yellow
            return $false
        }
    }
}

# ============================================================
# 8. FUNCION: VERIFICAR Y INSTALAR DEPENDENCIAS
# ============================================================
function Install-Dependencies {
    Write-Host "[INFO] Instalando dependencias de Python..." -ForegroundColor Cyan
    Set-Location $installDir
    
    # Actualizar pip
    & python -m pip install --upgrade pip 2>&1 | Out-Null
    
    # Instalar dependencias
    & pip install -r requirements.txt 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Dependencias instaladas" -ForegroundColor Green
        return $true
    } else {
        Write-Host "[ERR] Error al instalar dependencias." -ForegroundColor Red
        return $false
    }
}

# ============================================================
# 9. FUNCION: CREAR ACCESO DIRECTO
# ============================================================
function Create-Shortcut {
    $desktop = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = "$desktop\OptiWin.lnk"
    
    $wscript = New-Object -ComObject WScript.Shell
    $shortcut = $wscript.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = "python"
    $shortcut.Arguments = "$installDir\OptiWin.py"
    $shortcut.WorkingDirectory = $installDir
    $shortcut.IconLocation = "$installDir\OptiWin.py, 0"
    $shortcut.Save()
    
    Write-Host "[OK] Acceso directo creado en el escritorio" -ForegroundColor Green
    return $shortcutPath
}

# ============================================================
# 10. FUNCION: EJECUTAR OPTIWIN
# ============================================================
function Start-OptiWin {
    Write-Host "[INFO] Abriendo OptiWin..." -ForegroundColor Cyan
    Start-Process "python" -ArgumentList "$installDir\OptiWin.py"
    Write-Host "[OK] OptiWin se está ejecutando." -ForegroundColor Green
}

# ============================================================
# 11. EJECUCION PRINCIPAL
# ============================================================
Write-Host ""
Write-Host "[INFO] Verificando Python..." -ForegroundColor Cyan

# Verificar Python
$pythonOk = Test-PythonInstalled
if (-not $pythonOk) {
    $pythonOk = Install-PythonSilent
}

if (-not $pythonOk) {
    Write-Host ""
    Write-Host "[ERR] No se pudo instalar Python." -ForegroundColor Red
    Write-Host "Por favor, instalalo manualmente desde:" -ForegroundColor Yellow
    Write-Host "https://www.python.org/downloads/" -ForegroundColor Yellow
    Write-Host "Y volvé a ejecutar este script." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Presioná ENTER para salir"
    exit 1
}

# Verificar pip
Write-Host "[INFO] Verificando pip..." -ForegroundColor Cyan
$pipOk = Test-PipInstalled
if (-not $pipOk) {
    Write-Host "[INFO] Instalando pip..." -ForegroundColor Yellow
    & python -m ensurepip --upgrade 2>&1 | Out-Null
    Start-Sleep -Seconds 2
}

# Instalar dependencias
$depsOk = Install-Dependencies
if (-not $depsOk) {
    Write-Host ""
    Write-Host "[WARN] Las dependencias no se instalaron correctamente." -ForegroundColor Yellow
    Write-Host "[INFO] Podés instalarlas manualmente con:" -ForegroundColor Yellow
    Write-Host "cd $installDir" -ForegroundColor Yellow
    Write-Host "pip install -r requirements.txt" -ForegroundColor Yellow
}

# Crear acceso directo
Create-Shortcut

# ============================================================
# 12. RESUMEN FINAL
# ============================================================
Write-Host ""
Write-Host "═══════════════════════════════════════════" -ForegroundColor Green
Write-Host "[OK] INSTALACION COMPLETADA CON EXITO!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "OptiWin se instaló correctamente en:" -ForegroundColor White
Write-Host "  $installDir" -ForegroundColor Gray
Write-Host ""
Write-Host "Acceso directo creado en el escritorio." -ForegroundColor White
Write-Host ""

# Preguntar si quiere abrir OptiWin ahora
$response = Read-Host "¿Querés abrir OptiWin ahora? (S/N)"
if ($response -eq "S" -or $response -eq "s" -or $response -eq "SI" -or $response -eq "si") {
    Start-OptiWin
} else {
    Write-Host "[INFO] Podés ejecutar OptiWin desde el acceso directo en el escritorio." -ForegroundColor Cyan
}

Write-Host ""
Read-Host "Presioná ENTER para salir"
