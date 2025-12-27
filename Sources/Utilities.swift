import Foundation

/// Helper utilities for the TidyUp tool
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
    
    /// Format date for display
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy HH:mm:ss"
        return formatter.string(from: date)
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
