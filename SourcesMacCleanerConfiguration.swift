import Foundation

struct Configuration: Codable {
    var storagePath: String
    var fastStoragePath: String
    var defaultThreshold: Int
    var excludePaths: [String]
    var autoArchiveOldFiles: Bool
    var archiveOlderThanDays: Int
    
    static let `default` = Configuration(
        storagePath: "/Volumes/storage1/",
        fastStoragePath: "/Volumes/flash1/",
        defaultThreshold: 100,
        excludePaths: [
            "/System",
            "/Library/System",
            "/usr",
            "/private/var/db",
            "/private/var/vm"
        ],
        autoArchiveOldFiles: false,
        archiveOlderThanDays: 365
    )
    
    static let configPath: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let configDir = appSupport.appendingPathComponent("MacCleaner", isDirectory: true)
        try? FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
        return configDir.appendingPathComponent("config.json")
    }()
    
    static func load() -> Configuration {
        guard FileManager.default.fileExists(atPath: configPath.path) else {
            // Create default config
            let config = Configuration.default
            try? config.save()
            return config
        }
        
        do {
            let data = try Data(contentsOf: configPath)
            let decoder = JSONDecoder()
            return try decoder.decode(Configuration.self, from: data)
        } catch {
            print("⚠️  Failed to load config, using defaults: \(error.localizedDescription)")
            return .default
        }
    }
    
    func save() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        try data.write(to: Configuration.configPath)
    }
}
