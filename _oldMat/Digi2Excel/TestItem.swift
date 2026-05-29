import Foundation

/// Represents a single test item from the Headers.csv
struct TestItem: Identifiable {
    let id = UUID()
    let headerName: String
    var columns: [[String]] // Each column: [subHeader, dataRow1, dataRow2, ...]
    var isMissing: Bool = false
}

/// Log entry for processing status
struct LogEntry: Identifiable {
    let id = UUID()
    let message: String
    let type: LogType
    
    enum LogType {
        case info
        case warning
        case error
        case success
    }
}
