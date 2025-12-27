import Foundation

struct ResultsDisplay {
    static func show(_ results: ScanResults) {
        print("\n" + String(repeating: "=", count: 80))
        print("📊 SCAN RESULTS")
        print(String(repeating: "=", count: 80))
        print()
        
        print("📁 Total files scanned: \(results.scannedCount)")
        print("📦 Large files found: \(results.largeFiles.count)")
        print("💾 Total size: \(ByteCountFormatter.string(fromByteCount: results.totalSize, countStyle: .file))")
        print()
        
        if results.largeFiles.isEmpty {
            print("✨ No large files found!")
            return
        }
        
        print("🔍 Top Large Files:")
        print(String(repeating: "-", count: 80))
        print()
        
        // Display top 20 files
        for (index, file) in results.largeFiles.prefix(20).enumerated() {
            let number = String(format: "%2d", index + 1)
            let size = file.sizeFormatted.padding(toLength: 12, withPad: " ", startingAt: 0)
            let emoji = Utilities.fileTypeEmoji(for: file.path, isDirectory: file.isDirectory)
            
            print("\(number). \(emoji) \(size) - \(file.path)")
            print("    ⏰ \(Utilities.relativeTime(from: file.lastModified))")
            print("    💡 \(file.smartSuggestion)")
            print()
        }
        
        if results.largeFiles.count > 20 {
            print("... and \(results.largeFiles.count - 20) more files")
            print()
        }
        
        print(String(repeating: "=", count: 80))
        print()
        
        // Interactive mode
        interactiveMode(results)
    }
    
    static func interactiveMode(_ results: ScanResults) {
        let storageManager = StorageManager.shared
        
        // Check if volumes are available
        let volumes = Task {
            await storageManager.checkVolumesAvailable()
        }
        
        guard let (storageAvailable, fastStorageAvailable) = try? volumes.value else {
            print("⚠️  Could not check volume availability")
            return
        }
        
        if !storageAvailable {
            print("⚠️  Storage drive not available")
        }
        if !fastStorageAvailable {
            print("⚠️  Fast storage not available")
        }
        
        print("🔧 Interactive Mode")
        print()
        print("Would you like to process these files? (y/n): ", terminator: "")
        
        guard let response = readLine()?.lowercased(), response == "y" else {
            print("Exiting...")
            return
        }
        
        // Process each file
        for (index, file) in results.largeFiles.enumerated() {
            print("\n" + String(repeating: "-", count: 80))
            print("File \(index + 1) of \(results.largeFiles.count)")
            print("\(Utilities.fileTypeEmoji(for: file.path, isDirectory: file.isDirectory)) \(file.path)")
            print("Size: \(file.sizeFormatted)")
            print("Last modified: \(formatDate(file.lastModified))")
            print()
            
            print("Options:")
            print("  [s] Move to Storage")
            print("  [f] Move to Fast Storage")
            print("  [d] Delete")
            print("  [k] Keep (skip)")
            print("  [q] Quit")
            print()
            print("Choose action: ", terminator: "")
            
            guard let action = readLine()?.lowercased() else { continue }
            
            let task = Task {
                switch action {
                case "s":
                    if storageAvailable {
                        do {
                            let dest = try await storageManager.moveToStorage(sourcePath: file.path)
                            print("✅ Moved to: \(dest)")
                        } catch {
                            print("❌ Error: \(error.localizedDescription)")
                        }
                    } else {
                        print("⚠️  Storage drive not available")
                    }
                    
                case "f":
                    if fastStorageAvailable {
                        do {
                            let dest = try await storageManager.moveToFastStorage(sourcePath: file.path)
                            print("✅ Moved to: \(dest)")
                        } catch {
                            print("❌ Error: \(error.localizedDescription)")
                        }
                    } else {
                        print("⚠️  Fast storage not available")
                    }
                    
                case "d":
                    print("⚠️  Are you sure you want to delete this file? (yes/no): ", terminator: "")
                    if let confirm = readLine()?.lowercased(), confirm == "yes" {
                        do {
                            try FileManager.default.removeItem(atPath: file.path)
                            let journal = Journal.shared
                            let operation = FileOperation(source: file.path, destination: "", type: .delete, size: file.size)
                            await journal.addOperation(operation)
                            await journal.updateOperation(operation.id, status: .completed)
                            print("✅ Deleted")
                        } catch {
                            print("❌ Error: \(error.localizedDescription)")
                        }
                    } else {
                        print("Cancelled")
                    }
                    
                case "k":
                    print("⏭️  Skipped")
                    
                case "q":
                    print("👋 Exiting...")
                    return
                    
                default:
                    print("❓ Invalid option, skipping...")
                }
            }
            
            _ = try? task.value
        }
        
        print("\n✅ All files processed!")
    }
    
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
