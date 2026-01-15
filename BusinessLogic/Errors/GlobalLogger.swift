import os

class GlobalLogger {
    static let shared = GlobalLogger()
    
    private let logger = Logger(subsystem: "GlobalLogger", category: "Global")

    func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }

    func getLogger() -> Logger {
        return logger
    }
}
