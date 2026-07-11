# ============================================================
# install.ps1 - Instalador Automático de OptiWin
# Version: 5.0 - Sin preguntas, abre automáticamente
# ============================================================

Write-Host "═══════════════════════════════════════════" -ForegroundColor Green
Write-Host "    OptiWin - Optimizador de Windows" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════" -ForegroundColor Green
Write-Host ""

# ============================================================
# 1. VERIFICAR ADMINISTRADOR
# ============================================================
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ERR] Ejecutá como administrador." -ForegroundColor Red
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# ============================================================
# 2. CONFIGURACIÓN
# ============================================================
$repoOwner = "Fraqqqq"
$repoName = "OptiWin"
$baseUrl = "https://raw.githubusercontent.com/$repoOwner/$repoName/main"
$installDir = "$env:USERPROFILE\OptiWin"

Write-Host "[INFO] Instalando OptiWin..." -ForegroundColor Cyan

# ============================================================
# 3. CREAR DIRECTORIO DE INSTALACIÓN
# ============================================================
New-Item -ItemType Directory -Path $installDir -Force | Out-Null
Write-Host "[OK] Directorio creado: $installDir" -ForegroundColor Green

# ============================================================
# 4. DESCARGAR ARCHIVOS
# ============================================================
Write-Host "[INFO] Descargando OptiWin.py..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "$baseUrl/OptiWin.py" -OutFile "$installDir\OptiWin.py"
Write-Host "[OK] Script descargado" -ForegroundColor Green

try {
    Write-Host "[INFO] Descargando requirements.txt..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri "$baseUrl/requirements.txt" -OutFile "$installDir\requirements.txt" -ErrorAction Stop
    Write-Host "[OK] requirements.txt descargado" -ForegroundColor Green
} catch {
    Write-Host "[INFO] No hay requirements.txt, continuando..." -ForegroundColor Yellow
}

# ============================================================
# 5. FUNCIÓN: VERIFICAR PYTHON
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
# 6. FUNCIÓN: INSTALAR PYTHON SILENCIOSO
# ============================================================
function Install-PythonSilent {
    Write-Host "[INFO] Python no encontrado. Instalando..." -ForegroundColor Yellow
    
    $pythonUrl = "https://www.python.org/ftp/python/3.12.4/python-3.12.4-amd64.exe"
    $installerPath = "$env:TEMP\python-installer.exe"
    
    Write-Host "[INFO] Descargando Python desde python.org..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $pythonUrl -OutFile $installerPath -ErrorAction Stop
    } catch {
        Write-Host "[ERR] No se pudo descargar Python." -ForegroundColor Red
        Write-Host "[INFO] Instalá Python manualmente desde python.org" -ForegroundColor Yellow
        Read-Host "Presioná ENTER para salir"
        exit 1
    }
    
    Write-Host "[INFO] Instalando Python (esto puede tomar varios minutos)..." -ForegroundColor Cyan
    
    $installArgs = "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0"
    Start-Process -FilePath $installerPath -ArgumentList $installArgs -Wait
    
    Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    Start-Sleep -Seconds 5
    
    if (Test-PythonInstalled) {
        Write-Host "[OK] Python instalado correctamente." -ForegroundColor Green
        return $true
    } else {
        Write-Host "[ERR] No se pudo instalar Python." -ForegroundColor Red
        return $false
    }
}

# ============================================================
# 7. VERIFICAR PYTHON
# ============================================================
Write-Host ""
Write-Host "[INFO] Verificando Python..." -ForegroundColor Cyan

$pythonOk = Test-PythonInstalled
if (-not $pythonOk) {
    $pythonOk = Install-PythonSilent
}

if (-not $pythonOk) {
    Write-Host "[ERR] No se pudo instalar Python." -ForegroundColor Red
    Write-Host "Instalalo manualmente desde: https://www.python.org/downloads/" -ForegroundColor Yellow
    Read-Host "Presioná ENTER para salir"
    exit 1
}

# ============================================================
# 8. VERIFICAR PIP
# ============================================================
Write-Host "[INFO] Verificando pip..." -ForegroundColor Cyan
try {
    $pipTest = & pip --version 2>&1
    if ($pipTest -notmatch "pip") {
        throw "Pip no encontrado"
    }
    Write-Host "[OK] Pip detectado" -ForegroundColor Green
} catch {
    Write-Host "[INFO] Instalando pip..." -ForegroundColor Yellow
    & python -m ensurepip --upgrade 2>&1 | Out-Null
    Write-Host "[OK] Pip instalado" -ForegroundColor Green
}

# ============================================================
# 9. INSTALAR DEPENDENCIAS
# ============================================================
Write-Host "[INFO] Instalando dependencias de Python..." -ForegroundColor Cyan
Set-Location $installDir
& python -m pip install --upgrade pip 2>&1 | Out-Null

if (Test-Path "$installDir\requirements.txt") {
    & pip install -r requirements.txt 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Dependencias instaladas" -ForegroundColor Green
    } else {
        Write-Host "[WARN] Error en algunas dependencias. Continuando..." -ForegroundColor Yellow
    }
} else {
    # Instalar dependencias mínimas
    $deps = @("customtkinter", "psutil", "pywin32")
    foreach ($dep in $deps) {
        & pip install $dep --quiet 2>&1 | Out-Null
    }
    Write-Host "[OK] Dependencias básicas instaladas" -ForegroundColor Green
}

# ============================================================
# 10. ELIMINAR ACCESO DIRECTO EXISTENTE (SI EXISTE)
# ============================================================
$desktop = [Environment]::GetFolderPath("Desktop")
$oldShortcut = "$desktop\OptiWin.lnk"
if (Test-Path $oldShortcut) {
    Remove-Item $oldShortcut -Force
    Write-Host "[OK] Acceso directo anterior eliminado" -ForegroundColor Yellow
}

# ============================================================
# 11. ABRIR OPTIWIN AUTOMÁTICAMENTE (SIN PREGUNTAR)
# ============================================================
Write-Host ""
Write-Host "═══════════════════════════════════════════" -ForegroundColor Green
Write-Host "[OK] INSTALACION COMPLETADA CON EXITO!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "OptiWin se instaló correctamente en:" -ForegroundColor White
Write-Host "  $installDir" -ForegroundColor Gray
Write-Host ""
Write-Host "[INFO] Abriendo OptiWin automáticamente..." -ForegroundColor Cyan

# Ejecutar OptiWin
Start-Process "python" -ArgumentList "$installDir\OptiWin.py"

Write-Host "[OK] OptiWin se está ejecutando." -ForegroundColor Green
Write-Host ""
Write-Host "Presioná ENTER para cerrar este instalador." -ForegroundColor Gray
Read-Host
