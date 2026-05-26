---
description: Add, update, or remove app type mark YAML configurations. Use when the user wants to create a new app entry, modify directories, or remove an app config.
---

## Adding a New App

1. Ask for the Android package ID (e.g., `com.example.app`)
2. Ask for the type: `Download`, `Common`, or `AllFilesAccess`
3. Ask for directory paths (for `Download` type)
4. Create `{package_id}.yml` in the repository root with the standard format:

```yaml
type: Download
marks:
  - versionCode: 1
    directories:
      - /storage/emulated/0/path/to/dir
```

## Updating an App

1. Read the existing YAML file
2. Add new version entries or modify directory paths
3. Preserve existing entries when adding new version codes

## Removing an App

1. Confirm the package ID with the user
2. Delete the corresponding `.yml` file
3. Commit the change with a descriptive message
