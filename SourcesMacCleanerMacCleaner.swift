import Foundation
import ArgumentParser

@main
struct MacCleaner: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "maccleaner",
        abstract: "A comprehensive Mac cleanup tool with archiving and cache management",
        version: "1.0.0",
        subcommands: [
            Scan.self,
            Clean.self,
            Resume.self,
            Status.self
        ]
    )
}

// MARK: - Subcommands

extension MacCleaner {
    struct Scan: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Scan your Mac for large files and directories"
        )
        
        @Option(name: .shortAndLong, help: "Minimum file size in MB to report")
        var threshold: Int = 100
        
        @Option(name: .shortAndLong, help: "Path to scan (default: home directory)")
        var path: String?
        
        @Flag(name: .long, help: "Include system files")
        var includeSystem = false
        
        func run() async throws {
            let logger = Logger.shared
            let scanner = FileScanner(threshold: threshold, includeSystem: includeSystem)
            let scanPath = path ?? FileManager.default.homeDirectoryForCurrentUser.path
            
            logger.log("Starting scan of \(scanPath)", level: .info)
            
            let results = try await scanner.scan(path: scanPath)
            
            logger.log("Scan complete. Found \(results.largeFiles.count) large files", level: .info)
            
            // Display results
            ResultsDisplay.show(results)
        }
    }
    
    struct Clean: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Clean caches and temporary files"
        )
        
        @Flag(name: .long, help: "Clean user caches")
        var userCaches = false
        
        @Flag(name: .long, help: "Clean system caches (requires sudo)")
        var systemCaches = false
        
        @Flag(name: .long, help: "Clean all caches")
        var all = false
        
        @Flag(name: .shortAndLong, help: "Show what would be cleaned without actually cleaning")
        var dryRun = false
        
        func run() async throws {
            let logger = Logger.shared
            let cleaner = CacheCleaner(dryRun: dryRun)
            
            logger.log("Starting cleanup operation", level: .info)
            
            if all || userCaches {
                try await cleaner.cleanUserCaches()
            }
            
            if all || systemCaches {
                try await cleaner.cleanSystemCaches()
            }
            
            logger.log("Cleanup complete", level: .info)
        }
    }
    
    struct Resume: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Resume a previously interrupted operation"
        )
        
        func run() async throws {
            let journal = Journal.shared
            
            guard let operation = try journal.loadIncompleteOperation() else {
                print("No incomplete operations found")
                return
            }
            
            print("Resuming operation from \(operation.startDate)")
            try await operation.resume()
        }
    }
    
    struct Status: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Show status of storage volumes"
        )
        
        func run() async throws {
            let storage = StorageManager.shared
            storage.showStatus()
        }
    }
}
