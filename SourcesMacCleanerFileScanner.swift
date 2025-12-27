import Foundation

struct FileInfo: Identifiable {
    let id = UUID()
    let path: String
    let size: Int64
    let lastModified: Date
    let isDirectory: Bool
    
    var sizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

struct ScanResults {
    var largeFiles: [FileInfo] = []
    var totalSize: Int64 = 0
    var scannedCount: Int = 0
    var duplicates: [[FileInfo]] = []
    
    mutating func add(_ file: FileInfo) {
        largeFiles.append(file)
        totalSize += file.size
        scannedCount += 1
    }
}

actor FileScanner {
    private let threshold: Int64
    private let includeSystem: Bool
    private let fileManager = FileManager.default
    
    init(threshold: Int, includeSystem: Bool = false) {
        self.threshold = Int64(threshold) * 1_048_576 // Convert MB to bytes
        self.includeSystem = includeSystem
    }
    
    func scan(path: String) async throws -> ScanResults {
        var results = ScanResults()
        let logger = Logger.shared
        
        await logger.log("Scanning \(path) for files larger than \(threshold / 1_048_576) MB", level: .info)
        
        let url = URL(fileURLWithPath: path)
        
        // Paths to exclude
        let excludedPaths = includeSystem ? [] : [
            "/System",
            "/Library/System",
            "/usr",
            "/private/var/db",
            "/private/var/vm"
        ]
        
        try await scanDirectory(url: url, results: &results, excludedPaths: excludedPaths)
        
        // Sort by size descending
        results.largeFiles.sort { $0.size > $1.size }
        
        await logger.log("Scan complete. Found \(results.largeFiles.count) large files totaling \(ByteCountFormatter.string(fromByteCount: results.totalSize, countStyle: .file))", level: .success)
        
        return results
    }
    
    private func scanDirectory(url: URL, results: inout ScanResults, excludedPaths: [String]) async throws {
        // Check if this path should be excluded
        if excludedPaths.contains(where: { url.path.hasPrefix($0) }) {
            return
        }
        
        let resourceKeys: Set<URLResourceKey> = [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey]
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return
        }
        
        for case let fileURL as URL in enumerator {
            // Skip excluded paths
            if excludedPaths.contains(where: { fileURL.path.hasPrefix($0) }) {
                enumerator.skipDescendants()
                continue
            }
            
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: resourceKeys)
                
                guard let isDirectory = resourceValues.isDirectory else { continue }
                
                if !isDirectory {
                    guard let size = resourceValues.fileSize,
                          let modified = resourceValues.contentModificationDate else {
                        continue
                    }
                    
                    if Int64(size) >= threshold {
                        let fileInfo = FileInfo(
                            path: fileURL.path,
                            size: Int64(size),
                            lastModified: modified,
                            isDirectory: false
                        )
                        results.add(fileInfo)
                        
                        // Log every 10 large files found
                        if results.largeFiles.count % 10 == 0 {
                            await Logger.shared.log("Found \(results.largeFiles.count) large files so far...", level: .debug)
                        }
                    }
                } else {
                    // For directories, calculate total size
                    let dirSize = try directorySize(at: fileURL)
                    if dirSize >= threshold {
                        let fileInfo = FileInfo(
                            path: fileURL.path,
                            size: dirSize,
                            lastModified: resourceValues.contentModificationDate ?? Date(),
                            isDirectory: true
                        )
                        results.add(fileInfo)
                        
                        // Skip descendants since we've already counted the directory
                        enumerator.skipDescendants()
                    }
                }
            } catch {
                // Skip files we can't access
                continue
            }
        }
    }
    
    private func directorySize(at url: URL) throws -> Int64 {
        let resourceKeys: Set<URLResourceKey> = [.isDirectoryKey, .fileSizeKey]
        var totalSize: Int64 = 0
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: resourceKeys)
            if let isDirectory = resourceValues.isDirectory, !isDirectory {
                if let size = resourceValues.fileSize {
                    totalSize += Int64(size)
                }
            }
        }
        
        return totalSize
    }
}
