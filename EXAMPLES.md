# MacCleaner Usage Examples

This file contains practical examples for using MacCleaner in real-world scenarios.

## Scenario 1: First Time Setup

```bash
# Build and install
chmod +x install.sh
./install.sh

# Configure your storage paths
maccleaner config --storage-path "/Volumes/MyBackup/" --fast-storage-path "/Volumes/MySSD/"

# Verify configuration
maccleaner config --show

# Check storage status
maccleaner status
```

## Scenario 2: Finding and Archiving Large Old Files

```bash
# Find files larger than 1GB
maccleaner scan --threshold 1000 --path ~

# In interactive mode:
# - Press 's' to move old files to archive storage
# - Press 'f' to move frequently-used files to fast storage
# - Press 'k' to skip files you want to keep
```

## Scenario 3: Cleaning Up Downloads Folder

```bash
# Scan Downloads for files over 100MB
maccleaner scan --path ~/Downloads --threshold 100

# Interactive mode will show each file with:
# - File size
# - Last modified date
# - Smart suggestions (e.g., "Old file (>1 year) • Archive to storage")
```

## Scenario 4: Weekly Maintenance Routine

```bash
#!/bin/bash
# weekly-cleanup.sh

echo "Starting weekly Mac cleanup..."

# Check current storage
maccleaner status

# Find large files
maccleaner scan --threshold 500

# Clean user caches
maccleaner clean --user-caches

# Show what was done
maccleaner stats

echo "Cleanup complete!"
```

Make it executable and add to your schedule:
```bash
chmod +x weekly-cleanup.sh

# Add to crontab for Sunday at 10 AM
# crontab -e
# 0 10 * * 0 /path/to/weekly-cleanup.sh
```

## Scenario 5: Emergency Disk Space Recovery

```bash
# Find HUGE files (5GB+)
maccleaner scan --threshold 5000

# Clean all caches (preview first)
maccleaner clean --all --dry-run

# If safe, actually clean
maccleaner clean --user-caches

# Check if we recovered space
maccleaner status
```

## Scenario 6: Development Project Cleanup

```bash
# Scan your code directory for large build artifacts
maccleaner scan --path ~/Projects --threshold 500

# Look for:
# - node_modules directories
# - DerivedData
# - build folders
# 
# These will be marked with smart suggestions
# Choose 'd' to delete build artifacts safely
```

## Scenario 7: Media File Organization

```bash
# Find large media files
maccleaner scan --path ~/Movies --threshold 1000

# Smart suggestions will identify:
# 🎥 Video files - "Archive to storage"
# 🎵 Audio files - "Archive to storage"
# 📦 Disk images - "Archive to storage or delete"

# Move to archive storage with automatic organization
# Files go to /Volumes/storage1/Archive/2024/12/filename
```

## Scenario 8: Recovering from Interrupted Operation

```bash
# If MacCleaner was interrupted (power loss, etc.)
maccleaner resume

# This will:
# - Check journal for incomplete operations
# - Resume from where it left off
# - Complete any pending file moves
```

## Scenario 9: Safe Cache Cleaning

```bash
# Preview what will be cleaned
maccleaner clean --all --dry-run

# Review the output, then clean user caches only
maccleaner clean --user-caches

# For system caches, use sudo
sudo maccleaner clean --system-caches
```

## Scenario 10: Monitoring and Statistics

```bash
# View recent activity
maccleaner stats

# View more detailed logs
maccleaner stats --limit 50

# Check what's been processed
cat ~/Library/Application\ Support/MacCleaner/logs/*.log
```

## Scenario 11: Custom Configuration

Edit your config file:
```bash
# Open config in editor
open ~/Library/Application\ Support/MacCleaner/config.json
```

Example customization:
```json
{
  "storagePath": "/Volumes/MyArchive/",
  "fastStoragePath": "/Volumes/MySSD/",
  "defaultThreshold": 250,
  "autoArchiveOldFiles": true,
  "archiveOlderThanDays": 180,
  "excludePaths": [
    "/System",
    "/Library",
    "/usr",
    "/Applications",
    "~/Library/Photos"
  ]
}
```

Then verify:
```bash
maccleaner config --show
```

## Scenario 12: Automated Scanning with LaunchAgent

Install the LaunchAgent for weekly automatic scans:

```bash
# Copy the plist file
cp com.user.maccleaner.weekly.plist ~/Library/LaunchAgents/

# Load it
launchctl load ~/Library/LaunchAgents/com.user.maccleaner.weekly.plist

# Check if it's loaded
launchctl list | grep maccleaner

# View logs after it runs
cat /tmp/maccleaner-weekly.log
```

## Scenario 13: Batch Processing Multiple Directories

```bash
#!/bin/bash
# scan-multiple.sh

DIRS=(
    "$HOME/Downloads"
    "$HOME/Documents"
    "$HOME/Desktop"
    "$HOME/Movies"
)

for dir in "${DIRS[@]}"; do
    echo "Scanning $dir..."
    maccleaner scan --path "$dir" --threshold 500
done
```

## Scenario 14: Pre-Vacation Cleanup

```bash
# Before going on vacation, free up space

# 1. Find and archive everything over 2GB
maccleaner scan --threshold 2000

# 2. Clean all caches
maccleaner clean --all

# 3. Check final status
maccleaner status

# 4. View summary
maccleaner stats
```

## Scenario 15: Selective Cache Cleaning

```bash
# Clean only user caches, not system caches
maccleaner clean --user-caches

# If you want to clean browser caches specifically,
# the tool identifies them in:
# - ~/Library/Caches/com.apple.Safari
# - ~/Library/Application Support/Google/Chrome/Default/Cache
# - ~/Library/Application Support/Firefox/Profiles
```

## Tips and Best Practices

1. **Always check with dry-run first**
   ```bash
   maccleaner clean --all --dry-run
   ```

2. **Regular small cleanups are better than rare large ones**
   ```bash
   # Weekly: scan with 500MB threshold
   # Monthly: scan with 100MB threshold
   ```

3. **Keep your external drives mounted**
   ```bash
   # Check volumes
   ls /Volumes/
   ```

4. **Review logs regularly**
   ```bash
   maccleaner stats --limit 20
   ```

5. **Backup before major cleanups**
   ```bash
   # Use Time Machine or your backup solution first
   ```

6. **Customize thresholds based on your storage**
   ```bash
   # Small SSD: use lower threshold (100-250MB)
   # Large HDD: use higher threshold (500-1000MB)
   ```

## Common File Types and Recommendations

| File Type | Size Range | Recommendation |
|-----------|------------|----------------|
| Videos (.mp4, .mov) | >500MB | Archive to storage |
| Disk Images (.dmg, .iso) | >500MB | Archive or delete |
| Development builds | >200MB | Delete |
| Old documents | >100MB | Archive to storage |
| Frequently used media | Any | Move to fast storage |
| Cache files | Any | Delete via clean command |

## Exit Codes

- `0` - Success
- `1` - General error
- `2` - Configuration error
- `3` - Permission denied
- `4` - Volume not found

## Environment Variables

You can set these for temporary overrides:

```bash
# Override storage path for one run
STORAGE_PATH=/Volumes/backup2/ maccleaner scan
```

## Getting Help

```bash
# General help
maccleaner --help

# Help for specific command
maccleaner scan --help
maccleaner clean --help
maccleaner config --help
```
