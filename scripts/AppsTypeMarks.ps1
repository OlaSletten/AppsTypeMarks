<#
.SYNOPSIS
    PowerShell module for managing AppsTypeMarks configurations.
.DESCRIPTION
    Provides functions to read, query, validate, and manage app directory
    mappings with support for both Android and Windows paths.
#>

function Get-AppTypeMarks {
    <#
    .SYNOPSIS
        Reads and returns app type marks from YAML configuration files.
    .PARAMETER PackageName
        Optional package name to filter results (e.g., 'com.tencent.mm').
    .PARAMETER Platform
        Filter by platform: 'android', 'windows', or 'all' (default).
    .PARAMETER Path
        Path to the directory containing YAML files. Defaults to repo root.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$PackageName,

        [ValidateSet('android', 'windows', 'all')]
        [string]$Platform = 'all',

        [string]$Path = (Split-Path -Parent $PSScriptRoot)
    )

    $ymlFiles = Get-ChildItem -Path $Path -Filter "*.yml" -File

    if ($PackageName) {
        $ymlFiles = $ymlFiles | Where-Object { $_.BaseName -eq $PackageName }
    }

    $results = @()
    foreach ($file in $ymlFiles) {
        $content = Get-Content -Path $file.FullName -Raw
        $entry = @{
            PackageName = $file.BaseName
            FilePath    = $file.FullName
            Raw         = $content
        }

        # Parse Android directories
        if ($Platform -in @('android', 'all')) {
            $androidDirs = @()
            $inMarks = $false
            $inDirs = $false
            foreach ($line in ($content -split "`n")) {
                if ($line -match '^\s*marks:') { $inMarks = $true; continue }
                if ($line -match '^\s*windows:') { $inMarks = $false; $inDirs = $false; continue }
                if ($inMarks -and $line -match '^\s*directories:') { $inDirs = $true; continue }
                if ($inMarks -and $line -match '^\s*- versionCode:') { $inDirs = $false; continue }
                if ($inDirs -and $line -match '^\s*-\s+(.+)$') {
                    $androidDirs += $Matches[1].Trim()
                }
            }
            $entry['AndroidDirectories'] = $androidDirs
        }

        # Parse Windows directories
        if ($Platform -in @('windows', 'all')) {
            $windowsDirs = @()
            $inWindows = $false
            $inDirs = $false
            foreach ($line in ($content -split "`n")) {
                if ($line -match '^\s*windows:') { $inWindows = $true; continue }
                if ($inWindows -and $line -match '^\s*directories:') { $inDirs = $true; continue }
                if ($inWindows -and $line -match '^\s*-\s+versionCode:') { $inDirs = $false; continue }
                if ($inDirs -and $line -match "^\s*-\s+'?(.+?)'?\s*$") {
                    $windowsDirs += $Matches[1].Trim("'")
                }
            }
            $entry['WindowsDirectories'] = $windowsDirs
        }

        $results += [PSCustomObject]$entry
    }

    return $results
}

function Test-AppTypeMarks {
    <#
    .SYNOPSIS
        Validates all YAML configuration files for correct structure.
    .PARAMETER Path
        Path to the directory containing YAML files. Defaults to repo root.
    .OUTPUTS
        Returns validation results with any errors found.
    #>
    [CmdletBinding()]
    param(
        [string]$Path = (Split-Path -Parent $PSScriptRoot)
    )

    $ymlFiles = Get-ChildItem -Path $Path -Filter "*.yml" -File
    $results = @()

    foreach ($file in $ymlFiles) {
        $content = Get-Content -Path $file.FullName -Raw
        $errors = @()

        # Check required 'type' field
        if ($content -notmatch '^\s*type:\s*\w+') {
            $errors += "Missing or invalid 'type' field"
        }

        # Check required 'marks' section
        if ($content -notmatch 'marks:') {
            $errors += "Missing 'marks' section"
        }

        # Check that marks have versionCode
        if ($content -match 'marks:' -and $content -notmatch 'versionCode:') {
            $errors += "Missing 'versionCode' in marks"
        }

        # Check that marks have directories
        if ($content -match 'marks:' -and $content -notmatch 'directories:') {
            $errors += "Missing 'directories' in marks"
        }

        # Validate Windows paths use environment variables
        if ($content -match 'windows:') {
            $winLines = ($content -split "`n") | Where-Object { $_ -match '^\s*-\s+.*\\' }
            foreach ($line in $winLines) {
                if ($line -match '^\s*-\s+' -and $line -match '\\' -and $line -notmatch '%\w+%') {
                    $errors += "Windows path should use environment variables (e.g., %USERPROFILE%): $($line.Trim())"
                }
            }
        }

        $results += [PSCustomObject]@{
            PackageName = $file.BaseName
            FilePath    = $file.FullName
            Valid       = ($errors.Count -eq 0)
            Errors      = $errors
        }
    }

    $validCount = ($results | Where-Object { $_.Valid }).Count
    $totalCount = $results.Count
    Write-Host "Validation complete: $validCount/$totalCount files valid" -ForegroundColor $(if ($validCount -eq $totalCount) { 'Green' } else { 'Yellow' })

    return $results
}

function New-AppTypeMark {
    <#
    .SYNOPSIS
        Creates a new app type mark YAML configuration file.
    .PARAMETER PackageName
        The Android package name (e.g., 'com.example.app').
    .PARAMETER Type
        The type category (e.g., 'Download', 'Cache').
    .PARAMETER AndroidDirectories
        Array of Android directory paths.
    .PARAMETER WindowsDirectories
        Optional array of Windows directory paths.
    .PARAMETER VersionCode
        The version code for the mark entry. Defaults to 1.
    .PARAMETER Path
        Path to the directory for the YAML file. Defaults to repo root.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PackageName,

        [Parameter(Mandatory)]
        [string]$Type,

        [Parameter(Mandatory)]
        [string[]]$AndroidDirectories,

        [string[]]$WindowsDirectories,

        [int]$VersionCode = 1,

        [string]$Path = (Split-Path -Parent $PSScriptRoot)
    )

    $filePath = Join-Path $Path "$PackageName.yml"

    if (Test-Path $filePath) {
        Write-Error "Configuration file already exists: $filePath"
        return
    }

    $yaml = "type: $Type`n"
    $yaml += "marks:`n"
    $yaml += "  - versionCode: $VersionCode`n"
    $yaml += "    directories:`n"
    foreach ($dir in $AndroidDirectories) {
        $yaml += "      - $dir`n"
    }

    if ($WindowsDirectories) {
        $yaml += "windows:`n"
        $yaml += "  - directories:`n"
        foreach ($dir in $WindowsDirectories) {
            $yaml += "      - '$dir'`n"
        }
    }

    Set-Content -Path $filePath -Value $yaml.TrimEnd() -NoNewline
    Write-Host "Created: $filePath" -ForegroundColor Green

    return $filePath
}

function Remove-AppTypeMark {
    <#
    .SYNOPSIS
        Removes an app type mark YAML configuration file.
    .PARAMETER PackageName
        The package name to remove.
    .PARAMETER Path
        Path to the directory containing YAML files. Defaults to repo root.
    .PARAMETER Force
        Skip confirmation prompt.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$PackageName,

        [string]$Path = (Split-Path -Parent $PSScriptRoot),

        [switch]$Force
    )

    $filePath = Join-Path $Path "$PackageName.yml"

    if (-not (Test-Path $filePath)) {
        Write-Error "Configuration file not found: $filePath"
        return
    }

    if (-not $Force) {
        $confirm = Read-Host "Remove $PackageName configuration? (y/N)"
        if ($confirm -ne 'y') {
            Write-Host "Cancelled." -ForegroundColor Yellow
            return
        }
    }

    Remove-Item -Path $filePath
    Write-Host "Removed: $filePath" -ForegroundColor Green
}

function Resolve-WindowsPaths {
    <#
    .SYNOPSIS
        Resolves Windows environment variable paths to actual paths on the current system.
    .PARAMETER PackageName
        Optional package name to filter.
    .PARAMETER Path
        Path to the directory containing YAML files. Defaults to repo root.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$PackageName,

        [string]$Path = (Split-Path -Parent $PSScriptRoot)
    )

    $apps = Get-AppTypeMarks -PackageName $PackageName -Platform 'windows' -Path $Path

    $results = @()
    foreach ($app in $apps) {
        if (-not $app.WindowsDirectories -or $app.WindowsDirectories.Count -eq 0) {
            continue
        }

        $resolved = @()
        foreach ($dir in $app.WindowsDirectories) {
            $expandedPath = [System.Environment]::ExpandEnvironmentVariables($dir -replace '%(\w+)%', '${env:$1}')
            # Fallback: manual expansion for common variables
            $expandedPath = $dir -replace '%USERPROFILE%', $env:USERPROFILE `
                                   -replace '%APPDATA%', $env:APPDATA `
                                   -replace '%LOCALAPPDATA%', $env:LOCALAPPDATA `
                                   -replace '%PROGRAMDATA%', $env:ProgramData

            $resolved += [PSCustomObject]@{
                Template = $dir
                Resolved = $expandedPath
                Exists   = (Test-Path $expandedPath)
            }
        }

        $results += [PSCustomObject]@{
            PackageName = $app.PackageName
            Paths       = $resolved
        }
    }

    return $results
}

Export-ModuleMember -Function Get-AppTypeMarks, Test-AppTypeMarks, New-AppTypeMark, Remove-AppTypeMark, Resolve-WindowsPaths
