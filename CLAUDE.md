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
- Use `/data/user/0/` or `/Android/data/` for app-private paths

## Google Cloud & Google Play

This project integrates with Google Cloud and Google Play via MCP servers:

- **gcloud MCP** (`@google-cloud/gcloud-mcp`) — Interact with Google Cloud resources, manage projects, deploy services
- **Google Play MCP** (`google-play-developer-mcp`) — Query app listings, manage releases, read reviews, handle subscriptions

### Prerequisites

- `gcloud` CLI installed and authenticated (`gcloud auth login`)
- Google Cloud project with Vertex AI API enabled
- For Google Play: service account key with Android Publisher API access (`GOOGLE_APPLICATION_CREDENTIALS`)

### Setup

Run `scripts/Setup-GCloud.ps1` to configure gcloud CLI, enable APIs, and set up service account credentials.

## Validation

Run `Test-AppTypeMarks` via the PowerShell module in `scripts/AppsTypeMarks.ps1` to check for broken entries.
