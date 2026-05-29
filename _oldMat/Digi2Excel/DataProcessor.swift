import Foundation

/// Main data processor - Swift port of the MATLAB digitalMicDataTool
struct DataProcessor {
    
    /// Process rawData and headers to produce output CSV
    /// - Parameters:
    ///   - rawData: 2D array from rawData.csv
    ///   - headers: 1D array of header names from Headers.csv
    ///   - cm: CM factory info string
    /// - Returns: Tuple of (outputData as 2D string array, log entries)
    static func process(rawData: [[String]], headers: [String], cm: String) -> ([[String]], [LogEntry]) {
        var logs: [LogEntry] = []
        logs.append(LogEntry(message: "开始处理数据...", type: .info))
        logs.append(LogEntry(message: "原始数据: \(rawData.count) 行 × \(rawData.first?.count ?? 0) 列", type: .info))
        logs.append(LogEntry(message: "标签数量: \(headers.count) 个", type: .info))
        
        // Strip trailing empty rows from rawData
        var rawData = rawData
        while !rawData.isEmpty && rawData.last?.allSatisfy({ $0.trimmingCharacters(in: .whitespaces).isEmpty }) == true {
            rawData.removeLast()
        }
        logs.append(LogEntry(message: "真实原始数据: \(rawData.count) 行 × \(rawData.first?.count ?? 0) 列", type: .info))
        
        guard rawData.count >= 2 else {
            logs.append(LogEntry(message: "真实原始数据行不足", type: .error))
            return ([], logs)
        }
        
        // Volume labels: "1. 1" to "3. 10" (30 entries)
        var volume: [String] = []
        for i in 1...3 {
            for j in 1...10 {
                volume.append("\(i). \(j)")
            }
        }
        
        let headerRow = rawData[1] // Row index 1 = header row
        
        // Process each header — build columns (MATLAB: singleItem is column-major)
        var data: [[String]] = [] // starts empty
        
        for headerName in headers {
            // Collect matching columns from rawData
            // Each match: [subHeader, dataRow1, dataRow2, ...] — a COLUMN in the final matrix
            var columns: [[String]] = []
            
            for colIdx in 0..<headerRow.count {
                let colHeader = headerRow[colIdx]
                
                if colHeader.contains(headerName) {
                    let itemHead = colHeader.components(separatedBy: "@")
                    
                    if headerName.contains("Sens") || headerName.contains("tone") {
                        // Special: Sens/tone items have no "@" in header
                        if itemHead.count != 1 { continue }
                    } else {
                        // Normal items: must have "@" and exact name match
                        if itemHead.count < 2 { continue }
                        if itemHead[0] != headerName { continue }
                    }
                    
                    // Build column: subHeader + data from row 8 onwards
                    var col: [String] = [itemHead.last ?? ""]
                    if rawData.count > 7 {
                        for rowIdx in 7..<rawData.count {
                            col.append(colIdx < rawData[rowIdx].count ? rawData[rowIdx][colIdx] : "")
                        }
                    }
                    columns.append(col)
                }
            }
            
            // If no match found, create one empty column (31 rows)
            if columns.isEmpty {
                columns = [Array(repeating: "", count: 31)]
                logs.append(LogEntry(message: "HeaderNoMatch: \(headerName)", type: .warning))
            }
            
            // Transpose columns → rows: each frequency becomes a row
            let colCount = columns.count
            let rowCount = columns.first?.count ?? 0
            var rows: [[String]] = []
            for r in 0..<rowCount {
                var row: [String] = []
                for c in 0..<colCount {
                    row.append(r < columns[c].count ? columns[c][r] : "")
                }
                rows.append(row)
            }
            
            // Prepend header + volume column
            // Row 0: [headerName, freq1, freq2, ...]
            // Row 1+: [volume,    val1,  val2,  ...]
            var headCol: [String] = Array(repeating: "", count: rows.count)
            headCol[0] = headerName
            if volume.count < rows.count {
                for v in 0..<volume.count {
                    headCol[v + 1] = volume[v]
                }
            }
            for r in 0..<rows.count {
                rows[r].insert(headCol[r], at: 0)
            }
            
            // Add empty separator row on top
            let emptyRow = Array(repeating: "", count: rows.first?.count ?? 0)
            rows.insert(emptyRow, at: 0)
            
            // Vertically concatenate with data
            let theWidth = max(data.first?.count ?? 0, rows.first?.count ?? 0)
            data = extendArray(data, toWidth: theWidth)
            rows = extendArray(rows, toWidth: theWidth)
            data.append(contentsOf: rows)
        }
        
        // Insert CM on a new top row (don't overwrite data)
        let cmRow = Array(repeating: "", count: data.first?.count ?? 1)
        var cmRowFilled = cmRow
        cmRowFilled[0] = cm
        data[0] = cmRowFilled
        
        logs.append(LogEntry(message: "处理完成，输出 \(data.count) 行", type: .success))
        return (data, logs)
    }
    
    /// Extend array to specified width by padding with empty strings
    private static func extendArray(_ array: [[String]], toWidth width: Int) -> [[String]] {
        array.map { row in
            if row.count < width {
                return row + Array(repeating: "", count: width - row.count)
            } else if row.count > width {
                return Array(row.prefix(width))
            }
            return row
        }
    }
    
    /// Convert 2D string array to CSV string
    static func toCSVString(_ data: [[String]]) -> String {
        data.map { row in
            row.map { cell in
                if cell.contains(",") || cell.contains("\"") || cell.contains("\n") {
                    return "\"\(cell.replacingOccurrences(of: "\"", with: "\"\""))\""
                }
                return cell
            }.joined(separator: ",")
        }.joined(separator: "\n")
    }
    
    /// Generate output filename with CM and timestamp
    static func generateFilename(cm: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH:mm:ss"
        return "\(cm)_data_\(formatter.string(from: Date())).csv"
    }
}
