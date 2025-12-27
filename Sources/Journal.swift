import Foundation

struct FileOperation: Codable, Identifiable {
    let id: UUID
    let sourcePath: String
    let destinationPath: String
    let operationType: OperationType
    let fileSize: Int64
    var status: OperationStatus
    let timestamp: Date
    
    enum OperationType: String, Codable {
        case move
        case delete
        case archive
    }
    
    enum OperationStatus: String, Codable {
        case pending
        case inProgress
        case completed
        case failed
        case skipped
    }
    
    init(source: String, destination: String, type: OperationType, size: Int64) {
        self.id = UUID()
        self.sourcePath = source
        self.destinationPath = destination
        self.operationType = type
        self.fileSize = size
        self.status = .pending
        self.timestamp = Date()
    }
}

struct JournalSession: Codable {
    let id: UUID
    let startDate: Date
    var endDate: Date?
    var operations: [FileOperation]
    var isComplete: Bool
    
    init() {
        self.id = UUID()
        self.startDate = Date()
        self.endDate = nil
        self.operations = []
        self.isComplete = false
    }
}

actor Journal {
    static let shared = Journal()
    
    private let journalDirectory: URL
    private let currentSessionFile: URL
    private var currentSession: JournalSession
    
    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        self.journalDirectory = appSupport.appendingPathComponent("TidyUp/journal", isDirectory: true)
        
        // Create journal directory if needed
        try? FileManager.default.createDirectory(at: journalDirectory, withIntermediateDirectories: true)
        
        // Create session file
        let sessionFileName = "session_\(UUID().uuidString).json"
        self.currentSessionFile = journalDirectory.appendingPathComponent(sessionFileName)
        self.currentSession = JournalSession()

        // Note: Initial session will be saved on first operation
    }
    
    func addOperation(_ operation: FileOperation) async {
        currentSession.operations.append(operation)
        try? save()
        await Logger.shared.log("Added operation: \(operation.operationType.rawValue) \(operation.sourcePath)", level: .debug)
    }
    
    func updateOperation(_ operationId: UUID, status: FileOperation.OperationStatus) async {
        if let index = currentSession.operations.firstIndex(where: { $0.id == operationId }) {
            currentSession.operations[index].status = status
            try? save()
            await Logger.shared.log("Updated operation \(operationId): \(status.rawValue)", level: .debug)
        }
    }
    
    func completeSession() async {
        currentSession.endDate = Date()
        currentSession.isComplete = true
        try? save()
        await Logger.shared.log("Session completed", level: .success)
    }
    
    nonisolated func loadIncompleteOperation() throws -> JournalSession? {
        let files = try FileManager.default.contentsOfDirectory(at: journalDirectory, includingPropertiesForKeys: nil)

        for file in files where file.pathExtension == "json" {
            let data = try Data(contentsOf: file)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let session = try decoder.decode(JournalSession.self, from: data)

            if !session.isComplete {
                return session
            }
        }

        return nil
    }
    
    func getPendingOperations() -> [FileOperation] {
        currentSession.operations.filter { $0.status == .pending }
    }
    
    func getStatistics() -> (total: Int, completed: Int, failed: Int, pending: Int, totalSize: Int64) {
        let total = currentSession.operations.count
        let completed = currentSession.operations.filter { $0.status == .completed }.count
        let failed = currentSession.operations.filter { $0.status == .failed }.count
        let pending = currentSession.operations.filter { $0.status == .pending }.count
        let totalSize = currentSession.operations.reduce(0) { $0 + $1.fileSize }
        
        return (total, completed, failed, pending, totalSize)
    }
    
    private func save() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(currentSession)
        try data.write(to: currentSessionFile)
    }
}

extension JournalSession {
    func resume() async throws {
        let journal = Journal.shared
        let logger = Logger.shared
        
        await logger.log("Resuming session with \(operations.count) operations", level: .info)
        
        for operation in operations where operation.status == .pending || operation.status == .inProgress {
            await logger.log("Resuming: \(operation.sourcePath)", level: .info)
            
            // Update status to in progress
            await journal.updateOperation(operation.id, status: .inProgress)
            
            do {
                // Perform the operation
                try await performOperation(operation)
                await journal.updateOperation(operation.id, status: .completed)
            } catch {
                await logger.log("Failed to complete operation: \(error.localizedDescription)", level: .error)
                await journal.updateOperation(operation.id, status: .failed)
            }
        }
        
        await journal.completeSession()
    }
    
    private func performOperation(_ operation: FileOperation) async throws {
        let fileManager = FileManager.default
        
        switch operation.operationType {
        case .move, .archive:
            // Ensure destination directory exists
            let destURL = URL(fileURLWithPath: operation.destinationPath)
            let destDir = destURL.deletingLastPathComponent()
            try fileManager.createDirectory(at: destDir, withIntermediateDirectories: true)
            
            // Move file
            try fileManager.moveItem(atPath: operation.sourcePath, toPath: operation.destinationPath)
            
        case .delete:
            try fileManager.removeItem(atPath: operation.sourcePath)
        }
    }
}
