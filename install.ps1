# ============================================================
# install.ps1 - Instalador Rápido de OptiWin
# Version: 3.0 - Ejecución directa sin rastros
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

Write-Host "[INFO] Iniciando..." -ForegroundColor Cyan

# ============================================================
# 3. FUNCIÓN: DESCARGAR ARCHIVOS EN PARALELO
# ============================================================
function Download-Files {
    param($urls)
    
    $jobs = @()
    foreach ($url in $urls) {
        $fileName = [System.IO.Path]::GetFileName($url)
        $outputPath = "$tempDir\$fileName"
        
        $jobs += Start-Job -ScriptBlock {
            param($url, $output)
            Invoke-WebRequest -Uri $url -OutFile $output -ErrorAction SilentlyContinue
        } -ArgumentList $url, $outputPath
    }
    
    $jobs | Wait-Job | Out-Null
    $jobs | Remove-Job
}

# ============================================================
# 4. FUNCIÓN: DETECTAR PYTHON
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
# 5. FUNCIÓN: INSTALAR PYTHON PORTABLE (RÁPIDO)
# ============================================================
function Install-PythonPortable {
    Write-Host "[INFO] Instalando Python portable..." -ForegroundColor Yellow
    
    # Crear directorio temporal
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    # Descargar Python portable (más rápido que el instalador completo)
    Write-Host "[INFO] Descargando Python..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $pythonUrl -OutFile "$tempDir\python.zip" -ErrorAction Stop
    } catch {
        # Fallback a versión más pequeña
        $pythonUrl = "https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip"
        Invoke-WebRequest -Uri $pythonUrl -OutFile "$tempDir\python.zip"
    }
    
    # Descomprimir
    Write-Host "[INFO] Descomprimiendo Python..." -ForegroundColor Cyan
    Expand-Archive -Path "$tempDir\python.zip" -DestinationPath "$tempDir\python" -Force
    
    # Configurar Python para que funcione sin instalación
    $pythonExe = "$tempDir\python\python.exe"
    
    # Crear archivo de configuración para pip
    $pthContent = "import site`nsite.addsitedir('$tempDir\python\Lib\site-packages')"
    $pthContent | Out-File -FilePath "$tempDir\python\python312._pth" -Encoding ASCII
    
    # Descargar get-pip.py
    Invoke-WebRequest -Uri "https://bootstrap.pypa.io/get-pip.py" -OutFile "$tempDir\get-pip.py"
    
    # Instalar pip en el Python portable
    & $pythonExe "$tempDir\get-pip.py" --no-warn-script-location 2>&1 | Out-Null
    
    return $pythonExe
}

# ============================================================
# 6. FUNCIÓN: INSTALAR DEPENDENCIAS RÁPIDO
# ============================================================
function Install-DependenciesFast {
    param($pythonExe, $requirementsPath)
    
    Write-Host "[INFO] Instalando dependencias..." -ForegroundColor Cyan
    
    # Instalar solo las necesarias en paralelo
    $deps = @("customtkinter", "psutil", "pywin32")
    $pipPath = "$tempDir\python\Scripts\pip.exe"
    
    foreach ($dep in $deps) {
        & $pipPath install $dep --quiet --no-warn-script-location 2>&1 | Out-Null
    }
}

# ============================================================
# 7. FUNCIÓN: EJECUTAR OPTIWIN DIRECTAMENTE
# ============================================================
function Run-OptiWin {
    param($pythonExe, $scriptPath)
    
    Write-Host "[INFO] Ejecutando OptiWin..." -ForegroundColor Cyan
    
    # Ejecutar directamente en una nueva ventana
    $process = Start-Process -FilePath $pythonExe -ArgumentList $scriptPath -WindowStyle Normal -PassThru
    
    # Esperar un momento y verificar que se abrió
    Start-Sleep -Seconds 1
    if (-not $process.HasExited) {
        Write-Host "[OK] OptiWin ejecutándose." -ForegroundColor Green
        return $true
    }
    
    return $false
}

# ============================================================
# 8. FUNCIÓN: LIMPIAR RASTROS
# ============================================================
function Cleanup-Temp {
    param($path)
    
    # Programar eliminación al cerrar PowerShell
    $script = {
        Start-Sleep -Seconds 10
        Remove-Item -Path $using:path -Recurse -Force -ErrorAction SilentlyContinue
    }
    Start-Job -ScriptBlock $script | Out-Null
}

# ============================================================
# 9. EJECUCIÓN PRINCIPAL
# ============================================================
Write-Host ""

# Buscar Python existente
$pythonExe = Get-PythonPath

if (-not $pythonExe) {
    # Instalar Python portable
    $pythonExe = Install-PythonPortable
}

if (-not $pythonExe) {
    Write-Host "[ERR] No se pudo instalar Python." -ForegroundColor Red
    Read-Host "Presioná ENTER para salir"
    exit 1
}

# Crear directorio temporal para OptiWin
$tempOptiWin = "$env:TEMP\OptiWin"
New-Item -ItemType Directory -Path $tempOptiWin -Force | Out-Null

# Descargar OptiWin (si es Python portable, descargar a su carpeta)
$scriptPath = "$tempOptiWin\OptiWin.py"

Write-Host "[INFO] Descargando OptiWin..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "$baseUrl/OptiWin.py" -OutFile $scriptPath

# Si existe requirements.txt, instalar dependencias
try {
    Invoke-WebRequest -Uri "$baseUrl/requirements.txt" -OutFile "$tempOptiWin\requirements.txt" -ErrorAction Stop
    Write-Host "[INFO] Instalando dependencias..." -ForegroundColor Cyan
    
    $pipPath = "$tempDir\python\Scripts\pip.exe"
    if (Test-Path $pipPath) {
        & $pipPath install -r "$tempOptiWin\requirements.txt" --quiet --no-warn-script-location 2>&1 | Out-Null
    } else {
        # Si no hay pip, instalar dependencias básicas
        $deps = @("customtkinter", "psutil", "pywin32")
        foreach ($dep in $deps) {
            & $pipPath install $dep --quiet --no-warn-script-location 2>&1 | Out-Null
        }
    }
} catch {
    # No hay requirements.txt, continuar
}

# Ejecutar OptiWin
Write-Host ""
Run-OptiWin -pythonExe $pythonExe -scriptPath $scriptPath

# Limpiar después de 30 segundos
Start-Job -ScriptBlock {
    Start-Sleep -Seconds 30
    Remove-Item -Path $using:tempDir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $using:tempOptiWin -Recurse -Force -ErrorAction SilentlyContinue
} | Out-Null

Write-Host ""
Write-Host "[OK] OptiWin instalado y ejecutándose." -ForegroundColor Green
Write-Host "[INFO] No se crearon archivos permanentes." -ForegroundColor Gray
Write-Host ""
Read-Host "Presioná ENTER para cerrar"
