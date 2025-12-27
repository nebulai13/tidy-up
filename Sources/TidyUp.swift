//
//  main.swift
//  tidy-up
//
//  Created by Yara Riedl on 27.12.25.
//

import Foundation
import ArgumentParser

@main
struct TidyUp: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tidy-up",
        abstract: "A comprehensive Mac cleanup tool with archiving and cache management",
        version: "1.0.0",
        subcommands: [
            Scan.self,
            Clean.self,
            Resume.self,
            Status.self,
            Stats.self,
            Config.self
        ]
    )
}

// MARK: - Subcommands
extension TidyUp {
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
            
            await logger.log("Starting scan of \(scanPath)", level: .info)
            
            let results = try await scanner.scan(path: scanPath)

            await logger.log("Scan complete. Found \(results.largeFiles.count) large files", level: .info)

            // Display results
            await ResultsDisplay.show(results)
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
            
            await logger.log("Starting cleanup operation", level: .info)
            
            if all || userCaches {
                try await cleaner.cleanUserCaches()
            }
            
            if all || systemCaches {
                try await cleaner.cleanSystemCaches()
            }
            
            await logger.log("Cleanup complete", level: .info)
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
            await storage.showStatus()
        }
    }
    
    struct Stats: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Show statistics from previous operations"
        )
        
        @Option(name: .shortAndLong, help: "Number of recent operations to show")
        var limit: Int = 10
        
        func run() async throws {
            let journal = Journal.shared
            let stats = await journal.getStatistics()
            
            print("\n📊 Operation Statistics\n")
            print("Total operations: \(stats.total)")
            print("Completed: \(stats.completed) ✅")
            print("Failed: \(stats.failed) ❌")
            print("Pending: \(stats.pending) ⏳")
            print("Total size processed: \(Utilities.formatBytes(stats.totalSize))")
            print()
            
            // Show recent logs
            let logger = Logger.shared
            do {
                let logs = try await logger.readLogs(limit: limit)
                
                if !logs.isEmpty {
                    print("📝 Recent Log Entries:\n")
                    for log in logs.suffix(limit) {
                        print("\(log.level.emoji) [\(Utilities.formatDate(log.timestamp))] \(log.message)")
                    }
                }
            } catch {
                print("⚠️  Could not read logs: \(error.localizedDescription)")
            }
        }
    }
    
    struct Config: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Manage configuration settings"
        )
        
        @Flag(name: .long, help: "Show current configuration")
        var show = false
        
        @Flag(name: .long, help: "Reset to default configuration")
        var reset = false
        
        @Option(name: .long, help: "Set storage path")
        var storagePath: String?
        
        @Option(name: .long, help: "Set fast storage path")
        var fastStoragePath: String?
        
        @Option(name: .long, help: "Set default threshold (MB)")
        var threshold: Int?
        
        func run() async throws {
            var config = Configuration.load()
            
            if reset {
                config = Configuration.default
                try config.save()
                print("✅ Configuration reset to defaults")
                return
            }
            
            var modified = false
            
            if let storage = storagePath {
                config.storagePath = storage
                modified = true
            }
            
            if let fastStorage = fastStoragePath {
                config.fastStoragePath = fastStorage
                modified = true
            }
            
            if let threshold = threshold {
                config.defaultThreshold = threshold
                modified = true
            }
            
            if modified {
                try config.save()
                print("✅ Configuration updated")
            }
            
            if show || !modified {
                print("\n⚙️  Current Configuration\n")
                print("Storage path:      \(config.storagePath)")
                print("Fast storage path: \(config.fastStoragePath)")
                print("Default threshold: \(config.defaultThreshold) MB")
                print("Exclude paths:     \(config.excludePaths.count) paths")
                print("Auto-archive old:  \(config.autoArchiveOldFiles ? "Yes" : "No")")
                if config.autoArchiveOldFiles {
                    print("Archive age:       \(config.archiveOlderThanDays) days")
                }
                print("\nConfig file: \(Configuration.configPath.path)")
            }
        }
    }
}


