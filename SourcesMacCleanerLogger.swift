import Foundation

enum LogLevel: String, Codable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case success = "SUCCESS"
    
    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .success: return "✅"
        }
    }
}

struct LogEntry: Codable {
    let timestamp: Date
    let level: LogLevel
    let message: String
    let context: [String: String]?
    
    init(level: LogLevel, message: String, context: [String: String]? = nil) {
        self.timestamp = Date()
        self.level = level
        self.message = message
        self.context = context
    }
}

actor Logger {
    static let shared = Logger()
    
    private let logDirectory: URL
    private let currentLogFile: URL
    private var logFileHandle: FileHandle?
    
    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        self.logDirectory = appSupport.appendingPathComponent("MacCleaner/logs", isDirectory: true)
        
        // Create log directory if needed
        try? FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true)
        
        // Create log file with timestamp
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "maccleaner_\(formatter.string(from: Date())).log"
        self.currentLogFile = logDirectory.appendingPathComponent(filename)
        
        // Create log file
        FileManager.default.createFile(atPath: currentLogFile.path, contents: nil)
        self.logFileHandle = try? FileHandle(forWritingTo: currentLogFile)
    }
    
    func log(_ message: String, level: LogLevel = .info, context: [String: String]? = nil) {
        let entry = LogEntry(level: level, message: message, context: context)
        
        // Format for console
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timeString = formatter.string(from: entry.timestamp)
        
        let consoleMessage = "\(entry.level.emoji) [\(timeString)] \(message)"
        print(consoleMessage)
        
        // Format for file
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        if let jsonData = try? jsonEncoder.encode(entry),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            let logLine = jsonString + "\n"
            if let data = logLine.data(using: .utf8) {
                try? logFileHandle?.write(contentsOf: data)
            }
        }
    }
    
    func readLogs(limit: Int = 100) throws -> [LogEntry] {
        let contents = try String(contentsOf: currentLogFile, encoding: .utf8)
        let lines = contents.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return lines.suffix(limit).compactMap { line in
            try? decoder.decode(LogEntry.self, from: line.data(using: .utf8)!)
        }
    }
    
    deinit {
        try? logFileHandle?.close()
    }
}
