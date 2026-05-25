---
name: testing-configs
description: Validate all agent configuration files (Claude, Gemini, Codex) and PowerShell scripts for correct structure, MCP server entries, and cross-agent consistency. Use when verifying config changes or after adding new MCP servers.
---

## Overview

This skill validates the structural correctness of all agent configuration files and scripts in the AppsTypeMarks repo. All testing is shell-based via Python — no GUI or recording needed.

## What to Validate

### Agent Config Files
- `.claude/settings.json` — JSON format, `mcpServers` entries, `permissions.allow` list
- `.gemini/settings.json` — JSON format, `mcpServers` entries, `context.fileName` list
- `.codex/config.toml` — TOML format, `mcp_servers` sections

### Expected MCP Servers (as of latest)
- `filesystem` — `@modelcontextprotocol/server-filesystem`
- `context7` — `@upstash/context7-mcp`
- `gcloud` — `@google-cloud/gcloud-mcp`
- `google-play` — `google-play-developer-mcp` (requires `GOOGLE_APPLICATION_CREDENTIALS` in env)

### Cross-Agent Consistency
- All three agents should have identical MCP server package names
- All three agents should have `GOOGLE_APPLICATION_CREDENTIALS` in the google-play env config

### PowerShell Scripts
- `scripts/AppsTypeMarks.ps1` — functions: `Get-AppTypeMarks`, `Test-AppTypeMarks`, `New-AppTypeMark`, `Remove-AppTypeMark`
- `scripts/Setup-GCloud.ps1` — functions: `Test-GCloudInstalled`, `Initialize-GCloud`, `Enable-RequiredAPIs`, `Set-ServiceAccount`, `Set-EnvironmentVariables`
- `scripts/Setup-Profile.ps1` — profile loader
- Note: `pwsh` might not be installed in the test environment. Validate structurally (string matching for function definitions, param blocks, etc.)

### Context Docs
- `CLAUDE.md`, `GEMINI.md`, `AGENTS.md` should all contain sections for Google Cloud & Google Play with correct package references

### YAML App Configs (Regression)
- All `*.yml` files in root should parse with valid `type`, `marks`, `versionCode`, `directories`

## How to Test

Use Python with `json`, `tomllib`, `yaml` modules to parse configs and validate structure. Use string matching for PowerShell script validation. Example:

```python
import json, tomllib, yaml
with open('.claude/settings.json') as f:
    claude = json.load(f)
assert 'gcloud' in claude['mcpServers']
```

## Limitations

- PowerShell scripts: structural validation only (pwsh may not be available)
- MCP server connectivity: not testable without npx + npm registry access
- Google Play API: requires `GOOGLE_APPLICATION_CREDENTIALS` service account key
- gcloud CLI: requires gcloud SDK installed and authenticated

## Devin Secrets Needed

- `GOOGLE_APPLICATION_CREDENTIALS` — Google Cloud service account JSON key file path (for Google Play API runtime testing)
- `GOOGLE_API_KEY` — Google AI API key (for Gen AI SDK notebook testing)
