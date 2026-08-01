<#
.SYNOPSIS
    Sets up Google Cloud SDK and Google Play Developer API access.

.DESCRIPTION
    Configures gcloud CLI authentication and sets up the environment
    for Google Play Developer API and Vertex AI / Gen AI SDK usage.

.PARAMETER ProjectId
    Google Cloud project ID. If not provided, uses the current gcloud config.

.PARAMETER Region
    Google Cloud region. Defaults to 'global'.

.PARAMETER ServiceAccountKeyFile
    Path to the Google Cloud service account JSON key file for Google Play API access.
#>

[CmdletBinding()]
param(
    [string]$ProjectId,
    [string]$Region = "global",
    [string]$ServiceAccountKeyFile
)

function Test-GCloudInstalled {
    try {
        $null = Get-Command gcloud -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

function Initialize-GCloud {
    if (-not (Test-GCloudInstalled)) {
        Write-Host "gcloud CLI is not installed." -ForegroundColor Red
        Write-Host "Install from: https://cloud.google.com/sdk/docs/install" -ForegroundColor Yellow
        return $false
    }

    Write-Host "gcloud CLI found." -ForegroundColor Green

    if ($ProjectId) {
        Write-Host "Setting project to: $ProjectId" -ForegroundColor Cyan
        gcloud config set project $ProjectId
    }
    else {
        $current = gcloud config get-value project 2>$null
        if ($current) {
            Write-Host "Using current project: $current" -ForegroundColor Cyan
        }
        else {
            Write-Host "No project set. Run: gcloud config set project YOUR_PROJECT_ID" -ForegroundColor Yellow
        }
    }

    if ($Region -ne "global") {
        gcloud config set compute/region $Region
    }

    return $true
}

function Enable-RequiredAPIs {
    Write-Host "Enabling required Google Cloud APIs..." -ForegroundColor Cyan

    $apis = @(
        "aiplatform.googleapis.com",
        "androidpublisher.googleapis.com",
        "generativelanguage.googleapis.com"
    )

    foreach ($api in $apis) {
        Write-Host "  Enabling $api..." -ForegroundColor Gray
        gcloud services enable $api 2>$null
    }

    Write-Host "APIs enabled." -ForegroundColor Green
}

function Set-ServiceAccount {
    if (-not $ServiceAccountKeyFile) {
        Write-Host "No service account key file provided." -ForegroundColor Yellow
        Write-Host "For Google Play API access, create a service account:" -ForegroundColor Yellow
        Write-Host "  1. Go to https://console.cloud.google.com/iam-admin/serviceaccounts" -ForegroundColor Gray
        Write-Host "  2. Create a service account with 'Android Management' role" -ForegroundColor Gray
        Write-Host "  3. Download the JSON key file" -ForegroundColor Gray
        Write-Host "  4. Link it in Google Play Console > Settings > API access" -ForegroundColor Gray
        Write-Host "  5. Re-run with: -ServiceAccountKeyFile path/to/key.json" -ForegroundColor Gray
        return
    }

    if (-not (Test-Path $ServiceAccountKeyFile)) {
        Write-Error "Service account key file not found: $ServiceAccountKeyFile"
        return
    }

    $env:GOOGLE_APPLICATION_CREDENTIALS = (Resolve-Path $ServiceAccountKeyFile).Path
    Write-Host "GOOGLE_APPLICATION_CREDENTIALS set to: $env:GOOGLE_APPLICATION_CREDENTIALS" -ForegroundColor Green

    gcloud auth activate-service-account --key-file=$ServiceAccountKeyFile
    Write-Host "Service account activated." -ForegroundColor Green
}

function Set-EnvironmentVariables {
    param([string]$Project, [string]$Reg)

    if ($Project) {
        $env:GOOGLE_CLOUD_PROJECT = $Project
        Write-Host "GOOGLE_CLOUD_PROJECT=$Project" -ForegroundColor Green
    }

    $env:GOOGLE_CLOUD_REGION = $Reg
    Write-Host "GOOGLE_CLOUD_REGION=$Reg" -ForegroundColor Green
}

# Main setup flow
Write-Host "`n=== Google Cloud & Google Play Setup ===" -ForegroundColor Cyan

if (Initialize-GCloud) {
    $proj = if ($ProjectId) { $ProjectId } else { gcloud config get-value project 2>$null }
    Set-EnvironmentVariables -Project $proj -Reg $Region
    Enable-RequiredAPIs
    Set-ServiceAccount
}

Write-Host "`n=== Setup Complete ===" -ForegroundColor Cyan
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  - Run the Gen AI SDK notebook: sdk/intro_genai_sdk.ipynb" -ForegroundColor Gray
Write-Host "  - Use MCP servers: gcloud, google-play (via Claude/Gemini/Codex)" -ForegroundColor Gray
