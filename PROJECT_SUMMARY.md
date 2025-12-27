# MacCleaner Project Summary

## Overview

MacCleaner is a comprehensive command-line tool for macOS that helps you:
- 🔍 Find large files and directories (like TreeSize)
- 🗂️ Organize files across multiple storage drives
- 🧹 Clean caches and temporary files
- 📝 Journal all operations for safety and resumability
- 📊 Track statistics and view logs

## Project Structure

```
MacCleaner/
├── Package.swift                           # Swift Package Manager configuration
├── README.md                               # Comprehensive documentation
├── QUICKSTART.md                           # Quick start guide
├── EXAMPLES.md                             # Real-world usage examples
├── install.sh                              # Build and install script
├── .gitignore                              # Git ignore rules
├── config.example.json                     # Example configuration file
├── com.user.maccleaner.weekly.plist       # LaunchAgent for automation
│
└── Sources/
    └── MacCleaner/
        ├── MacCleaner.swift                # Main CLI entry point & commands
        ├── Logger.swift                    # Logging system with JSON output
        ├── Journal.swift                   # Operation journaling & resume
        ├── FileScanner.swift               # Large file detection
        ├── StorageManager.swift            # Multi-drive storage management
        ├── CacheCleaner.swift              # Cache cleaning functionality
        ├── ResultsDisplay.swift            # Interactive file management UI
        ├── Configuration.swift             # User configuration management
        └── Utilities.swift                 # Helper functions & smart suggestions
```

## Key Features

### 1. File Scanning
- **Smart Detection**: Finds files above configurable size threshold
- **Tree Analysis**: Shows file sizes, ages, and directory structures
- **Exclusions**: Automatically skips system files
- **File Categorization**: Identifies media, development artifacts, disk images
- **Smart Suggestions**: Recommends actions based on file type and age

### 2. Storage Management
- **Multi-Drive Support**: 
  - Archive storage (HDD): `/Volumes/storage1/`
  - Fast storage (NVMe): `/Volumes/flash1/`
- **Auto-Organization**: Files archived with year/month structure
- **Duplicate Handling**: Automatic timestamp suffixes
- **Safety Checks**: Verifies volumes before operations

### 3. Cache Cleaning
- **User Caches**: Library/Caches, logs, crash reports
- **Browser Caches**: Safari, Chrome, Firefox
- **System Caches**: Requires sudo, skips critical files
- **Dry-Run Mode**: Preview before cleaning

### 4. Journaling & Safety
- **Operation Journal**: Every file operation logged
- **Resumability**: Continue interrupted operations
- **Status Tracking**: Pending, in-progress, completed, failed
- **Rollback Info**: JSON journal with full operation details

### 5. Logging
- **Console Output**: Color-coded emoji indicators
- **JSON Log Files**: Machine-readable logs in Application Support
- **Timestamps**: All operations timestamped
- **Context Data**: Additional metadata for troubleshooting

### 6. Interactive Mode
- **File-by-File Review**: Decide what to do with each large file
- **Smart Suggestions**: Context-aware recommendations
- **Safety Confirmations**: Delete operations require explicit "yes"
- **Progress Tracking**: Shows position in file list

## Commands

### `maccleaner scan`
Find large files on your Mac
- `--threshold` - Minimum file size in MB (default: 100)
- `--path` - Directory to scan (default: home directory)
- `--include-system` - Include system files

### `maccleaner clean`
Clean caches and temporary files
- `--user-caches` - Clean user caches
- `--system-caches` - Clean system caches (requires sudo)
- `--all` - Clean all caches
- `--dry-run` - Preview without cleaning

### `maccleaner status`
Show storage volume information
- Displays total, used, and free space
- Shows percentage used
- Checks if volumes are mounted

### `maccleaner stats`
View operation statistics and logs
- `--limit` - Number of log entries to show

### `maccleaner resume`
Resume interrupted operations
- Checks journal for incomplete operations
- Continues from last checkpoint

### `maccleaner config`
Manage configuration
- `--show` - Display current configuration
- `--reset` - Reset to defaults
- `--storage-path` - Set archive drive path
- `--fast-storage-path` - Set NVMe drive path
- `--threshold` - Set default threshold

## Technical Details

### Language & Frameworks
- **Swift 6.0** with strict concurrency
- **Swift Argument Parser** for CLI
- **Actors** for thread-safe operations
- **Async/Await** throughout

### Storage Locations
- **Logs**: `~/Library/Application Support/MacCleaner/logs/`
- **Journal**: `~/Library/Application Support/MacCleaner/journal/`
- **Config**: `~/Library/Application Support/MacCleaner/config.json`

### File Format Examples

**Log Entry (JSON)**:
```json
{
  "timestamp": "2024-12-27T10:30:45Z",
  "level": "INFO",
  "message": "Starting scan of /Users/username",
  "context": {"path": "/Users/username", "threshold": "100"}
}
```

**Journal Session (JSON)**:
```json
{
  "id": "A1B2C3D4-...",
  "startDate": "2024-12-27T10:30:00Z",
  "operations": [
    {
      "id": "E5F6G7H8-...",
      "sourcePath": "/path/to/file.mov",
      "destinationPath": "/Volumes/storage1/Archive/2024/12/file.mov",
      "operationType": "archive",
      "fileSize": 5368709120,
      "status": "completed",
      "timestamp": "2024-12-27T10:30:15Z"
    }
  ],
  "isComplete": true
}
```

## Smart Features

### 1. File Type Recognition
The tool recognizes and provides specific icons for:
- 🎥 Videos (mp4, mov, avi, mkv)
- 🎵 Audio (mp3, wav, m4a, flac)
- 🖼️ Images (jpg, png, gif, heic)
- 💿 Disk Images (dmg, iso, img)
- 📦 Archives (zip, tar, gz)
- And more...

### 2. Smart Suggestions
Based on file analysis:
- **Old files** (>1 year): "Archive to storage"
- **Development artifacts**: "Consider deleting"
- **Media files**: "Archive to storage"
- **Very large files** (>5GB): Highlighted

### 3. Automatic Organization
Files moved to archive storage are organized:
```
/Volumes/storage1/
  └── Archive/
      └── 2024/
          └── 12/
              ├── large-video.mp4
              ├── old-project.zip
              └── disk-image.dmg
```

## Safety Features

1. ✅ All operations journaled before execution
2. ✅ Dry-run mode for cache cleaning
3. ✅ Delete confirmations require typing "yes"
4. ✅ System-critical caches automatically excluded
5. ✅ Duplicate file handling
6. ✅ Resume capability for interrupted operations
7. ✅ Volume availability checks
8. ✅ Detailed logging for audit trail

## Installation

```bash
# Clone or download the project
cd MacCleaner

# Build and install
chmod +x install.sh
./install.sh

# Verify
maccleaner --version
```

## Quick Start

```bash
# Configure your drives
maccleaner config --storage-path "/Volumes/storage1/" --fast-storage-path "/Volumes/flash1/"

# Check status
maccleaner status

# Find large files
maccleaner scan --threshold 500

# Clean caches
maccleaner clean --user-caches

# View stats
maccleaner stats
```

## Automation

### LaunchAgent Setup
```bash
cp com.user.maccleaner.weekly.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.user.maccleaner.weekly.plist
```

Runs every Sunday at 10 AM, scans for files >500MB

### Custom Automation
Create your own scripts using the CLI commands and schedule with cron or LaunchAgents.

## Customization

### Configuration File
Edit `~/Library/Application Support/MacCleaner/config.json`:

```json
{
  "storagePath": "/Volumes/storage1/",
  "fastStoragePath": "/Volumes/flash1/",
  "defaultThreshold": 100,
  "excludePaths": ["/System", "/Library/System", "/usr"],
  "autoArchiveOldFiles": false,
  "archiveOlderThanDays": 365
}
```

### Source Code
Modify source files for custom behavior:
- `StorageManager.swift` - Change storage logic
- `FileScanner.swift` - Modify scan behavior
- `CacheCleaner.swift` - Add/remove cache paths
- `Utilities.swift` - Add file type recognition

## Use Cases

1. **Weekly Maintenance**: Automated scans and cache cleaning
2. **Project Cleanup**: Find and remove build artifacts
3. **Media Organization**: Archive old videos and photos
4. **Space Recovery**: Emergency disk space cleanup
5. **Storage Migration**: Move files between drives systematically
6. **Development**: Clean node_modules, DerivedData, etc.

## Requirements

- macOS 14.0 (Sonoma) or later
- Swift 6.0 or later
- External drives for archive/fast storage (optional but recommended)

## Performance

- **Fast Scanning**: Uses `FileManager.enumerator` with optimizations
- **Async Operations**: Non-blocking file operations
- **Memory Efficient**: Streams results, doesn't load all at once
- **Safe Concurrency**: Actor-based thread safety

## Future Enhancements

Potential additions:
- [ ] Duplicate file detection
- [ ] File compression before archiving
- [ ] Email reports
- [ ] Web UI for remote management
- [ ] Smart scheduling based on disk usage
- [ ] Cloud storage integration
- [ ] Machine learning for file recommendations

## Troubleshooting

See README.md for detailed troubleshooting guide.

Common issues:
- Volume not found → Check `/Volumes/` directory
- Permission denied → Use sudo for system operations
- Operation interrupted → Run `maccleaner resume`

## License

MIT License - Free to use and modify

## Support

For issues, questions, or contributions:
- Check EXAMPLES.md for usage patterns
- Review logs in `~/Library/Application Support/MacCleaner/logs/`
- Use `maccleaner --help` for command reference

---

**Built with ❤️ for Mac power users who want control over their storage**
