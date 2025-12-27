# MacCleaner - Quick Start Guide

## Installation

1. **Build and install:**
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

2. **Verify installation:**
   ```bash
   maccleaner --version
   ```

## First Run

### 1. Check Your Storage Status
```bash
maccleaner status
```

This shows you how much space is available on your storage drives.

### 2. Scan for Large Files
```bash
maccleaner scan --threshold 100
```

This will find all files larger than 100 MB and let you decide what to do with them.

### 3. Interactive File Management

When scanning completes, you'll be asked what to do with each file:

- **[s]** - Move to Storage (`/Volumes/storage1/`)
- **[f]** - Move to Fast Storage (`/Volumes/flash1/`)
- **[d]** - Delete the file
- **[k]** - Keep and skip
- **[q]** - Quit interactive mode

### 4. Clean Caches

Preview what will be cleaned:
```bash
maccleaner clean --all --dry-run
```

Actually clean user caches:
```bash
maccleaner clean --user-caches
```

## Common Workflows

### Weekly Cleanup Routine
```bash
# Check what you have
maccleaner status

# Find large files (500MB+)
maccleaner scan --threshold 500

# Clean caches
maccleaner clean --user-caches

# Check results
maccleaner stats
```

### Find Huge Files in Downloads
```bash
maccleaner scan --path ~/Downloads --threshold 100
```

### Archive Old Files
```bash
# Scan with high threshold for truly massive files
maccleaner scan --threshold 1000

# In interactive mode, choose [s] to archive them
```

## Tips

1. **Start with high threshold**: Try `--threshold 500` first to find the biggest space hogs
2. **Use dry-run**: Always use `--dry-run` flag when cleaning caches first
3. **Check stats**: Run `maccleaner stats` to see what you've cleaned
4. **Resume if interrupted**: If something goes wrong, run `maccleaner resume`

## Customization

Edit storage paths in `Sources/MacCleaner/StorageManager.swift`:

```swift
let storagePath = "/Volumes/storage1/"       // Your archive drive
let fastStoragePath = "/Volumes/flash1/"     // Your NVMe drive
```

## Automation

To run scans automatically every week, install the LaunchAgent:

```bash
cp com.user.maccleaner.weekly.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.user.maccleaner.weekly.plist
```

## Where Are My Logs?

- **Logs**: `~/Library/Application Support/MacCleaner/logs/`
- **Journal**: `~/Library/Application Support/MacCleaner/journal/`

View recent logs:
```bash
maccleaner stats --limit 20
```

## Troubleshooting

**Volume not found?**
- Make sure your external drives are mounted
- Check with `ls /Volumes/`
- Update paths in `StorageManager.swift`

**Permission denied?**
- Use `sudo` for system caches
- Check file permissions
- Some system files can't be touched

**Operation stuck?**
- Press Ctrl+C to cancel
- Run `maccleaner resume` to continue

## Safety First

- All operations are journaled
- Deletions require confirmation
- Use dry-run mode first
- Keep backups!
