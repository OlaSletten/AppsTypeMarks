<#
.SYNOPSIS
    PowerShell utility functions for managing AppsTypeMarks YAML configurations.

.DESCRIPTION
    Provides functions to list, validate, add, and remove app type mark
    YAML configuration files in this repository.
#>

function Get-AppTypeMarks {
    <#
    .SYNOPSIS
        Lists all app type mark YAML files and their configurations.
    .PARAMETER Path
        Root path of the AppsTypeMarks repository. Defaults to the script's parent directory.
    .PARAMETER Type
        Filter by mark type (e.g., Download, Common, AllFilesAccess).
    #>
    [CmdletBinding()]
    param(
        [string]$Path = (Split-Path $PSScriptRoot -Parent),
        [string]$Type
    )

    $ymlFiles = Get-ChildItem -Path $Path -Filter "*.yml" -File
    $results = @()

    foreach ($file in $ymlFiles) {
        $content = Get-Content $file.FullName -Raw
        $appId = $file.BaseName

        $markType = if ($content -match "^type:\s*(.+)$") { $Matches[1].Trim() } else { "Unknown" }

        $directories = @()
        $lines = $content -split "`n"
        foreach ($line in $lines) {
            if ($line -match "^\s+-\s+(/\S+.*)$") {
                $directories += $Matches[1].Trim()
            }
        }

        $obj = [PSCustomObject]@{
            AppId       = $appId
            Type        = $markType
            Directories = $directories
            File        = $file.Name
        }

        if (-not $Type -or $markType -eq $Type) {
            $results += $obj
        }
    }

    return $results
}

function Test-AppTypeMarks {
    <#
    .SYNOPSIS
        Validates all app type mark YAML files for common issues.
    .PARAMETER Path
        Root path of the AppsTypeMarks repository.
    #>
    [CmdletBinding()]
    param(
        [string]$Path = (Split-Path $PSScriptRoot -Parent)
    )

    $apps = Get-AppTypeMarks -Path $Path
    $issues = @()

    foreach ($app in $apps) {
        if ($app.Directories.Count -eq 0 -and $app.Type -notin @("Common", "AllFilesAccess")) {
            $issues += [PSCustomObject]@{
                AppId   = $app.AppId
                File    = $app.File
                Issue   = "No directories defined for type '$($app.Type)'"
            }
        }

        if ($app.Type -eq "Unknown") {
            $issues += [PSCustomObject]@{
                AppId   = $app.AppId
                File    = $app.File
                Issue   = "Missing or invalid type field"
            }
        }
    }

    if ($issues.Count -eq 0) {
        Write-Host "All app type marks are valid." -ForegroundColor Green
    }
    else {
        Write-Host "Found $($issues.Count) issue(s):" -ForegroundColor Yellow
        $issues | Format-Table -AutoSize
    }

    return $issues
}

function New-AppTypeMark {
    <#
    .SYNOPSIS
        Creates a new app type mark YAML configuration file.
    .PARAMETER AppId
        The Android application package ID (e.g., com.example.app).
    .PARAMETER Type
        The mark type: Download, Common, or AllFilesAccess.
    .PARAMETER Directories
        Array of directory paths for the app.
    .PARAMETER Path
        Root path of the AppsTypeMarks repository.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$AppId,

        [Parameter(Mandatory)]
        [ValidateSet("Download", "Common", "AllFilesAccess")]
        [string]$Type,

        [string[]]$Directories = @(),

        [string]$Path = (Split-Path $PSScriptRoot -Parent)
    )

    $filePath = Join-Path $Path "$AppId.yml"

    if (Test-Path $filePath) {
        Write-Error "File already exists: $filePath"
        return
    }

    $yaml = "type: $Type`n"
    $yaml += "marks:`n"
    $yaml += "  - versionCode: 1`n"
    $yaml += "    directories:`n"

    foreach ($dir in $Directories) {
        $yaml += "      - $dir`n"
    }

    Set-Content -Path $filePath -Value $yaml.TrimEnd() -NoNewline
    Write-Host "Created: $filePath" -ForegroundColor Green
}

function Remove-AppTypeMark {
    <#
    .SYNOPSIS
        Removes an app type mark YAML configuration file.
    .PARAMETER AppId
        The Android application package ID to remove.
    .PARAMETER Path
        Root path of the AppsTypeMarks repository.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$AppId,

        [string]$Path = (Split-Path $PSScriptRoot -Parent)
    )

    $filePath = Join-Path $Path "$AppId.yml"

    if (-not (Test-Path $filePath)) {
        Write-Error "File not found: $filePath"
        return
    }

    if ($PSCmdlet.ShouldProcess($filePath, "Remove")) {
        Remove-Item $filePath
        Write-Host "Removed: $filePath" -ForegroundColor Yellow
    }
}

Write-Host "AppsTypeMarks PowerShell module loaded." -ForegroundColor Cyan
Write-Host "Available commands: Get-AppTypeMarks, Test-AppTypeMarks, New-AppTypeMark, Remove-AppTypeMark" -ForegroundColor Cyan
