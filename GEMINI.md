# AppsTypeMarks

This repository manages Android app-to-directory mappings via YAML configuration files, plus a Google Gen AI SDK notebook.

## Project Structure

- `*.yml` — App type mark files named by Android package ID (e.g., `com.tencent.mm.yml`)
- `sdk/` — Jupyter notebook for Google Generative AI SDK
- `scripts/` — PowerShell utilities for managing app configs

## YAML Format

Each `.yml` file follows this structure:

```yaml
type: Download | Common | AllFilesAccess
marks:
  - versionCode: 1
    directories:
      - /storage/emulated/0/path/to/dir
```

- `type`: One of `Download`, `Common`, or `AllFilesAccess`
- `marks`: Version-gated directory lists
- `versionCode`: Integer matching an app build version
- `directories`: Absolute Android filesystem paths

## Conventions

- File names must match the Android package ID exactly
- Every `Download` type entry must have at least one directory path
- `Common` and `AllFilesAccess` types may have empty directory lists
- Paths use `/storage/emulated/0/` as the base for shared storage

## Skills

### Validate Apps
Scan all `*.yml` files and check for:
- Valid `type` field (`Download`, `Common`, `AllFilesAccess`)
- Non-empty `marks` array with `versionCode` and `directories`
- At least one directory for `Download` type entries
- Valid directory path prefixes

### Manage Apps
- **Add**: Create `{package_id}.yml` with type and directory paths
- **Update**: Modify directories or add version entries
- **Remove**: Delete the `.yml` file for a package

## Google Cloud & Google Play

MCP servers available for Google Cloud and Google Play integration:

- **gcloud** (`@google-cloud/gcloud-mcp`) — Google Cloud CLI via natural language
- **google-play** (`google-play-developer-mcp`) — Android Publisher API (app listings, releases, reviews, subscriptions)

### Prerequisites

- `gcloud` CLI installed and authenticated
- Google Cloud project with Vertex AI API enabled
- For Google Play: `GOOGLE_APPLICATION_CREDENTIALS` pointing to a service account JSON key

### Setup

Run `scripts/Setup-GCloud.ps1` to configure gcloud, enable APIs, and set up credentials.
