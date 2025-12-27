# MacCleaner Troubleshooting Guide

## Common Issues and Solutions

### 1. Volume Not Found

**Error:**
```
⚠️  Storage drive not available at /Volumes/storage1/
⚠️  Fast storage not available at /Volumes/flash1/
```

**Solutions:**

a. **Check if drives are mounted:**
```bash
ls /Volumes/
```

b. **Mount drives if needed:**
```bash
diskutil list
diskutil mount disk2s1  # Use correct disk identifier
```

c. **Update configuration:**
```bash
# Find correct paths
ls /Volumes/

# Update config
maccleaner config --storage-path "/Volumes/YourDrive/" --fast-storage-path "/Volumes/YourSSD/"
```

d. **Verify configuration:**
```bash
maccleaner config --show
```

---

### 2. Permission Denied

**Error:**
```
❌ Error: You don't have permission to access this file
```

**Solutions:**

a. **For system caches, use sudo:**
```bash
sudo maccleaner clean --system-caches
```

b. **Fix file permissions:**
```bash
# Check permissions
ls -la /path/to/file

# Fix if needed
chmod 644 /path/to/file
```

c. **Full Disk Access (macOS Catalina+):**
1. System Settings → Privacy & Security → Full Disk Access
2. Add Terminal or your terminal app
3. Restart terminal

---

### 3. Operation Interrupted

**Error:**
```
^C (Ctrl+C pressed or unexpected termination)
```

**Solution:**
```bash
# Resume from where it left off
maccleaner resume
```

The journal system tracks all operations, so you can safely resume.

---

### 4. "No space left on device"

**Error when moving files:**
```
❌ Error: No space left on device
```

**Solutions:**

a. **Check destination space:**
```bash
maccleaner status
```

b. **Clean destination drive:**
```bash
# Check what's using space
du -sh /Volumes/storage1/* | sort -h

# Clean if possible
```

c. **Choose different destination:**
In interactive mode, select the drive with more space.

---

### 5. Build Errors

**Error during `swift build`:**
```
error: unable to resolve dependencies
```

**Solutions:**

a. **Update Swift:**
```bash
# Check version
swift --version

# Should be Swift 6.0 or later
# Download from https://swift.org or via Xcode
```

b. **Clean build:**
```bash
swift package clean
rm -rf .build
swift build
```

c. **Update dependencies:**
```bash
swift package update
swift build
```

---

### 6. Configuration Issues

**Error:**
```
⚠️  Failed to load config, using defaults
```

**Solutions:**

a. **Reset configuration:**
```bash
maccleaner config --reset
```

b. **Manually check config:**
```bash
# View config file
cat ~/Library/Application\ Support/MacCleaner/config.json

# Edit if needed
open ~/Library/Application\ Support/MacCleaner/config.json
```

c. **Use example config:**
```bash
cp config.example.json ~/Library/Application\ Support/MacCleaner/config.json
```

---

### 7. Slow Scanning

**Issue: Scan takes very long**

**Solutions:**

a. **Increase threshold:**
```bash
# Only find very large files
maccleaner scan --threshold 1000
```

b. **Scan specific directories:**
```bash
# Don't scan entire home directory
maccleaner scan --path ~/Downloads
maccleaner scan --path ~/Documents
```

c. **Exclude paths:**
Edit config to exclude slow directories:
```json
{
  "excludePaths": [
    "/System",
    "/Library",
    "~/Library/Photos",
    "~/Library/Developer"
  ]
}
```

---

### 8. LaunchAgent Not Running

**Issue: Automated scans not working**

**Solutions:**

a. **Check if loaded:**
```bash
launchctl list | grep maccleaner
```

b. **View logs:**
```bash
cat /tmp/maccleaner-weekly.log
cat /tmp/maccleaner-weekly-error.log
```

c. **Reload LaunchAgent:**
```bash
launchctl unload ~/Library/LaunchAgents/com.user.maccleaner.weekly.plist
launchctl load ~/Library/LaunchAgents/com.user.maccleaner.weekly.plist
```

d. **Check permissions:**
```bash
chmod 644 ~/Library/LaunchAgents/com.user.maccleaner.weekly.plist
```

e. **Test manually:**
```bash
# Run the command directly
/usr/local/bin/maccleaner scan --threshold 500
```

---

### 9. File Operations Failing

**Error:**
```
❌ Failed to move file: Operation not permitted
```

**Solutions:**

a. **Check if file is in use:**
```bash
lsof | grep filename
```

b. **Check file system:**
```bash
# Verify destination is writable
touch /Volumes/storage1/test.txt
rm /Volumes/storage1/test.txt
```

c. **Check disk health:**
```bash
diskutil verifyVolume /Volumes/storage1
```

d. **Review journal:**
```bash
maccleaner stats
cat ~/Library/Application\ Support/MacCleaner/journal/*.json
```

---

### 10. Cannot Delete Caches

**Issue: Cache cleaning reports errors**

**Solutions:**

a. **Close all applications:**
```bash
# Some caches are in use
# Close apps before cleaning
```

b. **Try dry-run first:**
```bash
maccleaner clean --all --dry-run
```

c. **Clean specific caches only:**
```bash
# Don't use --all
maccleaner clean --user-caches
```

d. **Manual cache cleanup:**
```bash
# Browser caches (close browsers first)
rm -rf ~/Library/Caches/com.apple.Safari

# User caches
cd ~/Library/Caches
ls -lh | sort -k 5 -h
```

---

### 11. Install Script Fails

**Error:**
```
permission denied: /usr/local/bin/maccleaner
```

**Solutions:**

a. **Use sudo:**
```bash
sudo ./install.sh
```

b. **Install to user directory:**
```bash
# Build
swift build -c release

# Copy to user bin
mkdir -p ~/bin
cp .build/release/maccleaner ~/bin/

# Add to PATH
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

---

### 12. Interactive Mode Not Working

**Issue: Cannot type responses**

**Solutions:**

a. **Check terminal:**
```bash
# Make sure you're in interactive terminal, not background process
```

b. **Use non-interactive scan:**
```bash
# Skip interactive mode for now
maccleaner scan --threshold 500 > results.txt
```

c. **Check input:**
```bash
# Test if stdin works
read -p "Test: " test
echo $test
```

---

### 13. Log Files Growing Too Large

**Issue: Log directory getting huge**

**Solutions:**

a. **Rotate logs:**
```bash
# Compress old logs
cd ~/Library/Application\ Support/MacCleaner/logs
gzip *.log

# Or delete old logs
find . -name "*.log" -mtime +30 -delete
```

b. **Set up log rotation:**
```bash
#!/bin/bash
# log-rotation.sh
LOG_DIR="$HOME/Library/Application Support/MacCleaner/logs"
find "$LOG_DIR" -name "*.log" -mtime +30 -delete
find "$LOG_DIR" -name "*.log" -mtime +7 -exec gzip {} \;
```

---

### 14. Duplicate File Handling Issues

**Issue: Too many files with timestamps**

**Solutions:**

a. **Clean up duplicates manually:**
```bash
# Find files with timestamps
ls /Volumes/storage1/ | grep '_[0-9]\{10\}\.'
```

b. **Prevent duplicates:**
Before running operations, check destinations:
```bash
ls /Volumes/storage1/Archive/2024/12/
```

---

### 15. Memory Issues on Large Scans

**Error: Process killed due to memory**

**Solutions:**

a. **Increase threshold:**
```bash
# Don't find too many files
maccleaner scan --threshold 2000
```

b. **Scan smaller directories:**
```bash
# Break into smaller scans
for dir in ~/Downloads ~/Documents ~/Desktop; do
  maccleaner scan --path "$dir"
done
```

c. **Use system Activity Monitor:**
```bash
# Monitor memory usage
top -pid $(pgrep maccleaner)
```

---

## Getting More Help

### View Logs
```bash
# Recent logs
maccleaner stats --limit 50

# All logs
cat ~/Library/Application\ Support/MacCleaner/logs/*.log | grep ERROR
```

### Check Journal
```bash
# View current session
cat ~/Library/Application\ Support/MacCleaner/journal/*.json | jq .
```

### System Information
```bash
# Check system
sw_vers
df -h
diskutil list
```

### Debug Mode
Add verbose output by modifying the log level in code, or redirect output:
```bash
maccleaner scan --threshold 500 2>&1 | tee debug.log
```

---

## Prevention Tips

1. **Regular Maintenance**: Run scans weekly with reasonable thresholds
2. **Keep Drives Mounted**: Always have archive drives available
3. **Backup First**: Use Time Machine before major operations
4. **Start Small**: Use dry-run and high thresholds first
5. **Monitor Space**: Run `maccleaner status` regularly
6. **Review Logs**: Check stats after operations
7. **Update Config**: Keep configuration current with actual drive locations
8. **Test Resume**: Periodically test the resume functionality

---

## When All Else Fails

### Complete Reset
```bash
# Remove all MacCleaner data
rm -rf ~/Library/Application\ Support/MacCleaner

# Reinstall
cd MacCleaner
./install.sh

# Reconfigure
maccleaner config --storage-path "/Volumes/storage1/" --fast-storage-path "/Volumes/flash1/"
```

### Manual Operations
If the tool isn't working, you can always:
```bash
# Find large files manually
find ~ -type f -size +500M -exec ls -lh {} \;

# Move files manually
mv large-file.mov /Volumes/storage1/Archive/

# Clean caches manually
rm -rf ~/Library/Caches/*
```

---

## Contact & Support

For persistent issues:
1. Check the EXAMPLES.md file
2. Review PROJECT_SUMMARY.md
3. Read the full README.md
4. Check logs and journal files
5. Review source code comments

Remember: All operations are journaled, so data loss should be impossible. If you're concerned, always make a backup first!
