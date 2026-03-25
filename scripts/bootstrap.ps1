param(
    [switch]$SkipDockerBuild
)

$ErrorActionPreference = "Stop"

function Resolve-CommandPath {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Candidates
    )

    foreach ($candidate in $Candidates) {
        $command = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($command) {
            return $command.Source
        }

        if (Test-Path $candidate) {
            return $candidate
        }
    }

    return $null
}

function Invoke-External {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Executable,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Description failed with exit code $LASTEXITCODE."
    }
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$venvPath = Join-Path $projectRoot ".venv"
$pythonExe = Resolve-CommandPath -Candidates @(
    "python",
    "py",
    (Join-Path $env:LOCALAPPDATA "Programs\\Python\\Python313\\python.exe"),
    (Join-Path $env:LOCALAPPDATA "Programs\\Python\\Python312\\python.exe"),
    (Join-Path $env:LOCALAPPDATA "Programs\\Python\\Python311\\python.exe"),
    (Join-Path $env:LOCALAPPDATA "Programs\\Python\\Launcher\\py.exe")
)

if (-not $pythonExe) {
    Write-Error "Python is not available in PATH. Install Python 3.11+ before running bootstrap."
}

Push-Location $projectRoot

try {
    if (-not (Test-Path $venvPath)) {
        Write-Host "Creating virtual environment..."
        Invoke-External -Executable $pythonExe -Arguments @("-m", "venv", $venvPath) -Description "Virtual environment creation"
    }

    $venvPython = Join-Path $venvPath "Scripts\\python.exe"
    if (-not (Test-Path $venvPython)) {
        Write-Error "Virtual environment was not created correctly."
    }

    Write-Host "Installing dependencies..."
    Invoke-External -Executable $venvPython -Arguments @("-m", "pip", "install", "--upgrade", "pip") -Description "Pip upgrade"
    Invoke-External -Executable $venvPython -Arguments @("-m", "pip", "install", "-r", "requirements-dev.txt") -Description "Dependency installation"

    Write-Host "Running tests..."
    Invoke-External -Executable $venvPython -Arguments @("-m", "pytest", "app/test_main.py", "-q") -Description "Pytest"

    Write-Host "Running Bandit..."
    Invoke-External -Executable $venvPython -Arguments @("-m", "bandit", "-r", "app", "-x", "app/test_main.py", "-q") -Description "Bandit"

    Write-Host "Running dependency audit..."
    Invoke-External -Executable $venvPython -Arguments @("-m", "pip_audit", "-r", "app/requirements.txt") -Description "Dependency audit"

    if (-not $SkipDockerBuild) {
        $dockerExe = Resolve-CommandPath -Candidates @(
            "docker",
            (Join-Path $env:ProgramFiles "Docker\\Docker\\resources\\bin\\docker.exe")
        )
        if ($dockerExe) {
            Write-Host "Building Docker image..."
            Invoke-External -Executable $dockerExe -Arguments @("build", "--tag", "secure-fastapi:local", ".") -Description "Docker build"
        }
        else {
            Write-Host "Docker is not available in PATH. Skipping Docker build."
        }
    }

    Write-Host ""
    Write-Host "Bootstrap complete."
}
finally {
    Pop-Location
}
