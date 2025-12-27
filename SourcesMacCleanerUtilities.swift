import Foundation

/// Helper utilities for the MacCleaner tool
struct Utilities {
    
    /// Format bytes into human-readable string
    static func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
    
    /// Get relative time string (e.g., "2 days ago")
    static func relativeTime(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: date, to: now)
        
        if let years = components.year, years > 0 {
            return "\(years) year\(years > 1 ? "s" : "") ago"
        } else if let months = components.month, months > 0 {
            return "\(months) month\(months > 1 ? "s" : "") ago"
        } else if let days = components.day, days > 0 {
            return "\(days) day\(days > 1 ? "s" : "") ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours > 1 ? "s" : "") ago"
        } else {
            return "just now"
        }
    }
    
    /// Check if a path is likely a media file
    static func isMediaFile(_ path: String) -> Bool {
        let mediaExtensions = ["mp4", "mov", "avi", "mkv", "mp3", "wav", "m4a", "flac"]
        let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
        return mediaExtensions.contains(ext)
    }
    
    /// Check if a path is likely a disk image
    static func isDiskImage(_ path: String) -> Bool {
        let imageExtensions = ["dmg", "iso", "img"]
        let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
        return imageExtensions.contains(ext)
    }
    
    /// Check if a path is likely a development artifact
    static func isDevelopmentArtifact(_ path: String) -> Bool {
        let components = path.components(separatedBy: "/")
        let devIndicators = ["node_modules", "DerivedData", ".build", "build", "dist", "target"]
        return components.contains { devIndicators.contains($0) }
    }
    
    /// Get file type emoji
    static func fileTypeEmoji(for path: String, isDirectory: Bool) -> String {
        if isDirectory {
            return "📁"
        }
        
        let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
        
        switch ext {
        case "mp4", "mov", "avi", "mkv":
            return "🎥"
        case "mp3", "wav", "m4a", "flac":
            return "🎵"
        case "jpg", "jpeg", "png", "gif", "heic":
            return "🖼️"
        case "pdf":
            return "📕"
        case "zip", "tar", "gz", "7z", "rar":
            return "📦"
        case "dmg", "iso", "img":
            return "💿"
        case "app":
            return "📱"
        case "doc", "docx", "pages":
            return "📄"
        case "xls", "xlsx", "numbers":
            return "📊"
        case "ppt", "pptx", "key":
            return "📽️"
        default:
            return "📄"
        }
    }
    
    /// Create a progress bar string
    static func progressBar(current: Int, total: Int, width: Int = 40) -> String {
        let percentage = Double(current) / Double(total)
        let filled = Int(percentage * Double(width))
        let empty = width - filled
        
        let bar = String(repeating: "█", count: filled) + String(repeating: "░", count: empty)
        return "[\(bar)] \(Int(percentage * 100))%"
    }
    
    /// Ask user for confirmation
    static func confirm(_ message: String, defaultYes: Bool = false) -> Bool {
        print("\(message) [\(defaultYes ? "Y/n" : "y/N")]: ", terminator: "")
        
        guard let response = readLine()?.lowercased() else {
            return defaultYes
        }
        
        if response.isEmpty {
            return defaultYes
        }
        
        return response.hasPrefix("y")
    }
    
    /// Get system info
    static func getSystemInfo() -> [String: String] {
        let processInfo = ProcessInfo.processInfo
        
        return [
            "osVersion": processInfo.operatingSystemVersionString,
            "hostName": processInfo.hostName,
            "processorCount": "\(processInfo.processorCount)",
            "physicalMemory": formatBytes(Int64(processInfo.physicalMemory))
        ]
    }
    
    /// Check available disk space
    static func checkDiskSpace(at path: String) -> (total: Int64, available: Int64)? {
        let url = URL(fileURLWithPath: path)
        
        do {
            let values = try url.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey])
            
            if let total = values.volumeTotalCapacity,
               let available = values.volumeAvailableCapacity {
                return (Int64(total), Int64(available))
            }
        } catch {
            return nil
        }
        
        return nil
    }
    
    /// Smart file categorization
    static func categorizeFile(_ file: FileInfo) -> FileCategory {
        let path = file.path
        
        if isDevelopmentArtifact(path) {
            return .development
        } else if isMediaFile(path) {
            return .media
        } else if isDiskImage(path) {
            return .diskImage
        } else if file.isDirectory {
            return .directory
        } else {
            return .other
        }
    }
    
    enum FileCategory: String {
        case development = "Development"
        case media = "Media"
        case diskImage = "Disk Image"
        case directory = "Directory"
        case other = "Other"
        
        var recommendedDestination: String {
            switch self {
            case .development:
                return "Consider deleting or archiving"
            case .media:
                return "Archive to storage"
            case .diskImage:
                return "Archive to storage or delete"
            case .directory:
                return "Review contents"
            case .other:
                return "Review manually"
            }
        }
    }
}

/// Extension to enhance FileInfo with smart suggestions
extension FileInfo {
    var smartSuggestion: String {
        let category = Utilities.categorizeFile(self)
        let age = Calendar.current.dateComponents([.day], from: lastModified, to: Date()).day ?? 0
        
        var suggestions: [String] = []
        
        // Age-based suggestions
        if age > 365 {
            suggestions.append("Old file (>1 year)")
        }
        
        // Size-based suggestions
        if size > 5_000_000_000 { // 5GB
            suggestions.append("Very large")
        }
        
        // Category-based
        suggestions.append(category.recommendedDestination)
        
        return suggestions.joined(separator: " • ")
    }
}
