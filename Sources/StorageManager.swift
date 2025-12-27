import Foundation

actor StorageManager {
    static let shared = StorageManager()
    
    private let config: Configuration
    
    var storagePath: String { config.storagePath }
    var fastStoragePath: String { config.fastStoragePath }
    
    private let fileManager = FileManager.default
    
    private init() {
        self.config = Configuration.load()
    }
    
    func showStatus() {
        print("\n📊 Storage Status\n")
        
        // Check storage volume
        displayVolumeInfo(path: storagePath, name: "Storage Drive (HDD)")
        print()
        
        // Check fast storage volume
        displayVolumeInfo(path: fastStoragePath, name: "Fast Storage (NVMe)")
        print()
    }
    
    private func displayVolumeInfo(path: String, name: String) {
        guard fileManager.fileExists(atPath: path) else {
            print("⚠️  \(name) not mounted at \(path)")
            return
        }
        
        do {
            let url = URL(fileURLWithPath: path)
            let values = try url.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey])
            
            if let total = values.volumeTotalCapacity,
               let available = values.volumeAvailableCapacity {
                let used = total - available
                let percentUsed = Double(used) / Double(total) * 100
                
                print("💾 \(name)")
                print("   Path: \(path)")
                print("   Total: \(ByteCountFormatter.string(fromByteCount: Int64(total), countStyle: .file))")
                print("   Used:  \(ByteCountFormatter.string(fromByteCount: Int64(used), countStyle: .file)) (\(String(format: "%.1f", percentUsed))%)")
                print("   Free:  \(ByteCountFormatter.string(fromByteCount: Int64(available), countStyle: .file))")
            }
        } catch {
            print("❌ Error reading volume info: \(error.localizedDescription)")
        }
    }
    
    func moveToStorage(sourcePath: String, createArchiveStructure: Bool = true) async throws -> String {
        let logger = Logger.shared
        let journal = Journal.shared
        
        // Determine destination
        let sourceURL = URL(fileURLWithPath: sourcePath)
        let fileName = sourceURL.lastPathComponent
        
        var destinationPath: String
        if createArchiveStructure {
            // Create year/month structure
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM"
            let dateFolder = formatter.string(from: Date())
            destinationPath = "\(storagePath)Archive/\(dateFolder)/\(fileName)"
        } else {
            destinationPath = "\(storagePath)\(fileName)"
        }
        
        let destinationURL = URL(fileURLWithPath: destinationPath)
        
        // Check if destination exists
        if fileManager.fileExists(atPath: destinationPath) {
            let timestamp = Int(Date().timeIntervalSince1970)
            let nameWithoutExt = sourceURL.deletingPathExtension().lastPathComponent
            let ext = sourceURL.pathExtension
            destinationPath = destinationURL.deletingLastPathComponent()
                .appendingPathComponent("\(nameWithoutExt)_\(timestamp).\(ext)")
                .path
        }
        
        // Create destination directory
        let destDir = URL(fileURLWithPath: destinationPath).deletingLastPathComponent()
        try fileManager.createDirectory(at: destDir, withIntermediateDirectories: true)
        
        // Get file size
        let attributes = try fileManager.attributesOfItem(atPath: sourcePath)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        // Create journal entry
        let operation = FileOperation(
            source: sourcePath,
            destination: destinationPath,
            type: .archive,
            size: fileSize
        )
        await journal.addOperation(operation)
        await journal.updateOperation(operation.id, status: .inProgress)
        
        await logger.log("Moving \(sourcePath) to \(destinationPath) (\(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)))", level: .info)
        
        // Perform move
        try fileManager.moveItem(atPath: sourcePath, toPath: destinationPath)
        
        await journal.updateOperation(operation.id, status: .completed)
        await logger.log("Successfully moved to storage", level: .success)
        
        return destinationPath
    }
    
    func moveToFastStorage(sourcePath: String) async throws -> String {
        let logger = Logger.shared
        let journal = Journal.shared
        
        let sourceURL = URL(fileURLWithPath: sourcePath)
        let fileName = sourceURL.lastPathComponent
        let destinationPath = "\(fastStoragePath)\(fileName)"
        
        // Check if destination exists
        var finalDestPath = destinationPath
        if fileManager.fileExists(atPath: destinationPath) {
            let timestamp = Int(Date().timeIntervalSince1970)
            let nameWithoutExt = sourceURL.deletingPathExtension().lastPathComponent
            let ext = sourceURL.pathExtension
            finalDestPath = "\(fastStoragePath)\(nameWithoutExt)_\(timestamp).\(ext)"
        }
        
        // Get file size
        let attributes = try fileManager.attributesOfItem(atPath: sourcePath)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        // Create journal entry
        let operation = FileOperation(
            source: sourcePath,
            destination: finalDestPath,
            type: .move,
            size: fileSize
        )
        await journal.addOperation(operation)
        await journal.updateOperation(operation.id, status: .inProgress)
        
        await logger.log("Moving \(sourcePath) to fast storage (\(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)))", level: .info)
        
        // Perform move
        try fileManager.moveItem(atPath: sourcePath, toPath: finalDestPath)
        
        await journal.updateOperation(operation.id, status: .completed)
        await logger.log("Successfully moved to fast storage", level: .success)
        
        return finalDestPath
    }
    
    func checkVolumesAvailable() -> (storage: Bool, fastStorage: Bool) {
        let storageAvailable = fileManager.fileExists(atPath: storagePath)
        let fastStorageAvailable = fileManager.fileExists(atPath: fastStoragePath)
        return (storageAvailable, fastStorageAvailable)
    }
}
