# Changelog

All notable changes to MacCleaner will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-12-27

### Initial Release

#### Added
- **File Scanning**
  - Scan directories for large files and folders
  - Configurable size threshold (default: 100MB)
  - Smart file categorization (media, development, disk images)
  - Automatic system path exclusion
  - Directory size calculation
  - File age analysis

- **Interactive File Management**
  - File-by-file review interface
  - Smart suggestions based on file type and age
  - Multiple action options (archive, fast storage, delete, keep)
  - Safety confirmations for destructive operations
  - Progress tracking

- **Storage Management**
  - Multi-drive support (archive HDD + fast NVMe)
  - Automatic date-based organization (YYYY/MM structure)
  - Duplicate file handling with timestamps
  - Volume availability checking
  - Space usage reporting

- **Cache Cleaning**
  - User cache cleaning (~/Library/Caches, logs, crash reports)
  - Browser cache cleaning (Safari, Chrome, Firefox)
  - System cache cleaning (requires sudo)
  - Dry-run mode for safe preview
  - Selective cache targeting

- **Journaling System**
  - All operations tracked in JSON journal
  - Resume interrupted operations
  - Operation status tracking (pending, in-progress, completed, failed)
  - Session-based organization
  - Statistics and summaries

- **Logging**
  - Console output with emoji indicators
  - JSON log files for programmatic access
  - Multiple log levels (debug, info, warning, error, success)
  - Timestamp tracking
  - Context data support

- **Configuration Management**
  - JSON configuration file
  - CLI-based config editing
  - Default values
  - Path customization
  - Threshold settings

- **CLI Commands**
  - `scan` - Find large files
  - `clean` - Clean caches
  - `status` - Show storage info
  - `stats` - View operation statistics
  - `resume` - Continue interrupted operations
  - `config` - Manage configuration

- **Utilities**
  - Human-readable byte formatting
  - Relative time display
  - File type detection
  - Smart emoji indicators
  - Progress bars
  - Confirmation dialogs

#### Documentation
- Comprehensive README with usage examples
- Quick start guide (QUICKSTART.md)
- Extensive examples (EXAMPLES.md)
- Troubleshooting guide (TROUBLESHOOTING.md)
- Architecture documentation (ARCHITECTURE.md)
- Project summary (PROJECT_SUMMARY.md)

#### Automation
- LaunchAgent plist for scheduled scanning
- Example configuration file
- Install script for easy setup

#### Technical Features
- Swift 6.0 with strict concurrency
- Actor-based thread safety
- Async/await throughout
- Swift Argument Parser integration
- Foundation framework usage
- macOS 14.0+ support

### Known Limitations
- Requires macOS 14.0 (Sonoma) or later
- External drives must be mounted at configured paths
- System cache cleaning requires sudo
- Interactive mode requires terminal input

### Future Enhancements
- Duplicate file detection
- File compression before archiving
- Email reports
- Web UI for remote management
- Cloud storage integration
- Machine learning recommendations

---

## [Unreleased]

### Planned for 1.1.0
- [ ] Duplicate file finder using hash comparison
- [ ] Compression option before archiving
- [ ] Email notification support
- [ ] Enhanced filtering options
- [ ] Custom file type rules

### Ideas for Future Versions
- Web dashboard for remote monitoring
- iCloud/cloud storage integration
- Smart scheduling based on disk usage
- File preview in interactive mode
- Undo/restore functionality
- Network drive support
- Multiple archive strategies
- Integration with Finder tags
- Spotlight metadata search
- Time Machine integration

---

## Version History

### [1.0.0] - 2024-12-27
- Initial public release
- Full feature set as documented above
- Comprehensive documentation
- Production-ready code

---

## Contributing

To contribute to MacCleaner:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Update documentation
6. Submit a pull request

Please update this CHANGELOG.md with your changes following the format above.

## Versioning Guidelines

**Major version (X.0.0)**: Breaking changes
- Changed command syntax
- Removed features
- Changed file formats
- New minimum requirements

**Minor version (0.X.0)**: New features
- New commands
- New functionality
- Enhanced existing features
- Non-breaking improvements

**Patch version (0.0.X)**: Bug fixes
- Bug fixes
- Performance improvements
- Documentation updates
- Minor tweaks

## Support

For issues, feature requests, or questions:
- Check TROUBLESHOOTING.md
- Review EXAMPLES.md
- Read documentation
- Check logs in ~/Library/Application Support/MacCleaner/logs/

---

[1.0.0]: https://github.com/yourusername/maccleaner/releases/tag/v1.0.0
[Unreleased]: https://github.com/yourusername/maccleaner/compare/v1.0.0...HEAD
