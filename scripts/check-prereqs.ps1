param()

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

function Get-VersionText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ExecutablePath,
        [string[]]$Arguments = @("--version")
    )

    try {
        return (& $ExecutablePath @Arguments 2>$null | Select-Object -First 1)
    }
    catch {
        return "installed, but version check failed"
    }
}

Write-Host "Checking prerequisites for Module 1 secure CI/CD project..."

$checks = @(
    @{
        Name = "git"
        Required = $true
        Hint = "Install Git for Windows: https://git-scm.com/download/win"
        Candidates = @("git")
        VersionArgs = @("--version")
    },
    @{
        Name = "python"
        Required = $true
        Hint = "Install Python 3.11+ and add it to PATH."
        Candidates = @(
            "python",
            "py",
            (Join-Path $env:LOCALAPPDATA "Programs\\Python\\Python313\\python.exe"),
            (Join-Path $env:LOCALAPPDATA "Programs\\Python\\Python312\\python.exe"),
            (Join-Path $env:LOCALAPPDATA "Programs\\Python\\Python311\\python.exe"),
            (Join-Path $env:LOCALAPPDATA "Programs\\Python\\Launcher\\py.exe")
        )
        VersionArgs = @("--version")
    },
    @{
        Name = "docker"
        Required = $false
        Hint = "Install Docker Desktop to build the container image locally."
        Candidates = @(
            "docker",
            (Join-Path $env:ProgramFiles "Docker\\Docker\\resources\\bin\\docker.exe")
        )
        VersionArgs = @("--version")
    }
)

$failed = $false

foreach ($check in $checks) {
    $resolvedPath = Resolve-CommandPath -Candidates $check.Candidates
    if ($resolvedPath) {
        $versionOutput = Get-VersionText -ExecutablePath $resolvedPath -Arguments $check.VersionArgs
        Write-Host "[OK] $($check.Name): $versionOutput"
    }
    else {
        $level = if ($check.Required) { "MISSING" } else { "OPTIONAL" }
        Write-Host "[$level] $($check.Name): $($check.Hint)"
        if ($check.Required) {
            $failed = $true
        }
    }
}

if ($failed) {
    Write-Host ""
    Write-Host "Required tools are missing. Install them first, then rerun this script."
    exit 1
}

Write-Host ""
Write-Host "Core prerequisites are available."
