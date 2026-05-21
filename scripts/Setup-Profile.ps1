<#
.SYNOPSIS
    Sets up the PowerShell profile to auto-load AppsTypeMarks functions.

.DESCRIPTION
    Adds an import line to your PowerShell profile so the AppsTypeMarks
    module is loaded automatically on each new PowerShell session.
#>

$scriptDir = $PSScriptRoot
$modulePath = Join-Path $scriptDir "AppsTypeMarks.ps1"
$importLine = ". `"$modulePath`""

if (-not (Test-Path $PROFILE)) {
    New-Item -Path $PROFILE -ItemType File -Force | Out-Null
    Write-Host "Created PowerShell profile: $PROFILE" -ForegroundColor Green
}

$profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue

if ($profileContent -and $profileContent.Contains($importLine)) {
    Write-Host "AppsTypeMarks is already configured in your profile." -ForegroundColor Yellow
}
else {
    Add-Content -Path $PROFILE -Value "`n# AppsTypeMarks module`n$importLine"
    Write-Host "Added AppsTypeMarks to PowerShell profile: $PROFILE" -ForegroundColor Green
    Write-Host "Restart PowerShell or run: . `"$modulePath`"" -ForegroundColor Cyan
}
