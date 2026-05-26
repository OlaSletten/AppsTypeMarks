---
description: Validate all app type mark YAML files for common issues like missing directories, invalid types, or malformed YAML. Use when the user asks to check, validate, or lint the app configs.
---

## Validation Steps

1. Scan all `*.yml` files in the repository root
2. For each file, verify:
   - The `type` field exists and is one of: `Download`, `Common`, `AllFilesAccess`
   - The `marks` array exists and has at least one entry
   - Each mark has a `versionCode` (integer) and `directories` field
   - For `Download` type: at least one directory path must be specified
   - Directory paths start with `/storage/emulated/0/` or `/data/user/0/`
3. Report any files with issues
4. Suggest fixes for common problems

## Output Format

List each file with its status (valid/invalid) and any issues found. Summarize the total count at the end.
