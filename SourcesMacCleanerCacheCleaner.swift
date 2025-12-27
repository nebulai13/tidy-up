import Foundation

actor CacheCleaner {
    private let fileManager = FileManager.default
    private let dryRun: Bool
    
    init(dryRun: Bool = false) {
        self.dryRun = dryRun
    }
    
    func cleanUserCaches() async throws {
        let logger = Logger.shared
        let journal = Journal.shared
        
        await logger.log("Starting user cache cleanup" + (dryRun ? " (dry run)" : ""), level: .info)
        
        // User cache directories
        let homeDirectory = fileManager.homeDirectoryForCurrentUser
        let cachePaths = [
            homeDirectory.appendingPathComponent("Library/Caches"),
            homeDirectory.appendingPathComponent("Library/Logs"),
            homeDirectory.appendingPathComponent("Library/Application Support/CrashReporter"),
        ]
        
        var totalCleaned: Int64 = 0
        
        for cachePath in cachePaths {
            guard fileManager.fileExists(atPath: cachePath.path) else { continue }
            
            await logger.log("Checking \(cachePath.path)", level: .debug)
            
            do {
                let contents = try fileManager.contentsOfDirectory(
                    at: cachePath,
                    includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
                    options: [.skipsHiddenFiles]
                )
                
                for item in contents {
                    // Skip certain critical caches
                    if shouldSkipCache(item) {
                        continue
                    }
                    
                    do {
                        let size = try calculateSize(of: item)
                        
                        if !dryRun {
                            // Create journal entry
                            let operation = FileOperation(
                                source: item.path,
                                destination: "",
                                type: .delete,
                                size: size
                            )
                            await journal.addOperation(operation)
                            await journal.updateOperation(operation.id, status: .inProgress)
                            
                            try fileManager.removeItem(at: item)
                            
                            await journal.updateOperation(operation.id, status: .completed)
                            await logger.log("Removed: \(item.lastPathComponent) (\(ByteCountFormatter.string(fromByteCount: size, countStyle: .file)))", level: .success)
                        } else {
                            await logger.log("Would remove: \(item.lastPathComponent) (\(ByteCountFormatter.string(fromByteCount: size, countStyle: .file)))", level: .info)
                        }
                        
                        totalCleaned += size
                    } catch {
                        await logger.log("Failed to process \(item.lastPathComponent): \(error.localizedDescription)", level: .warning)
                    }
                }
            } catch {
                await logger.log("Failed to read directory \(cachePath.path): \(error.localizedDescription)", level: .error)
            }
        }
        
        await logger.log("User cache cleanup complete. \(dryRun ? "Would free" : "Freed") \(ByteCountFormatter.string(fromByteCount: totalCleaned, countStyle: .file))", level: .success)
    }
    
    func cleanSystemCaches() async throws {
        let logger = Logger.shared
        
        await logger.log("System cache cleaning requires administrator privileges", level: .warning)
        await logger.log("Run with sudo to clean system caches", level: .info)
        
        // Check if running with elevated privileges
        guard getuid() == 0 else {
            await logger.log("Not running as root. Skipping system caches.", level: .warning)
            return
        }
        
        let systemCachePaths = [
            "/Library/Caches",
            "/System/Library/Caches"
        ]
        
        var totalCleaned: Int64 = 0
        
        for cachePath in systemCachePaths {
            let cacheURL = URL(fileURLWithPath: cachePath)
            guard fileManager.fileExists(atPath: cachePath) else { continue }
            
            await logger.log("Checking \(cachePath)", level: .debug)
            
            do {
                let contents = try fileManager.contentsOfDirectory(
                    at: cacheURL,
                    includingPropertiesForKeys: [.fileSizeKey],
                    options: [.skipsHiddenFiles]
                )
                
                for item in contents {
                    if shouldSkipCache(item) {
                        continue
                    }
                    
                    do {
                        let size = try calculateSize(of: item)
                        
                        if !dryRun {
                            try fileManager.removeItem(at: item)
                            await logger.log("Removed: \(item.lastPathComponent) (\(ByteCountFormatter.string(fromByteCount: size, countStyle: .file)))", level: .success)
                        } else {
                            await logger.log("Would remove: \(item.lastPathComponent) (\(ByteCountFormatter.string(fromByteCount: size, countStyle: .file)))", level: .info)
                        }
                        
                        totalCleaned += size
                    } catch {
                        await logger.log("Failed to process \(item.lastPathComponent): \(error.localizedDescription)", level: .warning)
                    }
                }
            } catch {
                await logger.log("Failed to read directory \(cachePath): \(error.localizedDescription)", level: .error)
            }
        }
        
        await logger.log("System cache cleanup complete. \(dryRun ? "Would free" : "Freed") \(ByteCountFormatter.string(fromByteCount: totalCleaned, countStyle: .file))", level: .success)
    }
    
    func cleanBrowserCaches() async throws {
        let logger = Logger.shared
        let homeDirectory = fileManager.homeDirectoryForCurrentUser
        
        await logger.log("Cleaning browser caches", level: .info)
        
        let browserCaches = [
            "Library/Caches/com.apple.Safari",
            "Library/Safari/LocalStorage",
            "Library/Safari/Databases",
            "Library/Application Support/Google/Chrome/Default/Cache",
            "Library/Application Support/Firefox/Profiles",
        ]
        
        var totalCleaned: Int64 = 0
        
        for cache in browserCaches {
            let cacheURL = homeDirectory.appendingPathComponent(cache)
            guard fileManager.fileExists(atPath: cacheURL.path) else { continue }
            
            do {
                let size = try calculateSize(of: cacheURL)
                
                if !dryRun {
                    try fileManager.removeItem(at: cacheURL)
                    await logger.log("Removed browser cache: \(cache) (\(ByteCountFormatter.string(fromByteCount: size, countStyle: .file)))", level: .success)
                } else {
                    await logger.log("Would remove browser cache: \(cache) (\(ByteCountFormatter.string(fromByteCount: size, countStyle: .file)))", level: .info)
                }
                
                totalCleaned += size
            } catch {
                await logger.log("Failed to clean \(cache): \(error.localizedDescription)", level: .warning)
            }
        }
        
        await logger.log("Browser cache cleanup complete. \(dryRun ? "Would free" : "Freed") \(ByteCountFormatter.string(fromByteCount: totalCleaned, countStyle: .file))", level: .success)
    }
    
    private func shouldSkipCache(_ url: URL) -> Bool {
        let skipPrefixes = [
            "com.apple.KeyboardServices",
            "com.apple.accountsd",
            "com.apple.cloud",
        ]
        
        let name = url.lastPathComponent
        return skipPrefixes.contains { name.hasPrefix($0) }
    }
    
    private func calculateSize(of url: URL) throws -> Int64 {
        let resourceKeys: Set<URLResourceKey> = [.isDirectoryKey, .fileSizeKey, .totalFileSizeKey]
        let resourceValues = try url.resourceValues(forKeys: resourceKeys)
        
        if let isDirectory = resourceValues.isDirectory, isDirectory {
            var totalSize: Int64 = 0
            
            if let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: [.fileSizeKey, .totalFileSizeKey],
                options: []
            ) {
                for case let fileURL as URL in enumerator {
                    let values = try fileURL.resourceValues(forKeys: [.fileSizeKey, .totalFileSizeKey])
                    totalSize += Int64(values.totalFileSize ?? values.fileSize ?? 0)
                }
            }
            
            return totalSize
        } else {
            return Int64(resourceValues.totalFileSize ?? resourceValues.fileSize ?? 0)
        }
    }
}
