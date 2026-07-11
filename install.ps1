# ============================================================
# install.ps1 - Instalador Rápido de OptiWin (Sin Rastros)
# Version: 3.1 - Ejecución directa, autolimpieza
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
$tempDir = "$env:TEMP\OptiWin_$(Get-Random)"
$pythonUrl = "https://www.python.org/ftp/python/3.12.4/python-3.12.4-embed-amd64.zip"

Write-Host "[INFO] Iniciando instalación rápida..." -ForegroundColor Cyan

# ============================================================
# 3. FUNCIÓN: DETECTAR PYTHON EXISTENTE
# ============================================================
function Get-PythonPath {
    # Buscar Python en ubicaciones comunes
    $paths = @(
        "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
        "$env:LOCALAPPDATA\Programs\Python\Python311\python.exe",
        "$env:ProgramFiles\Python312\python.exe",
        "$env:ProgramFiles\Python311\python.exe",
        (Get-Command python -ErrorAction SilentlyContinue).Source
    )
    
    foreach ($p in $paths) {
        if ($p -and (Test-Path $p)) {
            return $p
        }
    }
    
    # Intentar con el comando python
    try {
        $result = & python -c "import sys; print(sys.executable)" 2>&1
        if ($LASTEXITCODE -eq 0) {
            return $result.Trim()
        }
    } catch {
        # Ignorar
    }
    
    return $null
}

# ============================================================
# 4. FUNCIÓN: INSTALAR PYTHON PORTABLE
# ============================================================
function Install-PythonPortable {
    Write-Host "[INFO] Instalando Python portable (rápido)..." -ForegroundColor Yellow
    
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    Write-Host "[INFO] Descargando Python..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $pythonUrl -OutFile "$tempDir\python.zip" -ErrorAction Stop
    } catch {
        $pythonUrl = "https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip"
        Invoke-WebRequest -Uri $pythonUrl -OutFile "$tempDir\python.zip"
    }
    
    Write-Host "[INFO] Descomprimiendo..." -ForegroundColor Cyan
    Expand-Archive -Path "$tempDir\python.zip" -DestinationPath "$tempDir\python" -Force
    
    $pythonExe = "$tempDir\python\python.exe"
    
    # Configurar para pip
    $pthContent = "import site`nsite.addsitedir('$tempDir\python\Lib\site-packages')"
    $pthContent | Out-File -FilePath "$tempDir\python\python312._pth" -Encoding ASCII
    
    # Instalar pip
    Invoke-WebRequest -Uri "https://bootstrap.pypa.io/get-pip.py" -OutFile "$tempDir\get-pip.py"
    & $pythonExe "$tempDir\get-pip.py" --no-warn-script-location 2>&1 | Out-Null
    
    return $pythonExe
}

# ============================================================
# 5. FUNCIÓN: EJECUTAR OPTIWIN
# ============================================================
function Run-OptiWin {
    param($pythonExe, $scriptPath)
    
    Write-Host "[INFO] Ejecutando OptiWin..." -ForegroundColor Cyan
    
    # Ejecutar en una nueva ventana
    $process = Start-Process -FilePath $pythonExe -ArgumentList $scriptPath -WindowStyle Normal -PassThru
    
    Start-Sleep -Seconds 1
    if (-not $process.HasExited) {
        Write-Host "[OK] OptiWin ejecutándose." -ForegroundColor Green
        return $true
    }
    return $false
}

# ============================================================
# 6. FUNCIÓN: LIMPIEZA AUTOMÁTICA
# ============================================================
function Cleanup-After {
    param($paths)
    
    # Programar eliminación en segundo plano
    $script = {
        Start-Sleep -Seconds 15
        foreach ($path in $using:paths) {
            if (Test-Path $path) {
                Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    Start-Job -ScriptBlock $script | Out-Null
}

# ============================================================
# 7. EJECUCIÓN PRINCIPAL
# ============================================================
Write-Host ""

# Buscar Python existente
$pythonExe = Get-PythonPath

if (-not $pythonExe) {
    $pythonExe = Install-PythonPortable
}

if (-not $pythonExe) {
    Write-Host "[ERR] No se pudo instalar Python." -ForegroundColor Red
    Read-Host "Presioná ENTER para salir"
    exit 1
}

# Directorio temporal para OptiWin
$tempOptiWin = "$env:TEMP\OptiWin_Run"
New-Item -ItemType Directory -Path $tempOptiWin -Force | Out-Null

# Descargar OptiWin
$scriptPath = "$tempOptiWin\OptiWin.py"
Write-Host "[INFO] Descargando OptiWin..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "$baseUrl/OptiWin.py" -OutFile $scriptPath

# Instalar dependencias si existen
try {
    $requirementsPath = "$tempOptiWin\requirements.txt"
    Invoke-WebRequest -Uri "$baseUrl/requirements.txt" -OutFile $requirementsPath -ErrorAction Stop
    
    Write-Host "[INFO] Instalando dependencias..." -ForegroundColor Cyan
    $pipPath = "$tempDir\python\Scripts\pip.exe"
    if (Test-Path $pipPath) {
        & $pipPath install -r $requirementsPath --quiet --no-warn-script-location 2>&1 | Out-Null
    }
} catch {
    # No hay requirements.txt, continuar
}

# Ejecutar OptiWin
Write-Host ""
Run-OptiWin -pythonExe $pythonExe -scriptPath $scriptPath

# Programar limpieza automática (NO deja rastros)
Cleanup-After -paths @($tempDir, $tempOptiWin)

Write-Host ""
Write-Host "[OK] OptiWin instalado y ejecutándose." -ForegroundColor Green
Write-Host "[INFO] No se crearon archivos permanentes." -ForegroundColor Gray
Write-Host ""
Read-Host "Presioná ENTER para cerrar"
