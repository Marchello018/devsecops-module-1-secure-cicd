param(
    [Parameter(Mandatory = $true)]
    [string]$GitUserName,

    [Parameter(Mandatory = $true)]
    [string]$GitUserEmail,

    [Parameter(Mandatory = $true)]
    [string]$RemoteUrl,

    [string]$CommitMessage = "Add secure CI/CD lesson project"
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot

Push-Location $projectRoot

try {
    git config user.name $GitUserName
    git config user.email $GitUserEmail

    $remoteExists = git remote
    if ($remoteExists -contains "origin") {
        git remote set-url origin $RemoteUrl
    }
    else {
        git remote add origin $RemoteUrl
    }

    git add .
    git commit -m $CommitMessage
    git push -u origin main
}
finally {
    Pop-Location
}

