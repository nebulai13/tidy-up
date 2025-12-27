# MacCleaner

A comprehensive command-line tool for cleaning up your Mac, finding large files, and managing storage across multiple drives.

## Features

✨ **File Scanning**
- Find large files and directories above a configurable threshold
- Display file sizes, last modification dates, and file types
- Smart exclusion of system directories
- Tree-like size analysis

🗂️ **Storage Management**
- Move files to archive storage (`/Volumes/storage1/`)
- Move files to fast NVMe storage (`/Volumes/flash1/`)
- Automatic organization by date (year/month structure)
- Handle duplicate filenames automatically

🧹 **Cache Cleaning**
- Clean user caches (Library/Caches, logs, crash reports)
- Clean browser caches (Safari, Chrome, Firefox)
- Clean system caches (requires sudo)
- Dry-run mode to preview what will be cleaned

📝 **Journaling & Logging**
- All operations are logged to JSON files
- Resume interrupted operations
- View operation history and statistics
- Detailed timestamp and context tracking

🎯 **Interactive Mode**
- Review each large file individually
- Choose destination: storage, fast storage, delete, or keep
- Safety confirmations for destructive operations

## Installation

### Build from source

```bash
# Clone or create the project
cd MacCleaner

# Build the project
swift build -c release

# Copy to a location in your PATH
cp .build/release/maccleaner /usr/local/bin/

# Or create an alias in your shell config
alias maccleaner="swift run maccleaner"
```

## Usage

### Scan for Large Files

Find all files larger than 100 MB (default):

```bash
maccleaner scan
```

Find files larger than 500 MB:

```bash
maccleaner scan --threshold 500
```

Scan a specific directory:

```bash
maccleaner scan --path ~/Downloads
```

Include system files (requires elevated permissions):

```bash
sudo maccleaner scan --include-system
```

### Clean Caches

Preview what would be cleaned (dry run):

```bash
maccleaner clean --all --dry-run
```

Clean user caches:

```bash
maccleaner clean --user-caches
```

Clean system caches (requires sudo):

```bash
sudo maccleaner clean --system-caches
```

Clean all caches:

```bash
sudo maccleaner clean --all
```

### Check Storage Status

View available space on your configured volumes:

```bash
maccleaner status
```

Output:
```
📊 Storage Status

💾 Storage Drive (HDD)
   Path: /Volumes/storage1/
   Total: 4 TB
   Used:  2.1 TB (52.5%)
   Free:  1.9 TB

💾 Fast Storage (NVMe)
   Path: /Volumes/flash1/
   Total: 2 TB
   Used:  800 GB (40.0%)
   Free:  1.2 TB
```

### Resume Interrupted Operations

If an operation is interrupted, you can resume it:

```bash
maccleaner resume
```

## Configuration

The tool uses these default paths:
- **Storage Drive**: `/Volumes/storage1/`
- **Fast Storage**: `/Volumes/flash1/`

To change these, edit `Sources/MacCleaner/StorageManager.swift`:

```swift
let storagePath = "/Volumes/storage1/"  // Your HDD path
let fastStoragePath = "/Volumes/flash1/"  // Your NVMe path
```

## Logs and Journals

All logs and journals are stored in:
- **Logs**: `~/Library/Application Support/MacCleaner/logs/`
- **Journal**: `~/Library/Application Support/MacCleaner/journal/`

### Log Format

Logs are stored as JSON lines for easy parsing:

```json
{"timestamp":"2024-12-27T10:30:45Z","level":"INFO","message":"Starting scan of /Users/username"}
{"timestamp":"2024-12-27T10:31:12Z","level":"SUCCESS","message":"Scan complete. Found 45 large files"}
```

### Journal Format

The journal tracks all file operations for resumability:

```json
{
  "id": "A1B2C3D4-...",
  "startDate": "2024-12-27T10:30:00Z",
  "operations": [
    {
      "id": "E5F6G7H8-...",
      "sourcePath": "/Users/username/large-file.dmg",
      "destinationPath": "/Volumes/storage1/Archive/2024/12/large-file.dmg",
      "operationType": "archive",
      "fileSize": 5368709120,
      "status": "completed",
      "timestamp": "2024-12-27T10:30:15Z"
    }
  ],
  "isComplete": false
}
```

## Interactive Mode

When you run a scan, you'll enter interactive mode where you can process each file:

```
File 1 of 45
📄 /Users/username/Downloads/large-video.mp4
Size: 5.2 GB
Last modified: Nov 15, 2024 at 3:45 PM

Options:
  [s] Move to Storage (/Volumes/storage1/)
  [f] Move to Fast Storage (/Volumes/flash1/)
  [d] Delete
  [k] Keep (skip)
  [q] Quit

Choose action: s
✅ Moved to: /Volumes/storage1/Archive/2024/12/large-video.mp4
```

## Safety Features

1. **Journaling**: All operations are journaled before execution
2. **Dry Run**: Preview cache cleaning operations
3. **Confirmation**: Delete operations require explicit "yes" confirmation
4. **Exclusions**: System-critical caches are automatically excluded
5. **Duplicate Handling**: Files are renamed if destination exists
6. **Resume**: Interrupted operations can be resumed

## Examples

### Complete Cleanup Workflow

```bash
# 1. Check current storage status
maccleaner status

# 2. Scan for large files
maccleaner scan --threshold 500

# 3. Interactive mode will let you process files

# 4. Clean caches (dry run first)
maccleaner clean --all --dry-run

# 5. Actually clean caches
maccleaner clean --user-caches

# 6. Check status again
maccleaner status
```

### Finding Huge Files on Desktop

```bash
maccleaner scan --path ~/Desktop --threshold 1000
```

### Quick Cache Cleanup

```bash
# Clean user caches only
maccleaner clean --user-caches

# Clean everything (needs sudo for system caches)
sudo maccleaner clean --all
```

## Requirements

- macOS 14.0 or later
- Swift 6.0 or later
- External drives mounted at configured paths

## Tips

1. **Run regularly**: Set up a cron job or LaunchAgent to run scans weekly
2. **Archive structure**: Files moved to storage are organized by year/month automatically
3. **Log review**: Check logs to see what was cleaned and when
4. **Backup first**: Always have backups before running cleanup operations
5. **System caches**: Only clean system caches if you know what you're doing

## Troubleshooting

### Volume not found

```
⚠️  Storage drive not available at /Volumes/storage1/
```

**Solution**: Make sure your external drives are mounted. Check paths with `ls /Volumes/`

### Permission denied

```
❌ Error: You don't have permission to access this file
```

**Solution**: Run with `sudo` or adjust file permissions

### Operation interrupted

If an operation is interrupted:

```bash
maccleaner resume
```

## License

MIT License - feel free to modify and use as needed!

## Contributing

This is a personal utility tool, but contributions are welcome. Feel free to:
- Add new features
- Improve existing functionality
- Fix bugs
- Enhance documentation
